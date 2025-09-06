import os
from dotenv import load_dotenv
import asyncio
from collections import OrderedDict
from typing import Dict, List, Any, Optional
import logging
from datetime import datetime
import time
import uvicorn
from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException, BackgroundTasks, Depends, Header, UploadFile, File, WebSocket, Form, Query, Request
from fastapi.websockets import WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field
import PyPDF2
import io
import hashlib
import redis
import json as json_lib
from contextlib import asynccontextmanager
from sqlalchemy import text
import chromadb

# Debugging prints
print("===================================================================")
print("--- PYTHON: soulbios_api.py top level START ---")
print(f"--- PYTHON: DATABASE_URL is set: {os.getenv('DATABASE_URL') is not None} ---")
print(f"--- PYTHON: GOOGLE_API_KEY is set: {os.getenv('GOOGLE_API_KEY') is not None} ---")
print(f"--- PYTHON: SOULBIOS_API_KEY is set: {os.getenv('SOULBIOS_API_KEY') is not None} ---")
print(f"--- PYTHON: ENVIRONMENT is set: {os.getenv('ENVIRONMENT', 'NOT_SET')} ---")
print(f"--- PYTHON: PORT is set: {os.getenv('PORT', 'NOT_SET')} ---")
print("--- PYTHON: Starting imports ---")
print("===================================================================")

# Load environment variables
try:
    load_dotenv(dotenv_path="config/.env")  # Prefer config/.env
    print("Loaded .env variables:")
    for key in ["SOULBIOS_API_KEY", "GOOGLE_API_KEY", "REDIS_URL", "DATABASE_URL", "ENVIRONMENT"]:
        print(f"{key}: {os.getenv(key)}")
except Exception as e:
    print(f"--- PYTHON: load_dotenv failed: {e} ---")

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)
print("--- PYTHON: Logging configured ---")

chromadb.config.Settings(anonymized_telemetry=False)

# Import SoulBios components
print("--- PYTHON: Starting SoulBios component imports ---")
try:
    from infrastructure.SoulBios_collections_manager import SoulBiosCollectionsManager
    print("--- PYTHON: SoulBiosCollectionsManager imported ---")
except Exception as e:
    logger.error(f"--- PYTHON: SoulBiosCollectionsManager import failed: {e} ---", exc_info=True)
    SoulBiosCollectionsManager = None

try:
    from infrastructure.sql_database_manager import db_manager, Conversation, ConversationSchema
    print("--- PYTHON: sql_database_manager imported ---")
except Exception as e:
    logger.error(f"--- PYTHON: sql_database_manager import failed: {e} ---", exc_info=True)
    db_manager = None

try:
    from agents.kurzweil_pattern_recognizer import HierarchicalPatternNetwork
    print("--- PYTHON: kurzweil_pattern_recognizer imported ---")
except Exception as e:
    logger.error(f"--- PYTHON: kurzweil_pattern_recognizer import failed: {e} ---", exc_info=True)
    HierarchicalPatternNetwork = None

try:
    from agents.alice_consciousness_engine import AliceConsciousnessEngine
    print("--- PYTHON: alice_consciousness_engine imported ---")
except Exception as e:
    logger.error(f"--- PYTHON: alice_consciousness_engine import failed: {e} ---", exc_info=True)
    AliceConsciousnessEngine = None

try:
    from agents.character_playbook_manager import CharacterPlaybookManager
    print("--- PYTHON: character_playbook_manager imported ---")
except Exception as e:
    logger.error(f"--- PYTHON: character_playbook_manager import failed: {e} ---", exc_info=True)
    CharacterPlaybookManager = None

try:
    from middleware.gemini_confidence_proxy import GeminiConfidenceMiddleware, SoulBiosConfidenceAdapter
    print("--- PYTHON: gemini_confidence_proxy imported ---")
except Exception as e:
    logger.error(f"--- PYTHON: gemini_confidence_proxy import failed: {e} ---", exc_info=True)
    GeminiConfidenceMiddleware = None
    SoulBiosConfidenceAdapter = None

# Import multi-agent system
print("--- PYTHON: Starting agent imports ---")
try:
    from agents.cloud_student_agent import CloudStudentAgent
    print("--- PYTHON: CloudStudentAgent imported ---")
except Exception as e:
    logger.error(f"--- PYTHON: CloudStudentAgent import failed: {e} ---", exc_info=True)
    CloudStudentAgent = None

