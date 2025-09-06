#!/usr/bin/env python3
"""
SoulBios CLI Tool
Automates setup, troubleshooting, and launch for SoulBios Launch V1 project.
Commands:
- setup: Install dependencies, create .env if missing, set up directories and __init__.py files.
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
REDIS_PATH = r"C:\Redis"  # Adjust if Redis is in a different path

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
        with open(env_path, 'w', encoding='utf-8') as f:
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
    import time
    start_time = time.time()
    run_command("python test_cache.py")
    end_time = time.time()
    execution_time = (end_time - start_time) * 1000  # Convert to milliseconds
    logger.info(f"Test completed in {execution_time:.2f}ms")

def launch_api():
    """Launch the API with Uvicorn."""
    logger.info("Launching API...")
    run_command("uvicorn api.soulbios_api:app --reload --port 8000")

def fix_imports():
    """Scan and fix relative imports in agent files."""
    for file_path in AGENTS_DIR.glob('*.py'):
        if file_path.name != '__init__.py':
            logger.info(f"Fixing imports in {file_path.name}")
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                content = content.replace("from base_agent import", "from .base_agent import")
                content = content.replace("from gemini_confidence_proxy import", "from middleware.gemini_confidence_proxy import")
                content = content.replace("from character_playbook_manager import", "from .character_playbook_manager import")
                content = content.replace("from alice_consciousness_engine import", "from .alice_consciousness_engine import")
                content = content.replace("from SoulBios_collections_manager import", "from infrastructure.SoulBios_collections_manager import")
                content = content.replace("from kurzweil_pattern_recognizer import", "from .kurzweil_pattern_recognizer import")
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(content)
                logger.info(f"Fixed imports in {file_path.name}")
            except Exception as e:
                logger.error(f"Error fixing imports in {file_path.name}: {e}")
                continue

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