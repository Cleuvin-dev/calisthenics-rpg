# Changelog

Formato: data, o que mudou, impacto. Para o "porquê" narrativo completo
de cada entrada, ver `PROJECT_STATUS.md`. Entradas anteriores a
2026-07-27 são resumidas a partir do histórico de commits e de
`PROJECT_STATUS.md` — não presenciadas por quem escreveu este arquivo.

## 2026-07-27 — Objetivo de treino, abas do plano, limpeza da mídia
(commit `753d58c`)

Quarto item da mesma sessão de continuidade, depois de peso/altura/IMC
e favoritos. Começou como uma reverificação da integração das 195
imagens (pedido repetido do usuário) e virou quatro entregas:

- **Auditoria da integração das 195 imagens**: já estava completa de
  uma sessão anterior (commit `5b9a84a`); corrigido `README.md` da
  raiz (tinha sido sobrescrito pelo README de um pacote de entrega) e
  removidos 7 arquivos de manifesto/checksum duplicados soltos na
  raiz do repositório (nunca chegaram a ser commitados).
- **Ilustração animada removida**: `PatternIllustration` (bonequinho
  de traços animado, usado como fallback quando não há foto real)
  deletado a pedido do usuário; `ExerciseMediaPlaceholder` agora mostra
  um ícone estático (`Icons.fitness_center`).
- **Plano da semana em duas abas**: "Próximo treino" (só a sessão
  pendente mais próxima, mesma resolução de `nextPendingSession` usada
  no card da Jornada) e "Semana completa" (comportamento antigo,
  todos os dias). Antes, `TrainingPlanScreen` sempre mostrava a semana
  inteira de uma vez.
- **Objetivo de treino** (força muscular/perder gordura/
  condicionamento, um único por vez): novo enum `TrainingObjective` em
  `TrainingPreferences` + coluna aditiva `objective`
  (`training_preference_records`, migração 9→10) + item em Definição >
  Perfil e avaliação. Muda a dose prescrita em
  `WeeklyPlanGenerator._doseFor` (`restSeconds`/`targetSets`;
  `weeklyPlanGeneratorRuleVersion` → `weekly-plan-v2`); aquecimento
  nunca é modificado.
- **2 bugs pré-existentes corrigidos** (achados testando o item
  acima): `_editWeekdays` (Definição) zerava a altura salva ao não
  repassar `heightCm`; `TrainingPreferencesRepository.latest()` não
  desempatava gravações com o mesmo `updatedAt` (sequência rápida de
  edições), agora desempata por `id DESC`.
- Instalado e verificado sem crash no aparelho físico
  (`7549GMFUDA4DKZW8`) via `flutter build apk --release` + `adb
  install -r` — só checagem de abertura, sem navegação manual pelas
  telas novas ainda.
- 206 testes automatizados (eram 197), todos passando; `flutter
  analyze` sem problemas.

## 2026-07-27 — Favoritos (Descobrir)

Segundo item escolhido pelo usuário do topo do backlog, logo após
peso/altura/IMC.

- **Banco (schemaVersion 8→9, aditiva):** tabela nova `favorite_records`
  (`itemType` — `workout`/`exercise` —, `itemSlug`, `createdAt`, chave
  única `(itemType, itemSlug)` para evitar duplicata). Testado em
  `test/core/database/migration_v9_test.dart` com um banco montado no
  formato real da v8.
- **Domínio** (`lib/features/discover/domain/favorite.dart`):
  `FavoriteItemType` (workout/exercise) e `favoriteKey` (chave composta
  para checar pertencimento em `Set<String>` sem consulta por item).
- **Repositório** (`FavoriteRepository.toggle`/`allKeys`): sem tabela
  separada por tipo — `workout` e `exercise` com o mesmo slug não
  colidem porque a chave é composta.
- **Descobrir:** botão de estrela (`_FavoriteButton`) em todo card de
  treino/exercício, inclusive na seção "Recentes" (reaproveita
  `_ExerciseCard`); chip "Favoritos" deixou de ficar desabilitado e
  agora filtra a lista de verdade.
- É preferência pessoal, não progresso — `ProgressResetService`
  deliberadamente não toca em `favorite_records`.
- 194 testes automatizados (eram 189), todos passando; `flutter
  analyze` sem problemas.

## 2026-07-27 — Peso, altura e IMC

Implementa o item do topo do backlog (`IMPLEMENTATION_BACKLOG.md`, P2):
o card "Peso, altura e IMC — ainda não disponível nesta versão" do
Relatório vira funcionalidade real.

- **Banco (schemaVersion 7→8, aditivo):** coluna nova `heightCm`
  (nullable) em `training_preference_records` — altura é perfil,
  sobrevive ao reset. Tabela nova `body_metric_records` (peso + data,
  editável/excluível, ao contrário dos ledgers append-only do projeto)
  — histórico de progresso, apagado pelo "Reiniciar progresso e
  métricas". Testado em `test/core/database/migration_v8_test.dart` com
  um banco montado no formato real da v7.
- **Domínio** (`lib/features/report/domain/body_metric.dart`): validação
  de faixa plausível (peso 20–300 kg, altura 100–250 cm) e cálculo de
  IMC/categoria — indicador geral, sem diagnóstico médico (texto
  explícito na UI).
- **Definição > Perfil e avaliação:** "Altura" editável (diálogo com
  validação) e "Peso e IMC" abrindo a tela de histórico.
- **Nova tela `BodyMetricScreen`** (`lib/features/report/presentation/`):
  resumo (atual/maior/menor/tendência + IMC), lista de pesagens com
  editar/excluir (excluir pede confirmação), botão flutuante para
  adicionar.
