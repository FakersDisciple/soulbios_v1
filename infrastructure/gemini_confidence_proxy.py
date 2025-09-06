"""
GeminiConfidenceProxyEngine for SoulBios
Replaces DeepConf logprob calculations with semantic consistency analysis
"""

import asyncio
import logging
import json
import hashlib
import time
from typing import Dict, List, Any, Optional, Tuple
from datetime import datetime, timedelta
from dataclasses import dataclass
from enum import Enum

import google.generativeai as genai
import redis
from production_config import config
from SoulBios_collections_manager import SoulBiosCollectionsManager
from alice_consciousness_engine import AliceConsciousnessEngine

# Configure logging
logger = logging.getLogger(__name__)

class ConfidenceMethod(Enum):
    SEMANTIC_CONSISTENCY = "semantic_consistency"
    QUALITY_HEURISTICS = "quality_heuristics"
    MULTI_SAMPLING = "multi_sampling"
    COMPOSITE = "composite"

@dataclass
class ConfidenceMetrics:
    overall_confidence: float
    semantic_consistency: float
    response_quality: float
    sampling_consensus: float
    persona_alignment: float
    method_used: ConfidenceMethod
    processing_time: float
    gemini_calls_made: int
    cache_hit: bool = False
    
class GeminiConfidenceProxyEngine:
    """
    Gemini-based confidence proxy that replaces DeepConf logprob calculations
    with semantic consistency analysis for Alice persona selection
    """
    
    def __init__(self, collections_manager: SoulBiosCollectionsManager):
        self.collections_manager = collections_manager
        self.redis_client = config.get_redis_client()
        
        # Gemini configuration
        self.gemini_api_key = config.gemini_api_key
        if self.gemini_api_key:
            genai.configure(api_key=self.gemini_api_key)
            self.model = genai.GenerativeModel('gemini-2.0-flash-exp')
            logger.info("✅ Gemini 2.0 Flash configured for confidence proxy")
        else:
            logger.error("❌ GEMINI_API_KEY not found - confidence proxy disabled")
            self.model = None
        
        # Confidence thresholds aligned with Alice consciousness levels
        self.consciousness_thresholds = {
            "nurturing_presence": (0.0, 0.3),
            "wise_detective": (0.3, 0.6), 
            "transcendent_guide": (0.6, 0.8),
            "unified_consciousness": (0.8, 1.0)
        }
        
        # Cache configuration
        self.cache_ttl = 3600  # 1 hour
        self.cache_prefix = "gemini_confidence"
        
        # Rate limiting for Gemini API
        self.last_api_call = 0
        self.min_call_interval = 0.1  # 100ms between calls
        
    async def calculate_confidence(
        self,
        text: str,
        context: str = "",
        method: ConfidenceMethod = ConfidenceMethod.COMPOSITE,
        use_cache: bool = True
    ) -> ConfidenceMetrics:
        """
        Calculate confidence score using specified method
        """
        start_time = time.time()
        cache_key = self._generate_cache_key(text, context, method)
        gemini_calls = 0
        
        # Check cache first
        if use_cache and self.redis_client:
            cached_result = await self._get_cached_confidence(cache_key)
            if cached_result:
                cached_result.cache_hit = True
                return cached_result
        
        if not self.model:
            # Fallback to basic heuristics if Gemini unavailable
            return await self._fallback_confidence_calculation(text, context, start_time)
        
        try:
            confidence_metrics = None
            
            if method == ConfidenceMethod.SEMANTIC_CONSISTENCY:
                confidence_metrics, calls = await self._semantic_consistency_analysis(text, context)
                gemini_calls += calls
                
            elif method == ConfidenceMethod.QUALITY_HEURISTICS:
                confidence_metrics, calls = await self._quality_heuristics_analysis(text, context)
                gemini_calls += calls
                
            elif method == ConfidenceMethod.MULTI_SAMPLING:
                confidence_metrics, calls = await self._multi_sampling_analysis(text, context)
                gemini_calls += calls
                
            elif method == ConfidenceMethod.COMPOSITE:
                confidence_metrics, calls = await self._composite_analysis(text, context)
                gemini_calls += calls
            
            if confidence_metrics:
                confidence_metrics.processing_time = time.time() - start_time
                confidence_metrics.gemini_calls_made = gemini_calls
                confidence_metrics.method_used = method
                
                # Cache the result
                if use_cache and self.redis_client:
                    await self._cache_confidence(cache_key, confidence_metrics)
                
                return confidence_metrics
            
        except Exception as e:
            logger.error(f"Gemini confidence calculation failed: {e}")
            return await self._fallback_confidence_calculation(text, context, start_time)
    
    async def _semantic_consistency_analysis(self, text: str, context: str) -> Tuple[ConfidenceMetrics, int]:
        """
        Analyze semantic consistency using Gemini 2.0 Flash
        """
        await self._rate_limit()
        
        consistency_prompt = f"""
        Analyze the semantic consistency of this response:
        
        Context: {context}
        Response: {text}
        
        Evaluate on a scale of 0.0-1.0:
        1. Logical coherence within the response
        2. Relevance to the given context  
        3. Internal contradiction detection
        4. Conceptual clarity and precision
        
        Respond with only a JSON object:
        {{
            "semantic_consistency": <float 0.0-1.0>,
            "coherence_score": <float 0.0-1.0>,
            "relevance_score": <float 0.0-1.0>,
            "contradiction_penalty": <float 0.0-1.0>,
            "clarity_score": <float 0.0-1.0>
        }}
        """
        
        try:
            response = await self._call_gemini_async(consistency_prompt)
            result = json.loads(response.text)
            
            # Calculate overall semantic consistency
            semantic_score = result.get("semantic_consistency", 0.5)
            
            metrics = ConfidenceMetrics(
                overall_confidence=semantic_score,
                semantic_consistency=semantic_score,
                response_quality=0.5,  # Not evaluated in this method
                sampling_consensus=1.0,  # Single sample
                persona_alignment=await self._calculate_persona_alignment(text, context),
                method_used=ConfidenceMethod.SEMANTIC_CONSISTENCY,
                processing_time=0.0,  # Set by caller
                gemini_calls_made=0   # Set by caller
            )
            
            return metrics, 1
            
        except Exception as e:
            logger.error(f"Semantic consistency analysis failed: {e}")
            return await self._fallback_confidence_calculation(text, context, 0), 1
    
    async def _quality_heuristics_analysis(self, text: str, context: str) -> Tuple[ConfidenceMetrics, int]:
        """
        Analyze response quality using heuristic evaluation
        """
        await self._rate_limit()
        
        quality_prompt = f"""
        Evaluate the quality of this response using these criteria:
        
        Context: {context}
        Response: {text}
        
        Rate each criterion 0.0-1.0:
        1. Specificity: How specific and detailed is the response?
        2. Depth: How deeply does it address the topic?
        3. Usefulness: How practically helpful is the response?
        4. Appropriateness: How well-suited is the tone and content?
        5. Completeness: How thoroughly does it address the context?
        
        Respond with only a JSON object:
        {{
            "specificity": <float 0.0-1.0>,
            "depth": <float 0.0-1.0>,
            "usefulness": <float 0.0-1.0>,
            "appropriateness": <float 0.0-1.0>,
            "completeness": <float 0.0-1.0>,
            "overall_quality": <float 0.0-1.0>
        }}
        """
        
        try:
            response = await self._call_gemini_async(quality_prompt)
            result = json.loads(response.text)
            
            quality_score = result.get("overall_quality", 0.5)
            
            metrics = ConfidenceMetrics(
                overall_confidence=quality_score,
                semantic_consistency=0.5,  # Not evaluated
                response_quality=quality_score,
                sampling_consensus=1.0,
                persona_alignment=await self._calculate_persona_alignment(text, context),
                method_used=ConfidenceMethod.QUALITY_HEURISTICS,
                processing_time=0.0,
                gemini_calls_made=0
            )
            
            return metrics, 1
            
        except Exception as e:
            logger.error(f"Quality heuristics analysis failed: {e}")
            return await self._fallback_confidence_calculation(text, context, 0), 1
    
    async def _multi_sampling_analysis(self, text: str, context: str) -> Tuple[ConfidenceMetrics, int]:
        """
        Generate multiple responses and measure consensus
        """
        sample_prompt = f"""
        Given this context, generate a response similar to the provided example:
        
        Context: {context}
        Example Response: {text}
        
        Generate a response that addresses the same core needs and themes.
        Keep it concise and maintain similar tone and approach.
        """
        
        try:
            # Generate 3 alternative responses with different temperatures
            temperatures = [0.3, 0.7, 1.0]
            generated_responses = []
            gemini_calls = 0
            
            for temp in temperatures:
                await self._rate_limit()
                response = await self._call_gemini_async(
                    sample_prompt, 
                    temperature=temp,
                    max_output_tokens=200
                )
                generated_responses.append(response.text)
                gemini_calls += 1
            
            # Calculate consensus by comparing semantic similarity
            await self._rate_limit()
            consensus_prompt = f"""
            Compare these responses for semantic similarity and consensus:
            
            Original: {text}
            Alternative 1: {generated_responses[0]}
            Alternative 2: {generated_responses[1]} 
            Alternative 3: {generated_responses[2]}
            
            Rate the consensus level 0.0-1.0 based on:
            - Thematic consistency across responses
            - Similar key points and conclusions
            - Coherent approach to addressing the context
            
            Respond with only a JSON object:
            {{
                "consensus_score": <float 0.0-1.0>,
                "thematic_consistency": <float 0.0-1.0>,
                "approach_similarity": <float 0.0-1.0>
            }}
            """
            
            response = await self._call_gemini_async(consensus_prompt)
            result = json.loads(response.text)
            gemini_calls += 1
            
            consensus_score = result.get("consensus_score", 0.5)
            
            metrics = ConfidenceMetrics(
                overall_confidence=consensus_score,
                semantic_consistency=0.5,  # Not evaluated
                response_quality=0.5,      # Not evaluated
                sampling_consensus=consensus_score,
                persona_alignment=await self._calculate_persona_alignment(text, context),
                method_used=ConfidenceMethod.MULTI_SAMPLING,
                processing_time=0.0,
                gemini_calls_made=0
            )
            
            return metrics, gemini_calls
            
        except Exception as e:
            logger.error(f"Multi-sampling analysis failed: {e}")
            return await self._fallback_confidence_calculation(text, context, 0), 3
    
    async def _composite_analysis(self, text: str, context: str) -> Tuple[ConfidenceMetrics, int]:
        """
        Combine all analysis methods for comprehensive confidence score
        """
        try:
            # Run all analyses in parallel
            tasks = [
                self._semantic_consistency_analysis(text, context),
                self._quality_heuristics_analysis(text, context),
                self._multi_sampling_analysis(text, context)
            ]
            
            results = await asyncio.gather(*tasks, return_exceptions=True)
            total_calls = 0
            
            semantic_metrics, semantic_calls = results[0]
            quality_metrics, quality_calls = results[1] 
            sampling_metrics, sampling_calls = results[2]
            
            total_calls = semantic_calls + quality_calls + sampling_calls
            
            # Weighted composite score
            weights = {
                'semantic': 0.4,
                'quality': 0.3,
                'sampling': 0.3
            }
            
            composite_confidence = (
                weights['semantic'] * semantic_metrics.semantic_consistency +
                weights['quality'] * quality_metrics.response_quality +
                weights['sampling'] * sampling_metrics.sampling_consensus
            )
            
            metrics = ConfidenceMetrics(
                overall_confidence=composite_confidence,
                semantic_consistency=semantic_metrics.semantic_consistency,
                response_quality=quality_metrics.response_quality,
                sampling_consensus=sampling_metrics.sampling_consensus,
                persona_alignment=await self._calculate_persona_alignment(text, context),
                method_used=ConfidenceMethod.COMPOSITE,
                processing_time=0.0,
                gemini_calls_made=0
            )
            
            return metrics, total_calls
            
        except Exception as e:
            logger.error(f"Composite analysis failed: {e}")
            return await self._fallback_confidence_calculation(text, context, 0), 5
    
    async def _calculate_persona_alignment(self, text: str, context: str) -> float:
        """
        Calculate how well the response aligns with Alice persona system
        """
        # This could be enhanced with more sophisticated analysis
        # For now, use basic heuristics based on response characteristics
        
        persona_indicators = {
            'nurturing': ['feel', 'understand', 'support', 'gentle', 'safe'],
            'detective': ['explore', 'pattern', 'curious', 'investigate', 'why'],
            'transcendent': ['wisdom', 'deeper', 'consciousness', 'awareness', 'meta'],
            'unified': ['unity', 'connection', 'transcendent', 'universal', 'oneness']
        }
        
        text_lower = text.lower()
        persona_scores = {}
        
        for persona, indicators in persona_indicators.items():
            score = sum(1 for indicator in indicators if indicator in text_lower)
            persona_scores[persona] = score / len(indicators)
        
        # Return the highest persona alignment score
        return max(persona_scores.values()) if persona_scores else 0.5
    
    async def _call_gemini_async(self, prompt: str, temperature: float = 0.7, max_output_tokens: int = 500):
        """
        Async wrapper for Gemini API calls with error handling
        """
        try:
            response = self.model.generate_content(
                prompt,
                generation_config=genai.GenerationConfig(
                    temperature=temperature,
                    max_output_tokens=max_output_tokens,
                )
            )
            return response
        except Exception as e:
            logger.error(f"Gemini API call failed: {e}")
            raise
    
    async def _rate_limit(self):
        """
        Simple rate limiting for Gemini API calls
        """
        current_time = time.time()
        time_since_last_call = current_time - self.last_api_call
        
        if time_since_last_call < self.min_call_interval:
            await asyncio.sleep(self.min_call_interval - time_since_last_call)
        
        self.last_api_call = time.time()
    
    def _generate_cache_key(self, text: str, context: str, method: ConfidenceMethod) -> str:
        """
        Generate cache key for confidence calculations
        """
        content = f"{text}:{context}:{method.value}"
        return f"{self.cache_prefix}:{hashlib.md5(content.encode()).hexdigest()}"
    
    async def _get_cached_confidence(self, cache_key: str) -> Optional[ConfidenceMetrics]:
        """
        Retrieve cached confidence metrics
        """
        try:
            cached_data = self.redis_client.get(cache_key)
            if cached_data:
                data = json.loads(cached_data)
                return ConfidenceMetrics(**data)
        except Exception as e:
            logger.warning(f"Cache retrieval failed: {e}")
        
        return None
    
    async def _cache_confidence(self, cache_key: str, metrics: ConfidenceMetrics):
        """
        Cache confidence metrics
        """
        try:
            # Convert to dict for JSON serialization
            data = {
                'overall_confidence': metrics.overall_confidence,
                'semantic_consistency': metrics.semantic_consistency,
                'response_quality': metrics.response_quality,
                'sampling_consensus': metrics.sampling_consensus,
                'persona_alignment': metrics.persona_alignment,
                'method_used': metrics.method_used.value,
                'processing_time': metrics.processing_time,
                'gemini_calls_made': metrics.gemini_calls_made,
                'cache_hit': False
            }
            
            self.redis_client.setex(
                cache_key, 
                self.cache_ttl, 
                json.dumps(data)
            )
        except Exception as e:
            logger.warning(f"Cache storage failed: {e}")
    
    async def _fallback_confidence_calculation(self, text: str, context: str, start_time: float) -> ConfidenceMetrics:
        """
        Fallback confidence calculation when Gemini is unavailable
        """
        # Basic heuristics-based confidence calculation
        text_length = len(text.split())
        context_relevance = 0.5  # Default
        
        # Simple heuristics
        if text_length < 5:
            confidence = 0.2
        elif text_length < 20:
            confidence = 0.5
        elif text_length < 100:
            confidence = 0.7
        else:
            confidence = 0.8
        
        # Check for common response patterns
        if any(phrase in text.lower() for phrase in ['i understand', 'i feel', 'let me help']):
            confidence += 0.1
        
        confidence = min(confidence, 1.0)
        
        return ConfidenceMetrics(
            overall_confidence=confidence,
            semantic_consistency=confidence,
            response_quality=confidence,
            sampling_consensus=confidence,
            persona_alignment=0.5,
            method_used=ConfidenceMethod.COMPOSITE,
            processing_time=time.time() - start_time,
            gemini_calls_made=0
        )
    
    def get_persona_from_confidence(self, confidence_score: float) -> str:
        """
        Map confidence score to Alice persona based on consciousness thresholds
        """
        for persona, (min_score, max_score) in self.consciousness_thresholds.items():
            if min_score <= confidence_score < max_score:
                return persona
        
        # Default to unified consciousness for very high scores
        return "unified_consciousness"
    
    async def analyze_conversation_confidence(
        self, 
        user_message: str, 
        alice_response: str, 
        conversation_context: List[Dict] = None
    ) -> Dict[str, Any]:
        """
        Analyze confidence for a full conversation exchange
        """
        # Build context from conversation history
        context = ""
        if conversation_context:
            context_parts = []
            for turn in conversation_context[-3:]:  # Last 3 turns
                context_parts.append(f"User: {turn.get('user', '')}")
                context_parts.append(f"Alice: {turn.get('alice', '')}")
            context = "\n".join(context_parts)
        
        # Calculate confidence for Alice's response
        confidence_metrics = await self.calculate_confidence(
            text=alice_response,
            context=f"{context}\nUser: {user_message}",
            method=ConfidenceMethod.COMPOSITE
        )
        
        # Determine recommended persona
        recommended_persona = self.get_persona_from_confidence(
            confidence_metrics.overall_confidence
        )
        
        return {
            'confidence_score': confidence_metrics.overall_confidence,
            'confidence_metrics': confidence_metrics,
            'recommended_persona': recommended_persona,
            'persona_alignment': confidence_metrics.persona_alignment,
            'processing_time': confidence_metrics.processing_time,
            'gemini_calls_made': confidence_metrics.gemini_calls_made,
            'cache_hit': confidence_metrics.cache_hit
        }


