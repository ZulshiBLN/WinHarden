# Windows Hardening Script - Implementation Plan

**Projekt:** WinOpsKit System Module Enhancement  
**Feature:** Comprehensive Windows Hardening (Clients + Server)  
**Status:** Planning Phase  
**Version:** 1.0.0

---

## 1. ARCHITEKTUR-ÜBERSICHT

### 1.1 Modulstruktur

```
functions/System/
├── Hardening/                          # Neue Hardening-Funktionen
│   ├── Get-HardeningProfile.ps1       # Load Hardening Profile (Basis/Recommended/Strict)
│   ├── New-HardeningSession.ps1       # Init Hardening Session mit State
│   ├── Invoke-SecurityHardening.ps1   # Main Orchestration Function
│   ├── Test-HardeningCompliance.ps1   # Verify Hardening Applied
│   └── _ApplyHardeningRule.ps1        # Private: Rule Application Helper
│
├── Hardening.Profiles/                # Hardening Profile Definitions
│   ├── Basis.psd1                     # Basic Security Rules
│   ├── Recommended.psd1               # Recommended Security Rules
│   └── Strict.psd1                    # Strict Security Rules
│
└── Hardening.Rules/                   # Modular Security Rules
    ├── Account.Policy.ps1             # Account Policy Rules
    ├── Firewall.Policy.ps1            # Windows Firewall Rules
    ├── Registry.Hardening.ps1         # Registry Security Rules
    ├── Service.Hardening.ps1          # Service Configuration Rules
    ├── UAC.Policy.ps1                 # User Account Control Rules
    ├── Update.Policy.ps1              # Windows Update Rules
    ├── Encryption.Policy.ps1          # Encryption & BitLocker Rules
    ├── Network.Security.ps1           # Network Security Rules
    ├── SMB.Hardening.ps1              # SMB Protocol Rules
    ├── RDP.Security.ps1               # RDP Hardening Rules
    └── Audit.Policy.ps1               # Audit & Logging Rules
```

### 1.2 Abhängigkeiten (ADR-009)

```
Hardening Functions
    ↓
Core Module (Write-Log, Test-NotNullOrEmpty, etc.)
    ↓
System Module (Exchange Online Connection helpers)
    ↓
External Modules: GroupPolicy, Compliance (optional)
```

---

## 2. FUNKTIONAL-ANFORDERUNGEN

### 2.1 Hauptfunktionen (Public)

#### **New-HardeningSession**
```
Zweck: Initialisiere Hardening Session mit Validierung
Input: 
  - Profile: Basis|Recommended|Strict
  - TargetSystem: Client|Server
  - OSVersion: 11|2019|2022|2025
  - WhatIf: true/false
Output: HardeningSession Object
Abhängigkeiten: Write-Log (Core), Test-NotNullOrEmpty (Core)
```

#### **Invoke-SecurityHardening**
```
Zweck: Führe Hardening nach Profil durch
Input: 
  - Session: HardeningSession Object
  - RuleFilter: Array of Rule Names (optional)
  - SkipVerification: true/false
Output: HardeningResult Object mit Applied/Failed Rules
Abhängigkeiten: _ApplyHardeningRule (private), Write-Log (Core)
```

#### **Test-HardeningCompliance**
```
Zweck: Verifiziere Hardening Compliance
Input: 
  - Session: HardeningSession Object
  - Profile: Basis|Recommended|Strict
Output: ComplianceReport Object mit Compliance %
Abhängigkeiten: Write-Log (Core)
```

#### **Get-HardeningProfile**
```
Zweck: Lade Hardening Profile von Datei
Input: 
  - ProfileName: Basis|Recommended|Strict
  - TargetSystem: Client|Server
Output: Profile Hashtable mit Rules
Abhängigkeiten: Test-ValidPath (Core)
```

### 2.2 Private Funktionen

#### **_ApplyHardeningRule**
```
Zweck: Wende einzelne Hardening Rule an
Input: Rule Object (mit Type: Registry|Service|Firewall|etc.)
Output: RuleResult (Success/Failed + Error)
```

#### **_ValidateOSSupport** (privat)
```
Zweck: Prüfe OS-Version gegen Unterstützung
Input: OSVersion, TargetSystem
Output: boolean
```

#### **_CheckPrerequisites** (privat)
```
Zweck: Verifiziere Admin Rights, Module Availability
Output: boolean | Exception
```

---

## 3. HARDENING RULES DEFINITION

### 3.1 Rule Structure (Generisch)

Jede Rule folgt diesem Schema:

