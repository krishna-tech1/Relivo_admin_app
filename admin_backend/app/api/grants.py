"""
Grants API Endpoints

Provides endpoints for:
- Public grant access (verified & active only)
- Admin grant management (CRUD)
- Grant verification workflow
- Grants.gov import
"""

from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session, joinedload

from db import models
from app.schemas import grant as schemas
from app.api import deps
from db.session import get_db
from app.services.grants_gov_importer import GrantsGovImporter

router = APIRouter(
    prefix="/grants",
    tags=["grants"]
)

# ============================================================================
# PUBLIC ENDPOINTS (No Auth Required)
# ============================================================================


# ============================================================================
# PUBLIC ENDPOINTS - MOVED TO USER BACKEND
# ============================================================================





# ============================================================================
# USER ENDPOINTS - MOVED TO USER BACKEND
# ============================================================================


# ADMIN ENDPOINTS (Auth Required)
# ============================================================================

@router.get("/admin/verified", response_model=List[schemas.Grant])
def get_verified_grants(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(deps.get_current_admin_user)
):
    """
    Get all verified grants (admin only).
    """
    grants = db.query(models.Grant).options(joinedload(models.Grant.creator)).filter(
        models.Grant.is_verified == True
    ).order_by(models.Grant.created_at.desc()).offset(skip).limit(limit).all()
    return grants


@router.get("/admin/unverified", response_model=List[schemas.Grant])
def get_unverified_grants(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(deps.get_current_admin_user)
):
    """
    Get all unverified grants (admin only).
    """
    grants = db.query(models.Grant).options(joinedload(models.Grant.creator)).filter(
        models.Grant.is_verified == False
    ).order_by(models.Grant.created_at.desc()).offset(skip).limit(limit).all()
    return grants


@router.get("/admin/all", response_model=List[schemas.Grant])
def get_all_grants_admin(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(deps.get_current_admin_user)
):
    """
    Get all grants regardless of verification status (admin only).
    """
    grants = db.query(models.Grant).options(joinedload(models.Grant.creator)).order_by(
        models.Grant.created_at.desc()
    ).offset(skip).limit(limit).all()
    return grants


@router.post("/admin", response_model=schemas.Grant)
def create_grant(
    grant_in: schemas.GrantCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(deps.get_current_admin_user)
):
    """
    Create new grant (admin only).
    """
    grant = models.Grant(**grant_in.dict())
    grant.creator_id = current_user.id
    db.add(grant)
    db.commit()
    db.refresh(grant)
    return grant


@router.put("/admin/{grant_id}", response_model=schemas.Grant)
def update_grant(
    grant_id: int,
    grant_in: schemas.GrantUpdate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(deps.get_current_admin_user)
):
    """
    Update a grant (admin only).
    Supports partial updates - only provided fields are updated.
    """
    grant = db.query(models.Grant).filter(models.Grant.id == grant_id).first()
    if not grant:
        raise HTTPException(status_code=404, detail="Grant not found")
    
    # Update only provided fields
    update_data = grant_in.dict(exclude_unset=True)
    for field, value in update_data.items():
        setattr(grant, field, value)
    
    db.add(grant)
    db.commit()
    db.refresh(grant)
    return grant


@router.delete("/admin/{grant_id}")
def delete_grant(
    grant_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(deps.get_current_admin_user)
):
    """
    Delete a grant (admin only).
    """
    grant = db.query(models.Grant).filter(models.Grant.id == grant_id).first()
    if not grant:
        raise HTTPException(status_code=404, detail="Grant not found")
    
    db.delete(grant)
    db.commit()
    return {"message": "Grant deleted successfully", "id": grant_id}


# ============================================================================
# VERIFICATION ENDPOINTS
# ============================================================================

@router.put("/admin/{grant_id}/verify", response_model=schemas.Grant)
def verify_grant(
    grant_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(deps.get_current_admin_user)
):
    """
    Verify a grant - makes it visible to public users.
    Sets is_verified = True.
    """
    grant = db.query(models.Grant).filter(models.Grant.id == grant_id).first()
    if not grant:
        raise HTTPException(status_code=404, detail="Grant not found")
    
    grant.is_verified = True
    db.commit()
    db.refresh(grant)
    return grant


