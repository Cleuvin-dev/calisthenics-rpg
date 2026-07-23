# ADR-0003 — Layout do repositório

## Status

Aceito.

## Contexto

O projeto precisa versionar junto: app Flutter, migrations SQL e (futuramente)
Edge Functions do Supabase, mantendo tudo auditável em Git conforme regra
obrigatória do `IMPLEMENTATION_PROMPT.md` ("migrations e funções SQL precisam
ficar versionadas no Git").

## Decisão

Um único repositório com o projeto Flutter na raiz (`lib/`, `pubspec.yaml`,
`test/`) e uma pasta `supabase/` irmã contendo `config.toml`, `migrations/` e
`functions/`.

## Justificativa

- é a convenção padrão da Supabase CLI (`supabase/` na raiz de um projeto);
- evita indireção de workspace/monorepo tooling desnecessária nesta fase;
- documentação (`App_RPG_Calistenia_Documentacao/`) permanece na raiz, como
  já estava antes do código existir.

## Consequências

- `supabase/migrations/*.sql` é a fonte de verdade do schema; aplicações
  manuais em produção continuam proibidas;
- se o produto crescer para múltiplos apps (ex. painel web de conteúdo),
  reavaliar para um monorepo com workspaces.
