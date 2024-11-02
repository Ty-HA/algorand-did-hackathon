from pydantic import BaseModel
from typing import Optional, Dict, Any

class CredentialRequest(BaseModel):
    category: str
    subject: str
    issuer_name: str
    issuer_did: str
    period: Dict[str, str]
    destinator_did: str
    metadata: Optional[Dict[str, Any]] = None 