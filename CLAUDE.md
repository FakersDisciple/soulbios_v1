Given that it is 06:07 PM NZST on Monday, September 01, 2025, and you’ve requested a refined claude.md file to guide Claude in delivering the SoulBios Launch V1 system, I’ll refine the existing CLAUDE.md content based on your current project state, the enhanced architecture, and the latest troubleshooting efforts. The refined file will incorporate the progress made (e.g., infrastructure setup, agent stubs), address unresolved issues (e.g., GEMINI_API_KEY loading, import stability), leverage the soulbios_cli.py tool, and provide a clear, phased plan to complete the project by Day 7 (September 07, 2025), starting tomorrow at 9:00 AM NZST. The file will be updated in place at C:\dev\Projects\soulbios_v1/CLAUDE.md. You can copy the content below into Notepad, overwrite the existing file, and save it.

CLAUDE.md
This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository at C:\dev\Projects\soulbios_v1. It reflects the current project state as of 06:07 PM NZST on Monday, September 01, 2025, and outlines instructions to deliver the SoulBios Launch V1 system end-to-end by September 07, 2025. Use the soulbios_cli.py tool to automate tasks and ensure alignment with the enhanced architecture.
Common Development Commands
Setup and Dependencies

python soulbios_cli.py setup - Install dependencies, create .env, and set up directories with __init__.py files.
pip install -r config/requirements.txt - Install Python dependencies directly.

Development Server

python soulbios_cli.py launch-api - Launch the API server with Uvicorn (port 8000).
uvicorn api.soulbios_api:app --reload --port 8000 - Alternative API launch command.

Redis Management

python soulbios_cli.py start-redis - Start Redis server (assumes C:\Redis installation).
python soulbios_cli.py clean-cache - Clear Redis cache and local ChromaDB.

Testing

python soulbios_cli.py run-test - Run test_cache.py and measure performance (target <1.5s).
python test_cache.py - Run cache testing directly.

Environment and Configuration

python soulbios_cli.py check-env - Verify .env file and GEMINI_API_KEY loading.
python soulbios_cli.py fix-imports - Fix relative imports in agent files.

