# Supabase Self-Hosted Playbook

**Self-hosted deployment** of [Supabase](https://supabase.com/) - the open source Firebase alternative - with Nginx reverse proxy, automatic SSL via Certbot, and **Authelia 2FA protection** for the dashboard.

## Overview

Supabase is an open source Firebase alternative that provides:
- **PostgreSQL Database** - Full Postgres database with Row Level Security
- **Authentication** - Email/password, magic link, OAuth providers
- **Auto-generated APIs** - REST and GraphQL APIs generated from your database
- **Realtime** - WebSocket subscriptions for live data
- **Storage** - File storage with image transformations
- **Edge Functions** - Serverless functions (Deno-based)
- **Studio Dashboard** - Web-based database management UI

## Technology Stack

This playbook deploys the complete Supabase stack on a single VPS:

| Service | Description | Image |
|---------|-------------|-------|
| **Studio** | Web dashboard for database management | supabase/studio |
| **Kong** | API gateway routing all requests | kong:2.8.1 |
| **GoTrue** | Authentication service | supabase/gotrue |
| **PostgREST** | Auto-generated REST API | postgrest/postgrest |
| **Realtime** | WebSocket server for subscriptions | supabase/realtime |
| **Storage** | File storage API | supabase/storage-api |
| **imgproxy** | Image transformation service | darthsim/imgproxy |
| **Meta** | PostgreSQL metadata API | supabase/postgres-meta |
| **Edge Functions** | Serverless Deno runtime | supabase/edge-runtime |
| **Analytics** | Log aggregation (Logflare) | supabase/logflare |
| **PostgreSQL** | Database | supabase/postgres |
| **Vector** | Log collection | timberio/vector |
| **Supavisor** | Connection pooler | supabase/supavisor |
| **Authelia** | 2FA authentication for dashboard | authelia/authelia |

## Requirements

### System Requirements

| Requirement | Minimum | Recommended |
|-------------|---------|-------------|
| **CPU** | 2 vCPU | 4+ vCPU |
| **RAM** | 4 GB | 8+ GB |
| **Storage** | 20 GB | 50+ GB |
| **OS** | Ubuntu 20.04+ / Debian 11+ / RHEL 8+ | Ubuntu 22.04 / Debian 12 |

### Prerequisites

- Domain name pointing to your server (A record)
- Ports 80 and 443 available
- Ansible >= 2.10

## Configuration Variables

### Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `supabase_domain` | Fully qualified domain name | `supabase.example.com` |
| `admin_email` | Email for SSL certificate notifications | `admin@example.com` |
| `dashboard_password` | Password for Studio dashboard (min 8 chars) | `MySecurePassword123` |

### Optional Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `dashboard_username` | string | `supabase` | Studio dashboard username |
| `smtp_host` | string | - | SMTP server for emails |
| `smtp_port` | integer | `587` | SMTP port |
| `smtp_user` | string | - | SMTP username |
| `smtp_pass` | password | - | SMTP password |
| `smtp_sender_email` | string | - | Email sender address |
| `supabase_install_dir` | string | `/opt/supabase` | Installation directory |

> **Note**: All other secrets (PostgreSQL password, JWT secret, API keys) are automatically generated during installation and saved to `/opt/supabase/credentials.txt`.

## Usage

### Basic Installation

```bash
ansible-playbook -i inventory install.yml \
  -e supabase_domain=supabase.example.com \
  -e admin_email=admin@example.com \
  -e dashboard_password=YourSecurePassword123
```

### Installation with Custom Username

```bash
ansible-playbook -i inventory install.yml \
  -e supabase_domain=supabase.example.com \
  -e admin_email=admin@example.com \
  -e dashboard_username=admin \
  -e dashboard_password=YourSecurePassword123
```

### Installation with SMTP (for email auth)

```bash
ansible-playbook -i inventory install.yml \
  -e supabase_domain=supabase.example.com \
  -e admin_email=admin@example.com \
  -e smtp_host=smtp.sendgrid.net \
  -e smtp_port=587 \
  -e smtp_user=apikey \
  -e smtp_pass=SG.xxxxx \
  -e smtp_sender_email=noreply@example.com
```

### Uninstallation

```bash
ansible-playbook -i inventory uninstall.yml \
  -e supabase_domain=supabase.example.com
```

You will be prompted to confirm deletion of data.

## Post-Installation

### Access the Dashboard

After installation, access Supabase Studio at `https://your-domain.com`

You will be redirected to the **Authelia login page** for 2FA authentication.

#### First-Time Login with 2FA

1. **Navigate** to `https://your-domain.com`
2. **Enter credentials** - Use the email (`admin_email`) and password (`dashboard_password`) you provided during installation
3. **Set up TOTP** - On first login, you'll be prompted to register a TOTP device:
   - Scan the QR code with your authenticator app (Google Authenticator, Authy, etc.)
   - Enter the 6-digit code to verify
4. **Access Dashboard** - After successful 2FA, you'll be redirected to Supabase Studio

#### Subsequent Logins

1. Enter your email and password
2. Enter the 6-digit TOTP code from your authenticator app
3. Access the dashboard

Default credentials and API keys are displayed at the end of installation and saved to:
```
/opt/supabase/credentials.txt
```

**IMPORTANT**: Review and securely store credentials, then delete the file!

### API Keys

Your applications need two keys:
- **Anon Key** (public): Safe to use in browser/client-side code
- **Service Role Key** (private): Server-side only, bypasses Row Level Security

### Connecting Your Application

```javascript
import { createClient } from '@supabase/supabase-js'

const supabase = createClient(
  'https://supabase.example.com',
  'your-anon-key'
)
```

## Architecture

```
Internet
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│  Nginx (System) - SSL Termination                           │
│  Ports 80/443                                               │
└─────────────────────────────────────────────────────────────┘
    │
    ├─────────────────────────────────────────┐
    │                                         │
    ▼                                         ▼
┌──────────────────────┐    ┌─────────────────────────────────┐
│  Authelia (Docker)   │    │  API Routes (Public)            │
│  2FA for Dashboard   │    │  /auth, /rest, /graphql,        │
│  Port 9091           │    │  /realtime, /storage, /functions│
└──────────────────────┘    │  (authenticated via API keys)   │
    │ (auth success)        └─────────────────────────────────┘
    │                                         │
    ▼                                         │
┌─────────────────────────────────────────────┴───────────────┐
│  Kong API Gateway (Docker)                                  │
│  Routes: /auth, /rest, /graphql, /realtime, /storage, etc.  │
└─────────────────────────────────────────────────────────────┘
    │
    ├──► Studio (Dashboard) - Protected by 2FA
    ├──► GoTrue (Auth)
    ├──► PostgREST (REST API)
    ├──► Realtime (WebSockets)
    ├──► Storage API
    ├──► Edge Functions
    └──► PostgreSQL Meta
            │
            ▼
┌─────────────────────────────────────────────────────────────┐
│  PostgreSQL Database                                        │
│  + Supavisor Connection Pooler                              │
└─────────────────────────────────────────────────────────────┘
```

### Authentication Flow

- **Dashboard (`/`)**: Protected by Authelia 2FA - requires email/password + TOTP
- **API Routes** (`/auth/`, `/rest/`, `/storage/`, etc.): Public - authenticated via API keys (anon key or service role key)

## Managing the Service

### View Logs

```bash
# All services
cd /opt/supabase && docker compose logs -f

# Specific service
cd /opt/supabase && docker compose logs -f studio
cd /opt/supabase && docker compose logs -f db
cd /opt/supabase && docker compose logs -f auth
```

### Restart Services

```bash
cd /opt/supabase && docker compose restart

# Restart specific service
cd /opt/supabase && docker compose restart auth
```

### Update to Latest Version

```bash
cd /opt/supabase && docker compose pull && docker compose up -d
```

### Check Service Status

```bash
cd /opt/supabase && docker compose ps
```

## Data Storage

All data is stored in `/opt/supabase/volumes/`:

| Directory | Contents |
|-----------|----------|
| `db/data` | PostgreSQL database files |
| `storage` | Uploaded files |
| `functions` | Edge Functions code |
| `api` | Kong configuration |
| `logs` | Vector logging configuration |
| `authelia` | Authelia data (2FA device registrations) |

## Security Features

- **Automatic HTTPS** with Let's Encrypt certificates
- **Two-Factor Authentication (2FA)**: Authelia TOTP for dashboard access
- **Security headers**: HSTS, X-Content-Type-Options, X-Frame-Options
- **API Gateway**: Kong handles authentication and rate limiting
- **Row Level Security**: PostgreSQL RLS for fine-grained access control
- **JWT Authentication**: Secure token-based auth
- **Dashboard Protection**: Authelia 2FA (email/password + TOTP)

## Troubleshooting

### Service won't start

```bash
# Check container logs
cd /opt/supabase && docker compose logs db
cd /opt/supabase && docker compose logs kong

# Check if ports are in use
ss -tuln | grep -E ':8000|:5432'
```

### Database connection issues

```bash
# Check PostgreSQL is running
docker exec supabase-db pg_isready -U postgres

# Check database logs
cd /opt/supabase && docker compose logs db
```

### Authentication not working

1. Verify JWT secret is consistent across services
2. Check GoTrue logs: `docker compose logs auth`
3. Ensure SMTP is configured if email auth is needed

### Nginx configuration issues

```bash
# Test configuration
sudo nginx -t

# View error logs
sudo tail -f /var/log/nginx/supabase-error.log
```

### SSL certificate issues

```bash
# Check certificate status
sudo certbot certificates

# Renew manually
sudo certbot renew

# Test renewal
sudo certbot renew --dry-run
```

### Authelia / 2FA issues

```bash
# Check Authelia logs
cd /opt/supabase && docker compose logs authelia

# Check if Authelia is running
docker ps | grep authelia

# Restart Authelia
cd /opt/supabase && docker compose restart authelia
```

**Lost TOTP device?** You'll need to reset 2FA:
1. Stop Authelia: `docker compose stop authelia`
2. Remove TOTP registration: `rm -rf /opt/supabase/volumes/authelia/*`
3. Start Authelia: `docker compose start authelia`
4. Re-register your TOTP device on next login

## Cost Comparison

Self-hosting Supabase can significantly reduce costs:

| Provider | Specs | Monthly Cost |
|----------|-------|--------------|
| Supabase Cloud (Pro) | 8GB RAM, 100GB storage | ~$25+ |
| Hetzner VPS | 8 vCPU, 32GB RAM | ~$50 |
| DigitalOcean | 4 vCPU, 8GB RAM | ~$48 |
| Vultr | 4 vCPU, 8GB RAM | ~$48 |

## Limitations

Self-hosted Supabase has some differences from the cloud version:
- No automatic backups (configure your own)
- No built-in monitoring (use external tools)
- Manual updates required
- No support SLA

## Resources

- [Supabase Official Website](https://supabase.com/)
- [Supabase Documentation](https://supabase.com/docs)
- [Supabase Self-Hosting Guide](https://supabase.com/docs/guides/self-hosting)
- [Supabase GitHub Repository](https://github.com/supabase/supabase)
- [Supabase Discord Community](https://discord.supabase.com/)

## License

MIT
