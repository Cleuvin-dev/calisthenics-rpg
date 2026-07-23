# ADR-0002 — Banco de dados local

## Status

Aceito.

## Contexto

`NFR-005` exige registro local da sessão sem depender de conexão.
`TECHNICAL_ARCHITECTURE.md` já indica "SQLite/Drift ou equivalente" como
opção preferencial.

## Decisão

Usar **Drift** sobre SQLite (`sqlite3_flutter_libs` como engine nativa).

## Justificativa

- queries tipadas e migrations locais versionadas em código Dart;
- suporta transações, necessárias para persistir séries + status de sessão
  de forma consistente antes da sincronização;
- boa integração com Riverpod para observar mudanças reativas (ex.: tamanho
  da fila offline).

## Consequências

- schema local inicial (`lib/core/database/app_database.dart`) versionado
  separadamente do schema remoto (Postgres/Supabase);
- toda tabela local sensível a integridade (ex. fila offline) usa chave de
  idempotência (`event_id`) compatível com a chave usada no backend.
