# Node Pulse Community Playbooks

A curated collection of Ansible playbooks for deploying common services to Linux servers.

## Browse Playbooks

Install playbooks directly from your Admiral dashboard: **Playbooks → Community**

Or explore this repository by category:

- [**Security** (catalog/f/)](./catalog/f/) - fail2ban, SSH hardening, Wazuh
- [**Monitoring** (catalog/m/)](./catalog/m/) - node_exporter, process_exporter, blackbox_exporter
- [**Database** (catalog/d/)](./catalog/d/) - PostgreSQL, MySQL, MongoDB, Valkey
- [**Search** (catalog/s/)](./catalog/s/) - Meilisearch, Elasticsearch
- [**Proxy** (catalog/p/)](./catalog/p/) - Caddy, Nginx
- [**Storage** (catalog/s/)](./catalog/s/) - SeaweedFS, MinIO
- [**Dev Tools** (catalog/d/)](./catalog/d/) - Docker, Git, build tools

## Available Playbooks

### Security

| Playbook | Description | Status |
|----------|-------------|--------|
| [fail2ban](./catalog/f/fail2ban/) | Protect SSH and services from brute-force attacks | ✅ Ready |

## Quick Start

### Install a Playbook via Admiral

1. Open your Admiral dashboard
2. Go to **Playbooks → Community**
3. Search for a playbook (e.g., "fail2ban")
4. Click **Install**
5. Configure variables (if any)
6. Execute on your servers

### Manual Installation

```bash
# Clone this repository
git clone https://github.com/node-pulse/playbooks.git
cd playbooks

# Navigate to a playbook
cd catalog/f/fail2ban

# Run with ansible-playbook
ansible-playbook playbook.yml -i your-inventory.ini
```

## Contribute a Playbook

We welcome community contributions! See [CONTRIBUTING.md](./CONTRIBUTING.md) for detailed instructions.

### Quick Contribution Guide

1. Fork this repository
2. Create your playbook directory: `catalog/{first-letter}/{playbook-name}/`
3. Add required files:
   - `manifest.json` (required)
   - `playbook.yml` (required)
   - `templates/` (optional)
   - `files/` (optional)
   - `README.md` (recommended)
4. Test your playbook locally
5. Submit a pull request

### Playbook Requirements

- ✅ Complete `manifest.json` with all required fields
- ✅ Self-contained (no external dependencies, copy code locally)
- ✅ Idempotent (safe to run multiple times)
- ✅ Well-documented variables
- ✅ Passes `ansible-lint` (warnings acceptable)
- ✅ MIT licensed

## Repository Structure

```
playbooks/
├── README.md                    # This file
├── CONTRIBUTING.md              # Contribution guide
├── LICENSE                      # MIT License
├── .github/
│   └── workflows/
│       └── syntax-check.yml     # CI validation
│
├── schemas/                     # JSON schemas
│   └── node-pulse-admiral-playbook-manifest-v1.schema.json
│
└── catalog/                     # Playbook catalog
    ├── f/                       # Playbooks starting with 'f'
    │   └── fail2ban/
    │       ├── manifest.json
    │       ├── playbook.yml
    │       ├── templates/
    │       │   ├── jail.local.j2
    │       │   └── sshd.local.j2
    │       └── README.md
    │
    ├── m/                       # Playbooks starting with 'm'
    │   └── meilisearch/
    │       └── manifest.json
    │
    └── ... (a-z directories)
```

## Why 26 Directories?

- Easy navigation on GitHub
- Simple directory listing via GitHub API
- Avoids massive index files
- Scales to thousands of playbooks

## License

MIT - See [LICENSE](./LICENSE) for details

## Maintained By

[Node Pulse Community](https://github.com/node-pulse)

## Support

- **Issues**: [GitHub Issues](https://github.com/node-pulse/playbooks/issues)
- **Discussions**: [GitHub Discussions](https://github.com/node-pulse/playbooks/discussions)
- **Documentation**: [Node Pulse Docs](https://docs.nodepulse.io)
