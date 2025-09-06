#!/usr/bin/env python3
"""
Base Agent Class for SoulBios Multi-Agent System
Abstract foundation for Cloud Student, Teacher, Narrative, Transcendent, Growth/Alice, Context, and Fortress agents
"""
import asyncio
import time
import logging
from abc import ABC, abstractmethod
from typing import Dict, List, Any, Optional, Tuple
from datetime import datetime, timedelta
from dataclasses import dataclass
from enum import Enum
import json
import hashlib
import os
from dotenv import load_dotenv

# Third-party imports
import redis
import google.generativeai as genai
from chromadb import Client as ChromaClient
import chromadb

# Local imports
from infrastructure.SoulBios_collections_manager import SoulBiosCollectionsManager
from middleware.gemini_confidence_proxy import GeminiConfidenceMiddleware
from config.settings import settings

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')

class ModelType(Enum):
    GEMINI_2_5_PRO = "gemini-2.0-flash-exp"
    GEMMA_3 = "gemma-2-2b-it"
    SHIELD_GEMMA_2 = "shieldgemma-2-2b"

class AgentRole(Enum):
    CLOUD_STUDENT = "cloud_student"
    TEACHER = "teacher"
    NARRATIVE = "narrative"
    TRANSCENDENT = "transcendent"
    GROWTH_ALICE = "growth_alice"
    CONTEXT = "context"
    FORTRESS = "fortress"
    META_PATTERN = "meta_pattern"
    PREDICTION = "prediction"
    GAME_THEORY = "game_theory"
    HISTORY = "history"
    SOCIAL = "social"
    PERSONA = "persona"
    SAFETY = "safety"
    META = "meta"

@dataclass
class AgentMetrics:
    request_count: int = 0
    total_response_time: float = 0.0
    total_cost: float = 0.0
    error_count: int = 0
    cache_hits: int = 0
    cache_misses: int = 0
    
    @property
    def avg_response_time(self) -> float:
        return self.total_response_time / max(1, self.request_count)
    
    @property
    def avg_cost_per_request(self) -> float:
        return self.total_cost / max(1, self.request_count)
    
    @property
    def error_rate(self) -> float:
        return self.error_count / max(1, self.request_count)

@dataclass
class AgentRequest:
    user_id: str
    message: str
    context: Dict[str, Any]
    timestamp: datetime
    conversation_id: str
    requester_agent: Optional[str] = None

@dataclass
class AgentResponse:
    agent_id: str
    message: str
    confidence: float
    context_updates: Dict[str, Any]
    metadata: Dict[str, Any]
    timestamp: datetime
    processing_time: float
    cost: float
    context: Optional[Dict[str, Any]] = None

