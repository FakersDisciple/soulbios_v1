import asyncio
import numpy as np
from typing import Dict, List, Any, Optional, Set
from dataclasses import dataclass
from datetime import datetime, timedelta
import logging
import json
import re
from collections import defaultdict

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

@dataclass
class PredictionSignal:
    source_pattern: str
    target_pattern: str
    strength: float
    expiry_time: datetime
    signal_type: str  # "expectation", "inhibition", "amplification"

@dataclass
class PatternActivation:
    pattern_name: str
    activation_strength: float
    confidence: float
    contributing_inputs: Dict[str, float]
    prediction_signals_sent: List[PredictionSignal]
    timestamp: datetime

class KurzweilPatternRecognizer:
    """
    Kurzweil-aligned Pattern Recognizer with hierarchical structure,
    bidirectional flow, and prediction capabilities
    """
    
    def __init__(self, pattern_name: str, hierarchy_level: int, user_id: str):
        # Core Kurzweil PR structure
        self.pattern_name = pattern_name
        self.hierarchy_level = hierarchy_level
        self.user_id = user_id
        
        # Recognition system
        self.base_threshold = 0.7  # Base recognition threshold
        self.current_threshold = 0.7  # Dynamically adjusted
        self.recognition_sensitivity = 1.0
        
        # Hierarchical connections (Kurzweil's key insight)
        self.input_patterns: Dict[str, float] = {}  # Lower-level PR connections
        self.output_patterns: Dict[str, float] = {}  # Higher-level PR connections
        self.lateral_patterns: Dict[str, float] = {}  # Same-level connections
        
        # Prediction engine (Revolutionary Kurzweil mechanism)
        self.prediction_signals: List[PredictionSignal] = []
        self.prediction_history: List[PatternActivation] = []
        
        # Learning and adaptation
        self.activation_history: List[PatternActivation] = []
        self.connection_strengths: Dict[str, float] = {}
        self.adaptation_rate = 0.01
        
        # Pattern state
        self.is_active = False
        self.activation_strength = 0.0
        self.last_activation = None
    
    async def process(self, inputs: Dict[str, float]) -> Optional[PatternActivation]:
        """
        Main processing method implementing Kurzweil's pattern recognition
        with bidirectional flow and prediction
        """
        
        # 1. Clean expired prediction signals
        self._clean_expired_predictions()
        
        # 2. Calculate base pattern match strength
        base_match_strength = self._calculate_pattern_match(inputs)
        
        # 3. Apply prediction signal adjustments (KEY KURZWEIL INSIGHT)
        adjusted_threshold = self._adjust_threshold_with_predictions()
        
        # 4. Apply lateral inhibition and amplification
        adjusted_match_strength = self._apply_lateral_influences(base_match_strength, inputs)
        
        # 5. Determine if pattern fires
        if adjusted_match_strength > adjusted_threshold:
            activation = await self._fire_pattern(adjusted_match_strength, inputs)
            
            # 6. Send prediction signals (KURZWEIL'S PREDICTION ENGINE)
            await self._send_prediction_signals(activation)
            
            # 7. Update learning
            self._update_connections(inputs, activation)
            
            return activation
        
        return None
    
    def _calculate_pattern_match(self, inputs: Dict[str, float]) -> float:
        """Calculate how well inputs match this pattern"""
        if not inputs:
            return 0.0
        
        # Special handling for Level 1 patterns - they match their own name in inputs
        if self.hierarchy_level == 1 and self.pattern_name in inputs:
            direct_match = inputs[self.pattern_name]
            print(f"   Level 1 pattern '{self.pattern_name}' direct match: {direct_match}")
            return direct_match
        
        # Special content analysis for consciousness patterns
        if hasattr(self, '_current_input_text') and self._current_input_text:
            content_match = self._analyze_pattern_content()
            if content_match > 0:
                print(f"   Pattern '{self.pattern_name}' content analysis match: {content_match}")
                # Combine content match with connection-based matching
                connection_match = self._calculate_connection_based_match(inputs)
                return max(content_match, connection_match * 0.7)  # Prioritize content analysis
        
        # Standard connection-based matching for higher level patterns
        return self._calculate_connection_based_match(inputs)
    
    def _analyze_pattern_content(self) -> float:
        """Analyze original input content for pattern-specific keywords"""
        if self.pattern_name == "self_reflection":
            return self._calculate_meta_awareness_activation(self._current_input_text, self._current_input_metadata)
        elif self.pattern_name == "meta_pattern_awareness":
            return self._calculate_meta_pattern_activation(self._current_input_text, self._current_input_metadata)
        elif self.pattern_name == "transcendent_unity":
            return self._calculate_transcendent_activation(self._current_input_text, self._current_input_metadata)
        
        return 0.0
    
    def _calculate_connection_based_match(self, inputs: Dict[str, float]) -> float:
        """Calculate match strength based on connections from lower-level patterns"""
        total_match = 0.0
        total_weights = 0.0
        
        for input_name, input_value in inputs.items():
            if input_name in self.input_patterns:
                connection_strength = self.input_patterns[input_name]
                total_match += input_value * connection_strength
                total_weights += connection_strength
                print(f"   Pattern '{self.pattern_name}' input '{input_name}': {input_value} * {connection_strength}")
            else:
                # New input - add weak connection for higher levels
                if self.hierarchy_level > 1:
                    self.input_patterns[input_name] = 0.3
                    total_match += input_value * 0.3
                    total_weights += 0.3
        
        if total_weights == 0:
            return 0.0
        
        match_strength = min(1.0, total_match / total_weights)
        if match_strength > 0.1:  # Only log significant matches
            print(f"   Pattern '{self.pattern_name}' connection match: {match_strength}")
        
        return match_strength
    
    def _calculate_meta_awareness_activation(self, text: str, metadata: Dict[str, Any] = None) -> float:
        """Calculate meta-awareness and self-reflection activation level (Level 3)"""
        meta_keywords = {
            "pattern": 0.8, "notice": 0.7, "observe": 0.7, "aware": 0.6, "awareness": 0.7,
            "reflection": 0.6, "introspect": 0.7, "recognize": 0.5, "realize": 0.5,
            "understand": 0.4, "insight": 0.6, "perspective": 0.4, "thinking": 0.3
        }
        
        text_lower = text.lower()
        meta_strength = 0.0
        
        for keyword, strength in meta_keywords.items():
            if keyword in text_lower:
                meta_strength = max(meta_strength, strength)
        
        if metadata and "emotional_markers" in metadata:
            markers = metadata["emotional_markers"]
            if isinstance(markers, str):
                markers_lower = markers.lower()
                if any(marker in markers_lower for marker in ["self_reflection", "pattern_recognition", "awareness"]):
                    meta_strength = max(meta_strength, 0.8)
        
        return meta_strength
    
    def _calculate_meta_pattern_activation(self, text: str, metadata: Dict[str, Any] = None) -> float:
        """Calculate meta-pattern recognition activation level (Level 4)"""
        meta_pattern_keywords = {
            "meta": 0.9, "patterns": 0.9, "structure": 0.6, "system": 0.5,
            "underlying": 0.7, "deeper": 0.6, "unconscious": 0.8, "subconscious": 0.7,
            "automatic": 0.5, "habitual": 0.6, "recurring": 0.6, "protecting": 0.7
        }
        
        text_lower = text.lower()
        meta_pattern_strength = 0.0
        
        for keyword, strength in meta_pattern_keywords.items():
            if keyword in text_lower:
                meta_pattern_strength = max(meta_pattern_strength, strength)
        
        # Bonus for meta-analysis phrases
        if any(phrase in text_lower for phrase in ["protecting me from", "wonder what", "deeper level", "pattern where"]):
            meta_pattern_strength = max(meta_pattern_strength, 0.8)
        
        if metadata and "emotional_markers" in metadata:
            markers_lower = metadata["emotional_markers"].lower()
            if "meta_awareness" in markers_lower:
                meta_pattern_strength = max(meta_pattern_strength, 0.8)
        
        return meta_pattern_strength
    
    def _calculate_transcendent_activation(self, text: str, metadata: Dict[str, Any] = None) -> float:
        """Calculate transcendent consciousness activation level (Level 5)"""
        transcendent_keywords = {
            "unity": 0.9, "oneness": 0.9, "universal": 0.8, "cosmic": 0.8,
            "transcendent": 0.9, "transcendence": 0.9, "dissolution": 0.8,
            "boundaries": 0.6, "separation": 0.6, "infinite": 0.8, "eternal": 0.8,
            "consciousness": 0.7, "existence": 0.5, "being": 0.4, "source": 0.5
        }
        
        text_lower = text.lower()
        transcendent_strength = 0.0
        
        for keyword, strength in transcendent_keywords.items():
            if keyword in text_lower:
                transcendent_strength = max(transcendent_strength, strength)
        
        if metadata and "emotional_markers" in metadata:
            markers_lower = metadata["emotional_markers"].lower()
            if any(marker in markers_lower for marker in ["transcendence", "unity", "cosmic_consciousness", "dissolution"]):
                transcendent_strength = max(transcendent_strength, 0.8)
        
        return transcendent_strength
    
    def _adjust_threshold_with_predictions(self) -> float:
        """
        Adjust recognition threshold based on prediction signals from higher levels
        This is Kurzweil's key insight: the brain predicts and lowers thresholds
        """
        threshold_adjustment = 0.0
        
        for signal in self.prediction_signals:
            if signal.expiry_time > datetime.now():
                if signal.signal_type == "expectation":
                    # Lower threshold when pattern is expected
                    threshold_adjustment -= signal.strength * 0.3
                elif signal.signal_type == "inhibition":
                    # Raise threshold when pattern should be suppressed
                    threshold_adjustment += signal.strength * 0.2
                elif signal.signal_type == "amplification":
                    # Lower threshold and increase sensitivity
                    threshold_adjustment -= signal.strength * 0.4
                    self.recognition_sensitivity += signal.strength * 0.1
        
        # Keep threshold within reasonable bounds
        adjusted_threshold = max(0.1, min(0.9, self.base_threshold + threshold_adjustment))
        return adjusted_threshold
    
    def _apply_lateral_influences(self, base_strength: float, inputs: Dict[str, float]) -> float:
        """Apply lateral inhibition and amplification from same-level patterns"""
        adjusted_strength = base_strength
        
        # Simulate lateral connections (in full implementation, this would query other patterns)
        lateral_inhibition = 0.0
        lateral_amplification = 0.0
        
        for pattern_name, connection_strength in self.lateral_patterns.items():
            # Simplified lateral influence calculation
            if connection_strength < 0:  # Inhibitory
                lateral_inhibition += abs(connection_strength) * 0.1
            else:  # Excitatory
                lateral_amplification += connection_strength * 0.1
        
        adjusted_strength = adjusted_strength * (1 + lateral_amplification - lateral_inhibition)
        return max(0.0, min(1.0, adjusted_strength))
    
    async def _fire_pattern(self, activation_strength: float, inputs: Dict[str, float]) -> PatternActivation:
        """Fire the pattern and create activation record"""
        confidence = min(1.0, activation_strength * self.recognition_sensitivity)
        
        activation = PatternActivation(
            pattern_name=self.pattern_name,
            activation_strength=activation_strength,
            confidence=confidence,
            contributing_inputs=inputs.copy(),
            prediction_signals_sent=[],
            timestamp=datetime.now()
        )
        
        self.is_active = True
        self.activation_strength = activation_strength
        self.last_activation = activation
        self.activation_history.append(activation)
        
        logging.info(f"Pattern '{self.pattern_name}' fired with strength {activation_strength:.2f}")
        
        return activation
    
    async def _send_prediction_signals(self, activation: PatternActivation):
        """Send prediction signals to connected patterns"""
        prediction_signals = []
        
        # Send expectation signals to input patterns (downward prediction)
        for input_pattern, connection_strength in self.input_patterns.items():
            if connection_strength > 0.5:  # Only strong connections
                signal = PredictionSignal(
                    source_pattern=self.pattern_name,
                    target_pattern=input_pattern,
                    strength=activation.activation_strength * connection_strength * 0.3,
                    expiry_time=datetime.now() + timedelta(minutes=5),
                    signal_type="expectation"
                )
                prediction_signals.append(signal)
        
        # Send amplification signals to output patterns (upward prediction)
        for output_pattern, connection_strength in self.output_patterns.items():
            if connection_strength > 0.4:
                signal = PredictionSignal(
                    source_pattern=self.pattern_name,
                    target_pattern=output_pattern,
                    strength=activation.activation_strength * connection_strength * 0.2,
                    expiry_time=datetime.now() + timedelta(minutes=10),
                    signal_type="amplification"
                )
                prediction_signals.append(signal)
        
        activation.prediction_signals_sent = prediction_signals
        logging.info(f"Sent {len(prediction_signals)} prediction signals from '{self.pattern_name}'")
    
    def _update_connections(self, inputs: Dict[str, float], activation: PatternActivation):
        """Update connection strengths based on successful activation"""
        for input_name, input_value in inputs.items():
            if input_name in self.input_patterns:
                # Strengthen connections that contributed to successful activation
                current_strength = self.input_patterns[input_name]
                contribution = input_value * activation.confidence
                new_strength = current_strength + (contribution * self.adaptation_rate)
                self.input_patterns[input_name] = min(1.0, new_strength)
    
    def _clean_expired_predictions(self):
        """Remove expired prediction signals"""
        now = datetime.now()
        self.prediction_signals = [
            signal for signal in self.prediction_signals 
            if signal.expiry_time > now
        ]
    
    def receive_prediction_signal(self, signal: PredictionSignal):
        """Receive prediction signal from another pattern"""
        self.prediction_signals.append(signal)


