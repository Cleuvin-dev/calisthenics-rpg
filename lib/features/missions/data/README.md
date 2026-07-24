# Missions — data

Sem tabela própria: lê fatos de `workout_session`, `training_plan` e
`assessment`, grava crédito em `xp_ledger_records` (via
`XpLedgerRepository`) com `idempotencyKey` por missão+dia/semana.
`evaluateDaily`/`evaluateWeekly` são leitura pura (reativa);
`grantCompletedDaily`/`grantCompletedWeekly` é a ação explícita que
credita XP, chamada ao abrir a tela Jornada.

Referência: `06_GAMIFICATION/RPG_SYSTEM.md` §8.
