# Motor de Treino

## 1. Responsabilidade

Gerar uma semana executável a partir de capacidade, objetivo, tempo, frequência, equipamento, preferências, restrições, prontidão e histórico. O MVP deve usar regras determinísticas versionadas.

## 2. Entradas

```yaml
user:
  goals: []
  training_days: 2..6
  minutes_per_session: 15..90
  locations: []
  equipment: []
  preferences: []
  exclusions: []
state:
  capability_vector: {}
  mastered_nodes: []
  recent_load: {}
  pain_flags: []
  adherence: number
  readiness: number
  phase_week: integer
```

## 3. Padrões que precisam aparecer na semana

- empurrar horizontal;
- puxar horizontal;
- agachar/joelho dominante;
- cadeia posterior/hinge;
- core anti-extensão e/ou flexão controlada;
- suporte/pegada quando aplicável;
- empurrar/puxar vertical conforme capacidade e equipamento;
- mobilidade específica;
- equilíbrio/locomoção quando apropriado.

Grandes grupos musculares devem receber estímulo ao menos duas vezes por semana como referência geral, respeitando nível e recuperação.

## 4. Prioridade de seleção

1. excluir contraindicações, dor e equipamento indisponível;
2. escolher nós compatíveis com capacidade;
3. reservar dose para a habilidade-meta;
4. cobrir padrões fundamentais;
5. equilibrar fadiga entre dias;
6. respeitar tempo;
7. evitar redundâncias;
8. inserir alternativas equivalentes;
9. validar carga semanal;

## 5. Estrutura da sessão

| Bloco | Uso | Faixa de tempo |
|---|---|---:|
| Check-in | prontidão e ajuste | 1–2 min |
| Aquecimento | geral + específico | 3–10 min |
| Habilidade | prática de alta qualidade, baixa fadiga | 5–20 min |
| Força principal | 1–3 movimentos prioritários | 8–35 min |
| Acessórios | equilíbrio estrutural/pontos fracos | 3–20 min |
| Core/mobilidade | conforme objetivo | 3–12 min |
| Encerramento | esforço, dor, resumo | 1–3 min |

Quando o tempo for curto, preservar aquecimento necessário, exercício principal e segurança; remover acessórios primeiro.

## 6. Dose inicial conservadora

O catálogo define faixas por exercício e nível. Regra base sugerida:

- iniciante: 1–3 séries de trabalho por padrão/sessão;
- intermediário: 2–5 séries;
- avançado: individualizar por objetivo e histórico;
- terminar séries principais normalmente com repetições em reserva;
- isometrias encerram antes de perda técnica;
- movimentos explosivos usam poucas repetições de alta qualidade.

Números finais exigem aprovação profissional e testes.

## 7. Algoritmo semanal simplificado

```text
validar segurança e disponibilidade
definir template pela frequência
atribuir prioridades P1, P2 e manutenção
para cada sessão:
  calcular orçamento de minutos
  selecionar aquecimento específico
  selecionar habilidade sem fadiga prévia incompatível
  selecionar principais em faixa treinável
  completar padrões faltantes
  validar descanso e carga acumulada
  gerar alternativas
publicar plano com versão e explicações
```

## 8. Ajuste pós-série

| Resposta | Ajuste imediato |
|---|---|
| Muito fácil | aumentar alvo dentro da faixa ou tornar cadência mais controlada |
| Adequada | manter |
| Difícil, concluída | reduzir topo da próxima série |
| Não concluída | reduzir reps/assistência ou regressão |
| Dor | interromper e executar fluxo de segurança |

Troca de variação durante a sessão não deve ser tratada como punição.

## 9. Ajuste entre sessões

- progresso consistente: aplicar menor incremento possível;
- desempenho irregular: manter e coletar mais uma exposição;
- duas falhas equivalentes: reduzir dose ou regressão;
- prontidão baixa: reduzir volume, manter técnica;
- platô: verificar sono, adesão, técnica, recuperação e especificidade antes de adicionar volume;
- semana de boss: reduzir fadiga antes do teste;
- ausência: aplicar protocolo de retorno.

## 10. Restrições duras

- não prescrever dois testes máximos do mesmo padrão sem recuperação;
- não combinar volume alto e nova habilidade avançada na primeira exposição;
- não usar habilidade bloqueada como série de trabalho;
- não gerar sessão maior que tempo + tolerância definida;
- não alterar silenciosamente uma sessão já iniciada;
- não remover trabalho fundamental para preencher apenas habilidades chamativas.

## 11. Explicabilidade

Cada item inclui um `reason_code`, por exemplo:

- `GOAL_PRIMARY`;
- `FOUNDATION_GAP`;
- `SKILL_PREREQUISITE`;
- `WEEKLY_BALANCE`;
- `EQUIPMENT_SUBSTITUTION`;
- `READINESS_REDUCTION`;
- `RETURN_AFTER_BREAK`;
- `DELOAD`.

O app traduz o código: “A remada foi incluída para equilibrar sua força de puxada e preparar sua primeira barra.”
