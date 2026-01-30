from pydantic import BaseModel, EmailStr
from typing import Optional

class UserBase(BaseModel):
    email: EmailStr
    full_name: Optional[str] = None
    role: str = "user"

class UserCreate(UserBase):
    password: str

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    user_id: Optional[int] = None
    role: Optional[str] = None
    email: Optional[str] = None

class UserResponse(UserBase):
    id: int
    is_active: bool
    is_verified: bool

    class Config:
        from_attributes = True

class PasswordResetConfirm(BaseModel):
    email: EmailStr
    code: str
    new_password: str
