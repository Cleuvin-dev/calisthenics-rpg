# Workout session — data

Fase atual (local-only, ver `docs/adr/0006-mvp-local-only.md`): sessão e
séries gravadas em tabelas Drift locais (`workout_session_records`,
`set_log_records`), sem sincronização — a fila `OutboxEvents` segue
reservada para quando houver backend (`core/sync/README.md`). Quando o
backend voltar, migra para `workout_sessions`/`set_logs` no Supabase.

Referência: `08_ARCHITECTURE/DATA_MODEL.md`.
