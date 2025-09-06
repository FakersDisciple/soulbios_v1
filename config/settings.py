# config/settings.py

import os
from dotenv import load_dotenv

# Load environment variables from .env file for local development
load_dotenv()

class Settings:
    """
    Central configuration for the SoulBios application.
    - Reads from environment variables.
    - Provides a single, validated source of truth for configuration.
    """
    # --- Google AI Configuration ---
    # The application code now refers to GEMINI_API_KEY for clarity.
    # We read the GOOGLE_API_KEY from the environment (set by Secret Manager)
    # and assign it to the GEMINI_API_KEY attribute.
    GEMINI_API_KEY: str = os.getenv("GOOGLE_API_KEY")

    # --- Security Configuration ---
    SOULBIOS_API_KEY: str = os.getenv("SOULBIOS_API_KEY")

    # --- Database Configuration ---
    # This will be injected by Secret Manager in the deployed environment.
    # For local testing, you would add a DATABASE_URL to your .env file.
    DATABASE_URL: str = os.getenv("DATABASE_URL")

    # --- Redis Configuration (Optional) ---
    # The application is designed to work without Redis if this is not set.
    REDIS_URL: str = os.getenv("REDIS_URL") # More flexible than host/port


# Create a single instance of the settings to be imported by other modules
settings = Settings()

# --- Validation for Deployed Environment ---
# In a deployed environment, these variables are critical.
# We can check if we are in a production environment (set by deploy.sh)
if os.getenv("ENVIRONMENT") == "production":
    if not settings.GEMINI_API_KEY:
        raise ValueError("CRITICAL: GOOGLE_API_KEY is not set in the production environment.")
    if not settings.SOULBIOS_API_KEY:
        raise ValueError("CRITICAL: SOULBIOS_API_KEY is not set in the production environment.")
    if not settings.DATABASE_URL:
        raise ValueError("CRITICAL: DATABASE_URL is not set in the production environment.")