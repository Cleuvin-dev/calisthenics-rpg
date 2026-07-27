# App RPG Calistenia — Redesenho, Navegação e Plano de Implementação

**Versão:** 1.0  
**Data:** 27/07/2026  
**Status:** Especificação para implementação  
**Objetivo:** aproximar a organização e a riqueza funcional das telas de referência, preservando a identidade escura, gamificada e verde do aplicativo já construído.

---

## 1. Decisão visual

O aplicativo **não deve adotar o tema claro** das referências. As referências devem ser usadas para orientar hierarquia, navegação, variedade de conteúdo, filtros e composição dos cards.

Manter:

- fundo preto/grafite;
- cards em cinza muito escuro;
- verde como cor principal de destaque e ação;
- roxo reservado principalmente para XP, nível e elementos de progressão RPG;
- textos claros com contraste alto;
- identidade de jogo aplicada à calistenia;
- recursos já existentes de Jornada, nível, XP, missões, plano semanal, sessão pausada e progressão de habilidades.

Melhorar:

- navegação principal;
- organização do conteúdo;
- apresentação dos exercícios;
- legibilidade e contraste;
- consistência dos estados visuais;
- acesso a histórico, métricas, catálogo e configurações;
- redução de textos repetidos e cards excessivamente altos.

As imagens de referência **não devem ser copiadas nem incorporadas como assets**. Elas servem apenas como inspiração estrutural.

---

## 2. Navegação principal obrigatória

Criar uma barra inferior persistente com quatro abas:

| Aba | Função principal | Ícone sugerido |
|---|---|---|
| **Treino** | jornada, missão do dia, plano semanal e sessão em andamento | cronômetro ou halter |
| **Descobrir** | catálogo de treinos, exercícios, habilidades e filtros | bússola |
| **Relatório** | histórico, frequência, XP, evolução física e recordes | gráfico de barras |
| **Definição** | perfil, avaliação, preferências, dados e reinício do progresso | usuário ou engrenagem |

Requisitos:

- preservar o estado e a posição de rolagem de cada aba;
- impedir a recriação desnecessária das telas ao alternar abas;
- destacar somente a aba ativa em verde;
- ícones e textos inativos em cinza;
- respeitar `SafeArea`, teclado, gestos e diferentes tamanhos de tela;
- manter a barra visível nas telas-raiz e ocultá-la durante uma sessão de treino ativa;
- rotas internas devem permitir retorno previsível, sem empilhar telas duplicadas.

---

## 3. Sistema visual

### 3.1 Tokens sugeridos

Não espalhar cores, medidas e estilos diretamente pelos widgets. Centralizar em tema/tokens.

| Token | Uso | Valor de referência |
|---|---|---|
| `background` | fundo principal | `#070A09` |
| `surface` | cards principais | `#121715` |
| `surfaceElevated` | cards em destaque | `#18201C` |
| `primary` | ações e progresso principal | `#67D99B` |
| `primaryStrong` | botões/ênfase | `#39C979` |
| `xpAccent` | XP, nível e recompensa | `#8B5CF6` |
| `textPrimary` | título e conteúdo | `#F4F7F5` |
| `textSecondary` | metadados | `#A6AEA9` |
| `divider` | separadores | `#26302B` |
| `warning` | atenção | `#FFB547` |
| `danger` | exclusão/reinício | `#FF5D67` |

Os valores podem ser ajustados após inspeção do tema existente, mas o papel semântico de cada cor deve ser preservado.

### 3.2 Regras de interface

- raio padrão dos cards: 16 a 24 px;
- áreas tocáveis com pelo menos 48 × 48 dp;
- título de seção curto e sempre acompanhado de ação “Ver tudo” quando aplicável;
- botão principal verde com texto escuro e contraste suficiente;
- botão desabilitado visualmente distinto, mas ainda legível;
- não usar verde para erros nem vermelho para ações normais;
- roxo não deve competir com o verde em botões primários;
- evitar parágrafos longos na tela inicial;
- descrições extensas ficam nos detalhes do exercício;
- oferecer estados de carregamento, vazio, erro e conteúdo indisponível;
- usar imagens/GIFs próprios dos exercícios quando existirem e placeholder consistente quando faltarem;
- respeitar acessibilidade e escala de fonte, sem cortar textos.

