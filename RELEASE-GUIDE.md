# WinHarden Release Guide

Complete guide for releasing WinHarden to GitHub and PowerShell Gallery.

---

## Quick Release (2 Steps)

```powershell
# Step 1: Tag and push (triggers GitHub Release)
git tag -a v1.12.0 -m "Release: v1.12.0 - Description here"
git push origin v1.12.0
git push github v1.12.0

# Step 2: Publish to PowerShell Gallery (manual, ~5 min later)
.\Publish-ToGallery.ps1 -NuGetApiKey $env:PSGALLERY_API_KEY
```

---

## Detailed Release Process

### Phase 1: Prepare Release

1. **Update Version Numbers**
   ```powershell
   # Update WinHarden.psd1
   ModuleVersion = '1.12.0'
   ReleaseNotes = 'https://github.com/ZulshiBLN/WinHarden/releases/tag/v1.12.0'
   ```

2. **Update CLAUDE.md Release Notes** (if major changes)
   ```markdown
   **Version:** v1.12.0  
   **Release:** v1.12.0 - Feature description
   ```

3. **Test Everything**
   ```powershell
   .\build.ps1 -Validate
   Invoke-Pester -Path tests/ -CodeCoverage
   ```

4. **Commit & Push**
   ```powershell
   git add WinHarden.psd1 CLAUDE.md
   git commit -m "Release: v1.12.0 - Description"
   git push origin main
   git push github main
   ```

### Phase 2: Create Release Tag

```powershell
# Create annotated tag (recommended)
git tag -a v1.12.0 -m "Release: v1.12.0 - Feature X, Bug fixes Y"

# Push to both remotes
git push origin v1.12.0
git push github v1.12.0
```

**This automatically:**
- Triggers GitHub Actions workflow
- Creates GitHub Release
- Generates ZIP download
- Creates release notes from commits

### Phase 3: Publish to PowerShell Gallery

**Prerequisites:**
1. Register at https://www.powershellgallery.com
2. Create API key: https://www.powershellgallery.com/account/apikeys
3. Store API key securely

**Publishing:**
```powershell
# Option 1: Direct (requires API key)
.\Publish-ToGallery.ps1 -NuGetApiKey "oy2a1b2c3d4e5f6g7h8i9j0k1l2m3n4o"

# Option 2: Environment variable (more secure)
$env:PSGALLERY_API_KEY = "oy2a1b2c3d4e5f6g7h8i9j0k1l2m3n4o"
.\Publish-ToGallery.ps1 -NuGetApiKey $env:PSGALLERY_API_KEY

# Option 3: GitHub Secrets (future automation)
# Add PSGALLERY_API_KEY to GitHub Secrets
# Then GitHub Actions can auto-publish
```

**Verify Publication:**
```powershell
# Wait 5-10 minutes for indexing
Find-Module -Name WinHarden
Find-Module -Name WinHarden -RequiredVersion 1.12.0

# Install to test
Install-Module -Name WinHarden -RequiredVersion 1.12.0 -Scope CurrentUser
```

---

## Release Channels

### GitHub Releases
- **What:** ZIP download with full code
- **When:** Automatic on tag push
- **Who:** Developers, manual/scripted downloads
- **Where:** https://github.com/ZulshiBLN/WinHarden/releases

### PowerShell Gallery
- **What:** Installable module via `Install-Module`
- **When:** Manual publish (after GitHub Release)
- **Who:** Enterprise/standard users
- **Where:** https://www.powershellgallery.com/packages/WinHarden

### Azure DevOps
- **What:** Same as GitHub (dual sync)
- **When:** Every commit pushed
- **Who:** Internal teams
- **Where:** Azure DevOps repository

---

## Release Checklist

- [ ] Version updated in WinHarden.psd1
- [ ] CLAUDE.md updated with version
- [ ] `.\build.ps1 -Validate` passes
- [ ] Pester tests pass: `Invoke-Pester -Path tests/`
- [ ] Commit & push to main
- [ ] Git tag created: `git tag -a v1.12.0 -m "Release: ..."`
- [ ] Tag pushed: `git push origin v1.12.0 && git push github v1.12.0`
- [ ] GitHub Release created automatically
- [ ] ZIP download available on GitHub
- [ ] PowerShell Gallery API key ready
- [ ] Run: `.\Publish-ToGallery.ps1 -NuGetApiKey <KEY>`
- [ ] Wait 5-10 min for PSGallery indexing
- [ ] Verify: `Find-Module -Name WinHarden`
- [ ] Test install: `Install-Module -Name WinHarden -RequiredVersion 1.12.0`

---

## Troubleshooting

### GitHub Release not created
```powershell
# Check: Is tag pushed correctly?
git push origin v1.12.0
git push github v1.12.0

# Check: GitHub Actions status
# https://github.com/ZulshiBLN/WinHarden/actions
```

### PowerShell Gallery publish fails
```powershell
# Validate manifest first
Test-ModuleManifest .\WinHarden.psd1

# Check API key format
Write-Host $NuGetApiKey.Length  # Should be ~40 chars

# Try manual publish
Publish-Module -Path . -NuGetApiKey $key -Repository PSGallery -Verbose
```

### Module not found after publish
```powershell
# Wait 5-10 minutes for indexing
Get-PSRepository  # Verify PSGallery is registered
Find-Module -Name WinHarden -Repository PSGallery -ErrorAction Stop

# Clear cache if needed
$moduleCachePath = "$env:APPDATA\NuGet\Cache"
Remove-Item -Path $moduleCachePath -Force -Recurse -ErrorAction SilentlyContinue
```

---

## Version Numbering

WinHarden uses **Semantic Versioning**: MAJOR.MINOR.PATCH

- **MAJOR** (v2.0.0): Breaking changes, architectural redesign
- **MINOR** (v1.12.0): New features, backward compatible
- **PATCH** (v1.11.1): Bug fixes only

Examples:
- v1.11.0 → v1.12.0 (new feature: Scheduling)
- v1.12.0 → v1.12.1 (bug fix)
- v1.x → v2.0.0 (breaking changes)

---

## Automated Release (Future)

To fully automate PowerShell Gallery publishing:

1. **Add API Key to GitHub Secrets**
   - Settings → Secrets and variables → Actions
   - Create: `PSGALLERY_API_KEY = "oy2a..."`

2. **Update Workflow**
   ```yaml
   - name: Publish to PowerShell Gallery
     env:
       PSGALLERY_API_KEY: ${{ secrets.PSGALLERY_API_KEY }}
     run: |
       pwsh -Command ".\Publish-ToGallery.ps1 -NuGetApiKey $env:PSGALLERY_API_KEY"
   ```

3. **Tag & Push** (workflow handles rest)
   ```powershell
   git tag v1.12.0 && git push origin v1.12.0
   ```

---

## Support

For release issues:
- GitHub Issues: https://github.com/ZulshiBLN/WinHarden/issues
- PowerShell Gallery: Contact support at PSGallery
- Azure DevOps: Check repository settings
