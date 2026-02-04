from pydantic import BaseModel, EmailStr
from typing import Optional, List, Any
from datetime import datetime

class OrganizationBase(BaseModel):
    name: str
    description: Optional[str] = None
    website: Optional[str] = None
    contact_email: Optional[EmailStr] = None
    country: Optional[str] = None
    type: Optional[str] = None
    status: str = "pending"

class OrganizationCreate(OrganizationBase):
    user_id: int
    verification_documents: Optional[List[str]] = None

class OrganizationUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    website: Optional[str] = None
    contact_email: Optional[EmailStr] = None
    status: Optional[str] = None
    verification_documents: Optional[List[str]] = None

class Organization(OrganizationBase):
    id: int
    user_id: int
    verification_documents: Optional[Any] = None
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True