---

## 4. Aba Treino

A aba Treino será a evolução da tela **Jornada** atual.

### 4.1 Ordem recomendada

1. cabeçalho “Jornada”;
2. card de nível e XP;
3. card de sessão pausada, caso exista;
4. missão/próximo treino;
5. frequência semanal;
6. progresso para a próxima habilidade;
7. missões de hoje;
8. desafio ou sequência atual;
9. gráfico compacto de XP dos últimos 7 dias;
10. botão para abrir o plano semanal completo.

### 4.2 Card de nível

Exibir:

- nível atual;
- XP atual;
- XP necessário para o próximo nível;
- barra de progresso;
- pequeno texto sobre o próximo desbloqueio.

Exemplo: `Nível 4 · 380/500 XP · Próximo desbloqueio: Flexão diamante`.

### 4.3 Próximo treino

Card principal em verde, com:

- nome da sessão;
- duração aproximada;
- foco do dia;
- quantidade de exercícios;
- CTA “Iniciar treino”.

Se houver sessão pausada, o CTA principal deve ser “Continuar treino”, exibindo:

- exercício atual;
- série atual;
- progresso da sessão;
- horário do último salvamento.

Não permitir iniciar uma segunda sessão sem antes confirmar o descarte ou a conclusão da anterior.

### 4.4 Missões

Cada missão deve apresentar:

- descrição objetiva;
- recompensa em XP;
- progresso numérico quando aplicável;
- estado pendente, em andamento, concluído ou resgatado;
- atualização automática conforme as ações reais do usuário.

Substituir círculos puramente decorativos por indicadores de progresso reais.

### 4.5 Plano semanal

Na lista resumida, mostrar somente:

- dia;
- nome da sessão;
- foco;
- duração;
- status.

Na tela completa, cada exercício deve ter um card visual com:

- imagem ou GIF maior e legível;
- nome;
- padrão de movimento/grupo muscular;
- séries e repetições **ou** duração;
- descanso;
- dificuldade;
- botão “Como executar”;
- status na sessão.

Evitar repetir a mesma explicação (“incluído para cobrir um padrão...”) em todos os itens. Essa justificativa pode ficar em uma seção única do plano ou nos detalhes.

### 4.6 Fluxo da sessão

Para exercício por repetição:

- mostrar meta da série;
- controles `–` e `+` para ajustar repetições;
- botão “Concluir série”;
- iniciar descanso após confirmação;
- permitir registrar esforço/dificuldade.

Para exercício por tempo:

- contador regressivo central;
- iniciar, pausar, continuar e reiniciar;
- aviso sonoro e/ou vibração nos segundos finais;
- início automático do descanso, conforme preferência;
- impedir que a navegação descarte o progresso silenciosamente.

Persistir a sessão após cada série para permitir retomada segura.

---

## 5. Aba Descobrir

Criar um catálogo escuro e gamificado inspirado na variedade das referências.

### 5.1 Conteúdo

- busca por treino, exercício ou habilidade;
- seção “Recomendado para você”;
- “Treinos rápidos”;
- “Alongar e aquecer”;
- “Por parte do corpo”;
- “Por padrão de movimento”;
- “Com equipamento” e “Sem equipamento”;
- “Desafios”;
- “Progressões de habilidades”;
- “Para iniciantes”, “Intermediários” e “Avançados”.

### 5.2 Filtros

- duração: `< 10 min`, `10–20 min`, `20–40 min`, `> 40 min`;
- nível;
- grupo muscular;
- equipamento disponível;
- objetivo;
- tipo: repetição, tempo, mobilidade ou isometria;
- favoritos;
- concluídos/recentes.

### 5.3 Cards

Cada card deve mostrar:

- imagem/GIF/placeholder;
- nome;
- duração estimada;
- nível;
- foco;
- equipamento;
- XP previsto quando aplicável;
- bloqueio e requisito de desbloqueio, se fizer parte da progressão RPG.

Treinos recomendados pelo plano não devem ser misturados com conteúdo bloqueado sem indicação clara.

### 5.4 Detalhes

Ao abrir um treino:

