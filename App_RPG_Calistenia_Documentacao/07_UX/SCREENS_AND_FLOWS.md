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
- catálogo visual de treinos com filtros por nível;
- detalhes da sessão;
- check-in;
- configuração prévia de durações permitidas;
- player de exercício;
- registro da série por repetições com confirmação manual;
- contador regressivo para séries por tempo;
- descanso;
- substituição;
- fluxo de dor;
- resumo;
- salvamento local pendente.

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
- acesso por engrenagem no canto superior direito da dashboard;
- perfil físico, peso, altura e IMC informativo;
- reavaliação física;
- agenda;
- equipamentos;
- recuperação e prontidão;
- preferências do cronômetro;
- notificações;
- privacidade;
- recomeçar jornada sem apagar o perfil local;
- exportar/excluir;
- ajuda e segurança.

Consultar `SETTINGS_AND_TIMED_EXERCISES.md` para fluxo, dados, segurança,
reinício transacional e critérios de aceite.

Consultar `VISUAL_ARCHITECTURE_AND_WORKOUT_PLAYER.md` para identidade visual,
cards, catálogo, player por repetições, player por tempo, descanso e resumo.

## 3. Dashboard

Hierarquia:

1. estado de segurança ou persistência local, se existir;
2. missão principal: “Treino A — 32 min”;
3. próxima habilidade e progresso;
4. prontidão/check-in;
5. campanha e XP;
6. histórico curto.

Não sobrecarregar com rankings antes de mostrar a tarefa física real.

## 4. Player de treino

Elementos:

- nome e mídia local;
- série atual/total;
- alvo e variação;
- instruções curtas;
- critérios de repetição válida;
- cronômetro e descanso;
- para exercícios por tempo, duração configurável em segundos ou minutos
  dentro dos limites da versão do exercício;
- ações “registrar”, “substituir”, “dor”, “encerrar”;
- indicador offline;
- acesso a áudio e tela sempre ativa opcional.

O botão de dor nunca fica escondido em menu.

Para repetições, o alvo permanece visível até o usuário confirmar a série.
O aplicativo salva separadamente repetições planejadas e realizadas e não
presume que a abertura da tela representa execução.

Para tempo, o player usa contagem preparatória, contador regressivo, pausa,
retomada, conclusão, interrupção e recuperação após fechamento. O desenho do
arco não é a autoridade do tempo.

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
- backup/exportação concluída, quando aplicável;
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
