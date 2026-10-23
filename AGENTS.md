# REA for Kilo Code - Agents Rules

## Objective
REA for Kilo Code is a Reverse Engineering & Autonomous Auditing Framework designed to extend Kilo Code with systematic, evidence-based technical auditing.

## Core Principles
- Evidence first: No suspicion is presented as a confirmed bug without reproduction/evidence.
- Orchestration, not fusion: Integrate tools via submodules/MCP, don't duplicate them.
- Minimal change: Preserve unrequested code, fix only approved scope.
- Reproducible: Every finding must have evidence, steps, and validation.
- License aware: Respect original licenses and credits.

## Global Audit Flow
1. Recognition
2. Reverse Engineering
3. Audit
4. Validation
5. Correction
6. Memory (Engram)
7. Delivery

## Constraints
- Do not modify files outside approved scope.
- Do not create commits/PRs without explicit authorization.
- Do not alter branch names without testing.
- Use tools only if installed/accessible; report limitations.
- FHIR/SUSHI rules apply only when relevant.
