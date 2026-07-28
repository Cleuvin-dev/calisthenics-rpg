# Prompt de continuidade para Claude Code

Você está continuando a implementação do projeto Flutter **App RPG
Calistenia**. Leia primeiro `docs/PROJECT_STATUS.md` (histórico
narrativo completo, seções mais recentes no final) e
`docs/IMPLEMENTATION_BACKLOG.md` (lista priorizada do que falta, sem
prosa). Depois, se for mexer nas telas de quatro abas, também
`APP_RPG_CALISTENIA_REDESENHO_NAVEGACAO_E_IMPLEMENTACAO.md`,
`docs/ARCHITECTURE.md`, `docs/UI_UX.md` e `docs/DATA_RESET.md`.

Este handoff substitui a versão anterior. Não declare o escopo do
documento de redesenho 100% concluído: seções inteiras (Descobrir §5.1,
Relatório) têm itens explicitamente fora do escopo por falta de
conteúdo/dado real (ver "Lacunas reais restantes").

**Estado do Git:** ao contrário de handoffs anteriores, desta vez o
trabalho **já foi commitado** pelo usuário — `753d58c` (todo o código
desta sessão) e `f8bda20` (removeu `assets/images/icon.jpg`/`icon.png`
do repositório, ação do próprio usuário fora desta sessão). Rode
`git status --short` mesmo assim antes de assumir que a árvore está
limpa — não presuma que o próximo usuário também vai commitar sozinho.

## O que foi implementado e verificado nesta sessão (2026-07-27, continuação)

Ponto de partida: peso/altura/IMC e favoritos já completos (herdados da
sessão anterior, handoff antigo). O usuário pediu, em sequência, uma
reverificação da integração de imagens e depois três mudanças de
produto — nenhuma delas exigia catálogo de treinos maior nem tocava em
XP/progressão/regras de segurança.

### 1. Reverificação da integração das 195 imagens

Não era um trabalho novo — já estava completo desde o commit `5b9a84a`
(sessão anterior). Esta leva foi auditoria, não reconstrução:

- **Bug encontrado e corrigido**: `README.md` da raiz tinha sido
  sobrescrito pelo README de um pacote de entrega de imagens (perdeu o
  mapa da documentação mestre). Restaurado via `git checkout`.
- Conferência dado-a-dado: os 195 `slug`/`asset_path` dos manifestos
  de entrega batem 1-para-1 com `assets/data/exercise_media_catalog.json`
  — 0 divergências, todos os arquivos existem em disco.
- Removidos (com confirmação do usuário) 7 arquivos de manifesto/
  checksum soltos na raiz do repositório, duplicados de
  `App_RPG_Exercise_Images/` (já commitado). Nunca chegaram a ser
  commitados, então a remoção não aparece no histórico.
- Ver `PROJECT_STATUS.md` §"Reverificação da integração das 195
  imagens".

### 2. Ilustração animada removida

A pedido do usuário ("remova os gifs" — não havia `.gif` nenhum, era a
ilustração animada de bonequinho):

- `lib/shared/presentation/pattern_illustration.dart` **deletado**.
- `lib/shared/presentation/exercise_media_placeholder.dart` reescrito:
  ícone estático (`Icons.fitness_center`) no lugar do bonequinho
  animado. Mesma API, `ExerciseMedia`/`PatternLevelMedia` não mudaram.
- Ver `PROJECT_STATUS.md` §"Remoção da ilustração animada".

### 3. Plano da semana em duas abas

A pedido do usuário: por padrão, mostrar só os exercícios do "treino
escolhido" (a sessão pendente mais próxima), sem tirar o acesso à
semana inteira.

- `lib/features/training_plan/domain/training_plan.dart`: nova função
  pura `nextPendingSession(WeeklyPlan, Set<String> completedDayLabels)`
  — extraída da lógica que já existia (duplicada) em `_NextSessionCard`
  da Jornada.
- `TrainingPlanScreen` ganhou `TabController` + duas abas: "Próximo
  treino" (só a sessão de `nextPendingSession`, com estado vazio se
  não sobrar nenhuma pendente) e "Semana completa" (comportamento
  antigo). `initialTabIndex` deixa a Jornada abrir na aba certa
  dependendo de qual botão o usuário tocou.
- Ver `PROJECT_STATUS.md` §"Abas 'Próximo treino' / 'Semana completa'
  no plano".

### 4. Objetivo de treino

Item que já estava no backlog com duas decisões marcadas "não
presumir" — perguntadas ao usuário antes de codar:

- **Um único objetivo ativo por vez** (`strength`/`fatLoss`/
  `conditioning`), não multi-seleção.
- **Regra de dose**: `strength` (padrão) mantém a dose do catálogo;
  `fatLoss` reduz `restSeconds` pela metade (piso 20s); `conditioning`
  reduz `restSeconds` em 25% (piso 30s) e soma `targetSets + 1`.
  Aquecimento nunca é modificado. Aplicado em
  `WeeklyPlanGenerator._doseFor` (`weeklyPlanGeneratorRuleVersion` →
  `weekly-plan-v2`).
