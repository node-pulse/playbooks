# n8n Workflow Automation Platform

Deploy a complete n8n workflow automation stack with PostgreSQL, Caddy reverse proxy, and automatic SSL/TLS support.

## What is n8n?

n8n is an extendable workflow automation tool that allows you to connect anything to everything. It's a fair-code licensed node-based workflow automation tool with over 400+ integrations including Google Sheets, Slack, GitHub, and more.

## What This Playbook Does

- ✅ Installs Docker and Docker Compose
- ✅ Deploys n8n (version 1.120.3) with PostgreSQL backend
- ✅ Configures Caddy reverse proxy with automatic SSL/TLS
- ✅ Sets up persistent data storage
- ✅ Creates systemd service for automatic startup
- ✅ Generates secure credentials automatically
- ✅ Configures webhooks and external access
- ✅ Enables execution data pruning and logging

## Requirements

- **Supported OS**: Ubuntu 20.04/22.04/24.04, Debian 11/12
- `sudo` or root access
- SSH access to target server
- **For SSL**: Valid domain name pointing to your server
- **Minimum Resources**: 2GB RAM, 2 CPU cores, 20GB disk space

## Architecture

This deployment creates a complete stack:

```
Internet
    ↓
Caddy (Port 80/443) → SSL/TLS termination
    ↓
n8n (Port 5678) → Workflow automation
    ↓
PostgreSQL (Port 5432) → Database backend
```

## Variables

| Variable | Description | Default | Type |
|----------|-------------|---------|------|
| `n8n_domain` | Domain name for n8n access | `""` (IP-based) | String |
| `n8n_port` | External HTTP port for n8n | `5678` | Integer |
| `n8n_encryption_key` | Encryption key for credentials | Auto-generated | String |
| `postgres_password` | PostgreSQL password | Auto-generated | String |
| `n8n_basic_auth_user` | Basic auth username | `""` (disabled) | String |
| `n8n_basic_auth_password` | Basic auth password | `""` (disabled) | String |
| `n8n_timezone` | Timezone for n8n | `UTC` | String |
| `enable_ssl` | Enable SSL/TLS with Let's Encrypt | `false` | Boolean |
| `ssl_email` | Email for SSL certificate notifications | `""` | String |
| `n8n_data_dir` | Directory for n8n data | `/opt/n8n` | String |
| `redis_enabled` | Enable Redis queue mode | `false` | Boolean |
| `n8n_webhook_url` | Webhook base URL | Auto-configured | String |

## Example Deployments

### 1. Basic IP-Based Deployment (Development)

```yaml
# Minimal configuration - access via http://your-server-ip:5678
n8n_timezone: "America/New_York"
```

### 2. Domain with SSL/TLS (Production Recommended)

```yaml
n8n_domain: "n8n.example.com"
enable_ssl: true
ssl_email: "admin@example.com"
n8n_timezone: "America/New_York"
n8n_basic_auth_user: "admin"
n8n_basic_auth_password: "your-secure-password"
```

### 3. Custom Port without SSL

```yaml
n8n_domain: "n8n.example.com"
n8n_port: 8080
n8n_timezone: "Europe/London"
```

### 4. Secure Deployment with Custom Credentials

```yaml
n8n_domain: "automation.company.com"
enable_ssl: true
ssl_email: "devops@company.com"
postgres_password: "super-secure-db-password"
n8n_encryption_key: "your-32-character-encryption-key"
n8n_basic_auth_user: "workflow-admin"
n8n_basic_auth_password: "strong-auth-password"
n8n_timezone: "Asia/Tokyo"
n8n_data_dir: "/data/n8n"
```

## Post-Installation

### Access n8n

**With Domain (SSL enabled):**
```
https://n8n.example.com
```

**With Domain (SSL disabled):**
```
http://n8n.example.com
```

**Without Domain:**
```
http://your-server-ip:5678
```

### First-Time Setup

1. Navigate to your n8n URL
2. Create your first admin account
3. Start building workflows!

### Manage the Service

**Check status:**
```bash
sudo systemctl status n8n
```

**View logs:**
```bash
cd /opt/n8n
sudo docker compose logs -f n8n
```

