# SoulBios Backend - deepconf

This is the clean, production-ready backend for the SoulBios Flutter app using only ChromaDB and Gemini AI.

## 🏗️ Architecture

- **FastAPI** - REST API server
- **ChromaDB** - Vector database for pattern storage
- **Gemini AI** - Consciousness-aware response generation
- **Kurzweil Pattern Recognition** - Hierarchical pattern analysis
- **Alice Consciousness Engine** - Persona-based AI responses

## 🚀 Quick Start

1. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

2. **Set up environment:**
   ```bash
   # Copy .env file with your Gemini API key
   GEMINI_API_KEY=your_gemini_api_key_here
   SOULBIOS_API_KEY=test-key-12345
   ```

3. **Start the backend:**
   ```bash
   python run_backend.py
   ```

4. **Test the connection:**
   ```bash
   cd ..
   python test_backend_connection.py
   ```

## 📡 API Endpoints

- `GET /health` - Health check
- `POST /chat` - Chat with Alice
- `GET /users/{user_id}/status` - User status
- `POST /users/{user_id}/analyze` - Pattern analysis
- `POST /upload/lifebook` - Upload PDF documents

## 🧠 Core Components

### Alice Consciousness Engine
- Persona-based responses (nurturing, investigative, wisdom guide, transcendent)
- Consciousness level adaptation
- Historical pattern memory
- Gemini AI integration

### Kurzweil Pattern Recognizer
- Hierarchical pattern network (5 levels)
- Bidirectional prediction signals
- Pattern activation and learning
- Consciousness indicators

### ChromaDB Collections Manager
- Multi-tenant user isolation
- Pattern persistence
- Conversation history
- Semantic search

## 🔧 Configuration

The backend uses local ChromaDB storage in `./chroma_db/` directory.

For production, update the ChromaDB configuration in `SoulBios_collections_manager.py`.

## 🧪 Testing

Run the test suite:
```bash
python test_backend_connection.py
```

This tests:
- Health endpoint
- User status
- Chat functionality
- Gemini AI integration

## 📱 Flutter Integration

The Flutter app connects to `http://localhost:8000` by default.

Key endpoints used by Flutter:
- `/chat` - Main chat interface
- `/users/{id}/status` - User initialization
- `/health` - Connection verification

## 🔍 Debugging

Check logs for detailed information:
- API requests/responses
- Pattern recognition results
- Consciousness level calculations
- Gemini AI interactions

## 🚀 Production Deployment

For production:
1. Update ChromaDB to cloud instance
2. Set proper CORS origins
3. Enable API key authentication
4. Configure environment variables
5. Use proper logging configuration