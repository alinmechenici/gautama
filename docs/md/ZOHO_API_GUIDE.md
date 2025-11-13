# ZOHO API Integration Guide

**Purpose**: Complete guide for integrating ZOHO services (CRM, Mail, Desk) with Gautama using OAuth 2.0.

**Last Updated**: 2025-11-13
**Prerequisites**: ZOHO account, domain with Cloudflare Tunnel

---

## 📋 Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [ZOHO OAuth Setup](#zoho-oauth-setup)
- [Service Configuration](#service-configuration)
- [API Endpoints](#api-endpoints)
- [Integration Examples](#integration-examples)
- [Testing](#testing)
- [Monitoring](#monitoring)
- [Troubleshooting](#troubleshooting)
- [Security](#security)

---

## 🔍 Overview

The ZOHO API Integration Service provides REST endpoints for interacting with ZOHO services from Jekyll/Quarto websites.

### Supported ZOHO Services

1. **ZOHO CRM** - Customer relationship management
   - Create contacts
   - Manage leads
   - Track deals

2. **ZOHO Mail** - Email services
   - Send emails programmatically
   - Manage mail folders
   - Search messages

3. **ZOHO Desk** - Customer support
   - Create tickets
   - Manage support requests
   - Track ticket status

### Architecture

```
Static Website (Jekyll/Quarto)
    ↓ (JavaScript POST)
ZOHO API Service (FastAPI)
    ↓ (OAuth 2.0)
ZOHO Cloud Services
```

**Benefits**:
- Centralized credential management
- Rate limiting and retry logic
- Prometheus monitoring
- Error handling
- Security through OAuth 2.0

---

## ✅ Prerequisites

### 1. ZOHO Account

Create accounts for services you need:
- **CRM**: https://www.zoho.com/crm/signup.html
- **Mail**: https://www.zoho.com/mail/zohomail-pricing.html
- **Desk**: https://www.zoho.com/desk/signup.html

Most services offer free tiers:
- ZOHO CRM Free: 3 users, 5,000 records
- ZOHO Mail: $1/user/month
- ZOHO Desk Free: 3 agents

### 2. Domain Configuration

ZOHO API requires a registered OAuth application. You'll need:
- Active ZOHO account
- Access to API Console
- Cloudflare Tunnel configured (see CLOUDFLARE_TUNNEL_GUIDE.md)

---

## 🔐 ZOHO OAuth Setup

### Step 1: Create OAuth Application

1. **Go to API Console**:
   - Visit: https://api-console.zoho.com/
   - Sign in with your ZOHO account

2. **Create Self Client**:
   - Click "Add Client" or "Get Started"
   - Choose "Self Client"
   - Note: Self Client is for your own use, no approval needed

3. **Note Credentials**:
   - Copy **Client ID**
   - Copy **Client Secret**
   - Save these securely (you'll need them later)

### Step 2: Define Scopes

Select which ZOHO services your application can access:

**CRM Scopes**:
```
ZohoCRM.modules.ALL
ZohoCRM.settings.ALL
```

**Mail Scopes**:
```
ZohoMail.messages.ALL
ZohoMail.accounts.ALL
```

**Desk Scopes**:
```
Desk.tickets.ALL
Desk.contacts.READ
```

**Recommended for Gautama** (minimal permissions):
```
ZohoCRM.modules.contacts.CREATE
ZohoCRM.modules.contacts.READ
ZohoMail.messages.CREATE
Desk.tickets.CREATE
Desk.tickets.READ
```

### Step 3: Generate Refresh Token

ZOHO uses OAuth 2.0 with refresh tokens for long-term access.

**Generate Authorization Code**:

1. Build authorization URL (replace values):
   ```
   https://accounts.zoho.com/oauth/v2/auth?
     scope=ZohoCRM.modules.contacts.CREATE,ZohoMail.messages.CREATE,Desk.tickets.CREATE
     &client_id=YOUR_CLIENT_ID
     &response_type=code
     &access_type=offline
     &redirect_uri=http://localhost:8080/oauth/callback
   ```

2. Open this URL in browser
3. Grant permissions
4. Copy the **code** parameter from redirect URL:
   ```
   http://localhost:8080/oauth/callback?code=1000.abc123...
   ```

**Exchange Code for Refresh Token**:

```bash
curl -X POST https://accounts.zoho.com/oauth/v2/token \
  -d "code=YOUR_AUTHORIZATION_CODE" \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET" \
  -d "redirect_uri=http://localhost:8080/oauth/callback" \
  -d "grant_type=authorization_code"
```

**Response**:
```json
{
  "access_token": "1000.abc123...",
  "refresh_token": "1000.xyz789...",
  "expires_in": 3600,
  "token_type": "Bearer"
}
```

**Save the refresh_token** - this is what you'll use in Gautama!

### Step 4: Add to SOPS Secrets

Edit secrets file:

```bash
sops /etc/nixos/secrets.yaml
```

Add ZOHO credentials:

```yaml
zoho-client-id: "YOUR_CLIENT_ID"
zoho-client-secret: "YOUR_CLIENT_SECRET"
zoho-refresh-token: "1000.YOUR_REFRESH_TOKEN"
zoho-redirect-uri: "http://localhost:8080/oauth/callback"
```

Save and close.

### Step 5: Rebuild System

```bash
cd /etc/nixos
sudo nixos-rebuild switch --flake '.#vulcan'
```

---

## ⚙️ Service Configuration

### Enable ZOHO API Module

Edit host configuration:

```nix
# hosts/vulcan/default.nix
{
  imports = [
    # ... other imports ...
    ../../modules/containers/zoho-api-quadlet.nix
  ];
}
```

### Verify Service

```bash
# Check service status
sudo systemctl status quadlet-zoho-api

# View logs
sudo journalctl -u quadlet-zoho-api -f

# Test health endpoint
curl http://localhost:4102/health
```

Expected response:
```json
{
  "status": "healthy",
  "timestamp": "2025-11-13T12:00:00",
  "zoho_connection": "connected"
}
```

---

## 📡 API Endpoints

### Base URL

- **Local**: `http://localhost:4102`
- **Internet** (via Cloudflare): `https://api.example.com`

### Health & Metrics

#### GET /
```bash
curl https://api.example.com/
```

Returns API information and available endpoints.

#### GET /health
```bash
curl https://api.example.com/health
```

Returns health status and ZOHO connectivity.

#### GET /metrics
```bash
curl https://api.example.com/metrics
```

Returns Prometheus metrics.

---

### CRM Endpoints

#### POST /api/crm/contact

Create new contact in ZOHO CRM.

**Request**:
```bash
curl -X POST https://api.example.com/api/crm/contact \
  -H "Content-Type: application/json" \
  -d '{
    "first_name": "John",
    "last_name": "Doe",
    "email": "john@example.com",
    "phone": "+1234567890",
    "company": "Example Inc",
    "message": "Inquiry about services"
  }'
```

**Response**:
```json
{
  "status": "success",
  "contact_id": "3652397000001234567",
  "message": "Contact created successfully"
}
```

**Fields**:
- `first_name` (required): First name
- `last_name` (required): Last name
- `email` (required): Email address
- `phone` (optional): Phone number
- `company` (optional): Company name
- `message` (optional): Additional notes

---

### Mail Endpoints

#### POST /api/mail/send

Send email via ZOHO Mail.

**Request**:
```bash
curl -X POST https://api.example.com/api/mail/send \
  -H "Content-Type: application/json" \
  -d '{
    "to": "recipient@example.com",
    "subject": "Welcome!",
    "body": "Thank you for contacting us.",
    "from_address": "noreply@example.com"
  }'
```

**Response**:
```json
{
  "status": "success",
  "message": "Email sent successfully"
}
```

**Fields**:
- `to` (required): Recipient email
- `subject` (required): Email subject
- `body` (required): Email body (plain text)
- `from_address` (optional): Sender address

---

### Desk Endpoints

#### POST /api/desk/ticket

Create support ticket in ZOHO Desk.

**Request**:
```bash
curl -X POST https://api.example.com/api/desk/ticket \
  -H "Content-Type: application/json" \
  -d '{
    "subject": "Login Issue",
    "description": "Cannot access my account",
    "email": "user@example.com",
    "priority": "High"
  }'
```

**Response**:
```json
{
  "status": "success",
  "ticket_id": "1234567",
  "message": "Support ticket created successfully"
}
```

**Fields**:
- `subject` (required): Ticket subject
- `description` (required): Detailed description
- `email` (required): User email
- `priority` (required): Low, Medium, or High

---

## 💻 Integration Examples

### Example 1: Jekyll Contact Form

**HTML Form** (in Jekyll `_includes/contact-form.html`):

```html
<form id="contact-form">
  <div class="form-group">
    <label for="first_name">First Name *</label>
    <input type="text" id="first_name" name="first_name" required>
  </div>

  <div class="form-group">
    <label for="last_name">Last Name *</label>
    <input type="text" id="last_name" name="last_name" required>
  </div>

  <div class="form-group">
    <label for="email">Email *</label>
    <input type="email" id="email" name="email" required>
  </div>

  <div class="form-group">
    <label for="phone">Phone</label>
    <input type="tel" id="phone" name="phone">
  </div>

  <div class="form-group">
    <label for="company">Company</label>
    <input type="text" id="company" name="company">
  </div>

  <div class="form-group">
    <label for="message">Message</label>
    <textarea id="message" name="message" rows="5"></textarea>
  </div>

  <button type="submit" id="submit-btn">Send Message</button>
  <div id="form-status"></div>
</form>

<script>
document.getElementById('contact-form').addEventListener('submit', async (e) => {
  e.preventDefault();

  // Get form data
  const formData = new FormData(e.target);
  const data = Object.fromEntries(formData);

  // Disable submit button
  const submitBtn = document.getElementById('submit-btn');
  const statusDiv = document.getElementById('form-status');
  submitBtn.disabled = true;
  submitBtn.textContent = 'Sending...';
  statusDiv.textContent = '';

  try {
    // Send to ZOHO API
    const response = await fetch('https://api.example.com/api/crm/contact', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(data)
    });

    if (response.ok) {
      const result = await response.json();
      statusDiv.innerHTML = '<p class="success">✓ Thank you! We will contact you soon.</p>';
      e.target.reset();
    } else {
      throw new Error('Server error');
    }
  } catch (error) {
    statusDiv.innerHTML = '<p class="error">✗ Error sending message. Please try again.</p>';
  } finally {
    submitBtn.disabled = false;
    submitBtn.textContent = 'Send Message';
  }
});
</script>

<style>
.form-group {
  margin-bottom: 1rem;
}

.form-group label {
  display: block;
  margin-bottom: 0.5rem;
  font-weight: bold;
}

.form-group input,
.form-group textarea {
  width: 100%;
  padding: 0.5rem;
  border: 1px solid #ccc;
  border-radius: 4px;
}

button[type="submit"] {
  background: #007bff;
  color: white;
  padding: 0.75rem 2rem;
  border: none;
  border-radius: 4px;
  cursor: pointer;
}

button[type="submit"]:disabled {
  background: #6c757d;
  cursor: not-allowed;
}

.success {
  color: green;
  font-weight: bold;
}

.error {
  color: red;
  font-weight: bold;
}
</style>
```

### Example 2: Quarto Newsletter Signup

**Quarto Document** (`newsletter.qmd`):

```markdown
---
title: "Newsletter Signup"
---

## Subscribe to Our Newsletter

<form id="newsletter-form">
  <input type="email" id="email" placeholder="your@email.com" required>
  <button type="submit">Subscribe</button>
  <div id="status"></div>
</form>

```{=html}
<script>
document.getElementById('newsletter-form').addEventListener('submit', async (e) => {
  e.preventDefault();
  const email = document.getElementById('email').value;
  const status = document.getElementById('status');

  try {
    // Create CRM contact for newsletter
    const response = await fetch('https://api.example.com/api/crm/contact', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        first_name: 'Newsletter',
        last_name: 'Subscriber',
        email: email,
        message: 'Newsletter subscription'
      })
    });

    if (response.ok) {
      status.textContent = '✓ Subscribed successfully!';
      e.target.reset();
    }
  } catch (error) {
    status.textContent = '✗ Error. Please try again.';
  }
});
</script>
```
```

### Example 3: Support Ticket from Documentation

**JavaScript** (in Quarto):

```javascript
async function createSupportTicket(subject, description, email) {
  const response = await fetch('https://api.example.com/api/desk/ticket', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      subject: subject,
      description: description,
      email: email,
      priority: 'Medium'
    })
  });

  if (response.ok) {
    const result = await response.json();
    return result.ticket_id;
  }

  throw new Error('Failed to create ticket');
}

// Usage
createSupportTicket(
  'Documentation Issue',
  'Found typo on page X',
  'user@example.com'
).then(ticketId => {
  console.log('Ticket created:', ticketId);
});
```

---

## 🧪 Testing

### Local Testing

Test endpoints locally before deploying:

```bash
# Health check
curl http://localhost:4102/health

# Create test contact
curl -X POST http://localhost:4102/api/crm/contact \
  -H "Content-Type: application/json" \
  -d '{
    "first_name": "Test",
    "last_name": "User",
    "email": "test@example.com"
  }'
```

### Production Testing

Test via Cloudflare Tunnel:

```bash
# Health check (should work)
curl https://api.example.com/health

# Create contact
curl -X POST https://api.example.com/api/crm/contact \
  -H "Content-Type: application/json" \
  -d '{
    "first_name": "Production",
    "last_name": "Test",
    "email": "prod@example.com"
  }'
```

### Verify in ZOHO

1. **CRM**: https://crm.zoho.com/crm/org123/tab/Contacts
2. **Mail**: Check sent folder
3. **Desk**: https://desk.zoho.com/support/org123/ShowHomePage.do#Tickets

---

## 📊 Monitoring

### Prometheus Metrics

Available at `/metrics`:

```promql
# Total API requests
zoho_api_requests_total{endpoint="crm_contact", status="success"}

# Request duration
zoho_api_request_duration_seconds{endpoint="crm_contact"}

# Error rate
rate(zoho_api_requests_total{status="error"}[5m])
```

### Grafana Dashboard

Create panels with these queries:

```promql
# Request rate
sum(rate(zoho_api_requests_total[5m])) by (endpoint)

# Success vs error rate
sum(rate(zoho_api_requests_total[5m])) by (status)

# P95 latency
histogram_quantile(0.95, zoho_api_request_duration_seconds_bucket)
```

### Logs

```bash
# View real-time logs
sudo journalctl -u quadlet-zoho-api -f

# Filter for errors
sudo journalctl -u quadlet-zoho-api | grep ERROR

# Recent requests
sudo journalctl -u quadlet-zoho-api --since "1 hour ago"
```

---

## 🔧 Troubleshooting

### Issue: Authentication Failed

**Error**: `Failed to authenticate with ZOHO`

**Solutions**:

1. **Verify refresh token**:
   ```bash
   # Check secret exists
   sudo cat /run/secrets/zoho-api-env | grep REFRESH_TOKEN
   ```

2. **Test token manually**:
   ```bash
   curl -X POST https://accounts.zoho.com/oauth/v2/token \
     -d "refresh_token=YOUR_TOKEN" \
     -d "client_id=YOUR_ID" \
     -d "client_secret=YOUR_SECRET" \
     -d "grant_type=refresh_token"
   ```

3. **Regenerate refresh token** (see Step 3 in OAuth Setup)

### Issue: API Returns 403 Forbidden

**Error**: ZOHO API rejects requests

**Causes**:
- Insufficient OAuth scopes
- Rate limit exceeded
- Invalid API domain

**Solutions**:

1. **Check scopes**:
   - Go to API Console
   - Verify scopes include required permissions
   - Regenerate refresh token with new scopes

2. **Check rate limits**:
   ```bash
   # ZOHO has rate limits (200 calls/minute for CRM)
   curl https://api.example.com/metrics | grep zoho_api_requests_total
   ```

3. **Verify API domain**:
   - Most accounts use: `https://www.zohoapis.com`
   - EU accounts use: `https://www.zohoapis.eu`
   - Update in secrets if needed

### Issue: Container Not Starting

**Error**: `quadlet-zoho-api` fails to start

**Solutions**:

1. **Check logs**:
   ```bash
   sudo journalctl -u quadlet-zoho-api -n 50
   ```

2. **Verify image**:
   ```bash
   podman images | grep zoho-api
   ```

3. **Rebuild container**:
   ```bash
   cd /etc/nixos/containers/zoho-api
   podman build -t localhost/zoho-api:latest .
   sudo systemctl restart quadlet-zoho-api
   ```

---

## 🔒 Security

### Best Practices

1. **Secure credentials**:
   - Store in SOPS only
   - Never commit to git
   - Rotate refresh tokens annually

2. **Rate limiting**:
   - Implement client-side rate limiting
   - Use slowapi middleware
   - Monitor request patterns

3. **Input validation**:
   - All inputs validated with Pydantic
   - Email format checked
   - SQL injection prevented

4. **HTTPS only**:
   - All API calls over HTTPS
   - Cloudflare provides SSL termination

5. **CORS configuration**:
   ```python
   # Restrict in production
   allow_origins=["https://blog.example.com", "https://docs.example.com"]
   ```

### Cloudflare Security

Enable these features:

1. **WAF Rules**:
   - Managed rules: On
   - OWASP Core: On

2. **Rate Limiting**:
   - 100 requests/minute per IP
   - 1000 requests/hour per IP

3. **API Shield** (Enterprise):
   - Schema validation
   - mTLS authentication

---

## 📚 Additional Resources

- [ZOHO API Documentation](https://www.zoho.com/crm/developer/docs/api/v3/)
- [OAuth 2.0 Guide](https://www.zoho.com/accounts/protocol/oauth/web-server-applications.html)
- [ZOHO CRM API](https://www.zoho.com/crm/developer/docs/api/v3/modules-api.html)
- [ZOHO Mail API](https://www.zoho.com/mail/help/api/)
- [ZOHO Desk API](https://desk.zoho.com/support/APIDocument.do)

---

**Last Updated**: 2025-11-13
**Maintained by**: Gautama System Administrator
