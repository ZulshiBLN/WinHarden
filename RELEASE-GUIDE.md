# WinHarden Release Guide

Complete guide for the Three-Tier Release Model: Development → Pre-Release → Stable Release.

---

## Quick Reference

### Development Phase
```powershell
git checkout develop
git add <files>
git commit -m "Feature: Description"
git push origin develop && git push github develop
```

### Pre-Release Phase
```powershell
git checkout prerelease
git merge develop
git tag -a v1.12.0-beta.1 -m "Release: v1.12.0-beta.1 - Description"
git push origin prerelease && git push github prerelease
git push origin v1.12.0-beta.1 && git push github v1.12.0-beta.1
```

### Stable Release Phase
```powershell
git checkout main
git merge prerelease
git tag -a v1.12.0 -m "Release: v1.12.0 - Description"
git push origin main && git push github main
git push origin v1.12.0 && git push github v1.12.0
```

---

## PowerShell Gallery Listing Policy ⭐

**Critical Policy:** Only stable releases are listed on PowerShell Gallery.

### Listing Rules

| Version Type | Listed on PSGallery | Available On | Use Case |
|---|---|---|---|
| **Stable** (v1.13.0) | ✅ YES | PowerShell Gallery + GitHub | Production use, `Install-Module` |
| **Beta** (v1.13.0-beta.1) | ❌ NO | GitHub Releases only | Community testing, early feedback |
| **RC** (v1.13.0-rc.1) | ❌ NO | GitHub Releases only | Final pre-release testing |
| **Old Versions** | ❌ UNLISTED | GitHub Releases only | Backward compatibility |

### Why This Matters

```
Goal: Ensure stable users only see production-ready versions

❌ BAD: All versions on PSGallery → Confusion, users install beta by accident
✅ GOOD: Only stable on PSGallery → Clear, only production versions public

Pre-releases are GitHub-only for interested testers.
Stable releases go to PSGallery for mainstream users.
```

### Policy Enforcement

**Automatic checks:**
1. ✅ Publish-ToGallery.ps1 validates version format before publishing
2. ✅ GitHub Actions detects pre-release tags and SKIPS PSGallery
3. ✅ Manual publish requires stable version (no -beta/-rc/-alpha suffix)

**What happens if you try to publish a beta version:**
```powershell
$ .\Publish-ToGallery.ps1 -NuGetApiKey "..."

[PUBLISH] Validating Release Type
[ERROR] Cannot publish pre-release to PowerShell Gallery: 1.13.0-beta.1
ERROR: Only stable releases (v1.x.x) can be published to PSGallery

To publish a stable version:
  1. Update ModuleVersion to remove -beta/-rc suffix
  2. Merge from prerelease → main
  3. Tag as stable (v1.x.x)
  4. Re-run publish script
```

---

## Detailed Release Process

### Phase 1: Development (develop branch)

**Duration:** Usually 2-4 weeks

#### What to do on `develop`:
- Create new features
- Fix bugs
- Update documentation
- Write tests
- No version changes needed

#### Daily workflow:
```powershell
git checkout develop
git add src/ tests/ docs/
git commit -m "Feature: New hardening profile

- Add Baseline profile
- Update documentation
- Add unit tests"

git push origin develop
git push github develop
```

#### Commit message types:
- `Feature:` New functionality
- `Fix:` Bug fixes
- `Refactor:` Code structure changes
- `Test:` Test additions/improvements
- `Docs:` Documentation updates
- `Cleanup:` Code cleanup

#### Rules:
- ✅ Commit early and often
- ✅ Keep develop always building (run `.\build.ps1 -Validate`)
- ❌ Don't change version numbers
- ❌ Don't create tags
- ❌ Don't merge to other branches

---

### Phase 2: Pre-Release (prerelease branch)

**Duration:** Usually 1-2 weeks

#### When to move to pre-release:
- All planned features completed
- Main bugs fixed
- Code review complete
- Ready for community testing

#### Step 1: Merge develop → prerelease

```powershell
git checkout prerelease
git merge develop

# Verify merge went clean
git log --oneline -5

# Push to both remotes
git push origin prerelease
git push github prerelease
```

#### Step 2: Update version files

```powershell
# Update WinHarden.psd1
ModuleVersion = '1.12.0'

# Update CLAUDE.md
**Version:** v1.12.0

# Update README.md
**Version:** 1.12.0
**Release:** v1.12.0 - Feature descriptions

# Commit
git add WinHarden.psd1 CLAUDE.md README.md
git commit -m "Release: v1.12.0-beta.1 - Version bump"
git push origin prerelease && git push github prerelease
```

#### Step 3: Create beta tag

