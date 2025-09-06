"""
Production configuration for SoulBios API deployment
Handles AWS integration, Redis caching, and production optimizations
"""
import os
import redis
import boto3
import logging
from typing import Optional
from dotenv import load_dotenv
load_dotenv()

class ProductionConfig:
    """Production configuration management"""
    
    def __init__(self):
        self.environment = os.getenv("ENVIRONMENT", "development")
        self.is_production = self.environment == "production"
        self.is_staging = self.environment == "staging"
        
        # API Configuration
        self.api_host = os.getenv("API_HOST", "0.0.0.0")
        self.api_port = int(os.getenv("API_PORT", "8000"))
        self.api_workers = int(os.getenv("API_WORKERS", "4"))
        
        # Security
        self.api_key = os.getenv("API_KEY", "test-key-12345")
        self.cors_origins = os.getenv("CORS_ORIGINS", "*").split(",")
        self.ssl_enabled = os.getenv("SSL_ENABLED", "false").lower() == "true"
        
        # Gemini API
        self.gemini_api_key = self._get_secret("GEMINI_API_KEY")
        
        # Redis Configuration
        self.redis_host = os.getenv("REDIS_HOST", "localhost")
        self.redis_port = int(os.getenv("REDIS_PORT", "6379"))
        self.redis_password = os.getenv("REDIS_PASSWORD")
        
        # Database
        self.chroma_db_path = os.getenv("CHROMA_DB_PATH", "./chroma_db")
        
        # AWS Configuration
        self.aws_region = os.getenv("AWS_REGION", "us-east-1")
        self.s3_bucket = os.getenv("S3_BUCKET", "soulbios-data")
        
        # Performance
        self.max_cached_users = int(os.getenv("MAX_CACHED_USERS", "100"))
        self.request_timeout = int(os.getenv("REQUEST_TIMEOUT", "30"))
        
        # Logging
        self.log_level = os.getenv("LOG_LEVEL", "INFO")
    
    def _get_secret(self, secret_name: str) -> Optional[str]:
        """Get secret from AWS Secrets Manager or environment variable"""
        if self.is_production or self.is_staging:
            try:
                session = boto3.Session()
                client = session.client('secretsmanager', region_name=self.aws_region)
                response = client.get_secret_value(SecretId=f"SoulBios/{secret_name}")
                return response['SecretString']
            except Exception as e:
                logging.warning(f"Failed to get secret {secret_name} from AWS: {e}")
                return os.getenv(secret_name)
        else:
            return os.getenv(secret_name)
    
    def get_redis_client(self) -> Optional[redis.Redis]:
        """Get Redis client for caching"""
        try:
            return redis.Redis(
                host=self.redis_host,
                port=self.redis_port,
                password=self.redis_password,
                decode_responses=True,
                socket_connect_timeout=5,
                socket_timeout=5,
                retry_on_timeout=True
            )
        except Exception as e:
            logging.error(f"Failed to connect to Redis: {e}")
            return None
    
    def setup_logging(self):
        """Configure logging for production"""
        logging.basicConfig(
            level=getattr(logging, self.log_level),
            format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
            handlers=[
                logging.StreamHandler(),
                logging.FileHandler('soulbios_api.log') if self.is_production else logging.NullHandler()
            ]
        )
# Global configuration instance
config = ProductionConfig()