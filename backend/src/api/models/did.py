from pydantic import BaseModel
from typing import Optional, Dict, Any

class DIDRegistrationRequest(BaseModel):
    address: str
    private_key: Optional[str] = None
    user_info: Optional[Dict[str, Any]] = None 