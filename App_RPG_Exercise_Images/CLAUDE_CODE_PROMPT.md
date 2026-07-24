# Prompt para o Claude Code

Analise este projeto Flutter antes de alterar qualquer arquivo.

Leia primeiro:

1. `App_RPG_Calistenia_Documentacao/README.md`;
2. `App_RPG_Calistenia_Documentacao/05_EXERCISES/SKILL_TREES.md`;
3. `App_RPG_Calistenia_Documentacao/05_EXERCISES/EXERCISE_SCHEMA.md`;
4. `App_RPG_Calistenia_Documentacao/05_EXERCISES/EXERCISE_MEDIA_GUIDE.md`;
5. `App_RPG_Calistenia_Documentacao/07_UX/VISUAL_ARCHITECTURE_AND_WORKOUT_PLAYER.md`;
6. `App_RPG_Calistenia_Documentacao/07_UX/SETTINGS_AND_TIMED_EXERCISES.md`;
7. `App_RPG_Exercise_Images/exercise_media_catalog.json`;
8. `App_RPG_Exercise_Images/exercise_media_manifest.csv`.

## Objetivo

Integrar ao aplicativo as 195 imagens estáticas de exercícios existentes em:

```text
App_RPG_Exercise_Images/assets/images/exercises/
```

O aplicativo deve continuar 100% offline e não deve receber Supabase, Firebase,
API remota, download de mídia ou autenticação nesta fase.

## Procedimento obrigatório

1. Inspecione a estrutura atual e identifique como exercícios, catálogo, banco
   Drift e player foram implementados.
2. Não recrie arquitetura já existente e não altere IDs, slugs, progressões,
   regras de segurança, XP ou critérios de desbloqueio sem necessidade.
3. Mescle ou copie:

   ```text
   App_RPG_Exercise_Images/assets/images/exercises/
   ```

   para:

   ```text
   assets/images/exercises/
   ```

4. Preserve todos os assets já existentes.
5. Registre uma única vez no `pubspec.yaml`:

   ```yaml
   flutter:
     assets:
       - assets/images/exercises/
   ```

6. Importe o `exercise_media_catalog.json` para a fonte de dados que já
   representa os exercícios. Cada exercício deve ser associado pelo `slug`, e
   nunca por comparação frágil do nome exibido.
7. Adicione ao modelo somente os campos ainda ausentes e realmente necessários:

   ```text
   mediaKey
   assetPath
   mediaType
   visualReviewStatus
   ```

8. Se houver banco Drift já criado, faça uma migration versionada e segura.
   Preserve o progresso local e os dados do usuário.
9. No catálogo, detalhes do treino e player, carregue a imagem com
   `Image.asset`, `BoxFit.contain` e proporção preservada.
10. Implemente um `ExerciseMediaPlaceholder` reutilizável para asset ausente ou
    erro de decodificação. Um erro de imagem nunca pode impedir o treino.
11. Pré-carregue somente a imagem atual e a seguinte, respeitando memória de
    aparelhos Android intermediários.
12. Não coloque nome, contador, repetições ou tempo dentro da imagem. Esses
    elementos pertencem à interface.
13. Para exercícios por repetição:
    - mantenha a meta visível;
    - permita confirmar ou ajustar o realizado;
    - mantenha a imagem do movimento visível.
14. Para exercícios por tempo:
    - mantenha a imagem visível;
    - execute preparação `3, 2, 1`;
    - use o contador regressivo offline e recuperável já especificado;
    - não vincule o timer à animação ou ao carregamento da imagem.
15. Respeite acessibilidade, redução de movimento e orientação de tela.
16. Movimentos avançados com
    `visual_review_status = requires_professional_review` podem aparecer na
    árvore bloqueada, mas não devem ser prescritos ou desbloqueados fora dos
    portões de segurança documentados.

## Testes obrigatórios

Implemente ou atualize testes para verificar:

- todo exercício publicado possui `slug` único;
- todo `asset_path` registrado existe;
- não existem caminhos absolutos ou URLs;
- o catálogo carrega em modo avião;
- imagem ausente mostra placeholder;
- imagem não é recortada em telas pequenas;
- timer continua funcionando se a imagem falhar;
- exercícios repetidos compartilham a mesma mídia;
- a migration Drift preserva os registros anteriores;
- os fluxos por repetição e por tempo continuam funcionando.

Execute, conforme disponível no projeto:

```bash
dart format .
flutter analyze
flutter test
```

Corrija os erros introduzidos por esta implementação. Não faça refatorações
amplas ou alterações fora do escopo.

## Entrega da tarefa

Ao terminar:

1. informe os arquivos alterados;
2. explique como o catálogo foi associado aos exercícios;
3. informe os testes executados e seus resultados;
4. liste qualquer imagem ou exercício ainda sem associação;
5. atualize `PROJECT_STATUS.md`, se o projeto utilizar esse arquivo;
6. não marque revisão biomecânica como concluída sem validação profissional.

