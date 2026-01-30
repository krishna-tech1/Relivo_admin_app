import sys
import os
from datetime import datetime

# Improve path handling to find 'app' and 'db'
sys.path.append(os.getcwd())

from sqlalchemy.orm import Session
from db.session import SessionLocal
from db import models

def seed_grants():
    db = SessionLocal()
    try:
        # Check if grants already exist to avoid duplicates
        if db.query(models.Grant).count() > 0:
            print("Grants table already has data. Skipping seed.")
            return

        print("Seeding grants...")

        grants_data = [
            {
                "title": "Emergency Housing Assistance",
                "organizer": "UN Refugee Agency",
                "refugee_country": "Germany",
                "deadline": datetime(2026, 2, 15),
                "amount": "€5,000",
                "description": "Financial assistance for refugees seeking emergency housing solutions. This grant covers rent deposits, first month's rent, and essential furniture.",
                "apply_url": "https://www.unhcr.org/housing-assistance",
                "is_verified": True,
                "is_active": True
            },
            {
                "title": "Education & Training Grant",
                "organizer": "European Education Foundation",
                "refugee_country": "France",
                "deadline": datetime(2026, 3, 30),
                "amount": "€3,500",
                "description": "Support for refugees pursuing education, vocational training, or professional certification programs.",
                "apply_url": "https://www.eef.org/education-grants",
                "is_verified": True,
                "is_active": True
            },
            {
                "title": "Healthcare Support Fund",
                "organizer": "International Medical Corps",
                "refugee_country": "Sweden",
                "deadline": datetime(2026, 2, 28),
                "amount": "€2,000",
                "description": "Medical assistance for refugees requiring healthcare services not covered by standard insurance.",
                "apply_url": "https://www.imc.org/healthcare-fund",
                "is_verified": True,
                "is_active": True
            },
            {
                "title": "Small Business Startup Grant",
                "organizer": "Refugee Entrepreneurship Network",
                "refugee_country": "Netherlands",
                "deadline": datetime(2026, 4, 15),
                "amount": "€8,000",
                "description": "Funding for refugees looking to start their own small business or social enterprise.",
                "apply_url": "https://www.ren.org/startup-grants",
                "is_verified": True,
                "is_active": True
            },
            {
                "title": "Family Reunification Support",
                "organizer": "Red Cross International",
                "refugee_country": "Belgium",
                "deadline": datetime(2026, 3, 10),
                "amount": "€4,500",
                "description": "Legal and financial assistance for family reunification processes.",
                "apply_url": "https://www.redcross.org/family-reunification",
                "is_verified": True,
                "is_active": True
            },
            {
                "title": "Unverified Test Grant",
                "organizer": "Test Organization",
                "refugee_country": "Spain",
                "deadline": datetime(2026, 5, 1),
                "amount": "€1,000",
                "description": "This is a test grant that is unverified for admin testing purposes.",
                "apply_url": "https://www.test.org/grant",
                "is_verified": False,
                "is_active": True
            }
        ]

        for data in grants_data:
            grant = models.Grant(**data)
            db.add(grant)
        
        db.commit()
        print("Successfully seeded 6 grants (5 verified, 1 unverified).")

    except Exception as e:
        print(f"Error seeding grants: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    seed_grants()
