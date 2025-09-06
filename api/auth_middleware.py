"""
Authentication and Rate Limiting Middleware for SoulBios API
"""
import time
from typing import Dict, Optional
from fastapi import HTTPException, Request, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from config.settings import settings
import redis
from datetime import datetime, timedelta
import logging

logger = logging.getLogger(__name__)

# Initialize Redis for rate limiting
try:
    redis_url = settings.REDIS_URL or 'redis://localhost:6379'
    redis_client = redis.from_url(redis_url, decode_responses=True, socket_connect_timeout=2)
    redis_client.ping()
except Exception as e:
    logger.warning(f"Redis not available for rate limiting: {e}")
    redis_client = None

security = HTTPBearer()

class RateLimiter:
    """Simple rate limiter using Redis"""
    
    def __init__(self, max_requests: int = 100, window_seconds: int = 3600):
        self.max_requests = max_requests
        self.window_seconds = window_seconds
    
    def is_allowed(self, client_id: str) -> bool:
        """Check if client is within rate limits"""
        if not redis_client:
            return True  # Allow if Redis unavailable
        
        current_time = int(time.time())
        window_start = current_time - self.window_seconds
        
        # Clean old entries and count current requests
        pipe = redis_client.pipeline()
        key = f"rate_limit:{client_id}"
        
        # Remove old entries
        pipe.zremrangebyscore(key, 0, window_start)
        # Add current request
        pipe.zadd(key, {str(current_time): current_time})
        # Set expiry
        pipe.expire(key, self.window_seconds)
        # Count current requests
        pipe.zcard(key)
        
        results = pipe.execute()
        current_requests = results[-1]
        
        return current_requests <= self.max_requests

# Global rate limiter instances
# Set a very high limit for the Berghain Challenge simulation
chat_limiter = RateLimiter(max_requests=100000, window_seconds=3600)
chamber_limiter = RateLimiter(max_requests=20, window_seconds=3600)  # 20 sessions/hour

async def verify_api_key(credentials: HTTPAuthorizationCredentials = Depends(security)) -> str:
    """
    Verify API key authentication
    """
    if not credentials:
        raise HTTPException(
            status_code=401,
            detail="Authorization header required"
        )
    
    api_key = credentials.credentials
    
    expected_key = settings.SOULBIOS_API_KEY or "test-key-12345"
    if api_key != expected_key:
        logger.warning(f"Invalid API key attempt from client")
        raise HTTPException(
            status_code=401,
            detail="Invalid API key"
        )
    
    return api_key

async def verify_chat_rate_limit(request: Request, api_key: str = Depends(verify_api_key)) -> str:
    """
    Verify API key and check chat rate limits
    """
    client_id = f"api_key:{api_key}"
    
    if not chat_limiter.is_allowed(client_id):
        raise HTTPException(
            status_code=429,
            detail="Rate limit exceeded. Maximum 100000 requests per hour."
        )
    
    return api_key

async def verify_chamber_rate_limit(request: Request, api_key: str = Depends(verify_api_key)) -> str:
    """
    Verify API key and check chamber rate limits
    """
    client_id = f"api_key:{api_key}"
    
    if not chamber_limiter.is_allowed(client_id):
        raise HTTPException(
            status_code=429,
            detail="Rate limit exceeded. Maximum 20 chamber sessions per hour."
        )
    
    return api_key

async def optional_auth(credentials: Optional[HTTPAuthorizationCredentials] = Depends(HTTPBearer(auto_error=False))) -> Optional[str]:
    """
    Optional authentication for public endpoints like /health
    """
    if not credentials:
        return None
    
    try:
        return await verify_api_key(credentials)
    except HTTPException:
        # This is expected if the key is invalid or not present, so we don't log an error.
        # We just treat it as an unauthenticated request.
        return None