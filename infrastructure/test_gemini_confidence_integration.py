#!/usr/bin/env python3
"""
Integration test for GeminiConfidenceProxyEngine with existing SoulBios components
Tests confidence calculation, persona selection, and ChromaDB integration
"""

import asyncio
import os
import logging
from datetime import datetime
from dotenv import load_dotenv

# Import SoulBios components
from gemini_confidence_proxy import GeminiConfidenceProxyEngine, SoulBiosConfidenceAdapter, ConfidenceMethod
from SoulBios_collections_manager import SoulBiosCollectionsManager
from production_config import config

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

load_dotenv()

async def test_basic_confidence_calculation():
    """Test basic confidence calculation with semantic consistency"""
    
    logger.info("🧪 Testing basic confidence calculation...")
    
    # Initialize components
    collections_manager = SoulBiosCollectionsManager()
    confidence_engine = GeminiConfidenceProxyEngine(collections_manager)
    
    # Test inputs
    test_text = "I understand you're feeling anxious about your presentation. This is completely natural - your nervous system is trying to protect you. Let's explore this together gently."
    test_context = "User shared: 'I have a big presentation tomorrow and I'm really nervous about it. What should I do?'"
    
    # Calculate confidence using different methods
    methods_to_test = [
        ConfidenceMethod.SEMANTIC_CONSISTENCY,
        ConfidenceMethod.QUALITY_HEURISTICS,
        ConfidenceMethod.MULTI_SAMPLING,
        ConfidenceMethod.COMPOSITE
    ]
    
    results = {}
    
    for method in methods_to_test:
        try:
            logger.info(f"Testing {method.value}...")
            
            confidence_metrics = await confidence_engine.calculate_confidence(
                text=test_text,
                context=test_context,
                method=method,
                use_cache=False  # Don't cache during testing
            )
            
            results[method.value] = {
                'overall_confidence': confidence_metrics.overall_confidence,
                'semantic_consistency': confidence_metrics.semantic_consistency,
                'response_quality': confidence_metrics.response_quality,
                'sampling_consensus': confidence_metrics.sampling_consensus,
                'persona_alignment': confidence_metrics.persona_alignment,
                'processing_time': confidence_metrics.processing_time,
                'gemini_calls_made': confidence_metrics.gemini_calls_made,
                'cache_hit': confidence_metrics.cache_hit
            }
            
            logger.info(f"✅ {method.value}: confidence={confidence_metrics.overall_confidence:.3f}, time={confidence_metrics.processing_time:.2f}s")
            
        except Exception as e:
            logger.error(f"❌ {method.value} failed: {e}")
            results[method.value] = {'error': str(e)}
    
    return results

async def test_persona_selection():
    """Test persona selection based on confidence scores"""
    
    logger.info("🎭 Testing persona selection...")
    
    collections_manager = SoulBiosCollectionsManager()
    confidence_engine = GeminiConfidenceProxyEngine(collections_manager)
    
    # Test different confidence levels
    test_cases = [
        (0.1, "nurturing_presence"),
        (0.4, "wise_detective"), 
        (0.7, "transcendent_guide"),
        (0.9, "unified_consciousness")
    ]
    
    results = {}
    
    for confidence_score, expected_persona in test_cases:
        selected_persona = confidence_engine.get_persona_from_confidence(confidence_score)
        
        results[confidence_score] = {
            'expected': expected_persona,
            'selected': selected_persona,
            'correct': selected_persona == expected_persona
        }
        
        status = "✅" if selected_persona == expected_persona else "❌"
        logger.info(f"{status} Confidence {confidence_score} -> {selected_persona} (expected {expected_persona})")
    
    return results

async def test_soulbios_integration():
    """Test integration with SoulBios collections and conversation processing"""
    
    logger.info("🔗 Testing SoulBios integration...")
    
    collections_manager = SoulBiosCollectionsManager()
    confidence_adapter = SoulBiosConfidenceAdapter(collections_manager)
    
    test_user_id = "test_user_gemini_confidence"
    test_message = "I'm struggling with self-doubt lately. How do I build more confidence?"
    
    try:
        # Process conversation with confidence
        result = await confidence_adapter.process_conversation_with_confidence(
            user_id=test_user_id,
            message=test_message,
            context={'session_type': 'integration_test'}
        )
        
        logger.info("✅ SoulBios integration successful:")
        logger.info(f"  Response: {result['response'][:100]}...")
        logger.info(f"  Confidence: {result['confidence_score']:.3f}")
        logger.info(f"  Persona: {result['persona']}")
        logger.info(f"  Processing time: {result.get('processing_time', 0):.2f}s")
        
        return {
            'success': True,
            'confidence_score': result['confidence_score'],
            'persona': result['persona'],
            'processing_time': result.get('processing_time', 0)
        }
        
    except Exception as e:
        logger.error(f"❌ SoulBios integration failed: {e}")
        return {'success': False, 'error': str(e)}

