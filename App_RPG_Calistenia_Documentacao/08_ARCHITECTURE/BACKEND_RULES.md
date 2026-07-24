# Regras do Backend

> **Fase futura:** este documento não deve ser implementado na primeira versão.
> O MVP usa somente SQLite/Drift e serviços de domínio locais, conforme
> `TECHNICAL_ARCHITECTURE.md`. Estas regras serão usadas no roadmap Fase 4,
> quando o Supabase for conectado.

## 1. Operações críticas

### `start_assessment`

- valida triagem e protocolo;
- cria avaliação com versão;
- retorna testes elegíveis.

### `complete_assessment`

- valida tentativas;
- descarta evidência impeditiva;
- calcula capacidades e confiança;
- gera evento para plano inicial;
- é idempotente.

### `generate_training_plan`

- valida objetivos e agenda;
- lê capacidades, equipamento e restrições;
- aplica versão de regras;
- cria plano e explicações;
- não sobrescreve sessão iniciada.

### `finalize_workout_session`

Transação:

1. validar propriedade e idempotência;
2. persistir/confirmar eventos;
3. classificar integridade;
4. atualizar carga e capacidades;
5. criar evidências candidatas;
6. confirmar ou negar domínio;
7. gerar ledger de XP;
8. atualizar missões e conquistas;
9. criar recibo imutável;
10. enfileirar notificação;
11. commit e retorno do resumo.

### `claim_reward`

- valida janela e elegibilidade;
- usa chave única;
- registra ledger/inventário;
- retorna resultado anterior em repetição.

### `add_body_measurement`

- valida unidade e faixa plausível;
- converte para unidade canônica;
- recalcula IMC no servidor;
- mantém histórico;
- não altera capacidade, XP ou treino isoladamente;
- é idempotente por evento do cliente.

### `request_reassessment`

- valida triagem, prontidão e protocolo;
- impede duas avaliações ativas;
- cria uma nova avaliação versionada;
- preserva o histórico quando não houver reinício.

### `reset_user_journey`

- mantém a conta e autenticação;
- exige autenticação recente e confirmação forte;
- resolve o usuário exclusivamente por `auth.uid()`;
- executa limpeza e mudança de geração em transação;
- cria recibo idempotente;
- impede que eventos offline da geração anterior retornem;
- nunca é implementado como exclusões sequenciais pelo cliente.

## 2. Idempotência

Toda escrita do cliente usa chave previsível no escopo do usuário. A resposta processada deve ser recuperável. Erros após commit não podem gerar segunda recompensa.

## 3. Concorrência

- lock ou constraint por sessão;
- upsert controlado para eventos;
- ledger append-only;
- versão otimista do plano;
- conflito entre dispositivos retorna estado atual e não sobrescreve silenciosamente.

## 4. Jobs

- expirar capacidade estimada;
- criar missões e semanas;
- detectar sessões presas;
- reprocessar outbox;
- recalcular projeções do ledger;
- limpar mídia conforme retenção;
- gerar lembretes no fuso do usuário;
- relatórios de integridade e segurança.

Jobs devem ser idempotentes e observáveis.

## 5. RLS resumida

- usuário acessa somente linhas próprias;
- catálogo publicado é leitura pública/autenticada;
- conteúdo rascunho somente função administrativa;
- ledger não aceita insert/update pelo cliente;
- domínio não aceita update pelo cliente;
- triagem é privada e separada;
- tabelas de auditoria são backend-only;
- storage aplica pastas e políticas por proprietário.

## 6. Administração

Papéis separados:

- editor de conteúdo;
- revisor profissional;
- publicador;
- suporte com acesso limitado;
- segurança;
- administrador técnico.

Uma pessoa não deveria publicar conteúdo crítico que acabou de criar sem revisão, quando a operação permitir segregação.

## 7. Observabilidade

Métricas:

- sucesso/latência de finalização;
- tamanho/idade da fila offline;
- duplicatas evitadas;
- falhas por versão de regra;
- exercícios mais substituídos;
- marcações de dor por versão;
- regressões e abandonos;
- inconsistências de XP;
- notificações falhas.

Alertas devem evitar incluir texto sensível.