- resumo do objetivo;
- dificuldade;
- duração;
- lista dos exercícios;
- músculos/padrões envolvidos;
- equipamentos;
- estimativa de XP;
- botão “Iniciar”;
- opção “Adicionar ao meu plano”, quando válida.

Ao abrir um exercício:

- demonstração visual;
- instruções;
- erros comuns;
- regressão;
- progressão;
- contraindicações/observações gerais;
- tipo de medição;
- histórico pessoal daquele movimento.

---

## 6. Aba Relatório

A aba Relatório deve transformar os dados já registrados em informação útil, não apenas números soltos.

### 6.1 Resumo superior

Cards compactos para:

- treinos concluídos;
- minutos treinados;
- séries;
- repetições;
- XP obtido;
- sequência atual.

Permitir alternar período: `7 dias`, `30 dias`, `90 dias` e `Todo o período`.

### 6.2 Seções

- calendário/histórico de treinos;
- frequência semanal e aderência ao plano;
- evolução de XP;
- evolução de nível;
- progressão por habilidade;
- recordes pessoais;
- volume por grupo muscular/padrão;
- peso, altura e IMC, se o usuário optar por registrar;
- histórico detalhado de sessões.

### 6.3 Regras de clareza

- dias da semana devem ser inequívocos; usar `Seg`, `Ter`, `Qua`, `Qui`, `Sex`, `Sáb`, `Dom`;
- destacar o dia atual;
- gráficos devem ter legenda, unidade e período;
- histórico deve mostrar data, horário, sessão, duração, XP e resultado;
- estado vazio deve explicar como gerar o primeiro registro;
- IMC deve ser apresentado como indicador geral, sem diagnóstico médico.

### 6.4 Registro de peso

- permitir inserir peso e data;
- validar valores plausíveis e unidade;
- permitir editar/excluir registro individual com confirmação;
- mostrar tendência, maior, menor e valor atual;
- manter histórico separado do progresso de treino.

---

## 7. Aba Definição

Organizar por grupos.

### 7.1 Perfil e avaliação

- nome/apelido;
- avatar;
- objetivo;
- altura e peso;
- dias disponíveis;
- duração preferida;
- equipamentos;
- nível declarado;
- refazer avaliação física.

### 7.2 Treino

- descanso padrão entre séries;
- descanso entre exercícios;
- contagem regressiva;
- início automático;
- som;
- vibração;
- instruções por voz;
- manter tela ligada durante a sessão;
- unidade de peso;
- preferências de adaptação do plano.

### 7.3 Aparência e acessibilidade

- tema escuro como padrão e identidade principal;
- alto contraste;
- tamanho do texto;
- reduzir animações;
- idioma;
- volume dos avisos.

### 7.4 Dados

- exportar dados;
- importar/restaurar backup, quando suportado;
- consultar uso de armazenamento;
- **Reiniciar progresso e métricas**;
- excluir conta, se houver conta, como ação independente.

### 7.5 Sobre e suporte

- versão;
- documentação de privacidade;
- termos;
- enviar sugestão;
- relatar problema.

---

## 8. Reiniciar progresso e métricas

Adicionar na aba **Definição > Dados** uma opção visualmente perigosa chamada:

> **Reiniciar progresso e métricas**

Ela deve zerar o progresso do usuário para que ele possa começar novamente, mas **não deve apagar a conta nem preferências pessoais**.

### 8.1 Dados que devem ser apagados/zerados

- XP acumulado;
- nível e progresso de nível;
- missões e recompensas;
- sequência de dias;
- sessões concluídas e sessões em andamento;
- histórico de treinos;
- séries, repetições, duração e volume;
- recordes pessoais;
- progresso e domínio de habilidades;
- plano semanal ativo e adaptações derivadas do desempenho;
- avaliações físicas concluídas;
- histórico de peso e métricas corporais;
- desafios e conquistas;
- cache/estado derivado dessas métricas.

Depois do reinício:

- nível volta ao inicial;
- XP volta a zero;
- não existe sessão pausada;
- a Jornada mostra estado inicial;
- o usuário é direcionado para refazer a avaliação ou gerar novo plano;
- relatórios mostram estado vazio.

### 8.2 Dados preservados

