#!/usr/bin/env python3
"""
Meta-Pattern Agent for SoulBios
Analyzes existing patterns to identify higher-order insights and meta-patterns.
"""

import asyncio
from typing import Dict, List, Any, Tuple

from .base_agent import BaseAgent, AgentRole, AgentRequest, ModelType

class MetaPatternAgent(BaseAgent):
    """Analyzes patterns across a user's history to find meta-patterns."""

    def __init__(self, **kwargs):
        super().__init__(
            agent_role=AgentRole.META_PATTERN,
            model_type=ModelType.GEMINI_2_5_PRO, # Use a powerful model for analysis
            **kwargs
        )

    async def _process_agent_logic(self, request: AgentRequest, context: Dict[str, Any]) -> Tuple[str, float]:
        """Core logic for identifying meta-patterns."""
        self.logger.info(f"Searching for meta-patterns for user {request.user_id}")
        
        try:
            patterns_collection = self.collections_manager.get_user_collection(request.user_id, "life_patterns")
            all_patterns = await asyncio.to_thread(patterns_collection.get, include=["documents", "metadatas"])
        except Exception as e:
            self.logger.error(f"Could not retrieve patterns for user {request.user_id}: {e}")
            return "Could not access life patterns to analyze them.", 0.1

        if not all_patterns or not all_patterns["documents"]:
            return "No life patterns found to analyze. More interaction is needed to establish patterns.", 0.3

        # We need a certain number of patterns to find a meta-pattern
        if len(all_patterns["documents"]) < 5:
            return f"Found {len(all_patterns['documents'])} patterns. More interaction is needed to identify meta-patterns.", 0.4

        formatted_patterns = self._format_patterns_for_prompt(all_patterns)
        
        prompt = f"""You are a meta-pattern analysis agent.
Your task is to identify higher-order patterns (meta-patterns) from a given list of life patterns for a user.
Analyze the following patterns and identify 1-3 meta-patterns that connect them.
A meta-pattern is a pattern about other patterns (e.g., a recurring theme of 'avoidance of conflict' might connect patterns of 'procrastination on difficult conversations' and 'people-pleasing').

Here are the user's life patterns:
{formatted_patterns}

Based on this, what are the core meta-patterns? For each meta-pattern, provide a name, a brief description, and which of the life patterns it connects.
Be concise and insightful.
"""

        try:
            response = await asyncio.to_thread(
                self.model.generate_content, 
                prompt
            )
            meta_pattern_insights = response.text
            confidence = self._calculate_confidence_from_response(meta_pattern_insights, len(all_patterns["documents"]))
            return meta_pattern_insights, confidence
        except Exception as e:
            self.logger.error(f"Gemini API error during meta-pattern analysis: {e}")
            return "I encountered an issue while analyzing the deeper connections in your patterns.", 0.2

    def _format_patterns_for_prompt(self, patterns: Dict[str, List[Any]]) -> str:
        """Formats the retrieved patterns into a string for the prompt."""
        formatted_list = []
        for i, doc in enumerate(patterns["documents"]):
            metadata = patterns["metadatas"][i]
            pattern_name = metadata.get("pattern_name", f"Unnamed Pattern {i+1}")
            description = doc
            formatted_list.append(f"- **{pattern_name}**: {description}")
        return "\n".join(formatted_list)

    def _calculate_confidence_from_response(self, response_text: str, num_patterns: int) -> float:
        """Calculate confidence based on the quality of the response and number of source patterns."""
        confidence = 0.5  # Base confidence

        if "meta-pattern" in response_text.lower() and len(response_text) > 50:
            confidence += 0.2
        
        # More source patterns allow for higher confidence
        if num_patterns > 10:
            confidence += 0.2
        elif num_patterns > 5:
            confidence += 0.1
            
        return min(1.0, confidence)

    async def _get_agent_specific_context(self, request: AgentRequest) -> Dict[str, Any]:
        """Meta-Pattern agent does not require additional specific context."""
        return {"status": "Context is derived from existing life patterns."}

    async def _calculate_agent_confidence(self, request: AgentRequest, response: str) -> float:
        """Confidence is calculated within the main logic, so we just return a pre-calculated value if available."""
        # This is a simplified approach. In a real scenario, we might re-evaluate.
        return 0.8 # Placeholder
