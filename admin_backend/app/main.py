from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import logging

from app.api import auth
from db.session import engine, Base
import db.models # Import models to ensure they are registered with Base

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="Refugee App Backend", version="1.0.0")

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # In production, replace with specific origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Startup event to create tables
@app.on_event("startup")
async def startup_event():
    """Create database tables on startup"""
    try:
        logger.info("Creating database tables...")
        Base.metadata.create_all(bind=engine)
        logger.info("✅ Database tables created successfully")
    except Exception as e:
        logger.error(f"❌ Error creating tables: {e}")
        # Don't crash the app, tables might already exist
        logger.warning("Continuing without creating tables - they may already exist")

# Include routers
app.include_router(auth.router)
from app.api import grants
app.include_router(grants.router)

@app.get("/")
async def root():
    return {
        "message": "Refugee App Backend is running",
        "version": "1.0.0",
        "status": "healthy"
    }

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    try:
        # Test database connection
        from db.session import SessionLocal
        from sqlalchemy import text
        db = SessionLocal()
        db.execute(text("SELECT 1"))
        db.close()
        return {"status": "healthy", "database": "connected"}
    except Exception as e:
        return {"status": "unhealthy", "database": "disconnected", "error": str(e)}


@app.post("/migrate-database")
async def migrate_database_public():
    """
    PUBLIC endpoint to migrate database schema.
    This is a temporary endpoint to fix schema issues.
    TODO: Remove this endpoint after migration is complete.
    """
    from db.session import SessionLocal
    from sqlalchemy import text, inspect
    
    db = SessionLocal()
    try:
        # Get database inspector
        inspector = inspect(db.bind)
        
        # Check if grants table exists
        if 'grants' not in inspector.get_table_names():
            return {
                "error": "Grants table does not exist. Tables will be created on next startup.",
                "action": "Restart the application to create tables."
            }
        
        # Get existing columns
        existing_columns = [col['name'] for col in inspector.get_columns('grants')]
        migrations_applied = []
        
        # Migration 1: Rename 'provider' to 'organizer' if needed
        if 'provider' in existing_columns and 'organizer' not in existing_columns:
            db.execute(text('ALTER TABLE grants RENAME COLUMN provider TO organizer'))
            migrations_applied.append("Renamed 'provider' to 'organizer'")
        elif 'organizer' not in existing_columns:
            db.execute(text('ALTER TABLE grants ADD COLUMN organizer VARCHAR(200)'))
            migrations_applied.append("Added 'organizer' column")
        
        # Migration 2: Rename 'location' to 'refugee_country' if needed  
        if 'location' in existing_columns and 'refugee_country' not in existing_columns:
            db.execute(text('ALTER TABLE grants RENAME COLUMN location TO refugee_country'))
            migrations_applied.append("Renamed 'location' to 'refugee_country'")
        elif 'refugee_country' not in existing_columns:
            db.execute(text('ALTER TABLE grants ADD COLUMN refugee_country VARCHAR(100)'))
            migrations_applied.append("Added 'refugee_country' column")
        
        # Migration 3: Add missing columns
        column_definitions = {
            'eligibility': 'TEXT',
            'apply_url': 'VARCHAR(500)',
            'source': "VARCHAR(50) DEFAULT 'manual'",
            'external_id': 'VARCHAR(100)',
            'is_verified': 'BOOLEAN DEFAULT FALSE',
            'is_active': 'BOOLEAN DEFAULT TRUE',
            'eligibility_criteria': 'JSON',
            'required_documents': 'JSON',
        }
        
        for column_name, column_type in column_definitions.items():
            if column_name not in existing_columns:
                db.execute(text(f'ALTER TABLE grants ADD COLUMN {column_name} {column_type}'))
                migrations_applied.append(f"Added '{column_name}' column")
        
        # Migration 4: Update existing data defaults
        if migrations_applied:
            # Set default apply_url for existing records
            db.execute(text("UPDATE grants SET apply_url = 'https://example.com/apply' WHERE apply_url IS NULL"))
            # Set default source for existing records
            db.execute(text("UPDATE grants SET source = 'manual' WHERE source IS NULL"))
            # Set default is_verified for existing records
            db.execute(text("UPDATE grants SET is_verified = FALSE WHERE is_verified IS NULL"))
            # Set default is_active for existing records
            db.execute(text("UPDATE grants SET is_active = TRUE WHERE is_active IS NULL"))
        
        db.commit()
        
        if not migrations_applied:
            return {
                "message": "Schema is already up to date. No migrations needed.",
                "migrations_applied": []
            }
        
        return {
            "message": "✅ Schema migration completed successfully! You can now use the app.",
            "migrations_applied": migrations_applied,
            "total_migrations": len(migrations_applied),
            "next_steps": [
                "Test: curl https://relivo-app.onrender.com/grants/public",
                "The app should now work correctly",
                "You can create grants from the admin panel"
            ]
        }
        
    except Exception as e:
        db.rollback()
        return {
            "error": f"Migration failed: {str(e)}",
            "message": "Please check the error and try again or contact support."
        }
    finally:
        db.close()