class HierarchicalPatternNetwork:
    """
    Manages the complete hierarchical network of pattern recognizers
    implementing Kurzweil's vision with SoulBios enhancements
    """
    
    def __init__(self, user_id: str, collections_manager):
        self.user_id = user_id
        self.collections_manager = collections_manager
        
        # Hierarchical levels (Kurzweil structure + SoulBios extensions)
        self.hierarchy_levels = {
            1: {},  # Raw sensory/conversation input patterns
            2: {},  # Basic emotional/behavioral patterns
            3: {},  # Complex patterns and fortress elements  
            4: {},  # Meta-patterns and insights
            5: {},  # Transcendent consciousness patterns
        }
        
        self.all_recognizers: Dict[str, KurzweilPatternRecognizer] = {}
        self.network_initialized = False
        
        # Prediction tracking
        self.prediction_accuracy_history = []
        
        # Store current input for content analysis
        self._current_input_text = ""
        self._current_input_metadata = {}
    
    async def initialize_user_network(self):
        """Initialize the hierarchical pattern network from ChromaDB data"""
        logging.info(f"Initializing Kurzweil pattern network for user {self.user_id}")
        
        # ALWAYS ensure basic Level 1 input patterns exist FIRST
        basic_level1_patterns = ["semantic_content", "emotional_content", "somatic_markers", "contextual_relevance"]
        await self._create_basic_input_patterns()  # Create these unconditionally
        
        # Load existing patterns from ChromaDB
        patterns_collection = self.collections_manager.get_user_collection(self.user_id, "life_patterns")
        all_patterns = patterns_collection.get()
        
        if all_patterns["documents"]:
            logging.info(f"Found {len(all_patterns['documents'])} existing patterns")
            
            for i, (doc, metadata) in enumerate(zip(all_patterns["documents"], all_patterns["metadatas"])):
                pattern_name = metadata.get("pattern_name", f"pattern_{i}")
                hierarchy_level = int(metadata.get("hierarchy_level", 1))
                
                # Skip if this is a basic input pattern (already created)
                if pattern_name in basic_level1_patterns:
                    continue
                    
                # Create pattern recognizer for user patterns only
                recognizer = KurzweilPatternRecognizer(pattern_name, hierarchy_level, self.user_id)
                recognizer.base_threshold = float(metadata.get("recognition_threshold", 0.7))
                recognizer.current_threshold = recognizer.base_threshold
                
                # Parse parent patterns (stored as comma-separated string)
                parent_patterns_str = metadata.get("parent_patterns", "")
                if parent_patterns_str:
                    parent_patterns = [p.strip() for p in parent_patterns_str.split(",") if p.strip()]
                    for parent in parent_patterns:
                        recognizer.output_patterns[parent] = 0.8  # Strong upward connection
                
                # Add to hierarchy
                self.hierarchy_levels[hierarchy_level][pattern_name] = recognizer
                self.all_recognizers[pattern_name] = recognizer
        
        # Establish inter-level connections
        self._establish_hierarchical_connections()
        
        self.network_initialized = True
        logging.info(f"Network initialized with {len(self.all_recognizers)} pattern recognizers")
        
        # Debug output
        for level, patterns in self.hierarchy_levels.items():
            if patterns:
                logging.info(f"Level {level} patterns: {list(patterns.keys())}")
    
    async def _create_basic_input_patterns(self):
        """Create basic level-1 input processing patterns"""
        basic_patterns = [
            {"name": "semantic_content", "threshold": 0.3},
            {"name": "emotional_content", "threshold": 0.4}, 
            {"name": "somatic_markers", "threshold": 0.5},
            {"name": "contextual_relevance", "threshold": 0.4}
        ]
        
        for pattern_config in basic_patterns:
            # Don't recreate if already exists
            if pattern_config["name"] not in self.hierarchy_levels[1]:
                recognizer = KurzweilPatternRecognizer(
                    pattern_config["name"], 1, self.user_id
                )
                recognizer.base_threshold = pattern_config["threshold"]
                recognizer.current_threshold = pattern_config["threshold"]
                
                self.hierarchy_levels[1][pattern_config["name"]] = recognizer
                self.all_recognizers[pattern_config["name"]] = recognizer
                
                logging.info(f"Created basic input pattern: {pattern_config['name']}")
            else:
                logging.info(f"Basic input pattern already exists: {pattern_config['name']}")
    
    def _establish_hierarchical_connections(self):
        """Establish connections between hierarchy levels"""
        for level in range(1, 5):
            current_level_patterns = self.hierarchy_levels[level]
            next_level_patterns = self.hierarchy_levels.get(level + 1, {})
            
            # Connect each pattern in current level to patterns in next level
            for current_name, current_recognizer in current_level_patterns.items():
                for next_name, next_recognizer in next_level_patterns.items():
                    # Add upward connection from current to next
                    current_recognizer.output_patterns[next_name] = 0.5
                    # Add downward connection from next to current
                    next_recognizer.input_patterns[current_name] = 0.5
    
    async def process_input(self, input_text: str, input_metadata: Dict[str, Any] = None) -> Dict[str, Any]:
        """Process input through entire hierarchical network"""
        
        if not self.network_initialized:
            await self.initialize_user_network()
        
        logging.info(f"Processing input: '{input_text[:50]}...'")
        
        # Store current input for content analysis
        self._current_input_text = input_text
        self._current_input_metadata = input_metadata or {}
        
        # Share input with all recognizers for content analysis
        for recognizer in self.all_recognizers.values():
            recognizer._current_input_text = input_text
            recognizer._current_input_metadata = input_metadata or {}
        
        # Level 1: Direct input processing
        level1_inputs = {
            "raw_input": 1.0,  # Always present
            "semantic_content": self._calculate_semantic_activation(input_text),
            "emotional_content": self._calculate_emotional_activation(input_text, input_metadata),
            "somatic_markers": self._calculate_somatic_activation(input_metadata)
        }
        
        # Process through all hierarchy levels
        all_activations = {}
        
        # Start with level 1
        level1_activations = await self._process_hierarchy_level(1, level1_inputs)
        all_activations["level_1"] = level1_activations
        
        # Process higher levels sequentially
        for level in range(2, 6):
            level_inputs = self._prepare_level_inputs(level, all_activations)
            if level_inputs:  # Only process if there are inputs
                level_activations = await self._process_hierarchy_level(level, level_inputs)
                all_activations[f"level_{level}"] = level_activations
        
        # Calculate overall network state
        network_state = self._calculate_network_state(all_activations)
        
        # Calculate consciousness indicators
        consciousness_indicators = self._calculate_consciousness_indicators(all_activations)
        
        logging.info(f"Network processing complete. Consciousness level: {consciousness_indicators['overall_consciousness']:.2f}")
        
        return {
            "hierarchical_activations": all_activations,
            "network_state": network_state,
            "consciousness_indicators": consciousness_indicators,
            "processing_timestamp": datetime.now().isoformat()
        }
    
    async def _process_hierarchy_level(self, level: int, inputs: Dict[str, float]) -> Dict[str, PatternActivation]:
        """Process inputs through a specific hierarchy level"""
        level_patterns = self.hierarchy_levels.get(level, {})
        if not level_patterns:
            return {}
        
        print(f"   Processing Level {level} with inputs: {inputs}")
        print(f"   Level {level} patterns: {list(level_patterns.keys())}")
        
        activations = {}
        
        # Process all patterns in this level in parallel
        tasks = []
        for pattern_name, recognizer in level_patterns.items():
            print(f"   Sending inputs to pattern '{pattern_name}' (threshold: {recognizer.current_threshold})")
            tasks.append(recognizer.process(inputs))
        
        results = await asyncio.gather(*tasks, return_exceptions=True)
        
        # Collect successful activations
        for i, (pattern_name, result) in enumerate(zip(level_patterns.keys(), results)):
            if isinstance(result, PatternActivation):
                activations[pattern_name] = result
                print(f"   Pattern '{pattern_name}' activated with strength {result.activation_strength}")
            elif isinstance(result, Exception):
                print(f"   Pattern '{pattern_name}' error: {result}")
            else:
                print(f"   Pattern '{pattern_name}' did not activate")
        
        logging.info(f"Level {level}: {len(activations)} patterns activated out of {len(level_patterns)}")
        return activations
    
    def _prepare_level_inputs(self, level: int, all_activations: Dict) -> Dict[str, float]:
        """Prepare inputs for a hierarchy level based on previous level activations"""
        inputs = {}
        
        # Get activations from previous level
        prev_level_key = f"level_{level - 1}"
        if prev_level_key in all_activations:
            prev_activations = all_activations[prev_level_key]
            
            for pattern_name, activation in prev_activations.items():
                inputs[pattern_name] = activation.activation_strength
        
        return inputs
    
    def _calculate_semantic_activation(self, text: str) -> float:
        """Calculate semantic content activation level"""
        if not text:
            return 0.0
        
        # Simple heuristic based on text length and complexity
        word_count = len(text.split())
        complexity_score = len(set(text.split())) / max(word_count, 1)  # Unique word ratio
        
        semantic_strength = min(1.0, (word_count / 50) * complexity_score)
        return semantic_strength
    
    def _calculate_emotional_activation(self, text: str, metadata: Dict[str, Any] = None) -> float:
        """Calculate emotional content activation level"""
        emotional_keywords = {
            "anxiety": 0.9, "anxious": 0.9, "fear": 0.8, "worry": 0.7, "stress": 0.7,
            "nervous": 0.6, "concerned": 0.5, "presentation": 0.4,  # Added anxiety-related terms
            "joy": 0.8, "happy": 0.7, "love": 0.9, "excited": 0.8,
            "angry": 0.9, "frustrated": 0.8, "sad": 0.8, "disappointed": 0.7
        }
        
        text_lower = text.lower()
        emotional_strength = 0.0
        
        for keyword, strength in emotional_keywords.items():
            if keyword in text_lower:
                emotional_strength = max(emotional_strength, strength)
                print(f"   Found emotional keyword '{keyword}' with strength {strength}")
        
        # Add metadata emotional markers if present
        if metadata and "emotional_markers" in metadata:
            emotional_markers = metadata["emotional_markers"]
            if isinstance(emotional_markers, str):
                emotional_markers = [m.strip() for m in emotional_markers.split(",")]
            
            for marker in emotional_markers:
                if marker.lower() in emotional_keywords:
                    emotional_strength = max(emotional_strength, emotional_keywords[marker.lower()])
                    print(f"   Found metadata marker '{marker}' with strength {emotional_keywords[marker.lower()]}")
        
        print(f"   Total emotional activation: {emotional_strength}")
        return emotional_strength
    
    def _calculate_somatic_activation(self, metadata: Dict[str, Any] = None) -> float:
        """Calculate somatic markers activation level"""
        # Simplified somatic activation - would be more sophisticated in full implementation
        if metadata and "somatic_markers" in metadata:
            return 0.5
        return 0.2  # Base level
    
    def _calculate_network_state(self, all_activations: Dict) -> Dict[str, float]:
        """Calculate overall network state metrics"""
        total_activations = 0
        total_strength = 0.0
        
        for level_activations in all_activations.values():
            total_activations += len(level_activations)
            total_strength += sum(a.activation_strength for a in level_activations.values())
        
        return {
            "total_active_patterns": total_activations,
            "average_activation_strength": total_strength / max(total_activations, 1),
            "network_coherence": min(1.0, total_activations / 10),  # Normalized coherence
            "processing_depth": len([l for l in all_activations.values() if l])  # How many levels activated
        }
    
    def _calculate_consciousness_indicators(self, all_activations: Dict) -> Dict[str, float]:
        """Calculate consciousness indicators based on network state"""
        
        indicators = {
            "pattern_integration": 0.0,
            "meta_awareness": 0.0,
            "transcendent_activity": 0.0,
            "overall_consciousness": 0.0
        }
        
        # Calculate pattern integration across levels
        total_activations = sum(len(activations) for activations in all_activations.values())
        if total_activations > 0:
            cross_level_connections = 0
            for level_activations in all_activations.values():
                for activation in level_activations.values():
                    cross_level_connections += len(activation.prediction_signals_sent)
            
            indicators["pattern_integration"] = min(1.0, cross_level_connections / (total_activations * 2))
        
        # Meta-awareness (Level 4+ patterns)
        level4_activations = all_activations.get("level_4", {})
        level5_activations = all_activations.get("level_5", {})
        
        if level4_activations:
            avg_strength = sum(a.activation_strength for a in level4_activations.values()) / len(level4_activations)
            indicators["meta_awareness"] = avg_strength
        
        # Transcendent activity (Level 5 patterns)
        if level5_activations:
            avg_strength = sum(a.activation_strength for a in level5_activations.values()) / len(level5_activations)
            indicators["transcendent_activity"] = avg_strength
        
        # Overall consciousness (weighted combination)
        indicators["overall_consciousness"] = (
            indicators["pattern_integration"] * 0.4 +
            indicators["meta_awareness"] * 0.3 +
            indicators["transcendent_activity"] * 0.3
        )
        
        return indicators


