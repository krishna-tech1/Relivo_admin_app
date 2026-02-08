"""
Migration script to add rejection_reason column to organizations table
Run this script to update your existing database schema
"""

import os
import sys
from sqlalchemy import create_engine, text

# Add parent directory to path to import settings
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.core.config import settings

def migrate():
    """Add rejection_reason column to organizations table"""
    engine = create_engine(settings.DATABASE_URL)
    
    with engine.connect() as conn:
        # Check if column already exists
        result = conn.execute(text("""
            SELECT column_name 
            FROM information_schema.columns 
            WHERE table_name='organizations' AND column_name='rejection_reason'
        """))
        
        if result.fetchone():
            print("✓ Column 'rejection_reason' already exists in organizations table")
            return
        
        # Add the column
        print("Adding 'rejection_reason' column to organizations table...")
        conn.execute(text("""
            ALTER TABLE organizations 
            ADD COLUMN rejection_reason TEXT
        """))
        conn.commit()
        print("✓ Successfully added 'rejection_reason' column to organizations table")

if __name__ == "__main__":
    try:
        migrate()
        print("\n✓ Migration completed successfully!")
    except Exception as e:
        print(f"\n✗ Migration failed: {e}")
        sys.exit(1)
