import asyncio
import logging
import time
import json
from datetime import datetime
from typing import Dict, Any, Optional, Tuple
from .base_agent import BaseAgent, AgentRequest, AgentResponse, ModelType
from .context_agent import ContextAgent
from .history_agent import HistoryAgent
from .social_agent import SocialAgent
from .persona_agent import PersonaAgent
from .safety_agent import SafetyAgent
from .game_theory_agent import GameTheoryAgent
from .meta_agent import MetaAgent
from tenacity import retry, stop_after_attempt, wait_exponential
from fastapi import HTTPException

logger = logging.getLogger(__name__)

class CloudStudentAgent(BaseAgent):
    """
    The orchestrator agent, managing the flow of requests between specialized agents
    for the Berghain Challenge.
    """

    def __init__(self,
                 agent_role,
                 collections_manager=None,
                 redis_client=None,
                 context_agent: Optional[ContextAgent] = None,
                 history_agent: Optional[HistoryAgent] = None,
                 social_agent: Optional[SocialAgent] = None,
                 persona_agent: Optional[PersonaAgent] = None,
                 safety_agent: Optional[SafetyAgent] = None,
                 game_theory_agent: Optional[GameTheoryAgent] = None,
                 meta_agent: Optional[MetaAgent] = None):
        super().__init__(agent_role=agent_role, model_type=ModelType.GEMINI_2_5_PRO,
                        collections_manager=collections_manager, redis_client=redis_client)
        self.logger = logging.getLogger(self.__class__.__name__)
        self.context_agent = context_agent
        self.history_agent = history_agent
        self.social_agent = social_agent
        self.persona_agent = persona_agent
        self.safety_agent = safety_agent
        self.game_theory_agent = game_theory_agent
        self.meta_agent = meta_agent

    @retry(stop=stop_after_attempt(3), wait=wait_exponential(multiplier=1, min=2, max=10))
    async def process_request(self, request: AgentRequest) -> AgentResponse:
        """
        🎯 OPTIMAL BERGHAIN PIPELINE - Ultra-High Performance Multi-Agent Strategic Processing
        
        Implements maximum parallel processing across all 5 analysis agents simultaneously,
        then feeds combined intelligence into game theory and meta-optimization layers.
        
        Target: Sub-500ms total processing time for competitive advantage.
        """
        start_time = time.time()
        
        try:
            game_state = json.loads(request.message)
        except json.JSONDecodeError as e:
            self.logger.error(f"Invalid JSON in request: {e}")
            raise HTTPException(status_code=400, detail=f"Invalid game state JSON: {e}")

        # 🚀 PHASE 1-3: MAXIMUM PARALLEL ANALYSIS - All agents fire simultaneously
        self.logger.info("🔥 LAUNCHING: Optimal Berghain Pipeline - 5-Agent Parallel Analysis")
        
        analysis_tasks = {
            "context": self.context_agent.extract_features(game_state),
            "history": self.history_agent.analyze_patterns(game_state.get("observedFrequencies", [])),
            "social": self.social_agent.assess_crowd_dynamics(game_state),
            "persona": self.persona_agent.model_current_person(game_state.get("current_person", {})),
            "safety": self.safety_agent.check_constraints(game_state.get("constraints", []))
        }
        
        # Execute all analysis agents in perfect parallel - maximum concurrency
        analysis_start = time.time()
        analysis_results = await asyncio.gather(*analysis_tasks.values(), return_exceptions=True)
        analysis_time_ms = (time.time() - analysis_start) * 1000
        
        # Process results with enhanced error handling and performance tracking
        analysis_outputs = {}
        successful_agents = 0
        for agent_name, result in zip(analysis_tasks.keys(), analysis_results):
            if isinstance(result, Exception):
                self.logger.error(f"❌ {agent_name} agent failed: {result}")
                analysis_outputs[agent_name] = {"error": str(result), "fallback": True}
            else:
                analysis_outputs[agent_name] = result
                successful_agents += 1
                
        self.logger.info(f"⚡ Parallel Analysis Complete: {analysis_time_ms:.1f}ms ({successful_agents}/5 agents successful)")

        # 🎯 PHASE 4: COORDINATED GAME THEORY SYNTHESIS
        game_theory_start = time.time()
        game_theory_strategy = await self.game_theory_agent.calculate_strategy(
            analysis_outputs.get("context", {}),
            analysis_outputs.get("history", {}),
            analysis_outputs.get("social", {}),
            analysis_outputs.get("persona", {}),
            analysis_outputs.get("safety", {})
        )
        game_theory_time_ms = (time.time() - game_theory_start) * 1000
        self.logger.info(f"🧠 Game Theory Synthesis: {game_theory_time_ms:.1f}ms")

        # 🌟 PHASE 5: META-OPTIMIZATION & FINAL STRATEGY SYNTHESIS  
        meta_start = time.time()
        final_strategy = await self.meta_agent.optimize_strategy(
            game_theory_strategy,
            list(analysis_outputs.values())
        )
        meta_time_ms = (time.time() - meta_start) * 1000
        self.logger.info(f"✨ Meta-Optimization: {meta_time_ms:.1f}ms")

        # Performance analytics and success metrics
        processing_time_ms = (time.time() - start_time) * 1000
        
        # Enhanced performance logging with breakdown
        performance_breakdown = {
            "parallel_analysis_ms": round(analysis_time_ms, 1),
            "game_theory_ms": round(game_theory_time_ms, 1), 
            "meta_optimization_ms": round(meta_time_ms, 1),
            "total_processing_ms": round(processing_time_ms, 1),
            "parallel_efficiency": round((analysis_time_ms / (analysis_time_ms * 5)) * 100, 1),
            "successful_agents": successful_agents
        }
        
        success_emoji = "🏆" if processing_time_ms < 500 else "⚡" if processing_time_ms < 1000 else "✅"
        self.logger.info(f"{success_emoji} OPTIMAL BERGHAIN PIPELINE COMPLETE: {processing_time_ms:.1f}ms total | Breakdown: {performance_breakdown}")

        # Enhanced strategy response with performance metadata
        final_strategy.update({
            "_pipeline_performance": performance_breakdown,
            "_confidence_multiplier": min(1.0, successful_agents / 5.0),  # Confidence based on agent success rate
            "_processing_timestamp": datetime.now().isoformat(),
            "_pipeline_version": "OptimalBerghainPipeline_v2.0_UltraParallel"
        })

        return AgentResponse(
            agent_id=self.__class__.__name__,
            message=json.dumps(final_strategy),
            confidence=min(0.98, 0.85 + (successful_agents / 5.0) * 0.13),  # Dynamic confidence scoring
            timestamp=datetime.now(),
            processing_time=processing_time_ms,
            cost=0.0,  # Cost calculation can be implemented here
            context_updates={},
            metadata=performance_breakdown,
            context={"performance": performance_breakdown, "agents_successful": successful_agents}
        )

    # BaseAgent abstract method implementations
    async def _process_agent_logic(self, request: AgentRequest, context: Dict[str, Any]) -> Tuple[str, float]:
        """
        Core orchestration logic - delegates to the existing process_request method
        """
        try:
            response = await self.process_request(request)
            return response.message, response.confidence
        except Exception as e:
            self.logger.error(f"Orchestration failed: {e}")
            return json.dumps({"error": "orchestration_failed", "fallback": True}), 0.1

    def _get_agent_specific_context(self, request: AgentRequest) -> Dict[str, Any]:
        """
        The orchestrator's context is the main context, no additional context needed
        """
        return request.context

    def _calculate_agent_confidence(self, request: AgentRequest) -> float:
        """
        The orchestrator's confidence is an aggregate of its subordinate agents
        Returns high confidence as the orchestrator coordinates multiple specialized agents
        """
        return 0.95