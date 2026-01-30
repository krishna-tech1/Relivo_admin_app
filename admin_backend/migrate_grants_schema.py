"""
Database Migration Script for Grants.gov Integration

This script updates the grants table to support:
- Source tracking (manual vs grants.gov)
- External ID for deduplication
- Verification workflow
- Refugee country assignment
- Active/inactive status

Run this script to migrate existing database schema.
"""

from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")

if not DATABASE_URL:
    raise Exception("DATABASE_URL not found in environment variables")

# Create engine
engine = create_engine(DATABASE_URL)
Session = sessionmaker(bind=engine)

def migrate_grants_table():
    """Add new columns to grants table"""
    
    session = Session()
    
    try:
        print("Starting migration...")
        
        # Add new columns (using ALTER TABLE for existing databases)
        migrations = [
            # Rename provider to organizer
            """
            DO $$
            BEGIN
                IF EXISTS(SELECT 1 FROM information_schema.columns 
                         WHERE table_name='grants' AND column_name='provider') THEN
                    ALTER TABLE grants RENAME COLUMN provider TO organizer;
                END IF;
            END $$;
            """,
            
            # Add eligibility column
            """
            DO $$
            BEGIN
                IF NOT EXISTS(SELECT 1 FROM information_schema.columns 
                             WHERE table_name='grants' AND column_name='eligibility') THEN
                    ALTER TABLE grants ADD COLUMN eligibility VARCHAR;
                END IF;
            END $$;
            """,
            
            # Add source column
            """
            DO $$
            BEGIN
                IF NOT EXISTS(SELECT 1 FROM information_schema.columns 
                             WHERE table_name='grants' AND column_name='source') THEN
                    ALTER TABLE grants ADD COLUMN source VARCHAR DEFAULT 'manual';
                    CREATE INDEX IF NOT EXISTS idx_grants_source ON grants(source);
                END IF;
            END $$;
            """,
            
            # Add external_id column
            """
            DO $$
            BEGIN
                IF NOT EXISTS(SELECT 1 FROM information_schema.columns 
                             WHERE table_name='grants' AND column_name='external_id') THEN
                    ALTER TABLE grants ADD COLUMN external_id VARCHAR UNIQUE;
                    CREATE INDEX IF NOT EXISTS idx_grants_external_id ON grants(external_id);
                END IF;
            END $$;
            """,
            
            # Add refugee_country column
            """
            DO $$
            BEGIN
                IF NOT EXISTS(SELECT 1 FROM information_schema.columns 
                             WHERE table_name='grants' AND column_name='refugee_country') THEN
                    ALTER TABLE grants ADD COLUMN refugee_country VARCHAR;
                    CREATE INDEX IF NOT EXISTS idx_grants_refugee_country ON grants(refugee_country);
                END IF;
            END $$;
            """,
            
            # Add is_verified column
            """
            DO $$
            BEGIN
                IF NOT EXISTS(SELECT 1 FROM information_schema.columns 
                             WHERE table_name='grants' AND column_name='is_verified') THEN
                    ALTER TABLE grants ADD COLUMN is_verified BOOLEAN DEFAULT FALSE;
                    CREATE INDEX IF NOT EXISTS idx_grants_is_verified ON grants(is_verified);
                END IF;
            END $$;
            """,
            
            # Add is_active column
            """
            DO $$
            BEGIN
                IF NOT EXISTS(SELECT 1 FROM information_schema.columns 
                             WHERE table_name='grants' AND column_name='is_active') THEN
                    ALTER TABLE grants ADD COLUMN is_active BOOLEAN DEFAULT TRUE;
                    CREATE INDEX IF NOT EXISTS idx_grants_is_active ON grants(is_active);
                END IF;
            END $$;
            """,
            
            # Update existing grants to be verified (backward compatibility)
            """
            UPDATE grants 
            SET is_verified = TRUE, is_active = TRUE, source = 'manual'
            WHERE is_verified IS NULL OR is_active IS NULL OR source IS NULL;
            """,
            
            # Make apply_url NOT NULL (if it was nullable before)
            """
            DO $$
            BEGIN
                UPDATE grants SET apply_url = '' WHERE apply_url IS NULL;
                ALTER TABLE grants ALTER COLUMN apply_url SET NOT NULL;
            END $$;
            """
        ]
        
        for i, migration in enumerate(migrations, 1):
            print(f"Running migration {i}/{len(migrations)}...")
            session.execute(text(migration))
            session.commit()
        
        print("✅ Migration completed successfully!")
        print("\nNew schema includes:")
        print("  - organizer (renamed from provider)")
        print("  - eligibility (text field)")
        print("  - source (manual/grants.gov)")
        print("  - external_id (for deduplication)")
        print("  - refugee_country (admin assignment)")
        print("  - is_verified (verification status)")
        print("  - is_active (active/disabled)")
        
    except Exception as e:
        session.rollback()
        print(f"❌ Migration failed: {str(e)}")
        raise
    finally:
        session.close()

if __name__ == "__main__":
    print("=" * 60)
    print("Grants Table Migration for Grants.gov Integration")
    print("=" * 60)
    print()
    
    response = input("This will modify the grants table. Continue? (yes/no): ")
    if response.lower() == 'yes':
        migrate_grants_table()
    else:
        print("Migration cancelled.")
