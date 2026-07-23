# Supabase — backend local

## Status deste ambiente

A **Supabase CLI e o Docker não estão instalados** na máquina usada para este
scaffold. `config.toml` foi escrito à mão seguindo o formato padrão da CLI.
Antes de rodar localmente:

1. instalar a [Supabase CLI](https://supabase.com/docs/guides/cli);
2. instalar Docker (necessário para `supabase start`);
3. rodar `supabase start` a partir da raiz do repositório;
4. rodar `supabase db reset` para aplicar todas as migrations em
   `migrations/` do zero.

## Estrutura

- `config.toml` — configuração do stack local;
- `migrations/` — schema versionado, único caminho permitido para alterar
  o banco (proibido SQL manual em produção, conforme regra obrigatória do
  `IMPLEMENTATION_PROMPT.md`);
- `functions/` — Edge Functions (reservadas para integrações externas, ver
  `docs/adr/0004-critical-rules-engine.md`).

## Próximo passo

Migrations da primeira história vertical (perfil, triagem, preferências,
`capability_estimates`, RLS e a RPC de colocação conservadora) ainda não
foram escritas — é o próximo passo de implementação, não parte deste
scaffold.
