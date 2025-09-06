#!/usr/bin/env python3
"""
Narrative Agent for SoulBios Multi-Agent System
A wise storyteller who finds meaning through narrative, metaphors, and universal themes
"""

import asyncio
import logging
import json
import re
import os # <-- Added for os.getenv
from typing import Dict, List, Any, Optional, Tuple
from datetime import datetime
import random

# Local imports
from .base_agent import BaseAgent, AgentRequest, AgentResponse, ModelType # <-- Removed AgentRole, ModelType if not defined in base_agent
from .character_playbook_manager import CharacterPlaybookManager
# --- MODIFIED: Confidence Middleware is passed in init, not directly imported here. ---
# from middleware.gemini_confidence_proxy import GeminiConfidenceMiddleware # <-- REMOVED

logger = logging.getLogger(__name__)

class NarrativeAgent(BaseAgent):
    """
    Narrative Agent that uses storytelling and metaphors to illuminate truth
    
    Key characteristics:
    - Finds the story within the user's situation
    - Uses metaphors and analogies that illuminate truth
    - Connects experiences to universal human themes
    - Creates memorable insights through narrative structure
    
    Cost target: $0.00013/conversation (300 input tokens → 250 output tokens)
    """
    
    # --- MODIFIED: Added confidence_middleware as a parameter ---
    def __init__(self, agent_role, collections_manager=None, redis_client=None, character_manager=None, confidence_middleware=None):
        # ModelType already imported above
        super().__init__(
            agent_role=agent_role,
            model_type=ModelType.GEMMA_3, # Fix: Use ModelType enum instead of string
            collections_manager=collections_manager,
            redis_client=redis_client
        )
        
        self.logger = logging.getLogger(self.__class__.__name__)
        self.character_manager = character_manager
        self.confidence_middleware = confidence_middleware # <-- Stored for use
        
        # --- Graceful Redis Handling ---
        if self.redis_client:
            self.logger.info("NarrativeAgent initialized with Redis caching.")
        else:
            self.logger.warning("NarrativeAgent initialized WITHOUT Redis caching. Caching features will be skipped.")
        # --- End Graceful Redis Handling ---
        
        # Narrative-specific configuration
        self.cost_target_per_conversation = 0.00013
        self.target_input_tokens = 300
        self.target_output_tokens = 250
        
        # Universal narrative themes and archetypes
        self.universal_themes = [
            "the_hero_journey", "transformation", "overcoming_obstacles", "finding_purpose",
            "inner_wisdom", "connection", "growth_through_challenge", "self_discovery",
            "the_mentor_guide", "crossing_thresholds", "return_with_wisdom", "cycles_of_life"
        ]
        
        # Metaphor categories for different situations
        self.metaphor_categories = {
            "growth": ["seed_to_tree", "caterpillar_butterfly", "river_to_ocean", "diamond_formation"],
            "challenge": ["mountain_climbing", "storm_navigation", "forge_and_fire", "maze_exploration"],
            "relationship": ["dance_partners", "garden_tending", "bridge_building", "symphony_creation"],
            "learning": ["treasure_hunting", "map_making", "lighthouse_following", "key_collecting"],
            "healing": ["wound_to_scar", "winter_to_spring", "broken_bone_strength", "phoenix_rising"],
            "purpose": ["compass_finding", "star_navigation", "river_following", "calling_answering"]
        }
        
        # Narrative structures for different response types
        self.story_structures = [
            "situation_complication_resolution",
            "before_during_after",
            "problem_journey_wisdom",
            "question_exploration_insight",
            "metaphor_parallel_meaning"
        ]
        
        self.logger.info("Narrative Agent initialized with storytelling methodology")
    
    # --- MODIFIED: Added initialize method for LLM setup ---
    async def initialize(self):
        """Initialize LLM for narrative generation."""
        self.logger.info("Initializing NarrativeAgent LLM...")
        try:
            api_key = os.getenv("GOOGLE_API_KEY")
            if not api_key:
                raise ValueError("GOOGLE_API_KEY not found in environment variables for NarrativeAgent.")
            genai.configure(api_key=api_key)
            self.model = genai.GenerativeModel(self.model_type)
            self.logger.info(f"✅ NarrativeAgent LLM ({self.model_type}) initialized.")
        except Exception as e:
            self.logger.error(f"❌ Failed to initialize NarrativeAgent LLM: {e}", exc_info=True)
            self.model = None
            self.logger.warning("NarrativeAgent running in degraded mode (no LLM).")
            # --- CRITICAL: Raise the exception if in production to prevent silent failures ---
            if os.getenv("ENVIRONMENT") == "production":
                raise # Fail fast in production if LLM is critical

    async def _process_agent_logic(self, request: AgentRequest, context: Dict[str, Any]) -> Tuple[str, float]:
        """
        Core narrative logic using storytelling and metaphors
        Returns: (response_message, confidence_score)
        """
        # --- MODIFIED: Call actual response generation ---
        theme = await self._identify_narrative_theme(request, context)
        story_elements = await self._select_story_elements(request, theme, context)
        response_message = await self._generate_narrative_response(request, context, theme, story_elements)
        confidence_score = await self._calculate_narrative_confidence(request, response_message, context)
        return response_message, confidence_score
    
    async def _identify_narrative_theme(self, request: AgentRequest, context: Dict[str, Any]) -> str:
        """Identify the underlying narrative theme in the user's situation"""
        # This method is purely logic-based, no external dependencies, so it's fine.
        try:
            message = request.message.lower()
            
            # Theme detection patterns
            theme_patterns = {
                "the_hero_journey": ["challenge", "struggle", "overcome", "difficult", "journey"],
                "transformation": ["change", "different", "becoming", "evolving", "growth"],
                "overcoming_obstacles": ["stuck", "blocked", "problem", "barrier", "difficulty"],
                "finding_purpose": ["meaning", "purpose", "direction", "calling", "path"],
                "inner_wisdom": ["intuition", "feeling", "sense", "inner", "wisdom"],
                "connection": ["relationship", "together", "connect", "community", "love"],
                "self_discovery": ["who am i", "identity", "self", "discover", "understand"]
            }
            
            # Score themes based on keyword matches
            theme_scores = {}
            for theme, keywords in theme_patterns.items():
                score = sum(1 for keyword in keywords if keyword in message)
                if score > 0:
                    theme_scores[theme] = score
            
            # Return highest scoring theme, or default
            if theme_scores:
                return max(theme_scores.items(), key=lambda x: x[1])[0]
            else:
                return "self_discovery"  # Default theme
                
        except Exception as e:
            self.logger.error(f"Error identifying narrative theme: {e}", exc_info=True)
            return "transformation" # Fallback on error
    
    async def _select_story_elements(
        self, 
        request: AgentRequest, 
        theme: str, 
        context: Dict[str, Any]
    ) -> Dict[str, Any]:
        """Select appropriate metaphors and story elements for the response"""
        # This method is purely logic-based, no external dependencies, so it's fine.
        try:
            # Determine metaphor category based on request content
            message = request.message.lower()
            metaphor_category = "growth"  # default
            
            if any(word in message for word in ["difficult", "hard", "struggle", "challenge"]):
                metaphor_category = "challenge"
            elif any(word in message for word in ["relationship", "friend", "family", "partner"]):
                metaphor_category = "relationship"
            elif any(word in message for word in ["learn", "understand", "know", "study"]):
                metaphor_category = "learning"
            elif any(word in message for word in ["hurt", "pain", "heal", "recovery"]):
                metaphor_category = "healing"
            elif any(word in message for word in ["purpose", "meaning", "direction", "goal"]):
                metaphor_category = "purpose"
            
            # Select specific metaphors from category
            available_metaphors = self.metaphor_categories.get(metaphor_category, ["journey"])
            selected_metaphor = random.choice(available_metaphors)
            
            # Select narrative structure
            structure = random.choice(self.story_structures)
            
            return {
                "theme": theme,
                "metaphor_category": metaphor_category,
                "selected_metaphor": selected_metaphor,
                "structure": structure,
                "tone": "wise_compassionate"
            }
            
        except Exception as e:
            self.logger.error(f"Error selecting story elements: {e}", exc_info=True)
            return { # Fallback on error
                "theme": theme,
                "metaphor_category": "growth",
                "selected_metaphor": "seed_to_tree",
                "structure": "situation_complication_resolution",
                "tone": "wise_compassionate"
            }
    
    async def _generate_narrative_response(
        self, 
        request: AgentRequest, 
        context: Dict[str, Any],
        theme: str,
        story_elements: Dict[str, Any]
    ) -> str:
        """Generate a narrative response using storytelling techniques"""
        
        if not self.model: # --- MODIFIED: Handle missing LLM ---
            self.logger.warning("NarrativeAgent LLM not available for narrative generation. Returning generic fallback.")
            return await self._generate_fallback_narrative(request)

        system_prompt = """You are a wise Narrative Agent in the SoulBios consciousness development system. You are a masterful storyteller who finds meaning through narrative, metaphors, and universal themes.

Your narrative methodology:
1. FIND the story within the user's situation
2. USE metaphors and analogies that illuminate truth
3. CONNECT their experience to universal human themes
4. CREATE memorable insights through narrative structure

Guidelines:
- Speak as a wise storyteller with gentle authority
- Use vivid, sensory metaphors that resonate emotionally
- Keep stories concise but meaningful (target ~250 tokens)
- Connect personal experience to timeless wisdom
- End with an insight that stays with them

Avoid:
- Lengthy stories that lose focus
- Complex metaphors that confuse
- Preaching or moralizing
- Generic platitudes"""

        # Get relevant narrative patterns from context
        relevant_patterns = context.get("relevant_patterns", [])
        conversation_history = context.get("conversation_history", [])
        
        user_prompt = f"""
        User's situation: {request.message}
        
        Narrative theme identified: {theme}
        Story elements to use:
        - Metaphor category: {story_elements['metaphor_category']}
        - Selected metaphor: {story_elements['selected_metaphor']}
        - Structure: {story_elements['structure']}
        
        Relevant patterns from their journey:
        {json.dumps(relevant_patterns[:2], indent=2) if relevant_patterns else "This is a new chapter in their story"}
        
        Recent conversation:
        {json.dumps(conversation_history[-2:], indent=2) if conversation_history else "This is the opening of our story together"}
        
        Create a narrative response that:
        1. Finds the story in their situation
        2. Uses the selected metaphor to illuminate truth
        3. Connects to the universal theme of {theme}
        4. Provides memorable insight through narrative
        
        Keep to ~250 tokens for cost efficiency.
        """
        
        try:
            # --- MODIFIED: Use confidence_middleware if available, otherwise direct LLM call ---
            if self.confidence_middleware and hasattr(self.confidence_middleware, 'generate_with_confidence'):
                self.logger.info("Using confidence middleware for NarrativeAgent response.")
                response_data = await self.confidence_middleware.generate_with_confidence(
                    prompt=f"{system_prompt}\n\n{user_prompt}",
                    model=self.model,
                    user_id=request.user_id,
                    context_key=f"narrative_response_{request.conversation_id}"
                )
                response_text = response_data["content"]
                confidence = response_data["confidence"] # Use confidence from middleware
            else:
                self.logger.warning("Confidence middleware not available for NarrativeAgent. Calling LLM directly.")
                response_llm = await asyncio.wait_for(self.model.generate_content_async(f"{system_prompt}\n\n{user_prompt}"), timeout=30.0) # Longer timeout
                response_text = response_llm.candidates[0].content.parts[0].text
                confidence = llm_response.candidates[0].safety_ratings[0].probability # Example
        except asyncio.TimeoutError: # --- MODIFIED: Catch specific timeout ---
            self.logger.error("NarrativeAgent LLM call timed out. Returning fallback response.", exc_info=True)
            response_text = "Every story has a beginning, but my storytelling engine is currently at rest."
            confidence = 0.3
        except Exception as e:
            self.logger.error(f"❌ NarrativeAgent LLM generation failed: {e}", exc_info=True)
            response_text = "Every story has a beginning, but my storytelling engine is currently at rest."
            confidence = 0.3

        processing_time_ms = (time.time() - start_time) * 1000

        # --- Example of safely using self.redis_client for caching ---
        if self.redis_client and processing_time_ms < 5000:
            try:
                self.redis_client.setex(cache_key, 3600, response_text) # cache_key needs to be defined in scope
            except Exception as e:
                self.logger.warning(f"Redis cache storage error for NarrativeAgent: {e}", exc_info=True)
        # --- End Redis Use Example ---

        return AgentResponse(
            agent_id=self.__class__.__name__,
            message=response_text,
            confidence=confidence,
            timestamp=datetime.now(),
            processing_time=processing_time_ms,
            cost=0.0 # Placeholder
        )
    
    async def _calculate_narrative_confidence(
        self, 
        request: AgentRequest, 
        response: str, 
        context: Dict[str, Any]
    ) -> float:
        """Calculate confidence in the narrative response"""
        # --- MODIFIED: Add a check for self.model ---
        if not self.model:
            self.logger.warning("NarrativeAgent LLM not available for confidence calculation. Defaulting to 0.5.")
            return 0.5

        try:
            confidence_factors = []
            
            # Check for narrative elements
            has_metaphor = any(word in response.lower() for word in [
                "like", "as if", "imagine", "picture", "story", "journey", "path", 
                "river", "mountain", "tree", "seed", "bridge", "dance", "compass"
            ])
            has_imagery = len(re.findall(r'\b(?:see|feel|hear|touch|taste|imagine|picture)\b', response.lower())) > 0
            has_wisdom = any(phrase in response.lower() for phrase in [
                "wisdom", "truth", "understanding", "insight", "realize", "discover"
            ])
            has_connection = any(phrase in response.lower() for phrase in [
                "we all", "everyone", "human", "universal", "shared", "together"
            ])
            
            confidence_factors.append(0.3 if has_metaphor else 0.1)
            confidence_factors.append(0.2 if has_imagery else 0.1)
            confidence_factors.append(0.25 if has_wisdom else 0.15)
            confidence_factors.append(0.25 if has_connection else 0.15)
            
            # Check response length (targeting ~250 tokens)
            word_count = len(response.split())
            target_words = self.target_output_tokens * 0.75
            length_factor = 1.0 - abs(word_count - target_words) / target_words
            length_factor = max(0.7, min(1.0, length_factor)) # Clamp between 0.7 and 1.0
            
            base_confidence = sum(confidence_factors)
            final_confidence = base_confidence * length_factor
            
            return min(0.95, max(0.3, final_confidence))
            
        except Exception as e:
            self.logger.error(f"Error calculating narrative confidence: {e}", exc_info=True)
            return 0.6
    
    async def _get_agent_specific_context(self, request: AgentRequest) -> Dict[str, Any]:
        """Get narrative-specific context including story patterns and themes"""
        if not self.collections_manager: # --- MODIFIED: Handle missing collections_manager ---
            self.logger.warning("Collections Manager not available for NarrativeAgent context. Returning empty context.")
            return {
                "narrative_patterns": [],
                "recurring_themes": ["self_discovery"],
                "character_archetypes": [],
                "emotional_undertones": "neutral",
                "story_arc_position": "middle",
                "preferred_metaphor_types": ["nature"]
            }
        if not self.character_manager: # --- MODIFIED: Handle missing character_manager ---
            self.logger.warning("Character Manager not available for NarrativeAgent context. Character archetypes will be empty.")
        
        try:
            # Get user's narrative history
            narrative_patterns = await self._get_narrative_patterns(request.user_id)
            
            # Identify recurring themes in their journey
            recurring_themes = await self._identify_recurring_themes(request.user_id)
            
            # Get character archetypes from character manager
            character_context = await self._get_character_archetypes(request.user_id)
            
            # Analyze emotional undertones
            emotional_context = await self._analyze_emotional_undertones(request.message)
            
            return {
                "narrative_patterns": narrative_patterns,
                "recurring_themes": recurring_themes,
                "character_archetypes": character_context,
                "emotional_undertones": emotional_context,
                "story_arc_position": await self._determine_story_arc_position(request.user_id),
                "preferred_metaphor_types": await self._get_preferred_metaphors(request.user_id)
            }
            
        except Exception as e:
            self.logger.error(f"Error getting narrative-specific context: {e}", exc_info=True)
            return {
                "narrative_patterns": [],
                "recurring_themes": ["self_discovery"],
                "character_archetypes": [],
                "emotional_undertones": "neutral",
                "story_arc_position": "middle",
                "preferred_metaphor_types": ["nature"]
            }
    
    async def _get_narrative_patterns(self, user_id: str) -> List[Dict[str, Any]]:
        """Get user's narrative patterns from previous interactions"""
        if not self.collections_manager: return [] # --- MODIFIED: Handle missing collections_manager ---
        try:
            # --- MODIFIED: collections_manager.get_user_collection is an existing method ---
            user_collection = self.collections_manager.get_user_collection(user_id, "conversation_history") # Assuming a conversation_history collection
            if not user_collection:
                self.logger.warning(f"No conversation_history collection found for user {user_id}.")
                return []
            
            results = await asyncio.to_thread( # Assuming query is sync and potentially blocking
                user_collection.query,
                query_texts=["narrative", "story", "metaphor", "journey"],
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
                    self.logger.warning(f"NarrativeAgent: Unexpected document format in collection query results: {type(doc)}")
                    continue
                
                try:
                    doc_data = json.loads(doc_str)
                    if "narrative" in doc_data.get("agent", "").lower():
                        patterns.append({
                            "content": doc_data.get("response", ""),
                            "timestamp": doc_data.get("timestamp", ""),
                            "theme": doc_data.get("theme", "unknown")
                        })
                except json.JSONDecodeError:
                    self.logger.warning(f"NarrativeAgent: Failed to parse JSON from document: {doc_str[:100]}...")
                    continue
            
            return patterns
            
        except Exception as e:
            self.logger.error(f"Error getting narrative patterns: {e}", exc_info=True)
            return []
    
    async def _identify_recurring_themes(self, user_id: str) -> List[str]:
        """Identify recurring themes in user's conversations"""
        # This method is fine, no external dependencies, returns a default.
        return ["transformation", "growth", "self_discovery"]
            
    async def _get_character_archetypes(self, user_id: str) -> List[Dict[str, Any]]:
        """Get character archetypes associated with this user"""
        if not self.character_manager: # --- MODIFIED: Handle missing character_manager ---
            self.logger.warning("Character Manager not available. Cannot retrieve character archetypes.")
            return []
        try:
            # Use character playbook manager to get user's character context
            available_characters = await asyncio.to_thread(
                self.character_manager.get_available_characters,
                user_id
            )
            return available_characters.get("characters", [])
            
        except Exception as e:
            self.logger.error(f"Error getting character archetypes: {e}", exc_info=True)
            return []
    
    async def _analyze_emotional_undertones(self, message: str) -> str:
        """Analyze emotional undertones in the message"""
        # This method is purely logic-based, no external dependencies, so it's fine.
        try:
            message_lower = message.lower()
            
            if any(word in message_lower for word in ["excited", "happy", "joy", "amazing", "wonderful"]):
                return "positive_energy"
            elif any(word in message_lower for word in ["sad", "difficult", "hard", "struggle", "pain"]):
                return "challenging_growth"
            elif any(word in message_lower for word in ["confused", "unclear", "lost", "uncertain"]):
                return "seeking_clarity"
            elif any(word in message_lower for word in ["angry", "frustrated", "upset", "annoyed"]):
                return "transforming_tension"
            else:
                return "contemplative_reflection"
                
        except Exception as e:
            self.logger.error(f"Error analyzing emotional undertones: {e}", exc_info=True)
            return "neutral"
    
    async def _determine_story_arc_position(self, user_id: str) -> str:
        """Determine where the user is in their overall story arc"""
        # This method is fine, no external dependencies, returns a default.
        return "middle"  # Default to middle of journey
    
    async def _get_preferred_metaphors(self, user_id: str) -> List[str]:
        """Determine user's preferred metaphor types based on history"""
        # This method is fine, no external dependencies, returns a default.
        return ["nature", "journey", "growth"]
    
    async def _calculate_agent_confidence(self, request: AgentRequest, response: str) -> float:
        """Calculate overall confidence in this narrative interaction"""
        return await self._calculate_narrative_confidence(request, response, {})
    
    # Narrative-specific utility methods
    
    def get_narrative_metrics(self) -> Dict[str, Any]:
        """Get narrative-specific metrics in addition to base metrics"""
        base_metrics = self.get_metrics()
        
        narrative_metrics = {
            **base_metrics,
            "cost_target": self.cost_target_per_conversation,
            "target_input_tokens": self.target_input_tokens,
            "target_output_tokens": self.target_output_tokens,
            "storytelling_method": "metaphor_and_theme",
            "specialization": "narrative_consciousness_development"
        }
        
        return narrative_metrics
    
    async def create_story_for_agent(self, theme: str, context: Dict[str, Any]) -> str:
        """Create a narrative insight for other agents to use"""
        if not self.model: # --- MODIFIED: Handle missing LLM ---
            self.logger.warning("NarrativeAgent LLM not available for story creation. Returning generic fallback.")
            return f"Insight: Need more context to create a compelling story about {theme}."

        try:
            story_prompt = f"""
            As the Narrative Agent, create a brief story or metaphor about: {theme}
            
            Context: {json.dumps(context, indent=2)}
            
            Create a 2-3 sentence narrative that:
            1. Uses vivid metaphor
            2. Connects to universal human experience
            3. Provides insight other agents can reference
            
            Keep under 150 words for inter-agent communication.
            """
            
            # --- MODIFIED: Use generate_content_async directly with explicit timeout ---
            response_llm = await asyncio.wait_for(self.model.generate_content_async(story_prompt), timeout=15.0)
            return response_llm.candidates[0].content.parts[0].text.strip()
            
        except asyncio.TimeoutError: # --- MODIFIED: Catch specific timeout ---
            self.logger.error(f"NarrativeAgent story creation timed out for theme: {theme}", exc_info=True)
            return f"Story creation: Encountered a timeout while crafting a narrative for {theme}."
        except Exception as e:
            self.logger.error(f"Error creating story for agent: {e}", exc_info=True)
            return f"Story creation: Encountered an error while crafting a narrative for {theme}."
    
    async def extract_story_themes(self, conversation_text: str) -> List[str]:
        """Extract narrative themes from conversation text for other agents"""
        # This method is fine, no external dependencies, returns a default.
        try:
            themes = []
            text_lower = conversation_text.lower()
            
            # Simple theme extraction based on keywords
            for theme, keywords in {
                "hero_journey": ["challenge", "overcome", "struggle", "victory"],
                "transformation": ["change", "growth", "different", "becoming"],
                "wisdom_seeking": ["learn", "understand", "wisdom", "insight"],
                "connection": ["relationship", "love", "together", "community"],
                "healing": ["heal", "recovery", "pain", "wholeness"]
            }.items():
            # --- MODIFIED: Indent the next line ---
                if any(keyword in text_lower for keyword in keywords):
                    themes.append(theme)
            
            return themes or ["self_discovery"]
            
        except Exception as e:
            self.logger.error(f"Error extracting story themes: {e}", exc_info=True)
            return ["journey"]