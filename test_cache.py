from agents.base_agent import AgentRequest, AgentResponse, AgentRole, ModelType
from agents.cloud_student_agent import CloudStudentAgent
import asyncio
import datetime

async def test_cache():
    agent = CloudStudentAgent()
    request = AgentRequest(
        user_id="test_user_123",
        message="Test message",
        context={},
        timestamp=datetime.datetime.now(),
        conversation_id="test_conv_001"
    )
    response = await agent.process_request(request)
    print(f"First response: {response.message}")
    cached_response = await agent.process_request(request)
    print(f"Cached response: {cached_response.message}")

if __name__ == "__main__":
    asyncio.run(test_cache())