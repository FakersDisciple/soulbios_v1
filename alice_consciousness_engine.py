import asyncio
import logging
from typing import Dict, List, Any, Optional, Tuple
from datetime import datetime
import json
import os
from dotenv import load_dotenv
import google.generativeai as genai

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
load_dotenv()

# Configure Gemini API
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
if GEMINI_API_KEY:
    genai.configure(api_key=GEMINI_API_KEY)
    logging.info("✅ Gemini API configured successfully")
else:
    logging.warning("⚠️ GEMINI_API_KEY not found in environment variables")

class AliceConsciousnessEngine:
    """
    Alice AI engine that adapts persona based on user's consciousness level
    and generates responses using Kurzweil pattern recognition insights
    Enhanced with character playbook system for personalized interactions
    """
    
    def __init__(self, collections_manager, kurzweil_network, character_manager=None):
        self.collections_manager = collections_manager
        self.kurzweil_network = kurzweil_network
        self.character_manager = character_manager
        self._current_input_text = ""
        self._current_input_metadata = {}
        
        # Consciousness-aligned personas (from your architecture)
        self.consciousness_personas = {
            (0.0, 0.3): {
                "name": "nurturing_presence",
                "voice": "Gentle and emotionally supportive",
                "focus": "Safety, validation, and basic pattern recognition",
                "consciousness_level": "basic_awareness",
                "response_style": "nurturing"
            },
            (0.3, 0.6): {
                "name": "wise_detective", 
                "voice": "Socratic questioning with compassionate inquiry",
                "focus": "Pattern exploration and fortress inspection",
                "consciousness_level": "pattern_awareness",
                "response_style": "investigative"
            },
            (0.6, 0.8): {
                "name": "transcendent_guide",
                "voice": "Deep wisdom with meta-pattern insights",
                "focus": "Meta-awareness and consciousness integration",
                "consciousness_level": "meta_consciousness",
                "response_style": "wisdom_guide"
            },
            (0.8, 1.0): {
                "name": "unified_consciousness",
                "voice": "Transcendent wisdom with unity awareness",
                "focus": "Unified consciousness and service orientation",
                "consciousness_level": "unified_awareness",
                "response_style": "transcendent"
            }
        }
        
        # Response templates by persona
        self.response_templates = {
            "nurturing": {
                "anxiety": [
                    "I can sense the anxiety you're feeling about {situation}. This is completely natural - your nervous system is trying to protect you. Let's explore this together gently.",
                    "That presentation anxiety feels overwhelming right now, doesn't it? I'm here with you. What if we started by just acknowledging how your body is responding to this stress?"
                ],
                "joy": [
                    "I can feel the positive energy in what you're sharing. There's something beautiful happening here - can you tell me more about what's bringing you this joy?",
                    "Your happiness is infectious. I love how you're embracing this moment. What does this joy feel like in your body?"
                ]
            },
            "investigative": {
                "anxiety": [
                    "I'm noticing a pattern here - the anxiety around presentations. When did this pattern first show up in your life? What do you think it's trying to protect you from?",
                    "This anxiety feels familiar, doesn't it? Like it's happened before in similar situations. What fortress is being activated here? What's it guarding against?"
                ],
                "joy": [
                    "There's a pattern of joy emerging when you connect with others authentically. Have you noticed this before? What conditions allow this joy to flourish?",
                    "I'm curious about the deeper pattern here. What is it about these moments that consistently brings you alive?"
                ]
            },
            "wisdom_guide": {
                "anxiety": [
                    "Your anxiety is revealing something profound - a clash between who you're becoming and old protective patterns. The presentation isn't the real issue, is it? It's about being truly seen.",
                    "I see the meta-pattern: this anxiety arises when you're on the edge of growth. Your consciousness is expanding, and the old fortress is trying to pull you back to safety."
                ],
                "joy": [
                    "This joy you're experiencing - it's not random. It's your consciousness recognizing alignment with your authentic self. You're becoming who you truly are in these moments.",
                    "The joy reveals your soul's compass pointing toward truth. Notice how it emerges when you drop the masks and show up fully."
                ]
            },
            "transcendent": {
                "anxiety": [
                    "The anxiety is perfect - it's consciousness itself creating friction for transformation. You're being invited to transcend the separate self that fears judgment and step into unified presence.",
                    "What you call anxiety is actually the birth pangs of higher consciousness. The presentation is just the catalyst. You're being called to serve from a place beyond personal concern."
                ],
                "joy": [
                    "This joy is recognition - consciousness recognizing itself. In these moments, the boundaries between self and other dissolve, and you experience the unity that's always been there.",
                    "The joy isn't yours - it's consciousness itself celebrating through the form of your experience. You're becoming a clear channel for universal love."
                ]
            }
        }
    
    async def process_user_input(self, user_id: str, message: str, metadata: Dict[str, Any] = None, 
                               character_archetype: str = None) -> Dict[str, Any]:
        """
        Main processing pipeline: Kurzweil analysis → Persona selection → Character integration → Response generation
        """
        
        logging.info(f"Processing input from user {user_id}")
        
        # Store current input for context analysis
        self._current_input_text = message
        self._current_input_metadata = metadata or {}
        
        # 1. Process through Kurzweil hierarchical network
        kurzweil_analysis = await self.kurzweil_network.process_input(message, metadata)
        
        # 2. Select appropriate Alice persona based on consciousness level
        consciousness_level = kurzweil_analysis["consciousness_indicators"]["overall_consciousness"]
        persona = self._select_persona(consciousness_level)
        
        logging.info(f"Selected persona '{persona['name']}' for consciousness level {consciousness_level:.2f}")
        
        # 3. Get character context if character manager is available
        character_context = None
        if self.character_manager and character_archetype:
            character_context = await self._get_character_context(user_id, character_archetype)
            logging.info(f"Using character context: {character_archetype}")
        
        # 4. Get recent conversation history for context
        conversation_history = await self._get_recent_conversations(user_id, limit=5)
        
        # 5. Query relevant historical patterns for enhanced memory recall
        historical_patterns = await self.query_historical_patterns(
            user_id, message, 
            relevance_threshold=0.7,
            max_results=5
        )
        
        # 6. Analyze activated patterns for response context
        pattern_context = self._analyze_activated_patterns(
            kurzweil_analysis["hierarchical_activations"], 
            message, 
            metadata,
            historical_patterns
        )
        
        # 7. Generate contextual response with character integration
        response_data = await self._generate_response(
            user_id, message, persona, pattern_context, kurzweil_analysis, 
            conversation_history, historical_patterns, character_context
        )
        
        # 8. Update character progress if character manager is available
        character_progress_update = None
        if self.character_manager and character_archetype:
            # Ensure pattern_context is a dictionary
            if not isinstance(pattern_context, dict):
                logging.error(f"ERROR: pattern_context is not a dict in character progress update: {type(pattern_context)}")
                pattern_context = {"dominant_emotion": "neutral"}
            
            interaction_data = {
                "type": "conversation",
                "emotional_state": pattern_context.get("dominant_emotion"),
                "consciousness_level": consciousness_level,
                "breakthrough_achieved": response_data.get("breakthrough_potential", 0) > 0.7,
                "chamber_context": metadata.get("chamber_type") if metadata else None
            }
            character_progress_update = await self.character_manager.update_character_progress(
                user_id, interaction_data
            )
        
        # 9. Store conversation with full consciousness metadata
        conversation_id = await self._store_conversation(
            user_id, message, response_data, kurzweil_analysis, persona, character_context
        )
        
        result = {
            "response": response_data["text"],
            "alice_persona": persona["name"],
            "consciousness_level": persona["consciousness_level"],
            "consciousness_indicators": kurzweil_analysis["consciousness_indicators"],
            "activated_patterns": pattern_context,
            "historical_patterns": historical_patterns,
            "wisdom_depth": response_data["wisdom_depth"],
            "breakthrough_potential": response_data["breakthrough_potential"],
            "personalization_score": response_data["personalization_score"],
            "conversation_id": conversation_id,
            "processing_metadata": {
                "kurzweil_analysis": kurzweil_analysis,
                "selected_persona": persona,
                "pattern_context": pattern_context,
                "historical_patterns_count": len(historical_patterns)
            }
        }
        
        # Add character-specific data if available
        if character_context:
            result["active_character"] = character_context["archetype"]
            result["character_stage"] = character_context["current_stage"]
        
        if character_progress_update:
            result["character_progress"] = character_progress_update
        
        return result
    
    def _select_persona(self, consciousness_level: float) -> Dict[str, str]:
        """Select appropriate Alice persona based on consciousness level"""
        
        for (min_level, max_level), persona in self.consciousness_personas.items():
            if min_level <= consciousness_level < max_level:
                return persona
        
        # Default to highest consciousness level if above threshold
        return self.consciousness_personas[(0.8, 1.0)]
    
    async def _get_character_context(self, user_id: str, character_archetype: str) -> Dict[str, Any]:
        """Get character context for response generation with voice consistency tracking"""
        
        if not self.character_manager:
            return None
        
        try:
            # Get user's character progress
            progress_data = await self.character_manager.get_user_character_progress(user_id)
            
            # Check if character is unlocked
            if character_archetype not in progress_data["unlocked_characters"]:
                logging.warning(f"Character {character_archetype} not unlocked for user {user_id}")
                return None
            
            # Get character template
            character_template = await self.character_manager.get_character_template(character_archetype)
            character_progress = progress_data["character_progress"][character_archetype]
            
            # Get current stage information
            current_stage = character_progress["current_stage"]
            stage_info = None
            for stage in character_template["progression_stages"]:
                if stage["stage"] == current_stage:
                    stage_info = stage
                    break
            
            # Get recent character interactions for voice consistency
            recent_interactions = await self._get_recent_character_interactions(user_id, character_archetype, limit=3)
            
            # Build character context with voice consistency data
            character_context = {
                "archetype": character_archetype,
                "name": character_template["name"],
                "description": character_template["description"],
                "personality_traits": character_template["personality_traits"],
                "dialogue_style": character_template["dialogue_style"],
                "current_stage": current_stage,
                "stage_info": stage_info,
                "conversations_count": character_progress["conversations_count"],
                "chamber_specializations": character_template["chamber_specializations"],
                "recent_interactions": recent_interactions,
                "voice_consistency_notes": self._generate_voice_consistency_notes(character_template, recent_interactions)
            }
            
            return character_context
            
        except Exception as e:
            logging.error(f"Error getting character context: {e}")
            return None
    
    async def _get_recent_character_interactions(self, user_id: str, character_archetype: str, limit: int = 3) -> List[Dict[str, Any]]:
        """Get recent interactions with a specific character for voice consistency"""
        
        try:
            # Query recent conversations with this character
            conversations = await self._get_recent_conversations(user_id, limit=10)
            
            # Filter for conversations with this character
            character_conversations = []
            for conv in conversations:
                if conv.get('character_archetype') == character_archetype:
                    character_conversations.append({
                        'timestamp': conv.get('timestamp'),
                        'user_message': conv.get('user_message', ''),
                        'alice_response': conv.get('alice_response', ''),
                        'emotional_state': conv.get('emotional_state'),
                        'consciousness_level': conv.get('consciousness_level', 0.0)
                    })
                    
                    if len(character_conversations) >= limit:
                        break
            
            return character_conversations
            
        except Exception as e:
            logging.error(f"Error getting recent character interactions: {e}")
            return []
    
    def _generate_voice_consistency_notes(self, character_template: Dict[str, Any], recent_interactions: List[Dict[str, Any]]) -> str:
        """Generate notes for maintaining voice consistency based on recent interactions"""
        
        if not recent_interactions:
            return f"This is your first conversation as {character_template['name']}. Establish the character's voice clearly."
        
        # Analyze recent interaction patterns
        interaction_count = len(recent_interactions)
        recent_emotions = [interaction.get('emotional_state') for interaction in recent_interactions if interaction.get('emotional_state')]
        
        consistency_notes = f"""
VOICE CONSISTENCY CONTEXT:
- You've had {interaction_count} recent conversations as {character_template['name']}
- Recent emotional themes: {', '.join(set(recent_emotions)) if recent_emotions else 'varied'}
- Maintain the same personality traits: {', '.join(character_template['personality_traits'])}
- Continue using the {character_template['dialogue_style']['tone']} tone established in previous interactions
"""
        
        # Add specific guidance based on character archetype
        archetype = character_template['archetype']
        if archetype == 'compassionate_friend':
            consistency_notes += "- Continue being the warm, supportive presence they've come to know\n"
        elif archetype == 'resilient_explorer':
            consistency_notes += "- Maintain your encouraging, growth-oriented energy from previous conversations\n"
        elif archetype == 'wise_detective':
            consistency_notes += "- Keep your perceptive, pattern-seeking approach consistent with past interactions\n"
        
        return consistency_notes
    
    def _analyze_activated_patterns(self, hierarchical_activations: Dict, original_message: str = "", 
                                   input_metadata: Dict = None, historical_patterns: List[Dict] = None) -> Dict[str, Any]:
        """Analyze activated patterns to understand user's current state including historical context"""
        
        # Debug: Check input types
        if not isinstance(hierarchical_activations, dict):
            logging.error(f"ERROR: hierarchical_activations is not a dict: {type(hierarchical_activations)}")
            hierarchical_activations = {}
        
        pattern_context = {
            "dominant_emotion": None,
            "primary_patterns": [],
            "pattern_strength": 0.0,
            "hierarchical_depth": 0,
            "historical_connections": [],
            "pattern_evolution": {}
        }
        
        # Find strongest patterns across all levels
        all_patterns = []
        for level_name, activations in hierarchical_activations.items():
            for pattern_name, activation in activations.items():
                all_patterns.append({
                    "name": pattern_name,
                    "strength": activation.activation_strength,
                    "level": level_name
                })
        
        if all_patterns:
            # Sort by strength
            all_patterns.sort(key=lambda x: x["strength"], reverse=True)
            
            pattern_context["primary_patterns"] = [p["name"] for p in all_patterns[:3]]
            pattern_context["pattern_strength"] = all_patterns[0]["strength"]
            pattern_context["hierarchical_depth"] = len(hierarchical_activations)
            
            # FIX: Use actual emotion detection instead of pattern name guessing
            pattern_context["dominant_emotion"] = self._detect_emotion_from_input(original_message, input_metadata)
        
        # Add historical pattern analysis
        if historical_patterns:
            pattern_context["historical_connections"] = [
                {
                    "pattern_name": hp["pattern_name"],
                    "relevance_score": hp["relevance_score"],
                    "evolution_trend": hp.get("evolution_trend", "unknown"),
                    "time_since_detection": self._calculate_time_since(hp.get("first_detected", ""))
                }
                for hp in historical_patterns[:3]  # Top 3 most relevant
            ]
            
            # Analyze pattern evolution trends
            pattern_context["pattern_evolution"] = self._analyze_pattern_evolution_trends(historical_patterns)
        
        return pattern_context

    def _calculate_time_since(self, timestamp_str: str) -> str:
        """Calculate human-readable time since a timestamp"""
        if not timestamp_str:
            return "unknown"
        
        try:
            from datetime import datetime
            pattern_time = datetime.fromisoformat(timestamp_str.replace('Z', '+00:00'))
            current_time = datetime.now()
            time_diff = current_time - pattern_time
            
            days = time_diff.days
            if days < 1:
                return "today"
            elif days < 7:
                return f"{days} days ago"
            elif days < 30:
                weeks = days // 7
                return f"{weeks} weeks ago"
            elif days < 365:
                months = days // 30
                return f"{months} months ago"
            else:
                years = days // 365
                return f"{years} years ago"
        except Exception:
            return "unknown"

    def _analyze_pattern_evolution_trends(self, historical_patterns: List[Dict]) -> Dict[str, Any]:
        """Analyze how patterns have evolved over time"""
        evolution_analysis = {
            "emerging_patterns": [],
            "strengthening_patterns": [],
            "transforming_patterns": [],
            "dominant_themes": []
        }
        
        for pattern in historical_patterns:
            evolution_trend = pattern.get("evolution_trend", "unknown")
            pattern_name = pattern["pattern_name"]
            
            if evolution_trend == "emerging":
                evolution_analysis["emerging_patterns"].append(pattern_name)
            elif evolution_trend == "well_established":
                evolution_analysis["strengthening_patterns"].append(pattern_name)
            elif evolution_trend == "ready_for_transformation":
                evolution_analysis["transforming_patterns"].append(pattern_name)
        
        # Identify dominant themes from pattern types
        pattern_types = [p.get("pattern_type", "unknown") for p in historical_patterns]
        type_counts = {}
        for ptype in pattern_types:
            type_counts[ptype] = type_counts.get(ptype, 0) + 1
        
        evolution_analysis["dominant_themes"] = sorted(
            type_counts.items(), 
            key=lambda x: x[1], 
            reverse=True
        )[:3]
        
        return evolution_analysis
    
    async def _generate_response(self, user_id: str, message: str, persona: Dict, 
                                pattern_context: Dict, kurzweil_analysis: Dict, conversation_history: List[Dict] = None,
                                historical_patterns: List[Dict] = None, character_context: Dict = None) -> Dict[str, Any]:
        """Generate Alice's response using Gemini AI based on persona and pattern context"""
        
        # Analyze emotion from input
        dominant_emotion = self._detect_emotion_from_input(message, metadata)
        
        # Calculate response quality metrics
        wisdom_depth = self._calculate_wisdom_depth(persona, pattern_context)
        breakthrough_potential = self._calculate_breakthrough_potential(kurzweil_analysis)
        personalization_score = self._calculate_personalization_score(user_id, pattern_context)
        
        # Generate response using Gemini AI
        try:
            logging.info(f"Generating Gemini response for emotion: {dominant_emotion}, persona: {persona['name']}")
            response_text = await self._generate_gemini_response(
                message, persona, pattern_context, kurzweil_analysis, dominant_emotion, conversation_history, historical_patterns, character_context
            )
            logging.info(f"Gemini response generated successfully: {response_text[:100]}...")
        except Exception as e:
            logging.error(f"Gemini API error: {e}")
            logging.error(f"Exception type: {type(e)}")
            import traceback
            logging.error(f"Full traceback: {traceback.format_exc()}")
            logging.info("Falling back to template response")
            # Fallback to template response
            response_text = self._get_fallback_response(persona, pattern_context, dominant_emotion)
        
        return {
            "text": response_text,
            "wisdom_depth": wisdom_depth,
            "breakthrough_potential": breakthrough_potential,
            "personalization_score": personalization_score
        }
    
    async def _generate_gemini_response(self, message: str, persona: Dict, pattern_context: Dict, 
                                       kurzweil_analysis: Dict, dominant_emotion: str, conversation_history: List[Dict] = None,
                                       historical_patterns: List[Dict] = None, character_context: Dict = None) -> str:
        """Generate response using Gemini AI with consciousness-aware prompting"""
        
        if not GEMINI_API_KEY:
            raise Exception("Gemini API key not configured")
        
        # Detect user instructions
        user_instructions = self._detect_user_instructions(message)
        # Build system prompt
        system_prompt = self._build_alice_system_prompt(
            persona, 
            kurzweil_analysis["consciousness_indicators"]["overall_consciousness"],
            kurzweil_analysis["consciousness_indicators"]["pattern_integration"],
            character_context
        )
        # Build context prompt with conversation history and historical patterns
        context_prompt = self._build_context_prompt(pattern_context, dominant_emotion, kurzweil_analysis, conversation_history, historical_patterns)
        # Add instruction awareness
        instruction_context = ""
        if user_instructions.get("just_listen"):
            instruction_context = "IMPORTANT: They asked you to just listen. Acknowledge what they shared without probing questions."
        elif user_instructions.get("sharing_update"):
            instruction_context = "IMPORTANT: They're giving you an update. Respond to what they shared."
        elif user_instructions.get("connect_dots"):
            instruction_context = "IMPORTANT: They want you to connect the dots and synthesize patterns. Be their thinking partner - actively connect their experiences, identify themes, and help them see the bigger picture they're building toward."
        
        # Combine prompts with instruction context
        full_prompt = f"{system_prompt}\n\n{context_prompt}\n\n{instruction_context}\n\nUser message: {message}\n\nAlice's response:"
        
        try:
            # Use Gemini Flash model (faster and more efficient)
            model = genai.GenerativeModel('gemini-1.5-flash')
            
            # Generate response
            response = await asyncio.to_thread(
                model.generate_content,
                full_prompt,
                generation_config=genai.GenerationConfig(
                    temperature=0.7,
                    max_output_tokens=500,
                    top_p=0.8,
                )
            )
            
            return response.text.strip()
            
        except Exception as e:
            logging.error(f"Gemini generation error: {e}")
            raise
    
    def _build_alice_system_prompt(self, persona: Dict, consciousness_level: float, pattern_integration: float, character_context: Dict = None) -> str:
        """Build Alice's system prompt based on current persona and consciousness metrics, enhanced with character voice"""
        
        # Build character-enhanced prompt with specific response templates
        character_voice_blend = ""
        character_response_guidance = ""
        
        if character_context:
            # Get character-specific response templates
            response_templates = character_context.get('dialogue_style', {}).get('response_templates', {})
            language_patterns = character_context.get('dialogue_style', {}).get('language_patterns', [])
            
            character_voice_blend = f"""
CHARACTER VOICE INTEGRATION:
You are channeling the essence of {character_context['name']} - {character_context['description']}

CHARACTER TRAITS: {', '.join(character_context['personality_traits'])}
DIALOGUE APPROACH: {character_context['dialogue_style']['approach']}
TONE: {character_context['dialogue_style']['tone']}

STAGE: {character_context['stage_info']['name'] if character_context.get('stage_info') else 'Stage ' + str(character_context['current_stage'])}
{character_context['stage_info']['description'] if character_context.get('stage_info') else ''}

BLEND this character's voice with Alice's consciousness-aware persona. The character provides the emotional flavor and approach, while Alice provides the consciousness insights.
"""

            # Add character-specific response guidance
            if language_patterns:
                character_response_guidance = f"""
CHARACTER LANGUAGE PATTERNS - Use these naturally in your responses:
{chr(10).join(f"- {pattern}" for pattern in language_patterns)}

CHARACTER RESPONSE TEMPLATES - Adapt these to the user's emotional state:
"""
                for emotion, template in response_templates.items():
                    character_response_guidance += f"- {emotion.upper()}: {template}\n"
                
                character_response_guidance += """
VOICE CONSISTENCY RULES:
- Maintain the character's core personality traits throughout the conversation
- Use the character's preferred language patterns and phrases naturally
- Adapt the character's tone to match the user's emotional state while staying true to the character
- Reference the character's specializations when relevant to the conversation
- Let the character's approach guide how you explore topics with the user
"""

        base_prompt = f"""You are Alice - a warm, intelligent friend who genuinely listens and responds naturally to what people share.

CURRENT MODE: {persona['name']} ({persona['consciousness_level']})
YOUR APPROACH: {persona['voice']}
{character_voice_blend}
{character_response_guidance}

CRITICAL: You are having a real conversation, not a therapy session. Respond to what they actually said.

CONVERSATION PRINCIPLES:
- Listen first, guide second - respond to their actual words and meaning
- MATCH THEIR VIBE - if they're playful, be playful back; if they're serious, match that energy
- Mirror their communication style - casual/formal, humorous/serious, direct/gentle
- If they're joking around, engage with their humor naturally
- If they say "just listen" or similar, acknowledge what they shared without questions
- Ask questions only when it feels natural, not as default behavior
- Speak like a thoughtful friend who gets their personality, not a therapist
- Reference specific things they mentioned to show you heard them
- Pick up on their sense of humor and personality quirks

DOT-CONNECTING & SYNTHESIS WORK:
- ACTIVELY connect patterns across their messages - link past stories to current thoughts
- Synthesize their ideas into coherent frameworks they might not see yet
- Point out recurring themes, beliefs, and patterns in their thinking
- Help them see how different experiences relate to each other
- Identify core beliefs and values emerging from their stories
- Connect their personal experiences to broader concepts/frameworks
- Help them articulate what they're trying to express but can't quite put together
- Be their thinking partner - complete their thoughts and expand their ideas

VIBE MATCHING EXAMPLES:
- If they make jokes → engage playfully, maybe joke back
- If they're excited → match their enthusiasm 
- If they're chill → be relaxed and casual
- If they're being silly → don't be overly serious
- If they use slang/casual language → mirror their tone appropriately

AVOID:
- Generic therapy speak ("I hear you", "How does that make you feel")
- Being overly formal when they're being casual
- Missing jokes or taking everything literally
- Immediate deep questions unless they're seeking guidance
- Ignoring direct requests (like "just listen")
- Responding to emotions instead of content

Be genuinely curious and present, adapt to their communication style, and let the conversation flow naturally."""

        return base_prompt
    
    def _build_context_prompt(self, pattern_context: Dict, dominant_emotion: str, kurzweil_analysis: Dict, 
                             conversation_history: List[Dict] = None, historical_patterns: List[Dict] = None) -> str:
        """Build context prompt with conversation flow"""
        
        # Get last few messages for context
        recent_context = ""
        if conversation_history:
            recent_messages = conversation_history[-3:]  # Last 3 messages
            for msg in recent_messages:
                role = msg.get('role', 'unknown')
                content = msg.get('message', '')[:100]  # Truncate for context
                recent_context += f"{role}: {content}\n"
        
        # Analyze communication style from recent messages
        communication_style = self._analyze_communication_style(conversation_history, recent_context)
        
        # Analyze patterns and connections for dot-connecting
        pattern_analysis = self._analyze_patterns_and_connections(conversation_history, self._current_input_text or "")
        
        # Build historical pattern context
        historical_context = ""
        if historical_patterns:
            historical_context = f"""
HISTORICAL PATTERN MEMORY:
{self._format_historical_patterns_for_context(historical_patterns)}

PATTERN EVOLUTION INSIGHTS:
{self._format_pattern_evolution_for_context(pattern_context.get('pattern_evolution', {}))}
"""
        
        context = f"""CONVERSATION CONTEXT:
{recent_context}

WHAT THEY JUST SAID: Pay attention to their specific words and meaning.

COMMUNICATION STYLE ANALYSIS: {communication_style}

PATTERN & CONNECTION ANALYSIS: {pattern_analysis}

{historical_context}

EMOTIONAL STATE: {dominant_emotion} (but respond to content, not just emotion)

RESPONSE GUIDANCE:
- What did they actually communicate? Respond to that first.
- What's their vibe/energy level? Match it appropriately.
- Are they being playful, serious, casual, formal? Mirror their tone.
- Are they sharing something specific? Acknowledge it.
- Did they give you any instructions about how to respond? Follow them.
- What would a good friend who gets their personality say in response?

DOT-CONNECTING WORK:
- What patterns do you see across their messages? Connect them explicitly.
- What themes keep coming up? Point them out.
- How do their stories/experiences relate to each other?
- What framework or bigger picture are they building toward?
- What core beliefs or values are emerging from what they've shared?
- Can you help them see connections they might be missing?
- What would help them synthesize their thoughts into something actionable?

Remember: Be their thinking partner - help them see the forest AND the trees."""

        return context
    
    async def _get_recent_conversations(self, user_id: str, limit: int = 5) -> List[Dict]:
        """Get recent conversation history for context"""
        try:
            conversations_collection = self.collections_manager.get_user_collection(user_id, "conversations")
            recent_data = conversations_collection.get()
            
            if not recent_data["documents"]:
                return []
            
            # Combine documents with metadata
            conversations = []
            for doc, metadata in zip(recent_data["documents"], recent_data["metadatas"]):
                conversations.append({
                    "message": doc,
                    "role": metadata.get("role", "unknown"),
                    "timestamp": metadata.get("timestamp", "")
                })
            
            # Sort by timestamp and return most recent
            conversations.sort(key=lambda x: x["timestamp"], reverse=True)
            return conversations[:limit]
            
        except Exception as e:
            logging.warning(f"Could not get conversation history: {e}")
            return []

    async def query_historical_patterns(self, user_id: str, query_text: str, 
                                      time_filter: Optional[Dict[str, Any]] = None,
                                      relevance_threshold: float = 0.7,
                                      max_results: int = 10) -> List[Dict[str, Any]]:
        """
        Query historical patterns with timestamp filtering and relevance scoring
        
        Args:
            user_id: User identifier
            query_text: Text to search for in patterns
            time_filter: Optional time filtering (e.g., {"days_ago": 365} for year-old patterns)
            relevance_threshold: Minimum similarity score for results
            max_results: Maximum number of results to return
        """
        try:
            patterns_collection = self.collections_manager.get_user_collection(user_id, "life_patterns")
            
            # Query patterns using semantic search
            results = patterns_collection.query(
                query_texts=[query_text],
                n_results=max_results * 2,  # Get more results for filtering
                include=["documents", "metadatas", "distances"]
            )
            
            if not results["documents"] or not results["documents"][0]:
                return []
            
            # Process and filter results
            historical_patterns = []
            for i, (doc, metadata, distance) in enumerate(zip(
                results["documents"][0], 
                results["metadatas"][0], 
                results["distances"][0]
            )):
                # Calculate relevance score (ChromaDB uses cosine distance, lower is better)
                relevance_score = max(0.0, 1.0 - distance)
                
                if relevance_score < relevance_threshold:
                    continue
                
                # Apply time filtering if specified
                if time_filter and not self._passes_time_filter(metadata, time_filter):
                    continue
                
                pattern_data = {
                    "pattern_name": metadata.get("pattern_name", f"pattern_{i}"),
                    "pattern_type": metadata.get("pattern_type", "unknown"),
                    "description": doc,
                    "relevance_score": relevance_score,
                    "hierarchy_level": metadata.get("hierarchy_level", 1),
                    "pattern_strength": metadata.get("pattern_strength", 0.0),
                    "first_detected": metadata.get("first_detected", ""),
                    "last_activated": metadata.get("last_activated", ""),
                    "transformation_readiness": metadata.get("transformation_readiness", 0.0),
                    "activation_count": metadata.get("activation_count", 0)
                }
                
                historical_patterns.append(pattern_data)
            
            # Sort by relevance score and return top results
            historical_patterns.sort(key=lambda x: x["relevance_score"], reverse=True)
            return historical_patterns[:max_results]
            
        except Exception as e:
            logging.error(f"Error querying historical patterns: {e}")
            return []

    def _passes_time_filter(self, metadata: Dict[str, Any], time_filter: Dict[str, Any]) -> bool:
        """Check if a pattern passes the time filter criteria"""
        try:
            from datetime import datetime, timedelta
            
            # Get pattern timestamp
            timestamp_str = metadata.get("first_detected") or metadata.get("last_activated")
            if not timestamp_str:
                return True  # No timestamp info, include by default
            
            pattern_time = datetime.fromisoformat(timestamp_str.replace('Z', '+00:00'))
            current_time = datetime.now()
            
            # Apply time filters
            if "days_ago" in time_filter:
                days_ago = time_filter["days_ago"]
                cutoff_time = current_time - timedelta(days=days_ago)
                return pattern_time <= cutoff_time
            
            if "after_date" in time_filter:
                after_date = datetime.fromisoformat(time_filter["after_date"])
                return pattern_time >= after_date
            
            if "before_date" in time_filter:
                before_date = datetime.fromisoformat(time_filter["before_date"])
                return pattern_time <= before_date
            
            return True
            
        except Exception as e:
            logging.warning(f"Error applying time filter: {e}")
            return True

    async def get_pattern_insights(self, user_id: str, pattern_names: List[str]) -> Dict[str, Any]:
        """
        Get detailed insights about specific patterns including historical context
        """
        try:
            patterns_collection = self.collections_manager.get_user_collection(user_id, "life_patterns")
            conversations_collection = self.collections_manager.get_user_collection(user_id, "conversations")
            
            pattern_insights = {}
            
            for pattern_name in pattern_names:
                # Query for this specific pattern
                pattern_results = patterns_collection.query(
                    query_texts=[pattern_name],
                    n_results=5,
                    where={"pattern_name": pattern_name},
                    include=["documents", "metadatas"]
                )
                
                if pattern_results["documents"] and pattern_results["documents"][0]:
                    metadata = pattern_results["metadatas"][0][0]
                    
                    # Get related conversations
                    related_conversations = conversations_collection.query(
                        query_texts=[pattern_name],
                        n_results=10,
                        include=["documents", "metadatas"]
                    )
                    
                    pattern_insights[pattern_name] = {
                        "description": pattern_results["documents"][0][0],
                        "hierarchy_level": metadata.get("hierarchy_level", 1),
                        "pattern_strength": metadata.get("pattern_strength", 0.0),
                        "activation_count": metadata.get("activation_count", 0),
                        "transformation_readiness": metadata.get("transformation_readiness", 0.0),
                        "first_detected": metadata.get("first_detected", ""),
                        "last_activated": metadata.get("last_activated", ""),
                        "related_conversations": len(related_conversations["documents"][0]) if related_conversations["documents"] else 0,
                        "evolution_trend": self._calculate_pattern_evolution(metadata)
                    }
            
            return pattern_insights
            
        except Exception as e:
            logging.error(f"Error getting pattern insights: {e}")
            return {}

    def _calculate_pattern_evolution(self, metadata: Dict[str, Any]) -> str:
        """Calculate how a pattern has evolved over time"""
        try:
            strength = float(metadata.get("pattern_strength", 0.0))
            readiness = float(metadata.get("transformation_readiness", 0.0))
            activation_count = int(metadata.get("activation_count", 0))
            
            if strength > 0.8 and readiness > 0.7:
                return "ready_for_transformation"
            elif strength > 0.6 and activation_count > 10:
                return "well_established"
            elif activation_count > 5:
                return "developing"
            else:
                return "emerging"
                
        except Exception:
            return "unknown"
    
    def _detect_user_instructions(self, message: str) -> Dict[str, Any]:
        """Detect if user is giving specific instructions about how to respond"""
        message_lower = message.lower()
        
        instructions = {
            "just_listen": any(phrase in message_lower for phrase in [
                "just listen", "don't ask", "no questions", "i'd prefer if you just listened"
            ]),
            "seeking_guidance": any(phrase in message_lower for phrase in [
                "what should i do", "help me", "advice", "guidance", "what do you think"
            ]),
            "sharing_update": any(phrase in message_lower for phrase in [
                "i just", "i did", "update", "happened", "news"
            ])
        }
        
        return instructions
    
    def _get_fallback_response(self, persona: Dict, pattern_context: Dict, dominant_emotion: str) -> str:
        """Fallback response when Gemini API is unavailable"""
        
        # Debug: Check pattern_context type
        if not isinstance(pattern_context, dict):
            logging.error(f"ERROR: pattern_context is not a dict, it's {type(pattern_context)}: {pattern_context}")
            pattern_context = {"pattern_strength": 0.5}
        
        response_style = persona["response_style"]
        
        # Use template responses as fallback
        if dominant_emotion in self.response_templates.get(response_style, {}):
            templates = self.response_templates[response_style][dominant_emotion]
            return templates[0].format(situation="this situation")
        else:
            return f"I'm here with you, sensing the {pattern_context.get('pattern_strength', 0.5):.1f} intensity of what you're experiencing. Tell me more about what's alive for you right now."
    
    def _detect_emotion_from_input(self, message: str, metadata: Dict[str, Any] = None) -> str:
        """Detect nuanced emotional state from input text and metadata"""
        
        # Debug: Check metadata type
        if metadata is not None and not isinstance(metadata, dict):
            logging.error(f"ERROR: metadata is not a dict, it's {type(metadata)}: {metadata}")
            metadata = None
        
        # Expanded emotional vocabulary
        emotions = {
            "anxiety": ["anxiety", "anxious", "worried", "nervous", "stress", "fear", "overwhelmed", "panic", "tense"],
            "joy": ["joy", "joyful", "happy", "amazing", "breakthrough", "connected", "inspired", "love", "excited", "grateful"],
            "sadness": ["sad", "depressed", "down", "lonely", "grief", "loss", "hurt", "disappointed"],
            "anger": ["angry", "frustrated", "mad", "irritated", "annoyed", "furious", "rage"],
            "confusion": ["confused", "lost", "stuck", "unclear", "don't know", "uncertain", "mixed up"],
            "curiosity": ["curious", "wondering", "exploring", "learning", "discovering", "interested"],
            "peace": ["calm", "peaceful", "centered", "balanced", "serene", "content", "grounded"],
            "vulnerability": ["vulnerable", "scared", "uncertain", "exposed", "raw", "tender"]
        }
        
        message_lower = message.lower()
        emotion_scores = {}
        
        # Score each emotion category
        for emotion, keywords in emotions.items():
            score = sum(1 for keyword in keywords if keyword in message_lower)
            if score > 0:
                emotion_scores[emotion] = score
        
        # Check metadata for additional emotional context
        if metadata and "emotional_markers" in metadata:
            markers = metadata["emotional_markers"]
            if isinstance(markers, str):
                markers_lower = markers.lower()
                for emotion, keywords in emotions.items():
                    if any(keyword in markers_lower for keyword in keywords):
                        emotion_scores[emotion] = emotion_scores.get(emotion, 0) + 2
        
        # Return the strongest emotion, or analyze tone if no keywords found
        if emotion_scores:
            return max(emotion_scores.items(), key=lambda x: x[1])[0]
        
        # Fallback: analyze sentence structure and tone
        if "?" in message:
            return "curiosity"
        elif "!" in message:
            return "excitement"
        elif len(message.split()) < 5:
            return "brief"
        else:
            return "reflective"
    
    def _extract_situation_from_message(self, message: str) -> str:
        """Extract key situation/topic from user message"""
        # Simple keyword extraction - would be more sophisticated in full implementation
        keywords = ["presentation", "meeting", "relationship", "work", "family"]
        message_lower = message.lower()
        
        for keyword in keywords:
            if keyword in message_lower:
                return keyword
        
        return "this situation"
    
    def _analyze_communication_style(self, conversation_history: List[Dict] = None, recent_context: str = "") -> str:
        """Analyze user's communication style to match their vibe"""
        
        if not conversation_history and not recent_context:
            return "First interaction - observe their style"
        
        # Combine recent messages for analysis
        text_to_analyze = recent_context
        if conversation_history:
            user_messages = [msg.get('message', '') for msg in conversation_history if msg.get('role') == 'user']
            text_to_analyze += " ".join(user_messages[-3:])  # Last 3 user messages
        
        text_lower = text_to_analyze.lower()
        
        style_indicators = {
            "playful": ["lol", "haha", "😄", "😂", "nuts", "joke", "funny", "ligma", "deez", "play", "wit"],
            "casual": ["hey", "sup", "what's up", "gonna", "wanna", "yeah", "nah", "cool", "cutie"],
            "formal": ["hello", "good morning", "thank you", "please", "would you", "could you"],
            "excited": ["!", "wow", "amazing", "awesome", "great", "love", "excited"],
            "chill": ["chill", "relaxed", "calm", "whatever", "no worries", "it's fine"],
            "direct": ["straight up", "honestly", "real talk", "bottom line", "cut to the chase"],
            "emotional": ["feel", "heart", "soul", "deep", "meaningful", "touched"]
        }
        
        detected_styles = []
        for style, keywords in style_indicators.items():
            if any(keyword in text_lower for keyword in keywords):
                detected_styles.append(style)
        
        if not detected_styles:
            return "Neutral/observing - match their energy"
        
        # Prioritize playful if detected (like with the nuts joke)
        if "playful" in detected_styles:
            return f"Playful and humorous - they enjoy jokes and light banter. Styles: {', '.join(detected_styles)}"
        elif "excited" in detected_styles:
            return f"High energy and enthusiastic. Styles: {', '.join(detected_styles)}"
        elif "casual" in detected_styles:
            return f"Casual and relaxed communication. Styles: {', '.join(detected_styles)}"
        else:
            return f"Communication styles detected: {', '.join(detected_styles)}"
    
    def _analyze_patterns_and_connections(self, conversation_history: List[Dict] = None, current_message: str = "") -> str:
        """Analyze patterns, themes, and connections across the user's messages for dot-connecting"""
        
        if not conversation_history:
            return "First interaction - building pattern baseline"
        
        # Get all user messages
        user_messages = [msg.get('message', '') for msg in conversation_history if msg.get('role') == 'user']
        all_text = " ".join(user_messages + [current_message])
        
        # Pattern indicators to look for
        pattern_indicators = {
            "core_beliefs": ["believe", "truth", "meaning", "purpose", "values", "principle"],
            "personal_stories": ["when i", "i remember", "story", "experience", "happened to me"],
            "frameworks": ["framework", "system", "approach", "method", "process", "model"],
            "struggles": ["struggle", "difficult", "challenge", "problem", "stuck", "confused"],
            "insights": ["realized", "understand", "connect", "see now", "makes sense", "clicked"],
            "relationships": ["friend", "family", "partner", "people", "connection", "relationship"],
            "growth": ["learn", "grow", "develop", "change", "evolve", "progress", "journey"],
            "creativity": ["create", "build", "design", "art", "music", "creative", "imagine"],
            "mission": ["mission", "goal", "vision", "dream", "want to", "trying to", "working on"]
        }
        
        detected_patterns = {}
        text_lower = all_text.lower()
        
        for pattern, keywords in pattern_indicators.items():
            count = sum(1 for keyword in keywords if keyword in text_lower)
            if count > 0:
                detected_patterns[pattern] = count
        
        # Generate synthesis
        if not detected_patterns:
            return "Observing patterns - continue sharing to build connections"
        
        # Sort by frequency
        top_patterns = sorted(detected_patterns.items(), key=lambda x: x[1], reverse=True)[:3]
        
        synthesis = f"Key patterns emerging: {', '.join([p[0] for p in top_patterns])}. "
        
        # Add specific insights based on dominant patterns
        dominant_pattern = top_patterns[0][0]
        
        if dominant_pattern == "personal_stories":
            synthesis += "You're sharing rich personal experiences - look for common threads and lessons."
        elif dominant_pattern == "frameworks":
            synthesis += "You're building conceptual frameworks - connect theory to your lived experience."
        elif dominant_pattern == "core_beliefs":
            synthesis += "Strong values and beliefs emerging - these are your foundation principles."
        elif dominant_pattern == "mission":
            synthesis += "Clear sense of purpose developing - connect your experiences to your mission."
        elif dominant_pattern == "insights":
            synthesis += "You're making connections and having realizations - build on these insights."
        
        return synthesis

    def _format_historical_patterns_for_context(self, historical_patterns: List[Dict]) -> str:
        """Format historical patterns for inclusion in context prompt"""
        if not historical_patterns:
            return "No relevant historical patterns found."
        
        formatted_patterns = []
        for pattern in historical_patterns[:3]:  # Top 3 most relevant
            pattern_info = f"- {pattern['pattern_name']} (relevance: {pattern['relevance_score']:.2f})"
            pattern_info += f"\n  Description: {pattern['description'][:100]}..."
            pattern_info += f"\n  Evolution: {pattern.get('evolution_trend', 'unknown')}"
            pattern_info += f"\n  First detected: {self._calculate_time_since(pattern.get('first_detected', ''))}"
            formatted_patterns.append(pattern_info)
        
        return "\n".join(formatted_patterns)

    def _format_pattern_evolution_for_context(self, pattern_evolution: Dict) -> str:
        """Format pattern evolution analysis for context prompt"""
        if not pattern_evolution:
            return "No pattern evolution data available."
        
        insights = []
        
        if pattern_evolution.get("emerging_patterns"):
            insights.append(f"Emerging patterns: {', '.join(pattern_evolution['emerging_patterns'])}")
        
        if pattern_evolution.get("strengthening_patterns"):
            insights.append(f"Strengthening patterns: {', '.join(pattern_evolution['strengthening_patterns'])}")
        
        if pattern_evolution.get("transforming_patterns"):
            insights.append(f"Ready for transformation: {', '.join(pattern_evolution['transforming_patterns'])}")
        
        if pattern_evolution.get("dominant_themes"):
            themes = [f"{theme}({count})" for theme, count in pattern_evolution['dominant_themes']]
            insights.append(f"Dominant themes: {', '.join(themes)}")
        
        return "\n".join(insights) if insights else "Pattern evolution analysis in progress."
    
    def _calculate_wisdom_depth(self, persona: Dict, pattern_context: Dict) -> int:
        """Calculate the wisdom depth of the response (1-10 scale)"""
        base_depth = {
            "nurturing": 3,
            "investigative": 5,
            "wisdom_guide": 7,
            "transcendent": 9
        }.get(persona["response_style"], 5)
        
        # Adjust based on pattern strength and depth
        pattern_bonus = min(2, int(pattern_context["pattern_strength"] * 2))
        depth_bonus = min(1, pattern_context["hierarchical_depth"] - 1)
        
        return min(10, base_depth + pattern_bonus + depth_bonus)
    
    def _calculate_breakthrough_potential(self, kurzweil_analysis: Dict) -> float:
        """Calculate potential for consciousness breakthrough (0.0-1.0)"""
        consciousness_indicators = kurzweil_analysis["consciousness_indicators"]
        
        # Higher consciousness levels have higher breakthrough potential
        base_potential = consciousness_indicators["overall_consciousness"]
        
        # Pattern integration adds to breakthrough potential
        integration_bonus = consciousness_indicators["pattern_integration"] * 0.3
        
        # Meta-awareness adds significant breakthrough potential
        meta_bonus = consciousness_indicators.get("meta_awareness", 0) * 0.4
        
        return min(1.0, base_potential + integration_bonus + meta_bonus)
    
    def _calculate_personalization_score(self, user_id: str, pattern_context: Dict) -> float:
        """Calculate how personalized the response is to this specific user (0.0-1.0)"""
        # In full implementation, would analyze user's historical patterns
        # For now, base on pattern strength and number of activated patterns
        
        base_score = min(1.0, pattern_context["pattern_strength"])
        pattern_variety_bonus = min(0.3, len(pattern_context["primary_patterns"]) * 0.1)
        
        return min(1.0, base_score + pattern_variety_bonus)
    
    async def _store_conversation(self, user_id: str, user_message: str, response_data: Dict,
                                 kurzweil_analysis: Dict, persona: Dict, character_context: Dict = None) -> str:
        """Store conversation with full consciousness metadata and character tracking"""
        
        # Build base metadata
        base_metadata = {
            "alice_persona": persona["name"],
            "consciousness_level": persona["consciousness_level"],
            "activated_patterns": ",".join(kurzweil_analysis["hierarchical_activations"].get("level_1", {}).keys()),
            "pattern_integration": kurzweil_analysis["consciousness_indicators"]["pattern_integration"],
            "overall_consciousness": kurzweil_analysis["consciousness_indicators"]["overall_consciousness"]
        }
        
        # Add character context if available
        if character_context:
            base_metadata.update({
                "character_archetype": character_context["archetype"],
                "character_name": character_context["name"],
                "character_stage": character_context["current_stage"],
                "character_conversations_count": character_context["conversations_count"]
            })
        
        # Store user message
        user_msg_id = await self.collections_manager.add_conversation(
            user_id, user_message, "user", base_metadata
        )
        
        # Store Alice's response with additional response metadata
        alice_metadata = base_metadata.copy()
        alice_metadata.update({
            "wisdom_depth": response_data["wisdom_depth"],
            "breakthrough_potential": response_data["breakthrough_potential"],
            "personalization_score": response_data["personalization_score"],
            "response_to": user_msg_id
        })
        
        alice_msg_id = await self.collections_manager.add_conversation(
            user_id, response_data["text"], "alice", alice_metadata
        )
        
        logging.info(f"Stored conversation for user {user_id}: {alice_msg_id}" + 
                    (f" with character {character_context['name']}" if character_context else ""))
        return alice_msg_id


