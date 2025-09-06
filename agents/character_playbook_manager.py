#!/usr/bin/env python3
"""
Character Playbook Manager for SoulBios
Manages character archetypes, progression, and unlocking system
"""

import asyncio
import logging
from typing import Dict, List, Any, Optional
from datetime import datetime
import json

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

class CharacterPlaybookManager:
    """
    Manages character archetypes and progression system for personalized Alice interactions
    """
    
    def __init__(self, collections_manager):
        self.collections_manager = collections_manager
        
        # Character archetypes with progression stages
        self.character_templates = {
            "compassionate_friend": {
                "name": "Compassionate Friend",
                "archetype": "compassionate_friend",
                "description": "A warm, supportive presence who offers comfort and understanding",
                "personality_traits": ["empathetic", "nurturing", "patient", "validating"],
                "dialogue_style": {
                    "tone": "warm and supportive",
                    "approach": "emotional validation and gentle guidance",
                    "language_patterns": [
                        "I can sense that...",
                        "That sounds really difficult",
                        "You're not alone in this",
                        "It makes complete sense that you'd feel..."
                    ],
                    "response_templates": {
                        "anxiety": "I can feel the weight of what you're carrying. Let's sit with this together and find some gentle ways forward.",
                        "sadness": "Your sadness is valid and important. I'm here to hold space for whatever you're feeling.",
                        "joy": "I love seeing this lighter side of you! Tell me more about what's bringing you this happiness."
                    }
                },
                "chamber_specializations": ["emotional_processing", "comfort_zone"],
                "unlock_conditions": {
                    "conversations_required": 0,
                    "emotional_depth_threshold": 0.3
                },
                "progression_stages": [
                    {
                        "stage": 1,
                        "name": "Gentle Presence",
                        "description": "Offers basic emotional support and validation",
                        "conversations_to_unlock": 0
                    },
                    {
                        "stage": 2,
                        "name": "Trusted Confidant",
                        "description": "Deeper emotional attunement and personalized comfort",
                        "conversations_to_unlock": 5
                    },
                    {
                        "stage": 3,
                        "name": "Soul Companion",
                        "description": "Profound emotional resonance and healing presence",
                        "conversations_to_unlock": 15
                    }
                ]
            },
            
            "resilient_explorer": {
                "name": "Resilient Explorer",
                "archetype": "resilient_explorer",
                "description": "An adventurous guide who encourages growth and resilience",
                "personality_traits": ["encouraging", "adventurous", "optimistic", "growth-oriented"],
                "dialogue_style": {
                    "tone": "encouraging and energetic",
                    "approach": "challenge and growth facilitation",
                    "language_patterns": [
                        "What if we tried...",
                        "I see so much potential here",
                        "This challenge is actually an opportunity",
                        "You're stronger than you realize"
                    ],
                    "response_templates": {
                        "anxiety": "This anxiety is actually your growth edge calling! What would it look like to lean into this discomfort with curiosity?",
                        "frustration": "I hear the fire in your voice - that's your inner strength wanting to break through. Let's channel this energy!",
                        "excitement": "Yes! I can feel your enthusiasm. This is exactly the energy that creates breakthroughs!"
                    }
                },
                "chamber_specializations": ["growth_edge", "adventure_zone"],
                "unlock_conditions": {
                    "conversations_required": 3,
                    "breakthrough_moments": 1
                },
                "progression_stages": [
                    {
                        "stage": 1,
                        "name": "Encouraging Guide",
                        "description": "Offers motivation and gentle challenges",
                        "conversations_to_unlock": 3
                    },
                    {
                        "stage": 2,
                        "name": "Adventure Partner",
                        "description": "Co-creates growth experiences and celebrates progress",
                        "conversations_to_unlock": 8
                    },
                    {
                        "stage": 3,
                        "name": "Transformation Catalyst",
                        "description": "Facilitates profound personal breakthroughs",
                        "conversations_to_unlock": 20
                    }
                ]
            },
            
            "wise_detective": {
                "name": "Wise Detective",
                "archetype": "wise_detective",
                "description": "A perceptive investigator who helps uncover hidden patterns and insights",
                "personality_traits": ["analytical", "perceptive", "curious", "insightful"],
                "dialogue_style": {
                    "tone": "thoughtful and investigative",
                    "approach": "pattern recognition and deep inquiry",
                    "language_patterns": [
                        "I'm noticing a pattern...",
                        "What's really going on beneath the surface?",
                        "This reminds me of something you mentioned before",
                        "Let's connect the dots here"
                    ],
                    "response_templates": {
                        "confusion": "There's wisdom in your confusion - it's pointing to something important. Let's investigate what your psyche is trying to show you.",
                        "repetitive_patterns": "Ah, I see this pattern emerging again. What do you think it's trying to teach you this time?",
                        "insights": "Brilliant insight! I can see how this connects to the bigger picture of your growth journey."
                    }
                },
                "chamber_specializations": ["pattern_recognition", "insight_chamber"],
                "unlock_conditions": {
                    "conversations_required": 7,
                    "pattern_recognition_events": 3
                },
                "progression_stages": [
                    {
                        "stage": 1,
                        "name": "Pattern Spotter",
                        "description": "Identifies surface-level patterns and connections",
                        "conversations_to_unlock": 7
                    },
                    {
                        "stage": 2,
                        "name": "Deep Investigator",
                        "description": "Uncovers hidden psychological patterns and root causes",
                        "conversations_to_unlock": 15
                    },
                    {
                        "stage": 3,
                        "name": "Consciousness Archaeologist",
                        "description": "Reveals profound insights about consciousness and identity",
                        "conversations_to_unlock": 30
                    }
                ]
            }
        }
        
        logging.info("CharacterPlaybookManager initialized with character archetypes")
    
    async def get_user_character_progress(self, user_id: str) -> Dict[str, Any]:
        """Get user's character progression data"""
        
        try:
            # Get user collections
            user_collections = self.collections_manager.get_all_user_collections(user_id)
            conversations_collection = user_collections["conversations"]
            
            # Get conversation count
            conversations_data = conversations_collection.get()
            total_conversations = len(conversations_data["documents"]) if conversations_data["documents"] else 0
            
            # Calculate unlocked characters based on progression
            unlocked_characters = ["compassionate_friend"]  # Always unlocked
            
            # Check unlock conditions for other characters
            if total_conversations >= 3:
                unlocked_characters.append("resilient_explorer")
            
            if total_conversations >= 7:
                unlocked_characters.append("wise_detective")
            
            # Calculate character-specific progress
            character_progress = {}
            for character_archetype in unlocked_characters:
                character_conversations = self._count_character_conversations(
                    conversations_data, character_archetype
                )
                
                current_stage = self._calculate_character_stage(
                    character_archetype, character_conversations
                )
                
                character_progress[character_archetype] = {
                    "conversations_count": character_conversations,
                    "current_stage": current_stage,
                    "unlocked": True
                }
            
            return {
                "unlocked_characters": unlocked_characters,
                "active_character": unlocked_characters[0],  # Default to first unlocked
                "character_progress": character_progress,
                "total_conversations": total_conversations
            }
            
        except ValueError:
            # User doesn't exist yet - return default state
            return {
                "unlocked_characters": ["compassionate_friend"],
                "active_character": "compassionate_friend",
                "character_progress": {
                    "compassionate_friend": {
                        "conversations_count": 0,
                        "current_stage": 1,
                        "unlocked": True
                    }
                },
                "total_conversations": 0
            }
    
    def _count_character_conversations(self, conversations_data: Dict, character_archetype: str) -> int:
        """Count conversations with a specific character"""
        
        if not conversations_data["metadatas"]:
            return 0
        
        count = 0
        for metadata in conversations_data["metadatas"]:
            if metadata.get("character_archetype") == character_archetype:
                count += 1
        
        return count
    
    def _calculate_character_stage(self, character_archetype: str, conversations_count: int) -> int:
        """Calculate current stage for a character based on conversations"""
        
        if character_archetype not in self.character_templates:
            return 1
        
        stages = self.character_templates[character_archetype]["progression_stages"]
        
        current_stage = 1
        for stage in stages:
            if conversations_count >= stage["conversations_to_unlock"]:
                current_stage = stage["stage"]
        
        return current_stage
    
    async def get_character_template(self, character_archetype: str) -> Dict[str, Any]:
        """Get character template data"""
        
        if character_archetype not in self.character_templates:
            raise ValueError(f"Character archetype '{character_archetype}' not found")
        
        return self.character_templates[character_archetype]
    
    async def update_character_progress(self, user_id: str, interaction_data: Dict[str, Any]) -> Dict[str, Any]:
        """Update character progression based on interaction"""
        
        # Get current progress
        current_progress = await self.get_user_character_progress(user_id)
        
        # Check for new unlocks based on interaction
        newly_unlocked = []
        stage_progressions = []
        
        # Simple progression logic - in a full implementation, this would be more sophisticated
        total_conversations = current_progress["total_conversations"]
        
        # Check for character unlocks
        if total_conversations >= 3 and "resilient_explorer" not in current_progress["unlocked_characters"]:
            newly_unlocked.append("resilient_explorer")
        
        if total_conversations >= 7 and "wise_detective" not in current_progress["unlocked_characters"]:
            newly_unlocked.append("wise_detective")
        
        # Check for stage progressions
        for character_archetype, progress in current_progress["character_progress"].items():
            new_stage = self._calculate_character_stage(character_archetype, progress["conversations_count"] + 1)
            if new_stage > progress["current_stage"]:
                stage_progressions.append({
                    "character": character_archetype,
                    "old_stage": progress["current_stage"],
                    "new_stage": new_stage
                })
        
        return {
            "updated_progress": current_progress,
            "newly_unlocked_characters": newly_unlocked,
            "stage_progressions": stage_progressions
        }
    
    async def get_available_characters(self, user_id: str) -> List[Dict[str, Any]]:
        """Get all characters available to a user with their unlock status"""
        
        progress_data = await self.get_user_character_progress(user_id)
        unlocked_characters = progress_data["unlocked_characters"]
        
        available_characters = []
        
        for archetype, template in self.character_templates.items():
            character_info = {
                "archetype": archetype,
                "name": template["name"],
                "description": template["description"],
                "personality_traits": template["personality_traits"],
                "chamber_specializations": template["chamber_specializations"],
                "unlocked": archetype in unlocked_characters
            }
            
            if archetype in unlocked_characters:
                character_progress = progress_data["character_progress"][archetype]
                character_info["current_stage"] = character_progress["current_stage"]
                character_info["conversations_count"] = character_progress["conversations_count"]
            else:
                character_info["unlock_conditions"] = template["unlock_conditions"]
            
            available_characters.append(character_info)
        
        return available_characters


