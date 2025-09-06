# 🧠 SoulBios v1 - Multi-Agent AI Orchestration System

SoulBios is a high-performance, three-layer FastAPI application designed to power complex decision-making simulations. It features a hierarchical multi-agent framework, built for the "Berghain Challenge," that leverages parallel processing to achieve real-time strategic responses.

## ✨ Key Features

- **Multi-Agent Framework:** A hierarchical system where 16+ specialized agents inherit from a common `BaseAgent` contract.
- **High-Performance Orchestration:** A central `CloudStudentAgent` uses `asyncio.gather` to execute subordinate analysis agents in parallel, targeting sub-500ms response times.
- **Resilient Infrastructure:** Connects to PostgreSQL (via Cloud SQL), Redis (for caching), and ChromaDB (for vector storage), with built-in retry logic and graceful degradation.
- **Cloud-Native Deployment:** Optimized for deployment on Google Cloud Run, managed by a simple and robust `./deploy.sh` script.
- **OODA Loop Design:** The core strategic pipeline is modeled after the military OODA (Observe, Orient, Decide, Act) loop for competitive decision-making.

## 🚀 Getting Started

### Prerequisites

- Python 3.11+
- `pip` and `venv`
- A running PostgreSQL and Redis instance for local development.

### Installation & Setup

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/FakersDisciple/soulbios_v1
    cd soulbios_v1
    ```

2.  **Create and activate a virtual environment:**
    ```bash
    python3 -m venv venv
    source venv/bin/activate
    ```

3.  **Install dependencies:**
    ```bash
    pip install -r requirements.txt
    ```

4.  **Configure environment variables:**
    Copy the template and fill in your local development values.
    ```bash
    cp .env.example .env
    nano .env
    ```

5.  **Run the application locally:**
    ```bash
    uvicorn api.soulbios_api:app --host 0.0.0.0 --port 8080 --reload
    ```

## ☁️ Deployment to Google Cloud Run

The project includes a definitive deployment script that handles the entire build and deploy process.

1.  **Authenticate with gcloud:**
    ```bash
    gcloud auth login
    gcloud config set project YOUR_GCP_PROJECT_ID
    ```

2.  **Configure the `deploy.sh` script:**
    Open `deploy.sh` and verify the variables at the top (`PROJECT_ID`, `REGION`, `REDIS_URL`, etc.) match your GCP environment.

3.  **Run the deployment:**
    ```bash
    chmod +x deploy.sh
    ./deploy.sh
    ```

## 🏗️ Architecture Overview

### API Server Architecture
- **Three-Layer Design:** API Layer (FastAPI endpoints) → Agent Layer (specialized AI agents) → Infrastructure Layer (databases, caches)
- **Async Lifespan Management:** Sequential initialization of Redis, PostgreSQL, ChromaDB, and 11 specialized agents with graceful degradation
- **Request Processing:** JSON validation → AgentRequest creation → CloudStudentAgent orchestration → Response synthesis

### Agent Framework
- **Base Contract:** All agents inherit from `BaseAgent` with three mandatory abstract methods
- **Parallel Processing:** `asyncio.gather` executes 5 analysis agents simultaneously for maximum performance
- **Dependency Injection:** Hierarchical agent relationships enable cross-agent intelligence collaboration

### Client Architecture  
- **Dual-Server Connectivity:** Separate `httpx.Client` connections to game server and SoulBios API
- **Resilient Error Handling:** Comprehensive retry logic for HTTP errors, timeouts, and JSON parsing failures
- **Emergency Detection:** Real-time failure detection with automatic strategy adaptation

## 📊 Performance Metrics

- **Target Response Time:** <500ms for competitive advantage
- **Cache Hit Rate:** 40-60% with game-state similarity matching
- **Parallel Efficiency:** 95%+ concurrent agent execution
- **Emergency Detection:** <25 decision window for failure recovery

## 🛡️ Security & Best Practices

- **Environment Variables:** All sensitive data managed through `.env` files and Secret Manager
- **API Authentication:** Bearer token validation with rate limiting
- **Graceful Degradation:** System continues operating even if individual components fail
- **Production Monitoring:** Comprehensive logging and performance tracking

## 🤖 Agents Overview

The system includes specialized agents for different aspects of strategic analysis:

- **CloudStudentAgent:** Primary orchestrator managing parallel processing
- **GameTheoryAgent:** Strategic policy generation with OODA loop implementation  
- **ContextAgent:** Historical context and feature extraction
- **SafetyAgent:** Constraint validation and risk assessment
- **And 7 more specialized analysis agents...**

## 🧪 Testing & Validation

The system includes comprehensive testing for:
- **Performance Testing:** Response time validation and load testing
- **Integration Testing:** Multi-agent coordination and data flow
- **Emergency Scenarios:** Failure detection and recovery mechanisms

## 📈 Future Roadmap

- **V1.1:** Enhanced cache optimization and performance tuning  
- **V2.0:** Additional agent specializations and advanced orchestration patterns
- **V3.0:** Multi-tenant support and horizontal scaling capabilities

## 🤝 Contributing

This is the foundational v1.0 release. Future development will focus on performance optimization, additional agent capabilities, and deployment improvements.

## 📄 License

This project is proprietary software developed for competitive AI gaming scenarios.

---

**Built with:** FastAPI • PostgreSQL • Redis • ChromaDB • Google Cloud Run • Gemini AI
