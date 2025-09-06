#!/bin/bash

# SoulBios Backend Deployment Script
# Deploys FastAPI backend to AWS EC2 with production configuration

set -e

echo "🚀 Starting SoulBios Backend Deployment..."

# Environment setup
export ENVIRONMENT=staging
export API_HOST=0.0.0.0
export API_PORT=8000
export API_WORKERS=4

# AWS Configuration
export AWS_REGION=us-east-1
export S3_BUCKET=soulbios-staging

# Security
export CORS_ORIGINS="https://soulbios-staging.com,https://localhost:3000"
export SSL_ENABLED=true

# Performance
export MAX_CACHED_USERS=100
export REQUEST_TIMEOUT=30
export LOG_LEVEL=INFO

# Install dependencies
echo "📦 Installing dependencies..."
pip install -r requirements.txt

# Setup ChromaDB directory
echo "🗄️ Setting up ChromaDB..."
mkdir -p ./chroma_db
export CHROMA_DB_PATH=./chroma_db

# Get secrets from AWS Secrets Manager
echo "🔐 Retrieving secrets..."
if command -v aws &> /dev/null; then
    export GEMINI_API_KEY=$(aws secretsmanager get-secret-value \
        --secret-id SoulBios/GeminiKey \
        --query SecretString --output text | jq -r .GEMINI_API_KEY)
    
    export API_KEY=$(aws secretsmanager get-secret-value \
        --secret-id SoulBios/APIKey \
        --query SecretString --output text | jq -r .API_KEY)
    
    export REDIS_PASSWORD=$(aws secretsmanager get-secret-value \
        --secret-id SoulBios/RedisPassword \
        --query SecretString --output text | jq -r .REDIS_PASSWORD)
else
    echo "⚠️ AWS CLI not found, using environment variables"
fi

# Health check
echo "🏥 Running health check..."
python -c "
import sys
sys.path.append('.')
from production_config import config
print(f'Environment: {config.environment}')
print(f'API Host: {config.api_host}:{config.api_port}')
print(f'CORS Origins: {config.cors_origins}')
print(f'Gemini API Key: {\"✅ Set\" if config.gemini_api_key else \"❌ Missing\"}')
"

# Start server
echo "🌟 Starting SoulBios API server..."
if [ "$ENVIRONMENT" = "production" ]; then
    # Production with Gunicorn
    gunicorn soulbios_api:app \
        --workers $API_WORKERS \
        --worker-class uvicorn.workers.UvicornWorker \
        --bind $API_HOST:$API_PORT \
        --timeout $REQUEST_TIMEOUT \
        --access-logfile - \
        --error-logfile -
else
    # Staging with Uvicorn
    uvicorn soulbios_api:app \
        --host $API_HOST \
        --port $API_PORT \
        --workers $API_WORKERS \
        --access-log \
        --log-level info
fi