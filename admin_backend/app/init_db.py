import sys
import os

# Ensure the parent directory is in sys.path so we can import modules
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from db.session import engine, Base
# Import all models so they are registered with Base.metadata
import db.models 

def init_db():
    print("Creating database tables...")
    Base.metadata.create_all(bind=engine)
    print("Tables created successfully!")

if __name__ == "__main__":
    init_db()
