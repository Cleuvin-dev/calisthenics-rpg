# Training plan — data

Fase atual (local-only, ver `docs/adr/0006-mvp-local-only.md`): plano gerado
pelo motor de treino gravado em tabela Drift local (`training_plan_records`),
com sessões/itens serializados em JSON. Quando o backend voltar, migra para
`training_plans`/`plan_sessions`/`planned_exercises` relacionais no Supabase.

Referência: `08_ARCHITECTURE/DATA_MODEL.md`.
