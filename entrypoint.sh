#!/bin/bash
# This script runs first in the container to verify the environment
# and then starts the main application.

# Exit immediately if any command fails
set -e

echo "--- [ENTRYPOINT] SCRIPT STARTED ---"

echo "--- [ENTRYPOINT] Verifying Environment Variables (first 5 chars) ---"
# This safely prints the start of each critical variable to confirm it's loaded
# without exposing the full secret in the logs.
echo "GOOGLE_API_KEY: ${GOOGLE_API_KEY:0:5}..."
echo "SOULBIOS_API_KEY: ${SOULBIOS_API_KEY:0:5}..."
echo "DATABASE_URL: ${DATABASE_URL:0:5}..."

echo "--- [ENTRYPOINT] Verifying File Permissions ---"
echo "Listing /app:"
ls -la /app

echo "--- [ENTRYPOINT] Handing over to Uvicorn ---"
# This command starts the application.
# It dynamically uses the PORT variable provided by the environment (like Cloud Run),
# and falls back to port 8000 if it's not set (for local development).
# 'exec' replaces the shell process with the python process, which is a container best practice.
exec python -m uvicorn test_api:app --host 0.0.0.0 --port ${PORT:-8000}