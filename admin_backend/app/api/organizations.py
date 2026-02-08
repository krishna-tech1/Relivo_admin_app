from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks
from sqlalchemy.orm import Session
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

def send_approval_email(email: str):
    """Send approval email notification via Brevo API"""
    print(f"[EMAIL] Attempting to send approval email to: {email}")
    
    # Brevo API endpoint
    url = "https://api.brevo.com/v3/smtp/email"
    
    # Email content
    html_content = f"""
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: auto; border: 1px solid #ddd; padding: 20px; border-radius: 10px;">
        <h2 style="color: #17463a;">Congratulations!</h2>
        <p>Your organization has been approved by the Relivo Admin team.</p>
        <p>You can now log in to the Organization Portal and start accessing grant opportunities.</p>
        <div style="margin-top: 30px;">
            <a href="https://relivo-org-web.vercel.app/" style="background: #17463a; color: white; padding: 12px 25px; text-decoration: none; border-radius: 5px; font-weight: bold;">Go to Login</a>
        </div>
        <p style="margin-top: 25px; font-size: 0.9em; color: #666;">If you have any questions, please contact our support team at <a href="mailto:muthukrishnan8733@gmail.com">muthukrishnan8733@gmail.com</a></p>
        <p style="margin-top: 15px; font-size: 0.9em; color: #666;">Best regards,<br>The Relivo Team</p>
    </div>
    """
    
    payload = {
        "sender": {
            "name": "Relivo Admin",
            "email": settings.MAIL_FROM
        },
        "to": [
            {
                "email": email
            }
        ],
        "subject": "Relivo Organization Approved!",
        "htmlContent": html_content
    }
    
    headers = {
        "accept": "application/json",
        "api-key": settings.MAIL_PASSWORD,  # Brevo API key
        "content-type": "application/json"
    }
    
    try:
        print(f"[EMAIL] Sending via Brevo API to: {email}")
        import requests
        response = requests.post(url, json=payload, headers=headers, timeout=10)
        
        if response.status_code in [200, 201]:
            print(f"[EMAIL] ✓ Approval email sent successfully to {email}")
            print(f"[EMAIL] Response: {response.json()}")
            return True
        else:
            print(f"[EMAIL] ✗ Failed to send email. Status: {response.status_code}")
            print(f"[EMAIL] Response: {response.text}")
            return False
    except Exception as e:
        print(f"[EMAIL] ✗ Error sending approval email to {email}: {str(e)}")
        print(f"[EMAIL] Error type: {type(e).__name__}")
        import traceback
        print(f"[EMAIL] Traceback: {traceback.format_exc()}")
        return False

