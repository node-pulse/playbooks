# Umami v3 (PostgreSQL + Caddy) Playbook

**Opinionated deployment** of [Umami v3](https://umami.is/) with PostgreSQL database and Caddy reverse proxy for automatic HTTPS.

> **Note**: This is an opinionated stack using Caddy as the reverse proxy. If you prefer Nginx, Traefik, or another proxy, someone in the community can create alternative playbooks (e.g., `umami-v3-postgresql-nginx`).

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
- **PostgreSQL 15** - Database backend (Docker)
- **Caddy 2** - Reverse proxy with automatic HTTPS (Docker or System integration)

## What This Playbook Does

- Installs Docker and Docker Compose (if not already installed)
- Deploys Umami v3 and PostgreSQL using Docker containers
- **Smart Caddy deployment** with 3 modes:
  - **Auto-detect** - Automatically determines the best Caddy deployment strategy
  - **Docker mode** - Deploys Caddy in a Docker container (new installations)
  - **System mode** - Integrates with existing system Caddy installation
  - **Disabled mode** - Skip Caddy, expose Umami on port only (use your own proxy)
- Creates systemd integration for automatic startup
- Configures health checks and monitoring

## Requirements

- Supported OS: Ubuntu 20.04/22.04/24.04, Debian 11/12, RHEL/Rocky/Alma/Oracle 8/9, Amazon Linux 2/2023
- Architecture: amd64 or arm64
- Ansible version: >= 2.10
- Domain name pointing to your server (for SSL)
- Ports 80 and 443 available (for Docker Caddy mode)

## Configuration Variables

### Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `umami_domain` | Fully qualified domain name for Umami | `analytics.example.com` |
| `admin_email` | Email for SSL certificate notifications (required if SSL enabled) | `admin@example.com` |

### Optional Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `caddy_mode` | select | `auto` | Caddy deployment mode: `auto`, `docker`, `system`, or `disabled` |
| `umami_port` | integer | `3000` | Internal port for Umami application |
| `postgres_user` | string | `umami` | PostgreSQL username |
| `postgres_password` | password | auto-generated | PostgreSQL password |
| `postgres_db` | string | `umami` | PostgreSQL database name |
| `app_secret` | password | auto-generated | Secret key for session encryption |
| `umami_version` | string | `postgresql-latest` | Docker image tag (e.g., `postgresql-v3.0.0`) |
| `enable_ssl` | boolean | `true` | Enable automatic HTTPS via Caddy |
| `umami_install_dir` | string | `/opt/umami` | Installation directory |

## Caddy Deployment Modes

> **Note**: Caddy is mandatory in this playbook. If you prefer Nginx/Traefik, use a different playbook variant.

### Deployment Cases Overview

There are **2 main cases** for Caddy deployment:

**Case 1: Docker Caddy**
- Caddy deployed as a Docker container alongside Umami
- Handles ports 80/443
- Fully self-contained

**Case 2: System Caddy**
- Caddy installed/running as a system service
- Two subcases:
  - **2.1: Use existing Caddy** - Caddy already installed, playbook adds `/etc/caddy/conf.d/umami.conf`
  - **2.2: Install Caddy** - Caddy not found, playbook installs from official repository, then configures

The playbook automatically determines which case to use based on your system state.

**Decision Tree:**
```
caddy_mode=auto
    │
    ├─ Caddy binary found? ────────── YES → Case 2.1 (Use existing system Caddy)
    │
    ├─ Ports 80/443 free? ────────── YES → Case 1 (Deploy Docker Caddy)
    │
    └─ Ports occupied + No Caddy ─── ❌ FAIL (User must choose)

caddy_mode=docker ──────────────────────→ Case 1 (Deploy Docker Caddy)

caddy_mode=system
    │
    └─ Caddy installed? ──── YES → Case 2.1 (Use existing)
                        └─── NO ─→ Case 2.2 (Install, then configure)
```

### Auto Mode (Default)
The playbook automatically detects the best deployment strategy:
- ✅ **Existing Caddy found** → Case 2.1 (Use existing system Caddy)
- ✅ **Ports 80/443 free** → Case 1 (Deploy Docker Caddy)
- ❌ **Ports occupied + No Caddy** → **Fails with clear error message**

If auto-detection fails, you'll get actionable options:
1. Free up ports 80/443 and re-run
2. Manually set `-e caddy_mode=system` (installs Caddy for you - Case 2.2)
3. Use a different playbook variant if you need Nginx/Traefik

### Docker Mode
Force deployment of Caddy in a Docker container:
```bash
-e caddy_mode=docker
```
- Deploys Caddy as a Docker service
- Handles HTTPS certificates automatically
- Opens ports 80 and 443
- Best for dedicated Umami servers

### System Mode
Install or use existing system Caddy:
```bash
-e caddy_mode=system
```
- **If Caddy exists**: Integrates with it via `/etc/caddy/conf.d/umami.conf`
- **If Caddy missing**: Installs Caddy from official repository
- Creates reverse proxy configuration
- Adds `import /etc/caddy/conf.d/*.conf` to main Caddyfile (if not present)
- Reloads Caddy automatically
- Umami exposed on localhost:3000 only
- Best for servers running multiple applications

## Usage

### Basic Installation (Auto-detect Caddy)

```bash
ansible-playbook -i inventory install.yml \
  -e umami_domain=analytics.example.com \
  -e admin_email=admin@example.com
```

### Force Docker Caddy Mode

```bash
ansible-playbook -i inventory install.yml \
  -e umami_domain=analytics.example.com \
  -e admin_email=admin@example.com \
  -e caddy_mode=docker
```

### Install or Use System Caddy

```bash
ansible-playbook -i inventory install.yml \
  -e umami_domain=analytics.example.com \
  -e admin_email=admin@example.com \
  -e caddy_mode=system
```

If Caddy is not installed, it will be installed from the official Caddy repository.

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

⚠️ **IMPORTANT**: Change the default password immediately after first login!

### Adding Websites

1. Log in to Umami
2. Go to Settings > Websites
3. Click "Add Website"
4. Enter website details and get tracking code
5. Add the tracking script to your website's `<head>` section

### Managing the Service

```bash
# View logs
cd /opt/umami && docker compose logs -f

# Restart services
cd /opt/umami && docker compose restart

# Stop services
cd /opt/umami && docker compose stop

# Start services
cd /opt/umami && docker compose start

# Update to latest version
cd /opt/umami && docker compose pull && docker compose up -d
```

### System Caddy Integration

If using `caddy_mode=system`, your Umami configuration is at:
```
/etc/caddy/conf.d/umami.conf
```

To reload Caddy after manual changes:
```bash
systemctl reload caddy
```

## Data Storage

All data is stored in `/opt/umami/data/`:
- `postgres/` - PostgreSQL database files
- `caddy/` - SSL certificates and Caddy configuration (Docker mode only)

## Security Features

- Automatic HTTPS with Let's Encrypt certificates
- Security headers (HSTS, X-Content-Type-Options, etc.)
- PostgreSQL with password authentication
- No cookies or personal data collection
- IP address anonymization

## Health Checks

The playbook configures three health checks:
1. TCP port check on port 3000
2. HTTP heartbeat endpoint check
3. Docker container status check

## Troubleshooting

### Playbook fails: "Ports 80 and/or 443 are already in use"

This error occurs when auto-detection finds ports occupied but no Caddy installed.

**Solution 1: Use system Caddy mode**
```bash
ansible-playbook install.yml \
  -e umami_domain=analytics.example.com \
  -e admin_email=admin@example.com \
  -e caddy_mode=system
```
This will install Caddy and configure it to work with your existing services.

**Solution 2: Free up the ports**
```bash
# Find what's using the ports
sudo ss -tulpn | grep ':80\|:443'

# Stop the conflicting service (example: nginx)
sudo systemctl stop nginx
sudo systemctl disable nginx

# Re-run the playbook
ansible-playbook install.yml -e umami_domain=analytics.example.com -e admin_email=admin@example.com
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

### View Caddy logs (Docker mode)
```bash
cd /opt/umami && docker compose logs caddy
```

### View Caddy logs (System mode)
```bash
journalctl -u caddy -f
```

### Check SSL certificate
```bash
# Docker mode
cd /opt/umami && docker compose logs caddy | grep -i certificate

# System mode
journalctl -u caddy | grep -i certificate
```

## Dangerous Operations

This playbook performs the following operations:
- Installs Docker and Docker Compose if not present
- Creates PostgreSQL database with persistent storage
- **Installs or configures Caddy** as reverse proxy (Docker or System mode)
- Opens ports 80 and 443 for web access (Docker mode or System mode)
- Stores analytics data in /opt/umami/data directory
- May modify /etc/caddy/Caddyfile (System mode)

## Architecture

### Docker Mode
```
Internet → Caddy (80/443) → Umami (3000) → PostgreSQL (5432)
           Docker Container   Docker         Docker
```

### System Mode
```
Internet → System Caddy (80/443) → Umami (3000) → PostgreSQL (5432)
           apt/yum installed       Docker         Docker
           /etc/caddy/conf.d
```

## Alternative Playbooks

Don't like Caddy? The community can create alternative playbooks:
- `umami-v3-postgresql-nginx` - Nginx reverse proxy
- `umami-v3-postgresql-traefik` - Traefik reverse proxy
- `umami-v3-mysql-caddy` - MySQL database variant

## License

MIT

## Resources

- [Umami Official Website](https://umami.is/)
- [Umami Documentation](https://umami.is/docs)
- [Umami GitHub Repository](https://github.com/umami-software/umami)
- [Caddy Documentation](https://caddyserver.com/docs/)
- [Node Pulse Playbooks](https://github.com/node-pulse/playbooks)
