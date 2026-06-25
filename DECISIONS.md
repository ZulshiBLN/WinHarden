# WinOpsKit – Architectural Decision Records (ADRs)

Zentrale Dokumentation für Architektur-Entscheidungen, die das Projekt massgeblich beeinflussen.

**Alle ADRs:** ADR-001 bis ADR-009 ([OK] ACCEPTED)  
**Konkrete Implementierungs-Regeln:** Siehe [STRUCTURE.md](STRUCTURE.md) (Regeln 1.1-12.8)

---

## Entscheidungen

### ADR-001: Modulare PowerShell-Architektur mit Funktionen & Scripts

**Status:** [OK] ACCEPTED

**Context:**
WinOpsKit benötigt eine klare Struktur für Wiederverwendbarkeit, Testbarkeit und Wartbarkeit. PowerShell-Code sollte nicht monolithisch sein.

**Decision:**
Modulare PowerShell-Architektur mit klarer Trennung von Funktionen, Scripts und Tests. 
Siehe **[STRUCTURE.md](STRUCTURE.md)** für konkrete Implementierungs-Regeln (Regel 1.1-5.1).

**Consequences:**
- (+) Hohe Wiederverwendbarkeit durch klare Trennung
- (+) Testbarkeit jeder Funktion isoliert
- (+) Performance-Fokus von Anfang an
- (-) Mehr Initial-Struktur erforderlich
- (-) FUNCTION-STATUS.md muss manuell gepflegt werden

**Alternatives:**
- Monolithische Script-Struktur (schneller zu schreiben, aber schwer zu warten)
- Alles in einen großen `functions.ps1` (unübersichtlich ab Größe)

---

### ADR-002: PowerShell-Version & Compatibility

**Status:** [OK] ACCEPTED

**Context:**
Windows Server-Umgebungen haben gemischte PowerShell-Versionen:
- Ältere Server (2016, frühe 2019) haben nur PowerShell 5.1
- Neuere Server (2022+) haben PowerShell 7.x optional verfügbar
- WinOpsKit soll in beiden Umgebungen funktionieren

**Decision:**
- **Minimum-Version:** PowerShell 5.1 (funktioniert überall)
- **Dual-Support:** Code muss auf 5.1 UND 7.x laufen
- **Runtime-Checks:** Moderne 7.x-Features per `$PSVersionTable.PSVersion.Major -ge 7` abfragen
- **Moderne Cmdlets:** Verwende nicht-deprecated Varianten (z.B. `Get-Process` statt `ps`, `Get-Item` statt `dir`)
- **Windows-only:** Kein cross-plattform-Support nötig (keine UNIX-Pfade, etc.)
- **Keine Breaking Changes:** 5.1-kompatible Syntax default, 7.x-Features optional

**Consequences:**
- (+) Funktioniert in 100% der Windows Server-Umgebungen
- (+) Moderne Features können schrittweise genutzt werden
- (+) Kein Druck auf Server-Updates
- (-) Testing auf beiden Versionen erforderlich
- (-) Manche Conditional-Patterns notwendig für 7.x Features
- (-) Keine modernen PowerShell-7-only Syntaxen (z.B. Native Operators)

**Alternatives:**
- Nur PowerShell 5.1 (nicht zukunftssicher, Features fehlen)
- Nur PowerShell 7.x (funktioniert nicht auf älteren Servern)
- Cross-plattform PowerShell (nicht nötig, Windows-only ist Ziel)

**Implementation Notes:**
- Tests müssen auf mindestens 5.1 laufen
- Moderne Cmdlets: Bevorzuge `Get-*` Pattern über Aliase
- 7.x-Features: Nutze innerhalb von `if ($PSVersionTable.PSVersion.Major -ge 7) { ... }`
- Deprecated Functions dokumentieren mit `# PSv5.1: Use X instead of Y`

---

### ADR-003: Testing Framework (Pester 5.x)

**Status:** [OK] ACCEPTED

**Context:**
Automatisierte Tests sind kritisch für Qualitätsicherung und Regression-Verhinderung. Pester ist das Standard-Testing-Framework für PowerShell und sollte für alle Funktionen genutzt werden.

**Decision:**

**Pester-Version:**
- **Pester 5.x** (modern, aktuell gewartet, bessere Features)
- Mindestanforderung: Pester 5.0+

