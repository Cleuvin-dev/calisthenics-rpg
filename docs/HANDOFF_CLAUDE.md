# Prompt de continuidade para Claude Code

Você está continuando a implementação do projeto Flutter **App RPG
Calistenia**. Leia primeiro `APP_RPG_CALISTENIA_REDESENHO_NAVEGACAO_E_IMPLEMENTACAO.md`
(especificação do redesenho de navegação em quatro abas), depois
`docs/ARCHITECTURE.md`, `docs/UI_UX.md`, `docs/DATA_RESET.md`,
`docs/PROJECT_STATUS.md` e `docs/IMPLEMENTATION_BACKLOG.md`. Inspecione o
Git antes de editar e preserve qualquer trabalho não commitado — nada
desta sessão foi commitado ainda (o usuário commita manualmente).

Este handoff substitui a versão anterior (a implementação parcial da
Codex mencionada ali já foi completada e verificada nesta sessão — ver
abaixo). Não declare o escopo do documento de redesenho 100% concluído:
seções inteiras (Descobrir §5, Relatório §6) têm itens explicitamente
fora do escopo por falta de dado real (ver "Lacunas reais restantes").

## O que foi implementado e verificado nesta sessão

Ponto de partida: shell de quatro abas (Treino/Descobrir/Relatório/
Definição) e reset de progresso já existiam (herdados, não desta
sessão). Esta sessão fechou o que o handoff anterior listava como
pendente:

- **Correção de 3 bugs reais** (não features — ver `CHANGELOG.md` para
  detalhe técnico de cada um): gravação de JSON reforçada com fallback
  defensivo; `main_shell_test.dart` travava por I/O real fora de
  `tester.runAsync()`; `XpEvolutionChart` estourava layout com XP real
  no período (nunca tinha sido testado com dado não-zero antes).
- **Aba Treino (Jornada)** reordenada conforme a especificação §4.1;
  card de sessão pausada novo (dados reais); sequência atual nova
  (streak real); card redundante removido.
- **Aba Descobrir**: filtros reais (nível, duração, padrão, equipamento
  completo); seção "Recentes"; "Favoritos" honestamente desabilitado.
- **Aba Relatório**: aderência ao plano, recordes pessoais, volume por
  padrão, XP por sessão, nível/XP, card explícito de peso/IMC
  indisponível.
- **Aba Definição**: meta de dias de treino da semana (nova, com
  migração de banco); contagem regressiva editável e **conectada de
  verdade** ao player (antes era decorativa); uso real de armazenamento.
- **Ícone do app** trocado para `assets/images/icone.png`.
- **Validação visual/responsiva automatizada**: 5 cenários (tela
  pequena/grande, escala de fonte 1.0×/1.4×/2.0×, alto contraste) sem
  overflow em nenhuma das quatro abas.
- Toda a documentação em `docs/` (`ARCHITECTURE.md`, `UI_UX.md`,
  `DATA_RESET.md`, `CHANGELOG.md` novos; `PROJECT_STATUS.md` e
  `IMPLEMENTATION_BACKLOG.md` atualizados).

## Arquivos principais criados/modificados nesta sessão

- `lib/core/database/app_database.dart` (schemaVersion 6→7)
- `lib/core/database/tables/training_preference_records.dart` (coluna nova)
- `lib/core/time/date_period.dart` (`currentStreak` novo, compartilhado)
- `lib/features/discover/presentation/discover_screen.dart` (reescrito)
- `lib/features/journey/presentation/journey_screen.dart` (reordenado + cards novos)
- `lib/features/onboarding/domain/training_preferences.dart` /
  `data/training_preferences_repository.dart` (`preferredWeekdays`)
- `lib/features/report/data/report_repository.dart` /
  `presentation/report_screen.dart` (seções novas)
- `lib/features/rpg/presentation/xp_evolution_chart.dart` (bugfix de overflow)
- `lib/features/settings/data/settings_repository.dart` (fallback de escrita)
- `lib/features/settings/data/storage_usage_service.dart` /
  `storage_usage_providers.dart` (novos)
- `lib/features/settings/presentation/settings_screen.dart` (tiles novos)
- `lib/features/workout_session/presentation/timed_set_player.dart` /
  `workout_player_screen.dart` (contagem regressiva conectada)
- `pubspec.yaml` (ícone), `assets/images/icone.png` (novo)
- `test/app/responsive_visual_test.dart` (novo)
- `test/core/database/migration_v7_test.dart` (novo)
- `test/features/discover/discover_screen_test.dart` (novo)
- `test/features/onboarding/training_preferences_repository_test.dart` (novo)
- `test/features/report/report_screen_data_test.dart` (novo)
- `test/features/settings/settings_screen_reset_test.dart` (novo)
- `test/features/settings/settings_screen_weekdays_test.dart` (novo)
- `test/features/settings/storage_usage_service_test.dart` (novo)
- Mais correções pontuais em `test/app/main_shell_test.dart`,
  `test/core/database/migration_v6_test.dart`,
  `test/features/settings/settings_repository_test.dart`,
  `test/features/report/report_screen_test.dart`,
  `test/features/workout_session/timed_set_player_flow_test.dart`.

## Decisões arquiteturais tomadas

