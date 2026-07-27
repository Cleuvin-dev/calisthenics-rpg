# Prompt de continuidade para Claude Code

Você está continuando a implementação do projeto Flutter **App RPG
Calistenia**. Leia primeiro `docs/PROJECT_STATUS.md` (histórico
narrativo completo, seções mais recentes no final) e
`docs/IMPLEMENTATION_BACKLOG.md` (lista priorizada do que falta, sem
prosa). Depois, se for mexer nas telas de quatro abas, também
`APP_RPG_CALISTENIA_REDESENHO_NAVEGACAO_E_IMPLEMENTACAO.md`,
`docs/ARCHITECTURE.md`, `docs/UI_UX.md` e `docs/DATA_RESET.md`.
Inspecione o Git antes de editar e preserve qualquer trabalho não
commitado — **nada desta sessão foi commitado ainda** (o usuário
commita manualmente, geralmente no dia seguinte).

Este handoff substitui a versão anterior. Não declare o escopo do
documento de redesenho 100% concluído: seções inteiras (Descobrir §5.1,
Relatório) têm itens explicitamente fora do escopo por falta de
conteúdo/dado real (ver "Lacunas reais restantes").

## O que foi implementado e verificado nesta sessão (2026-07-27)

Ponto de partida: redesenho de quatro abas já completo (herdado de
sessão anterior — Jornada/Descobrir/Relatório/Definição, 169 testes).
O usuário escolheu, em sequência, dois itens do topo do backlog:

### 1. Peso, altura e IMC

- Banco (schemaVersion 7→8, aditivo): coluna `heightCm` em
  `training_preference_records` (perfil, sobrevive ao reset) + tabela
  nova `body_metric_records` (peso+data, editável/excluível — ao
  contrário dos ledgers append-only do projeto).
- Domínio puro `lib/features/report/domain/body_metric.dart`:
  validação de faixa plausível (peso 20–300 kg, altura 100–250 cm) e
  cálculo de IMC/categoria (indicador geral, sem diagnóstico médico).
- Definição > Perfil ganhou "Altura" (editável) e "Peso e IMC" (abre a
  tela nova `BodyMetricScreen`: resumo atual/maior/menor/tendência,
  histórico com editar/excluir com confirmação, botão flutuante para
  adicionar).