**Restart service:**
```bash
sudo systemctl restart n8n
```

**Stop service:**
```bash
sudo systemctl stop n8n
```

**Start service:**
```bash
sudo systemctl start n8n
```

### View Credentials

All credentials are saved to:
```bash
sudo cat /opt/n8n/credentials.txt
```

**Environment variables:**
```bash
sudo cat /opt/n8n/.env
```

### Database Management

**Connect to PostgreSQL:**
```bash
cd /opt/n8n
sudo docker compose exec pg psql -U n8n -d n8n
```

**Backup database:**
```bash
cd /opt/n8n
sudo docker compose exec pg pg_dump -U n8n n8n > n8n-backup-$(date +%Y%m%d).sql
```

**Restore database:**
```bash
cd /opt/n8n
cat n8n-backup-YYYYMMDD.sql | sudo docker compose exec -T pg psql -U n8n -d n8n
```

## Advanced Configuration

### Custom Webhook URL

If your n8n instance needs a specific webhook URL (e.g., behind a proxy):

```yaml
n8n_webhook_url: "https://workflows.company.com/"
```

### Multiple Environments

Deploy multiple n8n instances on the same server:

```yaml
# Production instance
n8n_data_dir: "/opt/n8n-prod"
n8n_domain: "n8n.example.com"
n8n_port: 5678

# Staging instance
n8n_data_dir: "/opt/n8n-staging"
n8n_domain: "n8n-staging.example.com"
n8n_port: 5679
```

### Timezone Reference

Common timezone values:
- `UTC` - Coordinated Universal Time
- `America/New_York` - US Eastern
- `America/Los_Angeles` - US Pacific
- `Europe/London` - UK
- `Europe/Paris` - Central European
- `Asia/Tokyo` - Japan
- `Australia/Sydney` - Australia

Full list: https://en.wikipedia.org/wiki/List_of_tz_database_time_zones

## Data Persistence

All data is stored in the configured data directory (default: `/opt/n8n`):

```
/opt/n8n/
├── n8n_data/          # n8n workflows, credentials, settings
├── n8n_files/         # File uploads and attachments
├── pg_data/           # PostgreSQL database
├── caddy_data/        # SSL certificates
├── caddy_config/      # Caddy configuration
├── .env               # Environment variables
├── credentials.txt    # Generated credentials
└── docker-compose.yml # Docker configuration
```

### Backup Strategy

**Complete backup:**
```bash
sudo tar -czf n8n-backup-$(date +%Y%m%d).tar.gz /opt/n8n
```

**Exclude large PostgreSQL data:**
```bash
sudo tar -czf n8n-backup-$(date +%Y%m%d).tar.gz \
  --exclude=/opt/n8n/pg_data \
  /opt/n8n
```

**Restore:**
```bash
sudo systemctl stop n8n
sudo tar -xzf n8n-backup-YYYYMMDD.tar.gz -C /
sudo systemctl start n8n
```

## Security Considerations

### Production Security Checklist

- ✅ **Use SSL/TLS**: Always enable SSL for production deployments
- ✅ **Basic Auth**: Enable basic authentication as additional security layer
- ✅ **Strong Passwords**: Use strong, unique passwords (auto-generated recommended)
- ✅ **Firewall**: Configure firewall to only allow necessary ports
- ✅ **Regular Updates**: Keep n8n and Docker images updated
- ✅ **Backup Encryption**: Encrypt backups containing credentials
- ✅ **Network Isolation**: Use private networks for database access
- ✅ **Monitoring**: Set up monitoring and alerting

### Secure Credential Management

**Never commit credentials to version control!**

Store credentials securely:
```bash
# Use ansible-vault for sensitive variables
ansible-vault encrypt_string 'my-secret-password' --name 'postgres_password'
```

### Firewall Configuration

```bash
# Allow HTTP/HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# If using custom port without Caddy
sudo ufw allow 5678/tcp

# Enable firewall
sudo ufw enable
```

## Troubleshooting

### Check Service Status

```bash
# Systemd service
sudo systemctl status n8n

# Docker containers
cd /opt/n8n
sudo docker compose ps

# View all logs
sudo docker compose logs -f
```

### Common Issues

