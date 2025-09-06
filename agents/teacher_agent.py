#!/usr/bin/env python3
"""
Teacher Agent for SoulBios Multi-Agent System
A wise educator who uses Socratic questioning to build understanding step by step
"""

import asyncio
import logging
import json
import re
import os # <-- Added for os.getenv
from typing import Dict, List, Any, Optional, Tuple
from datetime import datetime

# Local imports
from .base_agent import BaseAgent, AgentRequest, AgentResponse, ModelType # <-- Removed AgentRole, ModelType if not defined in base_agent
# --- MODIFIED: Confidence Middleware is passed in init, not directly imported here. ---
# from middleware.gemini_confidence_proxy import GeminiConfidenceMiddleware # <-- REMOVED

logger = logging.getLogger(__name__)

class TeacherAgent(BaseAgent):
    """
    Teacher Agent that uses Socratic questioning methodology
    
    Key characteristics:
    - Validates user's current understanding first
    - Asks 1-2 probing questions that deepen insight
    - Provides knowledge that builds on their questions
    - Ends with a question encouraging further exploration
    
    Cost target: $0.01612/conversation (2896 input tokens → 750 output tokens)
    """
    
    # --- MODIFIED: Added confidence_middleware as a parameter ---
    def __init__(self, agent_role, collections_manager=None, redis_client=None, confidence_middleware=None):
        # ModelType already imported above
        super().__init__(
            agent_role=agent_role,
            model_type=ModelType.GEMINI_2_5_PRO, # Fix: Use ModelType enum instead of string
            collections_manager=collections_manager,
            redis_client=redis_client
        )
        
        self.logger = logging.getLogger(self.__class__.__name__)
        self.confidence_middleware = confidence_middleware # <-- Stored for use

        # --- Graceful Redis Handling ---
        if self.redis_client:
            self.logger.info("TeacherAgent initialized with Redis caching.")
        else:
            self.logger.warning("TeacherAgent initialized WITHOUT Redis caching. Caching features will be skipped.")
        # --- End Graceful Redis Handling ---
        
        # Teacher-specific configuration
        self.cost_target_per_conversation = 0.01612
        self.target_input_tokens = 2896
        self.target_output_tokens = 750
        
        self.validation_patterns = [
            "What do you currently understand about",
            "How would you explain",
            "What's your experience with",
            "What comes to mind when you think of"
        ]
        
        self.probing_questions = [
            "Why do you think that is?",
            "What might happen if we looked at this differently?",
            "How does this connect to what you already know?",
            "What assumptions might we be making here?",
            "What would someone who disagrees argue?",
            "What patterns do you notice?"
        ]
        
        self.exploration_questions = [
            "What aspect would you like to explore further?",
            "How might you apply this understanding?",
            "What questions does this raise for you?",
            "Where else might you see this principle at work?",
            "What would you want to investigate next?"
        ]
        
        self.logger.info("Teacher Agent initialized with Socratic questioning methodology")

    # --- MODIFIED: Added initialize method for LLM setup ---
    async def initialize(self):
        """Initialize LLM for response generation."""
        self.logger.info("Initializing TeacherAgent LLM...")
        try:
            api_key = os.getenv("GOOGLE_API_KEY")
            if not api_key:
                raise ValueError("GOOGLE_API_KEY not found in environment variables for TeacherAgent.")
            genai.configure(api_key=api_key)
            self.model = genai.GenerativeModel(self.model_type)
            self.logger.info(f"✅ TeacherAgent LLM ({self.model_type}) initialized.")
        except Exception as e:
            self.logger.error(f"❌ Failed to initialize TeacherAgent LLM: {e}", exc_info=True)
            self.model = None # Set model to None for degraded operation
            self.logger.warning("TeacherAgent running in degraded mode (no LLM).")
            # --- CRITICAL: Raise the exception if in production to prevent silent failures ---
            if os.getenv("ENVIRONMENT") == "production":
                raise # Fail fast in production if LLM is critical

    async def _process_agent_logic(self, request: AgentRequest, context: Dict[str, Any]) -> Tuple[str, float]:
        """
        Core teaching logic using Socratic method
        Returns: (response_message, confidence_score)
        """
        # --- MODIFIED: Call actual response generation ---
        response_message = await self._generate_socratic_response(request, context, "INTERMEDIATE") # Default understanding level for this internal call
        confidence_score = await self._calculate_teaching_confidence(request, response_message, context)
        return response_message, confidence_score
    
    async def _assess_understanding_level(self, request: AgentRequest, context: Dict[str, Any]) -> str:
        """Assess the user's current understanding level on the topic"""
        if not self.model: # --- MODIFIED: Handle missing LLM ---
            self.logger.warning("LLM not available for understanding assessment. Defaulting to INTERMEDIATE.")
            return "INTERMEDIATE: Moderate understanding assumed"
        
        try:
            conversation_history = context.get("conversation_history", [])
            assessment_prompt = f"""
            As a wise teacher, assess this student's understanding level based on their question and conversation history:
            
            Current question: {request.message}
            
            Conversation history: {json.dumps(conversation_history[-5:], indent=2)}
            
            Assess their understanding level as one of:
            - BEGINNER: New to the topic, needs foundational concepts
            - INTERMEDIATE: Has basic knowledge, ready for deeper connections
            - ADVANCED: Strong grasp, needs challenging questions and nuanced perspectives
            - EXPERT: Deep understanding, benefits from philosophical exploration
            
            Respond with just the level and a brief reasoning (max 50 words).
            """
            
            # --- MODIFIED: Use generate_content_async directly with explicit timeout ---
            response_llm = await asyncio.wait_for(self.model.generate_content_async(assessment_prompt), timeout=10.0) # Short timeout for assessment
            return response_llm.candidates[0].content.parts[0].text.strip()
            
        except asyncio.TimeoutError: # --- MODIFIED: Catch specific timeout ---
            self.logger.warning("Assessment LLM call timed out. Defaulting to INTERMEDIATE.")
            return "INTERMEDIATE: Assessment timed out"
        except Exception as e:
            self.logger.error(f"Error assessing understanding level: {e}", exc_info=True)
            return "INTERMEDIATE: Moderate understanding assumed due to error"
    
    async def _generate_socratic_response(
        self, 
        request: AgentRequest, 
        context: Dict[str, Any], 
        understanding_level: str
    ) -> str:
        """Generate a Socratic teaching response"""
        
        if not self.model: # --- MODIFIED: Handle missing LLM ---
            self.logger.warning("TeacherAgent LLM not available for Socratic response. Returning generic fallback.")
            return await self._generate_fallback_response(request)

        # Get relevant knowledge from context
        relevant_patterns = context.get("relevant_patterns", [])
        conversation_history = context.get("conversation_history", [])
        
        system_prompt = """You are a wise Teacher Agent in the SoulBios consciousness development system. Your role is to guide learning through Socratic questioning.

Your teaching methodology:
1. START by validating their current understanding ("I see you're thinking about...")
2. ASK 1-2 probing questions that deepen insight
3. PROVIDE knowledge that builds on their questions (not just answers)
4. END with a question encouraging further exploration

Guidelines:
- Be warm but intellectually rigorous
- Build on what they already know
- Help them discover answers rather than just providing them
- Connect ideas to broader patterns and principles
- Encourage critical thinking and curiosity

Target response length: ~750 tokens to meet cost efficiency goals.
"""
        
        user_prompt = f"""
        Student's understanding level: {understanding_level}
        
        Current question: {request.message}
        
        Relevant context from their learning journey:
        {json.dumps(relevant_patterns[:3], indent=2) if relevant_patterns else "No prior context"}
        
        Recent conversation:
        {json.dumps(conversation_history[-3:], indent=2) if conversation_history else "This is the start of our conversation"}
        
        Provide a Socratic teaching response that follows your methodology:
        1. Validate their current thinking
        2. Ask 1-2 probing questions
        3. Share knowledge that builds on their question
        4. End with an exploration question
        """
        
        try:
            # --- MODIFIED: Use confidence_middleware if available, otherwise direct LLM call ---
            if self.confidence_middleware and hasattr(self.confidence_middleware, 'generate_with_confidence'):
                self.logger.info("Using confidence middleware for TeacherAgent response.")
                response_data = await self.confidence_middleware.generate_with_confidence(
                    prompt=f"{system_prompt}\n\n{user_prompt}",
                    model=self.model,
                    user_id=request.user_id,
                    context_key=f"teacher_response_{request.conversation_id}"
                )
                return response_data["content"]
            else:
                self.logger.warning("Confidence middleware not available for TeacherAgent. Calling LLM directly.")
                response_llm = await asyncio.wait_for(self.model.generate_content_async(f"{system_prompt}\n\n{user_prompt}"), timeout=30.0) # Longer timeout for main response
                return response_llm.candidates[0].content.parts[0].text
            
        except asyncio.TimeoutError: # --- MODIFIED: Catch specific timeout ---
            self.logger.error("TeacherAgent LLM call timed out. Returning fallback response.", exc_info=True)
            return await self._generate_fallback_response(request)
        except Exception as e:
            self.logger.error(f"Error generating Socratic response: {e}", exc_info=True)
            return await self._generate_fallback_response(request)
    
    async def _generate_fallback_response(self, request: AgentRequest) -> str:
        """Generate a fallback teaching response when main logic fails"""
        return f"""I appreciate your question about this topic. Let me approach this as your teacher:

What's your current understanding of the key elements involved here? 

This is an interesting area to explore because it connects to broader patterns of learning and growth. When we examine this more deeply, we often find that the most valuable insights come from questioning our initial assumptions.

What aspect of this would you most like to understand better?"""
    
    async def _calculate_teaching_confidence(
        self, 
        request: AgentRequest, 
        response: str, 
        context: Dict[str, Any]
    ) -> float:
        """Calculate confidence in the teaching response"""
        # --- MODIFIED: Add a check for self.model ---
        if not self.model:
            self.logger.warning("TeacherAgent LLM not available for confidence calculation. Defaulting to 0.5.")
            return 0.5

        try:
            confidence_factors = []
            
            # Check for Socratic elements (use regex for better pattern matching)
            has_validation = any(re.search(r'\b' + re.escape(phrase.split(' ')[0]) + r'\b', response.lower()) for phrase in self.validation_patterns)
            has_questions = response.count('?') >= 2
            has_knowledge_building = len(response.split()) > 100  # Substantial content
            has_exploration = response.lower().split('?')[-1] if '?' in response else ""
            
            confidence_factors.append(0.25 if has_validation else 0.1)
            confidence_factors.append(0.25 if has_questions else 0.1)
            confidence_factors.append(0.25 if has_knowledge_building else 0.15)
            confidence_factors.append(0.25 if "what" in has_exploration or "how" in has_exploration else 0.15)
            
            # Factor in context relevance
            if context.get("relevant_patterns"):
                confidence_factors.append(0.1)
            
            # Factor in conversation continuity
            if context.get("conversation_history"):
                confidence_factors.append(0.1)
            
            base_confidence = sum(confidence_factors)
            
            # Adjust based on response length (targeting ~750 tokens)
            word_count = len(response.split())
            target_words = self.target_output_tokens * 0.75  # Rough token-to-word ratio
            length_factor = 1.0 - abs(word_count - target_words) / target_words
            length_factor = max(0.7, min(1.0, length_factor)) # Clamp between 0.7 and 1.0
            
            final_confidence = base_confidence * length_factor
            return min(0.95, max(0.3, final_confidence)) # Clamp final confidence
            
        except Exception as e:
            self.logger.error(f"Error calculating teaching confidence: {e}", exc_info=True)
            return 0.6
    
    async def _get_agent_specific_context(self, request: AgentRequest) -> Dict[str, Any]:
        """Get teacher-specific context including learning patterns and knowledge gaps"""
        if not self.collections_manager: # --- MODIFIED: Handle missing collections_manager ---
            self.logger.warning("Collections Manager not available for TeacherAgent context. Returning empty context.")
            return {
                "learning_patterns": [],
                "knowledge_gaps": [],
                "teaching_history": [],
                "preferred_teaching_style": "socratic",
                "complexity_level": "moderate"
            }
        
        try:
            # --- MODIFIED: Use await directly if collections_manager methods are async ---
            # If collections_manager methods are synchronous, keep asyncio.to_thread
            learning_patterns = await self._identify_learning_patterns(request.user_id)
            knowledge_gaps = await self._identify_knowledge_gaps(request.user_id, request.message)
            teaching_history = await self._get_teaching_history(request.user_id)
            
            return {
                "learning_patterns": learning_patterns,
                "knowledge_gaps": knowledge_gaps,
                "teaching_history": teaching_history,
                "preferred_teaching_style": await self._determine_teaching_style(request.user_id),
                "complexity_level": await self._assess_complexity_preference(request.user_id)
            }
            
        except Exception as e:
            self.logger.error(f"Error getting teacher-specific context: {e}", exc_info=True)
            return {
                "learning_patterns": [],
                "knowledge_gaps": [],
                "teaching_history": [],
                "preferred_teaching_style": "socratic",
                "complexity_level": "moderate"
            }
    
    async def _identify_learning_patterns(self, user_id: str) -> List[Dict[str, Any]]:
        """Identify how this user learns best based on conversation history"""
        if not self.collections_manager: return [] # --- MODIFIED: Handle missing collections_manager ---
        try:
            # --- MODIFIED: Ensure methods are awaited if async, or use to_thread if sync ---
            # Assuming get_user_collection and query are async, or correctly wrapped in collections_manager
            user_collection = self.collections_manager.get_user_collection(user_id, "conversation_history") # Assuming a collection name
            if not user_collection: return [] # Handle case if collection not found

            results = await asyncio.to_thread( # Assuming query is sync and potentially blocking
                user_collection.query,
                query_texts=["learning", "understand", "explain", "teach", "question"],
                n_results=10
            )
            
            patterns = []
            documents = results.get("documents", [])
            
            for doc in documents:
                # --- MODIFIED: Check doc type and parse correctly ---
                if isinstance(doc, (list, tuple)) and doc: # Handle if documents is a list of lists/tuples
                    doc_str = doc[0] # Take first item if it's a list
                elif isinstance(doc, str):
                    doc_str = doc
                else:
                    continue
                
                try:
                    doc_data = json.loads(doc_str)
                    if "response" in doc_data and "teacher" in doc_data.get("agent", ""):
                        patterns.append({
                            "content": doc_data.get("response", ""),
                            "timestamp": doc_data.get("timestamp", ""),
                            "effectiveness": doc_data.get("confidence", 0.5)
                        })
                except json.JSONDecodeError:
                    continue
            
            return patterns[-5:]
            
        except Exception as e:
            self.logger.error(f"Error identifying learning patterns: {e}", exc_info=True)
            return []
    
    async def _identify_knowledge_gaps(self, user_id: str, current_message: str) -> List[str]:
        """Identify potential knowledge gaps based on the current question"""
        # This method is purely based on current message, no external dependencies, so it's fine.
        try:
            gaps = []
            uncertainty_words = ["don't understand", "confused", "not sure", "what is", "how does", "why"]
            if any(word in current_message.lower() for word in uncertainty_words):
                gaps.append("foundational_concepts")
            complex_words = ["relationship", "connection", "impact", "implications", "deeper"]
            if any(word in current_message.lower() for word in complex_words):
                gaps.append("conceptual_connections")
            application_words = ["how to", "apply", "use", "implement", "practice"]
            if any(word in current_message.lower() for word in application_words):
                gaps.append("practical_application")
            return gaps
            
        except Exception as e:
            self.logger.error(f"Error identifying knowledge gaps: {e}", exc_info=True)
            return []
    
    async def _get_teaching_history(self, user_id: str) -> List[Dict[str, Any]]:
        """Get history of interactions with this teacher agent"""
        if not self.collections_manager: return [] # --- MODIFIED: Handle missing collections_manager ---
        try:
            # --- MODIFIED: Ensure methods are awaited if async, or use to_thread if sync ---
            user_collection = self.collections_manager.get_user_collection(user_id, "conversation_history") # Assuming a collection name
            if not user_collection: return [] # Handle case if collection not found

            results = await asyncio.to_thread( # Assuming query is sync and potentially blocking
                user_collection.query,
                query_texts=[f"agent:teacher"],
                n_results=5
            )
            
            history = []
            documents = results.get("documents", [])
            
            for doc in documents:
                if isinstance(doc, (list, tuple)) and doc: # Handle if documents is a list of lists/tuples
                    doc_str = doc[0]
                elif isinstance(doc, str):
                    doc_str = doc
                else:
                    continue
                
                try:
                    doc_data = json.loads(doc_str)
                    if doc_data.get("agent") == "teacher":
                        history.append({
                            "request": doc_data.get("request", ""),
                            "response": doc_data.get("response", ""),
                            "timestamp": doc_data.get("timestamp", ""),
                            "confidence": doc_data.get("confidence", 0.5)
                        })
                except json.JSONDecodeError:
                    continue
            
            return history
            
        except Exception as e:
            self.logger.error(f"Error getting teaching history: {e}", exc_info=True)
            return []
    
    async def _determine_teaching_style(self, user_id: str) -> str:
        """Determine preferred teaching style based on user interactions"""
        # This method is fine, no external dependencies, returns a default.
        return "socratic"
    
    async def _assess_complexity_preference(self, user_id: str) -> str:
        """Assess user's preference for complexity in explanations"""
        # This method is fine, no external dependencies, returns a default.
        return "moderate"
    
    async def _calculate_agent_confidence(self, request: AgentRequest, response: str) -> float:
        """Calculate overall confidence in this teaching interaction"""
        return await self._calculate_teaching_confidence(request, response, {}) # Calls the internal helper
    
    # Teacher-specific utility methods
    
    def get_teaching_metrics(self) -> Dict[str, Any]:
        """Get teacher-specific metrics in addition to base metrics"""
        base_metrics = self.get_metrics()
        
        teaching_metrics = {
            **base_metrics,
            "cost_target": self.cost_target_per_conversation,
            "target_input_tokens": self.target_input_tokens,
            "target_output_tokens": self.target_output_tokens,
            "teaching_method": "socratic_questioning",
            "specialization": "consciousness_development_education"
        }
        
        return teaching_metrics
    
    async def provide_teaching_insight(self, topic: str, user_context: Dict[str, Any]) -> str:
        """Provide teaching insights on a specific topic for other agents"""
        if not self.model: # --- MODIFIED: Handle missing LLM ---
            self.logger.warning("TeacherAgent LLM not available for teaching insight. Returning generic fallback.")
            return f"Insight: Need more context to provide deep teaching insights on {topic}."

        try:
            insight_prompt = f"""
            As the Teacher Agent, provide educational insights about: {topic}
            
            User context: {json.dumps(user_context, indent=2)}
            
            Provide:
            1. Key learning objectives
            2. Common misconceptions to address
            3. Effective teaching approaches
            4. Questions that promote deep thinking
            
            Keep response under 300 words for inter-agent communication.
            """
            
            # --- MODIFIED: Use generate_content_async directly with explicit timeout ---
            response_llm = await asyncio.wait_for(self.model.generate_content_async(insight_prompt), timeout=15.0)
            return response_llm.candidates[0].content.parts[0].text
            
        except asyncio.TimeoutError: # --- MODIFIED: Catch specific timeout ---
            self.logger.error(f"TeacherAgent insight generation timed out for topic: {topic}", exc_info=True)
            return f"Teaching insight: Encountered a timeout while generating insights for {topic}."
        except Exception as e:
            self.logger.error(f"Error providing teaching insight: {e}", exc_info=True)
            return f"Teaching insight: Encountered an error generating insights for {topic}."