# Estratégia de Testes

## 1. Pirâmide

- muitos testes unitários para regras puras;
- testes de integração para banco/RPC/RLS/sincronização;
- testes de widget para estados críticos;
- poucos testes ponta a ponta dos fluxos essenciais;
- validação humana especializada para conteúdo físico;

## 2. Matrizes obrigatórias

Testar combinações de:

- nível: destreinado, iniciante, intermediário, avançado;
- frequência: 2–6 dias;
- duração: 15, 30, 45, 60, 90 min;
- equipamento: nenhum, elástico, barra, paralelas, completo;
- objetivo: geral e cada habilidade principal;
- conectividade: online, offline, intermitente;
- prontidão: normal, baixa, dor;
- histórico: novo, consistente, pausa, platô;
- acessibilidade: texto ampliado, leitor de tela, redução de movimento.

## 3. Testes unitários críticos

- colocação conservadora quando confiança baixa;
- exercício com dor não vira evidência;
- XP não libera nó;
- pré-requisitos compostos;
- duas confirmações em sessões distintas;
- deload não quebra streak;
- mudança de equipamento recalcula somente afetados;
- tempo curto remove acessórios antes do principal;
- limite de XP;
- saldo do ledger;
- expiração de capacidade;
- retorno após ausência.

## 4. Propriedades/invariantes

Usar testes baseados em propriedades quando possível:

- nenhuma saída contém exercício excluído;
- duração calculada não excede tolerância;
- nenhum nó dominado tem requisito obrigatório ausente;
- XP total corresponde ao ledger;
- processar N vezes equivale a processar uma vez;
- redução de prontidão nunca aumenta carga;
- uma regressão não apaga a conquista histórica;
- regras iguais + entradas iguais geram saída igual.

## 5. Integração/backend

- RLS entre dois usuários;
- tentativa de insert direto no ledger;
- duas finalizações concorrentes;
- timeout após commit e repetição;
- evento fora de ordem;
- migration up/down ou rollback definido;
- exercício aposentado no histórico;
- publicação sem revisão bloqueada;
- job repetido;
- exclusão de conta e retenção.

## 6. Offline

Casos:

1. iniciar e concluir totalmente offline;
2. matar app no meio da série;
3. reiniciar celular;
4. internet oscilar durante envio;
5. sincronizar em dois dispositivos;
6. servidor responder 500, 409 e timeout;
7. sessão processada, recibo não recebido;
8. catálogo atualizado antes da sincronização.

Aceite: nenhum set desaparece, nenhuma recompensa duplica e o estado é compreensível.

## 7. Segurança física

Testar que:

- triagem bloqueia corretamente conforme protocolo aprovado;
- dor interrompe exercício;
- sinal crítico encerra fluxo;
- habilidade avançada exige saída segura;
- equipamento ausente não produz improviso inseguro;
- prontidão baixa reduz, não aumenta;
- mensagens não prometem diagnóstico;
- descanso e deload não geram punição.

Esses testes devem ser aprovados pelo responsável de conteúdo.

## 8. UX e acessibilidade

- completar treino com uma mão e tela pequena;
- botão de dor sempre alcançável;
- uso sob luz externa;
- vídeos com legenda;
- mapa compreensível sem cor;
- timer com leitor de tela;
- texto em 200%;
- animações reduzidas;
- erro offline e recuperação claros.

## 9. Performance

- abrir treino cacheado rapidamente;
- mapa com centenas de nós sem travar;
- registrar série em poucos milissegundos localmente;
- fila com eventos acumulados;
- API sob pico após notificações;
- mídia em rede lenta;
- consumo de bateria durante sessão.

## 10. Segurança da informação

- SAST e análise de dependências;
- segredos no repositório;
- permissões de storage;
- rate limiting;
- abuso de IDs;
- exportação de dados;
- exclusão;
- logs sensíveis;
- tokens e sessão;
- revisão de RLS em toda migration.

## 11. Cenários E2E mínimos

1. novo usuário iniciante → avaliação → plano → treino offline → sincronização → XP;
2. usuário marca dor → alternativa/encerramento → sem domínio;
3. usuário domina um nó em duas sessões → desbloqueia próximo;
4. usuário pausa 30 dias → reavaliação curta → plano de retorno;
5. duas finalizações iguais → um único ledger;
6. equipamento removido → plano regenerado sem exercícios incompatíveis;
7. Boss Test adiado → streak preservado;
8. exclusão de conta.

## 12. Critério de lançamento

- zero falha crítica conhecida de segurança física ou RLS;
- 100% das operações de recompensa com teste idempotente;
- fluxos E2E essenciais aprovados em Android e iOS;
- conteúdo MVP revisado e assinado;
- crash-free e latência dentro das metas do piloto;
- plano de rollback e suporte pronto.
