from sqlalchemy import Column, Integer, String, Boolean, DateTime, JSON, Text, Index, ForeignKey
from sqlalchemy.sql import func
from .session import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, index=True, nullable=False)
    hashed_password = Column(String(255), nullable=False)
    full_name = Column(String(255))
    is_active = Column(Boolean, default=True)
    is_verified = Column(Boolean, default=False)
    role = Column(String(50), default="user")
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

class VerificationCode(Base):
    __tablename__ = "verification_codes"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), index=True, nullable=False)
    code = Column(String(10), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Add index for faster lookups
    __table_args__ = (
        Index('ix_verification_email_code', 'email', 'code'),
    )


class Grant(Base):
    __tablename__ = "grants"

    # Core Fields
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(500), index=True, nullable=False)
    organizer = Column(String(200), nullable=False)  # Agency/Organization name
    deadline = Column(DateTime, nullable=True, index=True)  # Index for sorting
    description = Column(Text, nullable=True)  # Use Text for long content
    eligibility = Column(Text, nullable=True)  # Text description of eligibility
    apply_url = Column(String(500), nullable=False)
    
    # Source & Tracking
    source = Column(String(50), default="manual", index=True)  # "manual" or "grants.gov"
    external_id = Column(String(100), unique=True, nullable=True, index=True)  # Grants.gov opportunity ID
    
    # Admin Curation Fields
    refugee_country = Column(String(100), nullable=True, index=True)  # For filtering
    is_verified = Column(Boolean, default=False, index=True)  # Admin verification
    is_active = Column(Boolean, default=True, index=True)  # Active/disabled status
    rejection_reason = Column(Text, nullable=True) # Reason for rejection if applicable

    # Ownership & Trust
    creator_id = Column(Integer, ForeignKey("users.id"), nullable=True, index=True) # User who submitted
    organization_id = Column(Integer, ForeignKey("organizations.id"), nullable=True, index=True) # Linked Org (if trusted)
    
    # Legacy/Optional Fields (for backward compatibility)
    amount = Column(String(100), nullable=True)  # Grant amount as string
    location = Column(String(200), nullable=True)  # Geographic location
    eligibility_criteria = Column(JSON, nullable=True)  # Structured eligibility list
    required_documents = Column(JSON, nullable=True)  # Required documents list
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Composite indexes for common queries
    __table_args__ = (
        Index('ix_grants_verified_active', 'is_verified', 'is_active'),
        Index('ix_grants_country_verified', 'refugee_country', 'is_verified'),
        Index('ix_grants_deadline_verified', 'deadline', 'is_verified'),
    )

class Organization(Base):
    __tablename__ = "organizations"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, index=True, nullable=False) # Link to User account
    name = Column(String(200), index=True, nullable=False)
    description = Column(Text, nullable=True)
    verification_documents = Column(JSON, nullable=True) # Paths to uploaded docs
    status = Column(String(50), default="pending", index=True) # pending, approved, suspended, rejected
    
    # Contact Info
    website = Column(String(200), nullable=True)
    contact_email = Column(String(200), nullable=True)
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