- conta e identificador do usuário;
- nome, avatar e idioma;
- preferências de acessibilidade;
- configurações de som, voz e vibração;
- consentimentos e aceite de termos;
- dados de assinatura, se existirem;
- configurações técnicas que não representem progresso;
- catálogo de exercícios e conteúdo estático.

### 8.3 Confirmação obrigatória

Fluxo em três etapas:

1. tela explicando claramente o que será apagado e preservado;
2. caixa de seleção: `Entendo que meu progresso não poderá ser recuperado sem um backup`;
3. usuário digita `REINICIAR` e confirma no botão vermelho `Apagar progresso`.

Também incluir `Cancelar` como ação segura e inicialmente focada.

### 8.4 Requisitos técnicos

- executar a limpeza em uma única operação transacional/atômica sempre que o armazenamento permitir;
- criar backup/snapshot local antes da limpeza se já houver mecanismo de backup;
- se qualquer etapa falhar, não deixar o usuário em estado parcialmente zerado;
- limpar dados persistidos e caches relacionados;
- emitir evento interno de reinício para atualizar todas as telas;
- impedir duplo toque/requisição duplicada;
- exibir progresso durante a operação;
- registrar somente informação técnica necessária, sem conservar dados apagados em logs;
- incluir testes para dados preservados, dados apagados, falha e repetição da operação.

**Importante:** “Reiniciar progresso” e “Excluir conta” são ações diferentes e nunca devem compartilhar o mesmo botão ou confirmação.

---

## 9. Arquitetura e estado

A implementação deve primeiro identificar a arquitetura existente e adaptar-se a ela. Não introduzir um segundo padrão de gerenciamento de estado, navegação, persistência ou injeção de dependências.

Diretrizes:

- separar apresentação, domínio e persistência;
- usar uma fonte única de verdade para XP, nível, missões e métricas;
- derivar totais dos registros ou atualizar tudo em operação consistente;
- não duplicar cálculos em widgets;
- centralizar regras de progressão;
- definir identificadores estáveis para exercícios, treinos, missões e habilidades;
- preservar compatibilidade/migrar dados locais já existentes;
- preparar interfaces de repositório para futura sincronização, sem obrigar backend no MVP offline;
- não simular dados como se fossem reais;
- conteúdo ainda não implementado deve usar estado vazio/placeholder explícito.

---

## 10. Componentes reutilizáveis sugeridos

- `AppBottomNavigation`
- `SectionHeader`
- `RpgLevelCard`
- `PrimaryMissionCard`
- `PausedWorkoutCard`
- `WorkoutCard`
- `ExerciseCard`
- `ExerciseMedia`
- `FilterChipGroup`
- `MetricSummaryCard`
- `EmptyStateCard`
- `XpProgressBar`
- `MissionProgressTile`
- `WeeklyFrequencyCard`
- `WorkoutHistoryTile`
- `DangerZoneTile`
- `ResetProgressDialog/Flow`

Usar os nomes reais e convenções já existentes no projeto quando equivalentes.

---

## 11. Estados obrigatórios

Todas as telas principais precisam de:

- carregando;
- sucesso com dados;
- estado vazio;
- erro recuperável com tentar novamente;
- conteúdo/asset indisponível;
- dados migrados de versão anterior, se necessário.

A sessão de treino também precisa de:

- pronta;
- executando;
- pausada;
- descanso;
- concluída;
- abandonada com confirmação;
- recuperada após reiniciar o app.

---

## 12. Critérios de aceite

### Navegação e visual

- [ ] Existem quatro abas: Treino, Descobrir, Relatório e Definição.
- [ ] O tema permanece escuro e o verde é a cor principal.
- [ ] XP/progressão usa roxo de forma secundária e consistente.
- [ ] A troca de abas preserva estado e rolagem.
- [ ] Não há overflow em telas pequenas ou fonte ampliada.
- [ ] Botões ativos e desabilitados são distinguíveis.

### Treino

- [ ] Jornada atual foi preservada e reorganizada.
- [ ] Sessão pausada pode ser retomada.
- [ ] Exercícios têm mídia/placeholder, séries/repetições ou tempo e descanso.
- [ ] Exercícios temporizados usam contador regressivo.
- [ ] Progresso é salvo após cada série.

