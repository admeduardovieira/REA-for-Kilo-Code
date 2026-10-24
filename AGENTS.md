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

## Validação Pré-Push (OBRIGATÓRIA)

Antes de git add, git commit ou git push em qualquer diretório *_fixed/:

- [ ] **Integridade do fork:** Comparar com o repositório original. Se o fork tiver uma quantidade drasticamente menor de arquivos (ex: só ndroid/), **NÃO** commitar. Reconstruir a partir de cópia íntegra.
- [ ] **Contagem de arquivos:** Rodar git ls-files | wc -l no fork e comparar com a cópia original em 	mp-audit/. Diferenças massivas exigem investigação.
- [ ] **Escopo do diff:** Rodar git diff --name-only e confirmar que **somente** os arquivos autorizados foram alterados.
- [ ] **Tamanho do diff:** Rodar git diff --stat. Se houver milhares de deleções/adições sem justificativa explícita, **PARAR** e investigar.
- [ ] **Validação de sintaxe:** Para arquivos .js alterados, rodar 
ode --check. Para arquivos .json, validar com 
ode -e "require('./arquivo.json')". Para AndroidManifest.xml, validar estrutura básica.
- [ ] **Escapamento no PowerShell:** **NUNCA** usar aspas duplas escapadas incorretamente. Preferir aspas simples em arquivos JS, ou usar Set-Content -Value com conteúdo literal testado. Sempre validar com 
ode --check após criar/modificar arquivos JS via PowerShell.
- [ ] **Remoto correto:** Verificar git remote -v antes do push. Garantir que o remoto origin aponta para o fork correto (dmeduardovieira/*).
- [ ] **Validação pós-commit:** Revisar o diff remoto no fork antes de abrir/atular PR.