def send_rejection_email(email: str, org_name: str, rejection_reason: str = None):
    """Send rejection email via Brevo API"""
    print(f"[EMAIL] Attempting to send rejection email to: {email} for org: {org_name}")
    
    # Brevo API endpoint
    url = "https://api.brevo.com/v3/smtp/email"
    
    # Build the reason section if provided
    reason_section = ""
    if rejection_reason and rejection_reason.strip():
        print(f"[EMAIL] Including rejection reason: {rejection_reason[:50]}...")
        reason_section = f"""
        <div style="background: #ffe6e6; padding: 15px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #d9534f;">
            <p style="margin: 0 0 8px 0; color: #721c24; font-weight: bold;">Reason for rejection:</p>
            <p style="margin: 0; color: #721c24;">{rejection_reason}</p>
        </div>
        """

    html_content = f"""
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: auto; border: 1px solid #ddd; padding: 20px; border-radius: 10px;">
        <h2 style="color: #d9534f;">Application Status Update</h2>
        <p>Thank you for your interest in joining the Relivo platform.</p>
        <p>After careful review, we regret to inform you that your organization application for <strong>{org_name}</strong> has not been approved at this time.</p>
        {reason_section}
        <div style="background: #fff3cd; padding: 15px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #ffc107;">
            <p style="margin: 0; color: #856404;">If you believe this decision was made in error or would like to reapply with additional information, please contact our support team.</p>
        </div>
        <p style="margin-top: 25px; font-size: 0.9em; color: #666;">For support, please contact: <a href="mailto:muthukrishnan8733@gmail.com">muthukrishnan8733@gmail.com</a></p>
        <p style="margin-top: 15px; font-size: 0.9em; color: #666;">Best regards,<br>The Relivo Team</p>
    </div>
    """
    
    payload = {
        "sender": {
            "name": "Relivo Admin",
            "email": settings.MAIL_FROM
        },
        "to": [
            {
                "email": email
            }
        ],
        "subject": "Relivo Organization Application Update",
        "htmlContent": html_content
    }
    
    headers = {
        "accept": "application/json",
        "api-key": settings.MAIL_PASSWORD,  # Brevo API key
        "content-type": "application/json"
    }

    try:
        print(f"[EMAIL] Sending via Brevo API to: {email}")
        import requests
        response = requests.post(url, json=payload, headers=headers, timeout=10)
        
        if response.status_code in [200, 201]:
            print(f"[EMAIL] ✓ Rejection email sent successfully to {email}")
            print(f"[EMAIL] Response: {response.json()}")
            return True
        else:
            print(f"[EMAIL] ✗ Failed to send email. Status: {response.status_code}")
            print(f"[EMAIL] Response: {response.text}")
            return False
    except Exception as e:
        print(f"[EMAIL] ✗ Error sending rejection email to {email}: {str(e)}")
        import traceback
        print(f"[EMAIL] Traceback: {traceback.format_exc()}")
        return False

@router.get("/admin/all", response_model=List[schemas.Organization])
def get_all_organizations(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(deps.get_current_admin_user)
):
    """Get all organizations (admin only) - only shows organizations with verified users"""
    return db.query(models.Organization).join(
        models.User, models.Organization.user_id == models.User.id
    ).filter(
        models.User.is_verified == True
    ).order_by(models.Organization.created_at.desc()).all()

@router.get("/admin/pending", response_model=List[schemas.Organization])
def get_pending_organizations(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(deps.get_current_admin_user)
):
    """Get only pending organizations (admin only) - only shows organizations with verified users"""
    return db.query(models.Organization).join(
        models.User, models.Organization.user_id == models.User.id
    ).filter(
        models.Organization.status == "pending",
        models.User.is_verified == True
    ).order_by(models.Organization.created_at.desc()).all()

@router.post("/admin/{org_id}/approve")
def approve_organization(
    org_id: int,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(deps.get_current_admin_user)
):
    """Approve organization and send notification email"""
    org = db.query(models.Organization).filter(models.Organization.id == org_id).first()
    if not org:
        raise HTTPException(status_code=404, detail="Organization not found")
    
    org.status = "approved"
    
    # Update the associated User account
    user = db.query(models.User).filter(models.User.id == org.user_id).first()
    if user:
        user.is_active = True
        user.role = "organization"
    
    db.commit()
    
    # Send approval email in background
    background_tasks.add_task(send_approval_email, org.contact_email)
    
    return {"message": "Organization approved and notification sent", "email": org.contact_email}

@router.post("/admin/{org_id}/reject")
def reject_organization(
    org_id: int,
    rejection_data: dict,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(deps.get_current_admin_user)
):
    """Reject organization and send notification email with reason"""
    org = db.query(models.Organization).filter(models.Organization.id == org_id).first()
    if not org:
        raise HTTPException(status_code=404, detail="Organization not found")
    
    # Get rejection reason from request body
    rejection_reason = rejection_data.get("reason", "")
    
    org.status = "rejected"
    org.rejection_reason = rejection_reason
    
    # Also update the associated User account
    user = db.query(models.User).filter(models.User.id == org.user_id).first()
    if user:
        user.is_active = False
    
    db.commit()
    
    # Send rejection email in background with reason
    background_tasks.add_task(send_rejection_email, org.contact_email, org.name, rejection_reason)
    
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