**Test-Struktur:**
- Tests in `tests/` Verzeichnis (parallel zu `functions/`)
- Test-Datei-Name: `<FunctionName>.Tests.ps1` (z.B. `Get-SystemInfo.Tests.ps1`)
- Jede Produktivfunktion MUSS eine entsprechende Test-Funktion haben
- Tests in eigenen `.Tests.ps1` Dateien organisieren

**Test-Mocking:**
- Nutzen von **Pester `Mock`** für externe Dependencies (APIs, Dateisystem, Registry, etc.)
- `InModuleScope` nur wenn nötig (private Funktionen testen)
- Mock mit `-ParameterFilter` für präzise Kontrolle

**Code Coverage:**
- **Minimum 95%** Code Coverage für alle Funktionen
- Coverage-Report via `Invoke-Pester -CodeCoverage`
- Ausnahmen nur mit explizitem Kommentar (z.B. `# Code Coverage Exception: Cannot mock registry access`)

**Test-Runner:**
- **Lokal PowerShell** (via `Invoke-Pester` im `build.ps1`)
- Keine CI/CD Pipeline zwingend (aber möglich)
- Test-Run vor jedem Commit (über Git Hook oder manual)

**Assertion Style:**
- Nutze **Standard Pester Assertions** (am weitesten verbreitet):
  - `Should -Be` (Gleichheit)
  - `Should -Throw` (Exception werfen)
  - `Should -Exist` (Datei/Verzeichnis existiert)
  - `Should -Match` (Regex-Matching)
  - `Should -BeTrue`, `Should -BeFalse` (Boolean)
  - `Should -Contain` (Array-Membership)
  - `Should -BeNullOrEmpty`, `Should -Not.BeNullOrEmpty`
  - Custom Assertions via Assertion Scopes erlaubt

**Test-Data:**
- **Fixtures:** Externe Test-Daten-Dateien unter `tests/fixtures/`
- Format: JSON, CSV, oder PowerShell-Objekte (je nach Usecase)
- Beispiel: `tests/fixtures/TestServers.json` mit Mock-Server-Daten
- Setup & Teardown via `BeforeEach` / `AfterEach` Blocks

**Test-Konventionen:**
- **Describe Block:** Funktion testen (z.B. `Describe "Get-SystemInfo"`)
- **Context Block:** Spezifischer Use-Case (z.B. `Context "When server is online"`)
- **It Block:** Einzelner Test (z.B. `It "returns system info"`)
- Aussagekräftige Test-Namen (nicht nur `Test 1`, `Test 2`)

**Consequences:**
- (+) 95% Coverage findet die meisten Bugs
- (+) Pester 5.x ist modern und aktiv gepflegt
- (+) Mocking isoliert Tests (schnell, zuverlässig)
- (+) Fixtures ermöglichen realistische Test-Daten
- (-) 95% Coverage ist streng (kann zeitaufwendig sein)
- (-) Mocking kann zu False-Positives führen (echte externe Fehler nicht fangen)
- (-) Fixture-Management muss gepflegt werden

**Alternatives:**
- Keine Tests (unakzeptabel)
- Integration Tests statt Unit Tests (langsam, instabil)
- Lower Coverage 80% (zu viele Bugs durchgehen)
- Pester 4.x (legacy, weniger Features)

