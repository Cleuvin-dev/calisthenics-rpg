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

**Última sincronização:** 2026-07-24, após feedback do usuário usando o
app de verdade no aparelho (5 itens novos: 2 bugs de mídia/contraste
diagnosticados, 3 pedidos de funcionalidade — Configurações completa,
reavaliação física periódica e adaptativa, trilha completa de treinos
visível na tela de Treino).

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
automatizado — diagnosticados no código, prontos para corrigir.

- [ ] **`TrainingPlanScreen` ("Ver plano da semana completo") não mostra
  as imagens novas**: `_ExerciseRow` (`lib/features/training_plan/
  presentation/training_plan_screen.dart:256`) chama
  `PatternIllustration(pattern: item.pattern, size: 44)` diretamente, em
  vez de `ExerciseMedia(..., mediaSlug: item.mediaSlug)`. O campo
  `PlannedExerciseItem.mediaSlug` já existe e já é preenchido pelo
  `WeeklyPlanGenerator` — a tela é que nunca foi migrada para o widget
  novo quando as 195 imagens foram integradas (esse trabalho só cobriu
  `WorkoutCatalogScreen`/`WorkoutDetailScreen`/`WorkoutPlayerScreen`/
  `RestScreen`, o catálogo de treinos novo, não a tela antiga do plano
  semanal). Fix contido: trocar a chamada do widget nessa linha.
- [ ] **Texto "Sua próxima missão de treino" sem contraste** no card
  verde-menta de destaque da Jornada: `_NextSessionCard`
  (`lib/features/journey/presentation/journey_screen.dart:354-370`) usa
  `Card(color: colorScheme.primaryContainer)` mas o `subtitle` do
  `ListTile` não define cor própria — herda o estilo padrão de texto
  claro/cinza pensado para o fundo escuro do app, não para o fundo
  verde do card. Fix: definir explicitamente
  `style: TextStyle(color: colorScheme.onPrimaryContainer)` (ou
  equivalente) no `title`/`subtitle` desse `ListTile`. Vale checar os
  outros cards com `color:` explícito na mesma tela pelo mesmo problema.

## P0 — épicos fundacionais ainda incompletos

- [ ] **Avaliação/progressão nos 4 padrões novos** (`pull_horizontal`,
  `squat`, `hinge_posterior_chain`, `core_anti_extension`): já têm
  escada de autorrelato (`fundamental_pattern_anchors.dart`) e
  colocação conservadora, mas o motor de treino ainda prescreve uma
  única variação por padrão (sem níveis) e `MasteryRule`/
  `ProgressionRepository` só cobrem `push_horizontal`. Extensão natural:
  dar aos 4 o mesmo tratamento em camadas que `push_horizontal` já tem.
  Relato real do usuário (2026-07-24) que evidencia o problema: o app
  prescreveu "Flexão na parede" (`push_up_wall`, nível 0-1) mesmo já
  conseguindo fazer flexão completa — sintoma direto de colocação
  conservadora sem caminho fácil de corrigir/reavaliar (ver item de
  reavaliação periódica abaixo, em P1).
- [ ] **Catálogo de exercícios ainda é mínimo** (1-2 variações por
  padrão, não o catálogo editorial de `EXERCISE_SCHEMA.md` §7 com 15+
  variações por padrão). Cresce junto com a revisão profissional acima.
- [ ] **Ligar as 195 imagens às escadas de avaliação/Evolução**
  (`fundamental_pattern_anchors.dart`, `push_horizontal_anchor.dart`,
  telas de avaliação e `EvolutionScreen`) via
  `MediaCatalogIndex.byCategoryLevel(categorySlug, level)` — já pronto
  em `lib/shared/domain/exercise_media_catalog.dart`, só falta o
  wiring nas telas. Hoje só 9 dos 13 exercícios prescritos mostram foto
  real; as ~184 imagens restantes (níveis avançados de todas as 14
  árvores) estão carregadas mas não aparecem em nenhuma tela.
- [ ] **2 exercícios prescritos sem `mediaSlug` associado**:
  `warmup_joint_mobility` (aquecimento não é nó de nenhuma árvore) e
  `parallel_bar_support_hold` (nenhum nó de `dips_suporte` corresponde
  com segurança). Mostram o placeholder animado — funcional, mas sem
  foto real.

## P1 — RPG/conteúdo

- [ ] **Teste físico periódico e adaptativo** (pedido do usuário,
  2026-07-24): tela nova acessível por um botão no Dashboard/Jornada,
  onde o usuário pode — a qualquer momento, ou como sugestão a cada
  15/30 dias — escolher quais exercícios/padrões quer reavaliar (não
  uma bateria fixa obrigatória). A partir do resultado, recalcular
  automaticamente as metas semanais (equivalente a rodar o
  `WeeklyPlanGenerator` de novo com o novo `pushHorizontalCapabilityLevel`
  e, quando os 4 padrões novos ganharem prescrição em camadas — item
  acima —, também com os outros níveis). Resolve o caso relatado de o
  app manter "Flexão na parede" prescrita sem o usuário conseguir dizer
  "já sei fazer flexão completa" de forma simples. Peças que já
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
- [ ] **Página de Configurações completa** (pedido reforçado pelo
  usuário, 2026-07-24; `SETTINGS_AND_TIMED_EXERCISES.md`, documento
  inteiro é sobre isso — prompt separado do que já foi implementado):
  - reset de jornada — apagar/reiniciar dados salvos (nível, XP,
    missões, histórico de sessões, colocações) para recomeçar do zero;
  - perfil físico: altura/peso para cálculo de IMC;
  - estimativa de gasto calórico por sessão/exercício — hoje não existe
    nenhum campo de peso/altura no modelo de dados nem cálculo de
    calorias em lugar nenhum do app; precisa decidir a fórmula (MET por
    padrão de movimento? por exercício?) antes de implementar.
- [ ] Catálogo de treinos maior — hoje só "Treino A · Fundação"; o
  documento prevê filtros por nível e múltiplos treinos nomeados.
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
