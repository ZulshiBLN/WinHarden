# WinHarden Release Guide

Complete guide for releasing WinHarden to GitHub and PowerShell Gallery.

---

## Quick Release (1 Step - Fully Automated!)

```powershell
# Create tag and push (both GitHub Release & PSGallery publishing are automatic!)
git tag -a v1.12.0 -m "Release: v1.12.0 - Description here"
git push origin v1.12.0
git push github v1.12.0

# Done! Workflow handles everything:
# - Creates GitHub Release (~1 min)
# - Publishes to PowerShell Gallery (~2 min)
# - Verifies publication (~30 sec)
```

**Watch the automation:**
- GitHub: https://github.com/ZulshiBLN/WinHarden/actions
- Check progress in "Workflows" tab

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

### Phase 3: Automatic PowerShell Gallery Publishing ✅ AUTOMATED

GitHub Actions automatically handles PowerShell Gallery publishing!

**Prerequisites (Setup Once):**
1. Register at https://www.powershellgallery.com
2. Create API key: https://www.powershellgallery.com/account/apikeys
3. Add to GitHub Secrets:
   - Repo Settings → Secrets and variables → Actions
   - New secret: `PSGALLERY_API_KEY = "oy2a1b2c3d4e5f6g7h8i9j0k1l2m3n4o"`

**That's it!** Tag push automatically triggers:
```powershell
git tag v1.12.0
git push github v1.12.0
# → GitHub Actions automatically publishes to PSGallery
```

**Monitor Publication:**
- GitHub Actions: https://github.com/ZulshiBLN/WinHarden/actions
- Watch "Create Release & Publish" workflow
- Should complete in ~3-5 minutes total

**Verify Publication:**
```powershell
# Check GitHub Release (instant, ~1 min)
# https://github.com/ZulshiBLN/WinHarden/releases

# Check PowerShell Gallery (takes 5-10 min to index)
Find-Module -Name WinHarden -Repository PSGallery

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

## Fully Automated Release (ENABLED ✅)

Your release pipeline is **fully automated**!

### Setup (One-time)
```
GitHub Repo → Settings → Secrets and variables → Actions
→ New secret: PSGALLERY_API_KEY = "your-api-key"
```

### Release (Just tag & push)
```powershell
git tag -a v1.12.0 -m "Release: v1.12.0 - Description"
git push origin v1.12.0
git push github v1.12.0
```

### What happens automatically
1. **GitHub Actions triggered** (0 sec)
2. **GitHub Release created** (~1 min)
3. **ZIP archive generated** (~1 min)
4. **PowerShell Gallery publish** (~2 min)
5. **Publication verified** (~30 sec)

Total time: **~4-5 minutes** ⚡

### Monitor progress
- Open: https://github.com/ZulshiBLN/WinHarden/actions
- Click latest workflow run
- Watch each step execute

---

## Support

For release issues:
- GitHub Issues: https://github.com/ZulshiBLN/WinHarden/issues
- PowerShell Gallery: Contact support at PSGallery
- Azure DevOps: Check repository settings


## Test Entry

This is a test beta release.
