#!/usr/bin/env python3
"""
Agent Communication Orchestration System for SoulBios
Coordinates conversation flow between all 6 agents with performance optimization and cost tracking
"""

import asyncio
import logging
import json
import time
import hashlib
import uuid
from typing import Dict, List, Any, Optional, Tuple, Union, AsyncIterator, Callable
from datetime import datetime, timedelta
from dataclasses import dataclass, asdict
from enum import Enum
import redis
from collections import defaultdict
import threading
import cProfile
import pstats
from io import StringIO

# Local imports
from base_agent import BaseAgent, AgentRole, AgentRequest, AgentResponse
from cloud_student_agent import CloudStudentAgent
from teacher_agent import TeacherAgent
from narrative_agent import NarrativeAgent
from transcendent_agent import TranscendentAgent
from meta_pattern_agent import MetaPatternAgent
from prediction_agent import PredictionAgent
from alice_consciousness_engine import AliceConsciousnessEngine
from SoulBios_collections_manager import SoulBiosCollectionsManager


class ConversationMode(Enum):
    STANDARD_CHAT = "standard_chat"
    CHAMBER_MODE = "chamber_mode"
    EMERGENCY_FALLBACK = "emergency_fallback"


class OrchestrationPattern(Enum):
    SEQUENTIAL = "sequential"
    PARALLEL = "parallel"
    HYBRID = "hybrid"
    WATERFALL = "waterfall"


@dataclass
class AgentFlow:
    sequence: List[AgentRole]
    parallel_groups: List[List[AgentRole]]
    pattern: OrchestrationPattern
    max_duration_ms: int
    fallback_agent: AgentRole


@dataclass
class ConversationMetrics:
    total_duration_ms: int
    agent_durations: Dict[str, int]
    parallel_efficiency: float
    cost_breakdown: Dict[str, float]
    total_cost: float
    error_count: int
    fallback_triggered: bool


@dataclass
class StreamingResponse:
    response_id: str
    agent_id: str
    partial_content: str
    is_complete: bool
    timestamp: datetime
    metadata: Dict[str, Any]

@dataclass
class OrchestrationResult:
    primary_response: str
    agent_contributions: Dict[str, str]
    conversation_metrics: ConversationMetrics
    context_updates: Dict[str, Any]
    confidence_score: float
    flow_completed: bool
    streaming_responses: List[StreamingResponse] = None

@dataclass
class AgentPerformanceProfile:
    agent_id: str
    call_count: int
    total_duration_ms: int
    average_duration_ms: float
    max_duration_ms: int
    min_duration_ms: int
    timeout_count: int
    error_count: int
    cache_hit_rate: float


