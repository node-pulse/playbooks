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
- **PostgreSQL 18** - Database backend (Docker)
- **Caddy 2** - Reverse proxy with automatic HTTPS (System integration)

## What This Playbook Does

- Installs Docker and Docker Compose (if not already installed)
- Deploys Umami v3 and PostgreSQL 18 using Docker containers
- **System Caddy deployment** for multi-app support:
  - Automatically detects and uses existing system Caddy installation
  - Installs Caddy from official repository if not found
  - Configures automatic HTTPS via Let's Encrypt
  - Enables running multiple applications on one server
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
| `umami_port` | integer | `3000` | Internal port for Umami application |
| `postgres_user` | string | `umami` | PostgreSQL username |
| `postgres_password` | password | auto-generated | PostgreSQL password |
| `postgres_db` | string | `umami` | PostgreSQL database name |
| `app_secret` | password | auto-generated | Secret key for session encryption |
| `umami_version` | string | `postgresql-latest` | Docker image tag (e.g., `postgresql-v3.0.0`) |
| `enable_ssl` | boolean | `true` | Enable automatic HTTPS via Caddy |
| `umami_install_dir` | string | `/opt/umami` | Installation directory |

## System Caddy Deployment

> **Note**: This playbook uses system Caddy only (not Docker). This enables running multiple applications on one server behind a shared reverse proxy.

### How It Works

**System Caddy** (supports multiple apps on one server):

- Caddy installed/running as a system service
- Enables running multiple applications behind one Caddy instance
- Better resource utilization and budget control
- Two scenarios:
  - **Use existing Caddy** - Caddy already installed, playbook adds `/etc/caddy/conf.d/umami.conf`
  - **Install Caddy** - Caddy not found, playbook installs from official repository, then configures

> **Why system Caddy only?** Docker Caddy would monopolize ports 80/443, preventing you from running other applications on the same server. System Caddy allows multiple apps to share one reverse proxy via `/etc/caddy/conf.d/*.conf` pattern.

### Deployment Logic

```
Playbook runs:
    │
    ├─ Caddy installed? ──── YES → Use existing system Caddy
    │                              Add /etc/caddy/conf.d/umami.conf
    │
    ├─ Ports 80/443 free? ─── YES → Install system Caddy
    │                               Configure for Umami
    │
    └─ Ports occupied + No Caddy → ❌ FAIL with clear error
```

### Automatic Detection

The playbook automatically:
- ✅ **Existing Caddy found** → Uses it, adds `/etc/caddy/conf.d/umami.conf`
- ✅ **Ports 80/443 free** → Installs system Caddy, then configures
- ❌ **Ports occupied + No Caddy** → **Fails with error** (free ports or install Caddy first)

### Configuration Details

- **If Caddy exists**: Integrates via `/etc/caddy/conf.d/umami.conf`
- **If Caddy missing**: Installs from official repository
- Creates reverse proxy configuration
- Adds `import /etc/caddy/conf.d/*.conf` to main Caddyfile (if not present)
- Reloads Caddy automatically
- Umami exposed on `127.0.0.1:3000` only (not accessible externally)
- **Perfect for servers running multiple applications**

## Usage

### Basic Installation

```bash
ansible-playbook -i inventory install.yml \
  -e umami_domain=analytics.example.com \
  -e admin_email=admin@example.com
```

This will automatically:
1. Detect if Caddy is installed
2. Install Caddy if needed (from official repository)
3. Configure Caddy for Umami with automatic HTTPS
4. Deploy Umami and PostgreSQL 18 in Docker

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

Your Umami configuration is at:
```
/etc/caddy/conf.d/umami.conf
```

To reload Caddy after manual changes:
```bash
systemctl reload caddy
```

## Data Storage

All data is stored in `/opt/umami/data/`:
- `postgres/` - PostgreSQL 18 database files

SSL certificates are managed by system Caddy at `/var/lib/caddy/`.

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

This error occurs when ports are occupied but Caddy is not installed.

**Solution: Free up the ports or install Caddy manually**
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

### View Caddy logs
```bash
journalctl -u caddy -f
```

### Check SSL certificate
```bash
journalctl -u caddy | grep -i certificate
```

## Dangerous Operations

This playbook performs the following operations:
- Installs Docker and Docker Compose if not present
- Creates PostgreSQL 18 database with persistent storage
- **Installs or configures Caddy** as system service (reverse proxy)
- Opens ports 80 and 443 for web access
- Stores analytics data in /opt/umami/data directory
- May modify /etc/caddy/Caddyfile (adds import directive if missing)

## Architecture

```
Internet → System Caddy (80/443) → Umami (127.0.0.1:3000) → PostgreSQL (5432)
           apt/yum installed       Docker Container        Docker Container
           /etc/caddy/conf.d

           ↓ Can add more apps

           → App2 (127.0.0.1:3001)
           → App3 (127.0.0.1:3002)
           etc.
```

**Multi-app support**: Each app gets its own config file in `/etc/caddy/conf.d/`, all sharing one Caddy instance.

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
