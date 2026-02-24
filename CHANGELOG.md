# Changelog

Todas as mudanças notáveis no CYBERGHOST OSINT serão documentadas neste arquivo.

O formato é baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/),
e este projeto adere ao [Versionamento Semântico](https://semver.org/lang/pt-BR/).

## [7.0.0] - 2024-01-15

### Adicionado
- Nova arquitetura modular com 50+ módulos OSINT
- Sistema de plugins para extensibilidade
- Dashboard web em tempo real
- API REST completa
- Suporte a container Docker e Kubernetes
- Integração com 20+ APIs (Shodan, VirusTotal, etc.)
- Sistema de relatórios em múltiplos formatos (HTML, PDF, JSON, CSV)
- Módulo de IA para análise de sentimentos e padrões
- Dark web monitoring via Tor
- Geolocalização avançada com mapas interativos
- Sistema de notificações (Email, Slack, Discord, Telegram)
- Agendador de tarefas integrado
- Backup e restore automáticos
- Health check e monitoramento

### Melhorado
- Performance 10x mais rápida em scans
- Interface de linha de comando redesenhada
- Documentação completa em português e inglês
- Sistema de logging mais robusto
- Gerenciamento de erros melhorado

### Corrigido
- Bugs na detecção de WAF
- Problemas de rate limiting em APIs
- Memory leaks em scans longos
- Issues de timeout em requisições

### Segurança
- Criptografia de relatórios
- Auditoria de ações
- Sanitização de inputs
- Proteção contra SSRF

## [6.0.0] - 2023-10-20

### Adicionado
- Módulo de inteligência de ameaças
- Integração com Have I Been Pwned
- Verificação de credenciais vazadas
- Suporte a proxies e Tor
- Sistema de cache

### Melhorado
- Interface de usuário mais intuitiva
- Velocidade de enumeração de subdomínios
- Precisão na detecção de CMS

### Corrigido
- Falhas na autenticação de APIs
- Erros de parsing em wordlists grandes

## [5.0.0] - 2023-07-05

### Adicionado
- Primeira versão pública
- Módulos básicos de reconhecimento
- Interface de linha de comando
- Relatórios em HTML
- Instalação automatizada

[7.0.0]: https://github.com/cyberghost/cyberghost-osint/compare/v6.0.0...v7.0.0
[6.0.0]: https://github.com/cyberghost/cyberghost-osint/compare/v5.0.0...v6.0.0
[5.0.0]: https://github.com/cyberghost/cyberghost-osint/releases/tag/v5.0.0