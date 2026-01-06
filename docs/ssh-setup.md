# SSH Remote Access Setup

This guide helps you set up SSH access between your 3 machines for remote Claude Code execution.

## Overview

**Goal**: Execute commands on Linux notebooks from Windows (and vice-versa)

**Machines**:
- MacBook Air (Main) - Apple MacBookAir7,2 running Arch Linux (hostname: omarchy)
- Linux Notebook 2
- Windows Desktop

---

## Part 1: SSH Key Setup

### On Each Linux Machine

```bash
# 1. Generate SSH key (if you don't have one)
ssh-keygen -t ed25519 -C "your-email@example.com"
# Press Enter to accept defaults
# Optionally set a passphrase

# 2. Start SSH agent
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# 3. Display public key (copy this)
cat ~/.ssh/id_ed25519.pub
```

### On Windows

**Option A: Using Windows OpenSSH** (recommended)
```powershell
# 1. Generate SSH key
ssh-keygen -t ed25519 -C "your-email@example.com"

# 2. Start SSH agent (PowerShell as Admin)
Get-Service ssh-agent | Set-Service -StartupType Automatic
Start-Service ssh-agent
ssh-add $env:USERPROFILE\.ssh\id_ed25519

# 3. Display public key
type $env:USERPROFILE\.ssh\id_ed25519.pub
```

**Option B: Using WSL2** (if you have it)
```bash
# Same commands as Linux
ssh-keygen -t ed25519 -C "your-email@example.com"
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
cat ~/.ssh/id_ed25519.pub
```

---

## Part 2: Exchange Keys

### On Each Machine

Add other machines' public keys to `~/.ssh/authorized_keys`:

```bash
# Create authorized_keys if it doesn't exist
mkdir -p ~/.ssh
touch ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

# Add public key from another machine
echo "ssh-ed25519 AAAA... user@other-machine" >> ~/.ssh/authorized_keys
```

**Example workflow**:
1. Copy Linux Notebook 1's public key
2. SSH into Linux Notebook 2 and add it to `~/.ssh/authorized_keys`
3. Repeat for Windows machine
4. Do the reverse: copy each machine's key to the others

---

## Part 3: Configure SSH

### On Each Linux Machine

Edit `~/.ssh/config`:

```bash
# MacBook Air (Main)
Host linux-notebook-2
    HostName 192.168.1.X  # Replace with actual IP
    User rob
    Port 22
    IdentityFile ~/.ssh/id_ed25519

Host windows-desktop
    HostName 192.168.1.Y  # Replace with actual IP
    User YourWindowsUsername
    Port 22
    IdentityFile ~/.ssh/id_ed25519
```

### On Windows

