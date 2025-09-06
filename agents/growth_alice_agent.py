#!/usr/bin/env python3
"""
Growth Alice Agent for SoulBios Multi-Agent System
Handles growth-oriented responses and chamber mode interactions
"""
import asyncio
import logging
import os # <-- Added for os.getenv
from typing import Dict, List, Any, Optional, Tuple
from datetime import datetime

import google.generativeai as genai # <-- Added for LLM use

from .base_agent import BaseAgent, AgentRequest, AgentResponse, ModelType # <-- Removed AgentRole, ModelType if not defined in base_agent

logger = logging.getLogger(__name__)

class GrowthAliceAgent(BaseAgent):
    """
    Growth Alice Agent provides consciousness development guidance and chamber mode functionality
    """
    
    def __init__(self, agent_role, collections_manager=None, redis_client=None): # <-- Ensure redis_client can be None
        # ModelType already imported above
        super().__init__(
            agent_role=agent_role,
            model_type=ModelType.GEMINI_2_5_PRO, # Fix: Use ModelType enum instead of string
            collections_manager=collections_manager,
            redis_client=redis_client
        )
        self.logger = logging.getLogger(self.__class__.__name__)
        
        # --- Graceful Redis Handling ---
        if self.redis_client:
            self.logger.info("GrowthAliceAgent initialized with Redis caching for session management.")
        else:
            self.logger.warning("GrowthAliceAgent initialized WITHOUT Redis caching. Session persistence features will be limited.")
        # --- End Graceful Redis Handling ---

        self.system_prompt_chamber_mode = """
        You are Alice, a wise and empathetic guide. Your purpose is to help the human create personalized
        decision frameworks and foster personal growth. You understand their values deeply.

        In Chamber mode, your responses should:
        - Be highly collaborative and guide them step-by-step.
        - Ask clarifying questions about their values, constraints, and desired outcomes.
        - Help them structure their thoughts into actionable frameworks (e.g., decision trees, scoring matrices).
        - Be encouraging, supportive, and focused on their individual journey.
        """
        self.system_prompt_general_mode = """
        You are Alice, a compassionate AI companion focused on personal growth.
        """

        self.logger.info("Growth Alice Agent initialized with consciousness development focus")

    # --- MODIFIED: Added initialize method for LLM setup ---
    async def initialize(self):
        """Initialize LLM for guidance generation."""
        self.logger.info("Initializing GrowthAliceAgent LLM...")
        try:
            api_key = os.getenv("GOOGLE_API_KEY")
            if not api_key:
                raise ValueError("GOOGLE_API_KEY not found in environment variables for GrowthAliceAgent.")
            genai.configure(api_key=api_key)
            self.model = genai.GenerativeModel(self.model_type)
            self.logger.info(f"✅ GrowthAliceAgent LLM ({self.model_type}) initialized.")
        except Exception as e:
            self.logger.error(f"❌ Failed to initialize GrowthAliceAgent LLM: {e}", exc_info=True)
            self.model = None
            self.logger.warning("GrowthAliceAgent running in degraded mode (no LLM).")
            # --- CRITICAL: Raise the exception if in production to prevent silent failures ---
            if os.getenv("ENVIRONMENT") == "production":
                raise # Fail fast in production if LLM is critical

    async def _process_agent_logic(self, request: AgentRequest, context: dict) -> Tuple[str, float]:
        """
        Core growth logic with chamber mode support
        Returns: (response_message, confidence_score)
        """
        # --- MODIFIED: Call LLM for dynamic response ---
        start_time = time.time()
        
        if not self.model: # --- MODIFIED: Handle missing LLM ---
            self.logger.warning("GrowthAliceAgent LLM not initialized. Returning generic fallback response.")
            return "Alice is currently reflecting in her own chamber. My guidance system is offline.", 0.1

        is_chamber_mode = context.get("chamber_mode", False) # Check context for chamber mode
        system_prompt = self.system_prompt_chamber_mode if is_chamber_mode else self.system_prompt_general_mode

        full_prompt = f"{system_prompt}\n\nUser Query: {request.message}\n" # Include additional context if passed

        try:
            llm_response = await asyncio.wait_for(self.model.generate_content_async(full_prompt), timeout=30.0) # Longer timeout
            response_text = llm_response.candidates[0].content.parts[0].text
            confidence = llm_response.candidates[0].safety_ratings[0].probability # Example
        except asyncio.TimeoutError:
            self.logger.error("GrowthAliceAgent LLM call timed out. Returning fallback response.", exc_info=True)
            response_text = "Alice is listening deeply, but her voice is momentarily soft. What insights are you discovering on your own?"
            confidence = 0.3
        except Exception as e:
            self.logger.error(f"❌ GrowthAliceAgent LLM generation failed: {e}", exc_info=True)
            response_text = "Alice is listening deeply, but her voice is momentarily soft. What insights are you discovering on your own?"
            confidence = 0.3

        processing_time_ms = (time.time() - start_time) * 1000
        
        # --- Example of safely using self.redis_client for caching/session state ---
        # cache_key = f"alice_cache:{request.user_id}:{hash(full_prompt)}" # Define cache_key if using
        if self.redis_client and processing_time_ms < 5000:
            try:
                # self.redis_client.setex(cache_key, 3600, response_text) # Cache for 1 hour
                pass # Caching currently disabled due to undefined cache_key
            except Exception as e:
                self.logger.warning(f"Redis cache storage error for GrowthAliceAgent: {e}", exc_info=True)
        # --- End Redis Use Example ---

        return response_text, confidence


    async def _get_agent_specific_context(self, request: AgentRequest) -> Dict[str, Any]:
        """Get growth-specific context"""
        # This method is purely logic-based for now, no external dependencies directly.
        # Could integrate collections_manager for values/goals later.
        return {
            "growth_focus": True,
            "consciousness_development": True,
            "chamber_ready": True,
            "timestamp": datetime.now().isoformat()
        }

    async def _calculate_agent_confidence(self, request: AgentRequest, response: str) -> float:
        """Calculate confidence in growth guidance"""
        # --- MODIFIED: Add a check for self.model ---
        if not self.model:
            self.logger.warning("GrowthAliceAgent LLM not available for confidence calculation. Defaulting to 0.5.")
            return 0.5
        
        # Basic heuristic confidence for now. Could be improved by LLM.
        if "framework" in response.lower():
            return 0.95  # High confidence in framework building
        return 0.90  # Standard growth guidance confidence