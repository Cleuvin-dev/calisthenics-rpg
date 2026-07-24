# Sistema de RPG

## 1. Três progressões independentes

| Sistema | Representa | Libera exercício? |
|---|---|---|
| XP e nível | participação e jornada | Não |
| Atributos | retrato resumido da evolução | Não diretamente |
| Domínio de habilidade | capacidade comprovada | Sim |

## 2. XP base proposto

| Evento | XP inicial |
|---|---:|
| Concluir sessão válida | 40 |
| Registrar todas as séries honestamente | 10 |
| Missão diária saudável | 10–25 |
| Missão semanal | 75 |
| Recorde pessoal validado | 25 |
| Primeiro domínio de nó | 80 |
| Boss Test concluído | 150 |
| Escolher interromper por segurança | 10 de “sabedoria”, sem bônus de performance |

Valores são configuráveis. Aplicar tetos para evitar farming.

## 3. Curva de nível

Proposta simples:

```text
xp_necessario_para_proximo_nivel = arredondar(100 + 25 × nivel^1.35)
```

O motor local usa tabela pré-calculada e versionada para evitar divergência. Na
futura fase Supabase, o backend usará a mesma versão. Não deve haver vantagem
física por nível alto.

## 4. Atributos narrativos

- Força;
- Resistência;
- Controle;
- Técnica;
- Mobilidade;
- Consistência.

O app exibe progresso e a origem da mudança. “+2 Controle: você dominou duas sessões de hollow hold com técnica válida.”

## 5. Classes

Classes são estilos, não limitações permanentes:

- **Guardião:** fundamentos, suporte e consistência;
- **Guerreiro:** força de empurrar e pernas;
- **Caçador:** puxada, pegada e levers;
- **Acrobata:** equilíbrio, handstand e mobilidade específica;
- **Monge:** controle, core e movimentos estritos;
- **Mestre Híbrido:** desbloqueado por fundamentos distribuídos.

O usuário pode trocar a especialização em mudança de fase. Classe não deve gerar prescrição desequilibrada.

## 6. Campanhas e fases

Exemplo de campanha inicial:

| Fase | Narrativa | Objetivo físico |
|---:|---|---|
| 1 | O Despertar | aprender técnica, esforço e rotina |
| 2 | Portões da Fortaleza | dominar bases de empurrar, puxar, pernas e core |
| 3 | Floresta da Resistência | sustentar volume recuperável |
| 4 | Torre do Controle | pausas, tempo e unilateral básico |
| 5 | Rotas de Especialização | escolher primeira habilidade-meta |

Fases posteriores são montadas pelas árvores, não por uma sequência única.

## 7. Boss Tests

Um Boss Test:

- possui versão e janela de disponibilidade;
- é adaptado aos nós atuais;
- mede critérios definidos, não exaustão teatral;
- pode ser remarcado sem perder streak;
- encerra imediatamente no fluxo de segurança;
- oferece tentativa de familiarização quando necessário;
- concede recompensa idempotente.

Exemplo da Fase 1:

- 2 séries válidas de variação de empurrar;
- 2 séries de agachar compatível;
- 2 séries de puxada compatível;
- 1 teste curto de core;
- técnica e esforço dentro do limite;
- completar 6 de 8 sessões planejadas ou equivalente ajustado.

## 8. Missões

### Diárias

- fazer check-in;
- concluir aquecimento;
- registrar série com precisão;
- realizar mobilidade prescrita;
- descansar quando o plano indicar.

### Semanais

- cumprir X% do plano ajustado;
- treinar todos os padrões previstos;
- confirmar técnica em uma habilidade;
- revisar progresso;
- completar sessão de recuperação quando prescrita.

Não criar missões como “treinar 7 dias seguidos” ou “fazer 500 repetições”.

## 9. Streak saudável

O streak mede semanas ativas ou compromissos planejados, não dias consecutivos. Estados que protegem a sequência:

- descanso prescrito;
- doença/pausa declarada;
- deload;
- interrupção por dor;
- viagem com plano adaptado.

## 10. Recompensas

- títulos;
- molduras e skins;
- mapas e capítulos narrativos;
- emotes e efeitos visuais;
- personalização do avatar;
- resumos e troféus.

Nunca vender desbloqueio físico, falsificar domínio ou limitar segurança ao plano premium.

## 11. Ranking opcional

Categorias separadas:

- consistência ajustada ao plano;
- desafios comunitários cooperativos;
- habilidades validadas por categoria;
- temporadas por faixa comparável.

Evitar um ranking único por repetições, pois favorece fraude, volume excessivo e comparações injustas.
