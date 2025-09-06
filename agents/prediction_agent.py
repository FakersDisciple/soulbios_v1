#!/usr/bin/env python3
"""
Prediction Agent for SoulBios
Forecasts future possibilities and timelines based on user patterns.
"""

import asyncio
from typing import Dict, List, Any, Tuple

from .base_agent import BaseAgent, AgentRole, AgentRequest, ModelType

class PredictionAgent(BaseAgent):
    """Forecasts potential timelines and outcomes based on user patterns."""

    def __init__(self, **kwargs):
        super().__init__(
            agent_role=AgentRole.PREDICTION,
            model_type=ModelType.GEMINI_2_5_PRO, # Needs strong reasoning
            **kwargs
        )

    async def _process_agent_logic(self, request: AgentRequest, context: Dict[str, Any]) -> Tuple[str, float]:
        """Core logic for generating predictions and timelines."""
        self.logger.info(f"Generating predictions for user {request.user_id}")

        # Extract patterns from the broader context provided by the orchestrator
        relevant_patterns = context.get("relevant_patterns", [])
        meta_pattern_insights = context.get("previous_agent_responses", {}).get("meta_pattern", "")

        if not relevant_patterns and not meta_pattern_insights:
            return "Insufficient data to generate a forecast. More interaction is needed to understand your trajectory.", 0.2

        formatted_context = self._format_context_for_prompt(request.message, relevant_patterns, meta_pattern_insights)

        prompt = f"""You are a Prediction Agent.
Your task is to analyze a user's current situation, their life patterns, and identified meta-patterns to forecast potential future timelines and outcomes. 
Do not give advice. Instead, outline potential paths and possibilities based on the data provided.

Here is the user's current context:
{formatted_context}

Based on this, generate a concise forecast. Consider the following:
1.  **Short-Term (Next few weeks/months):** What might unfold if the current patterns continue?
2.  **Long-Term (Next year+):** What are the potential long-term trajectories or major choice points?
3.  **Key Variables:** What are the key internal (e.g., mindset) or external factors that could significantly alter this forecast?

Present this as a set of potential scenarios, not as certainties. Use phrases like 'One possible path is...', 'Another possibility could be...', 'A key factor to watch is...'.
"""

        try:
            response = await asyncio.to_thread(
                self.model.generate_content,
                prompt
            )
            prediction = response.text
            confidence = self._calculate_confidence_from_response(prediction, len(relevant_patterns))
            return prediction, confidence
        except Exception as e:
            self.logger.error(f"Gemini API error during prediction: {e}")
            return "I encountered an issue while trying to map out potential futures.", 0.2

    def _format_context_for_prompt(self, message: str, patterns: List[str], meta_patterns: str) -> str:
        """Formats the context into a string for the prompt."""
        formatted_str = f"**Current Situation:** {message}\n"
        if patterns:
            formatted_str += "\n**Relevant Life Patterns:**\n"
            for p in patterns:
                formatted_str += f"- {p}\n"
        if meta_patterns:
            formatted_str += f"\n**Identified Meta-Patterns:**\n{meta_patterns}"
        
        return formatted_str

    def _calculate_confidence_from_response(self, response_text: str, num_patterns: int) -> float:
        """Calculate confidence based on the response and number of source patterns."""
        confidence = 0.4 # Base confidence for a speculative task

        if "potential" in response_text.lower() and "scenario" in response_text.lower():
            confidence += 0.2
        
        if num_patterns > 3:
            confidence += 0.2
            
        return min(1.0, confidence)

    async def _get_agent_specific_context(self, request: AgentRequest) -> Dict[str, Any]:
        """Prediction agent relies on context passed from the orchestrator."""
        return {"status": "Awaiting pattern data from orchestrator."}

    async def _calculate_agent_confidence(self, request: AgentRequest, response: str) -> float:
        """Confidence is calculated within the main logic."""
        return 0.7 # Placeholder