- Novo enum `TrainingObjective` em `TrainingPreferences` + coluna
  aditiva `objective` (`training_preference_records`, migração 9→10)
  + item "Objetivo de treino" em Definição > Perfil e avaliação
  (diálogo `_ObjectiveDialog`, `RadioGroup`).
- **Escopo deliberadamente menor** que a ambição original do item do
  backlog (que pedia o motor "classificar" cada exercício por
  adequação a cada objetivo e selecionar exercícios diferentes) — o
  usuário aprovou a versão mais simples (só dose) depois de eu propor.
  Se um dia isso for revisitado, é trabalho novo, não uma correção do
  que foi feito aqui.
- **2 bugs pré-existentes corrigidos** achados durante o teste de
  regressão deste item:
  1. `_editWeekdays` (Definição) reconstruía `TrainingPreferences` sem
     repassar `heightCm` — editar os dias de treino zerava a altura
     salva silenciosamente.
  2. `TrainingPreferencesRepository.latest()` ordenava só por
     `updatedAt`, sem desempate — gravações em sequência rápida (ex.:
     editar altura, objetivo e dias de treino em poucos segundos)
     podiam empatar no timestamp e devolver a linha errada. Corrigido
     com `id DESC` como desempate.
- Ver `PROJECT_STATUS.md` §"Objetivo de treino".

### 5. Instalação no aparelho físico

`flutter build apk --release` + `adb install -r` no aparelho
`7549GMFUDA4DKZW8`. App abriu e ficou de pé (processo confirmado vivo,
sem `FATAL EXCEPTION` no `logcat`) — **só uma checagem automatizada de
"não crasha ao abrir"**, sem navegação manual pelas telas novas ainda.

## Arquivos principais criados/modificados nesta sessão

- `lib/features/onboarding/domain/training_preferences.dart`
  (`TrainingObjective`, campo `objective`)
- `lib/features/onboarding/data/training_preferences_repository.dart`
  (save/decode do objetivo + correção do desempate em `latest()`)
- `lib/core/database/tables/training_preference_records.dart`,
  `app_database.dart` (coluna `objective`, schemaVersion 9→10)
- `lib/features/training_plan/domain/training_plan.dart`
  (`nextPendingSession`)
- `lib/features/training_plan/domain/weekly_plan_generator.dart`
  (`_doseFor`, `weeklyPlanGeneratorRuleVersion` → `weekly-plan-v2`)
- `lib/features/training_plan/presentation/training_plan_screen.dart`
  (duas abas, `TabController`)
- `lib/features/journey/presentation/journey_screen.dart`
  (`_openPlan(initialTabIndex:)`, reaproveita `nextPendingSession`)
- `lib/features/settings/presentation/settings_screen.dart` (item +
  diálogo "Objetivo de treino"; correção do `_editWeekdays`)
- `lib/shared/presentation/exercise_media_placeholder.dart` (reescrito),
  `pattern_illustration.dart` (**deletado**)
- Testes novos: `test/features/training_plan/training_plan_screen_test.dart`,
  `test/features/settings/settings_screen_objective_test.dart`.
  Testes existentes com casos novos: `training_preferences_repository_test.dart`,
  `weekly_plan_generator_test.dart`. Testes ajustados (removida
  referência a `PatternIllustration`): `exercise_media_test.dart`,
  `pattern_level_media_test.dart`, `timed_set_player_flow_test.dart`.
- Documentação: `README.md` (restaurado), `docs/PROJECT_STATUS.md`,
  `docs/IMPLEMENTATION_BACKLOG.md`, `docs/CHANGELOG.md` (todos
  atualizados), este `HANDOFF_CLAUDE.md`.

## Validações executadas

- `flutter analyze`: sem problemas, verificado repetidamente ao longo
  da sessão (inclusive depois de cada bug corrigido).
- `dart format --set-exit-if-changed .`: sem mudanças pendentes.
- `flutter test`: **206 passed, 0 failed** (eram 194 no início desta
  continuação — 197 depois das abas do plano, 206 depois do objetivo
  de treino).
- `dart run build_runner build --delete-conflicting-outputs`: OK
  (gerou a coluna `objective`).
- `flutter build apk --release` + `adb install -r` no aparelho físico:
  OK, app abre sem crash. **Não testado manualmente** navegando pelas
  telas novas (Objetivo de treino, as duas abas do plano) — só a
  cobertura automatizada de widget garante o comportamento até aqui.

## Decisões arquiteturais tomadas

- Estrutura de assets de imagem **preservada** como já estava
  (`assets/images/exercises/<category_slug>/<slug>.png`, não
  `<slug>/v1/exercise.png`) — a arquitetura existente já era a fonte
  de verdade dos manifestos de entrega, não fazia sentido reorganizar
  195 arquivos só por preferência de nomenclatura.
- Ilustração animada removida sem substituto animado — só ícone
  estático. Se o produto quiser recuperar alguma forma de feedback
  visual mais rico para exercícios sem foto real, é decisão nova, não
  presumir que "ícone fixo" é definitivo.