```powershell
@{
    Name = 'Rule-Name'
    Description = 'What this rule does'
    Category = 'Account.Policy|Firewall.Policy|etc'
    Severity = 'Critical|High|Medium|Low'
    Profiles = @('Basis', 'Recommended', 'Strict')  # In welchen Profilen enthalten
    OSSupport = @{
        'Client' = @('11')
        'Server' = @('2019', '2022', '2025')
    }
    Type = 'Registry|Service|Firewall|File|GPO|Audit'
    RuleDefinition = @{
        # Type-spezifische Definition
    }
    Verification = @{
        # How to verify this rule was applied
    }
}
```

### 3.2 Hardening Categories (10 Kategorien)

1. **Account.Policy** (Kennwort-Richtlinien, Account Lockout)
   - Minimum Password Length: 12 (Recommended) / 14 (Strict)
   - Password Complexity: Enabled (all profiles)
   - Account Lockout Duration: 15 minutes
   - Kerberos Policy (Server only)

2. **Firewall.Policy** (Windows Defender Firewall)
   - Inbound/Outbound default deny
   - Profile-specific rules
   - Disable ICMP echo requests
   - Disable mDNS

3. **Registry.Hardening** (Registry Security)
   - UAC: Prompt for privilege elevation
   - DEP/ASLR enforcement
   - Credential Guard (Server)
   - Spectre/Meltdown mitigations
   - LmCompatibilityLevel (LAN Manager)
   - NTLMv2 enforcement

4. **Service.Hardening** (Service Policies)
   - Disable unnecessary services (WinRM, Telnet, etc.)
   - Set service startup type
   - Services: Print Spooler, BITS, RPC

5. **UAC.Policy** (User Account Control)
   - Elevation prompt for admins
   - Detect application installations
   - Only allow UIAccess apps

6. **Update.Policy** (Windows Updates)
   - Enable automatic updates
   - Install security updates immediately
   - Restart without prompt (Server only)

7. **Encryption.Policy** (BitLocker, TLS)
   - BitLocker for OS drive (Strict)
   - TLS 1.2 minimum
   - Disable obsolete cipher suites
   - SMB Encryption (Server)

8. **Network.Security** (Network Hardening)
   - IPv6 (enable/disable based on profile)
   - IP Source Routing: disabled
   - ICMP Redirects: disabled
   - TCP/IP stack hardening

9. **SMB.Hardening** (SMB Protocol)
   - SMB1: Disabled (all profiles)
   - SMB2/3 encryption
   - SMB signing enforcement (Strict)

10. **RDP.Security** (Remote Desktop)
    - NLA enforcement
    - Encryption level: High
    - RDP port randomization (Recommended/Strict)
    - Disable clipboard/drive redirection (Strict)

11. **Audit.Policy** (Audit Logging)
    - Logon/Logoff auditing
    - Privilege Use auditing
    - Object Access auditing
    - Sensitive Data Auditing (Strict)

---

## 4. PROFILE DEFINITIONEN

### 4.1 Basis Profile

**Ziel:** Mindest-Sicherheit für produktive Umgebung

Enthaltene Rules:
- Account Policy: Min Password Length 12, Complexity
- Firewall: Enable with defaults
- UAC: Standard
- Updates: Auto security updates
- SMB1: Disabled
- RDP: NLA enabled
- Services: Stop unnecessary (Print Spooler optional)

Estimated Rules: 15-20

### 4.2 Recommended Profile

**Ziel:** Mittel-Sicherheit für Standard-Deployments

Enthält Basis + zusätzlich:
- Account Policy: Min Password Length 12, Enhanced lockout
- Firewall: Strict inbound rules
- Registry: DEP, ASLR, Spectre mitigations
- Services: Disable more optional services
- Encryption: TLS 1.2+ only
- Audit: Standard logging
- RDP: Port randomization
- SMB: Signing enabled

Estimated Rules: 30-40

### 4.3 Strict Profile

**Ziel:** Maximum-Sicherheit für hochsensible Daten

Enthält Recommended + zusätzlich:
- Account Policy: Min Password Length 14, Strict lockout
- Firewall: Explicit allow rules only
- Registry: Full hardening + exploit mitigations
- Encryption: BitLocker mandatory (Client), TLS 1.3 (if available)
- Services: Only essential services running
- Audit: Extended logging + sensitive data
- RDP: Highly restricted, clipboard/drive disabled
- SMB: Signing mandatory, encryption forced
- Network: IPv6 disabled, strict IP filtering
- UAC: All checks enabled

Estimated Rules: 50-60

