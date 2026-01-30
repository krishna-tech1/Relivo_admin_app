from pydantic import BaseModel
from typing import Optional, List, Any
from datetime import datetime

class OrganizationBase(BaseModel):
    name: str
    description: Optional[str] = None
    website: Optional[str] = None
    contact_email: Optional[str] = None

class OrganizationCreate(OrganizationBase):
    user_id: int
    verification_documents: Optional[Any] = None

class OrganizationUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    website: Optional[str] = None
    contact_email: Optional[str] = None
    status: Optional[str] = None # pending, approved, suspended, rejected

class Organization(OrganizationBase):
    id: int
    user_id: int
    status: str
    verification_documents: Optional[Any] = None
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True
