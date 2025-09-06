# SoulBios V1 - Windows PowerShell Deployment Script
param(
    [Parameter(Mandatory=$true)]
    [string]$ProjectId,
    
    [string]$Region = "us-central1",
    [string]$ServiceName = "soulbios-v1"
)

$ErrorActionPreference = "Stop"

# Load environment variables
$envPath = ".env"
if (Test-Path $envPath) {
    Get-Content $envPath | ForEach-Object {
        if ($_ -match "^([^#][^=]+)=(.*)$") {
            [Environment]::SetEnvironmentVariable($matches[1], $matches[2], "Process")
        }
    }
    Write-Host "✅ Environment variables loaded from .env"
} else {
    Write-Host "❌ .env file not found"
    exit 1
}

$ImageName = "gcr.io/$ProjectId/$ServiceName"

Write-Host "🚀 Starting SoulBios V1 deployment to GCP Cloud Run..." -ForegroundColor Green

# Step 1: Configure GCP
Write-Host "📋 Step 1: Configuring GCP project..." -ForegroundColor Yellow
gcloud config set project $ProjectId
gcloud config set run/region $Region

# Enable APIs
Write-Host "🔧 Enabling required GCP APIs..." -ForegroundColor Yellow
gcloud services enable cloudbuild.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable containerregistry.googleapis.com
gcloud services enable secretmanager.googleapis.com

# Setup Secrets
Write-Host "🔐 Setting up secrets..." -ForegroundColor Yellow

# Create Google API Key secret
$env:GOOGLE_API_KEY | gcloud secrets create google-api-key --replication-policy="automatic" --data-file=-
if ($LASTEXITCODE -ne 0) {
    Write-Host "⚠️ Google API Key secret might already exist, updating..." -ForegroundColor Yellow
    $env:GOOGLE_API_KEY | gcloud secrets versions add google-api-key --data-file=-
}

# Create SoulBios API Key secret  
$env:SOULBIOS_API_KEY | gcloud secrets create soulbios-api-key --replication-policy="automatic" --data-file=-
if ($LASTEXITCODE -ne 0) {
    Write-Host "⚠️ SoulBios API Key secret might already exist, updating..." -ForegroundColor Yellow
    $env:SOULBIOS_API_KEY | gcloud secrets versions add soulbios-api-key --data-file=-
}

# Grant permissions
$projectNumber = (gcloud projects describe $ProjectId --format="value(projectNumber)")
gcloud projects add-iam-policy-binding $ProjectId --member="serviceAccount:$projectNumber-compute@developer.gserviceaccount.com" --role="roles/secretmanager.secretAccessor"

# Step 2: Build image
Write-Host "🏗️ Step 2: Building container image..." -ForegroundColor Yellow
gcloud builds submit --tag $ImageName .

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Container build failed!" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Container image built: $ImageName" -ForegroundColor Green

# Step 3: Deploy to Cloud Run
Write-Host "🚀 Step 3: Deploying to Cloud Run..." -ForegroundColor Yellow
gcloud run deploy $ServiceName `
    --image $ImageName `
    --platform managed `
    --region $Region `
    --allow-unauthenticated `
    --port 8080 `
    --memory 2Gi `
    --cpu 1 `
    --min-instances 0 `
    --max-instances 10 `
    --concurrency 80 `
    --timeout 900 `
    --set-env-vars "ENVIRONMENT=production,REDIS_HOST=localhost,REDIS_PORT=6379" `
    --set-secrets "GOOGLE_API_KEY=google-api-key:latest,SOULBIOS_API_KEY=soulbios-api-key:latest"

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Cloud Run deployment failed!" -ForegroundColor Red
    exit 1
}

# Get service URL
$ServiceUrl = (gcloud run services describe $ServiceName --region=$Region --format="value(status.url)")

Write-Host "🎉 Deployment successful!" -ForegroundColor Green
Write-Host "📱 Service URL: $ServiceUrl" -ForegroundColor Cyan
Write-Host "🔍 Health check: $ServiceUrl/health" -ForegroundColor Cyan
Write-Host "💬 Chat endpoint: $ServiceUrl/chat" -ForegroundColor Cyan
Write-Host "🏛️ Chamber endpoint: $ServiceUrl/chamber/create" -ForegroundColor Cyan

# Test deployment
Write-Host "🧪 Testing deployment..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "$ServiceUrl/health" -UseBasicParsing
    Write-Host "✅ Health check passed: $($response.StatusCode)" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Health check failed: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host "✅ SoulBios V1 deployment complete!" -ForegroundColor Green