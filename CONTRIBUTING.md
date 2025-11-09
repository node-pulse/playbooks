# Contributing to Node Pulse Playbooks

Thank you for contributing to the community playbook repository!

## Quick Start

1. **Fork this repository**
2. **Create a playbook directory**: `catalog/{first-letter}/{playbook-name}/`
3. **Add required files**:
   - `manifest.json` (required)
   - `playbook.yml` (or custom entry point)
   - `templates/` (optional)
   - `files/` (optional)
   - `README.md` (recommended)
4. **Test locally**
5. **Submit a pull request**

## Directory Structure

```
catalog/{letter}/{playbook-name}/
├── manifest.json        # Required metadata
├── playbook.yml         # Ansible playbook (entry point)
├── templates/           # Optional Jinja2 templates
│   └── config.j2
├── files/               # Optional static files
│   └── script.sh
└── README.md            # Optional documentation
```

## Manifest Schema (manifest.json)

Every playbook **must** include a valid `manifest.json` file:

### Generating a Unique Playbook ID

The `id` field must be globally unique and follow the format `pb_[A-Za-z0-9]{10}`.

**Generate a random ID:**

```bash
# Using Python (recommended)
python3 -c "import random, string; print('pb_' + ''.join(random.choices(string.ascii_letters + string.digits, k=10)))"

# Using OpenSSL + base64
echo "pb_$(openssl rand -base64 8 | tr -dc 'A-Za-z0-9' | head -c10)"

# Example output: pb_Xk7nM2pQw9
```

