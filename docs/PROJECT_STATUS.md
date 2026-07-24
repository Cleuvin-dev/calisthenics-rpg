# Project Status

**Data:** 2026-07-24
**Responsável:** Claude Code (sessão com Cleuvin)
**Branch/commit:** `main` (working tree com alterações não commitadas — usuário commita manualmente)

## Objetivo da sessão

Dar andamento ao MVP depois da primeira história vertical (triagem →
onboarding → colocação): implementar o **motor de treino determinístico**
e, em seguida, o **player de sessão offline**, seguindo a cadeia de
dependências de `10_DELIVERY/ROADMAP.md` §7 (avaliação → motor de treino →
sessão offline).

## Implementado

### Motor de treino (`features/training_plan`)

- **Domínio:** `exercise_catalog.dart` — catálogo mínimo (não editorial)
  cobrindo os padrões fundamentais de TRAINING_ENGINE.md §3, com uma
  variação conservadora por padrão/faixa de capacidade e equipamento.
  `weekly_plan_generator.dart` — `WeeklyPlanGenerator` determinístico:
  templates por frequência (2 a 6 dias, seguindo WEEKLY_TEMPLATES.md),
  orçamento de exercícios por duração da sessão, downgrade automático de
  6→5 dias (WEEKLY_TEMPLATES.md §6 — sem histórico suficiente ainda),
  seleção por nível de `push_horizontal` (única capacidade avaliada hoje;
  demais padrões usam a variação mais conservadora, mesma filosofia de
  `calculateSkippedEntirely`), substituição por equipamento com
  `reason_code` (`FOUNDATION_GAP`, `WEEKLY_BALANCE`,
  `EQUIPMENT_SUBSTITUTION`).
- **Dados:** tabela `training_plan_records` (plano serializado em JSON —
  recomputável, não precisa de tabelas relacionais ainda), repositório e
  providers Riverpod.
- **Apresentação:** `GenerateTrainingPlanScreen` (ação explícita de
  gerar) e `TrainingPlanScreen` (semana com motivo de cada exercício,
  link para colocação, botão de regerar).

### Player de sessão (`features/workout_session`)

- **Domínio:** `WorkoutSessionStatus` (iniciada/pausada/abandonada/
  concluída — FR-026), `PerceivedEffort` (muito fácil/adequado/difícil
  concluí/não completei/dor — FR-022, substitui RPE/RIR numérico por
  categorias mais rápidas de registrar em campo), `WorkoutSessionItem`
  (cópia congelada do item do plano no início da sessão — regenerar o
  plano depois não altera sessão já iniciada).
- **Dados:** tabelas `workout_session_records` (itens congelados em JSON)
  e `set_log_records` (uma linha por série, append-only, para permitir
  consulta futura por exercício/histórico). Repositório com
  `startSession`/`logSet`/`pause`/`resume`/`abandon`/`complete`/
  `latestActive`.
- **Apresentação:** `WorkoutPlayerScreen` (nome/padrão/alvo do exercício
  atual, séries já registradas, registrar série via `LogSetSheet`, botão
  de dor sempre visível — nunca em menu —, pausar/abandonar/concluir) e
  `WorkoutSummaryScreen` (contagem de séries e alerta se houve dor,
  já citando que dor não conta como evidência de domínio,
  PROGRESSION_RULES.md §8).
- **Wiring:** `TrainingPlanScreen` ganhou botão "Iniciar sessão" por dia
  e banner de sessão ativa/pausada para retomar (evita sessões órfãs
  duplicadas). `AppFlowGate` ganhou o estágio `_AfterPlacementGate`
  (mostra `GenerateTrainingPlanScreen` ou `TrainingPlanScreen` conforme
  exista plano salvo).
- Texto desatualizado em `PlacementResultScreen` corrigido (dizia que
  motor de treino/sessões "ainda não existem").

### Geral

- 40 testes automatizados (era 20 no início da sessão), todos passando —
  cobrem o gerador de plano (templates, orçamento por duração, downgrade
  de 6 dias, seleção por capacidade/equipamento, round-trip JSON) e o
  repositório de sessão (start/log/pause/resume/abandon/complete,
  prioridade de sessão ativa). `flutter analyze` sem problemas.
