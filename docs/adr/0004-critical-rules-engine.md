# ADR-0004 — Local do motor de regras críticas no MVP

## Status

Aceito.

## Contexto

`BACKEND_RULES.md` define operações críticas (`complete_assessment`,
`finalize_workout_session`, `claim_reward`) que precisam ser transacionais,
idempotentes e ter lock/constraint por sessão. `TECHNICAL_ARCHITECTURE.md`
lista tanto Edge Functions quanto Postgres como opções, pedindo um ADR
explícito.

## Decisão

Implementar as operações críticas como **funções Postgres (RPC)**,
chamadas via `supabase.rpc(...)` a partir do cliente, em vez de Edge
Functions, para o MVP.

## Justificativa

- a transação inteira (validar idempotência, gravar evidência, atualizar
  ledger, criar recibo) ocorre no mesmo banco, sem round-trip adicional
  nem necessidade de coordenar transação distribuída;
- `rule_versions` e RLS já vivem no Postgres; manter a lógica no mesmo lugar
  simplifica auditoria (`audit_events`) e testes de integração via SQL;
- Edge Functions ficam reservadas para integrações externas (ex. FCM) que
  não exigem transação com o banco.

## Consequências

- cada operação crítica é uma migration versionada (`supabase/migrations`),
  revisável em PR como qualquer outro código;
- se uma regra futura precisar de lógica difícil de expressar em SQL/plpgsql,
  reavaliar Edge Function apenas para esse caso, mantendo a escrita final
  ainda transacional no Postgres.
