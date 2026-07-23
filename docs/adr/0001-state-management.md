# ADR-0001 — Gerenciamento de estado no Flutter

## Status

Aceito.

## Contexto

`08_ARCHITECTURE/TECHNICAL_ARCHITECTURE.md` exige "solução previsível com
separação de apresentação/domínio/dados" e que regras críticas não fiquem
apenas em widgets, sem indicar uma biblioteca específica.

## Decisão

Usar **Riverpod** (`flutter_riverpod`) como mecanismo de estado e injeção de
dependência.

## Justificativa

- providers são testáveis sem `BuildContext`, o que facilita testar regras de
  domínio isoladamente (exigido por `09_QUALITY/TEST_STRATEGY.md`);
- permite compor camadas domain/data/presentation sem acoplar a UI a
  implementações concretas (Supabase, Drift);
- suporta observação de streams (ex.: estado de autenticação, fila offline)
  de forma direta.

## Consequências

- toda feature expõe providers de domínio/dados desacoplados de widgets;
- decisão pode ser revisitada se o time preferir Bloc/Provider — não há
  dependência estrutural que impeça a troca nesta fase inicial.
