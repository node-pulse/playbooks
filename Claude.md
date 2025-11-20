# Claude Code Session Notes

## Nginx Deployment Pattern for Playbooks

**Last Updated**: 2025-11-19

### Standard Pattern: System Nginx Only

All playbooks using Nginx as a reverse proxy should follow this pattern for consistency and multi-app support.

#### Pattern Overview

```yaml
# 1. Early Nginx Detection (before Docker installation)
- name: Check if system Nginx is installed
  command: which nginx
  register: nginx_binary
  ignore_errors: yes
  changed_when: false

- name: Check if ports 80 and 443 are in use
  shell: |
    port80=$(ss -tuln | grep ':80 ' || echo "free")
    port443=$(ss -tuln | grep ':443 ' || echo "free")
    if [[ "$port80" != "free" ]] || [[ "$port443" != "free" ]]; then
      echo "in_use"
    else
      echo "free"
    fi
  register: ports_check
  changed_when: false

- name: Fail if ports are occupied and Nginx is not installed
  fail:
    msg: |
      ERROR: Ports 80 and/or 443 are already in use, but Nginx is not installed.

      This playbook uses system Nginx for multi-app support.
      Options:
      1. Free up ports 80/443 and re-run (playbook will install system Nginx)
      2. Install Nginx manually first
  when:
    - nginx_binary.rc != 0
    - ports_check.stdout == 'in_use'

- name: Display Nginx deployment decision
  debug:
    msg:
      - "Deploying with system Nginx + Certbot SSL (supports multiple applications on one server)"
      - "{{ 'Will use existing Nginx installation' if nginx_binary.rc == 0 else 'Will install Nginx from distribution repository' }}"
      - "SSL: Automatic via Certbot"
```

#### Key Principles

1. **System Nginx Only** - Never use Docker Nginx
   - Enables multiple applications on one server
   - All apps share a single Nginx instance
   - Better resource utilization

2. **Early Detection** - Check before installing anything
   - Validates Nginx presence
   - Checks port availability
   - Fails fast with clear error messages

3. **Conditional Installation** - Only install if needed
   ```yaml
   - name: Install Nginx (Debian/Ubuntu)
     apt:
       name: nginx
       state: present
     when:
       - system_nginx_check.rc != 0  # Only if not already installed
       - ansible_os_family == "Debian"
   ```

4. **Distribution Repositories** - Use system packages
   - Debian/Ubuntu: `apt install nginx`
   - RHEL/Rocky/Alma: `yum install nginx`
   - Never compile from source or use third-party repos

5. **Clear Communication**
   - Explain what's happening
   - Show whether using existing or installing new
   - Provide actionable solutions on failure

#### Configuration Structure

```
/etc/nginx/
├── sites-available/          # Debian/Ubuntu
│   ├── app1-service
│   ├── app2-api
│   └── app3-ui
├── sites-enabled/            # Debian/Ubuntu (symlinks)
│   ├── app1-service -> ../sites-available/app1-service
│   ├── app2-api -> ../sites-available/app2-api
│   └── app3-ui -> ../sites-available/app3-ui
└── conf.d/                   # RHEL/Rocky/Alma
    ├── app1-service.conf
    ├── app2-api.conf
    └── app3-ui.conf
```

#### Benefits

✅ **Multi-app Support**: Run multiple playbooks on one server
✅ **Resource Efficiency**: Single Nginx instance for all apps
✅ **Budget Friendly**: No need for multiple servers
✅ **Early Validation**: Fails fast if ports blocked
✅ **Clear Errors**: Users know exactly what to do
✅ **Consistent Pattern**: All playbooks work the same way

#### Reference Implementations

- ✅ `catalog/u/umami-v3-postgresql-nginx` - Reference implementation
- ✅ `catalog/p/pgsql-pgrest-pgweb-nginx` - Follows pattern correctly

---

**Note**: This document captures patterns and decisions from Claude Code sessions for future reference.
