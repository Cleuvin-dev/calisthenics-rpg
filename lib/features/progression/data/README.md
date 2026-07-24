# Progression — data

Sem tabela própria: lê sessões/séries já gravadas por `workout_session` e
grava promoções reaproveitando `capability_estimate_records`
(`CapabilityEstimateRepository.saveEstimate`), com `reason_code` próprio
(`masteryConfirmedReasonCode`) para diferenciar de colocação por
autorrelato.

Referência: `08_ARCHITECTURE/DATA_MODEL.md`, `04_TRAINING/PROGRESSION_RULES.md`.
