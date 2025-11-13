# ZOHO API Integration Service

FastAPI-based REST API for integrating with ZOHO services (CRM, Mail, Desk).

## Features

- **CRM Integration**: Create contacts in ZOHO CRM
- **Mail Integration**: Send emails via ZOHO Mail
- **Desk Integration**: Create support tickets
- **OAuth 2.0**: Automatic token refresh
- **Prometheus Metrics**: Built-in monitoring
- **Health Checks**: Service health endpoint

## API Endpoints

### Health & Monitoring

- `GET /` - API information
- `GET /health` - Health check with ZOHO connectivity test
- `GET /metrics` - Prometheus metrics

### ZOHO CRM

```bash
POST /api/crm/contact
Content-Type: application/json

{
  "first_name": "John",
  "last_name": "Doe",
  "email": "john@example.com",
  "phone": "+1234567890",
  "company": "Example Inc",
  "message": "Inquiry about services"
}
```

### ZOHO Mail

```bash
POST /api/mail/send
Content-Type: application/json

{
  "to": "recipient@example.com",
  "subject": "Hello from ZOHO API",
  "body": "This is a test email",
  "from_address": "sender@example.com"
}
```

### ZOHO Desk

```bash
POST /api/desk/ticket
Content-Type: application/json

{
  "subject": "Support Request",
  "description": "I need help with...",
  "email": "user@example.com",
  "priority": "Medium"
}
```

## Environment Variables

Required environment variables (provided via SOPS secrets):

```bash
ZOHO_CLIENT_ID=your_client_id
ZOHO_CLIENT_SECRET=your_client_secret
ZOHO_REFRESH_TOKEN=your_refresh_token
ZOHO_REDIRECT_URI=http://localhost:8080/oauth/callback
```

Optional:

```bash
ZOHO_API_DOMAIN=https://www.zohoapis.com
ZOHO_ACCOUNTS_DOMAIN=https://accounts.zoho.com
```

## Building the Container

```bash
cd /etc/nixos/containers/zoho-api
podman build -t localhost/zoho-api:latest .
```

## Running Locally

```bash
# Set environment variables
export ZOHO_CLIENT_ID="your_id"
export ZOHO_CLIENT_SECRET="your_secret"
export ZOHO_REFRESH_TOKEN="your_token"

# Run with uvicorn
uvicorn app:app --host 0.0.0.0 --port 8080 --reload
```

## Testing

```bash
# Health check
curl http://localhost:8080/health

# Create CRM contact
curl -X POST http://localhost:8080/api/crm/contact \
  -H "Content-Type: application/json" \
  -d '{
    "first_name": "Test",
    "last_name": "User",
    "email": "test@example.com"
  }'
```

## Monitoring

Prometheus metrics available at `/metrics`:

- `zoho_api_requests_total` - Total API requests by endpoint and status
- `zoho_api_request_duration_seconds` - Request duration histogram

## Security

- Runs as non-root user (UID 1000)
- OAuth 2.0 token refresh
- CORS configured (adjust for production)
- Input validation with Pydantic
- Rate limiting ready (implement with slowapi)

## Integration with Jekyll/Quarto

Example contact form in Jekyll:

```html
<form id="contact-form">
  <input type="text" name="first_name" required>
  <input type="text" name="last_name" required>
  <input type="email" name="email" required>
  <textarea name="message"></textarea>
  <button type="submit">Submit</button>
</form>

<script>
document.getElementById('contact-form').addEventListener('submit', async (e) => {
  e.preventDefault();
  const formData = new FormData(e.target);
  const data = Object.fromEntries(formData);

  const response = await fetch('https://api.example.com/api/crm/contact', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data)
  });

  if (response.ok) {
    alert('Thank you! We will contact you soon.');
  }
});
</script>
```

## License

Part of Gautama NixOS configuration.
