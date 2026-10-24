---
name: rea-audit
description: Conduct evidence-based reverse engineering, technical auditing, regression testing, and security analysis.
---

# REA Audit Skill

Run systematic technical audit using REA methodology.

## Usage
`/rea-audit <repo-path>`

## Steps
1. Reconnaissance
2. Static analysis (ast-grep/serena if available)
3. Security scan (gitleaks/osv-scanner if available)
4. CI analysis (actionlint if available)
5. Reproduce findings
6. Report with evidence

## Requirements
- Follow AGENTS.md rules
- Evidence required for confirmed findings
- Ask authorization before fixes