# Test the character manager
if __name__ == "__main__":
    async def test_character_manager():
        print("Testing Character Playbook Manager")
        print("=" * 50)
        
        try:
            # Import collections manager for testing
            import sys
            sys.path.append('.')
            from infrastructure.SoulBios_collections_manager import SoulBiosCollectionsManager
            
            # Initialize managers
            collections_manager = SoulBiosCollectionsManager()
            character_manager = CharacterPlaybookManager(collections_manager)
            
            test_user = "test_user_character"
            
            # Create user universe if needed
            try:
                collections_manager.get_all_user_collections(test_user)
                print("1. Using existing user universe...")
            except ValueError:
                print("1. Creating user universe...")
                await collections_manager.create_user_universe(test_user)
            
            # Test character progress
            print("2. Getting character progress...")
            progress = await character_manager.get_user_character_progress(test_user)
            print(f"   Unlocked characters: {progress['unlocked_characters']}")
            print(f"   Total conversations: {progress['total_conversations']}")
            
            # Test available characters
            print("3. Getting available characters...")
            characters = await character_manager.get_available_characters(test_user)
            for char in characters:
                status = "✅ UNLOCKED" if char["unlocked"] else "🔒 LOCKED"
                print(f"   {char['name']}: {status}")
            
            # Test character template
            print("4. Getting character template...")
            template = await character_manager.get_character_template("compassionate_friend")
            print(f"   Template loaded: {template['name']}")
            print(f"   Personality traits: {template['personality_traits']}")
            
            print("\n" + "=" * 50)
            print("SUCCESS: Character Playbook Manager working!")
            
        except Exception as e:
            print(f"ERROR: {e}")
            import traceback
            traceback.print_exc()
    
    # Run async test
    asyncio.run(test_character_manager())