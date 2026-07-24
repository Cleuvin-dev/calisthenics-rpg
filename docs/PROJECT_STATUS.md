# Project Status

**Data:** 2026-07-24
**Responsável:** Claude Code (sessão com Cleuvin)
**Branch/commit:** `main` (working tree com alterações não commitadas — usuário commita manualmente)

## Objetivo da sessão

Dar andamento ao MVP depois da primeira história vertical (triagem →
onboarding → colocação): implementar, em sequência, o **motor de treino
determinístico**, o **player de sessão offline** e a **confirmação de
domínio/progressão**, seguindo a cadeia de dependências de
`10_DELIVERY/ROADMAP.md` §7 (avaliação → motor de treino → sessão
offline → progressão/domínio).

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
  link para colocação, botão de regerar, botão "Iniciar sessão" por dia).

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
  `WorkoutSummaryScreen` (contagem de séries, alerta se houve dor, e — a
  partir desta sessão — o resultado da avaliação de domínio).
- **Wiring:** `TrainingPlanScreen` ganhou banner de sessão ativa/pausada
  para retomar (evita sessões órfãs duplicadas). `AppFlowGate` ganhou o
  estágio `_AfterPlacementGate` (mostra `GenerateTrainingPlanScreen` ou
  `TrainingPlanScreen` conforme exista plano salvo).
- Texto desatualizado em `PlacementResultScreen` corrigido (dizia que
  motor de treino/sessões "ainda não existem").

### Progressão/domínio (`features/progression`)

- **Domínio:** `mastery_rules.dart` — uma `MasteryRule` por variação da
  escada de `push_horizontal` (reps mínimas por série, séries
  qualificadas por sessão, confirmações necessárias, intervalo mínimo
  entre confirmações — PROGRESSION_RULES.md §2, números placeholder de
  MVP). `mastery_evaluator.dart` — `MasteryEvaluator` determinístico:
  percorre sessões concluídas em ordem cronológica, desqualifica sessão
  inteira se houver série com dor (DATA_MODEL.md §4), conta confirmações
  respeitando o intervalo mínimo entre elas.
- **Dados:** `ProgressionRepository.evaluateAndPromotePushHorizontal` —
  busca sessões concluídas + `set_logs` do exercício correspondente ao
  nível atual desde a última colocação, roda o avaliador e, se promovido,
  grava uma nova linha em `capability_estimate_records` via
  `CapabilityEstimateRepository.saveEstimate` (método novo, generalizado
  a partir do `save(ConservativePlacementResult)` existente — mesma
  tabela, `reason_code: masteryConfirmed`, `confidence: medium`). Sem
  tabela própria: reaproveita o que já existia.
- **Wiring:** `WorkoutPlayerScreen` recebe a colocação atual de
  `push_horizontal` e roda a avaliação ao concluir a sessão;
  `WorkoutSummaryScreen` mostra confirmação parcial ("você atingiu o alvo
  em X de Y sessões") ou domínio confirmado, com aviso para gerar um novo
  plano manualmente (nada muda de plano "em silêncio").

### Geral

- 52 testes automatizados (era 20 no início da sessão), todos passando —
  cobrem o gerador de plano, o repositório de sessão e, agora, o
  avaliador de domínio (sessões insuficientes, intervalo entre
  confirmações, dor desqualificando sessão, reps/esforço abaixo do
  alvo) e o repositório de progressão (promoção real grava
  `capability_estimate_records`, sessões antes da colocação atual não
  contam, nível 7 não é reavaliado). `flutter analyze` sem problemas.
- **Não instalado/testado no aparelho físico nesta sessão** — o usuário
  vai conectar o celular e testar por conta própria depois. Não há
  ferramenta de automação de GUI neste ambiente para validar visualmente
  o fluxo (apenas testes automatizados + `flutter analyze`).

## Banco/migrations

- Backend Supabase segue pausado (ADR-0006); `supabase/migrations/`
  continua vazio. Sync (`OutboxEvents`) segue reservada e não usada
  (ADR-0005, `core/sync/README.md`).
- Schema local Drift em `schemaVersion = 4` (sem mudança nesta parte da
  sessão — progressão reaproveita `capability_estimate_records`):
  - `1→2`: recria `CapabilityEstimateRecords` (`inputAnchor` opcional).
  - `2→3`: cria `training_plan_records`.
  - `3→4`: cria `workout_session_records` e `set_log_records`.
  - Todas aceitáveis por não haver dados reais em produção ainda.

## Testes executados

| Comando | Resultado |
|---|---|
| `flutter analyze` | Sem problemas |
| `flutter test` | 52 passed, 0 failed |
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
    futuros que vão precisar consultar por exercício — decisão que já
    pagou o investimento nesta mesma sessão, ao alimentar a progressão.
  - `PerceivedEffort` (5 categorias de FR-022/TRAINING_ENGINE.md §8)
    substitui RPE/RIR numérico no registro de série — mais rápido de
    preencher em treino, e é literalmente o que as FRs pedem.
  - Progressão só cobre `push_horizontal` (único padrão com colocação
    real hoje) e só promove +1 nível por vez, nunca pula direto para a
    próxima variação da escada — "menor incremento possível"
    (PROGRESSION_RULES.md §3/§9). `CapabilityEstimateRepository` ganhou
    `saveEstimate(...)` genérico para não duplicar a lógica de insert
    entre colocação conservadora e confirmação de domínio.

## Pendências

- Textos de triagem/segurança seguem placeholders — pendente de revisão
  profissional (SAFETY_AND_SCREENING.md §10).
- Catálogo de exercícios mínimo — precisa crescer antes de qualquer
  conteúdo além dos padrões fundamentais.
- Progressão não cobre regressão temporária, platô, deload nem os demais
  padrões além de `push_horizontal` (PROGRESSION_RULES.md §4-6).
- Sem XP, campanha ou dashboard/jornada ainda.
- Sem timer/descanso, substituição de exercício em tela ou vídeo no
  player (SCREENS_AND_FLOWS.md §4 lista esses itens; ficaram fora do
  escopo da primeira versão do player).
- Promoção de domínio não regenera o plano automaticamente — usuário
  precisa tocar "Gerar novamente" (decisão deliberada, ver acima).
- `flutter run` em modo debug historicamente instável neste Windows
  (contenção de lock do Gradle) — usar `flutter build apk --release` +
  `adb install -r` quando for instalar no aparelho.

## Riscos/bloqueios

- Nenhum bloqueio técnico. Supabase CLI/Docker seguem não instalados,
  irrelevante enquanto o backend estiver pausado.

## Próxima tarefa recomendada

Com plano → sessão → registro → confirmação de domínio fechando o ciclo
para `push_horizontal`, as próximas opções naturais são: (a) estender
avaliação/colocação real para os demais padrões fundamentais (hoje só
push_horizontal tem anchor/teste — os outros usam sempre nível 0), o que
destrava progressão de verdade neles também; ou (b) começar o épico de
RPG/XP (`ROADMAP.md` §7), que depende de "domínio" e já tem uma fonte de
eventos (`capability_estimate_records` promovido por
`masteryConfirmedReasonCode`) para se pendurar.

## Critério para retomar

Ler este arquivo e `docs/adr/0006-mvp-local-only.md`. Nada foi instalado
no aparelho físico nesta sessão — qualquer divergência encontrada ao
testar deve ser tratada como bug, não como escopo pendente, a menos que
liste em "Pendências" acima.
