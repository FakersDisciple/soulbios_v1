#!/bin/bash

# ==============================================================================
# SoulBios v1 - The Definitive Deployment Script (v2.3 - FINAL)
# ==============================================================================
# This script contains all fixes. It builds from source and deploys to
# Cloud Run with the correct startup command, secrets, and network config.
# ==============================================================================

set -e

# --- Configuration ---
PROJECT_ID="gen-lang-client-0339702058"
SERVICE_NAME="soulbios-v1"
REGION="us-central1"
VPC_CONNECTOR="soulbios-vpc-connector"
CLOUD_SQL_INSTANCE="gen-lang-client-0339702058:us-central1:soulbios-db-v1"

REDIS_IP="10.170.173.43"
REDIS_PORT="6379"
# --- END OF CONFIGURATION ---

# --- CORRECTED: Construct the Redis URL from the variables above ---
REDIS_URL="redis://${REDIS_IP}:${REDIS_PORT}"

echo "🚀 Starting definitive deployment of '$SERVICE_NAME'..."
echo "Connecting to Redis at: $REDIS_URL"
echo "--------------------------------------------------------------------"

gcloud run deploy "$SERVICE_NAME"   --source .   --project="$PROJECT_ID"   --region="$REGION"   --command="uvicorn"   --args="api.soulbios_api:app,--host,0.0.0.0,--port,8080"   --update-secrets="DATABASE_URL=database-url:latest,GOOGLE_API_KEY=google-api-key:latest,SOULBIOS_API_KEY=soulbios-api-key:latest,GEMINI_API_KEY=gemini-api-key:latest"   --set-env-vars="REDIS_URL=$REDIS_URL"   --add-cloudsql-instances="$CLOUD_SQL_INSTANCE"   --vpc-connector="$VPC_CONNECTOR"   --timeout=20m   --allow-unauthenticated

echo "--------------------------------------------------------------------"
SERVICE_URL=$(gcloud run services describe $SERVICE_NAME --region $REGION --format="value(status.url)")
echo "✅ Deployment successful!"
echo "Service URL: $SERVICE_URL"
echo "🧪 Running a quick health check..."
# The --fail flag makes curl exit with an error if the status is not 200 OK
curl --fail "$SERVICE_URL/health" || (echo "Health check failed." && exit 1)
echo "" # for a newline
echo "✅ SoulBios V1 is LIVE and ready for the player script."

