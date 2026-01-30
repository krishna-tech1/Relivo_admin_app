import sys
import os

# Improve path handling
sys.path.append(os.getcwd())

from sqlalchemy import text
from db.session import engine

def update_schema():
    print("Updating schema to add Apply URL and JSON lists...")
    try:
        with engine.connect() as connection:
            # 1. Add apply_url column
            try:
                connection.execute(text("ALTER TABLE grants ADD COLUMN apply_url VARCHAR;"))
                print("Added apply_url column.")
            except Exception as e:
                print(f"info: apply_url might already exist: {e}")

            # 2. Add eligibility_criteria (JSON)
            try:
                connection.execute(text("ALTER TABLE grants ADD COLUMN eligibility_criteria JSON;"))
                print("Added eligibility_criteria column.")
            except Exception as e:
                print(f"info: eligibility_criteria might already exist: {e}")

            # 3. Add required_documents (JSON)
            try:
                connection.execute(text("ALTER TABLE grants ADD COLUMN required_documents JSON;"))
                print("Added required_documents column.")
            except Exception as e:
                print(f"info: required_documents might already exist: {e}")
                
            connection.commit()
            print("Schema update completed.")
            
    except Exception as e:
        print(f"Critical error updating schema: {e}")

if __name__ == "__main__":
    update_schema()