- **Relatório:** card "Peso, altura e IMC" agora mostra peso atual + IMC
  reais quando há registro, ou estado vazio com atalho "Registrar peso"
  quando não há.
- `ProgressResetService` passa a apagar `body_metric_records`; altura
  (preferência) continua preservada.
- 189 testes automatizados (eram 169), todos passando; `flutter
  analyze` sem problemas.

## 2026-07-27 — Continuação: quatro abas completas, correções de bugs reais

Sessão de continuidade a partir de `docs/HANDOFF_CLAUDE.md` (versão
anterior), implementando o que o handoff listava como pendente.

**Correções de bugs reais (não features):**
- `SettingsRepository.save()`: fallback de escrita direta se o
  `rename` do arquivo temporário falhar (defensivo; o comportamento
  padrão foi verificado seguro neste ambiente Windows).
- `test/app/main_shell_test.dart` travava indefinidamente —
  `NativeDatabase`/`Directory.systemTemp.createTemp()` rodavam fora de
  `tester.runAsync()` dentro da zona `FakeAsync` de `testWidgets`.
  Corrigido; mesma causa documentada em `ARCHITECTURE.md` para não ser
  redescoberta.
- `XpEvolutionChart`: `RenderFlex` estourava sempre que havia XP real no
  período (a barra reservava `chartHeight + 28` de altura, insuficiente
  para texto do valor + barra + rótulo do dia). Corrigido para
  `chartHeight + 44`. Nunca tinha sido exercitado com dados não-zero em
  teste automatizado antes desta sessão.
- `test/core/database/migration_v6_test.dart`: não criava
  `training_preference_records` no banco legado simulado, quebrando
  quando a migração v7 (nova nesta sessão) tentou alterar essa tabela.
  Corrigido criando a tabela legada no teste.

**Aba Treino (Jornada) reordenada** conforme
`APP_RPG_CALISTENIA_REDESENHO_NAVEGACAO_E_IMPLEMENTACAO.md` §4.1: nível/
XP → sessão pausada (novo card, com exercício/série atuais, progresso e
horário do último salvamento, tudo derivado de dados reais) → próximo
treino → frequência semanal (agora mostra a meta de dias formalizada) →
próxima habilidade → missões → sequência atual (novo, streak real
derivado de `workout_session_records`) → evolução de XP → botão do
plano completo. Removido o card "Treino em destaque", redundante com a
aba Descobrir.

**Aba Descobrir**: filtros reais de nível, duração (faixas), padrão de
movimento e equipamento completo (antes só um toggle "sem
equipamento"); seção "Recentes" com exercícios de sessões concluídas de
verdade; chip "Favoritos" explicitamente desabilitado.

**Aba Relatório**: `XpLevelBadge`, aderência ao plano (sessões reais vs.
meta semanal), evolução de XP (reaproveitando o componente da Jornada),
recordes pessoais, volume por padrão de movimento, XP por sessão no
histórico, card explícito "Peso/altura/IMC ainda não disponível".

**Aba Definição**:
- Nova coluna `preferredWeekdaysJson` em `training_preference_records`
  (migração aditiva v6→v7) — usuário escolhe dias específicos da semana
  como meta de treino; `daysPerWeek` passa a acompanhar a quantidade
  escolhida.
- "Contagem regressiva" virou editável (diálogo com slider 0–10s) e foi
  **conectada de verdade** ao `TimedSetPlayer` (antes era só um número
  estático que nunca influenciava o cronômetro).
- Novo tile "Uso de armazenamento", somando o tamanho real do banco
  Drift + JSON de preferências.

**Ícone do app**: `pubspec.yaml` (`flutter_launcher_icons`) passou a
usar `assets/images/icone.png`; ícones Android/iOS regenerados.

**Validação visual/responsiva**: `test/app/responsive_visual_test.dart`
novo — 5 cenários (celular pequeno em 1.0×/1.4×/2.0× de escala de
fonte, tablet grande, alto contraste), navegando pelas quatro abas e
rolando, sem overflow em nenhum. Screenshot manual não foi possível
neste ambiente (sem Web/Windows desktop configurados, sem toolchain
MSVC nem ferramenta de automação de browser) — decisão registrada com o
usuário de manter só a validação automatizada.

**Testes:** 91 → 169 testes automatizados (todos passando),
`flutter analyze` sem problemas em cada etapa.

## Antes de 2026-07-27 — redesenho de navegação em quatro abas

Implementação anterior (fora desta sessão de continuidade, herdada via
commit `4e974a3` e handoff): shell raiz com `IndexedStack` de quatro
abas (Treino/Descobrir/Relatório/Definição) substituindo a `JourneyScreen`
como tela única; tema central recebeu tokens para a barra de navegação,
alto contraste e escala de texto; abas Descobrir/Relatório/Definição
criadas pela primeira vez; serviço de reinício de progresso
(`ProgressResetService`) implementado com fluxo de confirmação em três
etapas. Detalhe completo (arquivos, decisões, o que ficou incompleto) em
`docs/HANDOFF_CLAUDE.md` (histórico, antes de ser reescrito por esta
sessão) e `docs/PROJECT_STATUS.md`.

## 2026-07-26 e anteriores

Ver `docs/PROJECT_STATUS.md` para o histórico completo pré-redesenho:
motor de treino determinístico, player de sessão offline (repetições e
duração), progressão/domínio, RPG/XP, missões diárias/semanais, tela
"Evolução", integração do catálogo de 195 imagens de exercício,
catálogo em camadas para 5 padrões de movimento, tema escuro/"game".
