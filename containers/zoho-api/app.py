"""
ZOHO API Integration Service
FastAPI application for interacting with ZOHO services (CRM, Mail, Desk, etc.)
"""

import os
import logging
from datetime import datetime, timedelta
from typing import Optional, Dict, Any

import httpx
from fastapi import FastAPI, HTTPException, Request, Depends
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, EmailStr, Field
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST
from fastapi.responses import Response

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Initialize FastAPI app
app = FastAPI(
    title="ZOHO API Integration Service",
    description="REST API for ZOHO services integration",
    version="1.0.0"
)

# CORS middleware for web forms
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure appropriately for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Prometheus metrics
api_requests_total = Counter(
    'zoho_api_requests_total',
    'Total ZOHO API requests',
    ['method', 'endpoint', 'status']
)
api_request_duration = Histogram(
    'zoho_api_request_duration_seconds',
    'ZOHO API request duration',
    ['method', 'endpoint']
)

# Configuration from environment variables
ZOHO_CLIENT_ID = os.getenv("ZOHO_CLIENT_ID")
ZOHO_CLIENT_SECRET = os.getenv("ZOHO_CLIENT_SECRET")
ZOHO_REFRESH_TOKEN = os.getenv("ZOHO_REFRESH_TOKEN")
ZOHO_REDIRECT_URI = os.getenv("ZOHO_REDIRECT_URI", "http://localhost:8080/oauth/callback")
ZOHO_API_DOMAIN = os.getenv("ZOHO_API_DOMAIN", "https://www.zohoapis.com")
ZOHO_ACCOUNTS_DOMAIN = os.getenv("ZOHO_ACCOUNTS_DOMAIN", "https://accounts.zoho.com")

# In-memory token cache (use Redis for production)
access_token_cache: Dict[str, Any] = {}


# ============================================================================
# Pydantic Models
# ============================================================================

class ContactRequest(BaseModel):
    """Request model for creating CRM contact"""
    first_name: str = Field(..., min_length=1, max_length=100)
    last_name: str = Field(..., min_length=1, max_length=100)
    email: EmailStr
    phone: Optional[str] = None
    company: Optional[str] = None
    message: Optional[str] = None


class EmailRequest(BaseModel):
    """Request model for sending email via ZOHO Mail"""
    to: EmailStr
    subject: str = Field(..., min_length=1, max_length=200)
    body: str = Field(..., min_length=1)
    from_address: Optional[str] = None


class SupportTicketRequest(BaseModel):
    """Request model for creating support ticket in ZOHO Desk"""
    subject: str = Field(..., min_length=1, max_length=200)
    description: str = Field(..., min_length=1)
    email: EmailStr
    priority: str = Field(default="Medium", pattern="^(Low|Medium|High)$")


class HealthResponse(BaseModel):
    """Health check response"""
    status: str
    timestamp: str
    zoho_connection: str


# ============================================================================
# ZOHO OAuth Functions
# ============================================================================

async def get_access_token() -> str:
    """
    Get valid ZOHO access token, refreshing if necessary
    Uses refresh token to obtain new access token when expired
    """
    current_time = datetime.now()

    # Check if we have a valid cached token
    if "access_token" in access_token_cache:
        expires_at = access_token_cache.get("expires_at", current_time)
        if current_time < expires_at:
            logger.debug("Using cached access token")
            return access_token_cache["access_token"]

    # Refresh the access token
    logger.info("Refreshing ZOHO access token")

    async with httpx.AsyncClient() as client:
        try:
            response = await client.post(
                f"{ZOHO_ACCOUNTS_DOMAIN}/oauth/v2/token",
                data={
                    "refresh_token": ZOHO_REFRESH_TOKEN,
                    "client_id": ZOHO_CLIENT_ID,
                    "client_secret": ZOHO_CLIENT_SECRET,
                    "grant_type": "refresh_token",
                }
            )

            if response.status_code != 200:
                logger.error(f"Failed to refresh token: {response.text}")
                raise HTTPException(
                    status_code=500,
                    detail="Failed to authenticate with ZOHO"
                )

            token_data = response.json()
            access_token = token_data["access_token"]
            expires_in = token_data.get("expires_in", 3600)

            # Cache the token
            access_token_cache["access_token"] = access_token
            access_token_cache["expires_at"] = current_time + timedelta(seconds=expires_in - 60)

            logger.info("Access token refreshed successfully")
            return access_token

        except Exception as e:
            logger.error(f"Error refreshing access token: {str(e)}")
            raise HTTPException(
                status_code=500,
                detail=f"ZOHO authentication error: {str(e)}"
            )


# ============================================================================
# API Endpoints
# ============================================================================

@app.get("/", response_model=Dict[str, str])
async def root():
    """Root endpoint with API information"""
    return {
        "service": "ZOHO API Integration",
        "version": "1.0.0",
        "status": "running",
        "endpoints": {
            "health": "/health",
            "metrics": "/metrics",
            "crm_contact": "/api/crm/contact",
            "mail_send": "/api/mail/send",
            "desk_ticket": "/api/desk/ticket"
        }
    }


@app.get("/health", response_model=HealthResponse)
async def health_check():
    """Health check endpoint with ZOHO connectivity test"""
    zoho_status = "unknown"

    try:
        # Try to get access token to verify ZOHO connection
        await get_access_token()
        zoho_status = "connected"
    except Exception as e:
        logger.error(f"Health check failed: {str(e)}")
        zoho_status = "disconnected"

    return HealthResponse(
        status="healthy" if zoho_status == "connected" else "degraded",
        timestamp=datetime.now().isoformat(),
        zoho_connection=zoho_status
    )