class AgentOrchestrator:
    """
    Master orchestrator for coordinating conversation flow between all 6 agents
    
    Performance targets:
    - Total response time: 800ms-1.5s
    - Cost target: $0.034/conversation
    - Parallel processing optimization
    - Context sharing via ChromaDB
    """
    
    def __init__(
        self,
        collections_manager: SoulBiosCollectionsManager,
        redis_client: redis.Redis,
        alice_engine: AliceConsciousnessEngine = None,
        monitoring_enabled: bool = True
    ):
        self.collections_manager = collections_manager
        self.redis_client = redis_client
        self.alice_engine = alice_engine
        self.monitoring_enabled = monitoring_enabled
        
        # Performance configuration
        self.target_response_time_ms = 1200  # 1.2s target
        self.max_response_time_ms = 1500     # 1.5s max
        self.agent_timeout_ms = 30000        # 30s max per agent
        self.parallel_timeout_ms = 2000      # 2s for parallel processing
        self.cost_target_per_conversation = 0.034
        
        # Performance optimization features
        self.enable_response_streaming = True
        self.enable_aggressive_caching = True
        self.enable_performance_profiling = True
        self.cache_ttl_seconds = 3600  # 1 hour cache TTL
        
        # Agent instances
        self.agents = {}
        self.agent_locks = {}
        self.conversation_cache = {}
        
        # Performance monitoring
        self.agent_performance_profiles = {}
        self.streaming_callbacks = {}  # For response streaming
        self.profiler_enabled = False
        
        # Response caching
        self.response_cache_stats = {"hits": 0, "misses": 0}
        self.agent_response_cache = {}  # Memory cache for frequent responses
        
        # Conversation flow patterns
        self.conversation_flows = {
            ConversationMode.STANDARD_CHAT: AgentFlow(
                sequence=[
                    AgentRole.CLOUD_STUDENT,
                    AgentRole.FORTRESS,
                    AgentRole.CONTEXT,
                    AgentRole.TEACHER,
                    AgentRole.NARRATIVE,
                    AgentRole.TRANSCENDENT
                ],
                parallel_groups=[
                    [AgentRole.CLOUD_STUDENT],  # Always first
                    [AgentRole.FORTRESS, AgentRole.CONTEXT],  # Fast parallel validation
                    [AgentRole.TEACHER, AgentRole.NARRATIVE, AgentRole.TRANSCENDENT]  # Main processing in parallel
                ],
                pattern=OrchestrationPattern.HYBRID,
                max_duration_ms=1400,
                fallback_agent=AgentRole.CLOUD_STUDENT
            ),
            ConversationMode.CHAMBER_MODE: AgentFlow(
                sequence=[
                    AgentRole.CLOUD_STUDENT,
                    AgentRole.GROWTH_ALICE,
                    AgentRole.CONTEXT,
                    AgentRole.TRANSCENDENT,
                    AgentRole.GROWTH_ALICE
                ],
                parallel_groups=[
                    [AgentRole.CLOUD_STUDENT],
                    [AgentRole.GROWTH_ALICE, AgentRole.CONTEXT],
                    [AgentRole.TRANSCENDENT],
                    [AgentRole.GROWTH_ALICE]
                ],
                pattern=OrchestrationPattern.HYBRID,
                max_duration_ms=1400,
                fallback_agent=AgentRole.GROWTH_ALICE
            )
        }
        
        # Cost tracking per agent
        self.agent_cost_estimates = {
            AgentRole.CLOUD_STUDENT: 0.008,     # Orchestration overhead
            AgentRole.TEACHER: 0.01612,         # Full Gemini 2.5 Pro
            AgentRole.NARRATIVE: 0.00013,       # Gemma 3 efficient
            AgentRole.TRANSCENDENT: 0.01612,    # Full Gemini 2.5 Pro
            AgentRole.GROWTH_ALICE: 0.008,      # Existing Alice engine
            AgentRole.CONTEXT: 0.002,           # Context retrieval
            AgentRole.FORTRESS: 0.001           # Quick validation
        }
        
        # Initialize logging
        self.logger = logging.getLogger(f"{self.__class__.__name__}")
        self.logger.info("Agent Orchestrator initialized")
        
        # Initialize agents
        asyncio.create_task(self._initialize_agents())
    
    async def _initialize_agents(self):
        """Initialize all agent instances"""
        try:
            self.agents[AgentRole.CLOUD_STUDENT] = CloudStudentAgent(
                collections_manager=self.collections_manager,
                redis_client=self.redis_client
            )
            
            self.agents[AgentRole.TEACHER] = TeacherAgent(
                collections_manager=self.collections_manager,
                redis_client=self.redis_client
            )
            
            self.agents[AgentRole.NARRATIVE] = NarrativeAgent(
                collections_manager=self.collections_manager,
                redis_client=self.redis_client
            )
            
            self.agents[AgentRole.TRANSCENDENT] = TranscendentAgent(
                collections_manager=self.collections_manager,
                redis_client=self.redis_client
            )
            
            self.agents[AgentRole.META_PATTERN] = MetaPatternAgent(
                collections_manager=self.collections_manager,
                redis_client=self.redis_client
            )
            
            # Placeholder agents (Context and Fortress) - would need actual implementations
            self.agents[AgentRole.CONTEXT] = self._create_context_agent()
            self.agents[AgentRole.FORTRESS] = self._create_fortress_agent()
            
            # Alice engine as Growth agent
            if self.alice_engine:
                self.agents[AgentRole.GROWTH_ALICE] = self.alice_engine
            
            # Initialize locks for thread safety
            for agent_role in self.agents.keys():
                self.agent_locks[agent_role] = asyncio.Lock()
            
            self.logger.info(f"Initialized {len(self.agents)} agents")
            
        except Exception as e:
            self.logger.error(f"Error initializing agents: {e}")
            raise
    
    def _create_context_agent(self):
        """Create placeholder context agent - would be implemented as full agent"""
        class ContextAgent:
            async def process_request(self, request: AgentRequest) -> AgentResponse:
                # Simplified context agent implementation
                return AgentResponse(
                    agent_id="context_agent",
                    message="Context analysis complete",
                    confidence=0.8,
                    context_updates={"context_retrieved": True},
                    metadata={"agent_type": "context"},
                    timestamp=datetime.now(),
                    processing_time=0.1,
                    cost=0.002
                )
        return ContextAgent()
    
    def _create_fortress_agent(self):
        """Create placeholder fortress agent - would be implemented as full agent"""
        class FortressAgent:
            async def process_request(self, request: AgentRequest) -> AgentResponse:
                # Simplified fortress agent implementation
                return AgentResponse(
                    agent_id="fortress_agent",
                    message="Security validation complete",
                    confidence=0.9,
                    context_updates={"security_validated": True},
                    metadata={"agent_type": "fortress"},
                    timestamp=datetime.now(),
                    processing_time=0.05,
                    cost=0.001
                )
        return FortressAgent()
    
    async def orchestrate_conversation(
        self,
        request: AgentRequest,
        mode: ConversationMode = ConversationMode.STANDARD_CHAT,
        context: Dict[str, Any] = None,
        streaming_callback: Optional[Callable[[StreamingResponse], None]] = None
    ) -> OrchestrationResult:
        """
        Main orchestration method - coordinates conversation flow between agents
        
        Args:
            request: The user request to process
            mode: Conversation mode (standard_chat or chamber_mode)
            context: Additional context for the conversation
            streaming_callback: Optional callback for streaming responses
            
        Returns:
            OrchestrationResult with aggregated response and metrics
        """
        start_time = time.time()
        profile_data = None
        
        try:
            # Start profiling if enabled
            if self.enable_performance_profiling:
                profiler = cProfile.Profile()
                profiler.enable()
            
            # Store streaming callback
            if streaming_callback:
                self.streaming_callbacks[request.conversation_id] = streaming_callback
            
            # Get conversation flow for mode
            flow = self.conversation_flows.get(mode, self.conversation_flows[ConversationMode.STANDARD_CHAT])
            
            # Check aggressive cache first (with more granular caching)
            if self.enable_aggressive_caching:
                cached_result = await self._get_aggressive_cached_result(request, mode, context)
                if cached_result:
                    self.response_cache_stats["hits"] += 1
                    self.logger.info(f"Aggressive cache hit for conversation {request.conversation_id}")
                    return cached_result
                self.response_cache_stats["misses"] += 1
            
            # Share initial context across agents
            shared_context = await self._prepare_shared_context(request, context or {})
            
            # Execute optimized orchestration
            result = await self._execute_optimized_flow(request, flow, shared_context, streaming_callback)
            
            # Stop profiling and capture data
            if self.enable_performance_profiling:
                profiler.disable()
                profile_data = self._capture_profile_data(profiler)
            
            # Calculate final metrics
            total_duration = int((time.time() - start_time) * 1000)
            result.conversation_metrics.total_duration_ms = total_duration
            
            # Check performance targets
            if total_duration > self.max_response_time_ms:
                self.logger.warning(f"Response time {total_duration}ms exceeds target {self.max_response_time_ms}ms")
            
            if result.conversation_metrics.total_cost > self.cost_target_per_conversation:
                self.logger.warning(f"Cost ${result.conversation_metrics.total_cost:.4f} exceeds target ${self.cost_target_per_conversation}")
            
            # Cache result for similar requests
            await self._cache_result(cache_key, result)
            
            # Log metrics if monitoring enabled
            if self.monitoring_enabled:
                await self._log_metrics(request, result)
            
            return result
            
        except Exception as e:
            self.logger.error(f"Orchestration error: {e}")
            return await self._handle_orchestration_error(request, e)
        
        finally:
            # Clean up streaming callback
            if request.conversation_id in self.streaming_callbacks:
                del self.streaming_callbacks[request.conversation_id]
    
    async def _execute_optimized_flow(
        self,
        request: AgentRequest,
        flow: AgentFlow,
        shared_context: Dict[str, Any],
        streaming_callback: Optional[Callable[[StreamingResponse], None]] = None
    ) -> OrchestrationResult:
        """Execute optimized flow with parallel processing and streaming"""
        
        agent_responses = {}
        agent_durations = {}
        total_cost = 0.0
        error_count = 0
        streaming_responses = []
        
        try:
            # Process parallel groups with optimized timeouts and streaming
            for group_idx, group in enumerate(flow.parallel_groups):
                group_start = time.time()
                
                if len(group) == 1:
                    # Single agent processing with streaming
                    agent_role = group[0]
                    if agent_role not in self.agents:
                        continue
                    
                    try:
                        response, stream_responses = await self._process_agent_with_streaming(
                            agent_role, 
                            self._enhance_request_with_context(request, shared_context, agent_responses),
                            streaming_callback,
                            timeout_ms=self.agent_timeout_ms if group_idx == 0 else 5000  # First agent gets more time
                        )
                        
                        agent_responses[agent_role.value] = response
                        agent_durations[agent_role.value] = int((time.time() - group_start) * 1000)
                        total_cost += response.cost
                        shared_context.update(response.context_updates)
                        
                        if stream_responses:
                            streaming_responses.extend(stream_responses)
                        
                    except Exception as e:
                        self.logger.error(f"Error processing {agent_role.value}: {e}")
                        error_count += 1
                        await self._update_agent_performance_profile(agent_role.value, error=True)
                
                else:
                    # Parallel processing with advanced timeout handling
                    group_responses = await self._process_parallel_group_optimized(
                        group, request, shared_context, agent_responses, streaming_callback
                    )
                    
                    for agent_role, response in group_responses.items():
                        if response:
                            agent_responses[agent_role] = response
                            agent_durations[agent_role] = int((time.time() - group_start) * 1000)
                            total_cost += response.cost
                            shared_context.update(response.context_updates)
            
            # Synthesize final response
            primary_response, confidence = await self._synthesize_responses_optimized(
                agent_responses, request, shared_context
            )
            
            # Cache the result aggressively
            if self.enable_aggressive_caching:
                await self._cache_result_aggressively(request, agent_responses, primary_response)
            
            # Calculate metrics
            metrics = ConversationMetrics(
                total_duration_ms=0,  # Will be set by caller
                agent_durations=agent_durations,
                parallel_efficiency=self._calculate_parallel_efficiency(agent_durations, flow),
                cost_breakdown={role: self.agent_cost_estimates.get(AgentRole(role), 0.001) 
                              for role in agent_responses.keys()},
                total_cost=total_cost,
                error_count=error_count,
                fallback_triggered=False
            )
            
            return OrchestrationResult(
                primary_response=primary_response,
                agent_contributions={k: v.message for k, v in agent_responses.items()},
                conversation_metrics=metrics,
                context_updates=shared_context,
                confidence_score=confidence,
                flow_completed=len(agent_responses) >= len(flow.sequence) // 2,
                streaming_responses=streaming_responses
            )
            
        except Exception as e:
            self.logger.error(f"Optimized flow execution error: {e}")
            return await self._execute_fallback_flow(request, flow, shared_context)
    
    async def _process_parallel_group_optimized(
        self,
        group: List[AgentRole],
        request: AgentRequest,
        shared_context: Dict[str, Any],
        agent_responses: Dict[str, AgentResponse],
        streaming_callback: Optional[Callable[[StreamingResponse], None]] = None
    ) -> Dict[str, Optional[AgentResponse]]:
        """Process a group of agents in parallel with optimized timeouts and streaming"""
        
        # Create tasks for parallel processing
        tasks = {}
        for agent_role in group:
            if agent_role in self.agents:
                enhanced_request = self._enhance_request_with_context(
                    request, shared_context, agent_responses
                )
                
                # Use different timeouts based on agent type
                timeout_ms = self._get_agent_optimal_timeout(agent_role)
                
                task = asyncio.create_task(
                    self._process_agent_with_streaming(
                        agent_role, enhanced_request, streaming_callback, timeout_ms
                    )
                )
                tasks[agent_role] = task
        
        # Wait with group timeout
        group_results = {}
        
        try:
            # Wait for all tasks with aggressive timeout
            done, pending = await asyncio.wait(
                tasks.values(),
                timeout=self.parallel_timeout_ms / 1000,  # 2s for parallel group
                return_when=asyncio.FIRST_COMPLETED if len(tasks) > 2 else asyncio.ALL_COMPLETED
            )
            
            # Process completed tasks
            for agent_role, task in tasks.items():
                if task in done:
                    try:
                        result = await task
                        if isinstance(result, tuple):
                            response, _ = result  # Unpack streaming response if present
                            group_results[agent_role.value] = response
                        else:
                            group_results[agent_role.value] = result
                        
                        await self._update_agent_performance_profile(agent_role.value, success=True)
                        
                    except Exception as e:
                        self.logger.error(f"Parallel group error for {agent_role.value}: {e}")
                        group_results[agent_role.value] = None
                        await self._update_agent_performance_profile(agent_role.value, error=True)
                else:
                    # Task didn't complete in time
                    if task in pending:
                        task.cancel()
                    group_results[agent_role.value] = await self._get_simplified_fallback_response(agent_role)
                    await self._update_agent_performance_profile(agent_role.value, timeout=True)
            
            # Cancel any remaining tasks
            for task in pending:
                task.cancel()
                
        except asyncio.TimeoutError:
            self.logger.warning(f"Parallel group timeout for {[r.value for r in group]}")
            # Provide simplified responses for all
            for agent_role in group:
                group_results[agent_role.value] = await self._get_simplified_fallback_response(agent_role)
        
        return group_results
    
    def _get_agent_optimal_timeout(self, agent_role: AgentRole) -> int:
        """Get optimal timeout for specific agent based on historical performance"""
        
        # Default timeouts based on agent complexity
        default_timeouts = {
            AgentRole.CLOUD_STUDENT: 2000,      # Fast orchestration
            AgentRole.FORTRESS: 1000,           # Quick validation
            AgentRole.CONTEXT: 1500,            # Context retrieval
            AgentRole.TEACHER: 8000,            # Complex teaching logic
            AgentRole.NARRATIVE: 3000,          # Story generation
            AgentRole.TRANSCENDENT: 10000,      # Deep analysis
            AgentRole.GROWTH_ALICE: 5000        # Alice engine
        }
        
        base_timeout = default_timeouts.get(agent_role, 5000)
        
        # Adjust based on performance profile
        if agent_role.value in self.agent_performance_profiles:
            profile = self.agent_performance_profiles[agent_role.value]
            if profile.average_duration_ms > 0:
                # Use 2x average duration with minimum of base timeout
                optimized_timeout = max(base_timeout, int(profile.average_duration_ms * 2))
                return min(optimized_timeout, self.agent_timeout_ms)  # Cap at max timeout
        
        return base_timeout
    
    async def _process_agent_with_streaming(
        self,
        agent_role: AgentRole,
        request: AgentRequest,
        streaming_callback: Optional[Callable[[StreamingResponse], None]] = None,
        timeout_ms: int = 5000
    ) -> Tuple[AgentResponse, List[StreamingResponse]]:
        """Process agent request with streaming support"""
        
        agent_start = time.time()
        streaming_responses = []
        
        # Check individual agent cache first
        if self.enable_aggressive_caching:
            cached_response = await self._get_agent_cached_response(agent_role, request)
            if cached_response:
                await self._update_agent_performance_profile(agent_role.value, success=True, cache_hit=True)
                return cached_response, []
        
        try:
            agent = self.agents[agent_role]
            
            # Send initial streaming response
            if streaming_callback and self.enable_response_streaming:
                stream_response = StreamingResponse(
                    response_id=str(uuid.uuid4()),
                    agent_id=agent_role.value,
                    partial_content=f"🤔 {agent_role.value.title()} agent is thinking...",
                    is_complete=False,
                    timestamp=datetime.now(),
                    metadata={"phase": "processing"}
                )
                streaming_responses.append(stream_response)
                streaming_callback(stream_response)
            
            # Process with timeout
            if agent_role == AgentRole.GROWTH_ALICE and hasattr(agent, 'generate_response'):
                # Alice engine interface
                response_text = await asyncio.wait_for(
                    agent.generate_response(request.message, context=request.context),
                    timeout=timeout_ms / 1000
                )
                
                response = AgentResponse(
                    agent_id=f"alice_{int(time.time())}",
                    message=response_text,
                    confidence=0.8,
                    context_updates={"alice_response": True},
                    metadata={"agent_type": "alice", "streaming": True},
                    timestamp=datetime.now(),
                    processing_time=int((time.time() - agent_start) * 1000),
                    cost=self.agent_cost_estimates[agent_role]
                )
            else:
                # Standard agent interface
                response = await asyncio.wait_for(
                    agent.process_request(request),
                    timeout=timeout_ms / 1000
                )
            
            # Send completion streaming response
            if streaming_callback and self.enable_response_streaming:
                complete_stream_response = StreamingResponse(
                    response_id=str(uuid.uuid4()),
                    agent_id=agent_role.value,
                    partial_content=response.message[:200] + "..." if len(response.message) > 200 else response.message,
                    is_complete=True,
                    timestamp=datetime.now(),
                    metadata={"phase": "complete", "confidence": response.confidence}
                )
                streaming_responses.append(complete_stream_response)
                streaming_callback(complete_stream_response)
            
            # Cache the response
            if self.enable_aggressive_caching:
                await self._cache_agent_response(agent_role, request, response)
            
            # Update performance profile
            duration_ms = int((time.time() - agent_start) * 1000)
            await self._update_agent_performance_profile(agent_role.value, success=True, duration_ms=duration_ms)
            
            return response, streaming_responses
            
        except asyncio.TimeoutError:
            self.logger.warning(f"Agent {agent_role.value} timed out after {timeout_ms}ms")
            
            # Send timeout streaming response
            if streaming_callback and self.enable_response_streaming:
                timeout_stream_response = StreamingResponse(
                    response_id=str(uuid.uuid4()),
                    agent_id=agent_role.value,
                    partial_content=f"⏱️ {agent_role.value.title()} agent taking longer than expected, providing simplified response...",
                    is_complete=True,
                    timestamp=datetime.now(),
                    metadata={"phase": "timeout", "fallback": True}
                )
                streaming_responses.append(timeout_stream_response)
                streaming_callback(timeout_stream_response)
            
            # Return simplified fallback response
            fallback_response = await self._get_simplified_fallback_response(agent_role)
            await self._update_agent_performance_profile(agent_role.value, timeout=True)
            
            return fallback_response, streaming_responses
            
        except Exception as e:
            self.logger.error(f"Agent {agent_role.value} error: {e}")
            
            # Send error streaming response
            if streaming_callback and self.enable_response_streaming:
                error_stream_response = StreamingResponse(
                    response_id=str(uuid.uuid4()),
                    agent_id=agent_role.value,
                    partial_content=f"⚠️ {agent_role.value.title()} agent encountered an issue, providing alternative response...",
                    is_complete=True,
                    timestamp=datetime.now(),
                    metadata={"phase": "error", "fallback": True}
                )
                streaming_responses.append(error_stream_response)
                streaming_callback(error_stream_response)
            
            # Return error fallback response
            error_response = AgentResponse(
                agent_id=f"{agent_role.value}_error",
                message=await self._get_agent_error_message(agent_role),
                confidence=0.3,
                context_updates={},
                metadata={"error": str(e), "fallback": True},
                timestamp=datetime.now(),
                processing_time=int((time.time() - agent_start) * 1000),
                cost=0.001
            )
            
            await self._update_agent_performance_profile(agent_role.value, error=True)
            
            return error_response, streaming_responses
    
    async def _get_simplified_fallback_response(self, agent_role: AgentRole) -> AgentResponse:
        """Get simplified fallback response for timeout situations"""
        
        fallback_messages = {
            AgentRole.CLOUD_STUDENT: "I'm coordinating the best response for you from our available insights.",
            AgentRole.FORTRESS: "Security and safety considerations have been validated.",
            AgentRole.CONTEXT: "I'm gathering relevant context from your conversation history.",
            AgentRole.TEACHER: "Let me share what I can teach you about this topic in the time available.",
            AgentRole.NARRATIVE: "I see a meaningful story unfolding in what you've shared with me.",
            AgentRole.TRANSCENDENT: "From a deeper perspective, this situation offers opportunities for growth and understanding.",
            AgentRole.GROWTH_ALICE: "I'm here to support your growth and development in this moment."
        }
        
        return AgentResponse(
            agent_id=f"{agent_role.value}_simplified",
            message=fallback_messages.get(agent_role, "I'm working on providing you with helpful insights."),
            confidence=0.6,
            context_updates={"simplified_response": True},
            metadata={"fallback": True, "simplified": True},
            timestamp=datetime.now(),
            processing_time=100,
            cost=0.001
        )
    
    async def _get_agent_error_message(self, agent_role: AgentRole) -> str:
        """Get appropriate error message for agent type"""
        
        error_messages = {
            AgentRole.CLOUD_STUDENT: "I'm experiencing coordination challenges but working to provide you with helpful guidance.",
            AgentRole.FORTRESS: "Safety validation encountered an issue, but I'm maintaining security protocols.",
            AgentRole.CONTEXT: "I'm having difficulty accessing context at the moment, but I'm still here to help.",
            AgentRole.TEACHER: "While I'm experiencing technical challenges, I remain committed to supporting your learning.",
            AgentRole.NARRATIVE: "I'm having trouble accessing my storytelling capabilities right now, but I see meaning in your situation.",
            AgentRole.TRANSCENDENT: "Despite technical difficulties, I recognize the deeper wisdom available in this moment.",
            AgentRole.GROWTH_ALICE: "I'm experiencing some challenges but remain focused on supporting your growth."
        }
        
        return error_messages.get(agent_role, "I'm experiencing technical difficulties but remain committed to helping you.")
    
    async def _execute_hybrid_flow(
        self,
        request: AgentRequest,
        flow: AgentFlow,
        shared_context: Dict[str, Any]
    ) -> OrchestrationResult:
        """Execute hybrid flow combining parallel and sequential processing"""
        
        agent_responses = {}
        agent_durations = {}
        total_cost = 0.0
        error_count = 0
        
        try:
            # Process parallel groups in sequence
            for group in flow.parallel_groups:
                if len(group) == 1:
                    # Single agent - process directly
                    agent_role = group[0]
                    if agent_role not in self.agents:
                        continue
                    
                    agent_start = time.time()
                    
                    # Enhance request with accumulated context
                    enhanced_request = self._enhance_request_with_context(
                        request, shared_context, agent_responses
                    )
                    
                    try:
                        async with self.agent_locks[agent_role]:
                            response = await self._process_agent_with_timeout(
                                agent_role, enhanced_request, timeout_ms=300
                            )
                        
                        agent_responses[agent_role.value] = response
                        agent_durations[agent_role.value] = int((time.time() - agent_start) * 1000)
                        total_cost += response.cost
                        
                        # Update shared context
                        shared_context.update(response.context_updates)
                        
                    except Exception as e:
                        self.logger.error(f"Error processing {agent_role.value}: {e}")
                        error_count += 1
                        
                else:
                    # Multiple agents - process in parallel
                    group_start = time.time()
                    group_tasks = []
                    
                    for agent_role in group:
                        if agent_role in self.agents:
                            enhanced_request = self._enhance_request_with_context(
                                request, shared_context, agent_responses
                            )
                            
                            task = asyncio.create_task(
                                self._process_agent_safely(agent_role, enhanced_request)
                            )
                            group_tasks.append((agent_role, task))
                    
                    # Wait for all agents in group
                    group_results = await asyncio.gather(
                        *[task for _, task in group_tasks],
                        return_exceptions=True
                    )
                    
                    # Process results
                    for (agent_role, _), result in zip(group_tasks, group_results):
                        if isinstance(result, Exception):
                            self.logger.error(f"Group processing error for {agent_role.value}: {result}")
                            error_count += 1
                        else:
                            agent_responses[agent_role.value] = result
                            agent_durations[agent_role.value] = int((time.time() - group_start) * 1000)
                            total_cost += result.cost
                            shared_context.update(result.context_updates)
            
            # Synthesize final response
            primary_response, confidence = await self._synthesize_responses(
                agent_responses, request, shared_context
            )
            
            # Calculate metrics
            metrics = ConversationMetrics(
                total_duration_ms=0,  # Will be set by caller
                agent_durations=agent_durations,
                parallel_efficiency=self._calculate_parallel_efficiency(agent_durations, flow),
                cost_breakdown={role: self.agent_cost_estimates.get(AgentRole(role), 0.001) 
                              for role in agent_responses.keys()},
                total_cost=total_cost,
                error_count=error_count,
                fallback_triggered=False
            )
            
            return OrchestrationResult(
                primary_response=primary_response,
                agent_contributions={k: v.message for k, v in agent_responses.items()},
                conversation_metrics=metrics,
                context_updates=shared_context,
                confidence_score=confidence,
                flow_completed=len(agent_responses) >= len(flow.sequence) // 2
            )
            
        except Exception as e:
            self.logger.error(f"Hybrid flow execution error: {e}")
            return await self._execute_fallback_flow(request, flow, shared_context)
    
    async def _execute_sequential_flow(
        self,
        request: AgentRequest,
        flow: AgentFlow,
        shared_context: Dict[str, Any]
    ) -> OrchestrationResult:
        """Execute sequential agent processing"""
        
        agent_responses = {}
        agent_durations = {}
        total_cost = 0.0
        
        for agent_role in flow.sequence:
            if agent_role not in self.agents:
                continue
            
            agent_start = time.time()
            
            # Build cumulative context
            enhanced_request = self._enhance_request_with_context(
                request, shared_context, agent_responses
            )
            
            try:
                async with self.agent_locks[agent_role]:
                    response = await self._process_agent_with_timeout(
                        agent_role, enhanced_request, timeout_ms=200
                    )
                
                agent_responses[agent_role.value] = response
                agent_durations[agent_role.value] = int((time.time() - agent_start) * 1000)
                total_cost += response.cost
                
                # Each agent builds on previous responses
                shared_context.update(response.context_updates)
                
            except Exception as e:
                self.logger.error(f"Sequential processing error for {agent_role.value}: {e}")
                break  # Sequential flow stops on error
        
        # Use last response as primary
        primary_response = list(agent_responses.values())[-1].message if agent_responses else "No response available"
        confidence = list(agent_responses.values())[-1].confidence if agent_responses else 0.3
        
        metrics = ConversationMetrics(
            total_duration_ms=0,
            agent_durations=agent_durations,
            parallel_efficiency=0.0,  # Sequential has no parallelism
            cost_breakdown={role: self.agent_cost_estimates.get(AgentRole(role), 0.001) 
                          for role in agent_responses.keys()},
            total_cost=total_cost,
            error_count=0,
            fallback_triggered=False
        )
        
        return OrchestrationResult(
            primary_response=primary_response,
            agent_contributions={k: v.message for k, v in agent_responses.items()},
            conversation_metrics=metrics,
            context_updates=shared_context,
            confidence_score=confidence,
            flow_completed=len(agent_responses) == len(flow.sequence)
        )
    
    async def _execute_parallel_flow(
        self,
        request: AgentRequest,
        flow: AgentFlow,
        shared_context: Dict[str, Any]
    ) -> OrchestrationResult:
        """Execute full parallel agent processing"""
        
        # Create tasks for all agents
        agent_tasks = []
        for agent_role in flow.sequence:
            if agent_role in self.agents:
                enhanced_request = self._enhance_request_with_context(
                    request, shared_context, {}
                )
                
                task = asyncio.create_task(
                    self._process_agent_safely(agent_role, enhanced_request)
                )
                agent_tasks.append((agent_role, task))
        
        # Wait for all agents
        start_time = time.time()
        results = await asyncio.gather(
            *[task for _, task in agent_tasks],
            return_exceptions=True
        )
        
        # Process results
        agent_responses = {}
        agent_durations = {}
        total_cost = 0.0
        error_count = 0
        
        for (agent_role, _), result in zip(agent_tasks, results):
            if isinstance(result, Exception):
                self.logger.error(f"Parallel processing error for {agent_role.value}: {result}")
                error_count += 1
            else:
                agent_responses[agent_role.value] = result
                agent_durations[agent_role.value] = int((time.time() - start_time) * 1000)
                total_cost += result.cost
                shared_context.update(result.context_updates)
        
        # Synthesize responses
        primary_response, confidence = await self._synthesize_responses(
            agent_responses, request, shared_context
        )
        
        metrics = ConversationMetrics(
            total_duration_ms=0,
            agent_durations=agent_durations,
            parallel_efficiency=1.0,  # Full parallelism
            cost_breakdown={role: self.agent_cost_estimates.get(AgentRole(role), 0.001) 
                          for role in agent_responses.keys()},
            total_cost=total_cost,
            error_count=error_count,
            fallback_triggered=False
        )
        
        return OrchestrationResult(
            primary_response=primary_response,
            agent_contributions={k: v.message for k, v in agent_responses.items()},
            conversation_metrics=metrics,
            context_updates=shared_context,
            confidence_score=confidence,
            flow_completed=len(agent_responses) >= len(flow.sequence) // 2
        )
    
    async def _execute_waterfall_flow(
        self,
        request: AgentRequest,
        flow: AgentFlow,
        shared_context: Dict[str, Any]
    ) -> OrchestrationResult:
        """Execute waterfall flow where each agent depends on previous results"""
        # Similar to sequential but with dependency checking
        return await self._execute_sequential_flow(request, flow, shared_context)
    
    async def _execute_fallback_flow(
        self,
        request: AgentRequest,
        flow: AgentFlow,
        shared_context: Dict[str, Any]
    ) -> OrchestrationResult:
        """Execute fallback flow when primary orchestration fails"""
        
        try:
            fallback_agent = self.agents.get(flow.fallback_agent)
            if not fallback_agent:
                # Ultimate fallback - use Alice if available
                fallback_agent = self.agents.get(AgentRole.GROWTH_ALICE) or self.agents.get(AgentRole.CLOUD_STUDENT)
            
            if fallback_agent:
                response = await fallback_agent.process_request(request)
                
                metrics = ConversationMetrics(
                    total_duration_ms=0,
                    agent_durations={flow.fallback_agent.value: 100},
                    parallel_efficiency=0.0,
                    cost_breakdown={flow.fallback_agent.value: 0.005},
                    total_cost=0.005,
                    error_count=1,
                    fallback_triggered=True
                )
                
                return OrchestrationResult(
                    primary_response=response.message,
                    agent_contributions={flow.fallback_agent.value: response.message},
                    conversation_metrics=metrics,
                    context_updates=response.context_updates,
                    confidence_score=response.confidence * 0.7,  # Reduced confidence for fallback
                    flow_completed=False
                )
            
        except Exception as e:
            self.logger.error(f"Fallback flow error: {e}")
        
        # Ultimate emergency response
        return OrchestrationResult(
            primary_response="I apologize, but I'm experiencing technical difficulties. Please try again.",
            agent_contributions={},
            conversation_metrics=ConversationMetrics(
                total_duration_ms=0,
                agent_durations={},
                parallel_efficiency=0.0,
                cost_breakdown={},
                total_cost=0.0,
                error_count=1,
                fallback_triggered=True
            ),
            context_updates={},
            confidence_score=0.1,
            flow_completed=False
        )
    
    async def _process_agent_with_timeout(
        self,
        agent_role: AgentRole,
        request: AgentRequest,
        timeout_ms: int = 300
    ) -> AgentResponse:
        """Process agent request with timeout"""
        
        agent = self.agents[agent_role]
        
        # Handle special case for Alice engine
        if agent_role == AgentRole.GROWTH_ALICE and hasattr(agent, 'generate_response'):
            # Alice engine interface
            response_text = await asyncio.wait_for(
                agent.generate_response(request.message, context=request.context),
                timeout=timeout_ms / 1000
            )
            
            return AgentResponse(
                agent_id=f"alice_{int(time.time())}",
                message=response_text,
                confidence=0.8,
                context_updates={"alice_response": True},
                metadata={"agent_type": "alice"},
                timestamp=datetime.now(),
                processing_time=timeout_ms,
                cost=self.agent_cost_estimates[agent_role]
            )
        else:
            # Standard agent interface
            return await asyncio.wait_for(
                agent.process_request(request),
                timeout=timeout_ms / 1000
            )
    
    async def _process_agent_safely(
        self,
        agent_role: AgentRole,
        request: AgentRequest
    ) -> AgentResponse:
        """Process agent request with error handling"""
        try:
            return await self._process_agent_with_timeout(agent_role, request)
        except asyncio.TimeoutError:
            self.logger.warning(f"Agent {agent_role.value} timed out")
            return AgentResponse(
                agent_id=f"{agent_role.value}_timeout",
                message="Agent processing timed out",
                confidence=0.2,
                context_updates={},
                metadata={"timeout": True},
                timestamp=datetime.now(),
                processing_time=300,
                cost=0.001
            )
        except Exception as e:
            self.logger.error(f"Agent {agent_role.value} error: {e}")
            return AgentResponse(
                agent_id=f"{agent_role.value}_error",
                message="Agent encountered an error",
                confidence=0.1,
                context_updates={},
                metadata={"error": str(e)},
                timestamp=datetime.now(),
                processing_time=50,
                cost=0.0
            )
    
    def _enhance_request_with_context(
        self,
        original_request: AgentRequest,
        shared_context: Dict[str, Any],
        agent_responses: Dict[str, AgentResponse]
    ) -> AgentRequest:
        """Enhance request with accumulated context from previous agents"""
        
        enhanced_context = {
            **original_request.context,
            **shared_context,
            "previous_agent_responses": {
                agent: response.message for agent, response in agent_responses.items()
            },
            "orchestration_flow": True,
            "response_count": len(agent_responses)
        }
        
        return AgentRequest(
            user_id=original_request.user_id,
            message=original_request.message,
            context=enhanced_context,
            timestamp=original_request.timestamp,
            conversation_id=original_request.conversation_id,
            requester_agent="orchestrator"
        )
    
    async def _prepare_shared_context(
        self,
        request: AgentRequest,
        additional_context: Dict[str, Any]
    ) -> Dict[str, Any]:
        """Prepare shared context using ChromaDB"""
        
        try:
            # Get user's conversation history and patterns
            user_collection = await asyncio.to_thread(
                self.collections_manager.get_or_create_user_collection,
                request.user_id
            )
            
            # Search for relevant context
            relevant_docs = await asyncio.to_thread(
                user_collection.query,
                query_texts=[request.message],
                n_results=5
            )
            
            shared_context = {
                "user_id": request.user_id,
                "conversation_id": request.conversation_id,
                "relevant_history": relevant_docs.get("documents", []),
                "orchestration_timestamp": datetime.now().isoformat(),
                **additional_context
            }
            
            # Store shared context in Redis for agent access
            context_key = f"shared_context:{request.conversation_id}"
            await asyncio.to_thread(
                self.redis_client.setex,
                context_key,
                300,  # 5 minutes TTL
                json.dumps(shared_context)
            )
            
            return shared_context
            
        except Exception as e:
            self.logger.error(f"Error preparing shared context: {e}")
            return additional_context
    
    async def _synthesize_responses(
        self,
        agent_responses: Dict[str, AgentResponse],
        request: AgentRequest,
        context: Dict[str, Any]
    ) -> Tuple[str, float]:
        """Synthesize multiple agent responses into final response"""
        
        if not agent_responses:
            return "No agent responses available", 0.1
        
        # If we have transcendent agent response, use it as primary
        if "transcendent" in agent_responses:
            transcendent_response = agent_responses["transcendent"]
            return transcendent_response.message, transcendent_response.confidence
        
        # If we have cloud student response, use it
        if "cloud_student" in agent_responses:
            cloud_student_response = agent_responses["cloud_student"]
            return cloud_student_response.message, cloud_student_response.confidence
        
        # Otherwise, use highest confidence response
        best_response = max(agent_responses.values(), key=lambda r: r.confidence)
        return best_response.message, best_response.confidence
    
    def _calculate_parallel_efficiency(
        self,
        agent_durations: Dict[str, int],
        flow: AgentFlow
    ) -> float:
        """Calculate parallel processing efficiency"""
        
        if not agent_durations:
            return 0.0
        
        # Efficiency = (sequential_time - parallel_time) / sequential_time
        sequential_time = sum(agent_durations.values())
        parallel_time = max(agent_durations.values()) if agent_durations else 0
        
        if sequential_time == 0:
            return 0.0
        
        return max(0.0, (sequential_time - parallel_time) / sequential_time)
    
    # Aggressive caching methods
    
    async def _get_aggressive_cached_result(
        self,
        request: AgentRequest,
        mode: ConversationMode,
        context: Dict[str, Any]
    ) -> Optional[OrchestrationResult]:
        """Get cached result with more aggressive caching strategy"""
        
        try:
            # Generate multiple cache keys for different levels of similarity
            cache_keys = [
                self._generate_cache_key(request, mode),  # Exact match
                self._generate_semantic_cache_key(request, mode),  # Semantic similarity
                self._generate_user_cache_key(request.user_id, mode)  # User pattern cache
            ]
            
            for cache_key in cache_keys:
                cached_data = await asyncio.to_thread(self.redis_client.get, cache_key)
                if cached_data:
                    try:
                        data = json.loads(cached_data)
                        # Check if cache is still valid
                        cache_age = time.time() - data.get("cached_at", 0)
                        if cache_age < self.cache_ttl_seconds:
                            return self._reconstruct_orchestration_result(data)
                    except Exception as e:
                        self.logger.error(f"Error reconstructing cached result: {e}")
                        continue
            
            return None
            
        except Exception as e:
            self.logger.error(f"Error getting aggressive cached result: {e}")
            return None
    
    async def _get_agent_cached_response(
        self,
        agent_role: AgentRole,
        request: AgentRequest
    ) -> Optional[AgentResponse]:
        """Get cached response for specific agent"""
        
        try:
            # Create agent-specific cache key
            agent_cache_key = f"agent_cache:{agent_role.value}:{self._hash_request_content(request)}"
            
            # Check memory cache first (fastest)
            if agent_cache_key in self.agent_response_cache:
                cache_entry = self.agent_response_cache[agent_cache_key]
                if time.time() - cache_entry["cached_at"] < 300:  # 5 minute memory cache
                    return cache_entry["response"]
            
            # Check Redis cache
            cached_data = await asyncio.to_thread(self.redis_client.get, agent_cache_key)
            if cached_data:
                data = json.loads(cached_data)
                cache_age = time.time() - data.get("cached_at", 0)
                if cache_age < self.cache_ttl_seconds:
                    # Reconstruct AgentResponse
                    response_data = data["response"]
                    return AgentResponse(
                        agent_id=response_data["agent_id"],
                        message=response_data["message"],
                        confidence=response_data["confidence"],
                        context_updates=response_data["context_updates"],
                        metadata=response_data.get("metadata", {}),
                        timestamp=datetime.fromisoformat(response_data["timestamp"]),
                        processing_time=response_data["processing_time"],
                        cost=response_data["cost"]
                    )
            
            return None
            
        except Exception as e:
            self.logger.error(f"Error getting agent cached response: {e}")
            return None
    
    async def _cache_agent_response(
        self,
        agent_role: AgentRole,
        request: AgentRequest,
        response: AgentResponse
    ):
        """Cache individual agent response"""
        
        try:
            agent_cache_key = f"agent_cache:{agent_role.value}:{self._hash_request_content(request)}"
            
            cache_data = {
                "response": {
                    "agent_id": response.agent_id,
                    "message": response.message,
                    "confidence": response.confidence,
                    "context_updates": response.context_updates,
                    "metadata": response.metadata,
                    "timestamp": response.timestamp.isoformat(),
                    "processing_time": response.processing_time,
                    "cost": response.cost
                },
                "cached_at": time.time()
            }
            
            # Store in memory cache (limited size)
            if len(self.agent_response_cache) < 1000:  # Prevent memory bloat
                self.agent_response_cache[agent_cache_key] = cache_data
            
            # Store in Redis with TTL
            await asyncio.to_thread(
                self.redis_client.setex,
                agent_cache_key,
                self.cache_ttl_seconds,
                json.dumps(cache_data)
            )
            
        except Exception as e:
            self.logger.error(f"Error caching agent response: {e}")
    
    async def _cache_result_aggressively(
        self,
        request: AgentRequest,
        agent_responses: Dict[str, AgentResponse],
        primary_response: str
    ):
        """Cache orchestration result with multiple cache strategies"""
        
        try:
            cache_data = {
                "primary_response": primary_response,
                "agent_contributions": {k: v.message for k, v in agent_responses.items()},
                "cached_at": time.time(),
                "request_hash": self._hash_request_content(request)
            }
            
            # Cache with multiple keys for different hit strategies
            cache_keys = [
                f"orchestration_cache:{self._hash_request_content(request)}",
                f"user_cache:{request.user_id}:{hashlib.md5(request.message[:100].encode()).hexdigest()}",
                f"semantic_cache:{self._get_semantic_hash(request.message)}"
            ]
            
            for cache_key in cache_keys:
                await asyncio.to_thread(
                    self.redis_client.setex,
                    cache_key,
                    self.cache_ttl_seconds,
                    json.dumps(cache_data)
                )
            
        except Exception as e:
            self.logger.error(f"Error caching result aggressively: {e}")
    
    async def _synthesize_responses_optimized(
        self,
        agent_responses: Dict[str, AgentResponse],
        request: AgentRequest,
        context: Dict[str, Any]
    ) -> Tuple[str, float]:
        """Optimized response synthesis with fallback strategies"""
        
        if not agent_responses:
            return "I'm gathering insights to help you with your request.", 0.4
        
        # Priority-based synthesis
        synthesis_priority = [
            "transcendent",    # Best for philosophical synthesis
            "cloud_student",   # Good orchestration
            "teacher",         # Strong educational content
            "narrative",       # Engaging storytelling
            "growth_alice",    # Personal growth focus
            "context",         # Good context awareness
            "fortress"         # Safety-focused
        ]
        
        # Find the highest priority agent with a good response
        for agent_name in synthesis_priority:
            if agent_name in agent_responses:
                response = agent_responses[agent_name]
                if response.confidence > 0.6 and len(response.message) > 50:
                    return response.message, response.confidence
        
        # If no high-quality response, combine top responses
        if len(agent_responses) >= 2:
            # Get top 2 responses by confidence
            top_responses = sorted(
                agent_responses.items(),
                key=lambda x: x[1].confidence,
                reverse=True
            )[:2]
            
            combined_message = f"{top_responses[0][1].message}\n\n{top_responses[1][1].message}"
            combined_confidence = sum(r[1].confidence for r in top_responses) / len(top_responses)
            
            return combined_message, combined_confidence
        
        # Fallback to any available response
        best_response = max(agent_responses.values(), key=lambda r: r.confidence)
        return best_response.message, best_response.confidence
    
    # Performance monitoring and profiling
    
    async def _update_agent_performance_profile(
        self,
        agent_id: str,
        success: bool = False,
        error: bool = False,
        timeout: bool = False,
        duration_ms: int = 0,
        cache_hit: bool = False
    ):
        """Update performance profile for an agent"""
        
        if agent_id not in self.agent_performance_profiles:
            self.agent_performance_profiles[agent_id] = AgentPerformanceProfile(
                agent_id=agent_id,
                call_count=0,
                total_duration_ms=0,
                average_duration_ms=0.0,
                max_duration_ms=0,
                min_duration_ms=float('inf'),
                timeout_count=0,
                error_count=0,
                cache_hit_rate=0.0
            )
        
        profile = self.agent_performance_profiles[agent_id]
        profile.call_count += 1
        
        if success:
            profile.total_duration_ms += duration_ms
            profile.average_duration_ms = profile.total_duration_ms / profile.call_count
            profile.max_duration_ms = max(profile.max_duration_ms, duration_ms)
            profile.min_duration_ms = min(profile.min_duration_ms, duration_ms) if duration_ms > 0 else profile.min_duration_ms
        
        if error:
            profile.error_count += 1
        
        if timeout:
            profile.timeout_count += 1
        
        # Update cache hit rate
        if cache_hit:
            profile.cache_hit_rate = (profile.cache_hit_rate * (profile.call_count - 1) + 1.0) / profile.call_count
        else:
            profile.cache_hit_rate = (profile.cache_hit_rate * (profile.call_count - 1)) / profile.call_count
    
    def _capture_profile_data(self, profiler: cProfile.Profile) -> Dict[str, Any]:
        """Capture and analyze profiler data"""
        
        try:
            # Capture profile stats
            stats_stream = StringIO()
            stats = pstats.Stats(profiler, stream=stats_stream)
            stats.sort_stats('cumulative')
            stats.print_stats(20)  # Top 20 functions
            
            profile_text = stats_stream.getvalue()
            
            # Extract key metrics
            bottlenecks = []
            for line in profile_text.split('\n')[5:25]:  # Skip header, get top 20
                if line.strip() and not line.startswith('Ordered'):
                    parts = line.strip().split()
                    if len(parts) >= 6:
                        bottlenecks.append({
                            "function": parts[-1],
                            "calls": parts[0],
                            "total_time": parts[1],
                            "per_call": parts[2] if len(parts) > 2 else "0"
                        })
            
            return {
                "timestamp": datetime.now().isoformat(),
                "bottlenecks": bottlenecks[:10],
                "full_profile": profile_text[:2000]  # Truncate for storage
            }
            
        except Exception as e:
            self.logger.error(f"Error capturing profile data: {e}")
            return {"error": str(e)}
    
    # Utility methods for caching
    
    def _hash_request_content(self, request: AgentRequest) -> str:
        """Generate hash for request content"""
        content = f"{request.user_id}:{request.message}:{json.dumps(request.context, sort_keys=True)}"
        return hashlib.md5(content.encode()).hexdigest()
    
    def _get_semantic_hash(self, message: str) -> str:
        """Generate semantic hash for message (simplified)"""
        # Simplified semantic hashing - could be enhanced with embeddings
        words = message.lower().split()
        key_words = [w for w in words if len(w) > 3][:10]  # Take first 10 significant words
        return hashlib.md5(' '.join(sorted(key_words)).encode()).hexdigest()
    
    def _generate_semantic_cache_key(self, request: AgentRequest, mode: ConversationMode) -> str:
        """Generate semantic similarity cache key"""
        semantic_content = f"{request.user_id}:{self._get_semantic_hash(request.message)}:{mode.value}"
        return f"semantic_cache:{hashlib.md5(semantic_content.encode()).hexdigest()}"
    
    def _generate_user_cache_key(self, user_id: str, mode: ConversationMode) -> str:
        """Generate user pattern cache key"""
        return f"user_pattern_cache:{user_id}:{mode.value}"
    
    def _reconstruct_orchestration_result(self, data: Dict[str, Any]) -> OrchestrationResult:
        """Reconstruct OrchestrationResult from cached data"""
        return OrchestrationResult(
            primary_response=data.get("primary_response", ""),
            agent_contributions=data.get("agent_contributions", {}),
            conversation_metrics=ConversationMetrics(
                total_duration_ms=100,  # Cached response
                agent_durations={},
                parallel_efficiency=1.0,
                cost_breakdown={},
                total_cost=0.0,
                error_count=0,
                fallback_triggered=False
            ),
            context_updates={},
            confidence_score=0.8,  # Cached responses get good confidence
            flow_completed=True,
            streaming_responses=[]
        )
    
    # Caching and optimization methods
    
    def _generate_cache_key(self, request: AgentRequest, mode: ConversationMode) -> str:
        """Generate cache key for request"""
        content = f"{request.user_id}:{request.message}:{mode.value}"
        return f"orchestration_cache:{hashlib.md5(content.encode()).hexdigest()}"
    
    async def _get_cached_result(self, cache_key: str) -> Optional[OrchestrationResult]:
        """Get cached orchestration result"""
        try:
            cached_data = await asyncio.to_thread(self.redis_client.get, cache_key)
            if cached_data:
                data = json.loads(cached_data)
                # Reconstruct OrchestrationResult from dict
                metrics_data = data["conversation_metrics"]
                metrics = ConversationMetrics(**metrics_data)
                
                return OrchestrationResult(
                    primary_response=data["primary_response"],
                    agent_contributions=data["agent_contributions"],
                    conversation_metrics=metrics,
                    context_updates=data["context_updates"],
                    confidence_score=data["confidence_score"],
                    flow_completed=data["flow_completed"]
                )
        except Exception as e:
            self.logger.error(f"Error getting cached result: {e}")
        
        return None
    
    async def _cache_result(self, cache_key: str, result: OrchestrationResult):
        """Cache orchestration result"""
        try:
            # Convert to dict for JSON serialization
            cache_data = {
                "primary_response": result.primary_response,
                "agent_contributions": result.agent_contributions,
                "conversation_metrics": asdict(result.conversation_metrics),
                "context_updates": result.context_updates,
                "confidence_score": result.confidence_score,
                "flow_completed": result.flow_completed
            }
            
            await asyncio.to_thread(
                self.redis_client.setex,
                cache_key,
                300,  # 5 minutes cache
                json.dumps(cache_data)
            )
            
        except Exception as e:
            self.logger.error(f"Error caching result: {e}")
    
    async def _log_metrics(self, request: AgentRequest, result: OrchestrationResult):
        """Log performance metrics to monitoring system"""
        
        metrics_data = {
            "conversation_id": request.conversation_id,
            "user_id": request.user_id,
            "total_duration_ms": result.conversation_metrics.total_duration_ms,
            "total_cost": result.conversation_metrics.total_cost,
            "agent_count": len(result.agent_contributions),
            "confidence_score": result.confidence_score,
            "parallel_efficiency": result.conversation_metrics.parallel_efficiency,
            "error_count": result.conversation_metrics.error_count,
            "fallback_triggered": result.conversation_metrics.fallback_triggered,
            "timestamp": datetime.now().isoformat()
        }
        
        # Store in Redis for monitoring system pickup
        metrics_key = f"orchestration_metrics:{request.conversation_id}"
        await asyncio.to_thread(
            self.redis_client.setex,
            metrics_key,
            3600,  # 1 hour retention
            json.dumps(metrics_data)
        )
        
        # Log performance warnings
        if result.conversation_metrics.total_duration_ms > self.target_response_time_ms:
            self.logger.warning(f"Performance: {result.conversation_metrics.total_duration_ms}ms > {self.target_response_time_ms}ms target")
        
        if result.conversation_metrics.total_cost > self.cost_target_per_conversation:
            self.logger.warning(f"Cost: ${result.conversation_metrics.total_cost:.4f} > ${self.cost_target_per_conversation} target")
    
    async def _handle_orchestration_error(
        self,
        request: AgentRequest,
        error: Exception
    ) -> OrchestrationResult:
        """Handle orchestration errors with fallback"""
        
        self.logger.error(f"Orchestration error for {request.conversation_id}: {error}")
        
        # Try emergency fallback
        try:
            fallback_flow = self.conversation_flows[ConversationMode.EMERGENCY_FALLBACK] if ConversationMode.EMERGENCY_FALLBACK in self.conversation_flows else self.conversation_flows[ConversationMode.STANDARD_CHAT]
            return await self._execute_fallback_flow(request, fallback_flow, {})
        except:
            # Ultimate fallback
            return OrchestrationResult(
                primary_response="I'm experiencing technical difficulties. Please try again in a moment.",
                agent_contributions={},
                conversation_metrics=ConversationMetrics(
                    total_duration_ms=100,
                    agent_durations={},
                    parallel_efficiency=0.0,
                    cost_breakdown={},
                    total_cost=0.0,
                    error_count=1,
                    fallback_triggered=True
                ),
                context_updates={},
                confidence_score=0.1,
                flow_completed=False
            )
    
    # Public utility methods
    
    def get_orchestration_metrics(self) -> Dict[str, Any]:
        """Get current orchestration performance metrics"""
        return {
            "target_response_time_ms": self.target_response_time_ms,
            "max_response_time_ms": self.max_response_time_ms,
            "agent_timeout_ms": self.agent_timeout_ms,
            "parallel_timeout_ms": self.parallel_timeout_ms,
            "cost_target_per_conversation": self.cost_target_per_conversation,
            "available_agents": list(self.agents.keys()),
            "conversation_modes": list(self.conversation_flows.keys()),
            "monitoring_enabled": self.monitoring_enabled,
            "streaming_enabled": self.enable_response_streaming,
            "aggressive_caching_enabled": self.enable_aggressive_caching,
            "performance_profiling_enabled": self.enable_performance_profiling,
            "cache_ttl_seconds": self.cache_ttl_seconds,
            "cache_stats": self.response_cache_stats,
            "memory_cache_size": len(self.agent_response_cache)
        }
    
    def get_performance_analytics(self) -> Dict[str, Any]:
        """Get detailed performance analytics for all agents"""
        
        analytics = {
            "overall_stats": {
                "total_cache_hits": self.response_cache_stats["hits"],
                "total_cache_misses": self.response_cache_stats["misses"],
                "cache_hit_rate": self.response_cache_stats["hits"] / max(1, self.response_cache_stats["hits"] + self.response_cache_stats["misses"]),
                "memory_cache_entries": len(self.agent_response_cache),
                "agents_tracked": len(self.agent_performance_profiles)
            },
            "agent_profiles": {}
        }
        
        # Add agent-specific performance data
        for agent_id, profile in self.agent_performance_profiles.items():
            analytics["agent_profiles"][agent_id] = {
                "call_count": profile.call_count,
                "average_duration_ms": profile.average_duration_ms,
                "max_duration_ms": profile.max_duration_ms,
                "min_duration_ms": profile.min_duration_ms if profile.min_duration_ms != float('inf') else 0,
                "timeout_rate": profile.timeout_count / max(1, profile.call_count),
                "error_rate": profile.error_count / max(1, profile.call_count),
                "cache_hit_rate": profile.cache_hit_rate,
                "performance_grade": self._calculate_agent_performance_grade(profile)
            }
        
        return analytics
    
    def _calculate_agent_performance_grade(self, profile: AgentPerformanceProfile) -> str:
        """Calculate performance grade for an agent"""
        
        # Base score from 100
        score = 100
        
        # Deduct points for timeouts
        timeout_rate = profile.timeout_count / max(1, profile.call_count)
        score -= timeout_rate * 30
        
        # Deduct points for errors
        error_rate = profile.error_count / max(1, profile.call_count)
        score -= error_rate * 40
        
        # Add points for cache hits
        score += profile.cache_hit_rate * 10
        
        # Deduct points for slow performance
        if profile.average_duration_ms > 5000:  # Slower than 5s
            score -= 20
        elif profile.average_duration_ms > 2000:  # Slower than 2s
            score -= 10
        
        # Convert to letter grade
        if score >= 90:
            return "A"
        elif score >= 80:
            return "B"
        elif score >= 70:
            return "C"
        elif score >= 60:
            return "D"
        else:
            return "F"
    
    async def health_check(self) -> Dict[str, Any]:
        """Perform health check on all agents"""
        
        health_status = {}
        
        for agent_role, agent in self.agents.items():
            try:
                # Simple test request
                test_request = AgentRequest(
                    user_id="health_check",
                    message="Health check",
                    context={},
                    timestamp=datetime.now(),
                    conversation_id="health_check"
                )
                
                start_time = time.time()
                
                if agent_role == AgentRole.GROWTH_ALICE and hasattr(agent, 'generate_response'):
                    await asyncio.wait_for(agent.generate_response("test", {}), timeout=1.0)
                else:
                    await asyncio.wait_for(agent.process_request(test_request), timeout=1.0)
                
                response_time = int((time.time() - start_time) * 1000)
                
                health_status[agent_role.value] = {
                    "status": "healthy",
                    "response_time_ms": response_time
                }
                
            except Exception as e:
                health_status[agent_role.value] = {
                    "status": "unhealthy",
                    "error": str(e)
                }
        
        return {
            "overall_status": "healthy" if all(s["status"] == "healthy" for s in health_status.values()) else "degraded",
            "agent_health": health_status,
            "timestamp": datetime.now().isoformat()
        }