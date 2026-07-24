# Prompt de Implementação para Claude Code ou Codex

Copie o prompt abaixo para iniciar o desenvolvimento depois de colocar toda a pasta `App_RPG_Calistenia_Documentacao` na raiz do repositório.

---

## Prompt

Você atuará como arquiteto e desenvolvedor principal deste aplicativo Flutter de calistenia gamificada.

Antes de alterar código:

1. leia `App_RPG_Calistenia_Documentacao/README.md`;
2. siga a ordem de leitura indicada no mapa da documentação;
3. inspecione o repositório, `AGENTS.md`, `CLAUDE.md`, configurações e estado do Git;
4. produza um relatório curto de lacunas entre código e documentação;
5. crie um plano incremental, sem tentar implementar o produto inteiro em uma única etapa;
6. não altere arquivos até apresentar o plano e identificar a primeira história vertical.

Regras obrigatórias:

- a primeira versão é totalmente offline e não se conecta ao Supabase;
- segurança prevalece sobre gamificação;
- XP nunca libera capacidade física;
- domínio depende de critérios versionados;
- regras críticas e recompensas são calculadas por serviços de domínio locais;
- toda operação crítica deve ser idempotente;
- todo o aplicativo deve funcionar em modo avião;
- migrations do SQLite/Drift precisam ficar versionadas no Git;
- widgets não acessam o banco ou ledger diretamente;
- usar UUIDs, UTC, versões de regra e `sync_state = local_only` para preparar
  a futura migração ao Supabase;
- não inventar regras ausentes: registre a decisão pendente;
- não prescrever conteúdo ainda não revisado;
- preserve alterações existentes do usuário;
- execute análise e testes proporcionais a cada mudança;
- atualize a documentação de status ao final de cada sessão.

Stack preferencial:

- Flutter/Dart;
- banco local SQLite/Drift ou alternativa justificada;
- assets locais versionados;
- testes automatizados e CI.

Não adicionar agora:

- Supabase;
- Firebase;
- login online;
- API;
- sincronização em nuvem;
- dependência de internet no fluxo principal.

Primeira entrega recomendada:

“Um adulto do público inicial cria um perfil local, conclui triagem segura,
informa agenda/equipamento, recebe uma colocação conservadora em um único
padrão de empurrar e vê o resultado persistido no aparelho.”

Para essa entrega:

1. crie ADRs das decisões necessárias;
2. modele migrations locais e constraints;
3. implemente domínio sem acoplamento à UI;
4. crie repositório local e estados persistentes;
5. implemente telas acessíveis;
6. adicione testes unitários, integração com SQLite/Drift e fluxo principal;
7. documente arquivos alterados, comandos executados, riscos e próxima história.

Não implemente ainda XP, ranking, câmera, IA ou habilidades extremas. Primeiro prove segurança, versionamento, persistência e idempotência no menor fluxo vertical.

Depois dessa primeira história, a entrega visual recomendada está especificada
em `07_UX/VISUAL_ARCHITECTURE_AND_WORKOUT_PLAYER.md`. Ela deve ser feita com
widgets nativos, não usando a prancha conceitual como uma única imagem.

Ao terminar a análise inicial, responda com:

- estado atual do projeto;
- lacunas prioritárias;
- arquitetura proposta;
- primeira história e critérios de aceite;
- arquivos que pretende criar/alterar;
- migrations previstas;
- testes previstos;
- riscos ou decisões que precisam de aprovação.

---

## Prompts posteriores sugeridos

### Implementar motor de treino

“Leia `04_TRAINING/*`, `05_EXERCISES/*` e os modelos técnicos. Implemente somente a geração determinística de uma semana de 2–4 dias, com testes de propriedades e explicações `reason_code`. Não implemente IA.”

### Implementar sessão offline

“Leia `USER_JOURNEYS`, `TECHNICAL_ARCHITECTURE`, `DATA_MODEL` e
`TEST_STRATEGY`. Implemente o event log local, finalização transacional
idempotente e recibo. Demonstre que finalizar repetidamente não duplica XP nem
sessão. Não adicione rede.”

### Implementar arquitetura visual e player

“Leia `05_EXERCISES/EXERCISE_SCHEMA.md`,
`05_EXERCISES/EXERCISE_MEDIA_GUIDE.md`,
`07_UX/VISUAL_ARCHITECTURE_AND_WORKOUT_PLAYER.md`,
`07_UX/SETTINGS_AND_TIMED_EXERCISES.md`, `DATA_MODEL` e `TEST_STRATEGY`.
Implemente dashboard, detalhe do treino e uma sessão local com Flexão
inclinada, Agachamento e Prancha. Em repetições, mantenha o alvo até a
confirmação e salve alvo/realizado. Em tempo, implemente 3-2-1, regressivo,
pausa, retomada, término e recuperação. Use assets locais com placeholder.
Não adicione rede, câmera ou IA.”

### Implementar progressão

“Leia `SCORING_AND_PLACEMENT`, `PROGRESSION_RULES`, `SKILL_TREES` e
`ECONOMY_AND_ANTI_ABUSE`. Implemente os estados de nó e duas confirmações, sem
usar XP como requisito. Inclua migrations locais e testes.”

### Encerrar uma sessão de desenvolvimento

“Atualize `PROJECT_STATUS.md` com implementado, arquivos alterados, migrations, testes, pendências, riscos e próxima tarefa. Não marque como concluído o que não foi verificado.”
