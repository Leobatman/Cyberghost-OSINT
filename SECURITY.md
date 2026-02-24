# Política de Segurança do CYBERGHOST OSINT

## Versões Suportadas

| Versão | Suportada          |
|--------|-------------------|
| 7.0.x  | ✅                |
| 6.0.x  | ⚠️ (Manutenção)   |
| < 6.0  | ❌                 |

## Reportando Vulnerabilidades

Nós levamos a segurança do CYBERGHOST OSINT a sério. Agradecemos seus esforços para divulgar vulnerabilidades de forma responsável.

### Por favor, NÃO abra issues públicas para vulnerabilidades de segurança!

Em vez disso, envie um email para **cyberghost-security@protonmail.com** com:

- Descrição detalhada da vulnerabilidade
- Passos para reproduzir
- Versão afetada
- Impacto potencial
- Sugestão de correção (se aplicável)

### O que esperar

- **Confirmação**: Você receberá uma confirmação em até 48 horas
- **Análise**: Avaliaremos a vulnerabilidade e seu impacto
- **Correção**: Trabalharemos em uma correção
- **Divulgação**: Coordenaremos a divulgação responsável

### Processo

1. Reporte a vulnerabilidade via email
2. Aguarde nossa resposta (máximo 48h)
3. Trabalharemos juntos na correção
4. A vulnerabilidade será divulgada após correção

## Práticas de Segurança

### Para Usuários

- **Mantenha-se atualizado**: Use sempre a última versão
- **Configure APIs corretamente**: Use chaves com permissões mínimas
- **Use em ambientes isolados**: Considere usar Docker ou VMs
- **Proteja seus relatórios**: Use criptografia para dados sensíveis
- **Monitore logs**: Revise logs regularmente

### Recomendações de Configuração

```bash
# Sempre use HTTPS para web dashboard
ENABLE_HTTPS=true

# Ative autenticação para acesso web
REQUIRE_AUTH=true

# Use senhas fortes para bancos de dados
DB_PASS="gerar-senha-forte-aqui"

# Ative criptografia de relatórios
REPORT_ENCRYPT=true

# Configure rate limiting
RATE_LIMIT_ENABLED=true
RATE_LIMIT_REQUESTS=10