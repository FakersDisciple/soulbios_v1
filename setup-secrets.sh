#!/bin/bash
# Setup Google Cloud Secrets for SoulBios V1

# Configuration - REPLACE WITH YOUR VALUES
PROJECT_ID="your-gcp-project-id"

# Load environment variables from .env
set -a
source .env
set +a

echo "🔐 Setting up Google Cloud Secrets for SoulBios V1..."

# Enable Secret Manager API
echo "🔧 Enabling Secret Manager API..."
gcloud services enable secretmanager.googleapis.com

# Create secrets from environment variables
echo "📝 Creating secrets..."

# Create Google API Key secret
echo -n "${GOOGLE_API_KEY}" | gcloud secrets create google-api-key \
    --replication-policy="automatic" \
    --data-file=-

if [ $? -eq 0 ]; then
    echo "✅ Google API Key secret created"
else
    echo "⚠️ Google API Key secret might already exist, updating..."
    echo -n "${GOOGLE_API_KEY}" | gcloud secrets versions add google-api-key --data-file=-
fi

# Create SoulBios API Key secret
echo -n "${SOULBIOS_API_KEY}" | gcloud secrets create soulbios-api-key \
    --replication-policy="automatic" \
    --data-file=-

if [ $? -eq 0 ]; then
    echo "✅ SoulBios API Key secret created"
else
    echo "⚠️ SoulBios API Key secret might already exist, updating..."
    echo -n "${SOULBIOS_API_KEY}" | gcloud secrets versions add soulbios-api-key --data-file=-
fi

# Grant Cloud Run service account access to secrets
echo "🔑 Granting Cloud Run access to secrets..."
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member="serviceAccount:$(gcloud projects describe ${PROJECT_ID} --format='value(projectNumber)')-compute@developer.gserviceaccount.com" \
    --role="roles/secretmanager.secretAccessor"

echo "✅ Secrets setup complete!"
echo "🔍 Verify secrets:"
echo "   gcloud secrets list"
echo "   gcloud secrets versions list google-api-key"
echo "   gcloud secrets versions list soulbios-api-key"