# Esquema do Catálogo de Exercícios

## 1. Princípio

Nenhum exercício pode ser prescrito apenas por nome. Cada versão do catálogo é conteúdo estruturado, revisado e auditável.

## 2. Estrutura mínima

```yaml
exercise:
  id: uuid
  slug: push_up_incline
  version: 1
  status: draft|review|published|retired
  name_pt_br: Flexão inclinada
  pattern: push_horizontal
  secondary_patterns: [core_anti_extension]
  difficulty: 1..100
  skill_tier: foundation|basic|intermediate|advanced|elite
  movement_type: dynamic|isometric|explosive|mobility
  laterality: bilateral|unilateral|alternating
  equipment: [stable_elevated_surface]
  environment_checks: []
  instructions: []
  breathing_cues: []
  valid_rep_criteria: []
  common_errors: []
  stop_conditions: []
  contraindication_tags: []
  regressions: []
  progressions: []
  substitutions: []
  prescription:
    rep_ranges_by_level: {}
    hold_ranges_by_level: {}
    rest_seconds_range: []
    tempo_options: []
    max_test_cap: null
  media:
    demonstration_front: url
    demonstration_side: url
    thumbnail: url
  review:
    reviewer_id: uuid
    reviewed_at: timestamp
    next_review_at: timestamp
```

## 3. Padrões oficiais

- `push_horizontal`
- `push_vertical`
- `pull_horizontal`
- `pull_vertical`
- `squat`
- `lunge_unilateral`
- `hinge_posterior_chain`
- `calf_ankle`
- `core_anti_extension`
- `core_anti_rotation`
- `core_lateral`
- `core_compression`
- `support_dip`
- `hang_grip`
- `scapular_control`
- `hand_balance`
- `mobility_specific`
- `locomotion_conditioning`

## 4. Critérios de substituição

Uma substituição deve preservar, na ordem possível:

1. segurança e ausência de dor;
2. padrão principal;
3. objetivo do bloco;
4. nível de dificuldade;
5. equipamento;
6. dose/fadiga esperada.

Exemplo: flexão inclinada pode ser substituída por chest press com elástico aprovado, mas não por agachamento apenas porque ambos são “fáceis”.

## 5. Vídeos e instruções

Cada vídeo deve:

- mostrar início, execução e fim;
- ter ângulo que revele os critérios;
- incluir regressão e saída;
- evitar texto dependente apenas de áudio;
- indicar configuração segura do equipamento;
- corresponder exatamente à versão descrita.

## 6. Versionamento

Alterar critério técnico, dificuldade, dose ou contraindicação cria nova versão. Correção meramente ortográfica pode atualizar metadados sem mudar prescrição. Planos existentes mantêm referência à versão usada.

## 7. Conteúdo inicial necessário

Para o MVP, cadastrar pelo menos:

- 15 variações de empurrar;
- 15 de puxar/escápula/pegada;
- 15 de pernas e cadeia posterior;
- 15 de core;
- 10 de suporte/equilíbrio;
- 20 aquecimentos e mobilidades específicas;
- regressão e substituição para cada movimento fundamental.

O catálogo deve crescer antes de abrir trilhas elite ao público.