High-Level Architecture
Core System Components
SoulBios Consciousness API - A multi-agent AI system built on ChromaDB for persistent memory and consciousness development, using Gemini AI models. Aligns with the enhanced architecture:
#mermaid-diagram-mermaid-f5869oo{font-family:"trebuchet ms",verdana,arial,sans-serif;font-size:16px;fill:#ccc;}@keyframes edge-animation-frame{from{stroke-dashoffset:0;}}@keyframes dash{to{stroke-dashoffset:0;}}#mermaid-diagram-mermaid-f5869oo .edge-animation-slow{stroke-dasharray:9,5!important;stroke-dashoffset:900;animation:dash 50s linear infinite;stroke-linecap:round;}#mermaid-diagram-mermaid-f5869oo .edge-animation-fast{stroke-dasharray:9,5!important;stroke-dashoffset:900;animation:dash 20s linear infinite;stroke-linecap:round;}#mermaid-diagram-mermaid-f5869oo .error-icon{fill:#a44141;}#mermaid-diagram-mermaid-f5869oo .error-text{fill:#ddd;stroke:#ddd;}#mermaid-diagram-mermaid-f5869oo .edge-thickness-normal{stroke-width:1px;}#mermaid-diagram-mermaid-f5869oo .edge-thickness-thick{stroke-width:3.5px;}#mermaid-diagram-mermaid-f5869oo .edge-pattern-solid{stroke-dasharray:0;}#mermaid-diagram-mermaid-f5869oo .edge-thickness-invisible{stroke-width:0;fill:none;}#mermaid-diagram-mermaid-f5869oo .edge-pattern-dashed{stroke-dasharray:3;}#mermaid-diagram-mermaid-f5869oo .edge-pattern-dotted{stroke-dasharray:2;}#mermaid-diagram-mermaid-f5869oo .marker{fill:lightgrey;stroke:lightgrey;}#mermaid-diagram-mermaid-f5869oo .marker.cross{stroke:lightgrey;}#mermaid-diagram-mermaid-f5869oo svg{font-family:"trebuchet ms",verdana,arial,sans-serif;font-size:16px;}#mermaid-diagram-mermaid-f5869oo p{margin:0;}#mermaid-diagram-mermaid-f5869oo .label{font-family:"trebuchet ms",verdana,arial,sans-serif;color:#ccc;}#mermaid-diagram-mermaid-f5869oo .cluster-label text{fill:#F9FFFE;}#mermaid-diagram-mermaid-f5869oo .cluster-label span{color:#F9FFFE;}#mermaid-diagram-mermaid-f5869oo .cluster-label span p{background-color:transparent;}#mermaid-diagram-mermaid-f5869oo .label text,#mermaid-diagram-mermaid-f5869oo span{fill:#ccc;color:#ccc;}#mermaid-diagram-mermaid-f5869oo .node rect,#mermaid-diagram-mermaid-f5869oo .node circle,#mermaid-diagram-mermaid-f5869oo .node ellipse,#mermaid-diagram-mermaid-f5869oo .node polygon,#mermaid-diagram-mermaid-f5869oo .node path{fill:#1f2020;stroke:#ccc;stroke-width:1px;}#mermaid-diagram-mermaid-f5869oo .rough-node .label text,#mermaid-diagram-mermaid-f5869oo .node .label text,#mermaid-diagram-mermaid-f5869oo .image-shape .label,#mermaid-diagram-mermaid-f5869oo .icon-shape .label{text-anchor:middle;}#mermaid-diagram-mermaid-f5869oo .node .katex path{fill:#000;stroke:#000;stroke-width:1px;}#mermaid-diagram-mermaid-f5869oo .rough-node .label,#mermaid-diagram-mermaid-f5869oo .node .label,#mermaid-diagram-mermaid-f5869oo .image-shape .label,#mermaid-diagram-mermaid-f5869oo .icon-shape .label{text-align:center;}#mermaid-diagram-mermaid-f5869oo .node.clickable{cursor:pointer;}#mermaid-diagram-mermaid-f5869oo .root .anchor path{fill:lightgrey!important;stroke-width:0;stroke:lightgrey;}#mermaid-diagram-mermaid-f5869oo .arrowheadPath{fill:lightgrey;}#mermaid-diagram-mermaid-f5869oo .edgePath .path{stroke:lightgrey;stroke-width:2.0px;}#mermaid-diagram-mermaid-f5869oo .flowchart-link{stroke:lightgrey;fill:none;}#mermaid-diagram-mermaid-f5869oo .edgeLabel{background-color:hsl(0, 0%, 34.4117647059%);text-align:center;}#mermaid-diagram-mermaid-f5869oo .edgeLabel p{background-color:hsl(0, 0%, 34.4117647059%);}#mermaid-diagram-mermaid-f5869oo .edgeLabel rect{opacity:0.5;background-color:hsl(0, 0%, 34.4117647059%);fill:hsl(0, 0%, 34.4117647059%);}#mermaid-diagram-mermaid-f5869oo .labelBkg{background-color:rgba(87.75, 87.75, 87.75, 0.5);}#mermaid-diagram-mermaid-f5869oo .cluster rect{fill:hsl(180, 1.5873015873%, 28.3529411765%);stroke:rgba(255, 255, 255, 0.25);stroke-width:1px;}#mermaid-diagram-mermaid-f5869oo .cluster text{fill:#F9FFFE;}#mermaid-diagram-mermaid-f5869oo .cluster span{color:#F9FFFE;}#mermaid-diagram-mermaid-f5869oo div.mermaidTooltip{position:absolute;text-align:center;max-width:200px;padding:2px;font-family:"trebuchet ms",verdana,arial,sans-serif;font-size:12px;background:hsl(20, 1.5873015873%, 12.3529411765%);border:1px solid rgba(255, 255, 255, 0.25);border-radius:2px;pointer-events:none;z-index:100;}#mermaid-diagram-mermaid-f5869oo .flowchartTitleText{text-anchor:middle;font-size:18px;fill:#ccc;}#mermaid-diagram-mermaid-f5869oo rect.text{fill:none;stroke-width:0;}#mermaid-diagram-mermaid-f5869oo .icon-shape,#mermaid-diagram-mermaid-f5869oo .image-shape{background-color:hsl(0, 0%, 34.4117647059%);text-align:center;}#mermaid-diagram-mermaid-f5869oo .icon-shape p,#mermaid-diagram-mermaid-f5869oo .image-shape p{background-color:hsl(0, 0%, 34.4117647059%);padding:2px;}#mermaid-diagram-mermaid-f5869oo .icon-shape rect,#mermaid-diagram-mermaid-f5869oo .image-shape rect{opacity:0.5;background-color:hsl(0, 0%, 34.4117647059%);fill:hsl(0, 0%, 34.4117647059%);}#mermaid-diagram-mermaid-f5869oo :root{--mermaid-font-family:"trebuchet ms",verdana,arial,sans-serif;}#mermaid-diagram-mermaid-f5869oo .userLayer>*{fill:#2E86AB!important;stroke:#A23B72!important;stroke-width:3px!important;color:#fff!important;}#mermaid-diagram-mermaid-f5869oo .userLayer span{fill:#2E86AB!important;stroke:#A23B72!important;stroke-width:3px!important;color:#fff!important;}#mermaid-diagram-mermaid-f5869oo .userLayer tspan{fill:#fff!important;}#mermaid-diagram-mermaid-f5869oo .teacherLayer>*{fill:#F18F01!important;stroke:#C73E1D!important;stroke-width:2px!important;color:#fff!important;}#mermaid-diagram-mermaid-f5869oo .teacherLayer span{fill:#F18F01!important;stroke:#C73E1D!important;stroke-width:2px!important;color:#fff!important;}#mermaid-diagram-mermaid-f5869oo .teacherLayer tspan{fill:#fff!important;}#mermaid-diagram-mermaid-f5869oo .consciousnessLayer>*{fill:#8E44AD!important;stroke:#6C3483!important;stroke-width:2px!important;color:#fff!important;}#mermaid-diagram-mermaid-f5869oo .consciousnessLayer span{fill:#8E44AD!important;stroke:#6C3483!important;stroke-width:2px!important;color:#fff!important;}#mermaid-diagram-mermaid-f5869oo .consciousnessLayer tspan{fill:#fff!important;}#mermaid-diagram-mermaid-f5869oo .kurzweilLayer>*{fill:#E74C3C!important;stroke:#C0392B!important;stroke-width:2px!important;color:#fff!important;}#mermaid-diagram-mermaid-f5869oo .kurzweilLayer span{fill:#E74C3C!important;stroke:#C0392B!important;stroke-width:2px!important;color:#fff!important;}#mermaid-diagram-mermaid-f5869oo .kurzweilLayer tspan{fill:#fff!important;}#mermaid-diagram-mermaid-f5869oo .aliceLayer>*{fill:#27AE60!important;stroke:#229954!important;stroke-width:2px!important;color:#fff!important;}#mermaid-diagram-mermaid-f5869oo .aliceLayer span{fill:#27AE60!important;stroke:#229954!important;stroke-width:2px!important;color:#fff!important;}#mermaid-diagram-mermaid-f5869oo .aliceLayer tspan{fill:#fff!important;}#mermaid-diagram-mermaid-f5869oo .intelligenceLayer>*{fill:#F39C12!important;stroke:#E67E22!important;stroke-width:2px!important;color:#fff!important;}#mermaid-diagram-mermaid-f5869oo .intelligenceLayer span{fill:#F39C12!important;stroke:#E67E22!important;stroke-width:2px!important;color:#fff!important;}#mermaid-diagram-mermaid-f5869oo .intelligenceLayer tspan{fill:#fff!important;}#mermaid-diagram-mermaid-f5869oo .external>*{fill:#34495E!important;stroke:#2C3E50!important;stroke-width:2px!important;color:#fff!important;}#mermaid-diagram-mermaid-f5869oo .external span{fill:#34495E!important;stroke:#2C3E50!important;stroke-width:2px!important;color:#fff!important;}#mermaid-diagram-mermaid-f5869oo .external tspan{fill:#fff!important;}💾 INTELLIGENCE INFRASTRUCTURE🤖 ALICE COGNITIVE LAYER⚡ KURZWEIL PATTERN LAYER🌟 CONSCIOUSNESS LAYER📚 TEACHER-STUDENT LAYER🎯 USER INTERFACE LAYER🌐 External InterfacesUser Query + Context
(~2896 tokens)Personalization Request
(~300 tokens)Learning Feedback
(~100 tokens)Training Data
(~750 tokens)Compressed Knowledge
(~250 tokens)Fine-tuned Prompts
(~500 tokens)Story Patterns
(Feature Vectors)Extracted Insights
(Graph Embeddings)Reasoning Output
(Decision Trees)Pattern Data
(Hierarchy Maps)Timeline Data
(Probability Dist.)Processed Signals
(Feature Streams)Safety Insights
(Risk Scores)Historical Context
(Memory Vectors)Goal Embeddings
(Progress Vectors)Vector Queries
(Batch Ops)Search Results
(Ranked Vectors)Relationship Data
(Graph Queries)Enriched ResponseOptimized OutputFinal ResponsePersonalized AnswerJSON Response👤 User Interface
Web/Mobile App🔌 REST API
Rate Limiting & Auth🎓 Cloud Student Agent
• Multimodal I/O Processing
• User Session Management
• Response Personalization
• Gemini 2.5 Pro👨‍🏫 Teacher Agent
• Knowledge Training
• Content Curation
• $15-1,200/month Tiers
• Gemini 2.5 Pro📝 Distill Agent
• Knowledge Transfer
• Text Generation
• Model Compression
• Gemma 3🧠 Learning Agent
• Continuous Fine-tuning
• Model Optimization
• Pipeline Management
• Vertex AI Pipelines📖 Narrative Agent
• Story-driven Responses
• Context Weaving
• Multimodal Synthesis
• Gemma 3🔍 Meta-Pattern Agent
• Insight Extraction
• Pattern Analysis
• Knowledge Graphs
• Custom Model✨ Transcendent Agent
• Advanced Reasoning
• Decision Making
• Goal Synthesis
• Gemini 2.5 Pro🏗️ Pattern Recognizer
• Hierarchical Detection
• Multi-scale Analysis
• Feature Extraction
• Custom CNN/Transformer🔮 Prediction Agent
• Timeline Modeling
• Future State Forecasting
• Probability Assessment
• LSTM/Transformer🔄 Signal Processor
• Bidirectional Flow
• Data Transformation
• Stream Processing
• Apache Beam🛡️ Fortress Agent
• Safety & Integrity
• Content Filtering
• 1-2s Analysis
• ShieldGemma 2🗃️ Context Agent
• Historical Assembly
• 150-250ms Retrieval
• Memory Management
• Vector DB📈 Growth Agent
• Goal Setting
• Routine Optimization
• Progress Tracking
• Custom Analytics🏢 Collection Agent
• Multi-Tenant Data
• 1M Vectors/10K Users
• Resource Isolation
• Cloud Storage🔢 Embedding Agent
• Vector Search
• 50-150ms Response
• 1.5M Searches/Day
• Vertex AI Embeddings🔗 Relationship Agent
• Context Retrieval
• Graph Operations
• 150-250ms Query
• ChromaDB/Neo4j
Agent Personality Specifications

