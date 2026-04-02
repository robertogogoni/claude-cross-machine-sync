---
name: Release workflow for aifuel
description: After each version, run full tests, commit, update changelog, tag, push, verify release build
type: feedback
---

After completing each version's features, always follow the full release cycle before presenting results:

1. Run all tests (Go build, go vet, bash -n on all scripts, functional tests)
2. Commit with descriptive message
3. Update CHANGELOG.md with the new version entry
4. Update README if features changed
5. Push to master
6. Tag with semver (git tag -a vX.Y.Z)
7. Push tag to trigger GoReleaser
8. Wait for release build, verify it succeeded
9. Download and test the released binary

**Why:** User wants a complete, shippable release at each version boundary, not partial commits. Each version should be a clean, tested, documented release that anyone can install.

**How to apply:** Never present a version as "done" without the full cycle. The CHANGELOG, tag, and verified release binary are as important as the code itself.
