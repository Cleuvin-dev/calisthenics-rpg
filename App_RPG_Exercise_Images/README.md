# Pacote de Imagens — App RPG de Calistenia

## Conteúdo

Este pacote contém:

- 195 imagens estáticas individuais em PNG;
- resolução de 1024 × 1024 px;
- fundo transparente;
- uma imagem para cada movimento único de `SKILL_TREES.md`;
- organização por categoria;
- manifesto JSON e CSV;
- prompt de implementação para o Claude Code.

As duas ocorrências repetidas de `Wall walk parcial` e `Handstand livre
consistente` usam a mesma imagem e o mesmo `slug`, evitando duplicação no APK.

## Onde colocar

Extraia o ZIP na raiz do projeto Flutter. Copie a pasta `assets` deste pacote
para a raiz do aplicativo:

```text
seu_projeto_flutter/
├── App_RPG_Calistenia_Documentacao/
├── android/
├── assets/
│   └── images/
│       └── exercises/
│           ├── empurrar_horizontal/
│           ├── empurrar_vertical/
│           ├── puxar_horizontal_escapula/
│           ├── puxar_vertical/
│           ├── dips_suporte/
│           ├── agachamento_unilateral/
│           ├── cadeia_posterior/
│           ├── core_anterior_compressao/
│           ├── core_posterior/
│           ├── core_lateral_anti_rotacao/
│           ├── front_lever/
│           ├── back_lever/
│           ├── handstand/
│           └── panturrilha_tornozelo_impacto/
├── ios/
├── lib/
└── pubspec.yaml
```

Se a pasta `assets` já existir, mescle as pastas. Não apague outros assets.

## Registro no `pubspec.yaml`

Use:

```yaml
flutter:
  assets:
    - assets/images/exercises/
```

Se a chave `flutter/assets` já existir, acrescente somente a linha do diretório.
Não crie uma segunda chave `flutter:`.

Depois execute:

```bash
flutter pub get
```

## Como localizar uma imagem

Cada registro do `exercise_media_catalog.json` possui:

- `name`: nome exibido em português;
- `slug`: identificador estável do exercício;
- `media_key`: chave versionada da mídia;
- `asset_path`: caminho usado por `Image.asset`;
- `category_slug`: pasta da categoria;
- `visual_review_status`: estado da revisão profissional.

Exemplo:

```dart
Image.asset(
  exercise.assetPath,
  fit: BoxFit.contain,
  errorBuilder: (_, __, ___) => const ExerciseMediaPlaceholder(),
)
```

O nome visível do exercício não deve ser usado para montar caminhos em tempo de
execução. O aplicativo deve persistir o `slug` e resolver o `asset_path` pelo
catálogo.

## Regras de exibição

- usar `BoxFit.contain`;
- preservar a proporção;
- não recortar o corpo ou o equipamento;
- manter o nome e as instruções fora da imagem;
- usar placeholder quando o asset não for encontrado;
- pré-carregar apenas o exercício atual e o próximo;
- não atrelar o funcionamento do timer ao carregamento da imagem;
- continuar funcionando integralmente offline.

## Natureza das imagens

As imagens são ilustrações estáticas geradas para composição visual e
reconhecimento dos exercícios. Elas não substituem:

- instruções de execução;
- critérios de repetição;
- alertas de segurança;
- demonstração animada, quando necessária;
- revisão biomecânica profissional.

Antes da publicação comercial, um profissional de Educação Física deve revisar
principalmente as imagens de movimentos avançados, invertidos, levers, planche,
human flag, Nordic curl, HSPU e pliometria.

## Próximo passo

Abra o projeto no VS Code, inicie o Claude Code na raiz e envie integralmente o
conteúdo de `CLAUDE_CODE_PROMPT.md`.

