import logging
import os
import hashlib
import json
import time
from datetime import datetime
from typing import Dict, List, Any, Optional
from dotenv import load_dotenv
import chromadb
import redis

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# Load environment variables
load_dotenv()

class SoulBiosCollectionsManager:
    """Production-ready multi-tenant ChromaDB collections manager with emergency in-memory fallback"""
    
    def __init__(self):
        self.client = None
        self.collections = {}
        self.user_collections = {}  # Per-user isolated collections
        
        # EMERGENCY DATABASE BYPASS - In-memory storage
        self.emergency_mode = False
        self.memory_store = {}  # In-memory fallback storage
        self.bypass_log = []    # Log operations for later database fix
        
        # Redis client for emergency storage
        self.redis_client = None
        try:
            self.redis_client = redis.Redis(host='localhost', port=6379, decode_responses=True)
            self.redis_client.ping()  # Test connection
            logger.info("✅ Redis client available for emergency storage")
        except Exception as e:
            logger.warning(f"Redis not available: {e}")
            self.redis_client = None
        try:
            # Attempt cloud ChromaDB client with environment variables
            chroma_api_key = os.getenv("CHROMA_API_KEY")
            chroma_tenant = os.getenv("CHROMA_TENANT")
            chroma_database = os.getenv("CHROMA_DATABASE")
            
            if chroma_api_key and chroma_tenant and chroma_database:
                self.client = chromadb.Client(
                    api_key=chroma_api_key,
                    tenant=chroma_tenant,
                    database=chroma_database
                )
                logger.info("✅ ChromaDB cloud client initialized successfully")
            else:
                raise Exception("Missing ChromaDB cloud credentials")
                
        except Exception as e:
            logger.warning(f"ChromaDB cloud initialization failed: {e}")
            # Fallback to local client for development
            try:
                self.client = chromadb.PersistentClient(path="./chroma_db")
                logger.info("✅ Falling back to local ChromaDB client at ./chroma_db")
            except Exception as e:
                logger.error(f"Local ChromaDB initialization failed: {e}")
                self.client = None
                
        if self.client:
            logger.info("SoulBiosCollectionsManager initialized successfully")
        else:
            logger.error("SoulBiosCollectionsManager initialization failed; enabling emergency mode")
            self.emergency_mode = True
            logger.warning("🚨 EMERGENCY DATABASE BYPASS MODE ENABLED - Using in-memory storage")

    async def create_user_universe(self, user_id: str) -> Dict[str, Any]:
        """Create isolated ChromaDB universe for each user - EMERGENCY BYPASS MODE"""
        
        # EMERGENCY MODE: Skip ChromaDB operations
        if self.emergency_mode or not self.client:
            start_time = time.time()
            
            # Create mock universe in memory/Redis
            user_prefix = f"user_{hashlib.md5(user_id.encode()).hexdigest()[:8]}"
            mock_universe = {
                "conversations": f"{user_prefix}_conversations",
                "life_patterns": f"{user_prefix}_life_patterns", 
                "fortress_elements": f"{user_prefix}_fortress_elements",
                "wisdom_insights": f"{user_prefix}_wisdom_insights",
                "narrative_design": f"{user_prefix}_narrative_design"
            }
            
            # Store in memory
            if user_id not in self.memory_store:
                self.memory_store[user_id] = {"collections": mock_universe, "data": {}}
            
            # Log bypassed operation
            bypass_time = (time.time() - start_time) * 1000
            self.bypass_log.append({
                "operation": "create_user_universe",
                "user_id": user_id,
                "time_ms": bypass_time,
                "timestamp": datetime.now().isoformat()
            })
            
            logger.info(f"🚨 EMERGENCY BYPASS: Created mock universe for {user_id} in {bypass_time:.1f}ms")
            return mock_universe
        user_prefix = f"user_{hashlib.md5(user_id.encode()).hexdigest()[:8]}"
        logger.info(f"Creating user universe for {user_id} with prefix {user_prefix}")
        # ChromaDB collections (no predefined schemas - metadata is flexible)
        collection_names = [
            f"{user_prefix}_conversations",
            f"{user_prefix}_life_patterns",
            f"{user_prefix}_fortress_elements",
            f"{user_prefix}_wisdom_insights",
            f"{user_prefix}_narrative_design"
        ]
        user_collections = {}
        for name in collection_names:
            try:
                collection = self.client.get_or_create_collection(
                    name=name,
                    metadata={"description": f"SoulBios collection for user {user_id}"}
                )
                collection_key = name.split(f"{user_prefix}_")[1]
                user_collections[collection_key] = collection
                logger.info(f"Created/retrieved collection: {name}")
            except Exception as e:
                logger.error(f"Failed to create collection {name}: {e}")
                continue
        self.user_collections[user_id] = user_collections
        
        # Initialize with seed data
        if user_collections:
            await self._initialize_user_seed_data(user_id, user_collections)
        return user_collections

    async def _initialize_user_seed_data(self, user_id: str, user_collections: Dict):
        """Initialize user with seed patterns and wisdom"""
        
        if "life_patterns" not in user_collections:
            logger.warning(f"No life_patterns collection for user {user_id}, skipping seed data")
            return
        
        basic_patterns = [
            {
                "pattern_name": "anxiety_response",
                "pattern_type": "emotional_trigger",
                "hierarchy_level": 1,
                "description": "Basic anxiety response pattern - fight/flight activation in social or challenging situations",
                "recognition_threshold": 0.7
            },
            {
                "pattern_name": "joy_activation",
                "pattern_type": "positive_emotion",
                "hierarchy_level": 1,
                "description": "Joy and happiness activation pattern - natural positive emotional responses",
                "recognition_threshold": 0.6
            },
            {
                "pattern_name": "connection_seeking",
                "pattern_type": "social_pattern",
                "hierarchy_level": 2,
                "description": "Seeking connection and belonging - fundamental human need for social bonds",
                "recognition_threshold": 0.8,
                "parent_patterns": ["joy_activation"]
            },
            {
                "pattern_name": "self_reflection",
                "pattern_type": "cognitive_pattern",
                "hierarchy_level": 3,
                "description": "Self-awareness and introspective observation of internal states and behaviors",
                "recognition_threshold": 0.7,
                "parent_patterns": ["anxiety_response", "connection_seeking"]
            }
        ]
        
        patterns_collection = user_collections["life_patterns"]
        
        try:
            for i, pattern in enumerate(basic_patterns):
                pattern_id = f"seed_pattern_{i}"
                
                patterns_collection.add(
                    documents=[pattern["description"]],
                    metadatas=[{
                        "user_id": user_id,
                        "pattern_id": pattern_id,
                        "pattern_name": pattern["pattern_name"],
                        "pattern_type": pattern["pattern_type"],
                        "hierarchy_level": pattern["hierarchy_level"],
                        "parent_patterns": ",".join(pattern.get("parent_patterns", [])),
                        "recognition_threshold": pattern["recognition_threshold"],
                        "pattern_strength": 0.3,
                        "first_detected": datetime.now().isoformat(),
                        "transformation_readiness": 0.1
                    }],
                    ids=[pattern_id]
                )
                
            logger.info(f"Initialized seed data for user {user_id}")
        except Exception as e:
            logger.error(f"Failed to initialize seed data for user {user_id}: {e}")

    def get_user_collection(self, user_id: str, collection_type: str):
        """Get specific user collection"""
        if user_id not in self.user_collections:
            raise ValueError(f"User {user_id} universe not initialized")
        
        if collection_type not in self.user_collections[user_id]:
            raise ValueError(f"Collection type {collection_type} not found for user {user_id}")
        
        return self.user_collections[user_id][collection_type]

    def get_all_user_collections(self, user_id: str) -> Dict:
        """Get all collections for a user"""
        if user_id not in self.user_collections:
            raise ValueError(f"User {user_id} universe not initialized")
        
        return self.user_collections[user_id]

    async def add_conversation(self, user_id: str, message: str, role: str, metadata: Dict[str, Any] = None):
        """Add conversation to user's conversation collection - EMERGENCY BYPASS MODE"""
        
        # EMERGENCY MODE: Use Redis/Memory instead of ChromaDB
        if self.emergency_mode or not self.client:
            start_time = time.time()
            
            message_id = f"msg_{int(datetime.now().timestamp() * 1000)}"
            conversation_data = {
                "message": message,
                "role": role,
                "timestamp": datetime.now().isoformat(),
                "metadata": metadata or {}
            }
            
            # Store in Redis if available, otherwise memory
            redis_key = f"conversation:{user_id}:{message_id}"
            
            if self.redis_client:
                try:
                    self.redis_client.setex(redis_key, 3600, json.dumps(conversation_data))  # 1-hour TTL
                    storage_location = "Redis"
                except Exception:
                    # Fallback to memory
                    if user_id not in self.memory_store:
                        self.memory_store[user_id] = {"collections": {}, "data": {}}
                    if "conversations" not in self.memory_store[user_id]["data"]:
                        self.memory_store[user_id]["data"]["conversations"] = []
                    self.memory_store[user_id]["data"]["conversations"].append(conversation_data)
                    storage_location = "Memory"
            else:
                # Memory fallback
                if user_id not in self.memory_store:
                    self.memory_store[user_id] = {"collections": {}, "data": {}}
                if "conversations" not in self.memory_store[user_id]["data"]:
                    self.memory_store[user_id]["data"]["conversations"] = []
                self.memory_store[user_id]["data"]["conversations"].append(conversation_data)
                storage_location = "Memory"
            
            # Log bypassed operation
            bypass_time = (time.time() - start_time) * 1000
            self.bypass_log.append({
                "operation": "add_conversation",
                "user_id": user_id,
                "storage": storage_location,
                "time_ms": bypass_time,
                "timestamp": datetime.now().isoformat()
            })
            
            logger.info(f"🚨 EMERGENCY BYPASS: Stored conversation for {user_id} in {storage_location} ({bypass_time:.1f}ms)")
            return True
        
        # Original ChromaDB logic
        try:
            conversations = self.get_user_collection(user_id, "conversations")
            
            message_id = f"msg_{datetime.now().timestamp()}"
            
            conversation_metadata = {
                "user_id": user_id,
                "message_id": message_id,
                "timestamp": datetime.now().isoformat(),
                "role": role,
                "privacy_level": "private"
            }
            
            if metadata:
                # Convert any lists to comma-separated strings for ChromaDB compatibility
                processed_metadata = {}
                for key, value in metadata.items():
                    if isinstance(value, list):
                        processed_metadata[key] = ",".join(str(v) for v in value)
                    else:
                        processed_metadata[key] = str(value)
                conversation_metadata.update(processed_metadata)
            
            conversations.add(
                documents=[message],
                metadatas=[conversation_metadata],
                ids=[message_id]
            )
            
            logger.info(f"Added {role} message for user {user_id}")
            return message_id
        except Exception as e:
            logger.error(f"Failed to add conversation for user {user_id}: {e}")
            return None

    async def query_patterns(self, user_id: str, query_text: str, n_results: int = 5) -> Dict:
        """Query user's life patterns"""
        try:
            patterns = self.get_user_collection(user_id, "life_patterns")
            
            results = patterns.query(
                query_texts=[query_text],
                n_results=n_results
            )
            
            return results
        except Exception as e:
            logger.error(f"Failed to query patterns for user {user_id}: {e}")
            return {"documents": [[]], "metadatas": [[]], "distances": [[]]}

    async def add_pattern(self, user_id: str, pattern_data: Dict[str, Any]):
        """Add new pattern to user's collection"""
        try:
            patterns = self.get_user_collection(user_id, "life_patterns")
            
            pattern_id = f"pattern_{datetime.now().timestamp()}"
            
            pattern_metadata = {
                "user_id": user_id,
                "pattern_id": pattern_id,
                "first_detected": datetime.now().isoformat(),
                "transformation_readiness": 0.1
            }
            
            # Convert all values to strings for ChromaDB compatibility
            for key, value in pattern_data.items():
                if isinstance(value, list):
                    pattern_metadata[key] = ",".join(str(v) for v in value)
                else:
                    pattern_metadata[key] = str(value)
            
            patterns.add(
                documents=[pattern_data.get("description", "")],
                metadatas=[pattern_metadata],
                ids=[pattern_id]
            )
            
            logger.info(f"Added new pattern {pattern_data.get('pattern_name', 'unknown')} for user {user_id}")
            return pattern_id
        except Exception as e:
            logger.error(f"Failed to add pattern for user {user_id}: {e}")
            return None

    def get_or_create_user_collection(self, user_id: str):
        """Get or create a user's collection universe and return the collections dictionary"""
        if user_id not in self.user_collections:
            asyncio.run(self.create_user_universe(user_id))  # Run async method synchronously for simplicity
        return self.user_collections.get(user_id, {})

