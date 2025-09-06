from .base_agent import BaseAgent, AgentRequest, AgentResponse, ModelType, AgentRole
import logging
from datetime import datetime
import json
import os
import time
import google.generativeai as genai
from typing import Dict, Any, Optional, Tuple, List
from tenacity import retry, stop_after_attempt, wait_exponential
from jsonschema import validate, ValidationError
from threading import Lock
from infrastructure.strategy_cache import strategy_cache

logger = logging.getLogger(__name__)

class TokenBucket:
    def __init__(self, capacity: int, rate: float):
        self.capacity = capacity  # 200 requests per 20 minutes
        self.rate = rate  # 1 token every 6 seconds
        self.tokens = capacity
        self.last_refill = time.time()
        self.lock = Lock()

    def _refill(self):
        now = time.time()
        new_tokens = (now - self.last_refill) * self.rate
        self.tokens = min(self.capacity, self.tokens + new_tokens)
        self.last_refill = now

    def acquire(self):
        with self.lock:
            self._refill()
            if self.tokens >= 1:
                self.tokens -= 1
                return True
            return False

# Initialize token bucket: 200 requests per 20 minutes (1200 seconds)
token_bucket = TokenBucket(capacity=200, rate=1/6)

class GameTheoryAgent(BaseAgent):
    """
    The GameTheoryAgent handles OODA Orient & Decide phases for the Berghain Challenge,
    generating adaptive policies based on game state and constraints.
    """
    
    def __init__(self, agent_role: AgentRole, collections_manager=None, redis_client=None,
                 teacher_agent=None, narrative_agent=None, transcendent_agent=None):
        super().__init__(agent_role=agent_role, model_type=ModelType.GEMINI_2_5_PRO,
                        collections_manager=collections_manager, redis_client=redis_client)
        self.logger = logging.getLogger(self.__class__.__name__)
        self.teacher_agent = teacher_agent
        self.narrative_agent = narrative_agent
        self.transcendent_agent = transcendent_agent
        self.venue_capacity = 1000  # Fixed for Berghain
        self.request_count = 0
        self.window_start = time.time()
        
        # Performance optimization settings
        self.enable_cache = True
        self.enable_smart_routing = True
        self.fast_model = None  # Will be initialized for Gemma 3
        self._init_fast_model()

    async def initialize(self):
        """Initialize LLM for strategy generation."""
        self.logger.info("Initializing GameTheoryAgent components...")
        if self.model:
            self.logger.info("✅ GameTheoryAgent LLM initialized via BaseAgent.")
        else:
            self.logger.warning("No LLM available - using game theory fallback.")

    async def cleanup(self):
        """Cleanup resources used by the agent."""
        self.logger.info("Cleaning up GameTheoryAgent resources...")
    
    def _init_fast_model(self):
        """Initialize fast Gemma 3 model for simple scenarios"""
        try:
            from config.settings import settings
            if settings.GEMINI_API_KEY:
                self.fast_model = genai.GenerativeModel("gemma-2-2b-it")
                self.logger.info("✅ Fast model (Gemma 3) initialized for performance optimization")
        except Exception as e:
            self.logger.warning(f"Fast model initialization failed: {e}")
            self.fast_model = None
    
    def _calculate_complexity_score(self, context: Dict[str, Any]) -> float:
        """Calculate complexity score to determine optimal model (0.0 = simple, 1.0 = complex)"""
        try:
            complexity = 0.0
            
            # Game phase complexity (early game = simple, late game = complex)
            person_index = context.get("current_person", 1)
            phase_complexity = min(1.0, person_index / 500)  # 0.0 to 1.0
            complexity += phase_complexity * 0.3
            
            # Constraint deficit complexity
            constraints = context.get("constraints", [])
            if constraints:
                deficits = []
                for c in constraints:
                    deficit = c.get("minCount", 0) - context.get("current_state", {}).get("constraints", {}).get(c.get("attribute"), {}).get("admitted", 0)
                    deficits.append(max(0, deficit))
                
                max_deficit = max(deficits) if deficits else 0
                deficit_complexity = min(1.0, max_deficit / 300)  # Normalize to 0-1
                complexity += deficit_complexity * 0.4
            
            # Correlation complexity (negative correlations = more complex)
            correlations = context.get("correlations", {})
            correlation_complexity = 0.0
            for attr, corr_dict in correlations.items():
                for other_attr, corr_value in corr_dict.items():
                    if corr_value < -0.2:  # Strong negative correlation
                        correlation_complexity = min(1.0, correlation_complexity + 0.2)
            complexity += correlation_complexity * 0.3
            
            return min(1.0, complexity)
            
        except Exception as e:
            self.logger.warning(f"Complexity calculation failed: {e}")
            return 0.7  # Default to medium complexity
    
    def _should_enhance_with_llm(self, base_strategy: Dict[str, Any], context: Dict[str, Any]) -> Tuple[bool, str]:
        """Determine if strategy needs LLM enhancement based on confidence and complexity"""
        try:
            # Calculate game theory confidence
            constraints = context.get("constraints", [])
            if not constraints:
                return False, "no_constraints"
            
            # High confidence scenarios that don't need LLM enhancement
            person_index = context.get("current_person", 1)
            accepted_count = context.get("current_state", {}).get("slots_filled", 0)
            
            # Early game with clear constraints = high confidence
            if person_index < 200 and len(constraints) <= 2:
                return False, "early_game_simple"
            
            # Calculate deficit urgency
            total_deficit = 0
            for c in constraints:
                deficit = c.get("minCount", 0) - context.get("current_state", {}).get("constraints", {}).get(c.get("attribute"), {}).get("admitted", 0)
                total_deficit += max(0, deficit)
            
            slots_remaining = self.venue_capacity - accepted_count
            urgency_ratio = total_deficit / max(1, slots_remaining)
            
            # High confidence if we're comfortably meeting targets
            if urgency_ratio < 0.8:
                return False, "low_urgency"
            
            # Need LLM for complex scenarios
            complexity = self._calculate_complexity_score(context)
            if complexity > 0.6:
                return True, f"high_complexity_{complexity:.2f}"
            
            return True, "default_enhancement"
            
        except Exception as e:
            self.logger.warning(f"LLM enhancement decision failed: {e}")
            return True, "error_fallback"
    
    def _select_optimal_model(self, complexity_score: float) -> Tuple[Any, str]:
        """Select optimal model based on complexity score"""
        if not self.enable_smart_routing or not self.fast_model:
            return self.model, "gemini-2.0-flash-exp"
        
        if complexity_score < 0.3:  # Simple scenarios
            return self.fast_model, "gemma-2-2b-it"
        elif complexity_score < 0.7:  # Medium complexity - use fast Gemini
            return self.model, "gemini-2.0-flash-exp"  # Current model is actually fast
        else:  # Complex scenarios - use full power
            return self.model, "gemini-2.0-flash-exp"

    def _log_request(self):
        """Log request count per 20 minutes."""
        self.request_count += 1
        if time.time() - self.window_start >= 1200:  # 20 minutes
            self.logger.info(f"📊 {self.request_count} Gemini API requests in last 20 minutes")
            self.request_count = 0
            self.window_start = time.time()

    async def calculate_strategy(self, context, history, social, persona, safety) -> dict:
        # ... your logic ...
        # NOTE: You will need to adapt your existing logic to use these new
        # input dictionaries instead of a single AgentRequest object.
        # For a quick fix, you can just return a dummy value:
        return {"policy_type": "Fixed", "decision": "accept"}

    # Method expected by CloudStudentAgent orchestrator
    async def calculate_strategy(self, context, history, social, persona, safety) -> dict:
        """
        Calculates game theory strategy based on analysis results from other agents.
        This is the primary entry point for this agent from the orchestrator.
        """
        try:
            # Convert agent analysis results into a strategy
            strategy = {
                "policy_type": "Hybrid",
                "phase_switch_point": 400,
                "early_game_params": {
                    "base_leniency": 0.55,
                    "scaling_factor": 0.35
                },
                "late_game_params": {
                    "base_threshold": 0.45,
                    "buffer_percent": 0.1
                },
                "agent": "game_theory",
                "confidence": 0.85
            }
            
            # Incorporate analysis from other agents
            if isinstance(context, dict) and "confidence" in context:
                strategy["context_confidence"] = context["confidence"]
            if isinstance(history, dict) and "confidence" in history:
                strategy["history_confidence"] = history["confidence"]
            if isinstance(social, dict) and "confidence" in social:
                strategy["social_confidence"] = social["confidence"]
            if isinstance(persona, dict) and "confidence" in persona:
                strategy["persona_confidence"] = persona["confidence"]
            if isinstance(safety, dict) and "confidence" in safety:
                strategy["safety_confidence"] = safety["confidence"]
                
            return strategy
        except Exception as e:
            self.logger.error(f"GameTheoryAgent.calculate_strategy failed: {e}")
            return {
                "policy_type": "Fixed",
                "decision": "accept",
                "confidence": 0.1,
                "agent": "game_theory",
                "error": str(e)
            }

    async def _process_batch_logic(self, prompts: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """Process multiple prompts in a single Gemini API call."""
        if not token_bucket.acquire():
            self.logger.warning("⏳ Rate limit reached, waiting 6s")
            time.sleep(6)
        
        self._log_request()
        try:
            combined_prompt = "\n\n".join([json.dumps(p) for p in prompts])
            llm_response = await self.model.generate_content_async(combined_prompt)
            response_text = llm_response.candidates[0].content.parts[0].text
            responses = response_text.split("\n\n")
            strategies = []
            for resp in responses:
                json_start = resp.find('{')
                json_end = resp.rfind('}') + 1
                if json_start != -1 and json_end != -1:
                    strategy = json.loads(resp[json_start:json_end])
                    strategies.append(self._validate_strategy(strategy))
                else:
                    strategies.append(self._default_strategy(fallback_reason="Invalid LLM response format"))
            return strategies
        except Exception as e:
            self.logger.error(f"Batch processing failed: {e}", exc_info=True)
            return [self._default_strategy(fallback_reason=f"Batch error: {str(e)}") for _ in prompts]

    async def _process_agent_logic(self, request: AgentRequest, context: Dict[str, Any]) -> Tuple[str, float]:
        """
        OPTIMIZED Core game theory logic with caching and smart model selection
        Target: <1s response time, 40-60% cache hit rate
        Returns: (strategy_json_string, confidence_score)
        """
        optimization_start = time.time()
        try:
            # === PHASE 1: CACHE CHECK (Target: <50ms) ===
            if self.enable_cache:
                game_state = self._extract_game_state_for_cache(context)
                cached_strategy = strategy_cache.get_cached_strategy(game_state)
                if cached_strategy:
                    cache_time = (time.time() - optimization_start) * 1000
                    self.logger.info(f"🚀 CACHE HIT: {cache_time:.1f}ms - returning cached strategy")
                    confidence = self._calculate_agent_confidence(request)
                    return json.dumps(cached_strategy), confidence
            
            # === PHASE 2: GAME THEORY CALCULATION (Target: <10ms) ===
            # Extract game state
            constraints = context.get("constraints", [])
            frequencies = context.get("frequencies", {})
            correlations = context.get("correlations", {})
            state = context.get("current_state", {})
            slots_remaining = state.get("slots_remaining", self.venue_capacity)
            person_index = context.get("current_person", 1)

            # Game theory-based strategy
            deficits = {c["attribute"]: c["minCount"] - state.get("constraints", {}).get(c["attribute"], {}).get("admitted", 0) for c in constraints}
            max_deficit = max(deficits.values(), default=0) if deficits else 0
            phase_switch = 400 if person_index < 500 else 300
            leniency = 0.45 if max_deficit > slots_remaining * max(frequencies.values(), default=0.5) else 0.55
            threshold = 0.80 - (0.1 * (person_index / self.venue_capacity))  # Relax late-game
            buffer = 0.1  # 10% buffer

            # Correlation adjustment
            correlation_weight = 1.0
            for attr in deficits:
                for other_attr, corr in correlations.get(attr, {}).items():
                    if corr < -0.3:  # Prioritize negative correlations
                        correlation_weight += 0.05

            strategy = {
                "policy_type": "Hybrid",
                "phase_switch_point": phase_switch,
                "early_game_params": {
                    "base_leniency": leniency * correlation_weight,
                    "scaling_factor": 0.35
                },
                "late_game_params": {
                    # Drastically lower the threshold and make it more responsive to the game state
                    "base_threshold": max(0.35, threshold * 0.6), 
                    "buffer_percent": buffer
                }
            }

            # === PHASE 3: SMART LLM ENHANCEMENT (Target: <1s total) ===
            game_theory_time = (time.time() - optimization_start) * 1000
            
            # Determine if LLM enhancement is needed
            needs_enhancement, reason = self._should_enhance_with_llm(strategy, context)
            
            if self.model and needs_enhancement:
                try:
                    # Calculate complexity and select optimal model
                    complexity = self._calculate_complexity_score(context)
                    selected_model, model_name = self._select_optimal_model(complexity)
                    
                    # Rate limiting check
                    if not token_bucket.acquire():
                        self.logger.warning("⏳ Rate limit reached, waiting 6s")
                        time.sleep(6)
                    
                    self._log_request()
                    
                    # Optimized prompt (shorter for faster processing)
                    optimized_prompt = json.dumps({
                        "game_state": {
                            "person": person_index,
                            "constraints": constraints,
                            "deficits": deficits
                        },
                        "base_strategy": strategy,
                        "complexity": complexity
                    })
                    
                    llm_start = time.time()
                    llm_response = await selected_model.generate_content_async(optimized_prompt)
                    llm_time = (time.time() - llm_start) * 1000
                    
                    response_text = llm_response.candidates[0].content.parts[0].text
                    json_start = response_text.find('{')
                    json_end = response_text.rfind('}') + 1
                    if json_start != -1 and json_end != -1:
                        enhanced_strategy = json.loads(response_text[json_start:json_end])
                        strategy = enhanced_strategy
                        self.logger.info(f"✨ LLM enhanced ({model_name}): {llm_time:.1f}ms, complexity: {complexity:.2f}")
                    else:
                        self.logger.warning("Invalid LLM response format, using game theory strategy")
                        
                except Exception as e:
                    self.logger.warning(f"LLM enhancement failed ({reason}): {e}, using game theory strategy")
                    if isinstance(e, genai.types.generation_types.RateLimitError):
                        retry_after = getattr(e, 'retry_after', 45)
                        self.logger.warning(f"🚨 Gemini API quota exceeded, waiting {retry_after}s")
                        time.sleep(retry_after)
            else:
                self.logger.info(f"⚡ Skipped LLM enhancement: {reason} (game theory: {game_theory_time:.1f}ms)")

            # === PHASE 4: VALIDATION & CACHING ===
            strategy = self._validate_strategy(strategy)
            confidence = self._calculate_agent_confidence(request)
            
            # Cache the strategy for future use
            if self.enable_cache:
                game_state = self._extract_game_state_for_cache(context)
                strategy_cache.cache_strategy(game_state, strategy)
            
            # Performance logging
            total_time = (time.time() - optimization_start) * 1000
            self.logger.info(f"🏁 STRATEGY COMPLETE: {total_time:.1f}ms total")
            
            return json.dumps(strategy), confidence
            
        except Exception as e:
            self.logger.error(f"Strategy generation failed: {e}", exc_info=True)
            return json.dumps(self._default_strategy(fallback_reason=f"Generation error: {str(e)}")), 0.2

    def _validate_strategy(self, strategy: Dict[str, Any]) -> Dict[str, Any]:
        """Validate strategy structure using JSON schema."""
        schema = {
            "type": "object",
            "required": ["policy_type", "phase_switch_point", "early_game_params", "late_game_params"],
            "properties": {
                "policy_type": {"type": "string"},
                "phase_switch_point": {"type": "integer"},
                "early_game_params": {
                    "type": "object",
                    "required": ["base_leniency", "scaling_factor"],
                    "properties": {
                        "base_leniency": {"type": "number"},
                        "scaling_factor": {"type": "number"}
                    }
                },
                "late_game_params": {
                    "type": "object",
                    "required": ["base_threshold", "buffer_percent"],
                    "properties": {
                        "base_threshold": {"type": "number"},
                        "buffer_percent": {"type": "number"}
                    }
                }
            }
        }
        try:
            validate(instance=strategy, schema=schema)
            return strategy
        except ValidationError as e:
            self.logger.warning(f"Strategy validation failed: {e}")
            return self._default_strategy(fallback_reason=f"Validation error: {str(e)}")

    def _get_agent_specific_context(self, request: AgentRequest) -> Dict[str, Any]:
        """Extract game theory-specific context from the prompt."""
        try:
            prompt_data = json.loads(request.message) if request.message else {}
            constraints = prompt_data.get("constraints", [])
            frequencies = prompt_data.get("observedFrequencies", prompt_data.get("attributeStatistics", {}).get("relativeFrequencies", {}))
            correlations = prompt_data.get("attributeStatistics", {}).get("correlations", {})
            state = prompt_data.get("current_game_state", {})
            return {
                "constraints": constraints,
                "frequencies": frequencies,
                "correlations": correlations,
                "current_state": state,
                "current_person": state.get("slots_filled", 0) + 1,
                "timestamp": datetime.now().isoformat()
            }
        except json.JSONDecodeError as e:
            self.logger.error(f"Context extraction failed: {e}")
            return {"constraints": [], "frequencies": {}, "correlations": {}, "current_state": {}}

    def _calculate_agent_confidence(self, request: AgentRequest) -> float:
        """Calculate confidence based on game state."""
        try:
            context = self._get_agent_specific_context(request)
            constraints = context["constraints"]
            deficits = [c["minCount"] - context.get("current_state", {}).get("constraints", {}).get(c["attribute"], {}).get("admitted", 0) for c in constraints]
            max_deficit = max(deficits, default=0) if deficits else 0
            slots_remaining = context.get("current_state", {}).get("slots_remaining", self.venue_capacity)
            confidence = 0.8 if max_deficit <= slots_remaining * 0.5 else 0.5
            return min(0.95, max(0.3, confidence))
        except Exception as e:
            self.logger.warning(f"Confidence calculation failed: {e}")
            return 0.3

    def _default_strategy(self, fallback_reason: str) -> Dict[str, Any]:
        """Fallback strategy for error cases."""
        return {
            "policy_type": "Hybrid",
            "phase_switch_point": 400,
            "early_game_params": {"base_leniency": 0.55, "scaling_factor": 0.4},
            "late_game_params": {"base_threshold": 0.45, "buffer_percent": 0.1},
            "fallback_reason": fallback_reason,
            "_ooda_metadata": {
                "processing_time_ms": 0,
                "timestamp": datetime.now().isoformat(),
                "agent_version": "Fallback_Strategy",
                "mode": "emergency_fallback"
            }
        }
    def _extract_game_state_for_cache(self, context: Dict[str, Any]) -> Dict[str, Any]:
        """Extract normalized game state for cache key generation"""
        return {
            "current_person": context.get("current_person", 0),
            "accepted_count": context.get("current_state", {}).get("slots_filled", 0),
            "constraints": context.get("constraints", []),
            "observedFrequencies": context.get("frequencies", {}),
            "correlations": context.get("correlations", {})
        }