@router.put("/admin/{grant_id}/unverify", response_model=schemas.Grant)
def unverify_grant(
    grant_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(deps.get_current_admin_user)
):
    """
    Unverify a grant - hides it from public users.
    Sets is_verified = False.
    """
    grant = db.query(models.Grant).filter(models.Grant.id == grant_id).first()
    if not grant:
        raise HTTPException(status_code=404, detail="Grant not found")
    
    grant.is_verified = False
    db.commit()
    db.refresh(grant)
    return grant


@router.put("/admin/{grant_id}/activate", response_model=schemas.Grant)
def activate_grant(
    grant_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(deps.get_current_admin_user)
):
    """
    Activate a grant.
    Sets is_active = True.
    """
    grant = db.query(models.Grant).filter(models.Grant.id == grant_id).first()
    if not grant:
        raise HTTPException(status_code=404, detail="Grant not found")
    
    grant.is_active = True
    db.commit()
    db.refresh(grant)
    return grant


@router.put("/admin/{grant_id}/deactivate", response_model=schemas.Grant)
def deactivate_grant(
    grant_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(deps.get_current_admin_user)
):
    """
    Deactivate a grant - hides it from public even if verified.
    Sets is_active = False.
    """
    grant = db.query(models.Grant).filter(models.Grant.id == grant_id).first()
    if not grant:
        raise HTTPException(status_code=404, detail="Grant not found")
    
    grant.is_active = False
    db.commit()
    db.refresh(grant)
    return grant


# ============================================================================
# GRANTS.GOV IMPORT ENDPOINT
# ============================================================================

@router.post("/admin/import", response_model=schemas.GrantImportResult)
def import_grants_from_grants_gov(
    xml_url: Optional[str] = Query(None, description="Optional custom URL for XML extract"),
    db: Session = Depends(get_db),
    current_user: models.User = Depends(deps.get_current_admin_user)
):
    """
    Import grants from Grants.gov XML extract (admin only).
    
    Downloads the latest XML extract, parses it, and imports new grants.
    Existing grants (matched by external_id) are skipped to preserve admin edits.
    
    Returns:
        GrantImportResult with counts of imported, skipped, and errors
    """
    importer = GrantsGovImporter(db)
    result = importer.import_grants(xml_url=xml_url)
    
    return schemas.GrantImportResult(
        imported=result["imported"],
        skipped=result["skipped"],
        errors=result["errors"]
    )


# ============================================================================
# STATISTICS ENDPOINT
# ============================================================================

@router.get("/admin/stats")
def get_grant_statistics(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(deps.get_current_admin_user)
):
    """
    Get grant statistics (admin only).
    """
    total = db.query(models.Grant).count()
    verified = db.query(models.Grant).filter(models.Grant.is_verified == True).count()
    unverified = db.query(models.Grant).filter(models.Grant.is_verified == False).count()
    active = db.query(models.Grant).filter(models.Grant.is_active == True).count()
    from_grants_gov = db.query(models.Grant).filter(models.Grant.source == "grants.gov").count()
    manual = db.query(models.Grant).filter(models.Grant.source == "manual").count()
    
    return {
        "total": total,
        "verified": verified,
        "unverified": unverified,
        "active": active,
        "inactive": total - active,
        "from_grants_gov": from_grants_gov,
        "manual": manual
    }


@router.post("/admin/migrate-schema")
def migrate_schema(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(deps.get_current_admin_user)
):
    """
    Migrate database schema from old to new structure (admin only).
    Renames 'provider' to 'organizer' and 'location' to 'refugee_country'.
    Adds missing columns if they don't exist.
    """
    from sqlalchemy import text, inspect
    
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
            'category': 'VARCHAR(100) DEFAULT \'General\'',
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
            "message": "Schema migration completed successfully",
            "migrations_applied": migrations_applied,
            "total_migrations": len(migrations_applied)
        }
        
    except Exception as e:
        db.rollback()
        return {
            "error": f"Migration failed: {str(e)}",
            "message": "Please check the error and try again or contact support."
        }