class BaseAgent(ABC):
    """
    Abstract base class for all SoulBios agents
    Provides common functionality for ChromaDB integration, Redis caching,
    model communication, performance tracking, and agent coordination
    """
    
    def __init__(
        self,
        agent_role: AgentRole,
        model_type: ModelType = ModelType.GEMINI_2_5_PRO,
        collections_manager: Optional[SoulBiosCollectionsManager] = None,
        redis_client: Optional[redis.Redis] = None
    ):
        self.agent_role = agent_role
        self.agent_id = f"{agent_role.value}_{int(time.time())}"
        self.model_type = model_type
        self.logger = logging.getLogger(f"{self.__class__.__name__}({agent_role.value})")
        
        # Performance and cost tracking
        self.metrics = AgentMetrics()
        self.performance_target_ms = 1500  # 1.5s max
        self.cost_target_per_conversation = 0.034
        
        # Initialize ChromaDB connection
        self.collections_manager = collections_manager or self._init_chromadb()
        
        # Initialize Redis connection
        self.redis_client = redis_client or self._init_redis()
        
        # Initialize Gemini models
        self.model = None  # Initialize as None for fallback
        self._init_models()
        
        # Initialize confidence middleware
        self.confidence_middleware = GeminiConfidenceMiddleware(
            collections_manager=self.collections_manager
        ) if collections_manager else None
        
        self.logger.info(f"Agent {self.agent_id} initialized with {model_type.value}")
    
    def _init_chromadb(self) -> SoulBiosCollectionsManager:
        """Initialize ChromaDB connection using environment configuration"""
        try:
            return SoulBiosCollectionsManager()
        except Exception as e:
            self.logger.error(f"Failed to initialize ChromaDB: {e}")
            raise
    
    def _init_redis(self) -> Optional[redis.Redis]:
        """Initialize Redis connection for caching and agent communication"""
        try:
            redis_url = settings.REDIS_URL
            client = redis.from_url(redis_url, decode_responses=True)
            client.ping()
            self.logger.info("Redis connection established")
            return client
        except Exception as e:
            self.logger.warning(f"Redis connection failed: {e}. Running without cache.")
            return None
    
    def _init_models(self):
        """Initialize Gemini API models with fallback"""
        try:
            if not settings.GEMINI_API_KEY:
                self.logger.warning("GEMINI_API_KEY not found, running without LLM")
                return
            
            genai.configure(api_key=settings.GEMINI_API_KEY)
            self.model = genai.GenerativeModel(self.model_type.value)
            self.logger.info(f"Model {self.model_type.value} initialized")
            
        except Exception as e:
            self.logger.warning(f"Failed to initialize models: {e}, running in degraded mode")
            self.model = None
    
    async def process_request(self, request: AgentRequest) -> AgentResponse:
        """
        Main entry point for processing agent requests
        Includes performance tracking, caching, and error handling
        """
        start_time = time.time()
        self.metrics.request_count += 1
        
        try:
            # Check cache first
            cached_response = await self._get_cached_response(request)
            if cached_response:
                self.metrics.cache_hits += 1
                self.logger.debug(f"Cache hit for request {request.conversation_id}")
                return cached_response
            
            self.metrics.cache_misses += 1
            
            # Get context for this request
            context = await self.get_context(request)
            
            # Process the request using agent-specific logic
            response_content, confidence = await self._process_agent_logic(request, context)
            
            # Calculate cost (simplified estimation)
            cost = self._estimate_cost(request.message, response_content)
            
            # Create response
            processing_time = time.time() - start_time
            response = AgentResponse(
                agent_id=self.agent_id,
                message=response_content,
                confidence=confidence,
                context_updates=await self._generate_context_updates(request, response_content),
                metadata=self._generate_metadata(request, processing_time, cost),
                timestamp=datetime.now(),
                processing_time=processing_time,
                cost=cost
            )
            
            # Store response and update metrics
            await self.store_response(request, response)
            self._update_metrics(response)
            
            # Check performance targets
            if processing_time > (self.performance_target_ms / 1000):
                self.logger.warning(f"Response time {processing_time:.3f}s exceeds target {self.performance_target_ms/1000}s")
            
            return response
            
        except Exception as e:
            self.metrics.error_count += 1
            self.logger.error(f"Error processing request: {e}")
            return await self._generate_error_response(request, e)
    
    async def _get_cached_response(self, request: AgentRequest) -> Optional[AgentResponse]:
        """Check Redis cache for previous similar responses"""
        if not self.redis_client:
            return None
        
        try:
            cache_key = self._generate_cache_key(request)
            cached_data = await asyncio.to_thread(self.redis_client.get, cache_key)
            
            if cached_data:
                response_data = json.loads(cached_data)
                return AgentResponse(
                    agent_id=response_data["agent_id"],
                    message=response_data["message"],
                    confidence=response_data["confidence"],
                    context_updates=response_data["context_updates"],
                    metadata=response_data["metadata"],
                    timestamp=datetime.fromisoformat(response_data["timestamp"]),
                    processing_time=response_data["processing_time"],
                    cost=response_data["cost"]
                )
            self.logger.debug(f"Cache miss for request {request.conversation_id}")
            return None
        except Exception as e:
            self.logger.error(f"Error getting cached response: {e}")
            return None
    
    @abstractmethod
    async def _process_agent_logic(self, request: AgentRequest, context: Dict[str, Any]) -> Tuple[str, float]:
        """
        Agent-specific processing logic - must be implemented by each agent
        Returns: (response_message, confidence_score)
        """
        pass
    
    async def get_context(self, request: AgentRequest) -> Dict[str, Any]:
        """Retrieve relevant context from ChromaDB for the request"""
        try:
            # Get user's conversation history
            conversation_history = await self._get_conversation_history(
                request.user_id,
                request.conversation_id,
                limit=10
            )
            
            # Get relevant patterns from vector search
            relevant_patterns = await self._search_relevant_context(
                request.user_id,
                request.message,
                limit=5
            )
            
            # Get agent-specific context
            agent_context = self._get_agent_specific_context(request)
            
            return {
                "conversation_history": conversation_history,
                "relevant_patterns": relevant_patterns,
                "agent_context": agent_context,
                "user_id": request.user_id,
                "conversation_id": request.conversation_id,
                "request_context": request.context
            }
            
        except Exception as e:
            self.logger.error(f"Error getting context: {e}")
            return {"error": str(e)}
    
    async def store_response(self, request: AgentRequest, response: AgentResponse):
        """Store agent response in ChromaDB and cache in Redis"""
        try:
            # Store in ChromaDB
            await self._store_in_chromadb(request, response)
            
            # Cache in Redis
            await self._cache_response(request, response)
            
        except Exception as e:
            self.logger.error(f"Error storing response: {e}")
    
    async def communicate_with_agent(
        self,
        target_agent: AgentRole,
        message: str,
        context: Dict[str, Any]
    ) -> Optional[AgentResponse]:
        """
        Send a message to another agent via Redis pub/sub
        Used for inter-agent communication and coordination
        """
        if not self.redis_client:
            self.logger.warning("Redis not available, cannot communicate with other agents")
            return None
        
        try:
            channel = f"agent_comm_{target_agent.value}"
            message_data = {
                "from_agent": self.agent_role.value,
                "message": message,
                "context": context,
                "timestamp": datetime.now().isoformat(),
                "response_channel": f"agent_response_{self.agent_id}"
            }
            
            # Publish message
            await asyncio.to_thread(
                self.redis_client.publish,
                channel,
                json.dumps(message_data)
            )
            
            # Wait for response (with timeout)
            response = await self._wait_for_agent_response(message_data["response_channel"])
            return response
            
        except Exception as e:
            self.logger.error(f"Error communicating with agent {target_agent.value}: {e}")
            return None
    
    async def _cache_response(self, request: AgentRequest, response: AgentResponse):
        """Cache response in Redis with expiration"""
        if not self.redis_client:
            return
        
        try:
            cache_key = self._generate_cache_key(request)
            response_data = {
                "agent_id": response.agent_id,
                "message": response.message,
                "confidence": response.confidence,
                "context_updates": response.context_updates,
                "metadata": response.metadata,
                "timestamp": response.timestamp.isoformat(),
                "processing_time": response.processing_time,
                "cost": response.cost
            }
            
            # Cache for 1 hour
            await asyncio.to_thread(
                self.redis_client.setex,
                cache_key,
                3600,
                json.dumps(response_data)
            )
            
        except Exception as e:
            self.logger.error(f"Error caching response: {e}")
    
    def _generate_cache_key(self, request: AgentRequest) -> str:
        """Generate a cache key for the request"""
        content = f"{self.agent_role.value}:{request.user_id}:{request.message}"
        return f"agent_cache:{hashlib.md5(content.encode()).hexdigest()}"
    
    async def _get_conversation_history(
        self,
        user_id: str,
        conversation_id: str,
        limit: int = 10
    ) -> List[Dict[str, Any]]:
        """Get conversation history from ChromaDB"""
        try:
            # Ensure user universe exists
            try:
                conversations_collection = self.collections_manager.get_user_collection(user_id, "conversations")
            except ValueError:
                # Create user universe if it doesn't exist
                await self.collections_manager.create_user_universe(user_id)
                conversations_collection = self.collections_manager.get_user_collection(user_id, "conversations")
            
            results = await asyncio.to_thread(
                conversations_collection.query,
                query_texts=[f"conversation:{conversation_id}"],
                n_results=limit
            )
            
            return results.get("documents", [])
            
        except Exception as e:
            self.logger.error(f"Error getting conversation history: {e}")
            return []
    
    async def _search_relevant_context(
        self,
        user_id: str,
        message: str,
        limit: int = 5
    ) -> List[Dict[str, Any]]:
        """Search for relevant context using vector similarity"""
        try:
            # Ensure user universe exists
            try:
                conversations_collection = self.collections_manager.get_user_collection(user_id, "conversations")
            except ValueError:
                # Create user universe if it doesn't exist
                await self.collections_manager.create_user_universe(user_id)
                conversations_collection = self.collections_manager.get_user_collection(user_id, "conversations")
            
            results = await asyncio.to_thread(
                conversations_collection.query,
                query_texts=[message],
                n_results=limit
            )
            
            return results.get("documents", [])
            
        except Exception as e:
            self.logger.error(f"Error searching relevant context: {e}")
            return []
    
    @abstractmethod
    def _get_agent_specific_context(self, request: AgentRequest) -> Dict[str, Any]:
        """Get context specific to this agent type - must be implemented by each agent"""
        pass
    
    async def _store_in_chromadb(self, request: AgentRequest, response: AgentResponse):
        """Store the request-response pair in ChromaDB"""
        try:
            # Ensure user universe exists
            try:
                conversations_collection = self.collections_manager.get_user_collection(request.user_id, "conversations")
            except ValueError:
                # Create user universe if it doesn't exist
                await self.collections_manager.create_user_universe(request.user_id)
                conversations_collection = self.collections_manager.get_user_collection(request.user_id, "conversations")
            
            document = {
                "request": request.message,
                "response": response.message,
                "agent": self.agent_role.value,
                "conversation_id": request.conversation_id,
                "timestamp": response.timestamp.isoformat(),
                "confidence": response.confidence,
                "processing_time": response.processing_time
            }
            
            await asyncio.to_thread(
                conversations_collection.add,
                documents=[json.dumps(document)],
                ids=[f"{response.agent_id}_{response.timestamp.timestamp()}"],
                metadatas=[{
                    "agent": self.agent_role.value,
                    "conversation_id": request.conversation_id,
                    "user_id": request.user_id
                }]
            )
            
        except Exception as e:
            self.logger.error(f"Error storing in ChromaDB: {e}")
    
    def _estimate_cost(self, input_text: str, output_text: str) -> float:
        """Estimate API cost based on token usage (simplified)"""
        # Rough estimation: ~4 chars per token
        input_tokens = len(input_text) / 4
        output_tokens = len(output_text) / 4
        
        # Gemini pricing (approximate)
        cost_per_1k_input = 0.00125
        cost_per_1k_output = 0.00375
        
        cost = (input_tokens / 1000 * cost_per_1k_input) + (output_tokens / 1000 * cost_per_1k_output)
        return cost
    
    async def _generate_context_updates(
        self,
        request: AgentRequest,
        response: str
    ) -> Dict[str, Any]:
        """Generate context updates based on the interaction"""
        return {
            "last_interaction": datetime.now().isoformat(),
            "interaction_count": self.metrics.request_count,
            "agent_confidence": self._calculate_agent_confidence(request, response)
        }
    
    def _generate_metadata(
        self,
        request: AgentRequest,
        processing_time: float,
        cost: float
    ) -> Dict[str, Any]:
        """Generate metadata for the response"""
        return {
            "model_used": self.model_type.value,
            "processing_time": processing_time,
            "cost": cost,
            "cache_status": "miss",
            "agent_version": "1.0.0",
            "performance_target_met": processing_time <= (self.performance_target_ms / 1000)
        }
    
    def _update_metrics(self, response: AgentResponse):
        """Update agent performance metrics"""
        self.metrics.total_response_time += response.processing_time
        self.metrics.total_cost += response.cost
    
    async def _generate_error_response(
        self,
        request: AgentRequest,
        error: Exception
    ) -> AgentResponse:
        """Generate a graceful error response"""
        return AgentResponse(
            agent_id=self.agent_id,
            message=f"I apologize, but I encountered an issue processing your request. Please try again.",
            confidence=0.1,
            context_updates={},
            metadata={"error": str(error), "error_type": type(error).__name__},
            timestamp=datetime.now(),
            processing_time=0.0,
            cost=0.0
        )
    
    async def _wait_for_agent_response(
        self,
        response_channel: str,
        timeout: float = 5.0
    ) -> Optional[AgentResponse]:
        """Wait for response from another agent"""
        if not self.redis_client:
            return None
        
        try:
            pubsub = self.redis_client.pubsub()
            await asyncio.to_thread(pubsub.subscribe, response_channel)
            
            end_time = time.time() + timeout
            while time.time() < end_time:
                message = await asyncio.to_thread(pubsub.get_message, timeout=0.1)
                if message and message["type"] == "message":
                    response_data = json.loads(message["data"])
                    return AgentResponse(**response_data)
                await asyncio.sleep(0.1)
            
            return None
            
        except Exception as e:
            self.logger.error(f"Error waiting for agent response: {e}")
            return None
    
    @abstractmethod
    def _calculate_agent_confidence(self, request: AgentRequest) -> float:
        """Calculate confidence in the agent's response - must be implemented by each agent"""
        pass
    
    def get_metrics(self) -> Dict[str, Any]:
        """Get current agent performance metrics"""
        return {
            "agent_id": self.agent_id,
            "agent_role": self.agent_role.value,
            "request_count": self.metrics.request_count,
            "avg_response_time": self.metrics.avg_response_time,
            "avg_cost_per_request": self.metrics.avg_cost_per_request,
            "error_rate": self.metrics.error_rate,
            "cache_hit_rate": self.metrics.cache_hits / max(1, self.metrics.request_count),
            "performance_target_met": self.metrics.avg_response_time <= (self.performance_target_ms / 1000),
            "cost_target_met": self.metrics.avg_cost_per_request <= self.cost_target_per_conversation
        }