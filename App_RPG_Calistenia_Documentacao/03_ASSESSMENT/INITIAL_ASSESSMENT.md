# Avaliação Física Inicial Adaptativa

## 1. Objetivo

Encontrar o ponto inicial seguro em cada padrão de movimento. A avaliação não serve para competir, diagnosticar ou levar o usuário à exaustão absoluta.

## 2. Pré-condições

- triagem concluída e ainda válida;
- termo específico da avaliação aceito;
- tutorial de RPE, RIR, dor e repetição válida concluído;
- local e equipamento conferidos;
- check-in sem bloqueio;
- aquecimento realizado.

## 3. Fluxo adaptativo

Para cada padrão:

1. perguntar qual variação o usuário acredita conseguir;
2. mostrar demonstração e checklist;
3. executar 2–3 repetições de familiarização ou sustentação curta;
4. perguntar esforço, dor e confiança;
5. subir ou descer uma variação;
6. executar conjunto submáximo padronizado;
7. registrar qualidade e encerrar na falha técnica;
8. estimar colocação conservadora.

## 4. Bateria fundamental

| Ordem | Padrão | Opções adaptativas | Métrica principal |
|---:|---|---|---|
| 1 | Mobilidade/controle | elevação de braços, agachar até caixa, apoio unipodal | qualidade/tempo |
| 2 | Empurrar | parede → bancada → joelhos → chão | reps válidas |
| 3 | Pernas | sentar-levantar → assistido → livre | reps e controle |
| 4 | Core anterior | dead bug → prancha inclinada → prancha | tempo/reps |
| 5 | Puxar | retração → remada alta → remada baixa → barra assistida | reps válidas |
| 6 | Cadeia posterior | ponte → hinge sem carga → unilateral assistida | reps e controle |
| 7 | Suporte/pegada | apoio alto, hang assistido ou hang | tempo sem dor |
| 8 | Condicionamento opcional | marcha/degrau aprovado | recuperação/RPE |

O condicionamento não deve transformar o onboarding em uma prova máxima.

## 5. Protocolos básicos propostos

### Empurrar

- escolher a variação mais difícil que permita 5 repetições de familiarização com técnica;
- após descanso, executar até o limite técnico ou teto do protocolo;
- cadência orientativa controlada, sem exigir metrônomo no MVP;
- parar com dor, perda de alinhamento definida ou RPE máximo configurado.

### Puxar

Se não houver barra, usar remada com mesa/equipamento apenas quando o ambiente for verificado como seguro. Caso contrário, avaliar retração escapular/isometria com recurso aprovado e marcar “equipamento insuficiente”.

### Pernas

- começar por sentar e levantar de altura compatível;
- observar controle de descida, estabilidade e amplitude confortável;
- permitir apoio;
- não inferir diagnóstico a partir de alinhamento.

### Core

- avaliar respiração e manutenção da posição;
- tempo excessivo não é necessário; aplicar teto;
- encerrar quando perder posição repetidamente.

### Equilíbrio

- realizar próximo a apoio estável;
- nunca usar como teste competitivo;
- se houver risco de queda, pular e prescrever base segura.

## 6. Dados registrados

```yaml
assessment_attempt:
  assessment_id: uuid
  exercise_version_id: uuid
  started_at: timestamp
  variation_id: uuid
  repetitions: integer|null
  hold_seconds: number|null
  assistance_type: string|null
  assistance_value: number|null
  rpe: number
  rir: number|null
  pain_score: integer
  stop_reason: completed|technical_failure|effort_limit|pain|symptom|user_stopped
  technique_checks: object
  confidence: low|medium|high
  evidence_source: self_report|coach_review|camera_assisted
```

## 7. Avaliação abreviada

Usada após pausa ou mudança de equipamento:

- check-in e triagem de mudanças;
- 1 conjunto de confirmação nos padrões afetados;
- não repetir testes não relacionados;
- atualizar somente as estimativas necessárias.

## 8. Reavaliação

- a cada 4–8 semanas, configurável por fase;
- antes, se o desempenho exceder consistentemente o plano;
- após pausa longa;
- quando o usuário troca objetivo;
- ao retornar de dor, dentro dos limites do app;
- nunca imediatamente após sessão pesada do mesmo padrão.

## 9. Saída explicável

O resultado deve dizer:

- variação atual por padrão;
- por que foi escolhida;
- principal requisito faltante;
- nível de confiança da estimativa;
- data prevista da próxima confirmação, sem prometer domínio;
- quais dados não puderam ser avaliados.
