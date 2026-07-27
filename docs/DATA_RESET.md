# Reinício de progresso e métricas

**Última atualização:** 2026-07-27

Comportamento real de "Reiniciar progresso e métricas" (Definição >
Dados), como implementado em
`lib/features/settings/data/progress_reset_service.dart` e
`lib/features/settings/presentation/settings_screen.dart`
(`ResetProgressDialog`). Esta é uma ação diferente de "excluir conta" —
não há conta/login neste MVP (ADR-0006), então não existe nem pode
existir confusão entre as duas.

## O que é apagado

Uma única transação Drift (`_db.transaction()` em
`ProgressResetService.reset()`) apaga, nesta ordem:

1. `active_timed_set_records` (série por tempo em andamento);
2. `set_log_records` (todas as séries registradas);
3. `workout_session_records` (todo histórico de sessões);
4. `xp_ledger_records` (todo o ledger de XP — nível volta a 0 porque é
   sempre derivado da soma, nunca um campo mutável separado);
5. `capability_estimate_records` (todas as colocações/avaliações
   físicas, dos 5 padrões);
6. `training_plan_records` (plano semanal ativo);
7. `outbox_events` (fila de sincronização reservada — vazia hoje, mas
   limpa por completude);
8. `body_metric_records` (histórico de peso — métrica corporal, não
   preferência).

## O que é preservado

- `safety_screenings` — triagem/consentimento de segurança.
- `training_preference_records` — agenda, local, equipamento, a meta de
  dias específicos da semana (`preferredWeekdaysJson`) **e** a altura
  (`heightCm`) — é preferência/perfil pessoal, não progresso. O peso
  (`body_metric_records`) é diferente: é histórico de métrica corporal,
  então é apagado (ver "O que é apagado" acima).
- `favorite_records` — favoritos de treino/exercício na Descobrir; é
  preferência pessoal (marcar o que se gosta), não progresso, mesmo
  espírito da altura acima.
- `calisthenics_rpg_settings.json` — nome, som, voz, vibração,
  acessibilidade, idioma. Fica inteiramente fora do banco Drift, então o
  reset (que só opera sobre o banco) nunca o toca — nem precisa de
  lógica explícita para "não apagar isso".
- Catálogo de exercícios/treinos e catálogo de mídia — dado estático em
  Dart/JSON, nunca esteve no banco.

## Depois do reset

- `appResetEpochProvider.bump()` incrementa um contador observado pelo
  `AppFlowGate`, forçando-o a reavaliar do zero.
- Como `capability_estimate_records` e `training_plan_records` ficam
  vazios, o `AppFlowGate` naturalmente volta para a etapa de avaliação
  física (`AssessmentSkipTestScreen`) — sem lógica de redirecionamento
  dedicada, é consequência direta de os providers que o gate observa
  passarem a retornar `null`.
- Todos os providers de progresso (missões, XP, frequência, evolução,
  relatório, sessão ativa) são invalidados explicitamente pelo diálogo
  de reset antes de fechar, para refletir o estado limpo imediatamente
  em qualquer aba já aberta.

## Confirmação (fluxo de três etapas, `ResetProgressDialog`)

1. Texto explicando o que será apagado e o que será preservado.
2. Caixa de seleção obrigatória: "Entendo que meu progresso não poderá
   ser recuperado sem um backup".
3. Campo de texto exigindo a palavra exata `REINICIAR` — o botão
   destrutivo "Apagar progresso" só habilita com os dois requisitos
   simultaneamente satisfeitos.

Confirmar abre uma segunda caixa de diálogo ("Confirmação final") com
"Voltar" (focado por padrão) e "Confirmar e apagar" — as duas ações
nunca dividem a mesma confirmação/botão.

## Requisitos técnicos cumpridos

- **Atômico:** tudo dentro de uma transação; uma falha em qualquer parte
  não deixa apagamento parcial (testado explicitamente, forçando uma
  exceção antes do commit).
- **Idempotente:** repetir a operação com o banco já vazio retorna
  `deletedRows: 0`, sem erro.
- **Bloqueio de toque duplo:** `_busy` desabilita o botão e mostra uma
  barra de progresso linear durante a operação; testado com um contador
  de chamadas (`_TrackedResetService`) provando que um segundo toque
  durante a operação não dispara uma segunda transação.
- **Falha não deixa o usuário sem dados:** se `reset()` lançar, o diálogo
  mostra a mensagem de erro e mantém o botão disponível para tentar de
  novo — nada foi apagado (a transação não commitou).

## Testes que provam este comportamento

- `test/features/settings/progress_reset_service_test.dart` — apaga
  progresso e preserva triagem/preferências; idempotente; falha força
  rollback total (nenhuma das 7 tabelas de progresso perde dados quando
  o `beforeCommitForTesting` força uma exceção).
- `test/features/settings/settings_screen_reset_test.dart` — fluxo
  completo pela interface: caixa de ciência, texto incorreto bloqueia,
  texto correto libera, confirmação final é uma etapa separada, toque
  duplo durante a operação não dispara segunda chamada, e o app navega
  de volta à tela inicial (equivalente ao `AppFlowGate` recomeçando) com
  `appResetEpochProvider` incrementado.
