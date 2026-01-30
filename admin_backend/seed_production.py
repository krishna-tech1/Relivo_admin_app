"""
Remote Database Seeder
Seeds the production Neon database with sample grants
Run this to populate the database on Render
"""
import sys
import os
from datetime import datetime

# Add current directory to path
sys.path.append(os.getcwd())

# Use production database URL

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from db import models

# Create engine with production URL
DATABASE_URL = os.environ['DATABASE_URL']
print(f"Connecting to production database...")

try:
    engine = create_engine(
        DATABASE_URL,
        pool_pre_ping=True,
        connect_args={'sslmode': 'require'}
    )
    SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    
    # Create tables
    print("Creating tables...")
    models.Base.metadata.create_all(bind=engine)
    print("✅ Tables created")
    
    # Seed data
    db = SessionLocal()
    try:
        # Check if grants already exist
        existing_count = db.query(models.Grant).count()
        if existing_count > 0:
            print(f"⚠️  Database already has {existing_count} grants. Skipping seed.")
            sys.exit(0)
        
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
                "is_active": True,
                "source": "manual"
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
                "is_active": True,
                "source": "manual"
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
                "is_active": True,
                "source": "manual"
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
                "is_active": True,
                "source": "manual"
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
                "is_active": True,
                "source": "manual"
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
                "is_active": True,
                "source": "manual"
            }
        ]
        
        for data in grants_data:
            grant = models.Grant(**data)
            db.add(grant)
        
        db.commit()
        print("✅ Successfully seeded 6 grants (5 verified, 1 unverified)")
        
    except Exception as e:
        print(f"❌ Error seeding grants: {e}")
        db.rollback()
        raise
    finally:
        db.close()
        
except Exception as e:
    print(f"❌ Connection/Setup Error: {e}")
    print("\nThis is likely due to:")
    print("1. DNS resolution issue (use VPN or different network)")
    print("2. Firewall blocking connection")
    print("3. Database credentials changed")
    sys.exit(1)

print("\n✅ Production database seeded successfully!")
print("Test with: curl https://relivo-app.onrender.com/grants/public")
