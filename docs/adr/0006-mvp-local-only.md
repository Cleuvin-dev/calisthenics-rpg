# ADR-0006 — MVP local-only, sem login

## Status

Aceito (decisão do usuário em 2026-07-23, ver `docs/PROJECT_STATUS.md`).

## Contexto

Os documentos de `App_RPG_Calistenia_Documentacao/` descrevem um produto
multiusuário com Supabase Auth, RLS e backend como autoridade de XP/domínio
(`08_ARCHITECTURE/TECHNICAL_ARCHITECTURE.md`, `08_ARCHITECTURE/BACKEND_RULES.md`).
O usuário definiu que, **a princípio**, quer usar o app sozinho, offline, em
um único aparelho, sem tela de login.

## Decisão

1. Sem conta/autenticação nesta fase — nenhuma tela de login, sem Supabase
   Auth. O app assume um único usuário implícito no aparelho.
2. Backend Supabase (migrations, RLS, RPCs) fica **pausado**, não removido:
   a pasta `supabase/` e as ADRs 0003/0004 continuam descrevendo o plano
   para quando fizer sentido publicar ou sincronizar entre aparelhos.
3. Toda regra crítica (triagem, colocação conservadora e, futuramente,
   XP/domínio) roda **localmente em Dart**, persistida em tabelas Drift
   locais equivalentes às tabelas Postgres documentadas.
4. Uso é pessoal por enquanto — a documentação de produto **não** foi
   reescrita; ela continua descrevendo a visão multiusuário de médio/longo
   prazo. Esta ADR documenta apenas o desvio temporário de escopo técnico.

## Consequências

- regras como "backend é autoridade" e "RLS deve existir e ser testada"
  (princípios imutáveis do README) ficam **sem aplicação prática** enquanto
  não houver backend — não foram violadas, foram adiadas conscientemente;
- idempotência ainda importa localmente (evitar duplicar um registro de
  colocação ao reabrir o app), mas não há mais concorrência entre
  dispositivos/usuários a proteger nesta fase;
- ao reativar o Supabase, os nomes de tabela/campo em Drift devem espelhar
  `DATA_MODEL.md` o máximo possível, para facilitar a migração de dados
  locais para o backend;
- `lib/core/auth/` e `lib/core/sync/` ficam como pastas reservadas
  (ver READMEs atualizados), sem código ativo nesta fase.

## Revisão

Reavaliar quando o usuário quiser: (a) usar o app em mais de um aparelho,
(b) multiusuário, ou (c) qualquer recurso que dependa de autoridade de
servidor (ranking competitivo, antifraude real).
