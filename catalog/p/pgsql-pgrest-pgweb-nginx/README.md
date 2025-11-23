# PostgreSQL Stack (PostgreSQL 18 + PostgREST + pgweb + Nginx) Playbook

**Opinionated deployment** of a complete PostgreSQL service stack with JWT-authenticated REST API, 2FA-protected web UI, and automatic SSL.

## Overview

This playbook creates a production-ready PostgreSQL service featuring:
- **PostgreSQL 18** - Latest PostgreSQL database
- **PostgREST** - RESTful API with JWT authentication
- **JWT Auth Service** - Token-based API authentication
- **pgweb** - Web-based database browser (protected by Authelia 2FA)
- **Authelia** - 2FA authentication for pgweb access
- **Nginx** - Reverse proxy with automatic SSL

## Technology Stack

This playbook deploys:
- **PostgreSQL 18** - Database server (Docker)
- **PostgREST** - RESTful API with JWT authentication (Docker)
- **JWT Auth Service** - Custom Python/Flask authentication service (Docker)
- **pgweb** - Web UI for database management (Docker)
- **Authelia** - 2FA authentication protecting pgweb (Docker)
- **Nginx** - Reverse proxy with automatic SSL (System installation)
- **Certbot** - Automatic SSL certificate management (Let's Encrypt)

## What This Playbook Does

- Installs Docker and Docker Compose (if not already installed)
- Deploys PostgreSQL 18, PostgREST, JWT Auth, pgweb, and Authelia using Docker containers
- **Configures JWT authentication** for PostgREST API with role-based access control
- **Sets up Authelia 2FA** to protect pgweb access
- **Installs or uses system Nginx** with automatic configuration
- **Automatically obtains SSL certificates** for 3 domains (API, Auth, pgweb) via Certbot
- Creates PostgreSQL roles with proper permissions (anon, api_user, admin)
- Configures automatic certificate renewal
- Sets up security headers and optimizations

## Architecture

```
Internet → Nginx (80/443)
           ├─→ PostgREST API (3000) → PostgreSQL (5432)
           │   ↑ (requires JWT token)
           │
           ├─→ JWT Auth Service (5000)
           │   (issues JWT tokens after password auth)
           │
           └─→ Authelia (9091) → pgweb (8081) → PostgreSQL (5432)
               (2FA required)
```

**Security Model:**
- **PostgreSQL**: Direct access on port 5432 (configure firewall as needed)
- **PostgREST API**: Requires valid JWT token (get from Auth Service)
  - Anonymous role: No access by default (or read-only on specific tables)
  - API User role: Read/write access to all tables
  - Admin role: Full database access
- **JWT Auth Service**: Password authentication, issues JWT tokens
- **pgweb**: Protected by Authelia with 2FA authentication

**Authentication Flow:**
1. User authenticates at Auth Service (username + password) → receives JWT token
2. User calls PostgREST API with JWT token in `Authorization` header
3. PostgREST validates token and switches to the appropriate PostgreSQL role
4. Database executes query with role's permissions

## Requirements

- Supported OS: Ubuntu 20.04/22.04/24.04, Debian 11/12, RHEL/Rocky/Alma/Oracle 8/9, Amazon Linux 2/2023
- Architecture: amd64 or arm64
- Ansible version: >= 2.10
- **Three domain names pointing to your server** (API, Auth, pgweb)
- Ports 80, 443, and 5432 available

## Configuration Variables

### Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `domain` | Base domain for PostgreSQL service | `db.example.com` |
| `pgweb_domain` | Domain for pgweb web interface | `pgweb.example.com` |
| `postgrest_domain` | Domain for PostgREST API | `api.example.com` |
| `auth_domain` | Domain for JWT Auth service | `auth.example.com` |
| `admin_email` | Email for SSL certificate notifications (required if SSL enabled) | `admin@example.com` |

### Optional Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `postgres_port` | integer | `5432` | PostgreSQL port |
| `postgrest_port` | integer | `3000` | PostgREST internal port |
| `pgweb_port` | integer | `8081` | pgweb internal port |
| `authelia_port` | integer | `9091` | Authelia internal port |
| `auth_port` | integer | `5000` | JWT Auth service internal port |
| `postgres_user` | string | `postgres` | PostgreSQL superuser username |
| `postgres_password` | password | auto-generated | PostgreSQL password |
| `postgres_db` | string | `postgres` | PostgreSQL database name |
| `postgrest_role` | string | `authenticator` | PostgREST database role |
| `postgrest_password` | password | auto-generated | PostgREST role password |
| `postgrest_anon_role` | string | `anon` | PostgREST anonymous role |
| `postgrest_jwt_secret` | password | auto-generated | JWT secret for PostgREST |
| `postgrest_schemas` | string | `public` | Database schemas to expose via API |
| `api_user_password` | password | auto-generated | Password for api_user role (read/write access) |
| `api_admin_password` | password | auto-generated | Password for admin role (full access) |
| `authelia_admin_password` | password | auto-generated | Authelia admin password |
| `enable_ssl` | boolean | `true` | Automatically obtain SSL certificate via Certbot |
| `install_dir` | string | `/opt/postgresql-stack` | Installation directory |
| `allowed_cors_origins` | string | `""` (empty) | Comma-separated allowed origins for CORS (PostgREST API). Empty = no cross-origin requests (most secure) |

## Usage

### Basic Installation with Automatic SSL

```bash
ansible-playbook -i inventory install.yml \
  -e domain=db.example.com \
  -e pgweb_domain=pgweb.example.com \
  -e postgrest_domain=api.example.com \
  -e auth_domain=auth.example.com \
  -e admin_email=admin@example.com
```

This will automatically:
1. Detect if Nginx is installed
2. Install Nginx if needed (from distribution repository)
3. Deploy PostgreSQL 18, PostgREST, JWT Auth, pgweb, and Authelia in Docker
4. Build and deploy the JWT authentication service
5. Initialize PostgREST roles and permissions (anon, api_user, admin)
6. Obtain SSL certificates via Certbot for all 3 domains
7. Configure HTTPS with security headers
8. Set up Authelia to protect pgweb with 2FA
9. Configure JWT authentication for PostgREST API
10. Set up automatic certificate renewal

### Custom Configuration

```bash
ansible-playbook -i inventory install.yml \
  -e domain=db.example.com \
  -e pgweb_domain=pgweb.example.com \
  -e postgrest_domain=api.example.com \
  -e auth_domain=auth.example.com \
  -e admin_email=admin@example.com \
  -e postgres_password=SecurePassword123 \
  -e postgrest_schemas=public,api \
  -e install_dir=/var/postgresql-stack
```

### Uninstallation

```bash
ansible-playbook -i inventory uninstall.yml
```

You will be prompted to confirm deletion of database data.

## Post-Installation

### Access Your Services

After installation, you'll have:

1. **PostgreSQL Database**: Direct connection on `domain:5432`
   ```bash
   psql -h db.example.com -U postgres -d postgres
   ```

2. **PostgREST API**: `https://api.example.com` (requires JWT authentication)
   ```bash
   # This will fail without authentication:
   curl https://api.example.com/sample_data

   # You need a JWT token first (see JWT Authentication section below)
   ```

3. **JWT Auth Service**: `https://auth.example.com`
   - Issues JWT tokens for API access
   - Credentials shown in installation output

4. **pgweb (Web UI)**: `https://pgweb.example.com`
   - Protected by Authelia 2FA
   - Username: `admin`
   - Password: (shown in installation output)

### Authelia 2FA Setup

1. Access pgweb at `https://pgweb.example.com`
2. You'll be redirected to Authelia login page
3. Log in with:
   - **Username**: `admin`
   - **Password**: (shown in installation output - save it!)
4. Set up 2FA:
   - Click "Register a Device"
   - Scan QR code with authenticator app (Google Authenticator, Authy, etc.)
   - Enter the 6-digit code to verify
5. You'll be redirected to pgweb after authentication

**IMPORTANT**: Save your Authelia credentials and 2FA backup codes securely!

### JWT Authentication for PostgREST API

The PostgREST API requires JWT authentication. Here's how to use it:

#### Step 1: Get a JWT Token

Authenticate with the Auth Service to obtain a JWT token:

```bash
# Using api_user (read/write access)
curl -X POST https://auth.example.com/login \
  -H "Content-Type: application/json" \
  -d '{"username":"api_user","password":"YOUR_API_USER_PASSWORD"}'

# Response:
{
  "token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "expires_in": 86400,
  "expires_at": "2025-11-20T12:00:00",
  "role": "api_user"
}
```

**Available Users:**
- **api_user**: Read/write access to all tables
  - Username: `api_user`
  - Password: (shown in installation output)
  - Role: `api_user`

- **admin**: Full database access
  - Username: `admin`
  - Password: (shown in installation output)
  - Role: `admin`

**Note**: Passwords are auto-generated during installation and displayed in the output. Save them securely!

#### Step 2: Use the Token with PostgREST

Include the token in the `Authorization` header:

```bash
# Save the token to a variable
TOKEN="eyJ0eXAiOiJKV1QiLCJhbGc..."

# Query the API
curl https://api.example.com/sample_data \
  -H "Authorization: Bearer $TOKEN"

# Insert data (requires api_user or admin role)
curl -X POST https://api.example.com/sample_data \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"New Item","description":"Created via API"}'

# Update data
curl -X PATCH https://api.example.com/sample_data?id=eq.1 \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"description":"Updated description"}'

# Delete data (requires api_user or admin role)
curl -X DELETE https://api.example.com/sample_data?id=eq.1 \
  -H "Authorization: Bearer $TOKEN"
```

#### JWT Token Management

**Token Expiry**: Tokens expire after 24 hours by default. Get a new token when needed.

**Verify a Token**:
```bash
curl https://auth.example.com/verify \
  -H "Authorization: Bearer $TOKEN"
```

**Token Contains**:
- `role`: PostgreSQL role to use (anon, api_user, or admin)
- `username`: User who obtained the token
- `exp`: Expiration timestamp
- `iat`: Issued at timestamp

#### Role-Based Permissions

The playbook creates three PostgreSQL roles:

1. **anon** (Anonymous):
   - No token required (but PostgREST will use this role)
   - Read-only access to `sample_data` table only
   - Use for public, unauthenticated endpoints

2. **api_user**:
   - Requires JWT token with `api_user` role
   - Read/write access to all tables
   - Can SELECT, INSERT, UPDATE, DELETE
   - Good for application backends

3. **admin**:
   - Requires JWT token with `admin` role
   - Full database access
   - All privileges on all tables
   - Use for admin operations

**How PostgREST Uses Roles**:
1. Without a token → uses `anon` role (minimal permissions)
2. With a valid token → switches to the role specified in the token
3. Database enforces permissions based on the role

### PostgREST API Examples

The playbook creates a sample `sample_data` table for testing. Here are some examples:

```bash
# First, get a JWT token
TOKEN=$(curl -s -X POST https://auth.example.com/login \
  -H "Content-Type: application/json" \
  -d '{"username":"api_user","password":"YOUR_PASSWORD"}' \
  | jq -r '.token')

# List all data
curl https://api.example.com/sample_data \
  -H "Authorization: Bearer $TOKEN"

# Filter data
curl "https://api.example.com/sample_data?name=eq.Sample%20Item%201" \
  -H "Authorization: Bearer $TOKEN"

# Get specific columns
curl "https://api.example.com/sample_data?select=id,name" \
  -H "Authorization: Bearer $TOKEN"

# Limit and offset
curl "https://api.example.com/sample_data?limit=10&offset=5" \
  -H "Authorization: Bearer $TOKEN"

# Order by
curl "https://api.example.com/sample_data?order=created_at.desc" \
  -H "Authorization: Bearer $TOKEN"

# Complex queries
curl "https://api.example.com/sample_data?name=like.*Item*&select=id,name&order=id" \
  -H "Authorization: Bearer $TOKEN"
```

**Public Access (No Authentication)**:
The `sample_data` table has read-only access for anonymous users:
```bash
# This works without a token (anonymous role has SELECT permission)
curl https://api.example.com/sample_data
```

For more advanced PostgREST features, see [PostgREST documentation](https://postgrest.org/).

### CORS Configuration (Cross-Origin Requests)

**Default Behavior**: By default, the PostgREST API **blocks all cross-origin requests** for maximum security. Only same-origin requests are allowed.

**Allowing Specific Origins**: If you need to call the API from a web frontend on a different domain, configure `allowed_cors_origins`:

```bash
ansible-playbook -i inventory install.yml \
  -e domain=db.example.com \
  -e pgweb_domain=pgweb.example.com \
  -e postgrest_domain=api.example.com \
  -e auth_domain=auth.example.com \
  -e admin_email=admin@example.com \
  -e "allowed_cors_origins=https://app.example.com,https://admin.example.com"
```

**Security Notes**:
- Only list trusted domains (your own frontend applications)
- Always use `https://` (not `http://`)
- Be specific - don't use wildcards
- The auth service automatically allows requests from the PostgREST domain

**Testing CORS**:
```bash
# This will fail if origin is not in allowed_cors_origins
curl https://api.example.com/sample_data \
  -H "Origin: https://app.example.com" \
  -H "Authorization: Bearer $TOKEN"
```

### Database Management

**Using pgweb (Web UI)**:
1. Access `https://pgweb.example.com`
2. Authenticate with Authelia (username + password + 2FA code)
3. Browse tables, run queries, export data

**Using psql (Command Line)**:
```bash
# Connect to database
psql -h db.example.com -U postgres -d postgres

# List databases
\l

# Connect to a database
\c database_name

# List tables
\dt

# Run a query
SELECT * FROM sample_data;
```

**Using pgAdmin or other tools**:
- Host: `db.example.com`
- Port: `5432`
- Username: `postgres`
- Password: (from installation output)
- Database: `postgres`

### Managing the Service

```bash
# View all service logs
cd /opt/postgresql-stack && docker compose logs -f

# View specific service logs
cd /opt/postgresql-stack && docker compose logs -f db
cd /opt/postgresql-stack && docker compose logs -f postgrest
cd /opt/postgresql-stack && docker compose logs -f pgweb
cd /opt/postgresql-stack && docker compose logs -f authelia

# Restart services
cd /opt/postgresql-stack && docker compose restart

# Stop/Start services
cd /opt/postgresql-stack && docker compose stop
cd /opt/postgresql-stack && docker compose start

# Update to latest versions
cd /opt/postgresql-stack && docker compose pull && docker compose up -d

# Check Nginx status
systemctl status nginx

# Reload Nginx configuration
systemctl reload nginx

# Check SSL certificate expiry
certbot certificates
```

### Creating Your Own Tables

```sql
-- Connect to your database
\c postgres

-- Create a new table
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username TEXT UNIQUE NOT NULL,
    email TEXT UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Grant permissions to PostgREST
GRANT SELECT, INSERT, UPDATE, DELETE ON users TO anon;
GRANT USAGE, SELECT ON SEQUENCE users_id_seq TO anon;

-- Insert sample data
INSERT INTO users (username, email)
VALUES ('john', 'john@example.com');

-- Access via PostgREST API
-- GET https://api.example.com/users
```

## Data Storage

All data is stored in `/opt/postgresql-stack/`:
- `data/postgres/` - PostgreSQL database files
- `data/authelia/` - Authelia configuration and SQLite database
- `compose.yml` - Docker Compose configuration
- `.env` - Environment variables (contains passwords - keep secure!)
- `authelia-config.yml` - Authelia configuration
- `authelia-users.yml` - Authelia user database

Nginx configuration:
- `/etc/nginx/sites-available/postgresql-stack-pgweb` (Debian/Ubuntu)
- `/etc/nginx/sites-available/postgresql-stack-postgrest` (Debian/Ubuntu)
- `/etc/nginx/conf.d/postgresql-stack-*.conf` (RHEL/CentOS/Rocky/Alma)

SSL certificates:
- `/etc/letsencrypt/live/{{ pgweb_domain }}/`
- `/etc/letsencrypt/live/{{ postgrest_domain }}/`

## Security Features

- **Automatic HTTPS** with Let's Encrypt certificates
- **2FA authentication** protecting pgweb access via Authelia
- **Security headers**: HSTS, X-Content-Type-Options, X-Frame-Options
- **Automatic certificate renewal** via cron (twice daily)
- **Role-based access control** for PostgREST
- **PostgreSQL password authentication**
- **CORS configuration** for PostgREST API

### Security Best Practices

1. **Firewall Configuration**: Restrict PostgreSQL port 5432 access
   ```bash
   # Allow only specific IPs to access PostgreSQL
   ufw allow from 192.168.1.0/24 to any port 5432
   ```

2. **PostgREST Authentication**: Implement JWT authentication for production
   - See [PostgREST Auth Tutorial](https://postgrest.org/en/stable/tutorials/tut1.html)

3. **Database Permissions**: Adjust PostgREST role permissions
   ```sql
   -- Grant only SELECT permission (read-only API)
   GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon;

   -- Or grant full access
   GRANT ALL ON ALL TABLES IN SCHEMA public TO anon;
   ```

4. **Authelia Users**: Add more users to `authelia-users.yml`

5. **Backup**: Implement regular database backups
   ```bash
   # Backup database
   docker exec postgresql-stack-db pg_dump -U postgres postgres > backup.sql

   # Restore database
   docker exec -i postgresql-stack-db psql -U postgres postgres < backup.sql
   ```

## Health Checks

The playbook configures health checks for all services:
- PostgreSQL: `pg_isready` command
- PostgREST: HTTP endpoint check
- pgweb: HTTP endpoint check
- Authelia: HTTP health endpoint check

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
```

**Solution 2: Install Nginx manually first**
```bash
# Debian/Ubuntu
sudo apt install nginx

# RHEL/CentOS/Rocky/Alma
sudo yum install nginx
```

### Check service status

```bash
cd /opt/postgresql-stack && docker compose ps
```

### View logs

```bash
# PostgreSQL logs
cd /opt/postgresql-stack && docker compose logs db

# PostgREST logs
cd /opt/postgresql-stack && docker compose logs postgrest

# pgweb logs
cd /opt/postgresql-stack && docker compose logs pgweb

# Authelia logs
cd /opt/postgresql-stack && docker compose logs authelia

# Nginx logs
sudo tail -f /var/log/nginx/pgweb-access.log
sudo tail -f /var/log/nginx/postgrest-access.log
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

### PostgREST returns empty results

Check database permissions:
```sql
-- Connect to database
\c postgres

-- Check table permissions
\dp

-- Grant permissions if needed
GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon;
```

### Authelia login not working

Check Authelia logs:
```bash
cd /opt/postgresql-stack && docker compose logs authelia
```

Reset Authelia password:
```bash
# Generate new password hash
docker run --rm authelia/authelia:4.38.16 authelia crypto hash generate argon2 --password YourNewPassword

# Update authelia-users.yml with new hash
# Restart Authelia
cd /opt/postgresql-stack && docker compose restart authelia
```

### Cannot connect to PostgreSQL remotely

Check firewall:
```bash
# Ubuntu/Debian
sudo ufw status
sudo ufw allow 5432/tcp

# RHEL/CentOS
sudo firewall-cmd --list-all
sudo firewall-cmd --add-port=5432/tcp --permanent
sudo firewall-cmd --reload
```

## Dangerous Operations

This playbook performs the following operations:
- Installs Docker and Docker Compose if not present
- Creates PostgreSQL 18 database with persistent storage
- **Installs Nginx** if not already present
- **Installs Certbot** and obtains SSL certificates from Let's Encrypt
- Opens ports 80, 443, and 5432 for access
- Stores database data in /opt/postgresql-stack/data directory
- Creates Nginx configurations in /etc/nginx/
- Sets up automatic certificate renewal via cron

## License

MIT

## Resources

- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [PostgREST Documentation](https://postgrest.org/)
- [pgweb GitHub](https://github.com/sosedoff/pgweb)
- [Authelia Documentation](https://www.authelia.com/)
- [Nginx Documentation](https://nginx.org/en/docs/)
- [Certbot Documentation](https://certbot.eff.org/)
- [Node Pulse Playbooks](https://github.com/node-pulse/playbooks)