---

## 5. IMPLEMENTIERUNGS-STRATEGIE

### Phase 1: Core Infrastructure (Week 1)
- [ ] Erstelle Rule Schema & Validation
- [ ] Implementiere New-HardeningSession
- [ ] Implementiere Get-HardeningProfile
- [ ] Erstelle Profile-Dateien (Basis.psd1, Recommended.psd1, Strict.psd1)
- [ ] Tests: 25+ tests für Core functions

### Phase 2: Rule Application (Week 2)
- [ ] Implementiere _ApplyHardeningRule
- [ ] Implementiere Invoke-SecurityHardening
- [ ] Erstelle Hardening.Rules/* Funktionen (11 Kategorien)
- [ ] Tests: 50+ tests für Rule Application
- [ ] Manual Testing auf Client/Server

### Phase 3: Verification & Compliance (Week 3)
- [ ] Implementiere Test-HardeningCompliance
- [ ] Erstelle Verification-Logik pro Rule
- [ ] Erstelle Compliance-Reports
- [ ] Tests: 30+ tests für Verification
- [ ] Full Integration Testing

### Phase 4: Documentation & Optimization (Week 4)
- [ ] Dokumentation & Examples
- [ ] Performance Optimization
- [ ] Final Testing: 95%+ Coverage
- [ ] Code Review & Refactoring

---

## 6. PROJEKT-REGELN ANWENDUNG

### 6.1 STRUCTURE.md Rules

✅ **Regel 1.1-1.3:** Datei-Struktur
- Funktionen in `functions/System/Hardening/`
- Tests in `tests/System.Hardening.Tests.ps1`
- Profile in `functions/System/Hardening.Profiles/`

✅ **Regel 2.1-2.2:** Design-Prinzipien
- Scripts modular aus Hardening-Funktionen aufgebaut
- Alle Funktionen wiederverwendbar & generisch

✅ **Regel 3.1-3.3:** Funktions-Anforderungen
- Vollständige `.SYNOPSIS` in jeder Funktion
- `-WhatIf` Support in `Invoke-SecurityHardening`
- Performance-optimiert (Parallel rule application möglich)

✅ **Regel 4.1-4.8:** Testing
- Pester 5.x für alle Tests
- 95%+ Code Coverage
- Mock für externe Dependencies (Registry, Services, GPO)
- Test-Struktur: Describe → Context → It

✅ **Regel 8.1-8.8:** Naming Conventions
- `New-HardeningSession`, `Invoke-SecurityHardening` (Verb-Noun)
- `_ApplyHardeningRule` (Private mit underscore)
- `$hardeningSession`, `$hardeningResult` (camelCase)

### 6.2 CLAUDE.md Collaboration Rules

✅ **Regel 2.1-2.4:** Token-Effizienz
- Progressive Disclosure der Funktionen
- Fokussierte Code-Ausschnitte
- Keine Ganze-Datei-Uploads

✅ **Regel 3.1-3.3:** Code-Qualität
- Minimale Kommentare (nur WHY, nicht WHAT)
- ASCII-only Output Strings (keine Unicode)
- Keine Über-Abstraktionen

✅ **Regel 4.1-4.2:** Transparente Zusammenarbeit
- Klare Status-Updates nach jeder Phase
- Memory-System für Learnings

### 6.3 ADR Rules

- **ADR-003 (Testing):** 95% Coverage minimum
- **ADR-004 (Error Handling):** Try-Catch + Write-Log für Errors
- **ADR-005 (Logging):** Write-Log für alle wichtigen Aktionen
- **ADR-006 (Code Style):** PSScriptAnalyzer, K&R Bracing
- **ADR-007 (Naming):** Approved Verbs, PascalCase Parameters
- **ADR-008 (Module Import):** System.psm1 imports Hardening functions
- **ADR-009 (Dependencies):** Hardening → System → Core

---

## 7. TESTING STRATEGIE

### 7.1 Unit Tests (Primary)

**New-HardeningSession Tests (15 tests)**
- Parameter validation
- Profile validation
- OS version support
- Session creation

**Get-HardeningProfile Tests (10 tests)**
- Profile loading
- Default values
- Invalid profiles error handling

**Invoke-SecurityHardening Tests (20 tests)**
- Rule application per profile
- WhatIf behavior
- Error handling on rule failure
- Session state management

**Test-HardeningCompliance Tests (15 tests)**
- Compliance calculation
- Report generation
- Missing rules detection

### 7.2 Integration Tests (Secondary)

**End-to-End Hardening Flow (10 tests)**
- Full session lifecycle
- Rule application + verification
- Rollback scenarios (WhatIf)

**Cross-Profile Compatibility (10 tests)**
- Basis → Recommended → Strict progression
- Client vs Server differences

### 7.3 Mock Strategy

- Mock Registry operations (via Pester)
- Mock Service operations
- Mock GPO operations (if applicable)
- Mock Write-Log (Core dependency)

**Estimated Total Tests: 100+ tests**

---

## 8. FEHLERBEHANDLUNG & ROLLBACK

### 8.1 Error Handling Strategy

```powershell
# Each rule application:
try {
    Apply-Rule
    Write-Log -Message "Rule applied: $ruleName" -Level Info
}
catch {
    Write-ErrorLog -Message $_.Exception.Message
    $result.Failed += $ruleName
    if ($FailOnError) { throw }
}
```

### 8.2 Rollback Strategy

- **WhatIf Mode:** Alle Änderungen werden simuliert, nichts angewendet
- **Logging:** Alle Änderungen werden geloggt für manuelles Rollback
- **Restore Points (Optional):** Vor Hardening System Restore Point erstellen

---

## 9. PERFORMANCE OPTIMIERUNGEN

### 9.1 Parallel Execution
- Registry-Rules können parallel angewendet werden
- Service-Rules können parallel angewendet werden
- Firewall-Rules können parallel angewendet werden

### 9.2 Caching
- Profile-Laden nur einmal pro Session
- Rule Validation-Ergebnisse cachen

### 9.3 Skip Options
- `SkipVerification`: Rule Application ohne Verify-Check
- `RuleFilter`: Nur bestimmte Rules anwenden

---

## 10. DOKUMENTATION ANFORDERUNGEN

### 10.1 Code-Dokumentation
- `.SYNOPSIS` für alle public functions
- `.PARAMETER` für jeden Parameter
- `.EXAMPLE` mit realistischen Szenarien

### 10.2 External Dokumentation
- Hardening.md: Detaillierte Profile-Beschreibung
- Usage-Beispiele für CLI
- Integration-Beispiele

### 10.3 Profile-Dokumentation
- Jedes Profile erklärt: Zweck, Rules, Kompatibilität
- Release-Notes bei Regel-Änderungen

---

## 11. SUCCESS CRITERIA

✅ **Funktional:**
- [ ] Alle 3 Profile (Basis, Recommended, Strict) funktionieren
- [ ] Client + Server Support (11, 2019, 2022, 2025)
- [ ] 95%+ Test Coverage erreicht
- [ ] Alle Regeln korrekt angewendet

✅ **Qualität:**
- [ ] PSScriptAnalyzer: 0 Errors, 0 Warnings
- [ ] Code Review: Approved
- [ ] Performance: <5 Minuten für Strict Profile auf Client
- [ ] Documentation: Vollständig

✅ **Compliance:**
- [ ] ADR-003 bis ADR-009 implementiert
- [ ] STRUCTURE.md Rules befolgt
- [ ] CLAUDE.md Best Practices eingehalten

---

## 12. TIMELINE & RESOURCES

| Phase | Tasks | Duration | Owner |
|-------|-------|----------|-------|
| Phase 1 | Core Infrastructure | 5-7 days | AI |
| Phase 2 | Rule Implementation | 10-14 days | AI |
| Phase 3 | Verification & Tests | 7-10 days | AI |
| Phase 4 | Docs & Optimization | 5-7 days | AI |
| **Total** | **All Phases** | **~4 weeks** | |

---

## 13. RISIKEN & MITIGATION

| Risiko | Wahrscheinlichkeit | Impact | Mitigation |
|--------|-------------------|--------|-----------|
| Registry-Fehler macht System instabil | Mittel | Hoch | Umfangreiche Tests, WhatIf Mode |
| OS-Kompatibilitäts-Probleme | Mittel | Hoch | Early testing auf allen OS Versionen |
| Performance-Probleme bei vielen Rules | Niedrig | Mittel | Parallel execution, Profiling |
| User Rollback schwierig | Niedrig | Mittel | Gutes Logging, Restore Points |

---

## 14. NEXT STEPS

1. ✅ **Plan Review** (Dieses Dokument)
2. 🚀 **Phase 1 Start:** Core Infrastructure
   - New-HardeningSession Implementierung
   - Get-HardeningProfile Implementierung
   - Profile-Dateien Erstellung
3. 📝 **Tests für Phase 1**
4. 📊 **Status Update**

---

**Ende des Plans**  
**Ready for Implementation:** JA ✅
