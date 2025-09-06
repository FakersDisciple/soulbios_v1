#!/usr/bin/env python3
"""
Strategy Cache for SoulBios Game Theory Performance Optimization
Implements intelligent caching based on game state similarity for <1s response times
"""
import json
import time
import hashlib
import logging
from typing import Dict, Any, Optional, Tuple
from datetime import datetime, timedelta
import numpy as np
from dataclasses import dataclass

logger = logging.getLogger(__name__)

@dataclass
class CachedStrategy:
    strategy: Dict[str, Any]
    timestamp: datetime
    game_state_hash: str
    similarity_score: float
    hit_count: int = 0
    
class StrategyCache:
    """
    High-performance strategy cache with game state similarity matching
    Target: 40-60% cache hit rate, <50ms retrieval time
    """
    
    def __init__(self, collections_manager=None, redis_client=None):
        self.collections_manager = collections_manager
        self.redis_client = redis_client
        self.cache = {}  # In-memory cache as primary
        self.max_cache_size = 1000
        self.similarity_threshold = 0.85
        self.max_age_minutes = 30
        self.stats = {
            "hits": 0,
            "misses": 0,
            "total_requests": 0,
            "cache_size": 0
        }
        logger.info("StrategyCache initialized with similarity threshold: {:.2f}".format(self.similarity_threshold))
    
    def _calculate_game_state_hash(self, game_state: Dict[str, Any]) -> str:
        """Generate consistent hash for game state"""
        # Normalize game state for consistent hashing
        normalized_state = {
            "person": game_state.get("current_person", 0),
            "accepted": game_state.get("accepted_count", 0),
            "constraints": sorted([
                (c.get("attribute"), c.get("minCount"), c.get("admitted", 0))
                for c in game_state.get("constraints", [])
            ]),
            "frequencies": tuple(sorted(game_state.get("observedFrequencies", {}).items())),
        }
        state_str = json.dumps(normalized_state, sort_keys=True)
        return hashlib.md5(state_str.encode()).hexdigest()
    
    def _calculate_similarity(self, state1: Dict[str, Any], state2: Dict[str, Any]) -> float:
        """Calculate similarity score between two game states (0.0 to 1.0)"""
        try:
            # Key similarity factors for Berghain game
            person_diff = abs(state1.get("current_person", 0) - state2.get("current_person", 0))
            person_similarity = max(0, 1 - (person_diff / 100))  # Within 100 people = high similarity
            
            accept_diff = abs(state1.get("accepted_count", 0) - state2.get("accepted_count", 0))
            accept_similarity = max(0, 1 - (accept_diff / 50))  # Within 50 accepts = high similarity
            
            # Constraint similarity
            constraints1 = {c.get("attribute"): c.get("minCount", 0) for c in state1.get("constraints", [])}
            constraints2 = {c.get("attribute"): c.get("minCount", 0) for c in state2.get("constraints", [])}
            
            constraint_similarity = 1.0
            for attr in set(constraints1.keys()) | set(constraints2.keys()):
                diff = abs(constraints1.get(attr, 0) - constraints2.get(attr, 0))
                constraint_similarity *= max(0, 1 - (diff / 200))  # Within 200 count = similar
            
            # Weighted average
            overall_similarity = (
                person_similarity * 0.4 + 
                accept_similarity * 0.3 + 
                constraint_similarity * 0.3
            )
            
            return overall_similarity
            
        except Exception as e:
            logger.warning(f"Similarity calculation failed: {e}")
            return 0.0
    
    def get_cached_strategy(self, game_state: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """Retrieve cached strategy for similar game states"""
        start_time = time.time()
        self.stats["total_requests"] += 1
        
        try:
            current_hash = self._calculate_game_state_hash(game_state)
            
            # Check exact match first (fastest)
            if current_hash in self.cache:
                cached = self.cache[current_hash]
                if self._is_cache_valid(cached):
                    cached.hit_count += 1
                    self.stats["hits"] += 1
                    retrieval_time = (time.time() - start_time) * 1000
                    logger.info(f"✅ Cache HIT (exact): {retrieval_time:.1f}ms")
                    return self._add_cache_metadata(cached.strategy, "exact_match", 1.0)
            
            # Check similarity matches (slower but still fast)
            best_match = None
            best_similarity = 0.0
            
            for cache_hash, cached_strategy in self.cache.items():
                if not self._is_cache_valid(cached_strategy):
                    continue
                    
                # Quick parse of cached game state for similarity
                try:
                    cached_game_state = json.loads(cached_strategy.strategy.get("_cache_metadata", {}).get("original_game_state", "{}"))
                    similarity = self._calculate_similarity(game_state, cached_game_state)
                    
                    if similarity > best_similarity and similarity >= self.similarity_threshold:
                        best_similarity = similarity
                        best_match = cached_strategy
                        
                except Exception as e:
                    logger.debug(f"Similarity check failed for {cache_hash}: {e}")
                    continue
            
            if best_match:
                best_match.hit_count += 1
                self.stats["hits"] += 1
                retrieval_time = (time.time() - start_time) * 1000
                logger.info(f"✅ Cache HIT (similarity {best_similarity:.2f}): {retrieval_time:.1f}ms")
                return self._add_cache_metadata(best_match.strategy, "similarity_match", best_similarity)
            
            # No suitable cached strategy found
            self.stats["misses"] += 1
            retrieval_time = (time.time() - start_time) * 1000
            logger.info(f"❌ Cache MISS: {retrieval_time:.1f}ms")
            return None
            
        except Exception as e:
            logger.error(f"Cache retrieval error: {e}")
            self.stats["misses"] += 1
            return None
    
    def cache_strategy(self, game_state: Dict[str, Any], strategy: Dict[str, Any]) -> None:
        """Cache a strategy response for future retrieval"""
        try:
            game_state_hash = self._calculate_game_state_hash(game_state)
            
            # Add metadata to strategy for cache management
            enhanced_strategy = strategy.copy()
            enhanced_strategy["_cache_metadata"] = {
                "cached_at": datetime.now().isoformat(),
                "game_state_hash": game_state_hash,
                "original_game_state": json.dumps(game_state),
                "cache_version": "1.0"
            }
            
            cached_strategy = CachedStrategy(
                strategy=enhanced_strategy,
                timestamp=datetime.now(),
                game_state_hash=game_state_hash,
                similarity_score=1.0  # Exact match for original
            )
            
            # Implement LRU eviction if cache is full
            if len(self.cache) >= self.max_cache_size:
                self._evict_oldest_entries()
            
            self.cache[game_state_hash] = cached_strategy
            self.stats["cache_size"] = len(self.cache)
            
            logger.info(f"🔄 Strategy cached: {game_state_hash[:8]}... (cache size: {len(self.cache)})")
            
        except Exception as e:
            logger.error(f"Cache storage error: {e}")
    
    def _is_cache_valid(self, cached_strategy: CachedStrategy) -> bool:
        """Check if cached strategy is still valid (not expired)"""
        age = datetime.now() - cached_strategy.timestamp
        return age < timedelta(minutes=self.max_age_minutes)
    
    def _evict_oldest_entries(self):
        """Remove oldest 20% of cache entries (LRU eviction)"""
        sorted_entries = sorted(
            self.cache.items(), 
            key=lambda x: (x[1].timestamp, x[1].hit_count)
        )
        
        entries_to_remove = int(len(sorted_entries) * 0.2)
        for i in range(entries_to_remove):
            cache_hash = sorted_entries[i][0]
            del self.cache[cache_hash]
        
        logger.info(f"🧹 Cache evicted {entries_to_remove} old entries")
    
    def _add_cache_metadata(self, strategy: Dict[str, Any], match_type: str, similarity: float) -> Dict[str, Any]:
        """Add cache hit metadata to strategy response"""
        enhanced_strategy = strategy.copy()
        enhanced_strategy["_cache_metadata"]["match_type"] = match_type
        enhanced_strategy["_cache_metadata"]["similarity_score"] = similarity
        enhanced_strategy["_cache_metadata"]["served_from_cache"] = True
        return enhanced_strategy
    
    def get_cache_stats(self) -> Dict[str, Any]:
        """Return cache performance statistics"""
        hit_rate = (self.stats["hits"] / max(1, self.stats["total_requests"])) * 100
        return {
            **self.stats,
            "hit_rate_percent": round(hit_rate, 2),
            "similarity_threshold": self.similarity_threshold,
            "max_age_minutes": self.max_age_minutes
        }
    
    def clear_cache(self):
        """Clear all cached strategies"""
        self.cache.clear()
        self.stats = {"hits": 0, "misses": 0, "total_requests": 0, "cache_size": 0}
        logger.info("🧹 Cache cleared")

# Global cache instance for the application
strategy_cache = StrategyCache()