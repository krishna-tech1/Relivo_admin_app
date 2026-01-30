import sys
import os

sys.path.append(os.getcwd())

from sqlalchemy import text
from db.session import engine

def run_migration():
    print("Starting Phase-2 Schema Migration...")
    
    with engine.connect() as connection:
        trans = connection.begin()
        try:
            # 1. Create Organizations Table
            print("Creating 'organizations' table...")
            connection.execute(text("""
                CREATE TABLE IF NOT EXISTS organizations (
                    id SERIAL PRIMARY KEY,
                    user_id INTEGER NOT NULL REFERENCES users(id),
                    name VARCHAR(200) NOT NULL,
                    description TEXT,
                    verification_documents JSON,
                    status VARCHAR(50) DEFAULT 'pending',
                    website VARCHAR(200),
                    contact_email VARCHAR(200),
                    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
                    updated_at TIMESTAMP WITH TIME ZONE
                );
            """))
            print("Organizations table established.")

            # 2. Add columns to Grants table
            print("Updating 'grants' table...")

            # Add creator_id
            try:
                connection.execute(text("ALTER TABLE grants ADD COLUMN creator_id INTEGER REFERENCES users(id);"))
                print("- Added creator_id column.")
            except Exception as e:
                print(f"- Info: creator_id might exist: {e}")

            # Add organization_id
            try:
                connection.execute(text("ALTER TABLE grants ADD COLUMN organization_id INTEGER REFERENCES organizations(id);"))
                print("- Added organization_id column.")
            except Exception as e:
                print(f"- Info: organization_id might exist: {e}")
                
            # Add rejection_reason
            try:
                connection.execute(text("ALTER TABLE grants ADD COLUMN rejection_reason TEXT;"))
                print("- Added rejection_reason column.")
            except Exception as e:
                print(f"- Info: rejection_reason might exist: {e}")

            trans.commit()
            print("Phase-2 Migration Completed Successfully.")

        except Exception as e:
            trans.rollback()
            print(f"Migration Failed: {e}")
            raise e

if __name__ == "__main__":
    run_migration()