class SoulBiosConfidenceAdapter:
    """
    Adapter class to integrate GeminiConfidenceProxyEngine with existing SoulBios components
    Maintains compatibility with existing Alice consciousness engine and API structure
    """
    
    def __init__(self, collections_manager: SoulBiosCollectionsManager):
        self.collections_manager = collections_manager
        self.confidence_engine = GeminiConfidenceProxyEngine(collections_manager)
        self.alice_engines = {}  # Per-user Alice engines
        
    async def get_alice_engine(self, user_id: str) -> AliceConsciousnessEngine:
        """
        Get or create Alice engine for user
        """
        if user_id not in self.alice_engines:
            # Initialize user collections if needed
            user_collections = await self.collections_manager.create_user_universe(user_id)
            
            # Create Alice engine (this would need the Kurzweil network too)
            # For now, simplified initialization
            self.alice_engines[user_id] = AliceConsciousnessEngine(
                self.collections_manager,
                None,  # kurzweil_network - would need proper initialization
                None   # character_manager
            )
        
        return self.alice_engines[user_id]
    
    async def process_conversation_with_confidence(
        self, 
        user_id: str,
        message: str, 
        context: Dict[str, Any] = None
    ) -> Dict[str, Any]:
        """
        Process conversation with confidence-driven persona selection
        """
        try:
            # Get Alice engine for user
            alice_engine = await self.get_alice_engine(user_id)
            
            # Get conversation context from ChromaDB
            conversation_context = await self._get_conversation_context(user_id)
            
            # Generate Alice response (simplified - would use full Alice engine)
            alice_response = await self._generate_alice_response(
                user_id, message, context
            )
            
            # Calculate confidence and get persona recommendation
            confidence_analysis = await self.confidence_engine.analyze_conversation_confidence(
                user_message=message,
                alice_response=alice_response,
                conversation_context=conversation_context
            )
            
            # Store conversation with confidence metrics
            await self._store_conversation_with_confidence(
                user_id, message, alice_response, confidence_analysis
            )
            
            return {
                'response': alice_response,
                'confidence_score': confidence_analysis['confidence_score'],
                'persona': confidence_analysis['recommended_persona'],
                'confidence_metrics': confidence_analysis['confidence_metrics'],
                'processing_time': confidence_analysis['processing_time']
            }
            
        except Exception as e:
            logger.error(f"Conversation processing failed for user {user_id}: {e}")
            return {
                'response': "I'm having trouble connecting right now. Please try again.",
                'confidence_score': 0.1,
                'persona': 'nurturing_presence',
                'error': str(e)
            }
    
    async def _get_conversation_context(self, user_id: str) -> List[Dict]:
        """
        Retrieve recent conversation context from ChromaDB
        """
        try:
            # Get user collections
            if user_id not in self.collections_manager.user_collections:
                await self.collections_manager.create_user_universe(user_id)
            
            collections = self.collections_manager.user_collections[user_id]
            conversations_collection = collections.get('conversations')
            
            if conversations_collection:
                # Query recent conversations
                results = conversations_collection.query(
                    query_texts=["recent conversation"],
                    n_results=5
                )
                
                # Format for confidence analysis
                context = []
                if results and results.get('metadatas'):
                    for metadata in results['metadatas'][0]:
                        context.append({
                            'user': metadata.get('user_message', ''),
                            'alice': metadata.get('alice_response', ''),
                            'timestamp': metadata.get('timestamp', '')
                        })
                
                return context
                
        except Exception as e:
            logger.error(f"Failed to get conversation context for user {user_id}: {e}")
            
        return []
    
    async def _generate_alice_response(
        self, 
        user_id: str, 
        message: str, 
        context: Dict[str, Any] = None
    ) -> str:
        """
        Generate Alice response (simplified implementation)
        In full system, this would use the complete Alice consciousness engine
        """
        # This is a simplified version - the full implementation would:
        # 1. Use the Alice consciousness engine
        # 2. Apply pattern recognition
        # 3. Select appropriate persona
        # 4. Generate contextual response
        
        # For now, return a basic response
        return f"I understand you're sharing: {message[:100]}... Let me reflect on this with you."
    
    async def _store_conversation_with_confidence(
        self,
        user_id: str,
        user_message: str,
        alice_response: str,
        confidence_analysis: Dict[str, Any]
    ):
        """
        Store conversation with confidence metrics in ChromaDB
        """
        try:
            # Get user collections
            if user_id not in self.collections_manager.user_collections:
                await self.collections_manager.create_user_universe(user_id)
            
            collections = self.collections_manager.user_collections[user_id]
            conversations_collection = collections.get('conversations')
            
            if conversations_collection:
                # Store conversation with confidence data
                doc_id = f"conv_{user_id}_{int(time.time())}"
                
                conversations_collection.add(
                    documents=[f"{user_message} | {alice_response}"],
                    metadatas=[{
                        'user_id': user_id,
                        'user_message': user_message,
                        'alice_response': alice_response,
                        'confidence_score': confidence_analysis['confidence_score'],
                        'recommended_persona': confidence_analysis['recommended_persona'],
                        'processing_time': confidence_analysis['processing_time'],
                        'timestamp': datetime.now().isoformat(),
                        'confidence_method': 'gemini_proxy'
                    }],
                    ids=[doc_id]
                )
                
                logger.info(f"Stored conversation with confidence for user {user_id}")
                
        except Exception as e:
            logger.error(f"Failed to store conversation for user {user_id}: {e}")


# Integration with existing middleware and FastAPI
class GeminiConfidenceMiddleware:
    """
    Middleware to integrate confidence calculations with existing rate limiting
    """
    
    def __init__(self, collections_manager: SoulBiosCollectionsManager):
        self.confidence_adapter = SoulBiosConfidenceAdapter(collections_manager)
    
    async def process_chat_request(
        self,
        user_id: str,
        message: str,
        metadata: Dict[str, Any] = None
    ) -> Dict[str, Any]:
        """
        Process chat request with confidence analysis
        Compatible with existing soulbios_api.py structure
        """
        return await self.confidence_adapter.process_conversation_with_confidence(
            user_id=user_id,
            message=message,
            context=metadata
        )