### Descobrir

- [ ] Catálogo possui busca, filtros e seções.
- [ ] Cards mostram dificuldade, duração, foco e equipamento.
- [ ] Detalhes de treino e exercício são acessíveis.

### Relatório

- [ ] Resumo e histórico usam dados reais.
- [ ] Gráficos informam período, unidade e legenda.
- [ ] XP, frequência e habilidades são coerentes com os registros.
- [ ] Estado sem histórico está tratado.

### Definição e reset

- [ ] Preferências foram organizadas por grupo.
- [ ] Existe “Reiniciar progresso e métricas”.
- [ ] A operação não exclui conta nem preferências.
- [ ] A confirmação exige ciência e digitação de `REINICIAR`.
- [ ] O reset é atômico/idempotente e atualiza todas as telas.
- [ ] Há testes demonstrando o que é apagado e preservado.

### Qualidade

- [ ] Análise estática passa sem novos erros.
- [ ] Testes existentes continuam passando.
- [ ] Novos fluxos têm testes relevantes.
- [ ] Não existem dados falsos apresentados como reais.
- [ ] A documentação do projeto foi atualizada após a implementação.

---

## 13. Ordem recomendada de implementação

1. auditoria da estrutura atual, rotas, estado, persistência e documentação;
2. tokens de tema e componentes-base;
3. shell com quatro abas;
4. refatoração da Jornada para a aba Treino;
5. fluxo visual da sessão e cards de exercício;
6. aba Descobrir;
7. aba Relatório;
8. aba Definição;
9. serviço transacional de reinício;
10. migração/compatibilidade dos dados;
11. testes, análise estática e validação manual;
12. atualização da documentação e registro de mudanças.

---

## 14. Arquivos de documentação que o agente deve atualizar

Ao final da implementação, o agente deve localizar e atualizar os arquivos equivalentes já existentes. Se não existirem, criar:

- `docs/PROJECT_STATUS.md` — estado atual real do aplicativo;
- `docs/CHANGELOG.md` — alterações implementadas, data e impacto;
- `docs/ARCHITECTURE.md` — navegação, estado, persistência e serviço de reset;
- `docs/UI_UX.md` — tema, tokens, componentes e regras das quatro abas;
- `docs/DATA_RESET.md` — dados apagados, preservados, confirmação e recuperação;
- `docs/HANDOFF_CLAUDE.md` — resumo objetivo para o Claude continuar o projeto.

O handoff deve informar:

- o que foi implementado;
- arquivos criados e modificados;
- decisões arquiteturais;
- migrações de dados;
- testes executados e resultados;
- pendências reais;
- limitações conhecidas;
- como executar e validar;
- nenhuma alegação de conclusão para funcionalidade apenas desenhada ou simulada.

---

# Prompt pronto para enviar ao Codex

Copie todo o conteúdo abaixo e envie ao Codex junto com o projeto e com este documento.