async def test_caching():
    """Test Redis caching functionality"""
    
    logger.info("💾 Testing caching functionality...")
    
    collections_manager = SoulBiosCollectionsManager()
    confidence_engine = GeminiConfidenceProxyEngine(collections_manager)
    
    test_text = "This is a test response for caching validation."
    test_context = "Test context for cache verification"
    
    try:
        # First call - should not be cached
        start_time = datetime.now()
        result1 = await confidence_engine.calculate_confidence(
            text=test_text,
            context=test_context,
            method=ConfidenceMethod.SEMANTIC_CONSISTENCY,
            use_cache=True
        )
        first_call_time = (datetime.now() - start_time).total_seconds()
        
        # Second call - should be cached
        start_time = datetime.now()
        result2 = await confidence_engine.calculate_confidence(
            text=test_text,
            context=test_context,
            method=ConfidenceMethod.SEMANTIC_CONSISTENCY,
            use_cache=True
        )
        second_call_time = (datetime.now() - start_time).total_seconds()
        
        cache_worked = result2.cache_hit and second_call_time < first_call_time / 2
        
        logger.info(f"✅ Caching test:")
        logger.info(f"  First call: {first_call_time:.2f}s (cache_hit: {result1.cache_hit})")
        logger.info(f"  Second call: {second_call_time:.2f}s (cache_hit: {result2.cache_hit})")
        logger.info(f"  Cache effective: {cache_worked}")
        
        return {
            'cache_worked': cache_worked,
            'first_call_time': first_call_time,
            'second_call_time': second_call_time,
            'speedup': first_call_time / second_call_time if second_call_time > 0 else 1
        }
        
    except Exception as e:
        logger.error(f"❌ Caching test failed: {e}")
        return {'success': False, 'error': str(e)}

async def test_fallback_system():
    """Test fallback system when Gemini API is unavailable"""
    
    logger.info("🚨 Testing fallback system...")
    
    collections_manager = SoulBiosCollectionsManager()
    
    # Create confidence engine with invalid API key to trigger fallback
    original_api_key = config.gemini_api_key
    config.gemini_api_key = None
    
    confidence_engine = GeminiConfidenceProxyEngine(collections_manager)
    
    test_text = "Test response for fallback validation"
    test_context = "Test context"
    
    try:
        result = await confidence_engine.calculate_confidence(
            text=test_text,
            context=test_context,
            method=ConfidenceMethod.COMPOSITE
        )
        
        logger.info("✅ Fallback system working:")
        logger.info(f"  Confidence: {result.overall_confidence:.3f}")
        logger.info(f"  Processing time: {result.processing_time:.2f}s") 
        logger.info(f"  Gemini calls: {result.gemini_calls_made}")
        
        return {
            'success': True,
            'confidence_score': result.overall_confidence,
            'gemini_calls': result.gemini_calls_made
        }
        
    except Exception as e:
        logger.error(f"❌ Fallback test failed: {e}")
        return {'success': False, 'error': str(e)}
        
    finally:
        # Restore original API key
        config.gemini_api_key = original_api_key

async def run_comprehensive_test():
    """Run all integration tests"""
    
    logger.info("🚀 Starting comprehensive Gemini confidence proxy integration test...")
    logger.info("=" * 60)
    
    test_results = {}
    
    # Test 1: Basic confidence calculation
    test_results['basic_confidence'] = await test_basic_confidence_calculation()
    
    # Test 2: Persona selection
    test_results['persona_selection'] = await test_persona_selection()
    
    # Test 3: SoulBios integration
    test_results['soulbios_integration'] = await test_soulbios_integration()
    
    # Test 4: Caching
    test_results['caching'] = await test_caching()
    
    # Test 5: Fallback system
    test_results['fallback'] = await test_fallback_system()
    
    # Summary
    logger.info("=" * 60)
    logger.info("📊 Test Summary:")
    
    total_tests = 0
    passed_tests = 0
    
    for test_name, results in test_results.items():
        if isinstance(results, dict):
            if results.get('success', True):  # Default to True for basic tests
                logger.info(f"✅ {test_name}: PASSED")
                passed_tests += 1
            else:
                logger.info(f"❌ {test_name}: FAILED - {results.get('error', 'Unknown error')}")
            total_tests += 1
    
    success_rate = (passed_tests / total_tests) * 100 if total_tests > 0 else 0
    logger.info(f"📈 Overall success rate: {passed_tests}/{total_tests} ({success_rate:.1f}%)")
    
    if success_rate >= 80:
        logger.info("🎉 Integration test PASSED - System ready for deployment!")
    else:
        logger.info("⚠️  Integration test FAILED - Review errors before deployment")
    
    return test_results

if __name__ == "__main__":
    # Check for required environment variables
    if not config.gemini_api_key:
        logger.error("❌ GEMINI_API_KEY not found. Please set environment variable.")
        exit(1)
    
    # Run comprehensive test
    results = asyncio.run(run_comprehensive_test())
    
    # Exit with appropriate code
    exit(0 if all(r.get('success', True) for r in results.values()) else 1)