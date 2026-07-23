# Project Status

**Data:** 2026-07-23
**Responsável:** Claude Code (sessão com Cleuvin)
**Branch/commit:** `feat/onboarding-triagem-colocacao` (sobre `master` @ `adab42b`)

## Objetivo da sessão

Ler toda a documentação do produto, montar o plano da primeira história
vertical e criar o scaffold inicial do projeto Flutter + estrutura de backend
(inicialmente pensada com Supabase).

## Implementado

- Repositório Git inicializado; commit inicial com a documentação mestre.
- Branch `feat/onboarding-triagem-colocacao` criada.
- Projeto Flutter gerado na raiz (`calisthenics_rpg`, Android + iOS).
- Estrutura de pastas por feature (`lib/app`, `lib/core/*`,
  `lib/features/{onboarding,safety,assessment}/{domain,data,presentation}`),
  cada uma com README apontando para o documento de referência.
- Banco local com Drift configurado (`lib/core/database/app_database.dart`)
  com tabela `OutboxEvents` (fila offline, hoje não usada — ver pendências).
- 6 ADRs em `docs/adr/`: state management (Riverpod), banco local (Drift),
  layout do monorepo, motor de regras críticas (Postgres RPC, pausado),
  formato da fila offline, e **ADR-0006: MVP local-only, sem login**.
- **Mudança de escopo decidida pelo usuário durante a sessão:** sem tela de
  login, app roda 100% offline em um único aparelho por enquanto. Removida
  a dependência `supabase_flutter` e o bootstrap correspondente. Backend
  Supabase fica pausado (não removido) em `supabase/`.
- `flutter analyze`: sem problemas. `flutter test`: 1/1 passou (smoke test
  do app raiz).

## Arquivos alterados

Ver commit(s) na branch `feat/onboarding-triagem-colocacao` (scaffold Flutter
completo + `docs/adr/*.md` + `supabase/config.toml`, `supabase/README.md`).

## Banco/migrations

- Nenhuma migration Supabase escrita ainda (backend pausado por decisão do
  usuário). `supabase/migrations/` contém apenas `.gitkeep`.
- Schema local Drift definido apenas para `OutboxEvents`; tabelas locais
  para triagem, preferências/equipamento e colocação conservadora **ainda
  não foram criadas** — são o próximo passo.

## Testes executados

| Comando | Resultado |
|---|---|
| `flutter analyze` | Sem problemas |
| `flutter test` | 1 passed, 0 failed |
| `dart run build_runner build` | OK, gerou `app_database.g.dart` |

## Decisões e ADRs

- ADR-0001 a 0005: decisões técnicas do scaffold original (Riverpod, Drift,
  layout do repo, motor de regras no Postgres, formato da fila offline).
- **ADR-0006 (nova):** MVP local-only sem login, backend Supabase pausado.
  Documenta que os princípios "backend é autoridade" e "RLS deve existir"
  não foram violados, apenas adiados conscientemente enquanto o uso for
  pessoal e single-device.

## Pendências

- Redefinir a primeira história vertical sem a etapa "criar conta": app abre
  local → triagem seguraz → agenda/equipamento → colocação conservadora
  (push_horizontal) → resultado persistido **localmente** via Drift.
- Modelar as tabelas Drift locais equivalentes a `safety_screenings`,
  `user_preferences`/`user_equipment` e `capability_estimates`.
- Implementar a regra de colocação conservadora em Dart puro
  (`features/assessment/domain`), com testes unitários.
- Implementar as telas de triagem, onboarding e resultado.
- Textos de triagem/segurança ainda são placeholders — pendente de revisão
  profissional antes de qualquer uso além do pessoal (regra do
  `01_SAFETY/SAFETY_AND_SCREENING.md` §10).

## Riscos/bloqueios

- Nenhum bloqueio técnico no momento. Supabase CLI/Docker não estão
  instalados neste ambiente — não é um bloqueio porque o backend está
  pausado por decisão de escopo.

## Próxima tarefa recomendada

Modelar e implementar as tabelas Drift locais + a regra de colocação
conservadora (domínio puro, testável), depois as telas de triagem e
onboarding — nessa ordem, sem tela de login.

## Critério para retomar

Ler este arquivo e `docs/adr/0006-mvp-local-only.md` antes de continuar;
eles substituem, para esta fase, as partes da documentação original que
assumem conta/login/Supabase ativo.
