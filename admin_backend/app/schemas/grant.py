from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime

class GrantBase(BaseModel):
    title: str
    organizer: str  # Renamed from provider
    description: Optional[str] = None
    eligibility: Optional[str] = None  # Text description
    deadline: Optional[datetime] = None
    apply_url: str
    
    # Optional fields
    amount: Optional[str] = None
    location: Optional[str] = None
    eligibility_criteria: Optional[List[str]] = None
    required_documents: Optional[List[str]] = None
    
    # Admin curation fields
    refugee_country: Optional[str] = None
    is_verified: bool = False
    is_active: bool = True
    
    # Source tracking
    source: str = "manual"
    external_id: Optional[str] = None

class GrantCreate(GrantBase):
    pass

class GrantUpdate(BaseModel):
    """Partial update schema - all fields optional"""
    title: Optional[str] = None
    organizer: Optional[str] = None
    description: Optional[str] = None
    eligibility: Optional[str] = None
    deadline: Optional[datetime] = None
    apply_url: Optional[str] = None
    amount: Optional[str] = None
    location: Optional[str] = None
    eligibility_criteria: Optional[List[str]] = None
    required_documents: Optional[List[str]] = None
    refugee_country: Optional[str] = None
    is_verified: Optional[bool] = None
    is_active: Optional[bool] = None

class Grant(GrantBase):
    id: int
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True

class GrantImportResult(BaseModel):
    """Result of Grants.gov import operation"""
    imported: int
    skipped: int
    errors: List[str] = []

