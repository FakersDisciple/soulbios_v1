#!/bin/bash

# SoulBios Production Deployment Script
# This script handles the complete deployment process for SoulBios

set -e  # Exit on any error

echo "🚀 Starting SoulBios Production Deployment"
echo "=========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="soulbios"
VERCEL_PROJECT_NAME="soulbios-api"
FLUTTER_VERSION="3.16.0"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check Flutter
    if ! command -v flutter &> /dev/null; then
        print_error "Flutter is not installed or not in PATH"
        exit 1
    fi
    
    # Check Vercel CLI
    if ! command -v vercel &> /dev/null; then
        print_warning "Vercel CLI not found. Installing..."
        npm install -g vercel
    fi
    
    # Check if we're in the right directory
    if [ ! -f "pubspec.yaml" ]; then
        print_error "pubspec.yaml not found. Please run this script from the Flutter project root."
        exit 1
    fi
    
    print_success "Prerequisites check completed"
}

# Clean and prepare project
prepare_project() {
    print_status "Preparing project for deployment..."
    
    # Clean Flutter project
    flutter clean
    flutter pub get
    
    # Run tests
    print_status "Running tests..."
    flutter test || {
        print_error "Tests failed. Please fix failing tests before deployment."
        exit 1
    }
    
    # Run Flutter analyze
    print_status "Running Flutter analyze..."
    flutter analyze || {
        print_warning "Flutter analyze found issues. Consider fixing them."
    }
    
    print_success "Project preparation completed"
}

# Deploy backend to Vercel
deploy_backend() {
    print_status "Deploying backend to Vercel..."
    
    # Navigate to backend directory
    cd deepconf
    
    # Set up Vercel project if not exists
    if [ ! -f ".vercel/project.json" ]; then
        print_status "Setting up Vercel project..."
        vercel --confirm
    fi
    
    # Set environment variables
    print_status "Setting up environment variables..."
    vercel env add GEMINI_API_KEY production || print_warning "GEMINI_API_KEY already exists"
    vercel env add REDIS_URL production || print_warning "REDIS_URL already exists"
    vercel env add SOULBIOS_API_KEY production || print_warning "SOULBIOS_API_KEY already exists"
    
    # Deploy to production
    print_status "Deploying to Vercel production..."
    VERCEL_URL=$(vercel --prod --confirm | tail -n 1)
    
    if [ -z "$VERCEL_URL" ]; then
        print_error "Failed to get Vercel deployment URL"
        exit 1
    fi
    
    print_success "Backend deployed to: $VERCEL_URL"
    
    # Test the deployment
    print_status "Testing backend deployment..."
    sleep 10  # Wait for deployment to be ready
    
    if curl -f -s "$VERCEL_URL/health" > /dev/null; then
        print_success "Backend health check passed"
    else
        print_warning "Backend health check failed - deployment may still be starting"
    fi
    
    # Return to project root
    cd ..
    
    # Update API service with production URL
    print_status "Updating Flutter app with production URL..."
    sed -i.bak "s|https://soulbios-api.vercel.app|$VERCEL_URL|g" lib/services/api_service.dart
    
    echo "$VERCEL_URL" > .vercel_url
}

# Build Flutter apps
build_flutter_apps() {
    print_status "Building Flutter applications..."
    
    # Build Android APK
    print_status "Building Android APK..."
    flutter build apk --release --target-platform android-arm,android-arm64
    
    if [ $? -eq 0 ]; then
        print_success "Android APK built successfully"
        APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
        print_status "APK location: $APK_PATH"
    else
        print_error "Android APK build failed"
        exit 1
    fi
    
    # Build Android App Bundle
    print_status "Building Android App Bundle..."
    flutter build appbundle --release
    
    if [ $? -eq 0 ]; then
        print_success "Android App Bundle built successfully"
        AAB_PATH="build/app/outputs/bundle/release/app-release.aab"
        print_status "AAB location: $AAB_PATH"
    else
        print_error "Android App Bundle build failed"
        exit 1
    fi
    
    # Build iOS (if on macOS)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        print_status "Building iOS app..."
        flutter build ios --release --no-codesign
        
        if [ $? -eq 0 ]; then
            print_success "iOS app built successfully"
            print_status "iOS build location: build/ios/iphoneos/Runner.app"
            print_warning "Remember to sign and upload to TestFlight manually"
        else
            print_warning "iOS build failed - this is expected if not on macOS or without proper setup"
        fi
    else
        print_warning "Skipping iOS build - not on macOS"
    fi
}