Edit `%USERPROFILE%\.ssh\config` (create if doesn't exist):

```
# Windows config
Host macbook-air
    HostName 192.168.1.X
    User rob
    Port 22
    IdentityFile C:\Users\YourUser\.ssh\id_ed25519

Host linux-notebook-2
    HostName 192.168.1.Y
    User rob
    Port 22
    IdentityFile C:\Users\YourUser\.ssh\id_ed25519
```

---

## Part 4: Enable SSH Server

### On Linux (Arch)

```bash
# Install OpenSSH server
sudo pacman -S openssh

# Enable and start SSH service
sudo systemctl enable sshd
sudo systemctl start sshd

# Check status
sudo systemctl status sshd

# Allow SSH through firewall (if using)
sudo ufw allow 22/tcp  # or use firewalld
```

### On Windows

```powershell
# Install OpenSSH Server (PowerShell as Admin)
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0

# Start and enable service
Start-Service sshd
Set-Service -Name sshd -StartupType 'Automatic'

# Confirm firewall rule
Get-NetFirewallRule -Name *ssh*

# If no rule, create one
New-NetFirewallRule -Name sshd -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
```

---

## Part 5: Test Connections

### From Any Machine

```bash
# Test connection
ssh macbook-air

# If successful, you should see:
# Welcome to Arch Linux!

# Test with Claude Code
ssh macbook-air "claude --version"

# Should output: Claude Code version X.X.X
```

---

## Part 6: Remote Claude Code Workflows

### Workflow 1: Direct SSH + Claude

```bash
# From Windows
ssh macbook-air
cd ~/project
claude

# You're now running Claude Code on the MacBook Air
# Commands execute on the MacBook, results appear in your Windows terminal
```

### Workflow 2: VS Code Remote SSH

**Setup**:
1. Install "Remote - SSH" extension in VS Code
2. Press F1, type "Remote-SSH: Connect to Host"
3. Select your configured host (e.g., `macbook-air`)
4. VS Code opens a new window connected to remote machine

**Use Claude Code**:
```bash
# In VS Code's integrated terminal (now on remote machine)
claude

# Or use Claude Code extension if installed remotely
```

### Workflow 3: One-Off Commands

```bash
# Execute a single command remotely
ssh macbook-air "cd ~/project && ls -la"

# Run Claude in non-interactive mode
ssh macbook-air "cd ~/project && claude -p 'List all Python files'"

# Background task
ssh macbook-air "cd ~/project && nohup npm run dev > output.log 2>&1 &"
```

### Workflow 4: Git-Based Collaboration

```bash
# On Windows: Make changes, push
cd ~/project
# ... make changes ...
git add .
git commit -m "Changes from Windows"
git push

# On Linux: Pull and review
ssh linux-notebook-1
cd ~/project
git pull
# ... review changes ...
```

---

## Part 7: Dynamic IP Solutions

If your machines don't have static IPs:

### Option A: Use Hostnames (Local Network)

```bash
# Edit /etc/hosts on each machine
sudo nano /etc/hosts

# Add entries:
192.168.1.100  macbook-air
192.168.1.101  linux-notebook-2
192.168.1.102  windows-desktop
```

### Option B: Use Tailscale (Recommended)

**Tailscale** creates a secure mesh network with stable IPs:

```bash
# Install on Linux
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up

# Install on Windows
# Download from https://tailscale.com/download

# Each machine gets a stable 100.x.y.z IP
# Use these in SSH config
```

### Option C: Use ZeroTier

Similar to Tailscale, creates a virtual network:

```bash
# Install and join network
curl -s https://install.zerotier.com | sudo bash
sudo zerotier-cli join <NETWORK_ID>
```

---

## Part 8: Advanced: SSH Tunneling for MCP

If you want to access MCP servers remotely:

### Forward Beeper MCP from MacBook Air to Windows

```bash
# On Windows, create tunnel
ssh -L 23373:localhost:23373 macbook-air

# Now Beeper MCP is accessible on Windows at localhost:23373
# Configure in ~/.claude.json:
{
  "mcpServers": {
    "beeper": {
      "type": "http",
      "url": "http://localhost:23373/v0/mcp"
    }
  }
}
```

### Reverse Tunnel (Access Windows from Linux)

```bash
# On Linux, connect to Windows with reverse tunnel
ssh -R 9999:localhost:8080 windows-desktop

# Now Windows can access Linux's port 8080 via localhost:9999
```

---

## Security Best Practices

1. **Use SSH keys**, not passwords
2. **Set strong passphrase** on private keys
3. **Disable password authentication**:
   ```bash
   # Edit /etc/ssh/sshd_config
   sudo nano /etc/ssh/sshd_config

   # Set:
   PasswordAuthentication no
   PubkeyAuthentication yes

   # Restart SSH
   sudo systemctl restart sshd
   ```
4. **Use SSH agent** to avoid re-entering passphrase
5. **Limit SSH to specific IPs** (firewall rules)
6. **Use VPN/Tailscale** for remote access outside home network

---

## Troubleshooting

### Connection Refused
- Check SSH service is running: `sudo systemctl status sshd`
- Verify firewall allows port 22
- Check IP address is correct: `ip addr` (Linux) or `ipconfig` (Windows)

### Permission Denied
- Verify public key is in `~/.ssh/authorized_keys`
- Check file permissions:
  ```bash
  chmod 700 ~/.ssh
  chmod 600 ~/.ssh/authorized_keys
  chmod 600 ~/.ssh/id_ed25519
  ```
- Check SSH logs: `sudo journalctl -u sshd` (Linux)

### Host Key Verification Failed
- Remove old key: `ssh-keygen -R hostname`
- Accept new key on first connection

### SSH Hangs on Connection
- Try with verbose flag: `ssh -vvv hostname`
- Check network connectivity: `ping hostname`
- Verify DNS resolution: `nslookup hostname`

---

## Quick Reference

### Connect to Machines
```bash
# From any machine
ssh macbook-air
ssh linux-notebook-2
ssh windows-desktop
```

### Run Claude Remotely
```bash
# Interactive
ssh macbook-air -t "cd ~/project && claude"

# Non-interactive
ssh macbook-air "cd ~/project && claude -p 'your prompt'"
```

### Copy Files
```bash
# From remote to local
scp macbook-air:~/project/file.txt ./

# From local to remote
scp ./file.txt macbook-air:~/project/

# Entire directory
scp -r macbook-air:~/project/ ./local-copy/
```

### Sync Files with rsync
```bash
# Sync project directory
rsync -avz --delete macbook-air:~/project/ ./project/

# Sync Claude settings
rsync -avz ~/.claude/ linux-notebook-2:~/.claude/
```

---

## Next Steps

- [ ] Generate SSH keys on all machines
- [ ] Exchange public keys
- [ ] Configure SSH config files
- [ ] Test connections
- [ ] Install Tailscale for stable IPs (optional but recommended)
- [ ] Set up VS Code Remote SSH
- [ ] Test remote Claude Code execution

---

*For more help, see: https://www.ssh.com/academy/ssh*
