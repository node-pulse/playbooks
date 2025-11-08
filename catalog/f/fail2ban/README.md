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

- Ubuntu 20.04, 22.04, 24.04 or Debian 11, 12
- `sudo` or root access
- SSH access to target server

## Variables

| Variable | Description | Default | Type |
|----------|-------------|---------|------|
| `bantime` | Duration in seconds that an IP is banned | `3600` (1 hour) | Integer |
| `findtime` | Time window in seconds to count failed attempts | `600` (10 minutes) | Integer |
| `maxretry` | Maximum failed attempts before banning | `5` | Integer |
| `ssh_port` | SSH port to monitor | `22` | Integer |
| `destemail` | Email address for ban notifications | `root@localhost` | String |
| `action` | Ban action type | `action_` | Select |

### Action Types

- `action_` - Ban only (no email)
- `action_mw` - Ban + send email notification
- `action_mwl` - Ban + send email with log excerpts

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

### Custom SSH Port with Email Notifications

```yaml
ssh_port: 2222
destemail: "admin@example.com"
action: "action_mw"
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