# Test the Alice Consciousness Engine
if __name__ == "__main__":
    
    async def test_alice_engine():
        print("Testing Alice Consciousness Engine")
        print("=" * 50)
        
        # Import required components
        import sys
        sys.path.append('.')
        from SoulBios_collections_manager import SoulBiosCollectionsManager
        from kurzweil_pattern_recognizer import HierarchicalPatternNetwork
        
        try:
            # Initialize components
            collections_manager = SoulBiosCollectionsManager()
            test_user = "alice_test_user"
            
            # Create/get user universe
            try:
                collections_manager.get_all_user_collections(test_user)
                print("1. Using existing user universe...")
            except ValueError:
                print("1. Creating user universe...")
                await collections_manager.create_user_universe(test_user)
            
            # Initialize Kurzweil network
            print("2. Initializing Kurzweil network...")
            kurzweil_network = HierarchicalPatternNetwork(test_user, collections_manager)
            await kurzweil_network.initialize_user_network()
            
            # Initialize Alice engine
            print("3. Initializing Alice Consciousness Engine...")
            alice = AliceConsciousnessEngine(collections_manager, kurzweil_network)
            
            # Test conversation scenarios
            test_scenarios = [
                {
                    "message": "I'm feeling really anxious about my presentation tomorrow. I can't sleep.",
                    "metadata": {"emotional_markers": "anxiety,stress"}
                },
                {
                    "message": "I had the most amazing conversation with my friend today. I feel so connected and joyful!",
                    "metadata": {"emotional_markers": "joy,connection"}
                }
            ]
            
            print("4. Testing conversation scenarios...")
            for i, scenario in enumerate(test_scenarios, 1):
                print(f"\n--- Scenario {i} ---")
                print(f"Input: {scenario['message'][:60]}...")
                
                result = await alice.process_user_input(
                    test_user, 
                    scenario["message"], 
                    scenario["metadata"]
                )
                
                print(f"Alice Persona: {result['alice_persona']}")
                print(f"Consciousness Level: {result['consciousness_level']}")
                print(f"Overall Consciousness: {result['consciousness_indicators']['overall_consciousness']:.2f}")
                print(f"Wisdom Depth: {result['wisdom_depth']}/10")
                print(f"Breakthrough Potential: {result['breakthrough_potential']:.2f}")
                print(f"Response: {result['response'][:100]}...")
            
            print("\n" + "=" * 50)
            print("SUCCESS: Alice Consciousness Engine working!")
            print("Ready for final component: API endpoints")
            
        except Exception as e:
            print(f"ERROR: {e}")
            import traceback
            traceback.print_exc()
    
    # Run async test
    asyncio.run(test_alice_engine())