from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks
from sqlalchemy.orm import Session
import secrets
import string
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import bcrypt
import os

from db import models
from app.schemas import organization as schemas
from app.api import deps
from db.session import get_db
from app.core.config import settings

router = APIRouter(
    prefix="/organizations",
    tags=["organizations"]
)

def send_approval_email(email: str, password: str):
    """Send approval email with credentials via Brevo SMTP"""
    msg = MIMEMultipart()
    msg['From'] = settings.MAIL_FROM
    msg['To'] = email
    msg['Subject'] = "Relivo Organization Approved!"

    body = f"""
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: auto; border: 1px solid #ddd; padding: 20px; border-radius: 10px;">
        <h2 style="color: #17463a;">Congratulations!</h2>
        <p>Your organization has been approved by the Relivo Admin team.</p>
        <p>You can now log in to the Organization Portal using the credentials below:</p>
        <div style="background: #f9f9f9; padding: 15px; border-radius: 8px; margin: 20px 0; border: 1px solid #eee;">
            <p style="margin: 5px 0;"><strong>Username:</strong> {email}</p>
            <p style="margin: 5px 0;"><strong>Password:</strong> <span style="font-family: monospace; font-size: 1.2em; color: #17463a;">{password}</span></p>
        </div>
        <p style="color: #d9534f; font-weight: bold;">⚠️ Important: You will be required to change your password upon your first login.</p>
        <div style="margin-top: 30px;">
            <a href="http://localhost:8000/login" style="background: #17463a; color: white; padding: 12px 25px; text-decoration: none; border-radius: 5px; font-weight: bold;">Go to Login</a>
        </div>
        <p style="margin-top: 25px; font-size: 0.9em; color: #666;">If you have any questions, please reply to this email.</p>
    </div>
    """
    msg.attach(MIMEText(body, 'html'))

    try:
        with smtplib.SMTP(settings.MAIL_SERVER, settings.MAIL_PORT) as server:
            server.starttls()
            server.login(settings.MAIL_USERNAME, settings.MAIL_PASSWORD)
            server.send_message(msg)
        print(f"Approval email sent to {email}")
    except Exception as e:
        print(f"Error sending approval email: {e}")

def send_rejection_email(email: str, org_name: str):
    """Send rejection email via Brevo SMTP"""
    msg = MIMEMultipart()
    msg['From'] = settings.MAIL_FROM
    msg['To'] = email
    msg['Subject'] = "Relivo Organization Application Update"

    body = f"""
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: auto; border: 1px solid #ddd; padding: 20px; border-radius: 10px;">
        <h2 style="color: #d9534f;">Application Status Update</h2>
        <p>Thank you for your interest in joining the Relivo platform.</p>
        <p>After careful review, we regret to inform you that your organization application for <strong>{org_name}</strong> has not been approved at this time.</p>
        <div style="background: #fff3cd; padding: 15px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #ffc107;">
            <p style="margin: 0; color: #856404;">If you believe this decision was made in error or would like to reapply with additional information, please contact our support team.</p>
        </div>
        <p style="margin-top: 25px; font-size: 0.9em; color: #666;">If you have any questions, please reply to this email or contact our support team.</p>
        <p style="margin-top: 15px; font-size: 0.9em; color: #666;">Best regards,<br>The Relivo Team</p>
    </div>
    """
    msg.attach(MIMEText(body, 'html'))

    try:
        with smtplib.SMTP(settings.MAIL_SERVER, settings.MAIL_PORT) as server:
            server.starttls()
            server.login(settings.MAIL_USERNAME, settings.MAIL_PASSWORD)
            server.send_message(msg)
        print(f"Rejection email sent to {email}")
    except Exception as e:
        print(f"Error sending rejection email: {e}")

@router.get("/admin/all", response_model=List[schemas.Organization])
def get_all_organizations(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(deps.get_current_admin_user)
):
    """Get all organizations (admin only)"""
    return db.query(models.Organization).order_by(models.Organization.created_at.desc()).all()

@router.get("/admin/pending", response_model=List[schemas.Organization])
def get_pending_organizations(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(deps.get_current_admin_user)
):
    """Get only pending organizations (admin only)"""
    return db.query(models.Organization).filter(models.Organization.status == "pending").all()

@router.post("/admin/{org_id}/approve")
def approve_organization(
    org_id: int,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(deps.get_current_admin_user)
):
    """Approve organization, generate password, and send email"""
    org = db.query(models.Organization).filter(models.Organization.id == org_id).first()
    if not org:
        raise HTTPException(status_code=404, detail="Organization not found")
    
    # Generate random 8-char password
    alphabet = string.ascii_letters + string.digits
    password = ''.join(secrets.choice(alphabet) for i in range(8))
    
    # Hash password using app security utility
    from app.core import security
    hashed_password = security.get_password_hash(password)
    
    org.status = "approved"
    org.password = hashed_password
    org.must_change_password = True
    
    # Also update the associated User account's password
    user = db.query(models.User).filter(models.User.id == org.user_id).first()
    if user:
        user.hashed_password = hashed_password
        user.is_active = True
        user.role = "organization"
    
    db.commit()
    
    # Send email in background
    background_tasks.add_task(send_approval_email, org.contact_email, password)
    
    return {"message": "Organization approved and credentials sent", "email": org.contact_email}

@router.post("/admin/{org_id}/reject")
def reject_organization(
    org_id: int,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(deps.get_current_admin_user)
):
    """Reject organization and send notification email"""
    org = db.query(models.Organization).filter(models.Organization.id == org_id).first()
    if not org:
        raise HTTPException(status_code=404, detail="Organization not found")
    
    org.status = "rejected"
    
    # Also update the associated User account
    user = db.query(models.User).filter(models.User.id == org.user_id).first()
    if user:
        user.is_active = False
    
    db.commit()
    
    # Send rejection email in background
    background_tasks.add_task(send_rejection_email, org.contact_email, org.name)
    
    return {"message": "Organization rejected and notification sent", "email": org.contact_email}


@router.put("/admin/{org_id}/suspend")
def suspend_organization(
    org_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(deps.get_current_admin_user)
):
    """Suspend an organization"""
    org = db.query(models.Organization).filter(models.Organization.id == org_id).first()
    if not org:
        raise HTTPException(status_code=404, detail="Organization not found")
    
    org.status = "suspended"
    db.commit()
    return {"message": "Organization suspended"}

@router.put("/admin/{org_id}/reactivate")
def reactivate_organization(
    org_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(deps.get_current_admin_user)
):
    """Reactivate a suspended organization"""
    org = db.query(models.Organization).filter(models.Organization.id == org_id).first()
    if not org:
        raise HTTPException(status_code=404, detail="Organization not found")
    
    org.status = "ACTIVE"
    db.commit()
    return {"message": "Organization reactivated"}
