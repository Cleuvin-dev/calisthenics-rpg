# Telas e Fluxos

## 1. Navegação principal

Cinco destinos:

1. **Jornada:** fase, missão, próxima habilidade.
2. **Treino:** sessão de hoje e semana.
3. **Habilidades:** árvores e requisitos.
4. **Evolução:** atributos, histórico e recordes.
5. **Perfil:** personagem, equipamentos, privacidade e configurações.

## 2. Telas obrigatórias do MVP

### Acesso

- abertura;
- cadastro/login;
- recuperação;
- termos e consentimentos.

### Onboarding

- criação do personagem;
- objetivo;
- disponibilidade;
- local/equipamentos;
- experiência;
- triagem;
- tutorial de esforço/dor/técnica;
- avaliação;
- resultado;
- plano inicial.

### Jornada

- dashboard;
- campanha/fase;
- lista de missões;
- Boss Test;
- recompensa e level-up.

### Treino

- calendário semanal;
- detalhes da sessão;
- check-in;
- player de exercício;
- registro da série;
- descanso;
- substituição;
- fluxo de dor;
- resumo;
- sincronização pendente.

### Habilidades

- mapa geral;
- trilha individual;
- nó detalhado;
- pré-requisitos;
- evidências de domínio.

### Evolução

- atributos;
- gráfico por exercício;
- recordes;
- aderência;
- avaliações anteriores.

### Perfil/configurações

- dados;
- agenda;
- equipamentos;
- notificações;
- privacidade;
- exportar/excluir;
- ajuda e segurança.

## 3. Dashboard

Hierarquia:

1. estado de segurança ou sincronização, se existir;
2. missão principal: “Treino A — 32 min”;
3. próxima habilidade e progresso;
4. prontidão/check-in;
5. campanha e XP;
6. histórico curto.

Não sobrecarregar com rankings antes de mostrar a tarefa física real.

## 4. Player de treino

Elementos:

- nome e vídeo;
- série atual/total;
- alvo e variação;
- instruções curtas;
- critérios de repetição válida;
- cronômetro e descanso;
- ações “registrar”, “substituir”, “dor”, “encerrar”;
- indicador offline;
- acesso a áudio e tela sempre ativa opcional.

O botão de dor nunca fica escondido em menu.

## 5. Mapa de habilidades

Estados visuais e textuais:

- bloqueado: cadeado + requisitos;
- disponível: pode começar;
- em treino: progresso atual;
- candidato: aguarda confirmação;
- dominado: data e evidência;
- retorno: domínio histórico, confirmação atual pendente.

Cor não pode ser o único sinal.

## 6. Mensagens-chave

### Progressão

“Você atingiu o alvo uma vez. Repita em outra sessão com a mesma técnica para confirmar o domínio.”

### Regressão

“Hoje vamos reduzir a dificuldade para manter repetições de qualidade. Sua conquista continua registrada.”

### Dor

“Pare este exercício. Dor não é requisito de progresso. Responda duas perguntas para ajustarmos a sessão.”

### Offline

“Treino salvo neste aparelho. As recompensas serão calculadas quando a conexão voltar.”

### XP versus habilidade

“Seu nível de personagem aumentou. A próxima habilidade será liberada quando os requisitos físicos forem confirmados.”

## 7. Acessibilidade

- alvos de toque adequados;
- legendas e transcrição;
- instruções sem depender de áudio;
- suporte a texto ampliado;
- contraste AA como mínimo;
- reduzir animações;
- feedback háptico opcional;
- navegação por leitor de tela;
- linguagem simples e não humilhante;
- opção de ocultar peso, fotos e rankings.

## 8. Notificações

Permitidas:

- sessão planejada;
- confirmação de domínio disponível;
- plano ajustado;
- sincronização concluída;
- recuperação/descanso;
- campanha e missão não compulsiva.

Evitar culpa, urgência falsa ou mensagem do tipo “você perdeu tudo”.

## 9. Estados vazios e erros

Toda tela deve definir:

- carregando;
- vazio;
- erro recuperável;
- offline;
- acesso negado;
- conteúdo retirado;
- dados desatualizados;
- ação em processamento;
- sucesso idempotente.
