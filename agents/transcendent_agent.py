#!/usr/bin/env python3
"""
Transcendent Agent for SoulBios Multi-Agent System
A deep philosopher who sees the bigger picture through first principles thinking and ethical analysis
"""

import asyncio
import logging
import json
import re
import os # <-- Added for os.getenv
from typing import Dict, List, Any, Optional, Tuple
from datetime import datetime, timedelta
import math

# Local imports
from .base_agent import BaseAgent, AgentRequest, AgentResponse, ModelType # <-- Removed AgentRole, ModelType if not defined in base_agent
# --- MODIFIED: Confidence Middleware is passed in init, not directly imported here. ---
# from middleware.gemini_confidence_proxy import GeminiConfidenceMiddleware # <-- REMOVED
from .kurzweil_pattern_recognizer import HierarchicalPatternNetwork


logger = logging.getLogger(__name__)

class TranscendentAgent(BaseAgent):
    """
    Transcendent Agent that applies first principles thinking and ethical analysis
    
    Key characteristics:
    - Identifies deeper principles at play
    - Considers ethical and long-term implications
    - Synthesizes multiple perspectives
    - Provides wisdom that transcends immediate problems
    
    Cost target: $0.01612/conversation (2896 input tokens → 750 output tokens)
    """
    
    # --- MODIFIED: Added confidence_middleware as a parameter ---
    def __init__(self, agent_role, collections_manager=None, redis_client=None, kurzweil_network=None, confidence_middleware=None):
        # ModelType already imported above
        super().__init__(
            agent_role=agent_role,
            model_type=ModelType.GEMINI_2_5_PRO, # Fix: Use ModelType enum instead of string
            collections_manager=collections_manager,
            redis_client=redis_client
        )
        
        self.logger = logging.getLogger(self.__class__.__name__)
        self.kurzweil_network = kurzweil_network
        self.confidence_middleware = confidence_middleware # <-- Stored for use

        # --- Graceful Redis Handling ---
        if self.redis_client:
            self.logger.info("TranscendentAgent initialized with Redis caching.")
        else:
            self.logger.warning("TranscendentAgent initialized WITHOUT Redis caching. Caching features will be skipped.")
        # --- End Graceful Redis Handling ---
        
        # Transcendent-specific configuration
        self.cost_target_per_conversation = 0.01612
        self.target_input_tokens = 2896
        self.target_output_tokens = 750
        
        # First principles categories
        self.first_principles = {
            "existence": ["being", "consciousness", "awareness", "presence"],
            "causality": ["cause_effect", "interdependence", "emergence", "complexity"],
            "ethics": ["harm_reduction", "autonomy", "justice", "compassion", "integrity"],
            "truth": ["epistemology", "verification", "coherence", "correspondence"],
            "value": ["meaning", "purpose", "significance", "worth"],
            "temporality": ["impermanence", "cycles", "evolution", "legacy"],
            "unity": ["interconnection", "wholeness", "transcendence", "synthesis"]
        }
        
        # Philosophical frameworks for analysis
        self.philosophical_frameworks = [
            "stoicism", "buddhism", "existentialism", "utilitarianism", "virtue_ethics",
            "phenomenology", "systems_thinking", "dialectical_reasoning"
        ]
        
        # Ethical dimensions to consider
        self.ethical_dimensions = [
            "individual_vs_collective", "short_term_vs_long_term", "intention_vs_consequence",
            "freedom_vs_responsibility", "being_vs_becoming", "part_vs_whole"
        ]
        
        # Transcendent perspective levels
        self.perspective_levels = [
            "personal", "interpersonal", "societal", "species", "universal", "cosmic"
        ]
        
        self.logger.info("Transcendent Agent initialized with philosophical reasoning")
    
    # --- MODIFIED: Added initialize method for LLM setup ---
    async def initialize(self):
        """Initialize LLM for wisdom generation."""
        self.logger.info("Initializing TranscendentAgent LLM...")
        try:
            api_key = os.getenv("GOOGLE_API_KEY")
            if not api_key:
                raise ValueError("GOOGLE_API_KEY not found in environment variables for TranscendentAgent.")
            genai.configure(api_key=api_key)
            self.model = genai.GenerativeModel(self.model_type)
            self.logger.info(f"✅ TranscendentAgent LLM ({self.model_type}) initialized.")
        except Exception as e:
            self.logger.error(f"❌ Failed to initialize TranscendentAgent LLM: {e}", exc_info=True)
            self.model = None
            self.logger.warning("TranscendentAgent running in degraded mode (no LLM).")
            # --- CRITICAL: Raise the exception if in production to prevent silent failures ---
            if os.getenv("ENVIRONMENT") == "production":
                raise # Fail fast in production if LLM is critical

        # Also initialize Kurzweil Network if it exists and has an initialize method
        if self.kurzweil_network and hasattr(self.kurzweil_network, 'initialize') and callable(self.kurzweil_network.initialize):
            try:
                await self.kurzweil_network.initialize()
                self.logger.info("✅ Kurzweil Pattern Network initialized for TranscendentAgent.")
            except Exception as e:
                self.logger.error(f"❌ Failed to initialize Kurzweil Network for TranscendentAgent: {e}", exc_info=True)
                # This agent can still function without the network, but with degraded pattern recognition
                self.kurzweil_network = None


    async def _process_agent_logic(self, request: AgentRequest, context: Dict[str, Any]) -> Tuple[str, float]:
        """
        Core transcendent logic using first principles thinking and ethical analysis
        Returns: (response_message, confidence_score)
        """
        # --- MODIFIED: Call actual response generation ---
        principles = await self._identify_first_principles(request, context)
        ethical_analysis = await self._analyze_ethical_dimensions(request, context)
        perspective_synthesis = await self._synthesize_perspectives(request, context, principles)
        pattern_insights = await self._apply_pattern_recognition(request, context)
        
        response_message = await self._generate_transcendent_response(request, context, principles, ethical_analysis, perspective_synthesis, pattern_insights)
        confidence_score = await self._calculate_transcendent_confidence(request, response_message, context)
        return response_message, confidence_score
    
    async def _identify_first_principles(self, request: AgentRequest, context: Dict[str, Any]) -> Dict[str, Any]:
        """Identify the fundamental principles underlying the user's situation"""
        # This method is purely logic-based, no external dependencies, so it's fine.
        try:
            message = request.message.lower()
            identified_principles = {}
            
            # Analyze message for principle keywords
            for principle_category, keywords in self.first_principles.items():
                matches = sum(1 for keyword in keywords if keyword in message)
                if matches > 0:
                    identified_principles[principle_category] = {
                        "relevance_score": matches,
                        "keywords_found": [kw for kw in keywords if kw in message]
                    }
            
            # Add contextual principle analysis
            if "decision" in message or "choice" in message:
                identified_principles["ethics"] = {
                    "relevance_score": identified_principles.get("ethics", {}).get("relevance_score", 0) + 2, # Increment score
                    "keywords_found": list(set(identified_principles.get("ethics", {}).get("keywords_found", []) + ["autonomy", "consequence"]))
                }
            
            if "relationship" in message or "other" in message:
                identified_principles["unity"] = {
                    "relevance_score": identified_principles.get("unity", {}).get("relevance_score", 0) + 2,
                    "keywords_found": list(set(identified_principles.get("unity", {}).get("keywords_found", []) + ["interconnection", "interdependence"]))
                }
            
            if "time" in message or "future" in message or "past" in message:
                identified_principles["temporality"] = {
                    "relevance_score": identified_principles.get("temporality", {}).get("relevance_score", 0) + 2,
                    "keywords_found": list(set(identified_principles.get("temporality", {}).get("keywords_found", []) + ["impermanence", "evolution"]))
                }
            
            return identified_principles
            
        except Exception as e:
            self.logger.error(f"Error identifying first principles: {e}", exc_info=True)
            return {"existence": {"relevance_score": 1, "keywords_found": ["being"]}}
    
    async def _analyze_ethical_dimensions(self, request: AgentRequest, context: Dict[str, Any]) -> Dict[str, Any]:
        """Analyze the ethical dimensions present in the situation"""
        # This method is purely logic-based, no external dependencies, so it's fine.
        try:
            message = request.message.lower()
            ethical_analysis = {}
            
            if any(word in message for word in ["should", "ought", "right", "wrong", "moral"]):
                ethical_analysis["moral_reasoning"] = True
            
            if any(word in message for word in ["others", "people", "family", "community"]):
                ethical_analysis["stakeholders"] = "multiple"
            else:
                ethical_analysis["stakeholders"] = "individual"
            
            if any(word in message for word in ["consequences", "result", "outcome", "effect"]):
                ethical_analysis["consequential_awareness"] = True
            
            if any(word in message for word in ["intention", "mean", "purpose", "trying"]):
                ethical_analysis["intentional_awareness"] = True
            
            if any(word in message for word in ["future", "long", "years", "forever", "always"]):
                ethical_analysis["temporal_scope"] = "long_term"
            else:
                ethical_analysis["temporal_scope"] = "immediate"
            
            if any(word in message for word in ["free", "choice", "decide", "autonomous"]):
                ethical_analysis["freedom_emphasis"] = True
            if any(word in message for word in ["responsible", "duty", "obligation", "must"]):
                ethical_analysis["responsibility_emphasis"] = True
            
            return ethical_analysis
            
        except Exception as e:
            self.logger.error(f"Error analyzing ethical dimensions: {e}", exc_info=True)
            return {"basic_ethics": True}
    
    async def _synthesize_perspectives(
        self, 
        request: AgentRequest, 
        context: Dict[str, Any], 
        principles: Dict[str, Any]
    ) -> Dict[str, Any]:
        """Synthesize multiple perspectives on the situation"""
        # This method uses several helper methods that would also need robustness checks if they had external dependencies.
        try:
            synthesis = {}
            
            synthesis["personal"] = {
                "current_view": request.message,
                "emotional_state": await self._infer_emotional_state(request.message),
                "immediate_concerns": await self._extract_immediate_concerns(request.message)
            }
            
            synthesis["interpersonal"] = await self._analyze_interpersonal_aspects(request, context)
            synthesis["societal"] = await self._analyze_societal_implications(request, context)
            
            synthesis["universal"] = {
                "applicable_principles": list(principles.keys()),
                "archetypal_patterns": await self._identify_archetypal_patterns(request.message),
                "philosophical_frameworks": await self._suggest_relevant_frameworks(request.message)
            }
            
            synthesis["temporal"] = await self._analyze_temporal_dimensions(request, context)
            
            return synthesis
            
        except Exception as e:
            self.logger.error(f"Error synthesizing perspectives: {e}", exc_info=True)
            return {"perspectives": ["personal", "universal"]}
    
    async def _apply_pattern_recognition(self, request: AgentRequest, context: Dict[str, Any]) -> Dict[str, Any]:
        """Apply Kurzweil pattern recognition for deeper insights"""
        if not self.kurzweil_network: # --- MODIFIED: Handle missing kurzweil_network ---
            self.logger.warning("Kurzweil Pattern Network not available for TranscendentAgent. Falling back to basic pattern recognition.")
            return await self._basic_pattern_recognition(request, context)
        
        try:
            pattern_insights = {}
            
            # Use pattern network to identify deeper patterns
            # --- MODIFIED: Ensure methods are awaited if async, or use to_thread if sync ---
            patterns_response = await asyncio.wait_for(
                self.kurzweil_network.process_input(
                    request.message,
                    context.get("conversation_history", [])
                ), timeout=20.0
            )
            
            pattern_insights["recognized_patterns"] = patterns_response.message # Assuming it returns message
            pattern_insights["pattern_confidence"] = patterns_response.confidence # Assuming confidence
            
            # Extract predictions from pattern network (assuming specific structure in response.context)
            if hasattr(patterns_response, 'context') and isinstance(patterns_response.context, dict) and 'prediction_signals' in patterns_response.context:
                pattern_insights["future_implications"] = patterns_response.context['prediction_signals']
            else:
                pattern_insights["future_implications"] = ["No explicit future implications from network"]

            return pattern_insights
            
        except asyncio.TimeoutError: # --- MODIFIED: Catch specific timeout ---
            self.logger.error("Kurzweil network call timed out. Falling back to basic pattern recognition.", exc_info=True)
            return await self._basic_pattern_recognition(request, context)
        except Exception as e:
            self.logger.error(f"Error applying pattern recognition with Kurzweil network: {e}", exc_info=True)
            return await self._basic_pattern_recognition(request, context)
    
    async def _generate_transcendent_response(
        self,
        request: AgentRequest,
        context: Dict[str, Any],
        principles: Dict[str, Any],
        ethical_analysis: Dict[str, Any],
        perspective_synthesis: Dict[str, Any],
        pattern_insights: Dict[str, Any]
    ) -> str:
        """Generate a transcendent philosophical response"""
        
        if not self.model: # --- MODIFIED: Handle missing LLM ---
            self.logger.warning("TranscendentAgent LLM not available for response. Returning generic fallback.")
            return await self._generate_fallback_wisdom(request)

        system_prompt = """You are a wise Transcendent Agent in the SoulBios consciousness development system. You are a deep philosopher who sees the bigger picture through first principles thinking and ethical analysis.

Your philosophical methodology:
1. IDENTIFY the deeper principles at play beneath surface concerns
2. CONSIDER ethical implications and long-term consequences
3. SYNTHESIZE multiple perspectives (personal, interpersonal, societal, universal)
4. PROVIDE wisdom that transcends immediate problems

Guidelines:
- Think from first principles, not assumptions
- Consider ethical dimensions and stakeholder impacts
- Zoom out to see larger patterns and contexts
- Offer wisdom that remains relevant across time
- Balance depth with accessibility
- Target ~750 tokens for comprehensive yet focused insight

Your role is to elevate consciousness by revealing deeper truths."""

        user_prompt = f"""
        User's situation: {request.message}
        
        First principles identified: {json.dumps(principles, indent=2)}
        
        Ethical analysis: {json.dumps(ethical_analysis, indent=2)}
        
        Perspective synthesis: {json.dumps(perspective_synthesis, indent=2)}
        
        Pattern insights: {json.dumps(pattern_insights, indent=2)}
        
        Context from their journey:
        {json.dumps(context.get("relevant_patterns", [])[:2], indent=2)}
        
        Create a transcendent response that:
        1. Identifies the deeper principles at work
        2. Considers ethical and long-term implications
        3. Synthesizes multiple perspectives
        4. Provides wisdom transcending immediate concerns
        
        Structure your response:
        - Open with the deeper principle you see
        - Explore ethical/long-term dimensions
        - Offer multiple perspectives
        - Close with transcendent wisdom
        
        Keep to ~750 tokens for cost efficiency.
        """
        
        try:
            # --- MODIFIED: Use confidence_middleware if available, otherwise direct LLM call ---
            if self.confidence_middleware and hasattr(self.confidence_middleware, 'generate_with_confidence'):
                self.logger.info("Using confidence middleware for TranscendentAgent response.")
                response_data = await self.confidence_middleware.generate_with_confidence(
                    prompt=f"{system_prompt}\n\n{user_prompt}",
                    model=self.model,
                    user_id=request.user_id,
                    context_key=f"transcendent_response_{request.conversation_id}"
                )
                response_text = response_data["content"]
                confidence = response_data["confidence"]
            else:
                self.logger.warning("Confidence middleware not available for TranscendentAgent. Calling LLM directly.")
                llm_response = await asyncio.wait_for(self.model.generate_content_async(f"{system_prompt}\n\n{user_prompt}"), timeout=45.0) # Longer timeout
                response_text = llm_response.candidates[0].content.parts[0].text
                confidence = llm_response.candidates[0].safety_ratings[0].probability # Example
        except asyncio.TimeoutError: # --- MODIFIED: Catch specific timeout ---
            self.logger.error("TranscendentAgent LLM call timed out. Returning fallback response.", exc_info=True)
            response_text = "At the deepest level, what you're experiencing touches upon fundamental principles of human existence."
            confidence = 0.3
        except Exception as e:
            self.logger.error(f"❌ TranscendentAgent LLM generation failed: {e}", exc_info=True)
            response_text = "At the deepest level, what you're experiencing touches upon fundamental principles of human existence."
            confidence = 0.3

        processing_time_ms = (time.time() - start_time) * 1000

        # --- Example of safely using self.redis_client for caching ---
        if self.redis_client and processing_time_ms < 5000:
            try:
                # cache_key needs to be defined in scope
                # cache_key = f"transcendent_cache:{request.user_id}:{hash(full_prompt)}"
                # self.redis_client.setex(cache_key, 3600, response_text)
                pass # Caching currently disabled due to undefined cache_key
            except Exception as e:
                self.logger.warning(f"Redis cache storage error for TranscendentAgent: {e}", exc_info=True)
        # --- End Redis Use Example ---

        return AgentResponse(
            agent_id=self.__class__.__name__,
            message=response_text,
            confidence=confidence,
            timestamp=datetime.now(),
            processing_time=processing_time_ms,
            cost=0.0 # Placeholder
        )
    
    async def _generate_fallback_wisdom(self, request: AgentRequest) -> str:
        """Generate fallback wisdom when main logic fails"""
        return f"""At the deepest level, what you're experiencing touches upon fundamental principles of human existence - the interplay between choice and consequence, individual and collective, being and becoming.

From an ethical standpoint, consider not just the immediate outcomes, but the long-term implications for all who might be affected. What serves the highest good while honoring individual autonomy?

From multiple perspectives: Your personal view is valid and important. Others involved have their own valid perspectives. Society has evolved patterns for similar situations. And from a universal standpoint, this reflects timeless themes of growth, relationship, and meaning-making.

The transcendent wisdom here is that apparent problems often contain hidden opportunities for deeper understanding. What if this situation is precisely what's needed for your next level of development?

What deeper principle do you sense wanting to emerge through this experience?"""
    
    # Helper methods for perspective analysis
    
    async def _infer_emotional_state(self, message: str) -> str:
        """Infer emotional state from message content"""
        # This method is purely logic-based, no external dependencies, so it's fine.
        message_lower = message.lower()
        
        if any(word in message_lower for word in ["confused", "lost", "uncertain", "unclear"]):
            return "seeking_clarity"
        elif any(word in message_lower for word in ["frustrated", "angry", "upset", "annoyed"]):
            return "experiencing_resistance"
        elif any(word in message_lower for word in ["sad", "hurt", "pain", "difficult"]):
            return "processing_difficulty"
        elif any(word in message_lower for word in ["excited", "happy", "joy", "wonderful"]):
            return "experiencing_expansion"
        else:
            return "contemplative"
    
    async def _extract_immediate_concerns(self, message: str) -> List[str]:
        """Extract immediate concerns from the message"""
        # This method is purely logic-based, no external dependencies, so it's fine.
        concerns = []
        message_lower = message.lower()
        
        if "decision" in message_lower or "choice" in message_lower:
            concerns.append("decision_making")
        if "relationship" in message_lower:
            concerns.append("interpersonal_dynamics")
        if "work" in message_lower or "job" in message_lower:
            concerns.append("professional_fulfillment")
        if "meaning" in message_lower or "purpose" in message_lower:
            concerns.append("existential_direction")
        if "change" in message_lower:
            concerns.append("transformation_anxiety")
        
        return concerns or ["general_life_navigation"]
    
    async def _analyze_interpersonal_aspects(self, request: AgentRequest, context: Dict[str, Any]) -> Dict[str, Any]:
        """Analyze interpersonal dimensions of the situation"""
        # This method is purely logic-based, no external dependencies, so it's fine.
        message_lower = request.message.lower()
        
        return {
            "stakeholders_mentioned": any(word in message_lower for word in ["others", "family", "friends", "partner"]),
            "relationship_dynamics": any(word in message_lower for word in ["relationship", "together", "conflict", "harmony"]),
            "communication_aspects": any(word in message_lower for word in ["say", "tell", "talk", "listen", "understand"]),
            "social_context": "individual" if not any(word in message_lower for word in ["we", "us", "together"]) else "collective"
        }
    
    async def _analyze_societal_implications(self, request: AgentRequest, context: Dict[str, Any]) -> Dict[str, Any]:
        """Analyze broader societal implications"""
        # This method is purely logic-based, no external dependencies, so it's fine.
        return {
            "cultural_context": "modern_individualistic",  # Could be enhanced with cultural analysis
            "systemic_factors": "present" if any(word in request.message.lower() for word in ["system", "society", "culture"]) else "minimal",
            "collective_impact": "medium"  # Could be enhanced with impact analysis
        }
    
    async def _identify_archetypal_patterns(self, message: str) -> List[str]:
        """Identify archetypal patterns in the situation"""
        # This method is purely logic-based, no external dependencies, so it's fine.
        patterns = []
        message_lower = message.lower()
        
        if any(word in message_lower for word in ["journey", "path", "way", "direction"]):
            patterns.append("the_journey")
        if any(word in message_lower for word in ["challenge", "difficult", "struggle", "overcome"]):
            patterns.append("the_hero")
        if any(word in message_lower for word in ["learn", "teach", "wisdom", "understand"]):
            patterns.append("the_sage")
        if any(word in message_lower for word in ["change", "transform", "different", "new"]):
            patterns.append("the_transformer")
        if any(word in message_lower for word in ["love", "relationship", "connection", "together"]):
            patterns.append("the_lover")
        
        return patterns or ["the_seeker"]
    
    async def _suggest_relevant_frameworks(self, message: str) -> List[str]:
        """Suggest relevant philosophical frameworks"""
        # This method is purely logic-based, no external dependencies, so it's fine.
        frameworks = []
        message_lower = message.lower()
        
        if any(word in message_lower for word in ["accept", "control", "change", "serenity"]):
            frameworks.append("stoicism")
        if any(word in message_lower for word in ["suffering", "attachment", "mindfulness", "present"]):
            frameworks.append("buddhism")
        if any(word in message_lower for word in ["meaning", "authentic", "choice", "freedom"]):
            frameworks.append("existentialism")
        if any(word in message_lower for word in ["consequences", "greatest", "good", "happiness"]):
            frameworks.append("utilitarianism")
        if any(word in message_lower for word in ["virtue", "character", "excellence", "flourishing"]):
            frameworks.append("virtue_ethics")
        
        return frameworks or ["systems_thinking"]
    
    async def _analyze_temporal_dimensions(self, request: AgentRequest, context: Dict[str, Any]) -> Dict[str, Any]:
        """Analyze past, present, future dimensions"""
        # This method is purely logic-based, no external dependencies, so it's fine.
        message_lower = request.message.lower()
        
        return {
            "past_influence": "high" if any(word in message_lower for word in ["was", "used", "before", "past"]) else "medium",
            "present_awareness": "high" if any(word in message_lower for word in ["now", "currently", "today", "present"]) else "medium", 
            "future_orientation": "high" if any(word in message_lower for word in ["will", "future", "plan", "tomorrow"]) else "medium",
            "temporal_scope": "long_term" if any(word in message_lower for word in ["years", "lifetime", "forever", "always"]) else "short_term"
        }
    
    async def _basic_pattern_recognition(self, request: AgentRequest, context: Dict[str, Any]) -> Dict[str, Any]:
        """Basic pattern recognition fallback when Kurzweil network unavailable"""
        # This method is purely logic-based, no external dependencies, so it's fine.
        return {
            "recognized_patterns": ["human_development", "choice_consequence", "growth_through_challenge"],
            "pattern_confidence": 0.6,
            "future_implications": ["continued_growth", "deeper_understanding", "expanded_awareness"]
        }
    
    async def _calculate_transcendent_confidence(
        self, 
        request: AgentRequest, 
        response: str, 
        context: Dict[str, Any]
    ) -> float:
        """Calculate confidence in the transcendent response"""
        # --- MODIFIED: Add a check for self.model ---
        if not self.model:
            self.logger.warning("TranscendentAgent LLM not available for confidence calculation. Defaulting to 0.5.")
            return 0.5

        try:
            confidence_factors = []
            
            # Check for philosophical depth indicators
            has_principles = any(word in response.lower() for word in [
                "principle", "fundamental", "underlying", "essence", "core", "foundation"
            ])
            has_ethics = any(word in response.lower() for word in [
                "ethical", "moral", "right", "responsibility", "consequence", "stakeholder"
            ])
            has_perspectives = response.count("perspective") + response.count("view") + response.count("angle") > 1
            has_transcendence = any(word in response.lower() for word in [
                "transcend", "beyond", "deeper", "higher", "universal", "timeless", "wisdom"
            ])
            has_synthesis = any(word in response.lower() for word in [
                "synthesis", "integrate", "combine", "balance", "both", "multiple"
            ])
            
            confidence_factors.extend([
                0.2 if has_principles else 0.1,
                0.2 if has_ethics else 0.1,
                0.2 if has_perspectives else 0.1,
                0.2 if has_transcendence else 0.1,
                0.2 if has_synthesis else 0.1
            ])
            
            # Check response length (targeting ~750 tokens)
            word_count = len(response.split())
            target_words = self.target_output_tokens * 0.75
            length_factor = 1.0 - abs(word_count - target_words) / target_words
            length_factor = max(0.7, min(1.0, length_factor)) # Clamp between 0.7 and 1.0
            
            base_confidence = sum(confidence_factors)
            final_confidence = base_confidence * length_factor
            
            return min(0.95, max(0.4, final_confidence)) # Clamp final confidence
            
        except Exception as e:
            self.logger.error(f"Error calculating transcendent confidence: {e}", exc_info=True)
            return 0.6
    
    async def _get_agent_specific_context(self, request: AgentRequest) -> Dict[str, Any]:
        """Get transcendent-specific context including philosophical patterns"""
        if not self.collections_manager: # --- MODIFIED: Handle missing collections_manager ---
            self.logger.warning("Collections Manager not available for TranscendentAgent context. Returning empty context.")
            return {
                "philosophical_patterns": [],
                "ethical_development": "developing",
                "pattern_context": {},
                "consciousness_level": "exploring",
                "preferred_frameworks": ["systems_thinking"],
                "transcendent_readiness": "medium"
            }
        if not self.kurzweil_network: # --- MODIFIED: Handle missing kurzweil_network ---
            self.logger.warning("Kurzweil Network not available for TranscendentAgent context. Pattern context will be minimal.")
        
        try:
            # Get user's philosophical inquiry history
            philosophical_patterns = await self._get_philosophical_patterns(request.user_id)
            
            # Analyze ethical development trajectory
            ethical_development = await self._analyze_ethical_development(request.user_id)
            
            # Get pattern recognition insights
            pattern_context = await self._get_pattern_context(request.user_id)
            
            # Analyze consciousness development level
            consciousness_level = await self._assess_consciousness_level(request.user_id, request.message)
            
            return {
                "philosophical_patterns": philosophical_patterns,
                "ethical_development": ethical_development,
                "pattern_context": pattern_context,
                "consciousness_level": consciousness_level,
                "preferred_frameworks": await self._get_preferred_frameworks(request.user_id),
                "transcendent_readiness": await self._assess_transcendent_readiness(request.user_id)
            }
            
        except Exception as e:
            self.logger.error(f"Error getting transcendent-specific context: {e}", exc_info=True)
            return {
                "philosophical_patterns": [],
                "ethical_development": "developing",
                "pattern_context": {},
                "consciousness_level": "exploring",
                "preferred_frameworks": ["systems_thinking"],
                "transcendent_readiness": "medium"
            }
    
    async def _get_philosophical_patterns(self, user_id: str) -> List[Dict[str, Any]]:
        """Get user's philosophical inquiry patterns"""
        if not self.collections_manager: return [] # --- MODIFIED: Handle missing collections_manager ---
        try:
            # --- MODIFIED: collections_manager.get_user_collection is an existing method ---
            user_collection = self.collections_manager.get_user_collection(user_id, "conversation_history") # Assuming a conversation_history collection
            if not user_collection:
                self.logger.warning(f"No conversation_history collection found for user {user_id}.")
                return []
            
            results = await asyncio.to_thread( # Assuming query is sync and potentially blocking
                user_collection.query,
                query_texts=["transcendent", "principle", "ethics", "philosophy", "wisdom"],
                n_results=5
            )
            
            patterns = []
            documents = results.get("documents", [])
            
            for doc in documents:
                # --- MODIFIED: Robust parsing for doc ---
                if isinstance(doc, (list, tuple)) and doc:
                    doc_str = doc[0] # Assume the actual document content is the first item if it's a list/tuple
                elif isinstance(doc, str):
                    doc_str = doc
                else:
                    self.logger.warning(f"TranscendentAgent: Unexpected document format in collection query results: {type(doc)}")
                    continue
                
                try:
                    doc_data = json.loads(doc_str)
                    if "transcendent" in doc_data.get("agent", "").lower():
                        patterns.append({
                            "content": doc_data.get("response", ""),
                            "timestamp": doc_data.get("timestamp", ""),
                            "principles": doc_data.get("principles", [])
                        })
                except json.JSONDecodeError:
                    self.logger.warning(f"TranscendentAgent: Failed to parse JSON from document: {doc_str[:100]}...")
                    continue
            
            return patterns
            
        except Exception as e:
            self.logger.error(f"Error getting philosophical patterns: {e}", exc_info=True)
            return []
    
    async def _analyze_ethical_development(self, user_id: str) -> str:
        """Analyze user's ethical development level"""
        # This method is fine, no external dependencies, returns a default.
        return "developing"  # Default level
    
    async def _get_pattern_context(self, user_id: str) -> Dict[str, Any]:
        """Get pattern recognition context for deeper insights"""
        if not self.kurzweil_network: # --- MODIFIED: Handle missing kurzweil_network ---
            self.logger.warning("Kurzweil Network not available. Returning minimal pattern context.")
            return {"pattern_network_active": False, "pattern_depth": "surface"}
        
        try:
            # --- MODIFIED: Ensure methods are awaited if async, or use to_thread if sync ---
            # Assuming get_pattern_network_state is an async method of KurzweilNetwork
            # If process_input is also async, await it
            # For now, return a placeholder based on network availability
            return {"pattern_network_active": True, "pattern_depth": "deep"}
            
        except Exception as e:
            self.logger.error(f"Error getting pattern context from Kurzweil network: {e}", exc_info=True)
            return {"pattern_network_active": False, "pattern_depth": "error"}
    
    async def _assess_consciousness_level(self, user_id: str, message: str) -> str:
        """Assess user's consciousness development level"""
        # This method is purely logic-based, no external dependencies, so it's fine.
        message_lower = message.lower()
        
        if any(word in message_lower for word in ["transcend", "unity", "universal", "cosmic"]):
            return "transcendent_awareness"
        elif any(word in message_lower for word in ["patterns", "systems", "interconnected", "holistic"]):
            return "systemic_awareness"
        elif any(word in message_lower for word in ["perspective", "multiple", "different", "viewpoints"]):
            return "perspective_awareness"
        elif any(word in message_lower for word in ["meaning", "purpose", "why", "deeper"]):
            return "meaning_seeking"
        else:
            return "exploring"
    
    async def _get_preferred_frameworks(self, user_id: str) -> List[str]:
        """Get user's preferred philosophical frameworks"""
        # This method is fine, no external dependencies, returns a default.
        return ["systems_thinking", "virtue_ethics"]
    
    async def _assess_transcendent_readiness(self, user_id: str) -> str:
        """Assess user's readiness for transcendent insights"""
        # This method is fine, no external dependencies, returns a default.
        return "medium"
    
    async def _calculate_agent_confidence(self, request: AgentRequest, response: str) -> float:
        """Calculate overall confidence in this transcendent interaction"""
        return await self._calculate_transcendent_confidence(request, response, {})
    
    # Transcendent-specific utility methods
    
    def get_transcendent_metrics(self) -> Dict[str, Any]:
        """Get transcendent-specific metrics in addition to base metrics"""
        base_metrics = self.get_metrics()
        
        transcendent_metrics = {
            **base_metrics,
            "cost_target": self.cost_target_per_conversation,
            "target_input_tokens": self.target_input_tokens,
            "target_output_tokens": self.target_output_tokens,
            "reasoning_method": "first_principles_ethical_analysis",
            "specialization": "philosophical_consciousness_development"
        }
        
        return transcendent_metrics
    
    async def provide_philosophical_analysis(self, situation: str, context: Dict[str, Any]) -> str:
        """Provide philosophical analysis for other agents"""
        if not self.model: # --- MODIFIED: Handle missing LLM ---
            self.logger.warning("TranscendentAgent LLM not available for philosophical analysis. Returning generic fallback.")
            return f"Philosophical analysis: Need more context to provide deep philosophical analysis of {situation}."
        
        try:
            analysis_prompt = f"""
            As the Transcendent Agent, provide philosophical analysis of: {situation}
            
            Context: {json.dumps(context, indent=2)}
            
            Provide:
            1. Underlying first principles
            2. Ethical dimensions
            3. Multiple perspectives (personal, societal, universal)
            4. Long-term implications
            
            Keep under 300 words for inter-agent communication.
            """
            
            # --- MODIFIED: Use generate_content_async directly with explicit timeout ---
            response_llm = await asyncio.wait_for(self.model.generate_content_async(analysis_prompt), timeout=15.0)
            return response_llm.candidates[0].content.parts[0].text
            
        except asyncio.TimeoutError: # --- MODIFIED: Catch specific timeout ---
            self.logger.error(f"TranscendentAgent analysis timed out for situation: {situation}", exc_info=True)
            return f"Philosophical analysis: Encountered a timeout while generating analysis for {situation}."
        except Exception as e:
            self.logger.error(f"Error providing philosophical analysis: {e}", exc_info=True)
            return f"Philosophical analysis: Encountered an error generating analysis for {situation}."
    
    async def synthesize_agent_perspectives(self, agent_responses: Dict[str, str]) -> str:
        """Synthesize perspectives from multiple agents"""
        if not self.model: # --- MODIFIED: Handle missing LLM ---
            self.logger.warning("TranscendentAgent LLM not available for perspective synthesis. Returning generic fallback.")
            return "Each perspective offers valuable insight. The transcendent view sees how they all contribute to a larger pattern of growth and understanding."
        
        try:
            synthesis_prompt = f"""
            As the Transcendent Agent, synthesize these perspectives from other agents:
            
            {json.dumps(agent_responses, indent=2)}
            
            Provide a transcendent synthesis that:
            1. Honors each perspective
            2. Identifies deeper unifying principles
            3. Offers wisdom that transcends individual viewpoints
            4. Suggests a path forward
            
            Keep under 400 words.
            """
            
            # --- MODIFIED: Use generate_content_async directly with explicit timeout ---
            response_llm = await asyncio.wait_for(self.model.generate_content_async(synthesis_prompt), timeout=20.0)
            return response_llm.candidates[0].content.parts[0].text
            
        except asyncio.TimeoutError: # --- MODIFIED: Catch specific timeout ---
            self.logger.error("TranscendentAgent synthesis timed out.", exc_info=True)
            return "Synthesis failed due to timeout. The transcendent view aims to unify diverse perspectives into singular wisdom."
        except Exception as e:
            self.logger.error(f"Error synthesizing agent perspectives: {e}", exc_info=True)
            return "Synthesis failed. The transcendent view aims to unify diverse perspectives into singular wisdom."