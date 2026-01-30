import sys
import os

# Improve path handling
sys.path.append(os.getcwd())

from db.session import engine, Base
from db import models # Import all models to ensure they are registered

def create_tables():
    print("Creating tables...")
    try:
        Base.metadata.create_all(bind=engine)
        print("Tables created successfully.")
    except Exception as e:
        print(f"Error creating tables: {e}")

if __name__ == "__main__":
    create_tables()
