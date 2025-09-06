# 🧪 SoulBios V1 - Final Testing Checklist

## **Day 5: End-to-End Integration Testing**

### **✅ Health & Authentication Tests**
```bash
# 1. Health Check (No auth required)
curl https://[YOUR-SERVICE-URL]/health

# Expected: 200 OK with performance metrics

# 2. Unauthorized Access Test
curl -X POST https://[YOUR-SERVICE-URL]/chat \
  -H "Content-Type: application/json" \
  -d '{"user_id": "test", "message": "Hello"}'

# Expected: 401 Unauthorized
```

### **✅ Authenticated API Tests**
```bash
# 3. Chat Endpoint Test (With Auth)
curl -X POST https://[YOUR-SERVICE-URL]/chat \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer [YOUR-SOULBIOS-API-KEY]" \
  -d '{"user_id": "test_user", "message": "Tell me about personal growth"}'

# Expected: 200 OK with multi-agent response in <800ms

# 4. Chamber Creation Test
curl -X POST https://[YOUR-SERVICE-URL]/chamber/create \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer [YOUR-SOULBIOS-API-KEY]" \
  -H "X-User-ID: test_user" \
  -d '{"session_type": "growth", "duration": 30}'

# Expected: 200 OK with session ID
```

### **✅ Rate Limiting Tests**
```bash
# 5. Rate Limit Test (Run 51+ requests rapidly)
for i in {1..55}; do
  curl -X POST https://[YOUR-SERVICE-URL]/chat \
    -H "Authorization: Bearer [YOUR-SOULBIOS-API-KEY]" \
    -H "Content-Type: application/json" \
    -d '{"user_id": "rate_test", "message": "Test '$i'"}'
  echo "Request $i completed"
done

# Expected: First 50 succeed, then 429 Rate Limit Exceeded
```

## **Day 6: Performance & Load Testing**

### **✅ Response Time Validation**
```bash
# 6. Performance Test (Measure response times)
time curl -X POST https://[YOUR-SERVICE-URL]/chat \
  -H "Authorization: Bearer [YOUR-SOULBIOS-API-KEY]" \
  -H "Content-Type: application/json" \
  -d '{"user_id": "perf_test", "message": "Complex philosophical question about consciousness and growth"}'

# Expected: Response time <1.5 seconds, ideally <800ms
```

### **✅ Load Testing Script**
```bash
# 7. Concurrent Load Test
# Create load-test-production.ps1:
```

### **✅ Memory & Resource Monitoring**
```bash
# 8. Monitor Cloud Run Metrics
gcloud run services describe [SERVICE-NAME] \
  --region=[YOUR-REGION] \
  --format="table(status.conditions[].type:label=CONDITION,status.conditions[].status:label=STATUS)"

# Check logs for errors:
gcloud logs read "resource.type=cloud_run_revision" --limit=50
```

## **Day 7: User Acceptance & Final Validation**

### **✅ Agent Response Quality**
```bash
# 9. Multi-Agent Response Test
curl -X POST https://[YOUR-SERVICE-URL]/chat \
  -H "Authorization: Bearer [YOUR-SOULBIOS-API-KEY]" \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "quality_test", 
    "message": "I want to understand my purpose in life and develop better habits"
  }'

# Verify response contains:
# ✅ Teacher agent: Socratic questions
# ✅ Narrative agent: Story/metaphor
# ✅ Transcendent agent: Philosophical insights  
# ✅ Context agent: Historical reference
```

### **✅ Chamber Functionality**
```bash
# 10. Complete Chamber Flow Test
# a) Create session
SESSION_RESPONSE=$(curl -X POST https://[YOUR-SERVICE-URL]/chamber/create \
  -H "Authorization: Bearer [YOUR-SOULBIOS-API-KEY]" \
  -H "X-User-ID: chamber_test" \
  -H "Content-Type: application/json" \
  -d '{"session_type": "consciousness", "duration": 15}')

# b) Extract session ID
SESSION_ID=$(echo $SESSION_RESPONSE | jq -r '.session_id')

# c) Check session status  
curl https://[YOUR-SERVICE-URL]/chamber/$SESSION_ID/status \
  -H "Authorization: Bearer [YOUR-SOULBIOS-API-KEY]"

# Expected: Active session with growth prompts
```

### **✅ Security Validation**
```bash
# 11. Security Headers Test
curl -I https://[YOUR-SERVICE-URL]/health

# Verify security headers are present
# Expected headers: CORS, Content-Type, etc.

# 12. Invalid API Key Test
curl -X POST https://[YOUR-SERVICE-URL]/chat \
  -H "Authorization: Bearer invalid-key-12345" \
  -H "Content-Type: application/json" \
  -d '{"user_id": "security_test", "message": "Test"}'

# Expected: 401 Unauthorized
```

## **✅ Final Production Checklist**

- [ ] All API endpoints responding correctly
- [ ] Authentication working (valid keys accepted, invalid rejected)
- [ ] Rate limiting active (50 chat/hour, 20 chamber/hour)
- [ ] Response times <800ms for individual requests  
- [ ] Multi-agent responses include all 4 agent types
- [ ] Chamber creation and status working
- [ ] WebSocket connections stable (if using)
- [ ] Error handling graceful (no 500 errors)
- [ ] Logs are readable and informative
- [ ] Health check passes consistently
- [ ] No secrets exposed in logs or responses

## **🎉 Launch Criteria**

**SoulBios V1 is ready for launch when:**

1. ✅ All tests in this checklist pass
2. ✅ Response time P95 < 1.5 seconds  
3. ✅ 99.9% uptime over 24-hour test period
4. ✅ No critical security vulnerabilities
5. ✅ All 6 agents responding appropriately
6. ✅ Rate limiting preventing abuse
7. ✅ Error rates < 1%

**Expected Performance:**
- Response time: 800ms-1.5s ✅
- Cost per conversation: ~$0.034 ✅  
- Concurrent users: 50+ ✅
- Uptime: 99.9%+ ✅

**Post-Launch Monitoring:**
- Monitor Cloud Run metrics daily
- Check error logs weekly
- Review cost usage monthly
- Update API keys quarterly