- Relatório: o card "ainda não disponível nesta versão" virou card
  real com peso atual + IMC (ou estado vazio com atalho "Registrar
  peso").
- `ProgressResetService` passa a apagar `body_metric_records`; altura
  continua preservada (é preferência, não progresso).

### 2. Favoritos (Descobrir)

- Banco (schemaVersion 8→9, aditivo): tabela nova `favorite_records`
  (`itemType` `workout`/`exercise` + `itemSlug`, chave única composta).
- `FavoriteRepository.toggle`/`allKeys` (`lib/features/discover/data/`)
  e `FavoriteItemType`/`favoriteKey` (`lib/features/discover/domain/`).
- Botão de estrela em todo card de treino/exercício da Descobrir
  (inclusive na seção "Recentes", que reaproveita `_ExerciseCard`);
  chip "Favoritos" deixou de ficar desabilitado e agora filtra de
  verdade.
- É preferência pessoal — `ProgressResetService` deliberadamente não
  foi alterado (a tabela nunca é tocada pelo reset).

Ambos os itens têm detalhe técnico completo em `docs/PROJECT_STATUS.md`
(seções "Peso, altura e IMC" e "Favoritos", nesta ordem, perto do
final) e entradas próprias em `docs/CHANGELOG.md`.

## Arquivos principais criados/modificados nesta sessão

- `lib/core/database/app_database.dart` (schemaVersion 7→9, duas
  migrações novas)
- `lib/core/database/tables/body_metric_records.dart`,
  `favorite_records.dart` (novos)
- `lib/core/database/tables/training_preference_records.dart`
  (`heightCm` novo)
- `lib/features/onboarding/domain/training_preferences.dart` /
  `data/training_preferences_repository.dart` (`heightCm`)
- `lib/features/report/domain/body_metric.dart`,
  `data/body_metric_repository.dart`, `data/body_metric_providers.dart`,
  `presentation/body_metric_screen.dart` (todos novos)
- `lib/features/report/presentation/report_screen.dart`
  (`_BodyMetricsCard` real)
- `lib/features/discover/domain/favorite.dart`,
  `data/favorite_repository.dart`, `data/favorite_providers.dart`
  (todos novos)
- `lib/features/discover/presentation/discover_screen.dart`
  (`_FavoriteButton`, chip habilitado)
- `lib/features/settings/presentation/settings_screen.dart` ("Altura",
  "Peso e IMC")
- `lib/features/settings/data/progress_reset_service.dart` (apaga
  `body_metric_records`)
- Testes novos: `test/core/database/migration_v8_test.dart`,
  `migration_v9_test.dart`; `test/features/report/
  body_metric_repository_test.dart`, `body_metric_test.dart`,
  `body_metric_screen_test.dart`; `test/features/discover/
  favorite_repository_test.dart`; `test/features/settings/
  settings_screen_height_test.dart`. Testes existentes atualizados:
  `training_preferences_repository_test.dart`, `report_screen_test.dart`,
  `report_screen_data_test.dart`, `progress_reset_service_test.dart`,
  `discover_screen_test.dart` (o teste antigo do chip desabilitado foi
  substituído por dois novos, já que o comportamento mudou de
  propósito).
- Documentação: `docs/CHANGELOG.md`, `docs/DATA_RESET.md`,
  `docs/UI_UX.md`, `docs/IMPLEMENTATION_BACKLOG.md`,
  `docs/PROJECT_STATUS.md` (todos atualizados).

## Validações executadas

- `flutter analyze`: sem problemas, verificado repetidamente ao longo
  da sessão.
- `dart format lib test`: sem mudanças pendentes (rodado ao final de
  cada entrega).
- `flutter test`: **194 passed, 0 failed** (eram 169 no início da
  sessão — 189 depois de peso/altura/IMC, 194 depois de favoritos).
- `dart run build_runner build`: OK nas duas vezes (gerou
  `body_metric_records`/`heightCm`, depois `favorite_records`).
- **Não testado no aparelho físico nesta sessão** (sem acesso ao
  `adb`) — ambos os itens ficam pendentes de verificação manual, junto
  dos três testes físicos já pendentes de sessões anteriores.

## Decisões arquiteturais tomadas

- `body_metric_records` é editável/excluível (UPDATE/DELETE por linha),
  diferente dos ledgers append-only do projeto (`xp_ledger_records`,
  `set_log_records`) — o usuário precisa poder corrigir uma pesagem
  errada (Relatório §6.4 pede isso explicitamente).
- Altura é preferência de perfil (`training_preference_records`,
  sobrevive ao reset); peso é histórico de métrica corporal
  (`body_metric_records`, apagado no reset) — mesma distinção que a
  especificação já fazia (§8.1 lista "peso e métricas corporais" entre
  o que se apaga).
- Favorito é preferência pessoal (like/bookmark), não progresso — não
  faz sentido zerar ao reiniciar a jornada. `favorite_records` nunca é
  tocada pelo reset, mesmo padrão de `training_preference_records`/
  `safety_screenings`.
- Chave composta `(itemType, itemSlug)` para favoritos, não duas
  tabelas separadas — `workout` e `exercise` com o mesmo slug não
  colidem, e um único `Set<String>` (`favoriteKeysProvider`) resolve
  pertencimento para toda a tela sem consulta por item.
- IMC nunca é calculado/mostrado sem peso **e** altura reais — nunca
  inventa dado (mesma filosofia de `EmptyStateCard` em todo o app).

## Lacunas reais restantes

Nenhuma é bug — todas são escopo deliberadamente não coberto, com o
porquê registrado:

1. **Catálogo de treinos maior** — hoje só "Treino A · Fundação"; sem
   isso, seções da Descobrir §5.1 ("Alongar e aquecer", "Desafios",
   "Para iniciantes/Intermediários/Avançados", conteúdo bloqueado por
   nível) continuam impossíveis de implementar sem inventar conteúdo.
   Provavelmente o próximo item de maior alavancagem.
2. **"Descanso padrão" (Definição) não está conectado ao player** —
   conectá-lo substituiria o `restSeconds` curado por exercício no
   catálogo por um valor global; decidir primeiro se deve ser
   piso/teto ou substituição completa antes de codar.
3. **Estimativa de gasto calórico** — agora que peso/altura existem
   (dado de entrada disponível), falta decidir a fórmula (MET por
   padrão de movimento? por exercício?).
4. **Objetivo de treino escolhido pelo usuário** (perder gordura/ganhar
   força/manter condicionamento) — pedido pelo usuário em 2026-07-27,
   mas com uma pergunta em aberto antes de codar: é multi-seleção
   ("e/ou" do pedido)? Ver `docs/IMPLEMENTATION_BACKLOG.md` P1 para o
   detalhe completo (o motor precisa classificar exercícios por
   objetivo, não só guardar a preferência).
5. **Nova curva de XP progressiva a 5%/nível** — pedida pelo usuário em
   2026-07-27, mas o próprio exemplo numérico dele tem uma
   inconsistência de arredondamento (315 não virou par, apesar da regra
   geral dizer "sempre arredondar para par") que precisa esclarecimento
   antes de implementar. Ver `docs/IMPLEMENTATION_BACKLOG.md` P1.
6. **3 testes manuais físicos pendentes** de sessões anteriores: modo
   avião explícito, tela bloqueada durante série por tempo, toque duplo
   físico deliberado — nenhum é bloqueio (cenários equivalentes já
   testados), mas nenhuma leva desde então (peso/altura/IMC, favoritos)
   foi verificada no aparelho.
7. **Revisão profissional de conteúdo/mídia** (Educação Física) —
   bloqueia publicação comercial; depende de validação externa, não é
   trabalho de código.
8. Lacunas anteriores continuam registradas em
   `docs/IMPLEMENTATION_BACKLOG.md` (catálogo de exercícios mínimo,
   campanha/atributos RPG, missões incompletas, progressão sem
   regressão/platô/deload, etc.) — não foram tocadas nesta sessão.

## Sequência recomendada para continuar

1. `git status --short` (nada deve estar commitado ainda — confirme
   antes de assumir que é limpo), ler `docs/PROJECT_STATUS.md` (seções
   finais) e `docs/IMPLEMENTATION_BACKLOG.md`.
2. Escolher o próximo item com o usuário — a lacuna 1 (catálogo de
   treinos maior) tem o maior efeito cascata sobre a Descobrir; as
   lacunas 4 e 5 exigem uma pergunta de esclarecimento antes de
   qualquer código.
3. Implementar em etapas pequenas e testáveis: domínio puro →
   repositório/provider → tela → teste de cada camada → `flutter
   analyze` + `flutter test` completos antes de seguir para a próxima
   etapa. `dart run build_runner build` sempre que uma tabela/coluna
   Drift mudar.
4. Atualizar `docs/CHANGELOG.md` (nova entrada datada),
   `docs/PROJECT_STATUS.md` (seção narrativa + "Próxima tarefa
   recomendada") e este `HANDOFF_CLAUDE.md` ao final.

Preserve o tema escuro, verde-menta como ação principal, roxo só para
XP, e todas as funcionalidades já existentes (Jornada, missões, plano,
sessão pausada, progressão, peso/altura/IMC, favoritos).