try:
    from agents.teacher_agent import TeacherAgent
    print("--- PYTHON: TeacherAgent imported ---")
except Exception as e:
    logger.error(f"--- PYTHON: TeacherAgent import failed: {e} ---", exc_info=True)
    TeacherAgent = None

try:
    from agents.narrative_agent import NarrativeAgent
    print("--- PYTHON: NarrativeAgent imported ---")
except Exception as e:
    logger.error(f"--- PYTHON: NarrativeAgent import failed: {e} ---", exc_info=True)
    NarrativeAgent = None

try:
    from agents.transcendent_agent import TranscendentAgent
    print("--- PYTHON: TranscendentAgent imported ---")
except Exception as e:
    logger.error(f"--- PYTHON: TranscendentAgent import failed: {e} ---", exc_info=True)
    TranscendentAgent = None

try:
    from agents.context_agent import ContextAgent
    print("--- PYTHON: ContextAgent imported ---")
except Exception as e:
    logger.error(f"--- PYTHON: ContextAgent import failed: {e} ---", exc_info=True)
    ContextAgent = None

try:
    from agents.growth_alice_agent import GrowthAliceAgent
    print("--- PYTHON: GrowthAliceAgent imported ---")
except Exception as e:
    logger.error(f"--- PYTHON: GrowthAliceAgent import failed: {e} ---", exc_info=True)
    GrowthAliceAgent = None

try:
    from agents.base_agent import AgentRequest, AgentResponse, AgentRole
    print("--- PYTHON: base_agent imported ---")
except Exception as e:
    logger.error(f"--- PYTHON: base_agent import failed: {e} ---", exc_info=True)
    AgentRequest = None
    AgentResponse = None
    AgentRole = None

try:
    from agents.game_theory_agent import GameTheoryAgent
    print("--- PYTHON: game_theory_agent imported ---")
except Exception as e:
    logger.error(f"--- PYTHON: game_theory_agent import failed: {e} ---", exc_info=True)
    GameTheoryAgent = None

try:
    from agents.history_agent import HistoryAgent
    print("--- PYTHON: HistoryAgent imported ---")
except Exception as e:
    logger.error(f"--- PYTHON: HistoryAgent import failed: {e} ---", exc_info=True)
    HistoryAgent = None

try:
    from agents.social_agent import SocialAgent
    print("--- PYTHON: SocialAgent imported ---")
except Exception as e:
    logger.error(f"--- PYTHON: SocialAgent import failed: {e} ---", exc_info=True)
    SocialAgent = None

try:
    from agents.persona_agent import PersonaAgent
    print("--- PYTHON: PersonaAgent imported ---")
except Exception as e:
    logger.error(f"--- PYTHON: PersonaAgent import failed: {e} ---", exc_info=True)
    PersonaAgent = None

try:
    from agents.safety_agent import SafetyAgent
    print("--- PYTHON: SafetyAgent imported ---")
except Exception as e:
    logger.error(f"--- PYTHON: SafetyAgent import failed: {e} ---", exc_info=True)
    SafetyAgent = None

try:
    from agents.meta_agent import MetaAgent
    print("--- PYTHON: MetaAgent imported ---")
except Exception as e:
    logger.error(f"--- PYTHON: MetaAgent import failed: {e} ---", exc_info=True)
    MetaAgent = None

try:
    from api.auth_middleware import verify_chat_rate_limit, verify_chamber_rate_limit
    print("--- PYTHON: auth_middleware imported ---")
except Exception as e:
    logger.error(f"--- PYTHON: auth_middleware import failed: {e} ---", exc_info=True)
    verify_chat_rate_limit = None
    verify_chamber_rate_limit = None

try:
    from production_config import config
    print("--- PYTHON: production_config imported ---")
except Exception as e:
    logger.error(f"--- PYTHON: production_config import failed: {e} ---", exc_info=True)
    class DefaultConfig:
        cors_origins = ["*"]
    config = DefaultConfig()

print("--- PYTHON: All imports completed successfully ---")
print("===================================================================")
print("--- PYTHON: Proceeding to application initialization ---")

