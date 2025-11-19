# Umami v3 (PostgreSQL + Nginx) Playbook

**Opinionated deployment** of [Umami v3](https://umami.is/) with PostgreSQL database and Nginx reverse proxy with automatic SSL via Certbot.

> **Note**: This is an opinionated stack using Nginx as the reverse proxy. If you prefer Caddy, Traefik, or another proxy, use alternative playbook variants like `umami-v3-postgresql-caddy`.

## Overview

Umami is a simple, fast, privacy-focused alternative to Google Analytics that:
- Does not use cookies and does not collect personal data (GDPR compliant)
- Anonymizes IP addresses to protect visitor privacy
- Does not track users across websites or collect PII
- Provides essential insights into website traffic and user behavior
- Features a modern interface with advanced analytics (v3)

## Technology Stack

This playbook deploys:
- **Umami v3** - Modern web analytics (Docker)
- **PostgreSQL 18** - Database backend (Docker)
- **Nginx** - Reverse proxy with automatic SSL (System installation)
- **Certbot** - Automatic SSL certificate management (Let's Encrypt)

## What This Playbook Does

- Installs Docker and Docker Compose (if not already installed)
- Deploys Umami v3 and PostgreSQL using Docker containers
- **Installs or uses system Nginx** with automatic configuration
- **Automatically obtains SSL certificate** from Let's Encrypt using Certbot
- Configures automatic certificate renewal
- Sets up security headers and optimizations
- Creates systemd integration for automatic startup

## Requirements

- Supported OS: Ubuntu 20.04/22.04/24.04, Debian 11/12, RHEL/Rocky/Alma/Oracle 8/9, Amazon Linux 2/2023
- Architecture: amd64 or arm64
- Ansible version: >= 2.10
- **Domain name pointing to your server** (required for SSL)
- Ports 80 and 443 available

## Configuration Variables

### Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `umami_domain` | Fully qualified domain name for Umami | `analytics.example.com` |
| `admin_email` | Email for SSL certificate notifications (required if SSL enabled) | `admin@example.com` |

### Optional Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `umami_port` | integer | `3000` | Internal port for Umami application |
| `postgres_user` | string | `umami` | PostgreSQL username |
| `postgres_password` | password | auto-generated | PostgreSQL password |
| `postgres_db` | string | `umami` | PostgreSQL database name |
| `app_secret` | password | auto-generated | Secret key for session encryption |
| `umami_version` | string | `postgresql-latest` | Docker image tag (e.g., `postgresql-v3.0.0`) |
| `enable_ssl` | boolean | `true` | Automatically obtain SSL certificate via Certbot |
| `umami_install_dir` | string | `/opt/umami` | Installation directory |

## System Nginx Deployment with Automatic SSL

> **Note**: This playbook uses system Nginx only (not Docker). This enables running multiple applications on one server behind a shared reverse proxy. SSL is automatically configured via Certbot.

### How It Works

**System Nginx with Certbot** (supports multiple apps on one server):

- Nginx installed/running as a system service
- Enables running multiple applications behind one Nginx instance
- Automatic SSL certificate management via Certbot (Let's Encrypt)
- Better resource utilization and budget control
- Two scenarios:
  - **Use existing Nginx** - Nginx already installed, playbook adds Umami configuration
  - **Install Nginx** - Nginx not found, playbook installs from distribution repository

> **Why system Nginx only?** Docker Nginx would monopolize ports 80/443, preventing you from running other applications on the same server. System Nginx allows multiple apps to share one reverse proxy.

### Deployment Logic

```
Playbook runs:
    │
    ├─ Nginx installed? ──── YES → Use existing Nginx
    │                              Add Umami config
    │                              Run Certbot for SSL
    │
    ├─ Ports 80/443 free? ─── YES → Install Nginx
    │                               Configure for Umami
    │                               Run Certbot for SSL
    │
    └─ Ports occupied + No Nginx → ❌ FAIL with clear error
```

### Automatic Detection & SSL

The playbook automatically:
- ✅ **Existing Nginx found** → Uses it, adds Umami configuration
- ✅ **Nginx not found** → Installs from repository, then configures
- ✅ **SSL enabled** → Runs Certbot to obtain Let's Encrypt certificate
- ✅ **Auto-renewal** → Sets up cron job for certificate renewal
- ❌ **Ports occupied + No Nginx** → **Fails with error** (free ports or install Nginx first)

## Usage

### Basic Installation with Automatic SSL

```bash
ansible-playbook -i inventory install.yml \
  -e umami_domain=analytics.example.com \
  -e admin_email=admin@example.com
```

This will automatically:
1. Detect if Nginx is installed
2. Install Nginx if needed (from distribution repository)
3. Deploy Umami and PostgreSQL 18 in Docker
4. Obtain SSL certificate via Certbot
5. Configure HTTPS with security headers
6. Set up automatic certificate renewal

### Uninstallation

```bash
ansible-playbook -i inventory uninstall.yml
```

You will be prompted to confirm deletion of analytics data.

## Post-Installation

### Default Credentials

After installation, access Umami at `https://your-domain.com` with:

- **Username**: `admin`
- **Password**: `umami`

⚠️ **IMPORTANT - Change Default Credentials**:
1. Log in with default credentials
2. Go to **Settings → Team** (or **Settings → Accounts**)
3. Click **Edit** on the admin user
4. Change **username** from `admin` to something unique
5. Change **password** from `umami` to a strong, unique password
6. Click **Save**

**Note**: Umami does not currently support native 2FA. For additional security, consider:
- Using a password manager with a long, random password
- Restricting admin access by IP address via Nginx
- Deploying Authelia/Authentik for external 2FA protection (advanced)

**How Authelia 2FA Works:**
```
User → Nginx → Authelia (checks if logged in) → Umami
                    ↓
              Not logged in?
                    ↓
           Show login page with 2FA
```

**TODO**: Add Authelia integration playbook for 2FA support

### SSL Certificate

The SSL certificate is automatically:
- Obtained from Let's Encrypt during installation
- Configured in Nginx
- Set to auto-renew twice daily via cron job

Certificate location: `/etc/letsencrypt/live/{{ umami_domain }}/`

### Adding Websites

1. Log in to Umami
2. Go to Settings > Websites
3. Click "Add Website"
4. Enter website details and get tracking code
5. Add the tracking script to your website's `<head>` section

### Managing the Service

```bash
# View Umami logs
cd /opt/umami && docker compose logs -f

# Restart Umami services
cd /opt/umami && docker compose restart

# Stop/Start Umami
cd /opt/umami && docker compose stop
cd /opt/umami && docker compose start

# Update to latest version
cd /opt/umami && docker compose pull && docker compose up -d

# Check Nginx status
systemctl status nginx

# Reload Nginx configuration
systemctl reload nginx

# Check SSL certificate expiry
certbot certificates
```

## Data Storage

All data is stored in `/opt/umami/data/`:
- `postgres/` - PostgreSQL 18 database files

Nginx configuration:
- `/etc/nginx/sites-available/umami` (Debian/Ubuntu)
- `/etc/nginx/conf.d/umami.conf` (RHEL/CentOS/Rocky/Alma)

SSL certificates:
- `/etc/letsencrypt/live/{{ umami_domain }}/`

## Security Features

- **Automatic HTTPS** with Let's Encrypt certificates
- **Security headers**: HSTS, X-Content-Type-Options, X-Frame-Options, CSP
- **Automatic certificate renewal** via cron (twice daily)
- PostgreSQL with password authentication
- No cookies or personal data collection
- IP address anonymization

## Health Checks

The playbook configures four health checks:
1. TCP port check on port 3000
2. HTTP heartbeat endpoint check
3. Docker container status check
4. Nginx service status check

## Troubleshooting

### Playbook fails: "Ports 80 and/or 443 are already in use"

This error occurs when ports are occupied but Nginx is not installed.

**Solution 1: Free up the ports**
```bash
# Find what's using the ports
sudo ss -tulpn | grep ':80\|:443'

# Stop the conflicting service
sudo systemctl stop <service-name>
sudo systemctl disable <service-name>

# Re-run the playbook
ansible-playbook install.yml -e umami_domain=analytics.example.com -e admin_email=admin@example.com
```

**Solution 2: Install Nginx manually first**
```bash
# Debian/Ubuntu
sudo apt install nginx

# RHEL/CentOS/Rocky/Alma
sudo yum install nginx

# Then re-run the playbook
ansible-playbook install.yml \
  -e umami_domain=analytics.example.com \
  -e admin_email=admin@example.com
```

### Check service status
```bash
cd /opt/umami && docker compose ps
```

### View application logs
```bash
cd /opt/umami && docker compose logs umami
```

### View database logs
```bash
cd /opt/umami && docker compose logs db
```

### View Nginx logs
```bash
# Access logs
sudo tail -f /var/log/nginx/umami-access.log

# Error logs
sudo tail -f /var/log/nginx/umami-error.log
```

### Test Nginx configuration
```bash
sudo nginx -t
```

### Check SSL certificate status
```bash
# List all certificates
sudo certbot certificates

# Test certificate renewal
sudo certbot renew --dry-run
```

### Manually renew SSL certificate
```bash
sudo certbot renew
sudo systemctl reload nginx
```

## Dangerous Operations

This playbook performs the following operations:
- Installs Docker and Docker Compose if not present
- Creates PostgreSQL 18 database with persistent storage
- **Installs Nginx** if not already present
- **Installs Certbot** and obtains SSL certificate from Let's Encrypt
- Opens ports 80 and 443 for web access
- Stores analytics data in /opt/umami/data directory
- Creates Nginx configuration in /etc/nginx/
- Sets up automatic certificate renewal via cron

## Architecture

```
Internet → Nginx (80/443) → Umami (3000) → PostgreSQL (5432)
           System Service     Docker         Docker
           + SSL (Certbot)
```

## Alternative Playbooks

Don't like Nginx? Try these alternative playbooks:
- `umami-v3-postgresql-caddy` - Caddy reverse proxy with automatic HTTPS
- `umami-v3-postgresql-traefik` - Traefik reverse proxy (community)

## License

MIT

## Resources

- [Umami Official Website](https://umami.is/)
- [Umami Documentation](https://umami.is/docs)
- [Umami GitHub Repository](https://github.com/umami-software/umami)
- [Nginx Documentation](https://nginx.org/en/docs/)
- [Certbot Documentation](https://certbot.eff.org/)
- [Node Pulse Playbooks](https://github.com/node-pulse/playbooks)
