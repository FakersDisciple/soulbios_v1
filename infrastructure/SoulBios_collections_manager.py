import logging
import os
import hashlib
import json
import time
from datetime import datetime
from typing import Dict, List, Any, Optional
from dotenv import load_dotenv
import chromadb

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# Load environment variables
load_dotenv()

class SoulBiosCollectionsManager:
    """Clean ChromaDB collections manager - no bypass logic, proper API usage"""
    
    def __init__(self):
        self.client = None
        self.collections = {}
        self.user_collections = {}
        
        try:
            # Use ChromaDB 1.0+ API - simpler initialization
            self.client = chromadb.PersistentClient(path="/app/data")
            logger.info("✅ ChromaDB 1.0+ client initialized at /app/data")
            
        except Exception as e:
            logger.error(f"❌ ChromaDB initialization failed: {e}")
            raise
            
        logger.info("SoulBiosCollectionsManager initialized successfully")

    def _get_collection_name(self, user_id: str, collection_type: str) -> str:
        """Generate consistent collection names"""
        user_hash = hashlib.md5(user_id.encode()).hexdigest()[:8]
        return f"user_{user_hash}_{collection_type}"
    
    def get_user_collection(self, user_id: str, collection_type: str):
        """Get a specific collection for a user"""
        if user_id not in self.user_collections:
            raise ValueError(f"User {user_id} not found. Call create_user_universe first.")
        
        collection = self.user_collections[user_id].get(collection_type)
        if not collection:
            raise ValueError(f"Collection {collection_type} not found for user {user_id}")
        
        return collection

    async def create_user_universe(self, user_id: str) -> Dict[str, Any]:
        """Create collections for user - modern ChromaDB API"""
        start_time = time.time()
        
        try:
            collection_types = ["conversations", "life_patterns", "fortress_elements", "wisdom_insights", "narrative_design"]
            user_collections = {}
            
            for collection_type in collection_types:
                collection_name = self._get_collection_name(user_id, collection_type)
                
                try:
                    # Get existing collection or create new one
                    collection = self.client.get_or_create_collection(
                        name=collection_name,
                        metadata={"user_id": user_id, "collection_type": collection_type}
                    )
                    user_collections[collection_type] = collection
                    
                except Exception as e:
                    logger.error(f"❌ Failed to create collection {collection_name}: {e}")
                    continue
            
            # Store collections for this user
            self.user_collections[user_id] = user_collections
            
            creation_time = (time.time() - start_time) * 1000
            logger.info(f"✅ Created {len(user_collections)} collections for {user_id} in {creation_time:.1f}ms")
            
            return {name: name for name in user_collections.keys()}
            
        except Exception as e:
            logger.error(f"❌ Error creating user universe: {e}")
            return {}

    async def add_conversation(self, user_id: str, message: str, role: str, metadata: Dict[str, Any] = None):
        """Add conversation using proper ChromaDB API"""
        start_time = time.time()
        
        try:
            # Ensure user collections exist
            if user_id not in self.user_collections:
                await self.create_user_universe(user_id)
            
            conversations_collection = self.user_collections[user_id].get("conversations")
            if not conversations_collection:
                logger.error(f"❌ No conversations collection for {user_id}")
                return False
            
            # Create document with proper metadata
            doc_id = f"msg_{user_id}_{int(time.time() * 1000)}"
            doc_metadata = {
                "user_id": user_id,
                "role": role,
                "timestamp": datetime.now().isoformat()
            }
            
            # Add custom metadata
            if metadata:
                for key, value in metadata.items():
                    doc_metadata[key] = str(value)  # ChromaDB requires string metadata
            
            # Add to collection
            conversations_collection.add(
                documents=[message],
                metadatas=[doc_metadata],
                ids=[doc_id]
            )
            
            add_time = (time.time() - start_time) * 1000
            logger.info(f"✅ Added conversation for {user_id} in {add_time:.1f}ms")
            return True
            
        except Exception as e:
            logger.error(f"❌ Error adding conversation: {e}")
            return False

    async def get_conversation_history(self, user_id: str, limit: int = 5) -> List[Dict[str, Any]]:
        """Get conversation history using proper ChromaDB API"""
        start_time = time.time()
        
        try:
            # Ensure user collections exist
            if user_id not in self.user_collections:
                await self.create_user_universe(user_id)
            
            conversations_collection = self.user_collections[user_id].get("conversations")
            if not conversations_collection:
                return []
            
            # Query recent conversations
            results = conversations_collection.get(
                limit=limit,
                include=["documents", "metadatas"]
            )
            
            history = []
            if results and results.get("documents"):
                for doc, metadata in zip(results["documents"], results["metadatas"]):
                    history.append({
                        "request": doc,
                        "metadata": metadata,
                        "timestamp": metadata.get("timestamp", "unknown")
                    })
            
            query_time = (time.time() - start_time) * 1000
            logger.info(f"✅ Retrieved {len(history)} conversations for {user_id} in {query_time:.1f}ms")
            return history
            
        except Exception as e:
            logger.error(f"❌ Error retrieving conversation history: {e}")
            return []

    def store_in_collection(self, collection_type: str, user_id: str, text: str, metadata: Dict[str, Any]) -> bool:
        """Store data in specific collection type"""
        try:
            # Ensure user collections exist
            if user_id not in self.user_collections:
                # Create synchronously for now - can be made async later
                import asyncio
                loop = asyncio.new_event_loop()
                asyncio.set_event_loop(loop)
                loop.run_until_complete(self.create_user_universe(user_id))
                loop.close()
            
            collection = self.user_collections[user_id].get(collection_type)
            if not collection:
                logger.error(f"❌ No {collection_type} collection for {user_id}")
                return False
            
            # Create document
            doc_id = f"{collection_type}_{user_id}_{int(time.time() * 1000)}"
            doc_metadata = {key: str(value) for key, value in metadata.items()}  # Ensure string values
            
            collection.add(
                documents=[text],
                metadatas=[doc_metadata],
                ids=[doc_id]
            )
            
            logger.info(f"✅ Stored in {collection_type} for {user_id}")
            return True
            
        except Exception as e:
            logger.error(f"❌ Error storing in {collection_type}: {e}")
            return False

    def search_collections(self, user_id: str, query: str, collection_types: List[str], n_results: int = 5) -> List[Dict[str, Any]]:
        """Search across multiple collections"""
        try:
            if user_id not in self.user_collections:
                return []
            
            all_results = []
            for collection_type in collection_types:
                collection = self.user_collections[user_id].get(collection_type)
                if not collection:
                    continue
                    
                try:
                    results = collection.query(
                        query_texts=[query],
                        n_results=n_results,
                        include=["documents", "metadatas"]
                    )
                    
                    if results and results.get("documents") and results["documents"][0]:
                        for doc, metadata in zip(results["documents"][0], results["metadatas"][0]):
                            all_results.append({
                                "text": doc,
                                "metadata": metadata,
                                "collection_type": collection_type
                            })
                            
                except Exception as e:
                    logger.error(f"❌ Error querying {collection_type}: {e}")
                    continue
            
            return all_results[:n_results]
            
        except Exception as e:
            logger.error(f"❌ Error searching collections: {e}")
            return []

    def get_health_status(self) -> Dict[str, Any]:
        """Get health status of ChromaDB connection"""
        try:
            # Test connection by listing collections
            collections_count = len(self.client.list_collections())
            return {
                "status": "healthy",
                "collections_count": collections_count,
                "users_count": len(self.user_collections),
                "chromadb_version": "1.0.20"
            }
        except Exception as e:
            return {
                "status": "unhealthy",
                "error": str(e)
            }

async def test_manager():
    """Test the clean collections manager"""
    manager = SoulBiosCollectionsManager()
    
    # Test user creation
    await manager.create_user_universe("test_user")
    
    # Test conversation storage
    await manager.add_conversation("test_user", "Hello world", "user", {"test": True})
    
    # Test history retrieval
    history = await manager.get_conversation_history("test_user")
    print(f"Retrieved {len(history)} conversations")
    
    # Test health
    health = manager.get_health_status()
    print(f"Health: {health}")

if __name__ == "__main__":
    import asyncio
    asyncio.run(test_manager())