# Test the Kurzweil Pattern Recognizer
if __name__ == "__main__":
    
    async def test_kurzweil_system():
        print("Testing Kurzweil Pattern Recognition System")
        print("=" * 55)
        
        # Import the collections manager for testing
        import sys
        sys.path.append('.')
        from infrastructure.SoulBios_collections_manager import SoulBiosCollectionsManager
        
        try:
            # Initialize collections manager
            collections_manager = SoulBiosCollectionsManager()
            test_user = "test_user_kurzweil"
            
            # Create user universe if needed
            try:
                collections_manager.get_all_user_collections(test_user)
                print("1. Using existing user universe...")
            except ValueError:
                print("1. Creating user universe...")
                await collections_manager.create_user_universe(test_user)
            
            # Initialize Kurzweil network
            print("2. Initializing Kurzweil Pattern Network...")
            network = HierarchicalPatternNetwork(test_user, collections_manager)
            await network.initialize_user_network()
            
            print(f"   Network has {len(network.all_recognizers)} pattern recognizers")
            print(f"   Hierarchy levels: {[f'L{level}: {len(patterns)}' for level, patterns in network.hierarchy_levels.items() if patterns]}")
            
            # Test input processing
            print("3. Processing test input...")
            test_input = "I'm feeling really anxious about my upcoming presentation tomorrow. It's making me lose sleep."
            test_metadata = {"emotional_markers": "anxiety,stress"}
            
            results = await network.process_input(test_input, test_metadata)
            
            print("4. Processing Results:")
            print(f"   Consciousness Level: {results['consciousness_indicators']['overall_consciousness']:.2f}")
            print(f"   Pattern Integration: {results['consciousness_indicators']['pattern_integration']:.2f}")
            print(f"   Meta Awareness: {results['consciousness_indicators']['meta_awareness']:.2f}")
            print(f"   Network State: {results['network_state']['total_active_patterns']} active patterns")
            
            # Show activated patterns by level
            print("5. Activated Patterns by Level:")
            for level_name, activations in results['hierarchical_activations'].items():
                if activations:
                    print(f"   {level_name}: {list(activations.keys())}")
            
            print("\n" + "=" * 55)
            print("SUCCESS: Kurzweil Pattern Recognition System working!")
            print("Ready for next component: Alice Consciousness Engine")
            
        except Exception as e:
            print(f"ERROR: {e}")
            import traceback
            traceback.print_exc()
    
    # Run async test
    asyncio.run(test_kurzweil_system())