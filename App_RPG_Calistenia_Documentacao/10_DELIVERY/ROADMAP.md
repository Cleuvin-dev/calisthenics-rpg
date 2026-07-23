# Roadmap de Entrega

## 1. Fase 0 — Fundação e validação

Entregas:

- nome, identidade provisória e pesquisa com usuários;
- revisão por profissional de Educação Física;
- protótipo das jornadas;
- catálogo fundamental e critérios;
- arquitetura, CI e ambientes;
- modelo de dados e migrations iniciais;
- termos e privacidade em rascunho.

Saída: regras críticas revisadas e protótipo testado com pelo menos usuários representativos do nível básico.

## 2. Fase 1 — MVP funcional

Inclui:

- conta e perfil;
- triagem para adultos do público inicial;
- avaliação adaptativa;
- planos de 2, 3 e 4 dias, 15–60 min;
- trilhas fundamentais de empurrar, puxar, pernas e core;
- player offline;
- registro de séries, RPE, RIR e dor;
- adaptação básica;
- XP, nível, missões e uma campanha;
- histórico e atributos;
- notificações;
- painel mínimo de conteúdo/observabilidade.

Não inclui competição pública nem análise por câmera.

## 3. Fase 2 — Progressão completa

- planos de 5–6 dias e 90 min;
- trilhas de handstand, muscle-up, pistol, L-sit;
- objetivos simultâneos controlados;
- deload e detecção de platô;
- campanhas ramificadas;
- Boss Tests avançados;
- exportação e integrações básicas;
- assinatura premium.

## 4. Fase 3 — Habilidades avançadas

- planche, front/back lever, human flag, Nordic e dragon flag;
- confirmação de capacidade expirada;
- conteúdo avançado revisado;
- vídeo opcional para feedback técnico;
- ferramentas para revisão profissional;
- personalização maior.

## 5. Fase 4 — Social seguro

- amigos e grupos privados;
- desafios cooperativos;
- rankings segmentados e opt-in;
- moderação, denúncia e privacidade;
- antifraude ampliado;
- nenhuma pressão por volume perigoso.

## 6. Backlog posterior

- wearables;
- web para treinadores;
- marketplace de programas revisados;
- suporte a populações especiais após protocolos próprios;
- IA explicativa e recomendações assistidas;
- temporadas e eventos.

## 7. Épicos técnicos

| Épico | Dependência | Prioridade |
|---|---|---:|
| Segurança e consentimento | nenhuma | P0 |
| Catálogo versionado | conteúdo revisado | P0 |
| Avaliação | segurança + catálogo | P0 |
| Motor de treino | avaliação + regras | P0 |
| Sessão offline | plano | P0 |
| Backend idempotente | sessão | P0 |
| Progressão/domínio | sessões processadas | P0 |
| RPG | ledger + domínio | P1 |
| Notificações | plano/outbox | P1 |
| Admin de conteúdo | modelo/revisão | P1 |
| Social | privacidade/antifraude | P2 |
| Câmera/IA | consentimento/validação | P3 |

## 8. Definição de pronto por história

- requisito e critérios de aceite;
- comportamento offline e erro;
- acessibilidade;
- eventos/telemetria;
- testes automatizados;
- migration e RLS quando aplicável;
- conteúdo/revisão quando físico;
- documentação atualizada;
- nenhum segredo;
- observabilidade e rollback.

## 9. Piloto

Começar com público adulto geral e trilhas básicas. Medir:

- taxa de conclusão do onboarding;
- avaliações interrompidas e motivo;
- treinos difíceis/fáceis demais;
- substituições;
- dor por exercício/versão;
- aderência em 4 e 8 semanas;
- sincronizações falhas;
- progressões revertidas;
- compreensão de XP vs domínio.

Expansão depende dos dados e da revisão profissional, não apenas de calendário.

## 10. Riscos principais

| Risco | Mitigação |
|---|---|
| prescrição insegura | regras conservadoras + revisão + piloto |
| catálogo inconsistente | schema, versionamento e workflow editorial |
| gamificação compulsiva | streak saudável e limites de XP |
| fraude | backend autoritativo e confiança |
| perda offline | event log local e idempotência |
| complexidade precoce | motor determinístico no MVP |
| habilidade avançada cedo | dependências compostas e portões |
| mudança de regras | migrations, versões e auditoria |
