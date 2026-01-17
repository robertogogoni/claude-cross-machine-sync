# Beeper Bridge Manager Setup Summary

## Installation Status

✅ **bbctl v0.13.0 installed** at `~/.local/bin/bbctl`
✅ **PATH configured** in `~/.bashrc` (restart terminal or run `source ~/.bashrc`)
✅ **Dependencies verified**: Python 3.13.7, venv module, ffmpeg

## Next Steps

### 1. Authenticate with Beeper (You need to do this)

Run this command in your terminal:
```bash
bbctl login
```

Enter your Beeper email (associated with @robthepirate:beeper.com) and password.

### 2. Set Up WhatsApp Bridge with v2 Config

After authentication, run:
```bash
bbctl run sh-whatsapp
```

This will:
- Automatically download and configure the WhatsApp bridge with v2 configuration
- Install to `~/.local/share/bbctl/sh-whatsapp/`
- Start the bridge in foreground mode
- You'll receive a DM from the WhatsApp bridge bot to complete setup

### 3. Configure the Bridge

Once running:
- Open Beeper and find the DM from the WhatsApp bridge bot
- Follow the bot's instructions to link your WhatsApp account
- This is typically done by scanning a QR code

### 4. Set Up Persistent Operation (systemd)

I've created a systemd service file at `/home/rob/bbctl-whatsapp.service`

To install it:
```bash
# Copy service file to systemd user directory
mkdir -p ~/.config/systemd/user
cp ~/bbctl-whatsapp.service ~/.config/systemd/user/

# Enable and start the service
systemctl --user enable bbctl-whatsapp.service
systemctl --user start bbctl-whatsapp.service

# Check status
systemctl --user status bbctl-whatsapp.service

# View logs
journalctl --user -u bbctl-whatsapp.service -f
```

**IMPORTANT:** Only set up the systemd service AFTER you've successfully configured the bridge manually first!

## GUI Options

### Option 1: Beeper Web Self-Host (Recommended for GUI)

Beeper provides a web-based GUI at **https://self-host.beeper.com** that:
- Deploys bridges to your Fly.io account (requires Fly.io account)
- Provides a visual interface for managing bridges
- Automatically integrates with your Beeper account
- No command-line needed after initial setup

**Pros:**
- Full GUI experience
- Managed hosting on Fly.io
- Easy deployment and configuration

**Cons:**
- Requires Fly.io account (has free tier)
- Bridges run on Fly.io infrastructure, not your local machine
- Limited to Fly.io deployment

### Option 2: bbctl CLI (What we're setting up now)

**Pros:**
- Runs on your own hardware
- Full control over bridge configuration
- Free (no hosting costs)
- Direct integration with Beeper

**Cons:**
- Command-line only (no GUI)
- Manual configuration required
- You manage the infrastructure

### Option 3: Hybrid Approach

You could:
1. Use the web GUI at self-host.beeper.com for some bridges (easy setup)
2. Use bbctl locally for bridges you want more control over
3. Both can coexist with the same Beeper account

## Regarding Your Beeper Instance Bridges

**Important Clarification:**

The bridges that Beeper provides with your account (the managed ones) are automatically updated by Beeper. When they upgraded to WhatsApp bridge v2, your managed bridge was updated automatically.

**Self-hosted bridges via bbctl:**
- Are separate instances running on your own infrastructure
- Give you control and customization options
- Can run alongside Beeper's managed bridges
- Useful for testing, custom configurations, or bridges not offered by Beeper

**You cannot "upgrade" Beeper's managed bridges** - they handle that server-side.

## Monitoring the Bridge

After setting up the systemd service:

```bash
# View real-time logs
journalctl --user -u bbctl-whatsapp.service -f

# Check if running
systemctl --user status bbctl-whatsapp.service

# Restart if needed
systemctl --user restart bbctl-whatsapp.service

# Stop the service
systemctl --user stop bbctl-whatsapp.service
```

## Configuration Files

- **Bridge data**: `~/.local/share/bbctl/sh-whatsapp/`
- **bbctl config**: `~/.config/bbctl.json`
- **Systemd service**: `~/.config/systemd/user/bbctl-whatsapp.service`

## Support Resources

- Beeper self-hosting community: `#self-hosting:beeper.com` (Matrix room)
- Bridge Manager repo: https://github.com/beeper/bridge-manager
- Documentation: Included in the bbctl tool itself

## What You Get with v2 Configuration

Your WhatsApp bridge will use the new bridgev2 architecture which provides:
- Better reliability and maintainability
- More consistent behavior across bridges
- Improved error handling
- Foundation for future features
- Full group management support (invite/kick/leave/create)

## Security Considerations

- Self-hosted bridges may not have end-to-bridge encryption
- Messages may be visible to Beeper servers
- Keep your bridge updated for security patches
- The systemd service includes security hardening options

## Troubleshooting

If the bridge doesn't start:
1. Check logs: `journalctl --user -u bbctl-whatsapp.service`
2. Verify authentication: Try running `bbctl run sh-whatsapp` manually
3. Check permissions on `~/.local/share/bbctl` directory
4. Join the support room for help

## Quick Command Reference

```bash
# Login to Beeper
bbctl login

# Run WhatsApp bridge (foreground)
bbctl run sh-whatsapp

# List available bridge types
bbctl run --help

# Generate config without running
bbctl config sh-whatsapp

# Delete a bridge
bbctl delete sh-whatsapp

# Check version
bbctl --version
```