**Implementation Notes:**
See **[STRUCTURE.md Regel 4.1-4.8](STRUCTURE.md#4-testing-pester-5x)** for complete testing rules and examples.

---

### ADR-004: Error Handling Convention

**Status:** [OK] ACCEPTED

**Context:**
Konsistente Fehlerbehandlung ist kritisch für robuste PowerShell-Scripts. PowerShell hat verschiedene Error-Handling-Mechanismen (Try-Catch, ErrorActionPreference, Write-Error, Throw), die konsistent genutzt werden müssen.

**Decision:**

**Try-Catch Nutzung:**
- Nur wo **nötig** verwenden, nicht standardmäßig um alle Code wrappen
- Nutzen für externe Ressourcen (Datei-Zugriff, Netzwerk, Registry) oder bekannte Fehlerquellen
- Nicht für interne Code-Logik verwenden

**Fehlerbehandlung-Strategie:**
- **Terminating Errors:** `throw` Exception (stoppt Ausführung sofort)
- **Non-Terminating Errors:** `Write-Error` (gibt Error aus, setzt `$?` zu `$false`, aber setzt ErrorActionPreference)
- **ErrorActionPreference:** Default `Stop` (behandelt Fehler als terminating)

**Automatisches Logging:**
- Alle Errors werden **automatisch geloggt** (siehe ADR-005 für Logging-Implementation)
- Try-Catch sollte Fehler fangen, loggen, und neu-werfen oder Write-Error aufrufen
- Keine doppelten Logs (Logging-Funktion ist zentral)

**Exit-Codes (für Scripts, nicht Funktionen):**
- `0` = Erfolgreich
- `1` = General Error (unerwarteter Fehler)
- `2` = Cmdlet Error (PowerShell Fehler)
- `3+` = Custom Exit Codes (projekt-spezifisch)

**WhatIf & Confirm:**
- Fehlerbehandlung läuft **gleich** wie bei normalem Run
- `-WhatIf` ändert Fehler-Handling nicht
- Errors werden auch bei WhatIf geworfen/geloggt

**Parameter Validation:**
- Nutze **PowerShell Validation Attributes** (nicht manuelle Checks):
  - `[ValidateNotNullOrEmpty()]`
  - `[ValidateSet(...)]`
  - `[ValidateRange(...)]`
  - `[ValidateScript({...})]`
  - `[ValidatePath]`
- Diese werfen automatisch Errors bei ungültigen Inputs

**Consequences:**
- (+) Fehler stoppen Ausführung sofort (kein stummes Fehlschlag)
- (+) Zentrale Fehler-Handling & Logging reduziert Redundanz
- (+) ValidationAttributes sind lesbar und wartbar
- (+) Exit-Codes ermöglichen Scripting in Batch/Automation
- (-) `ErrorActionPreference Stop` ist streng (könnte manchmal zu restriktiv sein)
- (-) Braucht zentrale Logging-Funktion (ADR-005)
- (-) Try-Catch wird oft nicht gebraucht (könnte Code-Komplexität senken)

**Alternatives:**
- `ErrorActionPreference Continue` (weniger restriktiv, aber Fehler können ignoriert werden)
- Alle Errors als Write-Error (nicht streng genug)
- Jede Funktion mit eigenem Try-Catch (redundant, schwer zu maintainen)

**Implementation Notes:**
See **[STRUCTURE.md Regel 9.1-9.8](STRUCTURE.md#9-error-handling)** for complete error handling rules and examples.

---

### ADR-005: Logging Strategy

**Status:** [OK] ACCEPTED

**Context:**
Logging ist kritisch für Troubleshooting und Compliance. PowerShell-Scripts brauchen eine zentrale, konsistente Logging-Strategie, die Fehler und Operationen protokolliert, ohne sensitive Daten zu exponieren.

**Decision:**

**Logging-Ziele:**
- Datei-basiert: `$PSScriptRoot\logs\`
- Format: CSV (strukturiert, leicht zu analysieren)
- Datei-Name: `log_YYYY-MM-DD.csv` (tägliche Rotation)

**Log-Levels (in dieser Hierarchie):**
1. **Error** - Kritische Fehler (immer loggen)
2. **Warning** - Potenzielle Probleme (meist loggen)
3. **Info** - Standard-Operationen (loggen wenn NICHT `-Verbose`)
4. **Debug** - Detaillierte Debug-Info (loggen nur bei `-Debug`)
5. **Verbose** - Sehr detailliert (loggen nur bei `-Verbose`)

**Zentrale Logging-Funktion: `Write-Log`**
- Parameter: `-Message`, `-Level`, `-Caller` (optional)
- CSV-Spalten:
  ```
  Timestamp, Level, Caller, Function, LineNumber, Message
  2026-06-25 14:23:45.123, ERROR, Get-ServerStatus:42, Get-ServerStatus, 42, "Failed to connect to server: ***"
  ```

**Sensitive Data Masking:**
- Automatisches Maskieren bekannter sensitive Parameter:
  - `*password*`, `*token*`, `*secret*`, `*apikey*`, `*credential*`
  - Ersetzung: `***` (3 Sternchen)
- Auch Parameter-Werte maskieren wenn Name sensitive ist
- Beispiel: `"Password: ***"` statt `"Password: SecureP@ssw0rd"`

**Caller Info:**
- Funktions-Name (aus CallStack)
- Zeilen-Nummer (aus CallStack)
- Optional: Parameter (maskiert)

**Log-Rotation & Retention:**
- **Daily Files:** Ein CSV-Datei pro Tag (`log_2026-06-25.csv`)
- **Retention:** Automatisch löschen nach **7 Tagen**
- **Cleanup:** Läuft beim `Write-Log` erste Aufruf pro Tag

**LogLevel-Kontrolle:**
- Über `$env:LOG_LEVEL` (z.B. `$env:LOG_LEVEL = 'Debug'`)
- Default: `Info` (keine Debug/Verbose ohne Umgebungsvariable)
- Cmdlet-Parameter `-Verbose` und `-Debug` steuern auch LogLevel

**Consequences:**
- (+) Zentrale, strukturierte Logging-Strategie
- (+) CSV leicht zu analysieren und zu parsen
- (+) Sensitive Daten automatisch maskiert (compliance)
- (+) Caller Info hilft bei Troubleshooting
- (+) Tägliche Rotation reduziert Datei-Größe
- (-) CSV-Header muss konsistent sein
- (-) 7-Tage-Retention könnte zu Datenverlust führen (bei Audits beachten)
- (-) Maskieren kann legitime Daten verstecken (Fehler-Kontexte)

**Alternatives:**
- JSON-Logging (komplexer, aber besser strukturiert)
- Event Viewer (Windows-spezifisch, schwerer zu parsen)
- keine Logging (unmöglich zu debuggen)
- Plaintext (unklar, schwer zu parsen)

**Implementation Notes:**
See **[STRUCTURE.md Regel 10.1-10.8](STRUCTURE.md#10-logging-strategy)** for complete logging rules and examples.

---

### ADR-006: Code Style & PSScriptAnalyzer Rules

**Status:** [OK] ACCEPTED

**Context:**
Konsistente Code-Formatierung ist wichtig für Lesbarkeit und Wartbarkeit. PSScriptAnalyzer ist das Standard-Linting-Tool für PowerShell und sollte in den Build-Prozess integriert sein.

**Decision:**
- **PSScriptAnalyzer Ruleset:** Vordefiniertes Ruleset (PSGallery Standard)
- **Linting vor Commit:** Build-Check mit PSScriptAnalyzer (muss BESTEHEN vor jedem Commit)
- **Indentation:** 4 Spaces (nicht Tabs)
- **Line Length:** Optimiert auf Lesbarkeit (keine strikte Limit, aber ca. 120 Zeichen anstreben)
- **Bracing Style:** K&R Style – `{` auf gleicher Zeile (z.B. `if ($x) {`)
- **Format-Exceptions:** Erlaubt wenn für Lesbarkeit notwendig (mit `# PSScriptAnalyzer ignore [rule]` Kommentar)

**Consequences:**
- (+) Konsistente Code-Formatierung across Team/Sessions
- (+) Automatische Qualitäts-Checks vor Commits
- (+) PSScriptAnalyzer findet viele Common Pitfalls
- (-) Build-Check könnte lokal fehlschlagen (muss lokal PSScriptAnalyzer haben)
- (-) Strikte Regeln können manchmal Lesbarkeit beeinträchtigen (daher Exceptions erlaubt)

**Alternatives:**
- Manuelle Code Reviews statt Linting (zeitaufwendig, inkonsistent)
- Keine Formatierungs-Standards (Code-Zoo, schwer zu lesen)
- Custom PSScriptAnalyzer Rules (zu komplex für diesen Stage)

**Implementation Notes:**
- See **[STRUCTURE.md Regel 7.1-7.7](STRUCTURE.md#7-code-style--linting)** for complete code-style rules (K&R bracing, 4-space indentation, line length, exceptions)
- `build.ps1` runs PSScriptAnalyzer before tests
- `.editorconfig` and `PSScriptAnalyzerSettings.psd1` provide IDE/Linting config

---

### ADR-007: Naming Conventions (Funktionen, Parameter, Variablen)

**Status:** [OK] ACCEPTED

**Context:**
Konsistente Naming-Konventionen sind kritisch für Lesbarkeit und Verständlichkeit. PowerShell hat Conventions, die befolgt werden sollten, mit einigen Projekt-spezifischen Ergänzungen.

**Decision:**

**Funktions-Namen:**
- **Approved Verbs:** Nur PowerShell-Approved Verbs verwenden (Get, Set, Test, New, Remove, Add, Clear, etc.)
- **Format:** `Verb-Noun` (z.B. `Get-SystemInfo`, `Test-ServiceHealth`)
- **Private Funktionen:** Prefix `_` (z.B. `_GetSystemDetails`)

**Parameter-Namen:**
- **Singular/Plural:** Singular wenn Parameter **einen** Wert nimmt, Plural wenn **mehrere** (z.B. `$Server` vs. `$Servers`)
- **Format:** PascalCase (z.B. `$ComputerName`, `$ProcessList`)

**Variablen-Namen:**
- **Format:** camelCase (z.B. `$systemInfo`, `$isHealthy`, `$errorCount`)
- **Prefix für Typen:** Optional aber konsistent (z.B. `$strName`, `$intCount`)

**Boolean-Funktionen:**
- **Präfix:** `Is` (z.B. `Is-SystemHealthy`, `Is-ServiceRunning`)

**Datei-Namen:**
- **Match Funktions-Name:** Dateiname == Funktions-Name (z.B. `Get-SystemInfo.ps1`)
- **Private Funktionen:** `_PrivateFunction.ps1`

**Consequences:**
- (+) Sofort erkennbar: Funktion vs. Variable vs. Parameter
- (+) PowerShell-Standard + Projekt-Konventionen konsistent
- (+) PSScriptAnalyzer validiert Approved Verbs automatisch
- (-) Mehr Regeln zu merken
- (-) Umbenennungen nötig wenn vorhandene Code nicht komform

**Alternatives:**
- Keine Konventionen (völliges Chaos)
- Nur PowerShell-Standards ohne Projekt-Ergänzungen (weniger Klarheit)
- SCREAMING_SNAKE_CASE überall (nicht PowerShell-Standard)

**Implementation Notes:**
See **[STRUCTURE.md Regel 8.1-8.8](STRUCTURE.md#8-naming-conventions)** for complete naming conventions and examples.

---

### ADR-008: Modul-Import-Strategie

**Status:** [OK] ACCEPTED

**Context:**
WinOpsKit hat mehrere Funktions-Module (System, User, Maintenance, etc.). Die Import-Strategie muss klären:
1. Wie werden Module organisiert (1x .psm1 oder separate)?
2. Wie werden Dependencies gelöst (alle funktionieren)?
3. Wie wird Script-Initialisierung sauber (nur nötige Funktionen)?

**Decision:**

**Modul-Struktur:**
- **Getrennte Module** (nicht alles in 1 .psm1):
  - `Core.psm1` – Zentrale Basis-Funktionen (IMMER laden)
  - `System.psm1` – System-Admin Funktionen (optional)
  - `User.psm1` – User/Group Management (optional)
  - `Maintenance.psm1` – Updates, Cleanup, Monitoring (optional)

**Core-Modul Inhalte (IMMER verfügbar):**
- `Write-Log` – Zentrale Logging-Funktion
- `Write-Error` Wrapper – Error-Handling Basis
- `Test-* Validatoren` – Parameter-Validation Helpers
- `ConvertTo-MaskedString` – Sensitive Data Masking
- `Get-ModuleVersion` – Version Info

**Script-Initialisierung:**
```powershell
# Minimum Setup (alle Scripts)
. "$PSScriptRoot/modules/Core.psm1"  # IMMER laden

# Optional: Zusätzliche Module
. "$PSScriptRoot/modules/System.psm1"   # Nur wenn System-Funktionen nötig
. "$PSScriptRoot/modules/User.psm1"     # Nur wenn User-Funktionen nötig
```

**Dependency Resolution:**
- Core-Modul als **Basis für alles** (alle anderen nutzen Write-Log)
- Andere Module können aufeinander aufbauen (System ruft User-Funktionen auf)
- Reihenfolge beim Import beachten:
  1. Core.psm1 (obligatorisch)
  2. System.psm1
  3. User.psm1
  4. Maintenance.psm1

**Load-Performance:**
- **On-Startup:** Nur Core laden (schnell)
- **Dann:** Zusätzliche Module bei Bedarf laden
- Nicht lazy-load einzelne Funktionen (zu komplex)
- Jedes Modul lädt komplett oder gar nicht

**Global Scope:**
- Alle Funktionen landen im **Global Scope** (nach Import)
- Kein `$script:` private Scope (würde Dependencies komplizieren)
- Private Helper-Funktionen: Prefix `_` (z.B. `_ValidateServerName`)

**Consequences:**
- (+) Einfache, klare Struktur
- (+) Core ist immer verfügbar (keine Überraschungen)
- (+) Saubere Abhängigkeitsauflösung
- (+) Auf-Startup schnell (Core ist klein)
- (+) Scripts sind einfach zu schreiben (funktionen verfügbar)
- (-) Core muss stabil sein (alle hängen dran)
- (-) Global Scope könnte zu Naming-Konflikten führen (Regel 8: Naming verhindert das)

**Alternatives:**
- Alles in 1 .psm1 (monolithisch, schwer zu warten)
- Lazy-load Funktionen on-demand (komplex, schwer zu debuggen)
- Keine Module, nur dot-sourcing (unstrukturiert)
- Private Scopes für alle (Abhängigkeiten unmöglich)

**Implementation Notes:**
See **[STRUCTURE.md Regel 11.1-11.8](STRUCTURE.md#11-modul-import-strategie)** for complete module import rules and examples.

---

### ADR-009: Dependency Management zwischen Funktionen

**Status:** [OK] ACCEPTED

**Context:**
Mit mehreren Modulen (Core, System, User, Maintenance) müssen Abhängigkeiten zwischen Funktionen gemanagt werden. Ziele:
1. Zirkuläre Abhängigkeiten verhindern
2. Klare Dependency-Hierarchie etablieren
3. External Dependencies optional halten
4. Version-Kompatibilität sichern (PowerShell 5.1+)

**Decision:**

**Circular Dependencies Prevention:**
- **Linear Dependency Hierarchy:**
  ```
  Core (keine Dependencies)
    ↓
  System (darf Core nutzen)
    ↓
  User (darf Core + System nutzen)
    ↓
  Maintenance (darf Core + System + User nutzen)
  ```
- **Regel:** Modul N darf nur Modul M aufrufen wenn M < N in Hierarchie
- **Keine Rückwärts-Abhängigkeiten:** System darf NOT User aufrufen, User darf NOT Maintenance aufrufen

**Inter-Module Dependencies:**
- **Explizit dokumentieren** (Kommentar oben in Funktion):
  ```powershell
  # DEPENDS ON: Write-Log (Core), Test-NotNullOrEmpty (Core)
  # OPTIONAL: Get-UserInfo (User.psm1)
  ```
- **Test-Mocking** für alle Inter-Modul-Aufrufe (siehe ADR-003)
- Kein direct `.psm1` Import nötig (alles lädt beim Script-Start, ADR-008)

**External Dependencies (PowerShell-Module, APIs, etc.):**
- **Deklarieren optional:**
  ```powershell
  # REQUIRES (optional): ActiveDirectory Module 2.0+
  # REQUIRES (optional): Az.Storage Module 4.0+
  ```
- **Graceful Degradation:** Wenn externe Module fehlen, loggen + Error + return gracefully
- **Nicht hard-require:** WinOpsKit funktioniert ohne externe Modules (nur mit Einschränkungen)
- Nutzen von `Test-WinOpsKitDependencies` Helper (optional)

**Version Constraints:**
- **Minimum PowerShell:** 5.1 (alle Funktionen, siehe ADR-002)
- **Keine Version-Pinning:** Zu restriktiv
- **Modern Features nutzen mit Checks:** `if ($PSVersionTable.PSVersion.Major -ge 7) { ... }`
- **Breaking Changes:** Neue ADR schreiben wenn Major-Version inkompatibel

**Dependency Validation (Helper-Funktion in Core):**
- Optional, nicht blocking (graceful)
- Script kann selbst entscheiden: fail hard oder continue

**Consequences:**
- (+) Keine zirkulären Dependencies (saubere Architektur)
- (+) Klare Hierarchie (einfach zu verstehen)
- (+) External Modules optional (höhere Kompatibilität)
- (+) PowerShell 5.1+ überall (breite Unterstützung)
- (+) Test-Mocking verhindert aktuell-Abhängigkeiten (ADR-003)
- (-) Linear Hierarchy ist streng (könnte manchmal zu viel sein)
- (-) Graceful Degradation kann Error-Handling komplizieren
- (-) Dokumentation (DEPENDS ON) muss manuell gepflegt werden

**Alternatives:**
- Keine Hierarchie (Chaos)
- Automatische Dependency Resolution (zu komplex)
- Hard-require alle Modules (zu restriktiv)
- Keine External-Module Support (Limited)

**Implementation Notes:**
See **[STRUCTURE.md Regel 12.1-12.8](STRUCTURE.md#12-dependency-management)** for complete dependency management rules and examples.
