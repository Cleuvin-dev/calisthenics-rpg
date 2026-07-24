# Requisitos do Produto

## 1. Perfis e onboarding

### FR-001 — Perfil local

Na primeira versão, o usuário DEVE criar um perfil local sem login e deve poder
reiniciar a jornada, exportar e apagar os dados do aparelho. Conta,
autenticação e recuperação online pertencem à futura fase Supabase.

### FR-002 — Perfil físico e preferências

Coletar unidades, faixa etária, altura/peso opcionais quando necessários, experiência, objetivo, dias, duração, local, equipamentos e limitações declaradas.

### FR-003 — Objetivos

Objetivos disponíveis:

- iniciar com segurança;
- força geral;
- resistência muscular;
- composição corporal como objetivo comportamental, sem promessa clínica;
- primeira flexão/barra;
- muscle-up;
- handstand/handstand push-up;
- front lever/back lever;
- planche;
- pernas unilaterais e cadeia posterior.

O sistema deve limitar objetivos simultâneos incompatíveis e explicar prioridades.

## 2. Avaliação e plano

- **FR-010:** triagem obrigatória antes de testes.
- **FR-011:** selecionar regressão de teste por perguntas e tentativa técnica.
- **FR-012:** permitir pular teste, usando colocação conservadora.
- **FR-013:** registrar reps, tempo, RPE, RIR, dor, amplitude e qualidade.
- **FR-014:** calcular níveis independentes por padrão.
- **FR-015:** gerar plano para 2–6 dias e 15–90 minutos.
- **FR-016:** exibir motivo de cada exercício e relação com a habilidade-meta.
- **FR-017:** recalcular apenas o necessário após mudança de agenda/equipamento.

## 3. Execução

- **FR-020:** mostrar aquecimento, exercício, séries, descanso e saída segura.
- **FR-021:** aceitar reps/tempo/carga/assistência e percepção da série.
- **FR-022:** oferecer “muito fácil”, “adequado”, “difícil”, “não completei” e “dor”.
- **FR-023:** temporizador deve operar em segundo plano conforme limites do SO.
- **FR-024:** sessão deve funcionar integralmente offline e ser finalizada
  localmente de forma idempotente.
- **FR-025:** permitir substituir exercício mantendo padrão, dificuldade e restrições.
- **FR-026:** diferenciar sessão iniciada, pausada, abandonada e concluída.

## 4. Progressão

- **FR-030:** progressão depende de domínio, não de XP.
- **FR-031:** critérios devem ser cumpridos em duas exposições quando definido.
- **FR-032:** nenhuma habilidade avançada é liberada sem pré-requisitos de nós diferentes.
- **FR-033:** permitir regressão sem remover conquistas históricas.
- **FR-034:** detectar platô e propor ajuste/deload/reavaliação.
- **FR-035:** armazenar a versão da regra responsável por cada decisão.

## 5. RPG

- **FR-040:** conceder XP somente pelo serviço de domínio e ledger local; na
  futura fase Supabase, a autoridade passa para o backend.
- **FR-041:** possuir nível geral, atributos, títulos, conquistas e campanhas.
- **FR-042:** missões não devem recompensar treino excessivo.
- **FR-043:** Boss Test é adaptado ao nível e pode ser adiado sem punição.
- **FR-044:** cosméticos não alteram capacidade física.
- **FR-045:** ranking é opcional, segmentado e possui opção privada.

## 6. Histórico e análise

- calendário de sessões;
- evolução por exercício e atributo;
- recordes pessoais validados;
- mapa da árvore de habilidades;
- aderência semanal;
- distribuição de carga por padrão;
- explicação das adaptações;
- exportação dos dados.

## 7. Administração e conteúdo

- versionar exercícios e regras;
- revisar/publicar/despublicar conteúdo;
- simular prescrição antes de publicar;
- rollback de regra;
- feature flags;
- auditoria de alterações;
- painel de eventos de segurança e erros;
- não alterar retroativamente o histórico do usuário.

## 8. Requisitos não funcionais

| Código | Requisito |
|---|---|
| NFR-001 | Operações críticas idempotentes |
| NFR-002 | Dados privados isolados no banco local; RLS obrigatória na futura fase Supabase |
| NFR-003 | Segredos ausentes do aplicativo cliente |
| NFR-004 | Inicialização principal percebida em até 2 s em aparelho intermediário, salvo rede |
| NFR-005 | Registro local da sessão sem depender de conexão |
| NFR-006 | Acessibilidade: leitor de tela, contraste, texto ampliado e não depender só de cor |
| NFR-007 | Português do Brasil no lançamento e arquitetura pronta para i18n |
| NFR-008 | Métricas e logs sem expor dados sensíveis |
| NFR-009 | Regras determinísticas e testáveis no MVP |
| NFR-010 | Disponibilidade e recuperação definidas antes de produção |

## 9. Critérios globais de aceite

- dado o mesmo perfil e a mesma versão de regras, a prescrição é reproduzível;
- finalizar a mesma sessão várias vezes não duplica XP;
- marcar dor impede progressão automática daquele padrão;
- alterar equipamento não insere exercício incompatível;
- nível geral elevado não libera uma habilidade sem domínio;
- toda decisão mostra uma razão compreensível;
- conteúdo despublicado não aparece em novos planos, mas o histórico permanece íntegro.