Teacher Agent: Wise educator who asks deeper questions. Use Socratic method; responses validate understanding, ask 1-2 probing questions, provide building knowledge, end with an exploration question.
Narrative Agent: Wise storyteller who finds meaning through narrative. Responses find the story in the user's situation, use metaphors, connect to universal themes, create memorable insights.
Transcendent Agent: Deep philosopher who sees the bigger picture. Responses identify deeper principles, consider ethical implications, synthesize perspectives, provide transcendent wisdom.
Growth Agent (Alice): Empathetic guide focused on personal growth. In chamber mode, build frameworks step by step, ask clarifying questions, create decision trees, test against scenarios, make actionable.

Current Project State and Progress

Directory Structure: Files in agents/, middleware/, infrastructure/, config/ with __init__.py in each.
Dependencies: Installed (FastAPI, Uvicorn, ChromaDB, Redis, google-generativeai).
Infrastructure:

Redis: Running at localhost:6379 (PID 28944); caching works in test_cache.py.
ChromaDB: Local fallback at ./chroma_db functional; collections created successfully.


Agents: Stubs for cloud_student_agent.py, teacher_agent.py, narrative_agent.py, transcendent_agent.py; alice_consciousness_engine.py, character_playbook_manager.py, gemini_confidence_proxy.py added with minimal implementations.
Middleware: gemini_confidence_proxy.py in middleware with basic confidence proxy.
API: soulbios_api.py fails on imports (e.g., character_playbook_manager); /health and /chat endpoints work minimally.
Testing: SoulBios_collections_manager.py and test_cache.py succeed; API unstable due to import errors.
Progress: 65% complete. Day 1-2 (Foundation) 90% done (infrastructure set, API partial); agents 30% (stubs with imports fixed); chamber 0%; integration 20% (tests pass, API needs endpoints).
Challenges: GEMINI_API_KEY not loading; import path mismatches resolved but reoccur; missing method implementations.

