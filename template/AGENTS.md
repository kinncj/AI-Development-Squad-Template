# AGENTS.md — Multi-Agent Squad Roster

## Quick Reference

| # | Agent | Role | Model |
|---|---|---|---|
| 1 | orchestrator | Pipeline control (never codes) | opus |
| 2 | product-owner | User stories, acceptance criteria | sonnet |
| 3 | architect | ADR, contracts, threat models | opus |
| 4 | qa | Write tests (RED) + validate (GREEN) | sonnet |
| 5 | dotnet | .NET backend implementation | sonnet |
| 6 | javascript | Node.js / vanilla JS | sonnet |
| 7 | typescript | TypeScript backend/libraries | sonnet |
| 8 | react-vite | React + Vite + TypeScript SPA | sonnet |
| 9 | nextjs | Next.js full-stack | sonnet |
| 10 | java | Java backend (non-Spring) | sonnet |
| 11 | springboot | Spring Boot applications | sonnet |
| 12 | kubernetes | K8s manifests, Kustomize, Helm | gpt-4.1 |
| 13 | terraform | Terraform IaC | gpt-4.1 |
| 14 | docker | Dockerfiles, Compose | gpt-4.1 |
| 15 | postgresql | Schema, migrations, RLS | sonnet |
| 16 | redis | Caching, pub/sub, streams | sonnet |
| 17 | supabase | Auth, RLS, Edge Functions | sonnet |
| 18 | vercel | Deployment, edge, config | sonnet |
| 19 | stripe | Payments, webhooks, billing | sonnet |
| 20 | data-science | EDA, stats, visualization | sonnet |
| 21 | data-engineer | Pipelines, ETL, orchestration | sonnet |
| 22 | tensorflow | TF/Keras models, training | sonnet |
| 23 | pytorch | PyTorch models, training | sonnet |
| 24 | pandas-numpy | Data manipulation, arrays | sonnet |
| 25 | scikit | Classical ML, pipelines | sonnet |
| 26 | jupyter | Notebooks, papermill | sonnet |
| 27 | docs | Feature docs, CHANGELOG, Mermaid | sonnet |

## Pipeline Phases
1. DISCOVER → 2. ARCHITECT → 3. PLAN → 4. INFRA → 5. IMPLEMENT → 6. VALIDATE → 7. DOCUMENT → 8. FINAL GATE

## Makefile Contract
All agents use: `make build`, `make test`, `make test-integration`, `make test-e2e`,
`make test-contract`, `make test-all`, `make lint`, `make security-scan`, `make fmt`,
`make containers-up`, `make containers-down`, `make seed-test`, `make migrate`.

## Git Conventions
- Conventional Commits: `feat:`, `fix:`, `test:`, `docs:`, `infra:`, `refactor:`
- Branch naming: `feat/{slug}`, `fix/{slug}`
- Squash merge to main
