"""
Database Initialization Script
Comprehensive script to initialize the database with proper error handling
"""
import sys
import os
import logging

# Add current directory to path
sys.path.append(os.getcwd())

from db.session import engine, Base, SessionLocal
from db import models
from sqlalchemy import inspect, text

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


def check_database_connection():
    """Test database connection"""
    try:
        with engine.connect() as conn:
            conn.execute(text("SELECT 1"))
        logger.info("✅ Database connection successful")
        return True
    except Exception as e:
        logger.error(f"❌ Database connection failed: {e}")
        return False


def get_existing_tables():
    """Get list of existing tables"""
    inspector = inspect(engine)
    return inspector.get_table_names()


def create_tables():
    """Create all database tables"""
    try:
        logger.info("Creating database tables...")
        
        # Get existing tables
        existing_tables = get_existing_tables()
        logger.info(f"Existing tables: {existing_tables}")
        
        # Create all tables
        Base.metadata.create_all(bind=engine)
        
        # Verify tables were created
        new_tables = get_existing_tables()
        logger.info(f"Tables after creation: {new_tables}")
        
        created_tables = set(new_tables) - set(existing_tables)
        if created_tables:
            logger.info(f"✅ Created new tables: {created_tables}")
        else:
            logger.info("✅ All tables already exist")
        
        return True
    except Exception as e:
        logger.error(f"❌ Error creating tables: {e}")
        return False


def verify_schema():
    """Verify database schema"""
    try:
        inspector = inspect(engine)
        
        # Check each model
        for model_name in ['users', 'verification_codes', 'grants']:
            if model_name in inspector.get_table_names():
                columns = [col['name'] for col in inspector.get_columns(model_name)]
                logger.info(f"✅ Table '{model_name}' columns: {columns}")
            else:
                logger.warning(f"⚠️  Table '{model_name}' not found")
        
        return True
    except Exception as e:
        logger.error(f"❌ Error verifying schema: {e}")
        return False


def main():
    """Main initialization function"""
    logger.info("=" * 60)
    logger.info("DATABASE INITIALIZATION")
    logger.info("=" * 60)
    
    # Step 1: Check connection
    if not check_database_connection():
        logger.error("Cannot proceed without database connection")
        sys.exit(1)
    
    # Step 2: Create tables
    if not create_tables():
        logger.error("Failed to create tables")
        sys.exit(1)
    
    # Step 3: Verify schema
    if not verify_schema():
        logger.warning("Schema verification had issues")
    
    logger.info("=" * 60)
    logger.info("✅ DATABASE INITIALIZATION COMPLETE")
    logger.info("=" * 60)


if __name__ == "__main__":
    main()