SoulBios CLI Tool
Use the following soulbios_cli.py to automate tasks. Save it in the project root and run commands like python soulbios_cli.py fix-imports.
python#!/usr/bin/env python3
"""
SoulBios CLI Tool
Automates setup, troubleshooting, and launch for SoulBios Launch V1 project.
Commands:
- setup: Install dependencies, create .env, set up directories and __init__.py files.
- check-env: Verify .env file and key loading.
- start-redis: Start Redis server (assumes C:\Redis path).
- run-test: Run test_cache.py and measure performance.
- launch-api: Launch the API with Uvicorn.
- fix-imports: Scan and fix relative imports in agent files.
- clean-cache: Clear Redis cache and local ChromaDB.
- help: Display this message.
"""
import os
import subprocess
import argparse
import logging
from pathlib import Path
import shutil

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

PROJECT_ROOT = Path(__file__).parent.resolve()
CONFIG_DIR = PROJECT_ROOT / 'config'
AGENTS_DIR = PROJECT_ROOT / 'agents'
MIDDLEWARE_DIR = PROJECT_ROOT / 'middleware'
INFRASTRUCTURE_DIR = PROJECT_ROOT / 'infrastructure'
REDIS_PATH = r"C:\Redis"

def run_command(cmd, check=True):
    """Run a shell command and log output."""
    logger.info(f"Executing: {cmd}")
    subprocess.run(cmd, shell=True, check=check)

