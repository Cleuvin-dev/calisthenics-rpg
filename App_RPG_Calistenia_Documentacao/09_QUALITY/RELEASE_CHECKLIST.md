# Checklist de Release

## 1. Conteúdo e segurança

- [ ] Público-alvo desta versão está explícito.
- [ ] Triagem e mensagens foram aprovadas.
- [ ] Todo exercício publicado tem revisor, versão e vídeo correspondente.
- [ ] Dor e sinais de alerta interrompem os fluxos corretos.
- [ ] Habilidades avançadas sem protocolo continuam ocultas.
- [ ] Descanso, pausa e deload não quebram streak.
- [ ] Termos não prometem diagnóstico, resultado ou prazo.

## 2. Produto

- [ ] Onboarding pode ser concluído com teste pulado.
- [ ] Plano respeita dias, tempo e equipamentos.
- [ ] Usuário entende XP versus domínio.
- [ ] Todas as telas têm loading, vazio, erro e persistência local.
- [ ] Exportar/apagar dados locais funciona, se incluído nesta versão.
- [ ] Notificações têm consentimento e configuração.

## 3. Banco local e dados

- [ ] Migrations Drift/SQLite versionadas e testadas em banco novo e existente.
- [ ] Foreign keys e constraints estão ativas.
- [ ] Ledger e domínio só são alterados por serviços de domínio.
- [ ] Finalização e recompensa são idempotentes.
- [ ] Rotinas locais são repetíveis sem duplicação.
- [ ] Backup, recuperação e rollback foram exercitados.
- [ ] Reset da jornada e apagamento local estão implementados.

## 4. Cliente/offline

- [ ] Sessão completa funciona offline.
- [ ] Matar/reabrir app preserva eventos.
- [ ] Fechamento após commit não duplica recompensa.
- [ ] Todo o fluxo principal funciona em modo avião.
- [ ] Atualização de catálogo não corrompe sessão antiga.
- [ ] Android e iOS foram testados em aparelhos reais.

## 5. Qualidade

- [ ] Análise estática sem erro bloqueador.
- [ ] Testes unitários, integração local e E2E aprovados.
- [ ] Invariantes do motor têm testes de propriedade.
- [ ] Acessibilidade verificada.
- [ ] Performance e bateria dentro das metas.
- [ ] Relatórios locais de erro não contêm dados sensíveis.

## 6. Operação

- [ ] Feature flags e kill switch para conteúdo/regra crítica.
- [ ] Diagnóstico local acompanha dor, substituição e falha sem dados sensíveis.
- [ ] Suporte possui procedimento de incidente.
- [ ] Responsáveis de produto, conteúdo e engenharia assinaram a release.
- [ ] Release notes indicam versões de regras.
- [ ] Plano de piloto/rollout gradual definido.

## 7. Bloqueadores absolutos

Não publicar se houver:

- possível liberação de habilidade por XP;
- duplicação conhecida de recompensa;
- corrupção ou acesso indevido ao banco local;
- perda conhecida de sessão offline;
- exercício sem instrução/saída/versão;
- fluxo de dor não funcional;
- conteúdo avançado sem revisão;
- dependência de rede não documentada no fluxo offline.
