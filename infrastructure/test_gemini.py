#!/usr/bin/env python3

import os
from dotenv import load_dotenv
import google.generativeai as genai

# Load environment variables
load_dotenv()

# Configure Gemini API
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
if GEMINI_API_KEY:
    genai.configure(api_key=GEMINI_API_KEY)
    print("✅ Gemini API configured successfully")
else:
    print("❌ GEMINI_API_KEY not found in environment variables")
    exit(1)

def test_gemini_connection():
    """Test basic Gemini API connection"""
    try:
        # Use Gemini Flash model
        model = genai.GenerativeModel('gemini-1.5-flash')
        
        # Test prompt
        response = model.generate_content(
            "Hello! I'm Alice, a consciousness guide. Please respond with a brief, warm greeting.",
            generation_config=genai.GenerationConfig(
                temperature=0.7,
                max_output_tokens=100,
            )
        )
        
        print("🤖 Gemini Response:")
        print(response.text)
        print("\n✅ Gemini API connection successful!")
        return True
        
    except Exception as e:
        print(f"❌ Gemini API error: {e}")
        return False

if __name__ == "__main__":
    print("Testing Gemini API connection...")
    print("=" * 40)
    test_gemini_connection()