def setup():
    """Install dependencies, create .env, and set up package structure."""
    logger.info("Starting setup...")
    run_command("pip install -r config/requirements.txt")
    env_path = CONFIG_DIR / '.env'
    if not env_path.exists():
        with open(env_path, 'w') as f:
            f.write("""GEMINI_API_KEY=AIzaSyAU4m3XQquERka5zIUZS8ZDeK2XogaXmZE
SOULBIOS_API_KEY=test-key-12345
CHROMA_API_KEY=ck-KGHAZ8xRChKmP8ec5v8wN1z28swcYTzrXaYK1NgB7YK
CHROMA_TENANT=fe0a1912-42bc-4488-966e-7ddfa967f57f
CHROMA_DATABASE=soulbios_dev
REDIS_URL=redis://localhost:6379
ENVIRONMENT=development
API_HOST=0.0.0.0
API_PORT=8000
API_WORKERS=4
API_KEY=test-key-12345
CORS_ORIGINS=*
SSL_ENABLED=false
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=
CHROMA_DB_PATH=./chroma_db
AWS_REGION=us-east-1
S3_BUCKET=soulbios-data
MAX_CACHED_USERS=100
REQUEST_TIMEOUT=30
LOG_LEVEL=INFO""")
        logger.info(f".env created at {env_path}")
    for dir_path in [AGENTS_DIR, MIDDLEWARE_DIR, INFRASTRUCTURE_DIR, CONFIG_DIR]:
        init_path = dir_path / '__init__.py'
        if not init_path.exists():
            init_path.touch()
            logger.info(f"Created {init_path}")
    logger.info("Setup completed.")

