# ADR-0005 — Formato da fila offline

## Status

Aceito.

## Contexto

`NFR-005`, `TECHNICAL_ARCHITECTURE.md` §5 e `DATA_MODEL.md` exigem que a
sessão funcione offline e sincronize sem duplicar recompensas.

## Decisão

Fila local em Drift (tabela `OutboxEvents`, ver
`lib/core/database/tables/outbox_events.dart`) com:

- `event_id` (uuid) como chave de idempotência, gerado no cliente;
- `client_session_id` para agrupar eventos de uma mesma sessão;
- `status` (`pending|sent|failed`) e `attempt_count`/`last_attempt_at` para
  backoff;
- `payload_json` com o fato ocorrido (ex.: série registrada, sessão
  concluída) — não com "XP ganho", que é calculado só no backend.

## Justificativa

- espelha o par cliente/servidor descrito em `ECONOMY_AND_ANTI_ABUSE.md` §2
  (`client_session_id` + `event_id` por evento);
- permite reconciliar múltiplos dispositivos sem perder eventos (RF-024,
  DATA_MODEL `sync_receipts`).

## Consequências

- o worker de sincronização (ainda não implementado — próxima história de
  sessão offline) envia eventos em ordem e trata 200/409/timeout sem
  duplicar;
- a primeira história vertical (colocação conservadora) não usa a fila,
  pois é uma operação síncrona única — a tabela já existe para preparar a
  história seguinte.
