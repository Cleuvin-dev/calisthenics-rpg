# Economia e Prevenção de Abuso

## 1. Autoridade

Na primeira versão, a interface envia fatos da sessão ao serviço de domínio
local, que valida e calcula recompensas dentro de uma transação. Widgets nunca
gravam “XP ganho” diretamente. Na futura fase Supabase, o backend assumirá essa
autoridade.

## 2. Idempotência

Cada sessão possui `client_session_id` UUID e cada evento, `event_id`. A finalização usa chave única por usuário/sessão. Repetir a chamada retorna o mesmo resultado.

## 3. Limites de XP

- teto de XP de conclusão por sessão;
- teto diário de XP repetível;
- domínio paga somente na primeira conquista válida;
- recorde exige melhoria mínima e contexto comparável;
- treinos extras podem ser registrados, mas não produzir farming ilimitado;
- missões locais têm janela, versão de regra e origem verificável; quando
  existir servidor, também terão validação autoritativa remota.

## 4. Sinais de integridade

- volume ou progressão incompatível com histórico;
- sessões sobrepostas;
- duração impossível;
- relógio local alterado;
- eventos fora de ordem;
- muitas sessões curtas idênticas;
- salto de vários nós sem evidência;
- repetição exata anormal em massa;
- dispositivo/conta com padrão automatizado.

Sinais não devem bloquear automaticamente atividade física legítima sem política clara. Podem reduzir confiança, retirar ranking e pedir confirmação.

## 5. Níveis de confiança da sessão

| Nível | Uso |
|---|---|
| Pessoal | aparece no histórico e gera XP básico limitado |
| Coerente | conta para progressão comum |
| Confirmada | duas exposições/revisão; conta para domínio avançado |
| Verificada | evidência adicional; elegível para competição específica |

## 6. Sanções proporcionais

1. explicar inconsistência e pedir correção;
2. excluir evento de ranking;
3. limitar recompensas repetíveis;
4. exigir reavaliação;
5. revisão administrativa;
6. suspender competição ou conta conforme termos.

Nunca apagar dados de treino silenciosamente.

## 7. Moeda virtual

Se houver moedas:

- concedidas por missões e campanhas;
- usadas apenas em cosméticos/conveniência não física;
- ledger imutável com transações de crédito/débito;
- saldo derivado do ledger;
- compras idempotentes;
- política explícita de reembolso;
- sem loot boxes no MVP.

## 8. Eventos auditáveis

- `session_processed`;
- `xp_granted`;
- `mastery_candidate_created`;
- `mastery_confirmed`;
- `reward_claimed`;
- `integrity_flag_added`;
- `admin_override`;
- `rule_version_changed`.
