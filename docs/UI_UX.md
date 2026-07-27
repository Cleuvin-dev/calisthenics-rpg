# UI/UX

**Última atualização:** 2026-07-27

Tema, tokens, componentes reutilizáveis e regras de composição das
quatro abas, como existem hoje no código. A especificação original que
orientou o redesenho está em
`APP_RPG_CALISTENIA_REDESENHO_NAVEGACAO_E_IMPLEMENTACAO.md` (raiz do
projeto) — este documento reflete o que foi de fato implementado, que
diverge da especificação em alguns pontos (registrados abaixo).

## Decisão visual

Tema escuro fixo (`ThemeMode.dark` sempre) — sem alternância clara/
escuro. Verde-menta é a cor de ação principal; roxo é reservado
exclusivamente para XP/nível/progressão RPG; nunca o contrário.

## Tokens (`lib/app/theme.dart`)

| Token interno | Papel | Valor |
|---|---|---|
| `_surfaceCanvas` | fundo principal | `#080A0B` |
| `_surfaceCard` | cards | `#141819` |
| `_surfaceElevated` | cards em destaque | `#1B2021` |
| `_brandPrimary` | ação principal (verde-menta) | `#35E6A1` |
| `_brandPrimaryPressed` | ênfase/pressed | `#20C987` |
| `_rpgXp` | XP, nível, recompensa (roxo) | `#8B5CF6` |
| `_textPrimary` | título/conteúdo | `#F7F9F8` |
| `_textSecondary` | metadados | `#A7B0AD` (`#D5DDD9` em alto contraste) |
| `_stateWarning` | atenção (`colorScheme.stateWarning`, extensão) | `#F4B740` |
| `_stateDanger` | destrutivo (`colorScheme.error`) | `#F45B69` |
| `_divider` | separadores/`outline` | `#2A302F` (`#75807B` em alto contraste) |

`buildCalisthenicsRpgTheme({bool highContrast = false})` monta um único
`ColorScheme.fromSeed` escuro e ajusta `onSurfaceVariant`/`outline`
quando `highContrast` é verdadeiro (mais contraste, mesma paleta — não
existe um segundo tema totalmente separado). Cards com raio 20, botões
(`Filled`/`Outlined`) com raio 16, `NavigationBar` destaca só o item
ativo em verde (ícone e rótulo), inativos em `onSurfaceVariant`.

Acessibilidade de fonte/movimento não vive no tema, e sim em
`lib/app/app.dart`: o `MaterialApp.builder` lê `UserSettings.textScale`/
`reduceMotion` (Definição > Aparência e acessibilidade) e aplica via
`MediaQuery` (`TextScaler.linear`, clamp 0.8–2.0, e
`disableAnimations`).

## Navegação principal

Quatro abas persistentes (`MainShell`, ver `ARCHITECTURE.md`): **Treino**
(cronômetro/halter), **Descobrir** (bússola), **Relatório** (gráfico de
barras), **Definição** (engrenagem). Estado e posição de rolagem
preservados via `IndexedStack` — validado em
`test/app/main_shell_test.dart` (busca digitada em Descobrir sobrevive a
trocar de aba e voltar) e em `test/app/responsive_visual_test.dart`
(rolagem em qualquer aba, qualquer tamanho de tela/escala de fonte, sem
overflow).

## Componentes reutilizáveis existentes

Nomes reais no código (nem todos os sugeridos pela especificação viraram
componentes formais — alguns papéis ficaram como widgets privados dentro
da própria tela, por serem usados uma única vez):

- `XpLevelBadge` (`features/rpg/presentation/xp_level_badge.dart`) —
  nível, XP atual/necessário, barra de progresso animada. Reusado em
  `JourneyScreen`, `TrainingPlanScreen` e `ReportScreen`.