@app.get("/metrics")
async def metrics():
    """Prometheus metrics endpoint"""
    return Response(
        content=generate_latest(),
        media_type=CONTENT_TYPE_LATEST
    )


@app.post("/api/crm/contact")
async def create_crm_contact(contact: ContactRequest):
    """
    Create new contact in ZOHO CRM
    POST /api/crm/contact
    """
    logger.info(f"Creating CRM contact for {contact.email}")

    try:
        access_token = await get_access_token()

        # Prepare contact data
        contact_data = {
            "data": [{
                "First_Name": contact.first_name,
                "Last_Name": contact.last_name,
                "Email": contact.email,
            }]
        }

        if contact.phone:
            contact_data["data"][0]["Phone"] = contact.phone
        if contact.company:
            contact_data["data"][0]["Company"] = contact.company
        if contact.message:
            contact_data["data"][0]["Description"] = contact.message

        # Create contact via ZOHO CRM API
        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"{ZOHO_API_DOMAIN}/crm/v3/Contacts",
                headers={
                    "Authorization": f"Zoho-oauthtoken {access_token}",
                    "Content-Type": "application/json"
                },
                json=contact_data,
                timeout=30.0
            )

            if response.status_code not in [200, 201]:
                logger.error(f"ZOHO CRM API error: {response.text}")
                api_requests_total.labels(method="POST", endpoint="crm_contact", status="error").inc()
                raise HTTPException(
                    status_code=response.status_code,
                    detail=f"ZOHO CRM error: {response.text}"
                )

            result = response.json()
            contact_id = result["data"][0]["details"]["id"]

            api_requests_total.labels(method="POST", endpoint="crm_contact", status="success").inc()
            logger.info(f"Contact created successfully: {contact_id}")

            return {
                "status": "success",
                "contact_id": contact_id,
                "message": "Contact created successfully"
            }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error creating CRM contact: {str(e)}")
        api_requests_total.labels(method="POST", endpoint="crm_contact", status="error").inc()
        raise HTTPException(
            status_code=500,
            detail=f"Internal error: {str(e)}"
        )


@app.post("/api/mail/send")
async def send_mail(email_req: EmailRequest):
    """
    Send email via ZOHO Mail API
    POST /api/mail/send
    """
    logger.info(f"Sending email to {email_req.to}")

    try:
        access_token = await get_access_token()

        # Prepare email data
        email_data = {
            "to": [{"address": email_req.to}],
            "subject": email_req.subject,
            "content": email_req.body,
            "mailFormat": "plaintext"
        }

        if email_req.from_address:
            email_data["fromAddress"] = email_req.from_address

        # Send via ZOHO Mail API
        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"{ZOHO_API_DOMAIN}/mail/v1/accounts/me/messages",
                headers={
                    "Authorization": f"Zoho-oauthtoken {access_token}",
                    "Content-Type": "application/json"
                },
                json=email_data,
                timeout=30.0
            )

            if response.status_code not in [200, 201]:
                logger.error(f"ZOHO Mail API error: {response.text}")
                api_requests_total.labels(method="POST", endpoint="mail_send", status="error").inc()
                raise HTTPException(
                    status_code=response.status_code,
                    detail=f"ZOHO Mail error: {response.text}"
                )

            api_requests_total.labels(method="POST", endpoint="mail_send", status="success").inc()
            logger.info("Email sent successfully")

            return {
                "status": "success",
                "message": "Email sent successfully"
            }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error sending email: {str(e)}")
        api_requests_total.labels(method="POST", endpoint="mail_send", status="error").inc()
        raise HTTPException(
            status_code=500,
            detail=f"Internal error: {str(e)}"
        )


@app.post("/api/desk/ticket")
async def create_support_ticket(ticket: SupportTicketRequest):
    """
    Create support ticket in ZOHO Desk
    POST /api/desk/ticket
    """
    logger.info(f"Creating support ticket from {ticket.email}")

    try:
        access_token = await get_access_token()

        # Prepare ticket data
        ticket_data = {
            "subject": ticket.subject,
            "description": ticket.description,
            "email": ticket.email,
            "priority": ticket.priority,
            "status": "Open"
        }

        # Create ticket via ZOHO Desk API
        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"{ZOHO_API_DOMAIN}/desk/v1/tickets",
                headers={
                    "Authorization": f"Zoho-oauthtoken {access_token}",
                    "Content-Type": "application/json"
                },
                json=ticket_data,
                timeout=30.0
            )

            if response.status_code not in [200, 201]:
                logger.error(f"ZOHO Desk API error: {response.text}")
                api_requests_total.labels(method="POST", endpoint="desk_ticket", status="error").inc()
                raise HTTPException(
                    status_code=response.status_code,
                    detail=f"ZOHO Desk error: {response.text}"
                )

            result = response.json()
            ticket_id = result.get("id", "unknown")

            api_requests_total.labels(method="POST", endpoint="desk_ticket", status="success").inc()
            logger.info(f"Support ticket created: {ticket_id}")

            return {
                "status": "success",
                "ticket_id": ticket_id,
                "message": "Support ticket created successfully"
            }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error creating support ticket: {str(e)}")
        api_requests_total.labels(method="POST", endpoint="desk_ticket", status="error").inc()
        raise HTTPException(
            status_code=500,
            detail=f"Internal error: {str(e)}"
        )


# ============================================================================
# Main
# ============================================================================

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        app,
        host="0.0.0.0",
        port=8080,
        log_level="info"
    )
