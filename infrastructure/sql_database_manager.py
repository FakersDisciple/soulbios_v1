"""
SQL Database Manager for SoulBios
Handles persistent user data storage using SQLAlchemy with async support.
"""

from datetime import datetime
from typing import Optional, List
import asyncio
import logging
from sqlalchemy import Column, Integer, String, DateTime, Text, ForeignKey, create_engine, text
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from sqlalchemy.sql import select
from sqlalchemy.exc import OperationalError
from pydantic import BaseModel
import asyncpg
from config.settings import settings

Base = declarative_base()

class User(Base):
    """User model for persistent storage"""
    __tablename__ = 'users'
    
    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(String, unique=True, index=True, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    subscription_status = Column(String, default='active')

class Conversation(Base):
    """Conversation model for persistent chat history"""
    __tablename__ = 'conversations'
    
    id = Column(Integer, primary_key=True, autoincrement=True)
    conversation_id = Column(String, unique=True, index=True, nullable=False)
    user_id = Column(String, ForeignKey("users.user_id"), nullable=False)
    request_message = Column(Text, nullable=False)
    response_message = Column(Text, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)

class UserSchema(BaseModel):
    """Pydantic schema for User"""
    id: int
    user_id: str
    created_at: datetime
    subscription_status: str
    
    class Config:
        from_attributes = True

class ConversationSchema(BaseModel):
    """Pydantic schema for Conversation"""
    id: int
    conversation_id: str
    user_id: str
    request_message: str
    response_message: str
    created_at: datetime
    
    class Config:
        from_attributes = True

class DatabaseManager:
    """Async database manager for SoulBios"""
    
    def __init__(self):
        self.engine = None
        self.async_session = None
        
    async def initialize(self, max_retries=5, delay_seconds=2):
        """
        Initializes the database connection with a retry mechanism to handle
        the Cloud SQL proxy startup race condition.
        """
        database_url = getattr(settings, 'DATABASE_URL', None)
        if not database_url:
            raise ValueError("DATABASE_URL not set in environment")

        # Convert postgres:// to postgresql+asyncpg:// if needed
        if database_url.startswith('postgres://'):
            database_url = database_url.replace('postgres://', 'postgresql+asyncpg://', 1)
        elif database_url.startswith('postgresql://'):
            database_url = database_url.replace('postgresql://', 'postgresql+asyncpg://', 1)
            
        self.engine = create_async_engine(database_url, echo=False)
        self.async_session = async_sessionmaker(
            bind=self.engine,
            class_=AsyncSession,
            expire_on_commit=False
        )
        
        # Create tables with retry logic for Cloud SQL proxy race condition
        for attempt in range(max_retries):
            try:
                logging.info(f"Attempting to connect to the database (Attempt {attempt + 1}/{max_retries})...")
                # The original crashing line is now inside the try block
                async with self.engine.begin() as conn:
                    # Test the connection first
                    await conn.execute(text("SELECT 1"))
                    # Create tables if connection is successful
                    await conn.run_sync(Base.metadata.create_all)
                logging.info("✅ Database connection successful.")
                return  # Exit the function on success
            except (OperationalError, FileNotFoundError) as e:
                logging.warning(f"Database connection failed: {e}")
                if attempt < max_retries - 1:
                    logging.info(f"Retrying in {delay_seconds} seconds...")
                    await asyncio.sleep(delay_seconds)
                else:
                    logging.error("❌ Critical: Could not establish database connection after all retries.")
                    raise  # Re-raise the final exception to cause the app to fail startup
    
    async def get_or_create_user(self, user_id: str) -> User:
        """Get existing user or create new one if doesn't exist"""
        if not self.async_session:
            await self.initialize()
            
        async with self.async_session() as session:
            # Try to find existing user
            result = await session.execute(select(User).where(User.user_id == user_id))
            user = result.scalar_one_or_none()
            
            if user:
                return user
            
            # Create new user if not found
            new_user = User(user_id=user_id)
            session.add(new_user)
            await session.commit()
            await session.refresh(new_user)
            return new_user
    
    async def save_conversation(self, user_id: str, conversation_id: str, request_message: str, response_message: str) -> None:
        """Save a conversation to the database"""
        if not self.async_session:
            await self.initialize()
            
        async with self.async_session() as session:
            conversation = Conversation(
                conversation_id=conversation_id,
                user_id=user_id,
                request_message=request_message,
                response_message=response_message
            )
            session.add(conversation)
            await session.commit()
    
    async def get_conversations_for_user(self, user_id: str, limit: int = 50) -> List[Conversation]:
        """Get conversations for a specific user, limited by count"""
        if not self.async_session:
            await self.initialize()
            
        async with self.async_session() as session:
            result = await session.execute(
                select(Conversation)
                .where(Conversation.user_id == user_id)
                .order_by(Conversation.created_at.desc())
                .limit(limit)
            )
            return result.scalars().all()
    
    async def close(self):
        """Close database connections"""
        if self.engine:
            await self.engine.dispose()

# Global database manager instance
db_manager = DatabaseManager()