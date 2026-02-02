# Contributing to Claude Cross-Machine Sync

Welcome, and thank you for your interest in contributing to Claude Cross-Machine Sync! This project helps developers synchronize their Claude Code configurations, AI conversation history, and learned patterns across multiple machines. Every contribution helps make cross-machine AI workflows smoother for everyone.

Whether you're fixing a bug, improving documentation, or adding a new feature, we appreciate your help. This guide will walk you through the contribution process.

---

## Table of Contents

- [Ways to Contribute](#ways-to-contribute)
- [Development Setup](#development-setup)
- [Code Style Guidelines](#code-style-guidelines)
- [Testing Requirements](#testing-requirements)
- [Pull Request Process](#pull-request-process)
- [Commit Message Conventions](#commit-message-conventions)
- [Code of Conduct](#code-of-conduct)
- [Getting Help](#getting-help)

---

## Ways to Contribute

### Report Bugs

Found something broken? Open an issue with:

- A clear, descriptive title
- Steps to reproduce the problem
- Expected behavior vs. actual behavior
- Your machine details (OS, shell, Claude Code version)
- Relevant log output or error messages

### Suggest Features

Have an idea to improve cross-machine sync? We'd love to hear it! Open an issue with:

- A clear description of the problem you're solving
- Your proposed solution
- Any alternative approaches you considered
- Which platforms this would affect (Linux, Windows, or both)

### Improve Documentation

Good documentation helps everyone. You can:

- Fix typos or clarify confusing sections
- Add examples for complex workflows
- Improve setup guides for specific platforms
- Document undocumented features

### Contribute Code

Ready to dive in? Check out issues labeled `good first issue` or `help wanted`. Before starting major work, open an issue to discuss your approach.

---

## Development Setup

### Prerequisites

| Tool | Linux | Windows |
|------|-------|---------|
| Git | `sudo pacman -S git` (Arch) or `sudo apt install git` (Ubuntu) | `winget install Git.Git` |
| Git LFS | `sudo pacman -S git-lfs` or `sudo apt install git-lfs` | `winget install GitHub.GitLFS` |
| ShellCheck | `sudo pacman -S shellcheck` or `sudo apt install shellcheck` | `scoop install shellcheck` |
| yq (YAML parser) | `sudo pacman -S yq` or via pip | `scoop install yq` |

### Clone and Setup

```bash
# Clone the repository
git clone https://github.com/robertogogoni/claude-cross-machine-sync.git
cd claude-cross-machine-sync

# Initialize Git LFS (for large files like episodic memory archives)
git lfs install
git lfs pull

# Verify setup
./tests/run_all.sh
```

### Repository Structure

```
claude-cross-machine-sync/
├── bootstrap.sh           # Linux bootstrap script
├── bootstrap.ps1          # Windows bootstrap script
├── lib/                   # Shared library modules
│   ├── validator.sh       # Pre-flight validation
│   └── rollback.sh        # Rollback functionality
├── platform/              # Platform-specific code
│   ├── linux/scripts/     # Linux sync daemon, utilities
│   └── windows/scripts/   # PowerShell sync daemon
├── machines/              # Machine-specific configurations
├── universal/             # Cross-platform configurations
├── tests/                 # Test suite
│   ├── run_all.sh         # Test runner
│   ├── unit/              # Unit tests
│   └── integration/       # Integration tests
└── docs/                  # Documentation
```

---

## Code Style Guidelines

### Bash Scripts

All bash scripts must pass [ShellCheck](https://www.shellcheck.net/) without errors.

```bash
# Run ShellCheck on a file
shellcheck bootstrap.sh

# Run on all shell scripts
find . -name "*.sh" -exec shellcheck {} \;
```

**Style requirements:**

```bash
#!/bin/bash
# Always include shebang and description comment

set -e  # Exit on error (use for scripts, not libraries)

# Use lowercase for variables, UPPERCASE for constants/exports
local my_variable="value"
export REPO_DIR="/path/to/repo"

# Quote all variable expansions
echo "$my_variable"
cp "$source" "$destination"

# Use [[ ]] for conditionals, not [ ]
if [[ -f "$file" ]]; then
    echo "File exists"
fi

# Use descriptive function names with documentation
#######################################
# Validates pre-flight requirements.
# Arguments:
#   $1 - Repository directory path
# Returns:
#   0 on success, 1 on failure
#######################################
validate_preflight() {
    local repo_dir="$1"
    # ...
}
```

### PowerShell Scripts

Follow [PowerShell Best Practices](https://docs.microsoft.com/en-us/powershell/scripting/developer/cmdlet/cmdlet-development-guidelines).

```powershell
# Use approved verbs: Get-, Set-, New-, Remove-, etc.
function Get-MachineInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$MachineName
    )
    # ...
}

# Use PascalCase for function names, $camelCase for variables
$machineConfig = Get-Content -Path $configPath | ConvertFrom-Json
```

### YAML Files

- Use 2-space indentation
- Quote strings containing special characters
- Include comments for non-obvious values

```yaml
machines:
  macbook-air:
    hostname: macbook-air
    platform: linux
    # This machine runs Arch Linux with Hyprland
    desktop: Hyprland
```

### Markdown Files

- Use ATX-style headers (`#`, `##`, `###`)
- Include a table of contents for long documents
- Use fenced code blocks with language hints
- Keep lines under 120 characters when reasonable

---

## Testing Requirements

All contributions must pass the test suite before merging.

### Running Tests

```bash
# Run all tests
./tests/run_all.sh

# Run only unit tests (faster, for quick iteration)
CI_QUICK=true ./tests/run_all.sh
```

### Test Structure

```
tests/
├── run_all.sh              # Main test runner
├── unit/                   # Fast, isolated tests
│   ├── test_validator.sh   # Tests for lib/validator.sh
│   └── test_rollback.sh    # Tests for lib/rollback.sh
└── integration/            # End-to-end tests (optional)
```

### Writing Tests

Create test files in the appropriate directory:

```bash
#!/bin/bash
# tests/unit/test_my_feature.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/my_feature.sh"

# Test: my_function returns expected value
test_my_function_basic() {
    local result
    result=$(my_function "input")

    if [[ "$result" == "expected" ]]; then
        echo "PASS: my_function basic"
        return 0
    else
        echo "FAIL: my_function basic - got '$result', expected 'expected'"
        return 1
    fi
}

# Run tests
test_my_function_basic
```

### What to Test

- All new library functions in `lib/`
- Edge cases (empty input, missing files, permission errors)
- Platform-specific behavior when applicable
- Rollback scenarios for destructive operations

---

## Pull Request Process

### Before Submitting

1. **Create an issue first** for significant changes
2. **Fork the repository** and create a feature branch
3. **Run the test suite** and ensure all tests pass
4. **Run ShellCheck** on any bash scripts you've modified
5. **Update documentation** if your change affects user-facing behavior

### Branch Naming

Use descriptive branch names:

```
feature/add-macos-support
fix/sync-daemon-race-condition
docs/improve-windows-setup
refactor/consolidate-validation
```

### Submitting

1. Push your branch to your fork
2. Open a pull request against `main`
3. Fill out the PR template with:
   - Summary of changes
   - Related issue number(s)
   - Testing performed
   - Platform(s) tested on

### Review Process

1. Maintainers will review your PR
2. Address any feedback with additional commits
3. Once approved, a maintainer will merge your PR
4. Your contribution will be acknowledged in the commit history

---

## Commit Message Conventions

This project uses **platform tags** to categorize changes. Always include the appropriate tag at the start of your commit message.

### Tag Reference

| Tag | When to Use | Example |
|-----|-------------|---------|
| `[universal]` | Changes that work on all platforms | Settings, shared configs, documentation |
| `[linux]` | Linux-specific changes | Bash scripts, systemd services, Hyprland configs |
| `[windows]` | Windows-specific changes | PowerShell scripts, Task Scheduler, registry |
| `[machine:<hostname>]` | Machine-specific changes | GPU tweaks, monitor layouts, hardware-specific fixes |
| `[docs]` | Documentation only | README updates, guides, comments |
| `[tests]` | Test-related changes | New tests, test infrastructure |

### Message Format

```
[tag] Short summary (50 chars or less)

Longer description if needed. Explain what changed and why,
not how (the code shows how). Wrap at 72 characters.

- Use bullet points for multiple changes
- Reference issues with #123

Co-Authored-By: Your Name <your@email.com>
```

### Examples

```bash
# Good commit messages
[linux] Add inotifywait-based file watching to sync daemon
[windows] Fix PowerShell profile path detection on Server editions
[universal] Add machine registry validation to bootstrap
[machine:macbook-air] Configure keyboard backlight persistence
[docs] Add troubleshooting section for Git LFS issues
[tests] Add unit tests for rollback module

# Bad commit messages (avoid these)
Fixed stuff                    # Not descriptive
[linux] Updated files          # What files? Why?
WIP                            # Don't commit work-in-progress
```

### Decision Tree for Tags

```
Is the change hardware-dependent (monitor, GPU, trackpad)?
  └─ YES → [machine:<hostname>]

Is the change OS-specific (bash vs PowerShell, systemd vs Task Scheduler)?
  └─ YES → [linux] or [windows]

Is it documentation only?
  └─ YES → [docs]

Is it test-only?
  └─ YES → [tests]

Otherwise:
  └─ [universal]
```

---

## Code of Conduct

We are committed to providing a welcoming and inclusive environment for all contributors.

### Our Standards

**Positive behaviors:**
- Being respectful and inclusive
- Providing constructive feedback
- Accepting constructive criticism gracefully
- Focusing on what's best for the community

**Unacceptable behaviors:**
- Harassment, trolling, or personal attacks
- Publishing others' private information
- Any conduct that would be inappropriate in a professional setting

### Reporting Issues

If you experience or witness unacceptable behavior, please report it by opening an issue or contacting the maintainer directly. All reports will be handled confidentially.

---

## Getting Help

### Resources

- **[CLAUDE.md](./CLAUDE.md)** - Project memory with detailed context
- **[README.md](./README.md)** - Quick start and overview
- **[docs/](./docs/)** - Platform-specific guides and troubleshooting

### Questions?

- **Search existing issues** - Your question may already be answered
- **Open a discussion** - For general questions or ideas
- **Open an issue** - For bugs or feature requests

### Quick Answers

**Q: My changes work on Linux but I can't test Windows. What do I do?**

A: That's okay! Submit your PR with `[linux]` tag and note that Windows testing is needed. A maintainer or another contributor can test on Windows.

**Q: How do I know which tag to use?**

A: Use the decision tree above. When in doubt, ask in your PR or issue.

**Q: Do I need to add tests for documentation changes?**

A: No, documentation-only changes (`[docs]`) don't require tests.

---

Thank you for contributing to Claude Cross-Machine Sync! Your efforts help developers everywhere maintain consistent AI-powered workflows across their machines.