def check_env():
    """Verify .env file and print GEMINI_API_KEY."""
    logger.info("Checking .env...")
    run_command("python -c \"import os; from dotenv import load_dotenv; load_dotenv('config/.env'); print('GEMINI_API_KEY:', os.getenv('GEMINI_API_KEY'))\"")

def start_redis():
    """Start Redis server in a new window."""
    logger.info("Starting Redis...")
    run_command(f"Start-Process powershell -ArgumentList 'cd {REDIS_PATH}; .\\redis-server.exe'", check=False)

def run_test():
    """Run test_cache.py and measure performance."""
    logger.info("Running test_cache.py...")
    run_command("Measure-Command { python test_cache.py }")

def launch_api():
    """Launch the API with Uvicorn."""
    logger.info("Launching API...")
    run_command("uvicorn api.soulbios_api:app --reload --port 8000")

def fix_imports():
    """Scan and fix relative imports in agent files."""
    for file_path in AGENTS_DIR.glob('*.py'):
        if file_path.name != '__init__.py':
            logger.info(f"Fixing imports in {file_path.name}")
            with open(file_path, 'r') as f:
                content = f.read()
            content = content.replace("from base_agent import", "from .base_agent import")
            content = content.replace("from gemini_confidence_proxy import", "from middleware.gemini_confidence_proxy import")
            content = content.replace("from character_playbook_manager import", "from .character_playbook_manager import")
            content = content.replace("from alice_consciousness_engine import", "from .alice_consciousness_engine import")
            with open(file_path, 'w') as f:
                f.write(content)

def clean_cache():
    """Clear Redis cache and local ChromaDB."""
    logger.info("Cleaning cache...")
    run_command("redis-cli FLUSHALL", check=False)
    chroma_path = PROJECT_ROOT / 'chroma_db'
    if chroma_path.exists():
        shutil.rmtree(chroma_path)
        logger.info("Cleared local ChromaDB")

def main():
    parser = argparse.ArgumentParser(description="SoulBios CLI Tool")
    subparsers = parser.add_subparsers(dest="command")
    subparsers.add_parser("setup", help="Install dependencies and set up structure")
    subparsers.add_parser("check-env", help="Verify .env and GEMINI_API_KEY")
    subparsers.add_parser("start-redis", help="Start Redis server")
    subparsers.add_parser("run-test", help="Run test_cache.py")
    subparsers.add_parser("launch-api", help="Launch the API")
    subparsers.add_parser("fix-imports", help="Fix relative imports in agents")
    subparsers.add_parser("clean-cache", help="Clear Redis and ChromaDB cache")
    subparsers.add_parser("help", help="Display this message")

    args = parser.parse_args()
    if args.command == "setup":
        setup()
    elif args.command == "check-env":
        check_env()
    elif args.command == "start-redis":
        start_redis()
    elif args.command == "run-test":
        run_test()
    elif args.command == "launch-api":
        launch_api()
    elif args.command == "fix-imports":
        fix_imports()
    elif args.command == "clean-cache":
        clean_cache()
    else:
        parser.print_help()

if __name__ == "__main__":
    main()