- `XpEvolutionChart` (`features/rpg/presentation/xp_evolution_chart.dart`)
  — gráfico de barras (7 dias), Flutter puro
  (`TweenAnimationBuilder`, sem pacote de charting). Reusado em
  `JourneyScreen` e `ReportScreen`. Cada barra reserva
  `chartHeight + 44` de altura (valor acima do texto + barra + rótulo do
  dia — ver nota de bug corrigido em `HANDOFF_CLAUDE.md`).
- `ExerciseMedia`/`ExerciseMediaPlaceholder`/`PatternIllustration`
  (`shared/presentation/`) — mídia real (foto) quando associada no
  catálogo de 195 imagens, com fallback automático (via `errorBuilder`)
  para ilustração animada por família de movimento.
- `EmptyStateCard` (`shared/presentation/empty_state_card.dart`) —
  ícone + título + mensagem + ação opcional; usado em todo estado vazio
  real (Relatório sem histórico, sem recordes, sem plano, peso/IMC ainda
  não implementado etc.) — nunca dado fictício no lugar.
- `FadeSlideIn` (`shared/presentation/fade_slide_in.dart`) — entrada
  animada escalonada por índice, usada nos cards da Jornada.

## Aba Treino (`JourneyScreen`)

Ordem implementada (`features/journey/presentation/journey_screen.dart`),
seguindo a ordem recomendada do documento de redesenho §4.1:

1. cabeçalho "Jornada" (AppBar);
2. `XpLevelBadge` (nível/XP);
3. card de sessão pausada, só se existir (`_PausedSessionCard`) —
   exercício e série atuais, progresso (`X de Y séries concluídas`),
   horário do último salvamento (derivado do `SetLogRecord.completedAt`
   mais recente, ou `startedAt` da sessão se nenhuma série foi
   registrada ainda), botão "Continuar treino";
4. próximo treino/missão (`_NextSessionCard`);
5. frequência semanal (`_StatusCard`) — mostra também "Meta formalizada:
   Seg, Qua, Sex" quando o usuário já escolheu dias específicos em
   Definição;
6. progresso para a próxima habilidade;
7. missões de hoje + missões da semana (`MissionList`);
8. sequência atual (`_StreakCard`) — dias consecutivos com sessão
   concluída, derivado só de `workout_session_records.completedAt`
   (`core/time/date_period.dart#currentStreak`), sem nenhum estado de
   "desafio" separado (não existe modelo de desafio multi-dia no app —
   ver `IMPLEMENTATION_BACKLOG.md`);
9. `XpEvolutionChart` (7 dias);
10. botão "Ver plano da semana completo".

Depois do botão do plano, "Histórico recente" (últimos lançamentos de
XP) continua existindo como conteúdo suplementar — não faz parte da
lista de 10 itens da especificação, mas não foi removido (funcionalidade
já existente antes desta sessão).

**Divergência deliberada:** o card "Treino em destaque" (atalho para
`WorkoutCatalogScreen`) foi removido nesta sessão. Ele existia antes de
a aba Descobrir existir como navegação própria; hoje é redundante com
ela, e mantê-lo duplicaria o mesmo destino em dois lugares.

## Aba Descobrir (`DiscoverScreen`)

Filtros reais implementados: busca por texto (treino/exercício/padrão),
nível (treinos), duração em faixas (`< 10`, `10–20`, `20–40`, `> 40 min`,
treinos), padrão de movimento (exercícios, chips por padrão presente no
catálogo), equipamento (`Equipment.none` = "sem equipamento", ou um item
específico), tipo de medição (repetições/tempo). Seções: "Treinos
disponíveis" (filtrados), "Recentes" (exercícios de sessões concluídas
de verdade, só quando a busca está vazia), catálogo de exercícios
agrupado por padrão de movimento (quando nenhum padrão específico está
selecionado) ou lista plana em "Resultados" (quando há busca/filtro de
padrão ativo).

Chip "Favoritos" existe, mas fica **desabilitado** (`onSelected: null`,
com tooltip explicando que ainda não está disponível) — não há
persistência de favoritos implementada; mostrar o chip como se
funcionasse seria fingir uma funcionalidade que não existe.

