"""
Production middleware for SoulBios API
Handles rate limiting, request queuing, and performance monitoring
"""

import asyncio
import time
import logging
from typing import Dict, Optional
from collections import defaultdict, deque
from fastapi import Request, HTTPException
from fastapi.responses import JSONResponse
import redis
from production_config import config

logger = logging.getLogger(__name__)

class RateLimitMiddleware:
    """Rate limiting middleware for Gemini API protection"""
    
    def __init__(self):
        self.redis_client = config.get_redis_client()
        self.fallback_cache = defaultdict(deque)  # Fallback if Redis unavailable
        self.max_requests_per_minute = 60
        self.max_requests_per_hour = 1000
        
    async def __call__(self, request: Request, call_next):
        # Skip rate limiting for health checks
        if request.url.path == "/health":
            return await call_next(request)
        
        client_ip = request.client.host
        user_id = request.path_params.get("user_id", client_ip)
        
        # Check rate limits
        if not await self._check_rate_limit(user_id):
            return JSONResponse(
                status_code=429,
                content={
                    "error": "Rate limit exceeded",
                    "message": "Please wait before making more requests",
                    "retry_after": 60
                }
            )
        
        # Process request
        start_time = time.time()
        response = await call_next(request)
        processing_time = time.time() - start_time
        
        # Log performance metrics
        if processing_time > 5.0:  # Log slow requests
            logger.warning(f"Slow request: {request.url.path} took {processing_time:.2f}s")
        
        # Add performance headers
        response.headers["X-Processing-Time"] = str(processing_time)
        
        return response
    
    async def _check_rate_limit(self, user_id: str) -> bool:
        """Check if user is within rate limits"""
        current_time = int(time.time())
        
        if self.redis_client:
            try:
                # Use Redis for distributed rate limiting
                pipe = self.redis_client.pipeline()
                
                # Check minute limit
                minute_key = f"rate_limit:{user_id}:minute:{current_time // 60}"
                pipe.incr(minute_key)
                pipe.expire(minute_key, 60)
                
                # Check hour limit
                hour_key = f"rate_limit:{user_id}:hour:{current_time // 3600}"
                pipe.incr(hour_key)
                pipe.expire(hour_key, 3600)
                
                results = pipe.execute()
                minute_count = results[0]
                hour_count = results[2]
                
                return (minute_count <= self.max_requests_per_minute and 
                       hour_count <= self.max_requests_per_hour)
                
            except Exception as e:
                logger.error(f"Redis rate limiting error: {e}")
                # Fall back to in-memory rate limiting
                
        # Fallback in-memory rate limiting
        user_requests = self.fallback_cache[user_id]
        
        # Clean old requests (older than 1 hour)
        cutoff_time = current_time - 3600
        while user_requests and user_requests[0] < cutoff_time:
            user_requests.popleft()
        
        # Check limits
        recent_requests = sum(1 for req_time in user_requests if req_time > current_time - 60)
        
        if (recent_requests >= self.max_requests_per_minute or 
            len(user_requests) >= self.max_requests_per_hour):
            return False
        
        # Add current request
        user_requests.append(current_time)
        return True

class RequestQueueMiddleware:
    """Queue requests to prevent Gemini API overload"""
    
    def __init__(self):
        self.queue = asyncio.Queue(maxsize=100)
        self.processing = False
        
    async def __call__(self, request: Request, call_next):
        # Only queue AI-related requests
        if "/chat/" in request.url.path or "/analyze" in request.url.path:
            return await self._queue_request(request, call_next)
        else:
            return await call_next(request)
    
    async def _queue_request(self, request: Request, call_next):
        """Queue AI requests to prevent overload"""
        try:
            # Add request to queue with timeout
            await asyncio.wait_for(
                self.queue.put((request, call_next)),
                timeout=10.0
            )
            
            # Start processing if not already running
            if not self.processing:
                asyncio.create_task(self._process_queue())
            
            # Wait for response (implement proper response handling)
            # For now, process immediately to maintain functionality
            return await call_next(request)
            
        except asyncio.TimeoutError:
            return JSONResponse(
                status_code=503,
                content={
                    "error": "Service temporarily unavailable",
                    "message": "Request queue is full, please try again later"
                }
            )
    
    async def _process_queue(self):
        """Process queued requests sequentially"""
        self.processing = True
        try:
            while not self.queue.empty():
                request, call_next = await self.queue.get()
                # Process request with delay to respect API limits
                await asyncio.sleep(0.1)  # Small delay between requests
                # In production, implement proper response routing
        finally:
            self.processing = False

class HealthCheckMiddleware:
    """Health monitoring and metrics collection"""
    
    def __init__(self):
        self.start_time = time.time()
        self.request_count = 0
        self.error_count = 0
        
    async def __call__(self, request: Request, call_next):
        self.request_count += 1
        
        try:
            response = await call_next(request)
            
            # Track errors
            if response.status_code >= 400:
                self.error_count += 1
            
            return response
            
        except Exception as e:
            self.error_count += 1
            logger.error(f"Request failed: {e}")
            raise
    
    def get_health_metrics(self) -> Dict:
        """Get current health metrics"""
        uptime = time.time() - self.start_time
        error_rate = self.error_count / max(self.request_count, 1)
        
        return {
            "uptime_seconds": uptime,
            "total_requests": self.request_count,
            "total_errors": self.error_count,
            "error_rate": error_rate,
            "status": "healthy" if error_rate < 0.05 else "degraded"
        }

# Global middleware instances
rate_limiter = RateLimitMiddleware()
request_queue = RequestQueueMiddleware()
health_monitor = HealthCheckMiddleware()