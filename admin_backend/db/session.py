import os
import logging
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import NullPool
from app.core.config import settings

logger = logging.getLogger(__name__)

if not settings.DATABASE_URL:
    raise ValueError("DATABASE_URL is not set in .env")

DATABASE_URL = settings.DATABASE_URL
logger.info(f"Connecting to database: {DATABASE_URL.split('@')[0]}@***")  # Hide credentials in logs

# Configure engine with appropriate settings
# For PostgreSQL, use connection pooling; for SQLite, use NullPool
if DATABASE_URL.startswith("sqlite"):
    engine = create_engine(
        DATABASE_URL,
        connect_args={"check_same_thread": False},  # SQLite specific
        poolclass=NullPool
    )
else:
    # PostgreSQL configuration
    engine = create_engine(
        DATABASE_URL,
        pool_pre_ping=True,  # Verify connections before using them
        pool_size=5,
        max_overflow=10,
        pool_recycle=3600,  # Recycle connections after 1 hour
    )

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

def get_db():
    """Database session dependency"""
    db = SessionLocal()
    try:
        yield db
    except Exception as e:
        logger.error(f"Database session error: {e}")
        db.rollback()
        raise
    finally:
        db.close()
