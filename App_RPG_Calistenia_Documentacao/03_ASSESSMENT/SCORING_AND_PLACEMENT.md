# Pontuação e Colocação

## 1. Separação de conceitos

O sistema mantém quatro valores distintos:

1. **Nível de conta:** derivado de XP e usado na narrativa.
2. **Nível de atributo:** resumo de força, resistência, controle, mobilidade, técnica e consistência.
3. **Nó dominado:** comprovação específica dentro de uma árvore.
4. **Capacidade estimada:** valor interno com confiança e validade temporal.

Nenhum deles substitui os demais.

## 2. Escala de atributos

Cada atributo varia de 0 a 100, mas não é apresentado como precisão clínica.

| Faixa | Nome narrativo |
|---:|---|
| 0–14 | Despertar |
| 15–29 | Recruta |
| 30–44 | Aprendiz |
| 45–59 | Aventureiro |
| 60–74 | Veterano |
| 75–89 | Mestre |
| 90–100 | Lendário |

## 3. Componentes propostos

### Força

Combina dificuldade relativa dos nós dominados e desempenho recente em faixas de baixa/moderada repetição.

### Resistência

Combina capacidade de manter repetições/tempo válido e concluir volume prescrito sem degradação.

### Técnica

Proporção de critérios técnicos atendidos, ponderada pela confiabilidade da evidência.

### Controle

Isometrias, tempo, estabilidade e execução unilateral/escapular.

### Mobilidade

Somente amplitudes funcionais necessárias às habilidades escolhidas; não diagnostica limitações.

### Consistência

Adesão ajustada ao plano prescrito. Descanso previsto não reduz o valor.

## 4. Algoritmo de colocação

```text
para cada padrão:
  filtrar tentativas inválidas, com dor ou bloqueio
  localizar a variação mais difícil com familiarização válida
  verificar teste principal e qualidade
  se confiança baixa: colocar um nó abaixo
  se equipamento ausente: usar nó observável equivalente ou "não avaliado"
  salvar capacidade + confiança + versão da regra
```

## 5. Confiança

| Nível | Condição |
|---|---|
| Baixa | autorrelato, teste pulado, dados incompletos ou inconsistentes |
| Média | um teste válido e coerente |
| Alta | duas exposições coerentes ou revisão profissional |

Nó avançado não deve ser dominado apenas com confiança baixa.

## 6. Repetição válida

É definida por exercício e inclui:

- posição inicial;
- amplitude mínima/compatível;
- controle do segmento relevante;
- posição final;
- ausência de compensação proibida;
- ausência de dor impeditiva.

No MVP, a técnica é autoavaliada por checklist guiado. Uma futura análise de câmera deve produzir sugestão e confiança, não sentença clínica.

## 7. Colocação conservadora

Aplicar um nó abaixo quando:

- usuário não entendeu o teste;
- RPE não é confiável;
- técnica é incerta;
- houve pausa longa;
- resultado é discrepante do histórico;
- equipamento de teste difere do treino;
- existe receio ou pouca confiança.

## 8. Não usar um escore total para prescrição

O plano deve usar o vetor de capacidades. Exemplo:

```json
{
  "push_horizontal": 32,
  "pull_vertical": 12,
  "squat": 48,
  "hinge": 25,
  "core_anti_extension": 37,
  "support": 18,
  "balance": 29
}
```

Uma média esconderia a fraqueza de puxada.

## 9. Auditoria

Toda colocação deve armazenar:

- entradas;
- resultado;
- confiança;
- regra e versão;
- data de validade;
- motivo legível;
- eventual substituição manual por profissional.
