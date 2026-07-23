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
- [ ] Todas as telas têm loading, vazio, erro e offline.
- [ ] Exportar/excluir dados funciona.
- [ ] Notificações têm consentimento e configuração.

## 3. Backend e dados

- [ ] Migrations versionadas e testadas em ambiente limpo.
- [ ] RLS revisada com dois usuários.
- [ ] Ledger e domínio são backend-only.
- [ ] Finalização e recompensa são idempotentes.
- [ ] Jobs são repetíveis sem duplicação.
- [ ] Backup, recuperação e rollback foram exercitados.
- [ ] Retenção e exclusão estão implementadas.

## 4. Cliente/offline

- [ ] Sessão completa funciona offline.
- [ ] Matar/reabrir app preserva eventos.
- [ ] Timeout após commit não duplica recompensa.
- [ ] Conflito entre dispositivos é compreensível.
- [ ] Atualização de catálogo não corrompe sessão antiga.
- [ ] Android e iOS foram testados em aparelhos reais.

## 5. Qualidade

- [ ] Análise estática sem erro bloqueador.
- [ ] Testes unitários, integração, RLS e E2E aprovados.
- [ ] Invariantes do motor têm testes de propriedade.
- [ ] Acessibilidade verificada.
- [ ] Performance e bateria dentro das metas.
- [ ] Crash reporting e alertas ativos sem dados sensíveis.

## 6. Operação

- [ ] Feature flags e kill switch para conteúdo/regra crítica.
- [ ] Painel acompanha dor, substituição, falha e sincronização.
- [ ] Suporte possui procedimento de incidente.
- [ ] Responsáveis de produto, conteúdo e engenharia assinaram a release.
- [ ] Release notes indicam versões de regras.
- [ ] Plano de piloto/rollout gradual definido.

## 7. Bloqueadores absolutos

Não publicar se houver:

- possível liberação de habilidade por XP;
- duplicação conhecida de recompensa;
- bypass de RLS;
- perda conhecida de sessão offline;
- exercício sem instrução/saída/versão;
- fluxo de dor não funcional;
- conteúdo avançado sem revisão;
- segredo ou service role no aplicativo.
