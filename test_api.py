#!/usr/bin/env python3
"""
Minimal test API to verify deployment works
"""
import os
from fastapi import FastAPI

app = FastAPI(title="SoulBios Test API", version="1.0.0")

@app.get("/")
async def root():
    return {"status": "ok", "message": "SoulBios Test API is running"}

@app.get("/health")
async def health():
    return {
        "status": "healthy",
        "environment": os.getenv("ENVIRONMENT", "unknown"),
        "port": os.getenv("PORT", "8080")
    }

if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", 8080))
    uvicorn.run(app, host="0.0.0.0", port=port)