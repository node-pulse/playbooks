# Fail2Ban Intrusion Prevention

Deploy Fail2Ban to protect your server from brute-force attacks on SSH and other services.

## What is Fail2Ban?

Fail2Ban scans log files (e.g., `/var/log/auth.log`) and bans IPs that show malicious behavior such as too many password failures, seeking for exploits, etc. It updates firewall rules to reject the IP addresses for a specified amount of time.

## What This Playbook Does

- ✅ Installs fail2ban package
- ✅ Configures default ban settings (ban time, find time, max retry)
- ✅ Sets up SSH protection jail
- ✅ Enables and starts fail2ban service
- ✅ Provides status check

## Requirements

- **Supported OS**: Ubuntu 20.04/22.04/24.04, Debian 11/12, RHEL 8/9, Rocky Linux 8/9, AlmaLinux 8/9, Oracle Linux 8/9, Amazon Linux 2/2023
- `sudo` or root access
- SSH access to target server

## Variables

| Variable | Description | Default | Type |
|----------|-------------|---------|------|
| `bantime` | Duration in seconds that an IP is banned | `3600` (1 hour) | Integer |
| `findtime` | Time window in seconds to count failed attempts | `600` (10 minutes) | Integer |
| `maxretry` | Maximum failed attempts before banning | `5` | Integer |
| `ssh_port` | SSH port to monitor | `22` | Integer |
| `webhook_url` | HTTP endpoint to receive ban/unban notifications | `""` (disabled) | String |
| `webhook_token` | Bearer token for webhook authentication | `""` (none) | String |
| `webhook_timeout` | Webhook request timeout in seconds | `10` | Integer |

## Example Usage

### Default Configuration (1 hour ban after 5 failed attempts)

```yaml
# No variables needed, uses defaults
```

### Strict Configuration (24 hour ban after 3 failed attempts)

```yaml
bantime: 86400      # 24 hours
findtime: 300       # 5 minutes
maxretry: 3         # 3 attempts
```

### Custom SSH Port

```yaml
ssh_port: 2222
bantime: 3600
maxretry: 5
```

### With Webhook Notifications

```yaml
bantime: 3600
maxretry: 5
webhook_url: "https://api.example.com/fail2ban/notify"
webhook_token: "your-secret-token-here"
webhook_timeout: 10
```

## Webhook Notifications

When you provide a `webhook_url`, fail2ban will POST JSON payloads to your endpoint on these events.

### Security Features

- **Authentication**: Set `webhook_token` to add `Authorization: Bearer <token>` header to all requests
- **Timeout Protection**: Requests timeout after `webhook_timeout` seconds (default: 10s)
- **Non-blocking**: Webhook failures won't prevent fail2ban from banning IPs (fail-safe design)

### Ban Event
```json
{
  "event": "ban",
  "ip": "192.168.1.100",
  "jail": "sshd",
  "time": "2025-11-08 10:30:45",
  "failures": "5",
  "server": "web-01"
}
```

### Unban Event
```json
{
  "event": "unban",
  "ip": "192.168.1.100",
  "jail": "sshd",
  "time": "2025-11-08 11:30:45",
  "server": "web-01"
}
```

### Webhook Integration Examples

**Custom API (recommended):**
Set up your own API to receive and route notifications to Discord, Telegram, Slack, etc.
```yaml
webhook_url: "https://api.example.com/webhooks/fail2ban"
```

**Discord:**
```yaml
webhook_url: "https://discord.com/api/webhooks/YOUR_WEBHOOK_ID/YOUR_TOKEN"
```

**Slack:**
```yaml
webhook_url: "https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
```

**n8n/Make/Zapier:**
Use workflow automation platforms to route to Telegram, email, SMS, etc.
```yaml
webhook_url: "https://your-n8n.example.com/webhook/fail2ban"
```

## Post-Installation

### Check Fail2Ban Status

```bash
sudo fail2ban-client status
```

### Check SSH Jail Status

```bash
sudo fail2ban-client status sshd
```

### Unban an IP Address

```bash
sudo fail2ban-client set sshd unbanip 192.168.1.100
```

### View Banned IPs

```bash
sudo fail2ban-client status sshd
```

## Files Modified

- `/etc/fail2ban/jail.local` - Main configuration
- `/etc/fail2ban/jail.d/sshd.local` - SSH jail configuration
- `/var/log/fail2ban.log` - Fail2Ban log file

## Security Considerations

- **Testing**: Test with a non-production IP first to avoid locking yourself out
- **Whitelist**: Consider whitelisting your admin IPs in `/etc/fail2ban/jail.local` using `ignoreip`
- **SSH Key Auth**: Use SSH key authentication instead of passwords for better security
- **Custom Ports**: If using a custom SSH port, make sure to update the `ssh_port` variable

## Troubleshooting

### Locked Out?

If you get locked out, you can:

1. Access server via console (not SSH)
2. Stop fail2ban: `sudo systemctl stop fail2ban`
3. Clear iptables rules: `sudo iptables -F`
4. Restart fail2ban: `sudo systemctl start fail2ban`

### Check Logs

```bash
# Fail2Ban logs
sudo tail -f /var/log/fail2ban.log

# Authentication logs (what Fail2Ban monitors)
sudo tail -f /var/log/auth.log
```

## License

MIT

## Maintained By

Node Pulse Community