- "Próximo treino" (não "Hoje") como nome da aba/conceito — o modelo
  de dados não amarra dia da semana a data de calendário
  (`PlannedSession.dayLabel` é preferência, não data fixa), então
  "Hoje" seria impreciso.
- Objetivo de treino muda só dose (`restSeconds`/`targetSets`), não
  seleção de exercício — decisão explícita do usuário depois de eu
  propor, dado que o catálogo mínimo (1-2 variações por padrão/nível)
  não tem material pra uma seleção real por objetivo ainda.
- `TrainingPreferencesRepository.latest()` agora desempata por `id
  DESC` além de `updatedAt DESC` — qualquer novo campo de preferência
  editável via Definição deve continuar repassando todos os campos
  existentes na reconstrução de `TrainingPreferences` (é a mesma
  classe de bug do `heightCm`; sempre construa a partir de
  `currentDomain.toDomain()` e repasse tudo, nunca reconstrua parcial).

## Lacunas reais restantes

Nenhuma é bug — todas são escopo deliberadamente não coberto, com o
porquê registrado. Prioridade aproximada, do maior efeito cascata pro
menor:

1. **Catálogo de treinos maior** — hoje só "Treino A · Fundação"; sem
   isso, seções da Descobrir §5.1 continuam impossíveis de implementar
   sem inventar conteúdo. Provavelmente o próximo item de maior
   alavancagem, ainda não escolhido pelo usuário.
2. **Nova curva de XP progressiva a 5%/nível** — pedida pelo usuário
   em 2026-07-27 (sessão anterior a esta), mas o próprio exemplo
   numérico dele tem uma inconsistência de arredondamento (315 não
   virou par, apesar da regra geral dizer "sempre arredondar para
   par") que precisa esclarecimento antes de implementar. Ver
   `docs/IMPLEMENTATION_BACKLOG.md` P1.
3. **Teste físico periódico/reavaliação** — pedido pelo usuário em
   2026-07-24, sem pergunta em aberto (pode ser planejado e
   implementado direto quando escolhido). Ver
   `docs/IMPLEMENTATION_BACKLOG.md` P1 para as peças reaproveitáveis
   já identificadas.
4. **"Descanso padrão" (Definição) não está conectado ao player** —
   decidir primeiro se deve ser piso/teto ou substituição completa do
   `restSeconds` curado por exercício antes de codar (a mesma decisão
   fica mais delicada agora que `restSeconds` também varia por
   objetivo de treino — ver item 4 da seção "O que foi implementado").
5. **Estimativa de gasto calórico** — peso/altura já existem como
   dado de entrada, falta decidir a fórmula (MET por padrão de
   movimento? por exercício?).
6. **Testes manuais físicos pendentes**: navegação manual real pelas
   quatro entregas desta sessão (Objetivo de treino, abas do plano,
   ilustração removida, imagens) — só a checagem automatizada de "abre
   sem crash" foi feita no aparelho. Mais os 3 testes manuais físicos
   pendentes de sessões ainda mais antigas: modo avião explícito, tela
   bloqueada durante série por tempo, toque duplo físico deliberado.
7. **Revisão profissional de conteúdo/mídia** (Educação Física) —
   bloqueia publicação comercial; depende de validação externa, não é
   trabalho de código.
8. Lacunas anteriores continuam registradas em
   `docs/IMPLEMENTATION_BACKLOG.md` (catálogo de exercícios mínimo,
   campanha/atributos RPG, missões incompletas, progressão sem
   regressão/platô/deload, etc.) — não foram tocadas nesta sessão.

## Sequência recomendada para continuar

1. `git status --short` (esperado limpo — confirme, não presuma), ler
   `docs/PROJECT_STATUS.md` (seções finais) e
   `docs/IMPLEMENTATION_BACKLOG.md`.
2. Escolher o próximo item com o usuário — a lacuna 1 (catálogo de
   treinos maior) tem o maior efeito cascata; a lacuna 2 (curva de XP)
   exige uma pergunta de esclarecimento antes de qualquer código.
3. Implementar em etapas pequenas e testáveis: domínio puro →
   repositório/provider → tela → teste de cada camada → `flutter
   analyze` + `flutter test` completos antes de seguir para a próxima
   etapa. `dart run build_runner build --delete-conflicting-outputs`
   sempre que uma tabela/coluna Drift mudar. Quando reconstruir
   `TrainingPreferences` num `_editX` de Definição, sempre a partir de
   `currentDomain.toDomain()` com todos os campos repassados — ver a
   decisão arquitetural sobre o bug do `heightCm` acima.
4. Atualizar `docs/CHANGELOG.md` (nova entrada datada),
   `docs/PROJECT_STATUS.md` (seção narrativa) e este
   `HANDOFF_CLAUDE.md` ao final.

Preserve o tema escuro, verde-menta como ação principal, roxo só para
XP, e todas as funcionalidades já existentes (Jornada, missões, plano
em duas abas, sessão pausada, progressão, peso/altura/IMC, favoritos,
objetivo de treino).
