#!/usr/bin/env python3
"""
Simple test for Growth Alice Agent functionality
"""
import asyncio
from agents.growth_alice_agent import GrowthAliceAgent
from agents.base_agent import AgentRequest

async def test_growth_alice():
    # Create Growth Alice agent
    growth_alice = GrowthAliceAgent()
    
    # Test normal mode
    from datetime import datetime
    request = AgentRequest(
        user_id="test_user",
        message="How can I grow spiritually?",
        context={},
        timestamp=datetime.now(),
        conversation_id="test_conv"
    )
    
    normal_context = {}
    response, confidence = await growth_alice._process_agent_logic(request, normal_context)
    print(f"Normal mode: {response} (confidence: {confidence})")
    
    # Test chamber mode  
    chamber_context = {'chamber_mode': True}
    chamber_response, chamber_confidence = await growth_alice._process_agent_logic(request, chamber_context)
    print(f"Chamber mode: {chamber_response} (confidence: {chamber_confidence})")

if __name__ == "__main__":
    asyncio.run(test_growth_alice())