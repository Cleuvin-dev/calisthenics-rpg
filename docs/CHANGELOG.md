# Changelog

Formato: data, o que mudou, impacto. Para o "porquê" narrativo completo
de cada entrada, ver `PROJECT_STATUS.md`. Entradas anteriores a
2026-07-27 são resumidas a partir do histórico de commits e de
`PROJECT_STATUS.md` — não presenciadas por quem escreveu este arquivo.

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
