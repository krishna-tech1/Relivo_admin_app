from fastapi import APIRouter, Depends, HTTPException, status, BackgroundTasks
from sqlalchemy.orm import Session
import random
import string
from typing import Any

from db.session import get_db
from db import models
from app.core import security
from app.api import deps
from app.schemas import user as schemas, organization as org_schemas
from app.core.email_utils import send_verification_email
from pydantic import BaseModel, EmailStr
from typing import List, Optional

router = APIRouter(
    prefix="/auth",
    tags=["auth"]
)

def generate_verification_code():
    return ''.join(random.choices(string.digits, k=6))

@router.post("/register", response_model=Any)
def register(
    user_in: schemas.UserCreate, 
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db)
):
    """
    Register a new user.
    """
    try:
        # Check if user already exists
        user = db.query(models.User).filter(models.User.email == user_in.email).first()
        if user:
            if user.is_verified:
                raise HTTPException(status_code=400, detail="Email already registered")
            else:
                # User exists but is NOT verified (e.g. abandoned registration)
                # Overwrite their details and restart verification
                user.hashed_password = security.get_password_hash(user_in.password)
                user.full_name = user_in.full_name
                user.role = user_in.role
                
                # Cleanup any old codes
                db.query(models.VerificationCode).filter(models.VerificationCode.email == user_in.email).delete()
                
                # Create verification code
                code = generate_verification_code()
                db_code = models.VerificationCode(email=user_in.email, code=code)
                db.add(db_code)
                
                db.commit()
                db.refresh(user)
                
                # Send verification email in background
                background_tasks.add_task(send_verification_email, user_in.email, code)
                
                return {
                    "message": "Registration restarted. Check your email."
                }
        
        # Create new user
        db_user = models.User(
            email=user_in.email,
            hashed_password=security.get_password_hash(user_in.password),
            full_name=user_in.full_name,
            role=user_in.role, 
            is_verified=False
        )
        db.add(db_user)
        
        # Create verification code
        code = generate_verification_code()
        db_code = models.VerificationCode(email=user_in.email, code=code)
        db.add(db_code)
        
        db.commit()
        db.refresh(db_user)
        
        # Send verification email in background
        background_tasks.add_task(send_verification_email, user_in.email, code)
        
        return {
            "message": "User registered successfully"
        }
    except HTTPException as he:
        # Re-raise HTTP exceptions (like 400 Email already registered)
        raise he
    except Exception as e:
        print(f"❌ REGISTRATION ERROR: {str(e)}")
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Internal Server Error: {str(e)}")

class VerifyCodeSchema(BaseModel):
    email: EmailStr
    code: str

class EmailSchema(BaseModel):
    email: EmailStr

@router.post("/verify")
def verify_email_route(data: VerifyCodeSchema, db: Session = Depends(get_db)):
    db_code = db.query(models.VerificationCode).filter(
        models.VerificationCode.email == data.email,
        models.VerificationCode.code == data.code
    ).first()
    
    if not db_code:
        raise HTTPException(status_code=400, detail="Invalid verification code")
    
    user = db.query(models.User).filter(models.User.email == data.email).first()
    if user:
        user.is_verified = True
        db.delete(db_code) # Remove used code
        db.commit()
        db.refresh(user)
        
        # Generate token after verification
        access_token = security.create_access_token(
            subject=user.email,
            user_id=user.id,
            role=user.role
        )
        return {"access_token": access_token, "token_type": "bearer"}
    
    raise HTTPException(status_code=404, detail="User not found")

@router.post("/resend-code")
def resend_code(
    data: EmailSchema,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db)
):
    user = db.query(models.User).filter(models.User.email == data.email).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
        
    if user.is_verified:
        raise HTTPException(status_code=400, detail="User already verified")
        
    # Remove old codes
    db.query(models.VerificationCode).filter(models.VerificationCode.email == data.email).delete()
    
    # Create new code
    code = generate_verification_code()
    db_code = models.VerificationCode(email=data.email, code=code)
    db.add(db_code)
    db.commit()
    
    # Send email
    background_tasks.add_task(send_verification_email, data.email, code)
    
    return {"message": "Verification code resent"}

