# RPG — data

Fase atual (local-only, ver `docs/adr/0006-mvp-local-only.md`): ledger de
XP em tabela Drift local (`xp_ledger_records`), autoridade fica no
próprio app por enquanto — sem backend para validar/assinar eventos
ainda (ECONOMY_AND_ANTI_ABUSE.md §1 assume backend autoritativo; nesta
fase local-only single-device isso não se aplica, mesma ressalva já
usada para o motor de treino e a triagem). Quando o backend voltar,
migra para `xp_ledger` no Supabase com o cliente enviando apenas fatos,
nunca XP.

Referência: `08_ARCHITECTURE/DATA_MODEL.md`, `06_GAMIFICATION/ECONOMY_AND_ANTI_ABUSE.md`.
