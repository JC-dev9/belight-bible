---
trigger: always_on
---

# Regra de Commits Automáticos

Sempre que fizer alterações significativas no código (ex.: nova funcionalidade, correção de erro, refatoração ou alterações em múltiplos ficheiros), o agente deve automaticamente versionar as mudanças usando Git.

## Passos obrigatórios

1. Adicionar todas as alterações:

git add .


2. Criar um commit usando **Conventional Commits em português de Portugal**.

Formato do commit:

<tipo>: <descrição curta>


Tipos permitidos:
- feat: nova funcionalidade
- fix: correção de erro
- refactor: melhoria de código sem alterar comportamento
- docs: alterações de documentação
- style: formatação ou estilo
- chore: manutenção interna

Exemplos:

feat: adicionar sistema de autenticação
fix: corrigir erro na leitura da base de dados
refactor: reorganizar lógica do serviço de utilizadores


3. Enviar as alterações para o repositório remoto:

git push


## Regras adicionais

- O commit deve representar um **conjunto lógico de alterações**.
- Não criar commits para alterações mínimas ou temporárias.
- A mensagem deve ser **clara, curta e em português de Portugal**.