```powershell
git tag -a v1.12.0-beta.1 -m "Release: v1.12.0-beta.1 - Initial Beta Release

## What's New
- Feature: New hardening profiles (Baseline, Standard, Strict+)
- Feature: SIEM integration improvements
- Fix: Critical bug in compliance checking
- Fix: PowerShell 7.x compatibility issues

## Testing Focus
Please test:
- All three hardening profiles on WS2019, 2022, 2025
- Remote deployment with -ComputerName parameter
- SIEM integration with Splunk/Elasticsearch
- Compliance reporting in all formats (JSON, CSV, HTML)

## Known Issues
- Issue 1: Performance degradation on large enterprise networks
- Issue 2: Minor UI glitch in HTML reports

## Installation
Install-Module -Name WinHarden -Repository PSGallery -RequiredVersion 1.12.0-beta.1

## Support
Report issues: https://github.com/ZulshiBLN/WinHarden/issues"

git push origin v1.12.0-beta.1
git push github v1.12.0-beta.1
```

#### Step 4: GitHub Release automation

GitHub Actions automatically:
- Creates GitHub Release with "Pre-release" checkbox
- Generates ZIP download
- **Does NOT** publish to PowerShell Gallery

**Verify:**
- https://github.com/ZulshiBLN/WinHarden/releases/tag/v1.12.0-beta.1
- Download ZIP
- Test installation from GitHub

#### Step 5: Community testing & feedback

**During pre-release phase:**
- Share beta version in community forums
- Gather feedback from early adopters
- Fix reported bugs on `prerelease` branch

#### Fixing bugs during pre-release:

```powershell
# Fix bugs on prerelease
git checkout prerelease
git add fixes/
git commit -m "Fix: Critical bug in hardening profile parsing"
git push origin prerelease && git push github prerelease

# After fixes, create new beta tag
git tag -a v1.12.0-beta.2 -m "Release: v1.12.0-beta.2 - Bug fixes

## Changes
- Fix: Hardening profile parsing error
- Fix: CSV export encoding issue
- Improvement: Better error messages"

git push origin v1.12.0-beta.2 && git push github v1.12.0-beta.2

# Optional: Update develop with fixes
git checkout develop
git merge prerelease
git push origin develop && git push github develop
```

#### Release Candidate (optional):

After 2-3 betas, optionally create RC:

```powershell
git tag -a v1.12.0-rc.1 -m "Release: v1.12.0-rc.1 - Release Candidate

Final candidate for v1.12.0. No new features, critical fixes only."

git push origin v1.12.0-rc.1 && git push github v1.12.0-rc.1
```

---

### Phase 3: Stable Release (main branch)

**Duration:** Final approval and publication

#### When to promote to stable:
- All reported beta issues resolved
- Testing confirms stability
- Ready for production deployment
- Version numbers final

#### Step 1: Merge prerelease → main

```powershell
git checkout main
git merge prerelease

# Verify
git log --oneline -5

# Push to both remotes
git push origin main
git push github main
```

#### Step 2: Create stable tag

```powershell
git tag -a v1.12.0 -m "Release: v1.12.0 - Stable Release

WinHarden v1.12.0 is ready for production deployment.

## What's New
- Feature: New hardening profiles (Baseline, Standard, Strict+)
- Feature: SIEM integration improvements
- Feature: Enhanced compliance reporting
- Fix: Critical bug in compliance checking
- Fix: PowerShell 7.x compatibility issues
- Improvement: 30% performance improvement on large networks
- Improvement: Better error messages and logging

## Breaking Changes
None - Fully backward compatible with v1.11.x

## Installation

### PowerShell Gallery
\`\`\`powershell
Install-Module -Name WinHarden -RequiredVersion 1.12.0
\`\`\`

### Manual Download
https://github.com/ZulshiBLN/WinHarden/releases/tag/v1.12.0

## System Requirements
- Windows Server 2019, 2022, 2025
- Windows 11 Client
- PowerShell 5.1 or 7.x
- .NET Framework 4.5+

## Tested On
- Windows Server 2019 SP2
- Windows Server 2022 RTM, 21H2
- Windows Server 2025 (Preview)
- PowerShell 5.1 (Windows 10/11)
- PowerShell 7.4 (Core)

## Documentation
- [User Guide](https://github.com/ZulshiBLN/WinHarden/blob/main/docs/hardening/01_USER_GUIDE.md)
- [Deployment Guide](https://github.com/ZulshiBLN/WinHarden/blob/main/docs/hardening/02_DEPLOYMENT_GUIDE.md)
- [Architecture](https://github.com/ZulshiBLN/WinHarden/blob/main/docs/hardening/03_ARCHITECTURE.md)

## Support & Issues
- Report bugs: https://github.com/ZulshiBLN/WinHarden/issues
- Discussions: https://github.com/ZulshiBLN/WinHarden/discussions

## Contributors
- Michel Brosche (@ZulshiBLN)

---

**Status:** ✓ Production Ready (Grade A+)
**Published:** $(date)"

git push origin v1.12.0
git push github v1.12.0
```

#### Step 3: Automated publishing

GitHub Actions automatically:
- Creates GitHub Release (Final)
- Publishes to PowerShell Gallery
- Verifies publication
- Sends notification