- Riverpod, Drift e `Navigator`/`IndexedStack` existentes mantidos —
  nenhum segundo padrão introduzido.
- Migração v7 aditiva (`m.addColumn`), testada com banco legado
  simulado no formato real da v6 — mesmo padrão já usado nas migrações
  anteriores.
- Meta de dias de treino formalizada em `TrainingPreferenceRecord`
  (preferência pessoal), não em `UserSettings`/JSON — é dado que o
  motor de plano (`daysPerWeek`) já consome, faz sentido ficar junto.
- "Descanso padrão" (Definição) **não** foi conectado ao player — ver
  "Lacunas reais restantes".
- Ícone de app trocado via `flutter_launcher_icons`, sem tocar em código
  de UI.

## Validações executadas

- `flutter analyze`: sem problemas, verificado repetidamente a cada
  etapa (não só ao final).
- `flutter test`: suíte completa passando integralmente ao final da
  sessão — ver o resultado exato (contagem de testes) no topo de
  `docs/PROJECT_STATUS.md`, seção desta data. Rodada muitas vezes ao
  longo da sessão (não só uma vez ao final), a cada mudança.
- `test/app/responsive_visual_test.dart`: 5/5 cenários passando
  (celular pequeno 360×690 em três escalas de fonte, tablet 1024×1366,
  alto contraste) — nenhum overflow nas quatro abas.
- Reset de progresso: cobertura de serviço (idempotência, rollback em
  falha, preservação seletiva) e de interface (fluxo completo de
  confirmação, toque duplo, redirecionamento) — ver `docs/DATA_RESET.md`.

## Observação do ambiente

`dart analyze`/`build_runner` funcionaram normalmente **fora do
sandbox** nesta sessão (rodando via Bash direto, não a ferramenta
restrita) — a limitação registrada no handoff anterior ("build_runner
ficou bloqueado no ambiente") não se repetiu aqui. `flutter run` para
Web/Windows desktop não está disponível: o projeto nunca teve
`flutter create --platforms=web,windows .` executado (só Android/iOS
existem), e não há toolchain MSVC nem `chromium-cli`/Playwright
instalados neste ambiente para rodar/screenshotar a Web. Isso bloqueou
apenas a validação visual manual (screenshots) — a validação
automatizada (`responsive_visual_test.dart`) cobre o mesmo critério de
aceite sem depender disso.

## Lacunas reais restantes

Nenhuma é bug — todas são escopo deliberadamente não coberto, com o
porquê registrado:

1. **"Descanso padrão" (Definição) não está conectado ao player.**
   Conectá-lo substituiria o `restSeconds` já curado por exercício no
   catálogo (um item usa 45s deliberadamente, não 60s) por um valor
   global — arriscaria descartar uma tunagem existente. Se for
   conectar, decidir primeiro: o valor do usuário deve ser um piso/teto,
   ou realmente substituir o catálogo por completo?
2. **Peso/altura/IMC** (Relatório e Definição §7.1) — sem modelo de
   dados nem persistência. Mostrado como estado vazio explícito, nunca
   fabricado. Precisa de nova tabela + migração + tela de CRUD (seção
   6.4 da especificação tem os requisitos completos).
3. **Seções "Alongar e aquecer", "Desafios", "Progressões de
   habilidade", "Para iniciantes/Intermediários/Avançados" (Descobrir)
   e conteúdo bloqueado por nível** — o catálogo de treinos hoje tem só
   "Treino A · Fundação"; construir essas seções sem mais conteúdo
   real seria só estados vazios repetidos. Ganha valor real quando o
   catálogo de treinos crescer (ver `IMPLEMENTATION_BACKLOG.md`).
4. **Favoritos** — chip existe desabilitado; falta decidir onde
   persistir (banco ou JSON) antes de implementar de verdade.
5. **Validação visual manual (screenshots)** — ver "Observação do
   ambiente" acima. Se este ambiente ganhar suporte Web/Windows desktop
   no projeto (`flutter create --platforms=...`) e uma ferramenta de
   automação de browser, vale revisitar.
6. Lacunas anteriores a esta sessão continuam registradas em
   `docs/IMPLEMENTATION_BACKLOG.md` (catálogo de exercícios mínimo,
   revisão profissional de conteúdo/mídia pendente, campanha/atributos
   RPG não implementados, etc.) — não foram tocadas nesta sessão.

## Sequência recomendada para continuar

1. `git status --short`, ler a documentação acima.
2. Escolher uma lacuna da lista acima com o usuário (a mais barata/
   valiosa costuma ser peso/altura/IMC ou favoritos — ambas exigem
   decisão de modelo de dados antes de codar).
3. Implementar em etapas pequenas e testáveis, seguindo o mesmo padrão
   já estabelecido: domínio puro → repositório/provider → tela → teste
   de cada camada → `flutter analyze` + `flutter test` completos antes
   de seguir para a próxima etapa.
4. Atualizar `docs/CHANGELOG.md` (nova entrada datada),
   `docs/PROJECT_STATUS.md` (seção narrativa) e este `HANDOFF_CLAUDE.md`
   ao final.

Preserve o tema escuro, verde como ação principal, roxo só para XP, e
todas as funcionalidades já existentes de Jornada, missões, plano,
sessão pausada e progressão.