@router.post("/admin/fix-null-deadlines")
def fix_null_deadlines(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(deps.get_current_admin_user)
):
    """
    Fix grants with NULL deadlines by setting them to a default date (admin only).
    Sets NULL deadlines to 30 days from now.
    """
    from datetime import datetime, timedelta
    from sqlalchemy import text
    
    try:
        # Count grants with NULL deadlines
        null_deadline_count = db.query(models.Grant).filter(
            models.Grant.deadline == None
        ).count()
        
        if null_deadline_count == 0:
            return {
                "message": "No grants with NULL deadlines found.",
                "fixed": 0
            }
        
        # Set default deadline to 30 days from now
        default_deadline = datetime.now() + timedelta(days=30)
        
        # Update grants with NULL deadlines
        db.execute(
            text("UPDATE grants SET deadline = :deadline WHERE deadline IS NULL"),
            {"deadline": default_deadline}
        )
        
        db.commit()
        
        return {
            "message": f"Successfully fixed {null_deadline_count} grants with NULL deadlines",
            "fixed": null_deadline_count,
            "default_deadline": default_deadline.isoformat()
        }
        
    except Exception as e:
        db.rollback()
        return {
            "error": f"Failed to fix NULL deadlines: {str(e)}",
            "message": "Please check the error and try again."
        }


@router.post("/admin/seed")
def seed_database(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(deps.get_current_admin_user)
):
    """
    Seed database with sample grants (admin only).
    Only seeds if database is empty.
    """
    from datetime import datetime
    
    # Check if grants already exist
    existing_count = db.query(models.Grant).count()
    if existing_count > 0:
        return {
            "message": f"Database already has {existing_count} grants. Skipping seed.",
            "seeded": 0,
            "existing": existing_count
        }
    
    # Sample grants data
    grants_data = [
        {
            "title": "Emergency Housing Assistance",
            "organizer": "UN Refugee Agency",
            "refugee_country": "Germany",
            "category": "Housing",
            "deadline": datetime(2026, 2, 15),
            "amount": "€5,000",
            "description": "Financial assistance for refugees seeking emergency housing solutions.",
            "apply_url": "https://www.unhcr.org/housing-assistance",
            "is_verified": True,
            "is_active": True,
            "source": "manual"
        },
        {
            "title": "Education & Training Grant",
            "organizer": "European Education Foundation",
            "refugee_country": "France",
            "category": "Education",
            "deadline": datetime(2026, 3, 30),
            "amount": "€3,500",
            "description": "Support for refugees pursuing education and vocational training.",
            "apply_url": "https://www.eef.org/education-grants",
            "is_verified": True,
            "is_active": True,
            "source": "manual"
        },
        {
            "title": "Healthcare Support Fund",
            "organizer": "International Medical Corps",
            "refugee_country": "Sweden",
            "category": "Healthcare",
            "deadline": datetime(2026, 2, 28),
            "amount": "€2,000",
            "description": "Medical assistance for refugees requiring healthcare services.",
            "apply_url": "https://www.imc.org/healthcare-fund",
            "is_verified": True,
            "is_active": True,
            "source": "manual"
        },
        {
            "title": "Small Business Startup Grant",
            "organizer": "Refugee Entrepreneurship Network",
            "refugee_country": "Netherlands",
            "category": "Employment",
            "deadline": datetime(2026, 4, 15),
            "amount": "€8,000",
            "description": "Funding for refugees looking to start their own small business.",
            "apply_url": "https://www.ren.org/startup-grants",
            "is_verified": True,
            "is_active": True,
            "source": "manual"
        },
        {
            "title": "Family Reunification Support",
            "organizer": "Red Cross International",
            "refugee_country": "Belgium",
            "category": "Legal",
            "deadline": datetime(2026, 3, 10),
            "amount": "€4,500",
            "description": "Legal and financial assistance for family reunification.",
            "apply_url": "https://www.redcross.org/family-reunification",
            "is_verified": True,
            "is_active": True,
            "source": "manual"
        },
        {
            "title": "Unverified Test Grant",
            "organizer": "Test Organization",
            "refugee_country": "Spain",
            "category": "General",
            "deadline": datetime(2026, 5, 1),
            "amount": "€1,000",
            "description": "Test grant for admin verification workflow.",
            "apply_url": "https://www.test.org/grant",
            "is_verified": False,
            "is_active": True,
            "source": "manual"
        }
    ]
    
    # Add grants to database
    for data in grants_data:
        grant = models.Grant(**data)
        db.add(grant)
    
    db.commit()
    
    return {
        "message": "Database seeded successfully",
        "seeded": len(grants_data),
        "verified": 5,
        "unverified": 1
    }
