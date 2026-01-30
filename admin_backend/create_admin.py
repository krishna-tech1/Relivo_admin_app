import sys
import os

# Improve path handling to find 'app' and 'db'
sys.path.append(os.getcwd())

from sqlalchemy.orm import Session
from db.session import SessionLocal
from db import models
from app.core.security import get_password_hash

def create_admin(email, password, name="Admin User"):
    db = SessionLocal()
    try:
        user = db.query(models.User).filter(models.User.email == email).first()
        if user:
            print(f"User {email} already exists. Updating to admin...")
            user.role = "admin"
            user.hashed_password = get_password_hash(password)
            user.is_verified = True
            db.commit()
            print(f"User {email} updated to admin successfully.")
        else:
            print(f"Creating admin user {email}...")
            user = models.User(
                email=email,
                hashed_password=get_password_hash(password),
                full_name=name,
                role="admin",
                is_verified=True
            )
            db.add(user)
            db.commit()
            print(f"Admin user {email} created successfully.")
            
    except Exception as e:
        print(f"Error creating admin: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    create_admin("admin@relivo.app", "admin123")
