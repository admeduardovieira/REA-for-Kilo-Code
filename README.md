# REA for Kilo Code

Reverse Engineering & Autonomous Auditing Framework for Kilo Code.

## Overview
An open-source auditing framework that extends Kilo Code with persistent memory, semantic code analysis, vulnerability detection, systematic debugging, and reproducible technical evidence. Orchestrates REA 6.7.0 and complementary tools via Git submodules and MCP.

## Quick Start

### 1. Clone with submodules
```bash
git clone https://github.com/admeduardovieira/REA-for-Kilo-Code.git
cd REA-for-Kilo-Code
git submodule update --init --recursive
```

### 2. Use in Kilo Code
- Open the repository in Kilo Code
- Use agent `rea-auditor` or skill `/rea-audit`
- Follow the 7-step flow with evidence-first approach

### 3. Run audit script (Windows)
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\rea-audit.ps1 -RepoPath "C:\path\to\repo"
```

## Structure
- `rea-core/` - REA 6.7.0 core
- `skills/` - Kilo Skills + Superpowers
- `memory/` - Engram
- `code-analysis/` - ast-grep + Serena
- `documentation/` - Context7
- `security/` - Gitleaks + OSV-Scanner
- `ci-analysis/` - actionlint
- `marketplace/` - Kilo Marketplace
- `integrations/` - MCP configurations
- `tests/` - Integration tests
- `.kilo/` - Agents and Skills

## Principles
- Evidence first - reproduce before fixing
- Orchestration, not fusion
- Minimal changes with authorization
- Read-only by default
- License-aware

## License
See LICENSE and THIRD_PARTY_NOTICES.md for details.
