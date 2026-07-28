# Implementation Backlog

Lista viva e priorizada do que falta implementar/verificar. Complementa
`PROJECT_STATUS.md` (histórico narrativo de cada sessão — o "o que foi
feito e por quê") e `App_RPG_Calistenia_Documentacao/10_DELIVERY/
ROADMAP.md` (fases e épicos de longo prazo). Este arquivo é o "o que
fazer a seguir", sem prosa — cada item aponta para onde a decisão/
contexto completo está registrado.

**Como manter sincronizado:** ao concluir um item daqui, marque `[x]`,
mova para "Concluído recentemente" com a data, e registre o detalhe
(arquivos, testes, decisões) em `PROJECT_STATUS.md`. Ao descobrir uma
pendência nova durante uma sessão, adicione aqui **e** explique o
porquê em `PROJECT_STATUS.md` — nunca só em um dos dois.

**Última sincronização:** 2026-07-27, após implementar peso/altura/IMC,
favoritos (Descobrir) e, em seguida, objetivo de treino (dose por
`strength`/`fatLoss`/`conditioning`) — ver `PROJECT_STATUS.md`. Item
ainda aberto: catálogo de treinos maior continua bloqueador explícito
de várias seções da especificação de redesenho (Descobrir §5.1).

## P0 — imediato

- [ ] **Verificação manual restante no aparelho** (`docs/PROJECT_STATUS.md`
  §"Verificação manual no aparelho físico"): modo avião explícito, tela
  bloqueada durante série por tempo (`adb shell input keyevent
  KEYCODE_POWER`), toque duplo físico deliberado em "Concluir"/
  "Registrar série". O resto do player (mídia real, recuperação de
  série por tempo, ausência de crash) já foi confirmado no aparelho.
- [ ] **Revisão profissional de conteúdo/mídia** (Educação Física) —
  bloqueia publicação comercial (`README.md` do pacote de imagens,
  `SAFETY_AND_SCREENING.md` §10, `EXERCISE_SCHEMA.md` §5). Nenhum
  texto de triagem/segurança nem imagem tem essa revisão ainda; nada
  neste projeto deve marcar isso como concluído sem validação externa.

## P0/P1 — bugs reportados pelo uso real (2026-07-24)

Achados pelo usuário usando o app de verdade no aparelho, não em teste
automatizado — diagnosticados no código, corrigidos em 2026-07-26.

- [x] **`TrainingPlanScreen` ("Ver plano da semana completo") não mostra
  as imagens novas** — corrigido em 2026-07-26: `_ExerciseRow`
  (`lib/features/training_plan/presentation/training_plan_screen.dart:256`)
  agora chama `ExerciseMedia(exerciseSlug:, pattern:, namePtBr:,
  mediaSlug: item.mediaSlug, size: 44)` em vez de `PatternIllustration`
  direto. Ver `PROJECT_STATUS.md` §"Correções dos bugs reportados
  (2026-07-26)".
- [x] **Texto "Sua próxima missão de treino" sem contraste** no card
  verde-menta de destaque da Jornada — corrigido em 2026-07-26:
  `_NextSessionCard` (`lib/features/journey/presentation/
  journey_screen.dart:356-372`) agora define
  `style: TextStyle(color: colorScheme.onPrimaryContainer)` no
  `title`/`subtitle` e `color:` no `trailing` `Icon`. Checados os
  demais cards da tela — nenhum outro define `color:` explícito no
  `Card`, então nenhum outro tinha o mesmo problema.

## P0 — épicos fundacionais ainda incompletos

- [x] **Avaliação/progressão nos 4 padrões novos** (`pull_horizontal`,
  `squat`, `hinge_posterior_chain`, `core_anti_extension`) — concluído em
  2026-07-26: catálogo em camadas + `MasteryRule`/promoção automática
  igual a `push_horizontal`. Verificado no aparelho físico: regenerar o
  plano com dados reais prescreveu corretamente as novas variações por
  nível (ex.: "Remada australiana inclinada" pra pull_horizontal nível
  2-3). Ver `PROJECT_STATUS.md` §"Catálogo em camadas para os 4 padrões
  novos". Continua pendente (não fazia parte deste item): revisão
  profissional dos números de dose/mastery (placeholders de MVP) e o
  caso de um padrão nunca autoavaliado (sem colocação salva, sem
  progressão rastreada — ver item de reavaliação periódica abaixo, em
  P1).
- [ ] **Catálogo de exercícios ainda é mínimo** (1-2 variações por
  padrão, não o catálogo editorial de `EXERCISE_SCHEMA.md` §7 com 15+
  variações por padrão). Cresce junto com a revisão profissional acima.
- [x] **Ligar as 195 imagens às escadas de avaliação/Evolução** —
  concluído em 2026-07-26: novo `PatternLevelMedia`
  (`lib/shared/presentation/pattern_level_media.dart`) traduz
  `pattern`+`level` para `mediaSlug` via
  `MediaCatalogIndex.byCategoryLevel`, usado em
  `AssessmentSkipTestScreen`, `OtherPatternsAssessmentScreen`,
  `EvolutionScreen` e `PlacementResultScreen`. Verificado no aparelho
  físico (`EvolutionScreen`, `OtherPatternsAssessmentScreen`) — fotos
  reais e distintas por opção/padrão, sem crash. Ver
  `PROJECT_STATUS.md` §"Mídia real nas telas de avaliação/Evolução".
  Ainda restam imagens de níveis avançados (front lever, planche etc.)
  sem nenhum exercício prescrito que as referencie — fora do escopo
  deste item (é sobre as escadas de avaliação/colocação, não sobre
  expandir o catálogo de prescrição).
- [ ] **2 exercícios prescritos sem `mediaSlug` associado**:
  `warmup_joint_mobility` (aquecimento não é nó de nenhuma árvore) e
  `parallel_bar_support_hold` (nenhum nó de `dips_suporte` corresponde
  com segurança). Mostram o placeholder animado — funcional, mas sem
  foto real.

## P1 — RPG/conteúdo
- [ ] **Nova curva de XP por nível, progressiva a 5% por nível** (pedido
  do usuário, 2026-07-27): substitui a fórmula atual de
  `lib/features/rpg/domain/level_curve.dart`
  (`xpRequiredForLevel(level) = round(100 + 25 × nível^1.35)`,
  `levelCurveVersion = 'level-curve-v1'`). Regra exata pedida pelo
  usuário, com seu próprio exemplo numérico:
  - Nível 1 → 2: exige **300 XP**.
  - A partir daí, o XP exigido para o próximo nível é **5% maior que o
    do nível anterior**: nível 2 → 3 = `300 × 1.05 = 315`; nível 3 → 4 =
    `315 × 1.05 = 330,75`, **arredondado para o número par mais
    próximo = 330**; nível 4 → 5 = `330 × 1.05 = 346,5`, arredondado
    para **346**; nível 5 → 6 = `346 × 1.05 = 363,3`, arredondado para
    **364**. E assim sucessivamente até o **nível 100**.
  - **Arredondamento "para o número par mais próximo"**: não é
    arredondamento comum (que iria para o inteiro mais próximo depois
    ajustaria a paridade) — é comparar a distância aos dois inteiros
    pares vizinhos e escolher o mais próximo (confirmado batendo os 3
    exemplos do usuário: 330,75→330, 346,5→346, 363,3→364 — todos batem
    com "menor distância a um par", não com "arredondar e depois forçar
    par").
  - **Inconsistência a esclarecer com o usuário antes de implementar**:
    o próprio exemplo do usuário deixa `300 × 1.05 = 315` **sem
    arredondar para par** (315 é ímpar), embora a regra geral diga
    "arredonde sempre para o número par mais próximo". Implementar a
    regra geral ao pé da letra mudaria o nível 2→3 de 315 para 314 ou
    316, contradizendo o exemplo dado. Perguntar ao usuário se o
    arredondamento para par vale desde o primeiro passo (e o "315" do
    exemplo foi só um lapso) ou se só passa a valer a partir do momento
    em que o resultado tem casa decimal (já que `300 × 1,05` dá um
    número inteiro exato, sem nada para arredondar).
  - **Impacto em dados existentes**: como o nível é sempre derivado do
    XP total acumulado (`LevelCalculator.levelFor`), trocar a curva
    reinterpreta retroativamente todo XP já ganho por qualquer usuário
    existente — decidir se isso é aceitável (coerente com o app ainda
    não ter sido publicado/ter poucos usuários) ou se precisa de algum
    tratamento de migração. Ao implementar, seguir o padrão já usado
    pelo projeto de versionar a regra (`levelCurveVersion` sobe para
    `level-curve-v2` ou similar) e cobrir com teste todos os pontos do
    exemplo do usuário (níveis 1 a 5 pelo menos) mais o caso de borda do
    nível 100.
- [ ] **Teste físico periódico e adaptativo** (pedido do usuário,
  2026-07-24): tela nova acessível por um botão no Dashboard/Jornada,
  onde o usuário pode — a qualquer momento, ou como sugestão a cada
  15/30 dias — escolher quais exercícios/padrões quer reavaliar (não
  uma bateria fixa obrigatória). A partir do resultado, recalcular
  automaticamente as metas semanais (equivalente a rodar o
  `WeeklyPlanGenerator` de novo com o `capabilityLevelsByPattern`
  atualizado — os 4 padrões novos já ganharam prescrição em camadas,
  ver item acima, então isso já vale pros 5 padrões, não só
  push_horizontal). Resolve o caso relatado de o app manter "Flexão na
  parede" prescrita sem o usuário conseguir dizer "já sei fazer flexão
  completa" de forma simples, e o equivalente para os outros 4 padrões
  quando nunca autoavaliados. Peças que já
  existem e podem ser reaproveitadas: `ConservativePlacementCalculator.
  calculateForPattern`/`calculateSkippedEntirelyForPattern`
  (`conservative_placement.dart`), `CapabilityEstimateRepository.
  saveEstimate` (já grava uma nova linha por reavaliação, o histórico
  de colocações já é append-only), `OtherPatternsAssessmentScreen` como
  referência de UI para autorrelato por padrão. Falta: entrada point no
  Dashboard, fluxo de "reavaliar quando eu quiser" (não só na
  onboarding), e o recálculo automático do plano/metas ao final.
- [ ] **Campanha/fases narrativas, atributos, Boss Test, classes,
  ranking** (`RPG_SYSTEM.md` §4-7, §10-11) — hoje só existe XP/nível +
  missões diárias/semanais.
- [ ] **Missões**: só 3 diárias + 3 semanais dos ~10 tipos de
  `RPG_SYSTEM.md` §8. Faltam check-in/prontidão (não existe conceito de
  dia de descanso prescrito) e "revisar progresso".
- [ ] **Recordes da tela Evolução** são só "maior número de reps por
  exercício" — não separam por variação/amplitude/assistência/contexto
  (`PROGRESSION_RULES.md` §7). Atributos narrativos
  (força/resistência/controle/...) de `RPG_SYSTEM.md` §4 não existem.
- [ ] **Progressão**: não cobre regressão temporária, platô nem deload
  (`PROGRESSION_RULES.md` §4-6) — só promoção linear +1 nível.
- [ ] **Notificações locais** (`ROADMAP.md` §2, épico "Notificações
  locais") — não implementado.
- [ ] **Tela de Habilidades** (mapa de árvores, `SCREENS_AND_FLOWS.md`
  §5) — 2 dos 5 destinos de navegação (Habilidades, Perfil) não
  existem; tudo hoje é push de tela a partir da Jornada, sem abas.
  Agora tem 195 imagens prontas para usar quando for construída.
- [ ] **Tela de Treino: mostrar a trilha completa de treinos, não só
  "Treino A"** (pedido do usuário, 2026-07-24): abaixo do "Treino A ·
  Fundação" em `WorkoutCatalogScreen`, listar também os treinos de
  nível seguinte (B, C, ... até o mais avançado), mesmo os ainda
  bloqueados para o nível atual do usuário — mostrados de forma visível
  mas não iniciáveis, para o usuário enxergar aonde a evolução leva
  ("quais movimentos vou conseguir fazer lá na frente") e se manter
  motivado. Depende de `workoutCatalog` (`workout_catalog.dart`) ter
  mais de uma entrada — hoje só existe "Treino A" — e de um estado
  "bloqueado/desbloqueado" por treino baseado em nível de capacidade,
  que ainda não existe no modelo `Workout`. Conceitualmente próximo da
  Tela de Habilidades acima (mostrar toda a árvore, não só o próximo
  passo) — vale desenhar os dois juntos.

## P2 — player e configurações (fora do escopo combinado até aqui)

- [ ] Seletor de duração personalizável pré-sessão (chips 20s/30s/45s/
  Personalizar — `SETTINGS_AND_TIMED_EXERCISES.md` §9.1/§12.3). Hoje o
  player usa a duração recomendada do exercício como alvo fixo.
- [x] **Página de Configurações (Definição)** — em grande parte
  concluída via o redesenho de quatro abas + continuação de 2026-07-27:
  reset de jornada (`ProgressResetService`, ver `DATA_RESET.md`), meta
  de dias de treino da semana, contagem regressiva editável e conectada
  ao player, uso de armazenamento real,
  **perfil físico (altura/peso para IMC)** — concluído em 2026-07-27,
  ver item próprio abaixo. Ainda falta especificamente:
  - estimativa de gasto calórico por sessão/exercício — nem sequer
    decidido a fórmula (MET por padrão de movimento? por exercício?);
    agora que peso/altura existem, o dado de entrada já está disponível,
    mas a fórmula em si continua sem decisão.
  - "Descanso padrão" (Definição) existe e é exibido, mas
    deliberadamente não conectado ao player — ver
    `docs/HANDOFF_CLAUDE.md` "Lacunas reais restantes" para o porquê
    (arriscaria descartar rest time curado por exercício no catálogo).
- [ ] Catálogo de treinos maior — hoje só "Treino A · Fundação"; o
  documento prevê filtros por nível e múltiplos treinos nomeados. Sem
  isso, várias seções da aba Descobrir (§5.1 do documento de
  redesenho: "Alongar e aquecer", "Desafios", "Progressões de
  habilidade", "Para iniciantes/Intermediários/Avançados") continuam
  impossíveis de implementar sem inventar conteúdo — ver
  `docs/UI_UX.md` "Aba Descobrir".
- [x] **Favoritos** (Descobrir) — concluído em 2026-07-27: tabela
  `favorite_records` (workout/exercise + slug, preferência pessoal,
  sobrevive ao reset), botão de estrela em cada card de treino/exercício,
  chip "Favoritos" filtra por eles. Ver `PROJECT_STATUS.md` §"Favoritos".
- [ ] Placeholder de mídia sem lista de erros comuns/checklist de
  equipamento (`EXERCISE_MEDIA_GUIDE.md` §12) — mostra só nome,
  ilustração animada e dose.

## P2 — infraestrutura

- [ ] Nenhum: Supabase/sincronização (Fase 4 do `ROADMAP.md`) segue
  deliberadamente pausada (ADR-0006) — não é dívida técnica, é decisão
  de fase. Não iniciar sem decisão explícita do usuário.

## P3 — fora de escopo até novo aviso

- Social (amigos, grupos, rankings) — depende de Supabase/antifraude.
- Câmera/IA — depende de consentimento/validação; explicitamente
  excluído de todos os prompts de implementação até aqui.
- Habilidades avançadas com trilha elite (planche, front/back lever,
  human flag, Nordic, dragon flag) — imagens já existem no catálogo de
  195, mas nada foi prescrito nem revisado para essas trilhas.

## Achados de ambiente (não é trabalho de produto, mas afeta como testar)

- `adb shell uiautomator dump` neste aparelho específico
  (`7549GMFUDA4DKZW8`) abre esporadicamente o assistente de
  acessibilidade "Acesso por interruptor" do Android. Ao testar
  manualmente: preferir coordenadas já calibradas/`adb shell wm size`;
  se precisar de `uiautomator dump`, checar o resultado antes de tocar
  em qualquer coordenada e fechar o assistente se ele aparecer.
- `flutter run` em modo debug historicamente instável neste Windows
  (contenção de lock do Gradle) — usar `flutter build apk --release` +
  `adb install -r`.
- Assets em subpastas aninhadas (`assets/images/exercises/<categoria>/`)
  precisam de uma entrada própria por subpasta no `pubspec.yaml` — uma
  entrada só no diretório pai não garante inclusão recursiva confiável
  (confirmado testando com `flutter build bundle`).

## Concluído recentemente

- 2026-07-27 — Objetivo de treino escolhido pelo usuário: as duas
  decisões que este item deixava em aberto foram resolvidas pelo
  usuário antes de codar (não presumidas) — (1) **um único objetivo
  ativo por vez** (não multi-seleção, apesar do "e/ou" do pedido
  original) e (2) regra de dose explícita: `strength` (padrão) mantém
  a dose do catálogo; `fatLoss` reduz `restSeconds` pela metade (piso
  20s); `conditioning` reduz `restSeconds` em 25% (piso 30s) e soma
  `targetSets + 1`; aquecimento nunca é modificado. Implementado como
  modificador de dose em `WeeklyPlanGenerator._doseFor`
  (`weeklyPlanGeneratorRuleVersion` → `weekly-plan-v2`), não como
  reclassificação de exercícios por objetivo — a versão mais ambiciosa
  descrita originalmente (motor "pontuar" cada `CatalogExercise` por
  adequação a cada objetivo) foi descartada pelo usuário em favor desta
  mais simples. Novo enum `TrainingObjective` em `TrainingPreferences`
  + coluna aditiva `objective` em `training_preference_records`
  (migração 9→10) + item "Objetivo de treino" em Definição > Perfil e
  avaliação. Ver `PROJECT_STATUS.md` §"Objetivo de treino".
- 2026-07-27 — Favoritos (Descobrir): tabela `favorite_records`
  (migração 8→9, aditiva), `FavoriteRepository`
  (toggle/allKeys, `workout`/`exercise` não colidem por slug igual),
  botão de estrela em `_WorkoutCard`/`_ExerciseCard`, chip "Favoritos"
  agora filtra de verdade (antes desabilitado). Preferência pessoal —
  `ProgressResetService` não toca na tabela. Ver `PROJECT_STATUS.md`
  §"Favoritos".
- 2026-07-27 — Peso, altura e IMC: tabela nova `body_metric_records`
  (peso + data, editável/excluível) + coluna `heightCm` em
  `training_preference_records` (migração 7→8, aditiva), domínio de
  validação/IMC, "Altura" e "Peso e IMC" em Definição > Perfil, tela
  `BodyMetricScreen` (resumo, tendência, histórico, editar/excluir com
  confirmação), card real no Relatório substituindo o estado
  "ainda não disponível". `ProgressResetService` apaga o histórico de
  peso, preserva a altura. Ver `PROJECT_STATUS.md` §"Peso, altura e
  IMC".
- 2026-07-27 — Continuação do redesenho de quatro abas: Jornada
  reordenada, Descobrir/Relatório/Definição completos (filtros reais,
  aderência/recordes/volume, meta de dias de treino + contagem
  regressiva conectada + uso de armazenamento), ícone do app, validação
  visual/responsiva automatizada, 3 bugs reais corrigidos. Ver
  `PROJECT_STATUS.md` §"Continuação: quatro abas completas, correções
  de bugs reais (2026-07-27)" e `docs/HANDOFF_CLAUDE.md`.
- 2026-07-26 — Mídia real (foto em vez de placeholder) nas telas de
  avaliação/Evolução, via `MediaCatalogIndex.byCategoryLevel`. Ver
  `PROJECT_STATUS.md` §"Mídia real nas telas de avaliação/Evolução".
- 2026-07-26 — Catálogo em camadas + `MasteryRule`/promoção automática
  para os 4 padrões novos (`pull_horizontal`, `squat`,
  `hinge_posterior_chain`, `core_anti_extension`), mesmo tratamento que
  `push_horizontal` já tinha. Ver `PROJECT_STATUS.md` §"Catálogo em
  camadas para os 4 padrões novos".
- 2026-07-26 — Corrigidos os 2 bugs de mídia/contraste reportados pelo
  usuário em 2026-07-24 (`TrainingPlanScreen` sem imagens reais; texto
  sem contraste no card de destaque da Jornada). Ver
  `PROJECT_STATUS.md` §"Correções dos bugs reportados (2026-07-26)".
- 2026-07-24 — Integração das 195 imagens do pacote
  `App_RPG_Exercise_Images/` ao catálogo/detalhe/player/descanso, com
  associação por `mediaSlug` (9 de 13 exercícios prescritos, alta/média
  confiança) e verificação manual completa no aparelho físico
  (mídia real, recuperação de série por tempo, sem crashes). Ver
  `PROJECT_STATUS.md` §"Integração do pacote de 195 imagens reais" e
  §"Verificação manual no aparelho físico".
- 2026-07-24 — História vertical do player offline por repetições e por
  duração (dose estruturada, catálogo de treinos aditivo, timer
  monotônico, recuperação após fechar o app, idempotência, tema v1.2).
  Ver `PROJECT_STATUS.md` §"Player de treino offline: reps + duração".
- Sessão anterior — dois bugs corrigidos (voltar do sistema não pausava
  a sessão; `TrainingPlanScreen` não atualizava após regenerar),
  avaliação real estendida a 4 padrões novos, tela Evolução nova.
