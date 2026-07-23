# Assessment — data

Fase atual (local-only, ver `docs/adr/0006-mvp-local-only.md`): a regra de
colocação conservadora roda em Dart puro (feature `assessment/domain`) e o
resultado é gravado em tabela Drift local equivalente a
`capability_estimates`. Quando o backend voltar, a mesma regra migra para
RPC Postgres versionada, conforme `docs/adr/0004-critical-rules-engine.md`.

Referência: `08_ARCHITECTURE/BACKEND_RULES.md`.