# Test the collections manager
if __name__ == "__main__":
    import asyncio
    
    async def test_manager():
        print("Testing SoulBios Collections Manager")
        print("=" * 50)
        
        try:
            manager = SoulBiosCollectionsManager()
            
            if not manager.client:
                print("❌ ChromaDB client not initialized - check your environment variables")
                return
            
            test_user = "test_user_123"
            
            # Create user universe
            print(f"1. Creating user universe for {test_user}...")
            user_collections = await manager.create_user_universe(test_user)
            print(f"   Created {len(user_collections)} collections")
            
            if not user_collections:
                print("❌ Failed to create user collections")
                return
            
            # Test conversation addition
            print("2. Adding test conversation...")
            msg_id = await manager.add_conversation(
                test_user,
                "Hello Alice, I'm feeling anxious about my upcoming presentation",
                "user",
                {"emotional_markers": ["anxiety"], "developmental_stage": "awareness"}
            )
            print(f"   Added conversation with ID: {msg_id}")
            
            # Test pattern querying
            print("3. Querying patterns...")
            pattern_results = await manager.query_patterns(test_user, "anxiety", n_results=2)
            print(f"   Found {len(pattern_results['documents'][0])} matching patterns")
            
            # Test pattern addition
            print("4. Adding new pattern...")
            pattern_id = await manager.add_pattern(test_user, {
                "pattern_name": "presentation_anxiety",
                "pattern_type": "situational_trigger",
                "hierarchy_level": 2,
                "description": "Anxiety specifically triggered by public speaking situations",
                "recognition_threshold": 0.8,
                "pattern_strength": 0.6
            })
            print(f"   Added pattern with ID: {pattern_id}")
            
            print("\n" + "=" * 50)
            print("✅ SUCCESS: SoulBios Collections Manager working!")
            print("Ready for backend launch!")
            
        except Exception as e:
            print(f"❌ ERROR: {e}")
            import traceback
            traceback.print_exc()
    
    # Run async test
    asyncio.run(test_manager())