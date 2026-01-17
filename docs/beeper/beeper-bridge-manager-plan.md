# Beeper Bridge Manager Installation & Setup Plan

## Current System Status

**Already Installed:**
- ✅ Python 3.13.7 (required for Python bridges)
- ✅ Python venv module (required for virtual environments)
- ✅ ffmpeg n8.0.1 (required for media conversion)

**Not Installed:**
- ❌ bbctl (Beeper Bridge Manager CLI)
- ❌ Go 1.23+ (only needed if building from source)

## Installation Plan

### Phase 1: Install Beeper Bridge Manager

Since Go is not installed, we'll download the pre-built binary instead of building from source.

**Steps:**
1. Download the latest bbctl binary from GitHub releases (v0.13.0)
   - Platform: Linux (amd64 or arm64 - need to detect)
   - Source: https://github.com/beeper/bridge-manager/releases
2. Make the binary executable
3. Move to appropriate location in PATH (e.g., ~/.local/bin)
4. Verify installation with `bbctl --version`

### Phase 2: Authenticate with Beeper

**Steps:**
1. Run `bbctl login` to authenticate with Beeper account
2. Follow authentication prompts (user will need to provide credentials)

### Phase 3: Set Up WhatsApp Bridge

**Steps:**
1. Create a bridge instance: `bbctl run sh-whatsapp`
   - This will automatically detect "whatsapp" from the name
   - Bridge will be installed in `~/.local/share/bbctl` by default
2. Configure the bridge via DM with the bridge bot
3. Link WhatsApp account following bridge instructions

**Note:** This will use the new v2 configuration automatically in v0.13.0

### Phase 4: Verify Setup

**Steps:**
1. Check bridge status
2. Test message sending/receiving
3. Review installed bridge files in `~/.local/share/bbctl`

## Important Considerations

### Running in Background
- bbctl runs bridges in foreground by default
- For persistent operation, we'll need to use:
  - tmux/screen session, OR
  - systemd service, OR
  - nohup/background process

### Self-Hosted Bridge Limitations
- Limited customer support (community support via #self-hosting:beeper.com)
- Some bridges may lack end-to-bridge encryption
- Messages may be visible to Beeper servers

## WhatsApp Bridge Config v2 Updates Analysis

### What Changed in v2

The WhatsApp bridge underwent a major architectural rewrite:

**Architecture:**
- Migrated to bridgev2 framework (implemented in v0.11.0, Oct 2024)
- More modular and maintainable codebase
- Common foundation shared across mautrix bridges

**Configuration:**
- New configuration format (config v2)
- Manual config review recommended after upgrade
- Some settings may need manual migration

**Features:**
- Initially removed group management features (v0.11.0)
- Group invite/kick/leave restored in v0.12.0
- Group creation added in v0.12.5
- Current version should have full feature parity

**Benefits:**
- Better maintainability and extensibility
- Improved reliability
- Foundation for future enhancements
- Consistent architecture across bridges

### Migration Impact
- Existing users need to review configuration after upgrade
- Auto-migration possible if bridge can write to config
- Manual update needed if config writing is disabled

## Python Bridges PyPI Installation Changes

### What Changed

**Before v0.13.0:**
- Python bridges installed directly from GitHub repositories
- `pip install git+https://github.com/...`

**After v0.13.0:**
- Python bridges install from PyPI (Python Package Index)
- `pip install mautrix-whatsapp` (standard PyPI package)

### Benefits of PyPI Installation

1. **Better Dependency Management:**
   - PyPI packages have well-defined dependencies
   - Automatic dependency resolution
   - Version constraints handled properly

2. **Improved Reliability:**
   - PyPI serves official releases, not development code
   - More stable than tracking GitHub HEAD
   - Reduced chance of breaking changes

3. **Faster Installation:**
   - PyPI packages are pre-built
   - No need to clone entire Git repository
   - CDN-based distribution for faster downloads

4. **Better Versioning:**
   - Semantic versioning on PyPI
   - Easy to pin specific versions
   - Clearer upgrade paths

5. **Standard Python Workflow:**
   - Follows Python best practices
   - Works better with requirements.txt
   - Compatible with all pip features

### Affected Bridges

Python-based bridges that now install from PyPI:
- mautrix-whatsapp (Python implementation, if any)
- mautrix-signal
- mautrix-telegram
- Other Python-based mautrix bridges

**Note:** The main WhatsApp bridge (mautrix-whatsapp) is Go-based, so this change affects other Python bridges in the ecosystem.

## Questions to Clarify

1. **Beeper Account:** Do you have a Beeper account already, or need to create one?
2. **Background Running:** How would you like to run the bridge? (tmux, systemd, or other?)
3. **Bridge Selection:** Do you want to start with WhatsApp only, or set up multiple bridges?
4. **Architecture:** Need to detect if system is amd64 or arm64 for correct binary download

## Resources

- [Bridge Manager Repository](https://github.com/beeper/bridge-manager)
- [v0.13.0 Release Notes](https://github.com/beeper/bridge-manager/releases)
- [WhatsApp Bridge Changelog](https://github.com/mautrix/whatsapp/blob/main/CHANGELOG.md)
- [Bridge Manager Changelog](https://github.com/beeper/bridge-manager/blob/main/CHANGELOG.md)