```text
Você deve implementar no projeto Flutter existente as alterações descritas no documento:
APP_RPG_CALISTENIA_REDESENHO_NAVEGACAO_E_IMPLEMENTACAO.md

OBJETIVO
Manter a identidade atual do App RPG Calistenia — fundo preto/grafite, cards escuros, verde como destaque principal e roxo para XP/progressão — e evoluir sua estrutura para quatro abas:
1. Treino
2. Descobrir
3. Relatório
4. Definição

Não transforme o app em tema claro. As telas de referência são inspiração de organização, conteúdo, filtros, relatórios e navegação, não assets para copiar. Preserve Jornada, nível, XP, missões, plano semanal, sessão pausada e progressão de habilidades.

REGRAS DE TRABALHO
1. Leia primeiro toda a documentação do repositório, incluindo AGENTS.md, CLAUDE.md e arquivos em docs/.
2. Inspecione o código, arquitetura, rotas, gerenciamento de estado, modelos, persistência e testes antes de editar.
3. Verifique o estado do Git e preserve alterações já existentes do usuário. Não faça reset, checkout destrutivo nem reescreva trabalho não relacionado.
4. Use a arquitetura e as bibliotecas já adotadas. Não introduza um segundo padrão de navegação, estado, persistência ou injeção de dependências.
5. Faça uma análise de impacto e um plano curto, depois implemente. Não pare apenas na documentação ou em mockups.
6. Reutilize/refatore componentes existentes. Centralize tema, cores, tipografia e espaçamentos.
7. Não apresente dados simulados como dados reais. Onde ainda não houver dados, implemente estados vazios corretos.
8. Preserve os dados locais existentes. Se o esquema precisar mudar, crie migração/compatibilidade segura.
9. Não remova funcionalidades atuais para simplificar a entrega.

ESCOPO OBRIGATÓRIO
- Criar barra inferior persistente com Treino, Descobrir, Relatório e Definição.
- Preservar estado e posição de rolagem das abas.
- Reorganizar Jornada como raiz de Treino.
- Melhorar cards de exercícios, com mídia/placeholder, séries/repetições ou duração, descanso, dificuldade e acesso à execução correta.
- Manter e validar contador regressivo nos exercícios por tempo.
- Criar Descobrir com busca, filtros e catálogo a partir dos dados reais disponíveis.
- Criar Relatório com histórico, frequência, XP, habilidades e métricas reais, incluindo estados vazios.
- Criar Definição com perfil/avaliação, preferências de treino, acessibilidade e dados.
- Implementar “Reiniciar progresso e métricas” exatamente conforme o documento.

RESET DE PROGRESSO — REQUISITO CRÍTICO
- Deve apagar XP, nível derivado, missões, sequência, sessões, históricos, recordes, habilidades, plano ativo, avaliações, métricas corporais, desafios e caches derivados.
- Deve preservar conta, identificador, perfil, idioma, acessibilidade, som/voz/vibração, consentimentos, assinatura e catálogo.
- Não pode ser confundido com excluir conta.
- Exigir explicação, caixa de ciência, digitação de REINICIAR e confirmação final em ação destrutiva.
- Executar de forma atômica e idempotente; em falha, não deixar dados parcialmente apagados.
- Após sucesso, invalidar/atualizar todo o estado e conduzir o usuário ao fluxo inicial de avaliação/novo plano.
- Adicionar testes que provem tanto o apagamento quanto a preservação correta.

QUALIDADE E VALIDAÇÃO
- Execute formatador, análise estática e testes automatizados do projeto.
- Corrija regressões causadas pelas mudanças.
- Adicione testes de navegação, persistência da sessão, estados vazios e reset.
- Faça validação visual nas resoluções disponíveis e verifique overflow, SafeArea, contraste, fonte ampliada e toque mínimo.
- Se algum recurso não puder ser concluído por ausência real de dados/assets, implemente a estrutura e o estado vazio/placeholder, documentando a limitação; não invente uma conclusão.

DOCUMENTAÇÃO E HANDOFF PARA O CLAUDE
Depois de implementar e validar, atualize a documentação existente. Localize os arquivos equivalentes e evite duplicações. Se não existirem, crie:
- docs/PROJECT_STATUS.md
- docs/CHANGELOG.md
- docs/ARCHITECTURE.md
- docs/UI_UX.md
- docs/DATA_RESET.md
- docs/HANDOFF_CLAUDE.md

No HANDOFF_CLAUDE.md registre:
- resumo do que foi realmente implementado;
- arquivos criados/modificados;
- decisões de arquitetura;
- modelos e migrações;
- comportamento do reset;
- comandos executados;
- resultados da análise e dos testes;
- pendências e limitações;
- passos exatos para executar e validar o app.

ENTREGA FINAL
Apresente:
1. resumo das mudanças;
2. arquivos principais alterados;
3. testes/comandos e resultados;
4. pendências reais;
5. confirmação dos documentos atualizados.

Implemente de ponta a ponta dentro do escopo. Não declare sucesso sem validar.
```

---

## 15. Resultado esperado

O aplicativo deve continuar reconhecível como o atual **App RPG Calistenia**, mas atingir uma organização mais completa e comercial:

- Jornada mais clara;
- catálogo acessível;
- relatórios úteis;
- configurações completas;
- exercícios visuais;
- progressão RPG preservada;
- controle seguro para começar do zero;
- documentação suficiente para Codex e Claude alternarem sem perder contexto.
