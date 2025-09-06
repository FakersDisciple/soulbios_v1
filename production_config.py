# production_config.py
# Defines static configuration that doesn't change.
# All secret/dynamic configuration is now handled by config/settings.py

class ProductionConfig:
    """
    A simple container for non-sensitive, static configuration variables.
    """
    # Define the list of allowed origins for CORS.
    # Update this list with your actual frontend domains for production.
    cors_origins = [
        "http://localhost",
        "http://localhost:8080",
        "http://localhost:3000",
        # e.g., "https://your-flutter-app-domain.com"
    ]

# Global configuration instance
config = ProductionConfig()