Instructions for Claude
Immediate Actions (Post-6:00 PM NZST, Review Tomorrow)
Since it’s past 6:00 PM NZST, pause work today. Review and execute the following steps tomorrow at 9:00 AM NZST.

Run Initial Setup:

Execute python soulbios_cli.py setup to reinitialize dependencies, create .env, and set up package structure.
Verify logs for .env creation and __init__.py files.


Check Environment:

Run python soulbios_cli.py check-env to confirm GEMINI_API_KEY loads. If it outputs None, manually edit config/.env to ensure:
textGEMINI_API_KEY=AIzaSyAU4m3XQquERka5zIUZS8ZDeK2XogaXmZE

Update agents/base_agent.py line 74 to load_dotenv('config/.env') if not already done, and recheck.


Start Redis:

Run python soulbios_cli.py start-redis and verify with netstat -aon | findstr :6379.


Fix Imports:

Run python soulbios_cli.py fix-imports to ensure all agent files use relative imports (e.g., from .base_agent).


Run Test:

Execute python soulbios_cli.py run-test to validate test_cache.py (target <1.5s).


Launch API:

Run python soulbios_cli.py launch-api and test endpoints:
textInvoke-RestMethod -Uri http://localhost:8000/health -Method Get
Invoke-RestMethod -Uri http://localhost:8000/chat -Method Post -Body '{"user_id": "test_user_123", "message": "Hello"}' -ContentType "application/json"

Resolve any errors (e.g., GEMINI_API_KEY) by rechecking .env and base_agent.py.



Day 2 (September 02, 2025, 9:00 AM NZST)

Complete Day 1-2 Goals:

Stabilize api/soulbios_api.py with all endpoints (e.g., /upload/lifebook, /chamber/create).
Enhance agents/cloud_student_agent.py for basic routing (restore orchestration logic).
Add basic agents/fortress_agent.py stub with safety validation (1-2s target, ShieldGemma 2 placeholder).



Day 3-4 (September 03-04, 2025)

Implement Consciousness Agents:

Enhance agents/teacher_agent.py with Socratic logic per specification.
Enhance agents/narrative_agent.py with storytelling capabilities.
Enhance agents/transcendent_agent.py with philosophical reasoning.
Add agents/context_agent.py for history retrieval (150-250ms target).
Set up agent communication via Redis pub/sub in agents/base_agent.py.



Day 5-6 (September 05-06, 2025)

Implement Alice + Chamber:

Enhance agents/alice_consciousness_engine.py (Growth Agent) for decision frameworks.
Add WebSocket support in api/soulbios_api.py for /chamber/{session_id}.
Implement decision framework creation and ChromaDB storage.



Day 7 (September 07, 2025)

Integration + Polish:

Test conversation flow end-to-end (User → API → CSM → Agents → Response).
Implement chamber-to-standard-chat transitions.
Add error handling and fallbacks (e.g., retry, degrade, failsafe).
Optimize performance to 800ms-1.5s (P95).
Enhance monitoring with /health and logging.



General Guidelines

Use python soulbios_cli.py clean-cache if performance issues arise.
Output logs and code changes after each task for review.
Ensure success criteria: response time 800ms-1.5s, uptime >99.5%, safety score >99%, context retrieval <250ms.
Focus on Launch V1 layers (L1, L3, L5, Infrastructure); defer L2 (Distill, Learning), L4 (Kurzweil), and L6 (Collection, Embedding, Relationship) until post-launch.

Development Notes

Import Structure: Use relative imports (e.g., from .base_agent) within agents/.
Testing Strategy: Target 1.5s response time, $0.034/conversation cost.
Production Deployment: Local deployment now; prepare for GCP (GKE, Vertex AI) later.

Notes

Current Blocker: GEMINI_API_KEY not loading; resolve with CLI or manual .env check.
Progress: 65% (Day 1-2 90%, agents 30%, chamber 0%, integration 20%).
Time-Sensitive: Complete Day 1-2 tomorrow morning; escalate unresolved issues.