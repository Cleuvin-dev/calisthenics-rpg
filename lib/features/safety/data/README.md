# Safety — data

Fase atual (local-only, ver `docs/adr/0006-mvp-local-only.md`): triagem
gravada em tabela Drift local, nunca exportada/exibida publicamente. Quando
o backend voltar a ser desenvolvido, migra para `safety_screenings` no
Supabase com RLS por dono.

Referência: `01_SAFETY/SAFETY_AND_SCREENING.md`, `08_ARCHITECTURE/DATA_MODEL.md`.