**Não implementado desta especificação** (seção 5 do documento de
redesenho), por falta de dado real que sustente a seção sem inventar
conteúdo: "Alongar e aquecer", "Desafios", "Progressões de habilidade",
"Para iniciantes/Intermediários/Avançados" como seções dedicadas (o
catálogo de treinos hoje tem só uma entrada, "Treino A · Fundação" —
ver `IMPLEMENTATION_BACKLOG.md`), bloqueio/desbloqueio de conteúdo por
nível de capacidade (não existe mecânica de "conteúdo trancado" na
Descobrir — os exercícios/treinos já filtram por equipamento/tipo, mas
nenhum aparece "bloqueado").

## Aba Relatório (`ReportScreen`)

Seletor de período (7/30/90 dias, todo o período) no topo, depois:
`XpLevelBadge`, grade de métricas (treinos, minutos, séries, repetições,
XP, sequência atual), aderência ao plano (sessões reais no período vs.
meta de dias/semana do plano ativo), evolução de XP (7 dias, mesmo
componente da Jornada), recordes pessoais (maior número de repetições
por exercício, via `bestRepsByExerciseProvider`), volume por padrão de
movimento (soma de repetições por padrão, no período selecionado),
card explícito "Peso, altura e IMC — ainda não disponível nesta versão"
(`EmptyStateCard`, sem inventar dado), histórico de sessões (data,
horário, duração, XP da sessão quando existe), progressão de
habilidades.

## Aba Definição (`SettingsScreen`)

Seções: Perfil e avaliação (nome editável, dias/semana + meta de dias
específicos da semana editável, "Refazer avaliação física" desabilitado
com explicação), Treino (som/vibração/voz/início automático de descanso
via `SwitchListTile`; contagem regressiva editável com diálogo de
slider 0–10s, conectada de verdade ao `TimedSetPlayer`; "Descanso
padrão" ainda só exibido, não editável — ver nota abaixo), Aparência e
acessibilidade (alto contraste, reduzir animações, escala de texto via
slider, idioma fixo), Dados (uso de armazenamento real — soma do banco
Drift + JSON de preferências —, exportar dados desabilitado, reiniciar
progresso), Sobre e suporte (versão, privacidade).

**Por que "Descanso padrão" não foi conectado ao player nesta sessão:**
o catálogo de exercícios já tem `restSeconds` por exercício, com pelo
menos um valor deliberadamente diferente do padrão (45s em vez de 60s
para um exercício específico de `core_anti_extension`). Substituir esse
valor pelo ajuste global do usuário descartaria uma tunagem já existente
sem necessidade real de dado adicional — decisão de escopo, não
esquecimento. Ver `IMPLEMENTATION_BACKLOG.md`.

## Regras de interface aplicadas

- Raio de card 16–24px (20px na prática) — cumprido via `CardThemeData`
  central, sem raio hardcoded espalhado pelas telas.
- Verde nunca usado para erro, vermelho nunca usado para ação normal —
  `colorScheme.error` é usado exclusivamente nas ações destrutivas
  (reset de progresso).
- Estados de carregamento/vazio/erro em toda tela principal — `.when()`
  do Riverpod em todas as telas das quatro abas, `EmptyStateCard` para
  vazio, botão "Tentar novamente" para erro.
- Validado automaticamente sem overflow em tela pequena (360×690) e
  grande (1024×1366), escala de fonte 1.0×/1.4×/2.0× e tema de alto
  contraste — `test/app/responsive_visual_test.dart` (5 cenários,
  cobrindo as quatro abas em cada um). Não há screenshot manual nem
  teste golden de imagem: este ambiente não tem emulador móvel, projeto
  Web/Windows desktop configurado nem ferramenta de automação de
  browser instalada — decisão registrada com o usuário, que optou por
  manter só a validação automatizada.