- **Não instalado/testado no aparelho físico nesta sessão** — o usuário
  vai conectar o celular e testar por conta própria depois. Não há
  ferramenta de automação de GUI neste ambiente para validar visualmente
  o fluxo (apenas testes automatizados + `flutter analyze`).

## Banco/migrations

- Backend Supabase segue pausado (ADR-0006); `supabase/migrations/`
  continua vazio. Sync (`OutboxEvents`) segue reservada e não usada
  (ADR-0005, `core/sync/README.md`).
- Schema local Drift em `schemaVersion = 4`:
  - `1→2`: recria `CapabilityEstimateRecords` (`inputAnchor` opcional).
  - `2→3`: cria `training_plan_records`.
  - `3→4`: cria `workout_session_records` e `set_log_records`.
  - Todas aceitáveis por não haver dados reais em produção ainda.

## Testes executados

| Comando | Resultado |
|---|---|
| `flutter analyze` | Sem problemas |
| `flutter test` | 40 passed, 0 failed |
| `dart run build_runner build` | OK |

Não rodado nesta sessão: `flutter build apk` / instalação no aparelho
(fica para o usuário, que testará conectando o celular).

## Decisões e ADRs

- ADR-0001 a 0006 seguem válidas.
- Decisões desta sessão (não formalizadas em ADR por serem locais e
  pequenas):
  - Catálogo de exercícios do motor de treino é deliberadamente mínimo
    (1-2 variações por padrão) — não é o catálogo editorial completo de
    EXERCISE_SCHEMA.md §7 (15+ variações, mídia, revisão profissional).
    Cresce em sessão futura dedicada a conteúdo.
  - Plano semanal e sessão de treino são armazenados como JSON dentro de
    uma linha (não tabelas relacionais normalizadas por sessão/item),
    porque são recomputáveis a partir de preferências+capacidade e ainda
    não há necessidade de consulta relacional. `set_log_records` é a
    exceção: uma linha por série, pensando em histórico/progressão
    futuros que vão precisar consultar por exercício.
  - `PerceivedEffort` (5 categorias de FR-022/TRAINING_ENGINE.md §8)
    substitui RPE/RIR numérico no registro de série — mais rápido de
    preencher em treino, e é literalmente o que as FRs pedem.

## Pendências

- Textos de triagem/segurança seguem placeholders — pendente de revisão
  profissional (SAFETY_AND_SCREENING.md §10).
- Catálogo de exercícios mínimo — precisa crescer antes de qualquer
  conteúdo além dos padrões fundamentais.
- Sem XP, progressão de domínio (`PROGRESSION_RULES.md`), campanha ou
  dashboard/jornada ainda.
- Sem timer/descanso, substituição de exercício em tela ou vídeo no
  player (SCREENS_AND_FLOWS.md §4 lista esses itens; ficaram fora do
  escopo desta primeira versão do player).
- `flutter run` em modo debug historicamente instável neste Windows
  (contenção de lock do Gradle) — usar `flutter build apk --release` +
  `adb install -r` quando for instalar no aparelho.

## Riscos/bloqueios

- Nenhum bloqueio técnico. Supabase CLI/Docker seguem não instalados,
  irrelevante enquanto o backend estiver pausado.

## Próxima tarefa recomendada

Com plano + execução + registro de séries funcionando, o próximo elo do
roadmap é **progressão/domínio** (`PROGRESSION_RULES.md`): usar os
`set_log_records` acumulados para promover/regredir nós de habilidade e
alimentar o `capability_estimate` de padrões além de `push_horizontal`.
Isso também é pré-requisito para o épico de RPG/XP (`ROADMAP.md` §7 lista
XP como dependente de "domínio").

## Critério para retomar

Ler este arquivo e `docs/adr/0006-mvp-local-only.md`. Nada foi instalado
no aparelho físico nesta sessão — qualquer divergência encontrada ao
testar deve ser tratada como bug, não como escopo pendente, a menos que
liste em "Pendências" acima.
