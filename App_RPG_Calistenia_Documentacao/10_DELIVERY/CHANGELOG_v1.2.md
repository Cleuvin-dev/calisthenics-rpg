# Alterações da versão 1.2

**Data:** 24/07/2026  
**Base:** versão 1.1

## Adicionado

- arquitetura visual original inspirada nas referências recebidas;
- prancha conceitual com dashboard, detalhe e dois players;
- identidade escura com verde-menta e destaque violeta para XP;
- catálogo visual de treinos;
- player por repetições com confirmação manual;
- armazenamento separado de alvo e resultado;
- player por tempo com 3-2-1, pausa, retomada e recuperação;
- fluxo de descanso;
- estados de mídia e placeholder;
- guia de imagens, WebP animado, GIF e vídeo;
- manifesto de mídia por versão;
- quatro ilustrações estáticas transparentes de referência;
- prompts para produzir o restante do catálogo;
- critérios de aceite e testes do player.

## Atualizado

- `README.md`;
- `05_EXERCISES/EXERCISE_SCHEMA.md`;
- `07_UX/SCREENS_AND_FLOWS.md`;
- `08_ARCHITECTURE/DATA_MODEL.md`;
- `08_ARCHITECTURE/TECHNICAL_ARCHITECTURE.md`;
- `09_QUALITY/TEST_STRATEGY.md`;
- `10_DELIVERY/IMPLEMENTATION_PROMPT.md`;
- `10_DELIVERY/ROADMAP.md`.

## Decisões preservadas

- primeira versão 100% offline;
- SQLite/Drift como fonte de verdade;
- nenhum Supabase, Firebase, login ou API no MVP;
- segurança acima da gamificação;
- XP separado de domínio físico;
- timer monotônico;
- reset local transacional;
- catálogo e regras versionados.

## Como atualizar

Substituir somente a pasta:

```text
App_RPG_Calistenia_Documentacao/
```

Não substituir `lib`, `android`, `ios`, `assets` ou `pubspec.yaml` do
aplicativo. Se a documentação antiga recebeu alterações manuais, fazer backup
e comparar antes da substituição.