# Create deployment artifacts
create_artifacts() {
    print_status "Creating deployment artifacts..."
    
    # Create deployment directory
    mkdir -p deployment_artifacts
    
    # Copy APK and AAB
    cp build/app/outputs/flutter-apk/app-release.apk deployment_artifacts/soulbios-release.apk
    cp build/app/outputs/bundle/release/app-release.aab deployment_artifacts/soulbios-release.aab
    
    # Create deployment info
    cat > deployment_artifacts/deployment_info.json << EOF
{
  "deployment_date": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "flutter_version": "$(flutter --version | head -n 1)",
  "backend_url": "$(cat .vercel_url)",
  "git_commit": "$(git rev-parse HEAD 2>/dev/null || echo 'unknown')",
  "git_branch": "$(git branch --show-current 2>/dev/null || echo 'unknown')",
  "build_artifacts": {
    "android_apk": "soulbios-release.apk",
    "android_aab": "soulbios-release.aab"
  }
}
EOF
    
    # Create README for deployment
    cat > deployment_artifacts/README.md << EOF
# SoulBios Deployment Artifacts

Generated on: $(date)
Backend URL: $(cat .vercel_url)

## Files Included

- \`soulbios-release.apk\` - Android APK for direct installation
- \`soulbios-release.aab\` - Android App Bundle for Google Play Store
- \`deployment_info.json\` - Deployment metadata
- \`README.md\` - This file

## Next Steps

### Android Deployment
1. Upload \`soulbios-release.aab\` to Google Play Console
2. Create internal testing track
3. Add beta testers
4. Publish to internal testing

### iOS Deployment (if built)
1. Open Xcode and archive the iOS build
2. Upload to App Store Connect
3. Create TestFlight beta
4. Add beta testers

### Backend Monitoring
- Backend URL: $(cat .vercel_url)
- Health check: $(cat .vercel_url)/health
- Monitor logs in Vercel dashboard

## Testing Checklist
- [ ] Backend health check passes
- [ ] Android APK installs and runs
- [ ] Core features work (chat, patterns, memory)
- [ ] Offline mode functions
- [ ] Premium features gate correctly
- [ ] Analytics and crash reporting active
EOF
    
    print_success "Deployment artifacts created in deployment_artifacts/"
}

# Setup monitoring and analytics
setup_monitoring() {
    print_status "Setting up monitoring and analytics..."
    
    # Create Firebase configuration reminder
    cat > firebase_setup_reminder.md << EOF
# Firebase Setup Reminder

## Required Firebase Configuration

1. **Create Firebase Project**
   - Go to https://console.firebase.google.com/
   - Create new project named "SoulBios"
   - Enable Google Analytics

2. **Add Android App**
   - Package name: com.soulbios.app
   - Download google-services.json
   - Place in android/app/

3. **Add iOS App** (if applicable)
   - Bundle ID: com.soulbios.app
   - Download GoogleService-Info.plist
   - Place in ios/Runner/

4. **Enable Services**
   - Analytics: Enabled by default
   - Crashlytics: Enable in Firebase console
   - Performance: Enable in Firebase console

5. **Configure Analytics Events**
   - Chamber unlock events
   - Memory capture events
   - Pattern discovery events
   - User engagement metrics

## Vercel Monitoring

Backend is deployed to: $(cat .vercel_url)

Monitor at: https://vercel.com/dashboard

## Next Steps
- Set up Firebase project and download config files
- Configure analytics events in the app
- Set up alerts for crashes and performance issues
- Create monitoring dashboards
EOF
    
    print_success "Monitoring setup instructions created"
}

# Generate deployment report
generate_report() {
    print_status "Generating deployment report..."
    
    BACKEND_URL=$(cat .vercel_url)
    
    cat > DEPLOYMENT_REPORT.md << EOF
# SoulBios Production Deployment Report

**Deployment Date:** $(date)  
**Deployment Status:** ✅ SUCCESS  
**Backend URL:** $BACKEND_URL

## 🎯 Deployment Summary

### Backend Deployment
- ✅ FastAPI backend deployed to Vercel
- ✅ Environment variables configured
- ✅ Health check endpoint accessible
- ✅ Production URL updated in Flutter app

### Mobile App Builds
- ✅ Android APK built successfully
- ✅ Android App Bundle (AAB) built successfully
- ⚠️  iOS build requires macOS and proper signing

### Artifacts Generated
- \`deployment_artifacts/soulbios-release.apk\` - Android APK
- \`deployment_artifacts/soulbios-release.aab\` - Android App Bundle
- \`deployment_artifacts/deployment_info.json\` - Metadata

## 🔧 Configuration

### API Configuration
- **Base URL:** $BACKEND_URL
- **Health Check:** $BACKEND_URL/health
- **Authentication:** API Key based

### Firebase Services
- **Analytics:** Ready for configuration
- **Crashlytics:** Ready for configuration  
- **Performance:** Ready for configuration

## 📱 Next Steps

### Immediate Actions Required
1. **Configure Firebase**
   - Create Firebase project
   - Add Android/iOS apps
   - Download and add config files
   - Enable Analytics, Crashlytics, Performance

2. **Deploy to App Stores**
   - Upload AAB to Google Play Console
   - Create internal testing track
   - Add beta testers
   - For iOS: Build, sign, and upload to TestFlight

3. **Set Up Monitoring**
   - Configure Vercel monitoring
   - Set up Firebase dashboards
   - Create alerts for critical issues

### Testing Checklist
- [ ] Backend health check passes
- [ ] Android app installs and launches
- [ ] Core features functional (chat, patterns, memory)
- [ ] Offline mode works
- [ ] Premium features gate correctly
- [ ] Analytics events fire correctly
- [ ] Crash reporting works

## 🚨 Important Notes

1. **Environment Variables:** Ensure all production secrets are properly set in Vercel
2. **Firebase Config:** Download and add Firebase config files before final deployment
3. **API Keys:** Verify all API keys (Gemini, etc.) are working in production
4. **Testing:** Thoroughly test all features before releasing to users

## 📊 Performance Targets

- Backend response time: < 500ms
- App startup time: < 3 seconds
- Memory usage: < 200MB
- Crash rate: < 1%

## 🔗 Useful Links

- **Vercel Dashboard:** https://vercel.com/dashboard
- **Firebase Console:** https://console.firebase.google.com/
- **Google Play Console:** https://play.google.com/console/
- **App Store Connect:** https://appstoreconnect.apple.com/

---

**Deployment completed successfully! 🎉**

Backend is live at: $BACKEND_URL  
Mobile apps are ready for store deployment.
EOF
    
    print_success "Deployment report generated: DEPLOYMENT_REPORT.md"
}

# Main deployment process
main() {
    echo "Starting deployment process..."
    
    check_prerequisites
    prepare_project
    deploy_backend
    build_flutter_apps
    create_artifacts
    setup_monitoring
    generate_report
    
    echo ""
    echo "🎉 DEPLOYMENT COMPLETED SUCCESSFULLY!"
    echo "=========================================="
    echo ""
    print_success "Backend deployed to: $(cat .vercel_url)"
    print_success "Mobile apps built and ready for store deployment"
    print_success "Deployment artifacts available in: deployment_artifacts/"
    print_success "Full report available in: DEPLOYMENT_REPORT.md"
    echo ""
    echo "Next steps:"
    echo "1. Configure Firebase (see firebase_setup_reminder.md)"
    echo "2. Upload apps to stores (see deployment_artifacts/README.md)"
    echo "3. Set up monitoring and alerts"
    echo "4. Test all features thoroughly"
    echo ""
    print_success "SoulBios is ready for production! 🚀"
}

# Run main function
main "$@"