@router.post("/login", response_model=schemas.Token)
def login(user_in: schemas.UserLogin, db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.email == user_in.email).first()
    
    if not user:
        # USER REQUEST: Explicitly say email not registered
        raise HTTPException(status_code=404, detail="Email not registered")
        
    keyword_match = security.verify_password(user_in.password, user.hashed_password)
    
    if not keyword_match:
        # USER REQUEST: Explicitly say incorrect password
        raise HTTPException(status_code=401, detail="Incorrect password")
    
    if not user.is_verified:
        raise HTTPException(status_code=400, detail="Email not verified")
    
    access_token = security.create_access_token(
        subject=user.email,
        user_id=user.id,
        role=user.role
    )
    return {"access_token": access_token, "token_type": "bearer"}

@router.post("/forgot-password")
def forgot_password(
    data: EmailSchema,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db)
):
    """
    Send an OTP to the user's email for password reset.
    """
    user = db.query(models.User).filter(models.User.email == data.email).first()
    if not user:
        # For security, standard practice is to not reveal if email exists, 
        # BUT the user explicitly requested "shows the cause", so we will return 404 if not found for better UX as requested.
        raise HTTPException(status_code=404, detail="Email not registered")

    # Remove old codes
    db.query(models.VerificationCode).filter(models.VerificationCode.email == data.email).delete()
    
    # Create new code
    code = generate_verification_code()
    db_code = models.VerificationCode(email=data.email, code=code)
    db.add(db_code)
    db.commit()
    
    # Send email
    subject = "Reset Your Password - Relivo"
    heading = "Password Reset Code"
    background_tasks.add_task(send_verification_email, data.email, code, subject, heading)
    
    return {"message": "Password reset OTP sent"}

@router.post("/reset-password")
def reset_password(
    data: schemas.PasswordResetConfirm,
    db: Session = Depends(get_db)
):
    """
    Verify OTP and reset password.
    """
    # Verify code
    db_code = db.query(models.VerificationCode).filter(
        models.VerificationCode.email == data.email,
        models.VerificationCode.code == data.code
    ).first()
    
    if not db_code:
        raise HTTPException(status_code=400, detail="Invalid or expired verification code")
    
    # Get User
    user = db.query(models.User).filter(models.User.email == data.email).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Reset Password
    user.hashed_password = security.get_password_hash(data.new_password)
    
    # Also verify user if not already (since they proved ownership of email)
    if not user.is_verified:
        user.is_verified = True
        
    # Delete code
    db.delete(db_code)
    db.commit()
    
    return {"message": "Password reset successfully"}

@router.get("/me", response_model=schemas.UserResponse)
def read_users_me(current_user: models.User = Depends(deps.get_current_active_user)):
    return current_user

# --- ADMIN ORGANIZATION MANAGEMENT ---

@router.get("/admin/organizations", response_model=List[org_schemas.Organization])
def get_organizations(
    status: Optional[str] = None,
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(deps.get_current_admin_user)
):
    """
    Get all organizations, optionally filtered by status (admin only).
    """
    query = db.query(models.Organization)
    if status:
        query = query.filter(models.Organization.status == status)
    
    return query.order_by(models.Organization.created_at.desc()).offset(skip).limit(limit).all()

@router.put("/admin/organizations/{org_id}/status", response_model=org_schemas.Organization)
def update_organization_status(
    org_id: int,
    status_update: str, # pending, approved, suspended, rejected
    db: Session = Depends(get_db),
    current_user: models.User = Depends(deps.get_current_admin_user)
):
    """
    Update organization status (admin only).
    """
    org = db.query(models.Organization).filter(models.Organization.id == org_id).first()
    if not org:
        raise HTTPException(status_code=404, detail="Organization not found")
    
    org.status = status_update
    
    # If approved, also make the associated user an 'organization' role if not already
    if status_update == 'approved':
        user = db.query(models.User).filter(models.User.id == org.user_id).first()
        if user:
            user.role = 'organization'
    
    db.commit()
    db.refresh(org)
    return org