**Important:**
- Generate the ID **once** when creating the playbook
- **Never change it** after creation (it's the permanent identifier)
- The CI will reject duplicate IDs

### Example manifest.json

```json
{
  "$schema": "https://raw.githubusercontent.com/node-pulse/playbooks/main/schemas/node-pulse-admiral-playbook-manifest-v1.schema.json",

  "id": "pb_Xk7nM2pQw9",
  "name": "Fail2Ban Intrusion Prevention",
  "version": "1.0.0",
  "description": "Install and configure Fail2Ban to protect SSH from brute-force attacks",

  "author": {
    "name": "Your Name",
    "email": "you@example.com",
    "url": "https://github.com/yourname",
    "status": "community"
  },

  "category": "security",
  "tags": ["security", "ssh", "fail2ban"],
  "entry_point": "playbook.yml",

  "structure": {
    "playbook": "playbook.yml",
    "templates": ["templates/config.j2"],
    "files": ["files/script.sh"]
  },

  "ansible_version": ">=2.10",

  "os_support": [
    {
      "distro": "ubuntu",
      "version": "22.04",
      "arch": "both"
    },
    {
      "distro": "debian",
      "version": "12",
      "arch": "both"
    }
  ],

  "variables": [
    {
      "name": "port",
      "label": "HTTP Listen Port",
      "type": "integer",
      "default": 8080,
      "description": "Port to listen on",
      "required": false,
      "min": 1024,
      "max": 65535
    }
  ],

  "health_checks": [
    {
      "type": "command",
      "command": "systemctl is-active myservice",
      "timeout": 5
    }
  ],

  "dangerous_operations": [
    "Opens firewall port 8080",
    "Creates systemd service 'myservice'"
  ],

  "license": "MIT"
}
```

### Required Fields

| Field | Type | Description |
|-------|------|-------------|
| `id` | string | Unique identifier (must match directory name) |
| `name` | string | Display name |
| `version` | string | Semantic version (e.g., "1.0.0") |
| `description` | string | Short description (max 200 chars) |
| `author` | object | Author information (name, email, url, status) |
| `category` | string | One of: `monitoring`, `database`, `search`, `security`, `proxy`, `storage`, `dev-tools` |
| `tags` | array | Searchable tags (max 10) |
| `entry_point` | string | Main playbook file (e.g., "playbook.yml") |
| `ansible_version` | string | Minimum Ansible version (e.g., ">=2.10") |
| `os_support` | array | OS compatibility (distro, version, arch) |
| `license` | string | SPDX license identifier |

### Variable Types

Each variable must include both `name` (Ansible variable) and `label` (UI display):

| Type | Description | Validation |
|------|-------------|------------|
| `string` | Text input | Optional `pattern` regex |
| `integer` | Number input | Optional `min`/`max` |
| `boolean` | Checkbox | N/A |
| `select` | Dropdown | Requires `options` array |
| `password` | Password input (hidden) | N/A |

### OS Support

Specify exact OS compatibility:

```json
"os_support": [
  { "distro": "ubuntu", "version": "22.04", "arch": "both" },
  { "distro": "debian", "version": "12", "arch": "amd64" }
]
```

**Supported distros**: `ubuntu`, `debian`, `centos`, `rhel`, `rocky`, `alma`
**Supported arch**: `amd64`, `arm64`, `both`

## Validation Checklist

Before submitting a PR, ensure:

- [ ] `manifest.json` exists and is valid JSON
- [ ] All required fields are present
- [ ] `id` matches directory name
- [ ] Entry point file exists
- [ ] YAML passes syntax check: `ansible-playbook --syntax-check playbook.yml`
- [ ] Playbook passes ansible-lint (warnings acceptable)
- [ ] Category is valid
- [ ] Version follows semantic versioning (MAJOR.MINOR.PATCH)
- [ ] **No `requirements.yml` file** (we don't fetch external dependencies)
- [ ] **No external role/collection references** (copy code locally instead)
- [ ] All templates, files, roles are in the playbook directory
- [ ] If using Galaxy code, it's copied locally and credited in README

### Run Validation Locally

```bash
# Validate JSON
jq empty catalog/f/fail2ban/manifest.json

# Check YAML syntax
ansible-playbook --syntax-check catalog/f/fail2ban/playbook.yml

# Run linter (warnings are OK)
ansible-lint catalog/f/fail2ban/playbook.yml

# Check for external dependencies (must return nothing)
find catalog/f/fail2ban -name "requirements.yml"
```

## Playbook Best Practices

1. **Self-Contained** - **CRITICAL**: No external dependency fetching
   - All code must be in your playbook directory
   - You can use Galaxy role/collection code, but copy it locally
   - No `requirements.yml` files (Admiral doesn't run `ansible-galaxy install`)
   - If you copy Galaxy code, credit the original author in README

2. **Idempotency** - Safe to run multiple times
   ```yaml
   # Good: Uses state parameter
   - name: Ensure nginx is installed
     apt:
       name: nginx
       state: present
   ```

3. **Error Handling** - Use `failed_when` and `changed_when`
   ```yaml
   - name: Check service status
     command: systemctl is-active myservice
     register: result
     failed_when: false
     changed_when: false
   ```

4. **Variables** - Use sensible defaults
   ```yaml
   vars:
     port: 8080
     bind_address: "0.0.0.0"
   ```

5. **Templates** - Use Jinja2 for configuration files
   ```jinja
   # templates/config.j2
   listen_port = {{ port }}
   bind_address = {{ bind_address }}
   ```

6. **Security** - Never hardcode secrets
   ```yaml
   # Good: Use variable marked as type: "password"
   variables:
     - name: db_password
       label: "Database Password"
       type: password
   ```

7. **Health Checks** - Include verification tasks
   ```yaml
   - name: Verify service is running
     systemd:
       name: myservice
       state: started
     check_mode: yes
   ```

8. **Documentation** - Add clear README with examples

## Submission Process

1. **Fork** this repository
2. **Create** your playbook directory
3. **Add** `manifest.json` and playbook files
4. **Test** locally with Ansible
5. **Commit** with clear message: `feat: add fail2ban playbook`
6. **Submit** a pull request
7. **CI** will validate your submission
8. **Maintainers** will review and merge

## CI Validation

Our CI automatically checks:

- ✅ `manifest.json` exists and is valid JSON
- ✅ All required fields are present
- ✅ `id` matches directory name
- ✅ Entry point file exists
- ✅ YAML syntax is valid
- ✅ Category is valid
- ✅ No `requirements.yml` file exists
- ✅ ansible-lint passes (warnings OK)

## Example Playbooks

See existing playbooks for examples:

- [fail2ban](./catalog/f/fail2ban/) - Security playbook with templates
- More coming soon!

## Questions?

- Open an [issue](https://github.com/node-pulse/playbooks/issues)
- Start a [discussion](https://github.com/node-pulse/playbooks/discussions)

---

**License**: All contributions must be MIT licensed.

**Code of Conduct**: Be respectful and collaborative.
