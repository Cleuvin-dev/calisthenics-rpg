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

- segurança prevalece sobre gamificação;
- XP nunca libera capacidade física;
- domínio depende de critérios versionados;
- regras críticas e recompensas são calculadas no backend;
- toda operação crítica deve ser idempotente;
- RLS deve existir e ser testada;
- sessões devem funcionar offline;
- migrations e funções SQL precisam ficar versionadas no Git;
- não aplicar SQL manual em produção;
- não inventar regras ausentes: registre a decisão pendente;
- não prescrever conteúdo ainda não revisado;
- preserve alterações existentes do usuário;
- execute análise e testes proporcionais a cada mudança;
- atualize a documentação de status ao final de cada sessão.

Stack preferencial:

- Flutter/Dart;
- Supabase Auth/PostgreSQL/Storage/Edge Functions;
- Firebase Cloud Messaging somente para push;
- banco local SQLite/Drift ou alternativa justificada;
- ambientes separados e CI/CD.

Primeira entrega recomendada:

“Um adulto do público inicial cria conta, conclui triagem segura, informa agenda/equipamento, recebe uma colocação conservadora em um único padrão de empurrar e vê o resultado persistido.”

Para essa entrega:

1. crie ADRs das decisões necessárias;
2. modele migrations e RLS;
3. implemente domínio sem acoplamento à UI;
4. crie repositório local/remoto e estados offline;
5. implemente telas acessíveis;
6. adicione testes unitários, integração/RLS e fluxo principal;
7. documente arquivos alterados, comandos executados, riscos e próxima história.

Não implemente ainda XP, ranking, câmera, IA ou habilidades extremas. Primeiro prove segurança, versionamento, persistência e idempotência no menor fluxo vertical.

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

“Leia `USER_JOURNEYS`, `TECHNICAL_ARCHITECTURE`, `DATA_MODEL`, `BACKEND_RULES` e `TEST_STRATEGY`. Implemente o event log local, fila, finalização idempotente e recibo. Demonstre que repetir a sincronização não duplica XP nem sessão.”

### Implementar progressão

“Leia `SCORING_AND_PLACEMENT`, `PROGRESSION_RULES`, `SKILL_TREES` e `ECONOMY_AND_ANTI_ABUSE`. Implemente os estados de nó e duas confirmações, sem usar XP como requisito. Inclua migrations, RLS e testes.”

### Encerrar uma sessão de desenvolvimento

“Atualize `PROJECT_STATUS.md` com implementado, arquivos alterados, migrations, testes, pendências, riscos e próxima tarefa. Não marque como concluído o que não foi verificado.”