**Expected timeline:**
- 0-1 min: GitHub Release created
- 1-2 min: ZIP archive generated
- 2-3 min: PowerShell Gallery publishing
- 3-5 min: Verification complete

**Verify publication:**
```powershell
# Wait 5-10 minutes for PSGallery indexing
Find-Module -Name WinHarden -Repository PSGallery

# Install from PSGallery
Install-Module -Name WinHarden -RequiredVersion 1.12.0

# Verify installation
Get-Module WinHarden -ListAvailable
```

---

## Version Numbering Scheme

### Semantic Versioning (SemVer)

```
MAJOR.MINOR.PATCH
1.12.0
│ │   │
│ │   └─ PATCH: Bugfixes only (v1.12.0 → v1.12.1)
│ └───── MINOR: New features, backward compatible (v1.12.0 → v1.13.0)
└─────── MAJOR: Breaking changes (v1.x → v2.0.0)
```

### Examples

| Scenario | Old | New | Type |
|----------|-----|-----|------|
| Bugfixes in v1.12.0 | v1.12.0 | v1.12.1 | PATCH |
| New features | v1.12.1 | v1.13.0 | MINOR |
| API redesign | v1.x | v2.0.0 | MAJOR |
| Beta 1 | - | v1.12.0-beta.1 | Pre-release |
| Beta 2 | v1.12.0-beta.1 | v1.12.0-beta.2 | Pre-release |
| Release Candidate | - | v1.12.0-rc.1 | Pre-release |
| Final Stable | v1.12.0-rc.1 | v1.12.0 | Release |

---

## Release Checklist

### Pre-Release Preparation
- [ ] All features on `develop` branch
- [ ] `.\build.ps1 -Validate` passes
- [ ] All tests pass: `Invoke-Pester -Path tests/`
- [ ] Code review complete
- [ ] Documentation updated
- [ ] CHANGELOG updated (if applicable)

### Beta Release
- [ ] `develop` merged into `prerelease`
- [ ] Version numbers updated (all files)
- [ ] Beta tag created with full release notes
- [ ] Tag pushed to both remotes
- [ ] GitHub Release created (verified Pre-release checkbox)
- [ ] Community notified for testing

### Bug Fix During Beta
- [ ] Bugs fixed on `prerelease`
- [ ] Tests pass
- [ ] New beta tag created (beta.2, beta.3, etc.)
- [ ] Feedback gathered

### Stable Release
- [ ] All beta issues resolved
- [ ] Final testing complete
- [ ] `prerelease` merged into `main`
- [ ] Version numbers finalized
- [ ] Stable tag created with complete release notes
- [ ] Tag pushed to both remotes
- [ ] GitHub Release published (verify Final Release)
- [ ] PowerShell Gallery publication verified
- [ ] Announcement sent

---

## Hotfixes (Emergency Releases)

For critical bugs in stable version:

```powershell
# Create hotfix branch from main
git checkout main
git checkout -b hotfix/critical-bug

# Fix the issue
git add fixes/
git commit -m "Hotfix: Critical security issue in hardening"

# Create patch version tag
git tag -a v1.12.1 -m "Hotfix: v1.12.1 - Critical Security Fix"

# Push directly to main (exception to normal flow)
git checkout main
git merge hotfix/critical-bug
git push origin main && git push github main
git push origin v1.12.1 && git push github v1.12.1

# Clean up hotfix branch
git branch -d hotfix/critical-bug
```

---

## Troubleshooting

### GitHub Release not created
```
Check: GitHub Actions at https://github.com/ZulshiBLN/WinHarden/actions
Likely causes:
1. Tag not pushed: git push github v1.12.0
2. Permissions issue: Check GITHUB_TOKEN permissions
3. Workflow error: Check Actions log details
```

### PowerShell Gallery publish failed
```
Check: GitHub Actions logs (PSGallery section)
Likely causes:
1. API Key incorrect in GitHub Secret
2. Version already published
3. Manifest validation failed

Solution:
1. Test locally: .\Publish-ToGallery.ps1 -NuGetApiKey $key
2. Check manifest: Test-ModuleManifest .\WinHarden.psd1
3. Increment version and retry
```

### Module not installing from PSGallery
```
PowerShell Gallery indexing takes 5-10 minutes

Check:
1. Wait 10 minutes
2. Run: Find-Module -Name WinHarden -Repository PSGallery
3. Clear cache: Remove-Item "$env:APPDATA\NuGet\Cache" -Recurse
4. Retry: Install-Module -Name WinHarden
```

---

## Related Documentation

- [CLAUDE.md](CLAUDE.md) - Git Workflow & Branch Rules
- [RELEASE-GUIDE.md](RELEASE-GUIDE.md) - This file
- [GitHub Releases](https://github.com/ZulshiBLN/WinHarden/releases) - Published releases
- [PowerShell Gallery](https://www.powershellgallery.com/packages/WinHarden) - Module repository

