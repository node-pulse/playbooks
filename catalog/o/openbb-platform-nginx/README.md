# OpenBB Platform API (Nginx) Playbook

Opinionated Ansible playbook for deploying the OpenBB Platform API with Nginx reverse proxy and automatic SSL via Certbot.

## Overview

This playbook deploys the [OpenBB Platform](https://github.com/OpenBB-finance/OpenBB), an open-source financial data platform that helps data engineers integrate proprietary, licensed, and public data sources into downstream applications like AI copilots and research dashboards.

### What Gets Installed

- OpenBB Platform API (Docker container)
- System Nginx as reverse proxy
- Certbot for automatic SSL certificate management
- Docker and Docker Compose (if not already installed)

### Deployment Architecture

```
Internet
    ↓
Nginx (ports 80/443) + SSL/TLS
    ↓
OpenBB Platform API (localhost:6900)
    ↓
Data Storage (/opt/openbb/data)
```

## Prerequisites

- Supported OS:
  - Ubuntu 20.04, 22.04, 24.04
  - Debian 11, 12
  - RHEL 8, 9
  - Rocky Linux 8, 9
  - AlmaLinux 8, 9
  - Oracle Linux 8, 9
  - Amazon Linux 2, 2023
- Root or sudo access
- Domain name pointing to your server (for SSL)
- Ports 80 and 443 available

## Quick Start

### Installation

```bash
ansible-playbook install.yml \
  -e openbb_domain=openbb.example.com \
  -e admin_email=admin@example.com
```

### Required Variables

- `openbb_domain`: Fully qualified domain name (e.g., `openbb.example.com`)
- `admin_email`: Email for SSL certificate notifications (required if SSL is enabled)

### Optional Variables

- `openbb_port`: Internal application port (default: `6900`)
- `enable_ssl`: Enable automatic SSL via Certbot (default: `true`)
- `openbb_install_dir`: Installation directory (default: `/opt/openbb`)

## Features

### System Nginx with Multi-App Support

This playbook uses **system Nginx** (not Docker Nginx) to enable running multiple applications on a single server:

- All apps share one Nginx instance
- Better resource utilization
- Budget-friendly (no need for multiple servers)
- Consistent pattern across all playbooks

### Automatic SSL/TLS

When `enable_ssl` is true (default), the playbook:

1. Obtains SSL certificate from Let's Encrypt via Certbot
2. Configures automatic HTTPS redirect
3. Sets up auto-renewal via cron
4. Applies security best practices (HSTS, security headers)

### Data Persistence

OpenBB configuration and data are stored in:
- `/opt/openbb/data` (mounted as `~/.openbb_platform` in container)

This directory persists across container restarts and updates.

## Post-Installation

### Access the API

After installation completes:

1. Visit: `https://openbb.example.com` (or your configured domain)
2. API Documentation: `https://openbb.example.com/docs`

### Configure API Keys

OpenBB Platform requires API keys for various data providers. Configure them through the API interface or by editing the configuration files in `/opt/openbb/data`.

For detailed setup guides, visit: https://docs.openbb.co

### View Logs

```bash
docker compose -f /opt/openbb/compose.yml logs -f
```

### Restart the Service

```bash
docker compose -f /opt/openbb/compose.yml restart
```

### Update to Latest Version

```bash
cd /opt/openbb
docker compose pull
docker compose up -d
```

## Uninstallation

```bash
ansible-playbook uninstall.yml
```

This will:
- Stop and remove OpenBB containers
- Remove Docker images
- Remove Nginx configuration
- Revoke SSL certificates
- Optionally remove data directory

**Note:** Docker, Nginx, and Certbot remain installed for other applications.

## Security Considerations

### Firewall Configuration

The playbook does not automatically configure firewall rules. Ensure ports 80 and 443 are open:

```bash
# UFW (Ubuntu/Debian)
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Firewalld (RHEL/Rocky/Alma)
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload
```

### API Security

By default, the OpenBB API is exposed through Nginx. Consider:

- Using authentication/authorization mechanisms
- Implementing rate limiting
- Restricting access by IP if needed
- Reviewing OpenBB's security documentation

### SSL/TLS Best Practices

The playbook automatically configures:
- Strong SSL protocols (TLS 1.2+)
- Secure cipher suites
- HSTS headers
- Security headers (X-Frame-Options, X-Content-Type-Options, etc.)

## Troubleshooting

### Ports Already in Use

If ports 80/443 are occupied but Nginx is not installed, the playbook will fail with a clear error message. Options:

1. Free up the ports and re-run
2. Install Nginx manually first

### Container Won't Start

Check logs:
```bash
docker compose -f /opt/openbb/compose.yml logs
```

Common issues:
- Port conflicts
- Insufficient memory
- Configuration errors

### SSL Certificate Fails

Ensure:
- Domain DNS points to your server
- Ports 80/443 are open and accessible
- Email address is valid
- Domain validation can complete

### API Key Configuration

If you need to configure API keys:

1. Access the configuration directory: `/opt/openbb/data`
2. Edit configuration files as needed
3. Restart the container: `docker compose -f /opt/openbb/compose.yml restart`

## Architecture Details

### Docker Compose Structure

```yaml
services:
  openbb:
    image: ghcr.io/openbb-finance/openbb-platform:latest
    ports:
      - "127.0.0.1:6900:6900"
    volumes:
      - /opt/openbb/data:/root/.openbb_platform
    restart: unless-stopped
```

### Nginx Configuration

- HTTP (port 80): Redirects to HTTPS or serves for Certbot validation
- HTTPS (port 443): Proxies to OpenBB API with security headers
- Logs: `/var/log/nginx/openbb-access.log` and `/var/log/nginx/openbb-error.log`

### File Structure

```
/opt/openbb/
├── compose.yml          # Docker Compose configuration
└── data/               # Persistent data (API keys, configuration)
    └── .openbb_platform/

/etc/nginx/
├── sites-available/openbb    # Nginx config (Debian/Ubuntu)
├── sites-enabled/openbb      # Symlink (Debian/Ubuntu)
└── conf.d/openbb.conf        # Nginx config (RHEL/Rocky/Alma)
```

## Multi-Application Deployment

This playbook follows the standard pattern for multi-app support. You can run multiple playbooks on the same server:

```bash
# Deploy OpenBB
ansible-playbook openbb-platform-nginx/install.yml \
  -e openbb_domain=openbb.example.com \
  -e admin_email=admin@example.com

# Deploy Umami (analytics)
ansible-playbook umami-v3-postgresql-nginx/install.yml \
  -e umami_domain=analytics.example.com \
  -e admin_email=admin@example.com

# All apps share the same Nginx instance
```

## API Usage Examples

Once deployed, you can access the OpenBB Platform API:

```bash
# Health check
curl https://openbb.example.com/api/v1/health

# Access API documentation
# Visit: https://openbb.example.com/docs
```

For comprehensive API usage guides, visit the [OpenBB documentation](https://docs.openbb.co).

## Additional Resources

- [OpenBB Platform GitHub](https://github.com/OpenBB-finance/OpenBB)
- [OpenBB Documentation](https://docs.openbb.co)
- [OpenBB Workspace](https://pro.openbb.co)
- [Node Pulse Playbooks](https://github.com/node-pulse/playbooks)

## License

MIT License - See LICENSE file for details

## Support

For playbook-specific issues:
- Open an issue: https://github.com/node-pulse/playbooks/issues

For OpenBB Platform issues:
- Visit: https://github.com/OpenBB-finance/OpenBB/issues
- Documentation: https://docs.openbb.co

## Contributing

Contributions are welcome! Please ensure:
- Follow the existing playbook patterns
- Test on supported OS distributions
- Update documentation as needed
- Maintain the standard Nginx deployment pattern

---

**Generated by Node Pulse Admiral**