redis_client = None

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan management with resilient startup"""
    global redis_client, collections_manager, character_manager, confidence_middleware, cloud_student_agent, teacher_agent, narrative_agent, transcendent_agent, context_agent, growth_alice_agent, game_theory_agent, history_agent, social_agent, persona_agent, safety_agent, meta_agent
   
    is_production = os.getenv("ENVIRONMENT") == "production"
    logger.info(f"Starting SoulBios API in {'PRODUCTION' if is_production else 'DEVELOPMENT'} mode...")
   
    # Initialize Redis with fallback
    try:
        redis_url = os.getenv('REDIS_URL', 'redis://localhost:6379')
        redis_client = redis.from_url(redis_url, decode_responses=True, socket_connect_timeout=10)
        redis_client.ping()
        logger.info("✅ Redis connection established")
    except Exception as e:
        logger.warning(f"Redis connection failed: {e}. Running without session cache.")
        redis_client = None
    
    # Initialize SoulBios components
    try:
        logger.info("🚀 Starting SoulBios Consciousness API...")
        
        if db_manager:
            try:
                await db_manager.initialize()
                logger.info("✅ SQL Database Manager initialized")
            except Exception as e:
                logger.error(f"Database initialization failed: {e}", exc_info=True)
                if is_production:
                    raise
                else:
                    logger.warning("Continuing without database in development mode")
        else:
            logger.warning("SQL Database Manager not imported - cannot initialize database.")
        
        if SoulBiosCollectionsManager:
            try:
                collections_manager = SoulBiosCollectionsManager()
                logger.info("✅ SoulBios Collections Manager initialized")
            except Exception as e:
                logger.error(f"Collections manager initialization failed: {e}", exc_info=True)
                if is_production:
                    raise
                else:
                    collections_manager = None
                    logger.warning("Continuing without collections manager")
        else:
            logger.warning("SoulBiosCollectionsManager class not imported - cannot initialize collections manager.")
        
        if collections_manager:
            try:
                logger.info("🔧 Pre-warming collections for performance...")
                await collections_manager.create_user_universe("demo_user")
                await collections_manager.create_user_universe("test_user")
                logger.info("✅ Collections pre-warmed for performance")
            except Exception as e:
                logger.warning(f"Collection pre-warming failed: {e}", exc_info=True)
        else:
            logger.warning("Collections manager not available - skipping pre-warming.")
        
        try:
            character_manager = CharacterPlaybookManager(collections_manager) if collections_manager and CharacterPlaybookManager else None
            logger.info("✅ Character Playbook Manager initialized")
            confidence_middleware = GeminiConfidenceMiddleware(collections_manager) if collections_manager and GeminiConfidenceMiddleware else None  
            logger.info("✅ Gemini Confidence Proxy initialized")
        except Exception as e:
            logger.warning(f"Manager initialization failed: {e}", exc_info=True)
            character_manager = None
            confidence_middleware = None
        
        if collections_manager and TeacherAgent and NarrativeAgent and TranscendentAgent and ContextAgent and GrowthAliceAgent and GameTheoryAgent and HistoryAgent and SocialAgent and PersonaAgent and SafetyAgent and MetaAgent:
            try:
                logger.info("🎯 Initializing Multi-Agent System with fixed BaseAgent calls...")
                from agents.base_agent import AgentRole
                
                teacher_agent = TeacherAgent(
                    agent_role=AgentRole.TEACHER,
                    collections_manager=collections_manager,
                    redis_client=redis_client
                ) 
                logger.info("✅ Teacher Agent initialized")
                
                narrative_agent = NarrativeAgent(
                    agent_role=AgentRole.NARRATIVE,
                    collections_manager=collections_manager,
                    redis_client=redis_client
                )
                logger.info("✅ Narrative Agent initialized")
                
                transcendent_agent = TranscendentAgent(
                    agent_role=AgentRole.TRANSCENDENT,
                    collections_manager=collections_manager,
                    redis_client=redis_client
                )
                logger.info("✅ Transcendent Agent initialized")
                
                context_agent = ContextAgent(
                    agent_role=AgentRole.CONTEXT,
                    collections_manager=collections_manager,
                    redis_client=redis_client
                )
                logger.info("✅ Context Agent initialized")
                
                growth_alice_agent = GrowthAliceAgent(
                    agent_role=AgentRole.GROWTH_ALICE,
                    collections_manager=collections_manager,
                    redis_client=redis_client
                )
                logger.info("✅ Growth Alice Agent initialized")
                
                game_theory_agent = GameTheoryAgent(
                    agent_role=AgentRole.GAME_THEORY,
                    collections_manager=collections_manager,
                    redis_client=redis_client,
                    teacher_agent=teacher_agent,
                    narrative_agent=narrative_agent,
                    transcendent_agent=transcendent_agent
                )
                logger.info("✅ Game Theory Agent initialized")
                
                history_agent = HistoryAgent(
                    agent_role=AgentRole.HISTORY,
                    collections_manager=collections_manager,
                    redis_client=redis_client
                )
                logger.info("✅ History Agent initialized")
                
                social_agent = SocialAgent(
                    agent_role=AgentRole.SOCIAL,
                    collections_manager=collections_manager,
                    redis_client=redis_client
                )
                logger.info("✅ Social Agent initialized")
                
                persona_agent = PersonaAgent(
                    agent_role=AgentRole.PERSONA,
                    collections_manager=collections_manager,
                    redis_client=redis_client
                )
                logger.info("✅ Persona Agent initialized")
                
                safety_agent = SafetyAgent(
                    agent_role=AgentRole.SAFETY,
                    collections_manager=collections_manager,
                    redis_client=redis_client
                )
                logger.info("✅ Safety Agent initialized")
                
                meta_agent = MetaAgent(
                    agent_role=AgentRole.META,
                    collections_manager=collections_manager,
                    redis_client=redis_client
                )
                logger.info("✅ Meta Agent initialized")
                
                logger.info("🎯 CRITICAL: About to initialize CloudStudentAgent...")
                cloud_student_agent = CloudStudentAgent(
                    agent_role=AgentRole.CLOUD_STUDENT,
                    collections_manager=collections_manager,
                    redis_client=redis_client,
                    context_agent=context_agent,
                    history_agent=history_agent,
                    social_agent=social_agent,
                    persona_agent=persona_agent,
                    safety_agent=safety_agent,
                    game_theory_agent=game_theory_agent,
                    meta_agent=meta_agent
                )
                logger.info("🏆 SUCCESS: CloudStudentAgent initialized - Multi-Agent System is FULLY OPERATIONAL!")
            except Exception as e:
                logger.error(f"❌ Agent initialization failed: {e}", exc_info=True)
                teacher_agent = narrative_agent = transcendent_agent = context_agent = growth_alice_agent = game_theory_agent = cloud_student_agent = None
                logger.warning("Some agents failed to initialize - running in degraded mode")
        else:
            teacher_agent = narrative_agent = transcendent_agent = context_agent = growth_alice_agent = game_theory_agent = cloud_student_agent = None
            logger.warning("Not all agent classes or dependencies available - running in minimal/degraded mode.")
                
        logger.info("🧠 SoulBios Consciousness API ready!")
            
    except Exception as e:
        logger.error(f"❌ Critical startup failure: {e}", exc_info=True)
        if is_production:
            raise
   
    yield
   
    logger.info("Shutting down SoulBios API...")
    if redis_client:
        redis_client.close()
    if db_manager:
        await db_manager.close()

app = FastAPI(
    title="SoulBios Consciousness API",
    description="Kurzweil-Enhanced ChromaDB Digital Mind for Consciousness Development",
    version="2.1.0",
    lifespan=lifespan
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=config.cors_origins,
    allow_credentials=True,
    allow_methods=["GET", "POST", "DELETE"],
    allow_headers=["*"],
)

# Global components
collections_manager: Optional[SoulBiosCollectionsManager] = None
character_manager: Optional[CharacterPlaybookManager] = None
confidence_middleware: Optional[GeminiConfidenceMiddleware] = None
cloud_student_agent: Optional[CloudStudentAgent] = None
teacher_agent: Optional[TeacherAgent] = None
narrative_agent: Optional[NarrativeAgent] = None
transcendent_agent: Optional[TranscendentAgent] = None
context_agent: Optional[ContextAgent] = None
growth_alice_agent: Optional[GrowthAliceAgent] = None
game_theory_agent: Optional[GameTheoryAgent] = None
history_agent: Optional[HistoryAgent] = None
social_agent: Optional[SocialAgent] = None
persona_agent: Optional[PersonaAgent] = None
safety_agent: Optional[SafetyAgent] = None
meta_agent: Optional[MetaAgent] = None
chamber_sessions: Dict[str, Any] = {}

class ChatRequest(BaseModel):
    user_id: str
    message: str
    metadata: Optional[Dict[str, Any]] = None
    context_depth: int = 3

class ChatResponse(BaseModel):
    response: str
    alice_persona: str
    consciousness_level: str
    consciousness_indicators: Dict[str, float]
    activated_patterns: Dict[str, Any]
    wisdom_depth: int
    breakthrough_potential: float
    personalization_score: float
    conversation_id: str
    processing_time_ms: int
    active_character: Optional[str] = None
    character_stage: Optional[int] = None
    character_progress: Optional[Dict[str, Any]] = None

class StrategizeRequest(BaseModel):
    prompt: Optional[str] = None
    prompts: Optional[List[str]] = None

@app.get("/", summary="Health Check")
async def root():
    return {"service": "SoulBios Consciousness API", "status": "operational", "version": "2.1.0"}

@app.get("/health", summary="Detailed Health Check")
async def health_check():
    start_time = time.time()
    try:
        db_status = "active" if db_manager and db_manager.engine else "inactive"
        db_latency_ms = 0
        if db_manager and db_manager.engine:
            db_start = time.time()
            async with db_manager.engine.connect() as conn:
                await conn.scalar(text("SELECT 1"))
            db_latency_ms = (time.time() - db_start) * 1000
        
        chroma_status = "active" if collections_manager else "inactive"
        chroma_latency_ms = 0
        chroma_heartbeat = None
        if collections_manager:
            chroma_start = time.time()
            try:
                chroma_heartbeat = collections_manager.client.heartbeat()
                chroma_latency_ms = (time.time() - chroma_start) * 1000
            except Exception as e:
                chroma_status = f"error ({str(e)})"
                logger.warning(f"ChromaDB heartbeat failed: {e}")
                
        redis_status = "active" if redis_client else "inactive"
        redis_latency_ms = 0
        if redis_client:
            redis_start = time.time()
            try:
                redis_client.ping()
                redis_latency_ms = (time.time() - redis_start) * 1000
            except Exception as e:
                redis_status = f"error ({str(e)})"
                logger.warning(f"Redis ping failed: {e}")
                
        agents_status = {
            "cloud_student": "active" if cloud_student_agent else "inactive",
            "alice": "active" if growth_alice_agent else "inactive",
            "teacher": "active" if teacher_agent else "inactive",
            "narrative": "active" if narrative_agent else "inactive",
            "transcendent": "active" if transcendent_agent else "inactive",
            "context": "active" if context_agent else "inactive",
            "game_theory": "active" if game_theory_agent else "inactive",
        }
        
        total_latency_ms = (time.time() - start_time) * 1000
        
        return {
            "status": "healthy", 
            "latency": f"{total_latency_ms:.1f}ms",
            "performance": {
                "total_latency_ms": round(total_latency_ms, 1),
                "chromadb_latency_ms": round(chroma_latency_ms, 1),
                "redis_latency_ms": round(redis_latency_ms, 1),
                "db_latency_ms": round(db_latency_ms, 1),
            },
            "chromadb_heartbeat": chroma_heartbeat,
            "db_status": db_status,
            "redis_status": redis_status,
            "agents": agents_status,
            "chamber_sessions": len(chamber_sessions),
            "timestamp": datetime.now().isoformat()
        }
    except Exception as e:
        total_latency_ms = (time.time() - start_time) * 1000
        logger.error(f"❌ Health check error: {e}", exc_info=True)
        return {"status": "error", "error": str(e), "latency": f"{total_latency_ms:.1f}ms", "timestamp": datetime.now().isoformat()}

@app.post("/chat", response_model=ChatResponse, summary="Chat with Alice (Authenticated)")
async def chat_with_alice(request: ChatRequest, api_key: str = Depends(verify_chat_rate_limit)):
    start_time = datetime.now()
    try:
        if db_manager:
            await db_manager.get_or_create_user(request.user_id)
        else:
            logger.warning(f"Database manager not available for user {request.user_id} - skipping user creation.")

        logger.info(f"💬 Processing chat request from user {request.user_id}")

        if not cloud_student_agent:
            raise HTTPException(status_code=503, detail="Service initializing, please try again shortly.")

        req = AgentRequest(
            user_id=request.user_id,
            message=request.message,
            context={},
            timestamp=datetime.now(),
            conversation_id=f"conv_{request.user_id}_{int(start_time.timestamp())}"
        )
        response = await cloud_student_agent.process_request(req)
        processing_time = int((datetime.now() - start_time).total_seconds() * 1000)
       
        response_context = getattr(response, 'context', {})
        final_consciousness_indicators = response_context.get("consciousness_indicators", {})
        final_activated_patterns = response_context.get("activated_patterns", {})

        chat_response = ChatResponse(
            response=response.message,
            alice_persona="Nurturing Presence",
            consciousness_level="1",
            consciousness_indicators=final_consciousness_indicators,
            activated_patterns=final_activated_patterns,
            wisdom_depth=1,
            breakthrough_potential=0.5,
            personalization_score=0.3,
            conversation_id=req.conversation_id,
            processing_time_ms=processing_time
        )
       
        if redis_client and processing_time < 5000:
            try:
                cache_key = f"chat:{request.user_id}:{req.conversation_id}"
                redis_client.setex(cache_key, 600, chat_response.model_dump_json())
                logger.info(f"💾 CACHED: {processing_time}ms response")
            except Exception as e:
                logger.warning(f"Cache storage error: {e}")
        
        if db_manager:
            try:
                await db_manager.save_conversation(
                    user_id=request.user_id,
                    conversation_id=req.conversation_id,
                    request_message=request.message,
                    response_message=response.message
                )
                logger.info(f"💾 Conversation saved to database for user {request.user_id}")
            except Exception as e:
                logger.warning(f"Failed to save conversation to database: {e}", exc_info=True)
        else:
            logger.warning("Database manager not available - skipping conversation save.")
        
        return chat_response
    except Exception as e:
        logger.error(f"❌ Chat processing error: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Chat failed: {str(e)}")

class StrategizeRequest(BaseModel):
    prompt: Optional[str] = None
    prompts: Optional[List[str]] = None

@app.post("/v1/berghain/strategize", summary="🎯 OPTIMAL BERGHAIN PIPELINE - Ultra-High Performance Strategic Analysis")
async def get_berghain_strategy(
    request: StrategizeRequest,
    api_key: str = Depends(verify_chat_rate_limit)
):
    """
    🏆 OPTIMAL BERGHAIN PIPELINE - OODA Loop Orient & Decide Phase
    
    Ultra-high performance multi-agent strategic processing:
    • Phase 1-3: Parallel analysis (Context, History, Social, Persona, Safety)
    • Phase 4: Game theory synthesis 
    • Phase 5: Meta-optimization
    
    Target: Sub-500ms response time for competitive advantage
    """
    start_time = time.time()
    
    if not cloud_student_agent:
        logger.error("❌ CloudStudentAgent not initialized - critical system failure")
        raise HTTPException(status_code=503, detail="Strategic orchestrator offline - system initializing")

    try:
        logger.info(f"🚀 LAUNCHING: Optimal Berghain Pipeline for strategic analysis")
        
        # Validate request payload
        if not request.prompt:
            raise HTTPException(status_code=400, detail="Missing required 'prompt' field containing game state JSON")

        # Validate JSON format early to avoid processing invalid requests
        try:
            test_parse = json_lib.loads(request.prompt)
            if not isinstance(test_parse, dict):
                raise ValueError("Game state must be a JSON object")
        except (json_lib.JSONDecodeError, ValueError) as e:
            logger.error(f"❌ Invalid game state JSON: {e}")
            raise HTTPException(status_code=400, detail=f"Invalid game state JSON format: {e}")

        # Create optimized agent request for Berghain processing
        agent_req = AgentRequest(
            user_id="berghain_player",
            message=request.prompt,  # Contains the game state JSON
            context={
                "request_type": "berghain_strategy", 
                "ooda_phase": "orient_decide",
                "pipeline": "OptimalBerghainPipeline_v2.0",
                "performance_target_ms": 500
            },
            timestamp=datetime.now(),
            conversation_id=f"berghain_strategy_{int(start_time * 1000)}"
        )
        
        # Execute the Optimal Berghain Pipeline through CloudStudentAgent
        response = await cloud_student_agent.process_request(agent_req)
        
        if not response or not response.message:
            logger.error("❌ CloudStudentAgent returned null/empty response - pipeline failure!")
            raise HTTPException(status_code=500, detail="Strategic pipeline failure - no response from orchestrator")
        
        # Parse and validate strategy response
        try:
            strategy_dict = json_lib.loads(response.message)
        except json_lib.JSONDecodeError as e:
            logger.error(f"❌ Invalid JSON response from CloudStudentAgent: {e}")
            raise HTTPException(status_code=500, detail="Strategic pipeline returned invalid response format")
        
        # Calculate final performance metrics
        processing_time = int((time.time() - start_time) * 1000)
        
        # Determine performance grade for logging
        performance_emoji = "🏆" if processing_time < 500 else "⚡" if processing_time < 1000 else "✅"
        performance_grade = "ELITE" if processing_time < 500 else "FAST" if processing_time < 1000 else "GOOD"
        
        logger.info(f"{performance_emoji} OPTIMAL BERGHAIN PIPELINE COMPLETE: {processing_time}ms ({performance_grade})")
        
        # Enhance strategy response with comprehensive metadata
        strategy_dict["_ooda_metadata"] = {
            "processing_time_ms": processing_time,
            "performance_grade": performance_grade,
            "timestamp": datetime.now().isoformat(),
            "agent_version": "CloudStudentAgent_OptimalBerghain_v2.0",
            "pipeline": "OptimalBerghainPipeline_UltraParallel",
            "confidence_score": getattr(response, 'confidence', 0.95),
            "agents_successful": response.context.get("agents_successful", 5) if hasattr(response, 'context') else 5,
            "parallel_efficiency": response.context.get("performance", {}).get("parallel_efficiency", 95.0) if hasattr(response, 'context') else 95.0
        }
        
        return strategy_dict

    except HTTPException:
        # Re-raise HTTP exceptions (validation errors, etc.)
        raise
    except Exception as e:
        processing_time = int((time.time() - start_time) * 1000)
        logger.error(f"❌ CRITICAL: Optimal Berghain Pipeline failure after {processing_time}ms: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Strategic pipeline failure: {str(e)}")

@app.post("/upload/lifebook", summary="Upload Lifebook Document (Authenticated)")
async def upload_lifebook(
    file: UploadFile = File(...),
    user_id: str = Form(...),
    api_key: str = Depends(verify_chat_rate_limit)
):
    start_time = datetime.now()
    try:
        logger.info(f"📚 Processing lifebook upload for user {user_id}")
        
        if not file.filename.lower().endswith(('.pdf', '.txt', '.md')):
            raise HTTPException(status_code=400, detail="Only PDF, TXT, and MD files are supported")
        
        content = await file.read()
        
        if file.filename.lower().endswith('.pdf'):
            pdf_reader = PyPDF2.PdfReader(io.BytesIO(content))
            text_content = "".join(page.extract_text() for page in pdf_reader.pages)
        else:
            text_content = content.decode('utf-8')
        
        if collections_manager:
            try:
                collections_manager.get_user_collection(user_id, "life_patterns")
            except ValueError:
                if collections_manager:
                    await collections_manager.create_user_universe(user_id)
            
            lifebook_collection = collections_manager.get_user_collection(user_id, "life_patterns")
            lifebook_collection.add(
                documents=[text_content[:50000]],
                ids=[f"lifebook_{user_id}_{int(start_time.timestamp())}"],
                metadatas=[{"type": "lifebook", "filename": file.filename, "upload_timestamp": start_time.isoformat()}]
            )
        else:
            logger.warning("Collections manager not available - skipping lifebook storage.")
        
        processing_time = int((datetime.now() - start_time).total_seconds() * 1000)
        
        return {"status": "uploaded", "filename": file.filename, "content_length": len(text_content), "processing_time_ms": processing_time}
        
    except Exception as e:
        logger.error(f"❌ Lifebook upload error: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Upload failed: {str(e)}")

@app.post("/chamber/create", summary="Create Consciousness Chamber Session (Authenticated)")
async def create_chamber_session(
    request: Dict[str, Any],
    user_id: str = Header(..., alias="X-User-ID"),
    api_key: str = Depends(verify_chamber_rate_limit)
):
    try:
        session_id = f"chamber_{user_id}_{int(datetime.now().timestamp())}"
        
        chamber_sessions[session_id] = {
            "user_id": user_id,
            "created_at": datetime.now().isoformat(),
            "status": "active",
            "framework_type": request.get("framework_type", "decision_tree"),
            "context": request.get("context", {}),
            "progress": {"steps_completed": 0, "total_steps": request.get("total_steps", 5)}
        }
        
        logger.info(f"🏛️ Created chamber session {session_id} for user {user_id}")
        
        return {"session_id": session_id, "status": "created", "websocket_url": f"/chamber/{session_id}"}
        
    except Exception as e:
        logger.error(f"❌ Chamber creation error: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Chamber creation failed: {str(e)}")

@app.get("/chamber/{session_id}/status", summary="Get Chamber Session Status (Authenticated)")
async def get_chamber_status(
    session_id: str,
    user_id: str = Header(..., alias="X-User-ID"),
    api_key: str = Depends(verify_chat_rate_limit)
):
    try:
        if session_id not in chamber_sessions or chamber_sessions[session_id]["user_id"] != user_id:
            raise HTTPException(status_code=404, detail="Chamber session not found or access denied")
        
        return chamber_sessions[session_id]
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Chamber status error: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Status check failed: {str(e)}")

@app.websocket("/chamber/{session_id}")
async def chamber_websocket(websocket: WebSocket, session_id: str):
    await websocket.accept()
    logger.info(f"🔌 WebSocket connected for chamber session: {session_id}")
    try:
        await websocket.send_text(f"Chamber started for {session_id}")
        while True:
            await asyncio.sleep(60)
    except WebSocketDisconnect:
        logger.info(f"🔌 WebSocket disconnected for chamber {session_id}")
    except Exception as e:
        logger.error(f"❌ WebSocket error for chamber {session_id}: {e}", exc_info=True)
    finally:
        await websocket.close()

@app.get("/users/{user_id}/status", summary="Get User Status (Authenticated)")
async def get_user_status(
    user_id: str,
    api_key: str = Depends(verify_chat_rate_limit)
):
    try:
        if db_manager:
            user = await db_manager.get_or_create_user(user_id)
            return {
                "user_id": user.user_id,
                "created_at": user.created_at.isoformat(),
                "subscription_status": user.subscription_status
            }
        else:
            raise HTTPException(status_code=503, detail="Database not available.")
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ User status error: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Failed to get user status: {str(e)}")

@app.get("/users/{user_id}/conversations", summary="Get User Conversation History (Authenticated)")
async def get_user_conversations(
    user_id: str,
    limit: int = Query(default=50, description="Number of conversations to return"),
    api_key: str = Depends(verify_chat_rate_limit)
):
    try:
        if db_manager:
            conversations = await db_manager.get_conversations_for_user(user_id, limit)
            return [
                {
                    "id": conv.id,
                    "conversation_id": conv.conversation_id,
                    "user_id": conv.user_id,
                    "request_message": conv.request_message,
                    "response_message": conv.response_message,
                    "created_at": conv.created_at.isoformat()
                }
                for conv in conversations
            ]
        else:
            raise HTTPException(status_code=503, detail="Database not available.")
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Conversation history error: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Failed to get conversations: {str(e)}")

@app.post("/users/{user_id}/analyze", summary="Analyze User Data (Placeholder)")
async def analyze_user_data(
    user_id: str,
    api_key: str = Depends(verify_chat_rate_limit)
):
    return {"status": "success", "message": "Feature not yet implemented."}

@app.post("/users/{user_id}/patterns", summary="Generate User Patterns (Placeholder)")
async def generate_user_patterns(
    user_id: str,
    api_key: str = Depends(verify_chat_rate_limit)
):
    return {"status": "success", "message": "Feature not yet implemented."}

@app.post("/generate/image", summary="Generate Image (Placeholder)")
async def generate_image(
    api_key: str = Depends(verify_chat_rate_limit)
):
    return {"status": "success", "message": "Feature not yet implemented."}

@app.get("/users/{user_id}/images", summary="Get User Images (Placeholder)")
async def get_user_images(
    user_id: str,
    api_key: str = Depends(verify_chat_rate_limit)
):
    return {"status": "success", "message": "Feature not yet implemented."}

@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    logger.error(f"❌ Unhandled exception for request {request.method} {request.url}: {exc}", exc_info=True)
    return JSONResponse(status_code=500, content={"detail": "An internal server error occurred."})

if __name__ == "__main__":
    port = int(os.getenv("PORT", 8000))
    host = os.getenv("HOST", "0.0.0.0")
   
    is_production = os.getenv("ENVIRONMENT") == "production"
   
    if is_production:
        logger.info(f"🚀 Starting SoulBios Consciousness API Server in PRODUCTION mode on port {port}")
        uvicorn.run("api.soulbios_api:app", host=host, port=port, log_level="info", reload=False)
    else:
        logger.info(f"🚀 Starting SoulBios Consciousness API Server in DEVELOPMENT mode on port {port}")
        uvicorn.run("api.soulbios_api:app", host=host, port=8000, log_level="info", reload=True)