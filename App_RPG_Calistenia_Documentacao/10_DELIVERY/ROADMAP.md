# Roadmap de Entrega

## 1. Fase 0 — Fundação e validação

Entregas:

- nome, identidade provisória e pesquisa com usuários;
- revisão por profissional de Educação Física;
- protótipo das jornadas;
- direção visual original e protótipo do player;
- catálogo fundamental e critérios;
- pipeline de imagens/animações e revisão técnica;
- arquitetura, CI e ambientes;
- modelo de dados e migrations iniciais;
- termos e privacidade em rascunho.

Saída: regras críticas revisadas e protótipo testado com pelo menos usuários representativos do nível básico.

## 2. Fase 1 — MVP funcional

Inclui:

- perfil local, sem login;
- triagem para adultos do público inicial;
- avaliação adaptativa;
- planos de 2, 3 e 4 dias, 15–60 min;
- trilhas fundamentais de empurrar, puxar, pernas e core;
- player offline;
- player por repetições com confirmação manual;
- contador regressivo recuperável para exercícios por tempo;
- mídia local por versão e placeholder;
- registro de séries, RPE, RIR e dor;
- adaptação básica;
- XP, nível, missões e uma campanha;
- histórico e atributos;
- notificações locais;
- catálogo empacotado e diagnóstico local.

Não inclui Supabase, login online, sincronização, competição pública nem
análise por câmera.

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

## 5. Fase 4 — Supabase e nuvem

- Supabase Auth;
- vínculo do perfil local com a conta;
- importação idempotente do histórico;
- PostgreSQL e RLS;
- sincronização entre dispositivos;
- Storage e catálogo remoto;
- backend autoritativo para XP competitivo;
- backup em nuvem;
- notificações push quando necessárias.

## 6. Fase 5 — Social seguro

- amigos e grupos privados;
- desafios cooperativos;
- rankings segmentados e opt-in;
- moderação, denúncia e privacidade;
- antifraude ampliado;
- nenhuma pressão por volume perigoso.

## 7. Backlog posterior

- wearables;
- web para treinadores;
- marketplace de programas revisados;
- suporte a populações especiais após protocolos próprios;
- IA explicativa e recomendações assistidas;
- temporadas e eventos.

## 8. Épicos técnicos

| Épico | Dependência | Prioridade |
|---|---|---:|
| Segurança e consentimento | nenhuma | P0 |
| Catálogo versionado | conteúdo revisado | P0 |
| Avaliação | segurança + catálogo | P0 |
| Motor de treino | avaliação + regras | P0 |
| Sessão offline | plano | P0 |
| Arquitetura visual e player | sessão + catálogo | P0 |
| Mídia local e fallback | catálogo + revisão | P0 |
| Finalização local idempotente | sessão | P0 |
| Progressão/domínio | sessões processadas | P0 |
| RPG | ledger + domínio | P1 |
| Notificações locais | plano | P1 |
| Pipeline de conteúdo | modelo/revisão | P1 |
| Supabase e sincronização | MVP local estável | P2 |
| Social | Supabase/privacidade/antifraude | P3 |
| Câmera/IA | consentimento/validação | P3 |

## 9. Definição de pronto por história

- requisito e critérios de aceite;
- comportamento offline e erro;
- acessibilidade;
- eventos/telemetria;
- testes automatizados;
- migration local; RLS somente na Fase 4;
- conteúdo/revisão quando físico;
- documentação atualizada;
- nenhum segredo;
- observabilidade e rollback.

## 10. Piloto

Começar com público adulto geral e trilhas básicas. Medir:

- taxa de conclusão do onboarding;
- avaliações interrompidas e motivo;
- treinos difíceis/fáceis demais;
- substituições;
- dor por exercício/versão;
- aderência em 4 e 8 semanas;
- falhas de persistência e recuperação local;
- progressões revertidas;
- compreensão de XP vs domínio.

Expansão depende dos dados e da revisão profissional, não apenas de calendário.

## 11. Riscos principais

| Risco | Mitigação |
|---|---|
| prescrição insegura | regras conservadoras + revisão + piloto |
| catálogo inconsistente | schema, versionamento e workflow editorial |
| imagem ensinar técnica incorreta | revisão profissional por versão |
| pacote grande de mídia | WebP, orçamento de assets e carregamento sob demanda |
| gamificação compulsiva | streak saudável e limites de XP |
| fraude | sem competição pública antes do backend autoritativo |
| perda offline | event log local e idempotência |
| complexidade precoce | motor determinístico no MVP |
| habilidade avançada cedo | dependências compostas e portões |
| mudança de regras | migrations, versões e auditoria |
