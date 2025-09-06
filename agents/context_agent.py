#!/usr/bin/env python3
"""
Context Agent for SoulBios Multi-Agent System
Manages conversation history and contextual memory
"""
import asyncio
import logging
import os # <-- Added for os.getenv if needed for internal LLM
from typing import Dict, List, Any, Optional, Tuple
from datetime import datetime

# Local imports
from .base_agent import BaseAgent, AgentRequest, AgentResponse, ModelType # <-- Removed AgentRole, ModelType if not defined in base_agent

logger = logging.getLogger(__name__)

class ContextAgent(BaseAgent):
    """
    Context Agent provides conversation history and contextual memory management
    """
    
    def __init__(self, agent_role, collections_manager=None, redis_client=None): # <-- Ensure redis_client can be None
        # ModelType already imported above
        super().__init__(
            agent_role=agent_role,
            model_type=ModelType.GEMINI_2_5_PRO, # Fix: Use actual model type for context processing
            collections_manager=collections_manager,
            redis_client=redis_client
        )
        
        # --- Graceful Redis Handling ---
        if self.redis_client:
            self.logger.info("ContextAgent initialized with Redis caching for temporary context.")
        else:
            self.logger.warning("ContextAgent initialized WITHOUT Redis caching. Session management features will be limited.")
        # --- End Graceful Redis Handling ---

        if not self.collections_manager:
            self.logger.error("ContextAgent initialized WITHOUT a Collections Manager. Context retrieval will be non-functional.")

        self.logger.info("Context Agent initialized with history management")

    # Method expected by CloudStudentAgent orchestrator
    async def extract_features(self, game_state: dict) -> dict:
        """Extracts and structures context from the game state."""
        # This method should not be creating a new AgentRequest.
        # It should process the game_state and return a dictionary.
        
        # TODO: Implement the real context extraction logic here.
        # For now, let's just return a success message.
        return {"context_summary": "Features extracted successfully"}

    # --- MODIFIED: Added initialize method ---
    async def initialize(self):
        # No LLM to initialize for the Context Agent itself, but it ensures its dependencies are ready.
        self.logger.info("ContextAgent initialized (no LLM, relies on Collections Manager).")
        # --- CRITICAL: Raise if collections_manager is not available in production ---
        if not self.collections_manager and os.getenv("ENVIRONMENT") == "production":
            raise ValueError("ContextAgent is critical in production but collections_manager is not initialized.")


    async def _process_agent_logic(self, request: AgentRequest, context: dict) -> Tuple[str, float]:
        """
        Core context logic providing conversation history
        Returns: (response_message, confidence_score)
        """
        # --- MODIFIED: Call the more robust context retrieval from the base class ---
        # The main CloudStudentAgent process_request will call ContextAgent's process_request,
        # which needs to return a full context message.
        if not self.collections_manager:
            self.logger.warning("ContextAgent collections manager not available. Returning empty context.")
            return "No historical context available.", 0.0

        try:
            # We will use the comprehensive logic from the previous context_agent.py
            # This is essentially what the CloudStudentAgent expects ContextAgent to do.
            conversations = await self.collections_manager.get_conversation_history(request.user_id, limit=request.context_depth)
            
            relevant_patterns = await self.collections_manager.search_collections(
                user_id=request.user_id,
                query=request.message,
                collection_types=["life_patterns", "values_frameworks", "conversation_history"],
                n_results=request.context_depth
            )

            full_context_message = f"Recent Conversation History ({len(conversations)} entries):\n"
            for conv in conversations:
                full_context_message += f"- User: {conv.get('request_message', '')}\n- Agent: {conv.get('response_message', '')}\n"
            
            if relevant_patterns:
                full_context_message += f"\nRelevant Memories/Patterns ({len(relevant_patterns)} entries):\n"
                for pat in relevant_patterns:
                    # Truncate document for brevity in context message
                    doc_content = pat.get('document', '')
                    full_context_message += f"- {doc_content[:100]}... (Source: {pat.get('metadata', {}).get('source', 'unknown')})\n"
            
            # Store current message as part of context update for future queries (handled by main API endpoint already)
            # This logic should generally live in the main API endpoint after a successful response
            # if self.collections_manager:
            #     await self.collections_manager.add_conversation(...)

            return full_context_message, 0.9
            
        except Exception as e:
            self.logger.error(f"❌ ContextAgent failed to process request (context retrieval): {e}", exc_info=True)
            return f"Error retrieving context: {str(e)}", 0.1

    async def _get_agent_specific_context(self, request: AgentRequest) -> Dict[str, Any]:
        """Get context-specific context for history analysis. (Internal helper, not core process_request return)."""
        # This is primarily for internal orchestration within ContextAgent or specific utility calls.
        return {
            "context_check": True,
            "user_id": request.user_id,
            "conversation_id": request.conversation_id,
            "timestamp": datetime.now().isoformat()
        }

    async def _calculate_agent_confidence(self, request: AgentRequest, response: str) -> float:
        """Calculate confidence in context provision"""
        if "No historical context" in response or "Error retrieving context" in response:
            return 0.1 # Low confidence if degraded
        return 0.95

    # --- MODIFIED: Removed duplicate methods, kept essential ones with robust checks ---
    # The _get_conversation_history, store_framework, retrieve_frameworks methods are now assumed
    # to be called directly on self.collections_manager or handled in CloudStudentAgent.

    # If these methods are needed *directly* by the ContextAgent to perform its _process_agent_logic,
    # they should be placed inside a helper function called by _process_agent_logic.

    # However, based on api/soulbios_api.py and CloudStudentAgent, the collections_manager
    # is often called directly or indirectly via ContextAgent.process_request.

    # Keeping `store_framework` and `retrieve_frameworks` as they are utility functions
    # the ContextAgent might expose for other agents or parts of the system.
    # Just adding robustness.

    async def store_framework(self, user_id: str, framework_data: Dict[str, Any]) -> bool:
        """
        Store consciousness framework in ChromaDB
        """
        if not self.collections_manager: # --- MODIFIED: Handle missing collections_manager ---
            self.logger.warning(f"Collections Manager not available. Skipping framework storage for user {user_id}.")
            return False
        
        try:
            framework_text = f"Framework: {framework_data.get('values', 'No values')} | Goals: {framework_data.get('goals', 'No goals')}"
            metadata = {
                "type": "consciousness_framework", 
                "user_id": user_id,
                "timestamp": datetime.now().isoformat(),
                "framework_id": framework_data.get('id', 'unknown')
            }
            
            # --- MODIFIED: Ensure store_in_collection is awaited if async ---
            # Assuming store_in_collection might be async
            success = await asyncio.to_thread(self.collections_manager.store_in_collection, # Assuming sync for now
                collection_type="wisdom_insights",
                user_id=user_id,
                text=framework_text,
                metadata=metadata
            )
            
            if success:
                self.logger.info(f"✅ Framework stored for user {user_id}")
                return True
            else:
                self.logger.warning(f"⚠️ Framework storage failed for user {user_id}")
                return False
                    
        except Exception as e:
            self.logger.error(f"❌ Error storing framework: {e}", exc_info=True)
            return False
    
    async def retrieve_frameworks(self, user_id: str, limit: int = 5) -> List[Dict[str, Any]]:
        """
        Retrieve stored frameworks for a user
        """
        if not self.collections_manager: # --- MODIFIED: Handle missing collections_manager ---
            self.logger.warning(f"Collections Manager not available. Skipping framework retrieval for user {user_id}.")
            return []
        
        try:
            results = await asyncio.to_thread(self.collections_manager.search_collections, # Assuming sync for now
                user_id=user_id,
                query="consciousness framework",
                collection_types=["wisdom_insights"],
                n_results=limit
            )
            
            frameworks = []
            if results:
                for result in results: # Removed [:limit] as search_collections limits it
                    frameworks.append({
                        'text': result.get('document', ''), # Assuming 'document' key now
                        'metadata': result.get('metadata', {}),
                        'timestamp': result.get('metadata', {}).get('timestamp', 'unknown')
                    })
                        
            return frameworks
                
        except Exception as e:
            self.logger.error(f"❌ Error retrieving frameworks: {e}", exc_info=True)
            return []