# Estratégia de Testes

## 1. Pirâmide

- muitos testes unitários para regras puras;
- testes de integração para SQLite/Drift, migrations, transações e repositórios;
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
- execução: modo normal, modo avião, app em segundo plano;
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
- cálculo de IMC no domínio e persistência local;
- IMC não altera prescrição sozinho;
- limites e tempo monotônico do cronômetro;
- pausa não conta como tempo ativo;
- reset muda a geração da jornada sem apagar o perfil local.
- repetições-alvo e realizadas permanecem separadas;
- concluir a mesma série duas vezes produz um único log;
- duração selecionada respeita mínimo, máximo e teto de segurança;
- fallback de mídia segue a ordem prevista;

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

## 5. Integração local

- isolamento entre perfis locais;
- widget tentando contornar o serviço do ledger;
- duas finalizações concorrentes;
- fechamento do app após commit e repetição;
- evento fora de ordem;
- migration local com backup/rollback definido;
- exercício aposentado no histórico;
- catálogo sem revisão bloqueado no build;
- rotina local repetida;
- reset da jornada e apagamento de dados locais.
- manifesto de mídia com path ausente, checksum inválido ou versão divergente;
- série por repetições confirmada com valor diferente do alvo;
- timer chegando a zero enquanto a UI está em segundo plano;

## 6. Persistência offline e ciclo de vida

Casos:

1. iniciar e concluir em modo avião;
2. matar app no meio da série;
3. reiniciar celular;
4. fechar após persistir e antes de atualizar a UI;
5. finalizar a mesma sessão duas vezes;
6. banco retornar erro e transação reverter;
7. sessão processada e recibo local não exibido;
8. catálogo do app ser atualizado antes de abrir uma sessão antiga.

Aceite: nenhum set desaparece, nenhuma recompensa duplica e o estado é
compreensível sem conexão.

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
- mídia estática com rótulo semântico;
- ausência de mídia com placeholder compreensível;
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
- decodificação de mídia local e limite de memória;
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
- revisão de schema e privacidade em toda migration local;
- validação de arquivo de backup/importação.

## 11. Cenários E2E mínimos

1. novo usuário iniciante → avaliação → plano → treino em modo avião → processamento local → XP;
2. usuário marca dor → alternativa/encerramento → sem domínio;
3. usuário domina um nó em duas sessões → desbloqueia próximo;
4. usuário pausa 30 dias → reavaliação curta → plano de retorno;
5. duas finalizações iguais → um único ledger;
6. equipamento removido → plano regenerado sem exercícios incompatíveis;
7. Boss Test adiado → streak preservado;
8. apagamento de todos os dados locais.
9. perfil físico → IMC → reavaliação → plano atualizado;
10. exercício por tempo → pausa → segundo plano → recuperação → persistência;
11. reinício da jornada → fila antiga rejeitada → nova avaliação obrigatória.
12. série por reps → ajustar realizado → toque duplo em concluir → um registro;
13. mídia ausente → placeholder → treino continua;
14. timer → bloquear tela → retornar → tempo ativo coerente;

## 12. Critério de lançamento

- zero falha crítica conhecida de segurança física ou perda de dados local;
- 100% das operações de recompensa com teste idempotente;
- fluxos E2E essenciais aprovados em Android e iOS;
- conteúdo MVP revisado e assinado;
- nenhuma mídia fundamental publicada sem revisão técnica e procedência;
- crash-free e latência dentro das metas do piloto;
- plano de rollback e suporte pronto.
