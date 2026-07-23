# Core — sync

**Pausado.** A tabela local `OutboxEvents`
(`core/database/tables/outbox_events.dart`) fica reservada para quando
existir um backend para sincronizar (ver
`docs/adr/0006-mvp-local-only.md`). Na fase atual, 100% local/single-device,
não há worker de sincronização nem fila ativa: os dados vivem só no SQLite
local.

Referência: `08_ARCHITECTURE/TECHNICAL_ARCHITECTURE.md` §5, `docs/adr/0005-offline-queue.md`.
