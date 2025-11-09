# Node Pulse Community Playbooks

A curated collection of Ansible playbooks for deploying common services to Linux servers.

## Browse Playbooks

Search and install playbooks at: **https://nodepulse.sh**

Or install directly from your Admiral dashboard: **Playbooks → Community**

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
- ✅ Unique playbook ID in format `pb_[A-Za-z0-9]{10}` (generate once, never change)
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
│
├── .github/workflows/
│   └── syntax-check.yml         # CI validation workflow
│
├── schemas/                     # JSON schemas
│   └── node-pulse-admiral-playbook-manifest-v1.schema.json
│
├── scripts/                     # Validation scripts
│   ├── find-changed-playbooks.sh
│   ├── validate-ansible-lint.sh
│   ├── validate-category.sh
│   ├── validate-entry-point.sh
│   ├── validate-json-schema.sh
│   ├── validate-json-syntax.sh
│   ├── validate-manifest-fields.sh
│   ├── validate-no-external-deps.sh
│   ├── validate-os-support.sh
│   └── validate-yaml-syntax.sh
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
