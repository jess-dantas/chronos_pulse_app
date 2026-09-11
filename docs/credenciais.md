# Credenciais (seeds — demonstração)

> Esta página concentra as credenciais de demonstração do **frontend**. As credenciais
> de acesso **privilegiado** (fundador da empresa e Admin Plataforma) **não são
> documentadas em texto plano no repositório** — são entregues fora do código
> (ver seção de acessos do time / gestor de segredos). Fonte dos dados: seeds do
> backend (`chronos-pulse` → `docs/credenciais.md`).

## Tenant de demonstração

- **Tenant de demonstração:** `a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11` (Chronos Pulse Tech LTDA) — possui os **9 módulos** ativos (`PONTO`, `RECURSOS_HUMANOS`, `ESTOQUE`, `PATRIMONIO`, `FROTA`, `PROTOCOLO`, `COMPRAS`, `LICITACOES`, `TRANSPARENCIA`).

## Usuários de demonstração

| Perfil | CPF | Senha | Observação |
|---|---|---|---|
| Admin Empresa | `11111111111` | `admin123` | Acesso irrestrito no tenant (todos os módulos) |
| Gestor RH | `22222222222` | `admin123` | Gestão de RH, ponto, estoque |
| Colaborador | `12345678901` | `senha123` | Apenas ponto eletrônico |
| Colaborador Almoxarife | `98765432100` | `senha123` | Ponto + estoque (`acessoEstoque=true`) |

## Perfis de plataforma (fora do repositório)

- **Admin Plataforma** (CPF `00000000000`): senha entregue fora do repositório; tem **acesso irrestrito a todos os módulos** (menu e backend).
- **Fundador / Admin Empresa da Red Cape** (CPF `99999999999`): senha entregue fora do repositório.

Para saber como subir o app, ver [`README.md`](../README.md).