**Issue: n8n won't start**
```bash
# Check logs
cd /opt/n8n
sudo docker compose logs n8n

# Check database connection
sudo docker compose logs pg
```

**Issue: SSL certificate not working**
- Ensure domain DNS is pointed to server
- Verify port 80 and 443 are open
- Check Caddy logs: `sudo docker compose logs caddy`
- Verify email in SSL configuration

**Issue: Can't access n8n**
```bash
# Check if ports are listening
sudo netstat -tlnp | grep -E '80|443|5678'

# Test local access
curl http://localhost:5678/healthz
```

**Issue: Workflows not executing**
- Check n8n logs for errors
- Verify timezone settings
- Check execution timeout settings
- Ensure adequate system resources

### Reset Admin Password

```bash
cd /opt/n8n
sudo docker compose exec n8n n8n user:reset-password --email admin@example.com
```

### Completely Reset Installation

```bash
sudo systemctl stop n8n
cd /opt/n8n
sudo docker compose down -v
sudo rm -rf /opt/n8n/*
# Then run the playbook again
```

## Uninstallation

### Remove n8n (Keep Data)

```yaml
# Run uninstall playbook
ansible-playbook uninstall.yml
```

### Remove Everything (Including Data)

```yaml
# Run with remove_data flag
ansible-playbook uninstall.yml -e "remove_data=true"
```

### Remove n8n and Docker

```yaml
# Remove everything including Docker
ansible-playbook uninstall.yml -e "remove_data=true remove_docker=true"
```

## Performance Optimization

### Resource Recommendations

**Small (1-10 workflows):**
- 2 CPU cores
- 2GB RAM
- 20GB storage

**Medium (10-50 workflows):**
- 4 CPU cores
- 4GB RAM
- 50GB storage

**Large (50+ workflows):**
- 8+ CPU cores
- 8GB+ RAM
- 100GB+ storage

### Execution Data Pruning

The playbook automatically enables execution data pruning:
- Old execution data is deleted after 168 hours (7 days)
- Prevents database growth
- Configurable in `/opt/n8n/.env`

## Monitoring

### Health Check Endpoint

```bash
curl http://localhost:5678/healthz
```

### Prometheus Metrics

n8n exposes Prometheus metrics at `/metrics` endpoint.

### Log Analysis

```bash
# View recent errors
cd /opt/n8n
sudo docker compose logs n8n | grep ERROR

# Monitor in real-time
sudo docker compose logs -f --tail=100 n8n
```

## Integration Examples

### Webhook Workflows

Your webhook URL format:
```
https://n8n.example.com/webhook/your-webhook-path
```

### Calling External APIs

n8n can integrate with:
- REST APIs
- GraphQL endpoints
- SOAP services
- Databases (MySQL, PostgreSQL, MongoDB, etc.)
- Cloud services (AWS, GCP, Azure)
- 400+ pre-built integrations

## Updates and Maintenance

### Update n8n Version

1. Edit `/opt/n8n/docker-compose.yml`
2. Change n8n version: `n8nio/n8n:1.120.3` → `n8nio/n8n:latest`
3. Restart: `sudo systemctl restart n8n`

### Update PostgreSQL

1. Backup database first!
2. Edit compose file: `postgres:16` → `postgres:17`
3. Follow PostgreSQL upgrade guide

### Regular Maintenance

**Weekly:**
- Check disk space: `df -h`
- Review logs for errors
- Verify backups are working

**Monthly:**
- Update Docker images
- Review execution data retention
- Check SSL certificate expiry

**Quarterly:**
- Security audit
- Performance review
- Workflow optimization

## Support and Resources

### Official Documentation
- n8n Documentation: https://docs.n8n.io
- Community Forum: https://community.n8n.io
- GitHub: https://github.com/n8n-io/n8n

### Getting Help

For issues with this playbook:
- Check the troubleshooting section above
- Review logs in `/opt/n8n/`
- Consult n8n documentation

For n8n-specific questions:
- Visit https://community.n8n.io
- Check https://docs.n8n.io

## License

MIT

## Maintained By

Node Pulse Community

## Credits

This playbook is inspired by the excellent n8n deployment setup at https://github.com/guiyumin/n88n
