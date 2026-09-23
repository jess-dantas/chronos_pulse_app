# Credenciais (seeds — demonstração)

> Esta página concentra as credenciais de demonstração do **frontend**.
> Fonte dos dados: seeds do backend (`chronos-pulse` → `docs/credenciais.md`).
> Senhas em texto plano são **apenas para demonstração**.

## Tenants

- **Tenant de demonstração (Demonstração):** `a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11` (CNPJ `01.001.001/0001-01`, slug **`demonstracao`**) — possui os **9 módulos** ativos (`PONTO`, `RECURSOS_HUMANOS`, `ESTOQUE`, `PATRIMONIO`, `FROTA`, `PROTOCOLO`, `COMPRAS`, `LICITACOES`, `TRANSPARENCIA`). Os 4 usuários demo abaixo pertencem a este tenant.
- **Tenant LJ Code:** `a0eebc99-0009-0009-0009-6bb9bd380a09` (CNPJ `49.262.262/0001-13`, slug **`lj-code`**) — trio core (`PONTO`, `RECURSOS_HUMANOS`, `ESTOQUE`), **sem usuários CPF** nos seeds.

## Usuários de demonstração (login CPF + senha)

| Perfil | Nome | CPF | Senha | Observação |
|---|---|---|---|---|
| `ADMIN_EMPRESA` | Admin Empresa | `11111111111` | `admin123` | Gestão completa; **herda todos os módulos contratados** no primeiro consentimento LGPD; vê o card **Transferir titularidade** em `/perfil` |
| `GESTOR_RH` | Gestor de RH | `22222222222` | `admin123` | Colaboradores, ponto, estoque + gerência |
| `COLABORADOR` | Colaborador 1 | `12345678901` | `senha123` | Apenas ponto eletrônico (candidato ideal ao wizard de titularidade) |
| `COLABORADOR` | Colaborador 2 | `98765432100` | `senha123` | Ponto + estoque (`acessoEstoque=true`) |

> **Zero-trace:** nenhum usuário com CPF `99999999999` (ex-Fundador Red Cape) existe nos seeds.

## Administrator (Admin Plataforma)

- **Username:** `Administrator` — tela **"Login Administrator"** (`/admin/auth/login`, fora de `/api/v1`).
- **Produção:** a tabela nasce **vazia** — primeiro acesso pelo wizard `/admin/auth/bootstrap` (username ≤20, senha 8–100); setup **obrigatório** de 2FA (`chronos.admin.two-factor-required`, default `true`) gera **8 códigos de recuperação** exibidos uma única vez (`/admin/auth/setup-2fa` + dialog); recuperação em `/admin/auth/recover`.
- **Desenvolvimento:** seed `db/seed/R__seed_admin_dev.sql` cria `Administrator` / senha `admin123`, 2FA desabilitado (`two-factor-required: false` no dev) — login direto, sem wizard.
- Escopo LGPD: **sem CPF, sem tenant, sem acesso a dados de tenant** — apenas catálogo/ativação de módulos, gestão de empresas e telemetria.

Para saber como subir o app, ver [`README.md`](../README.md). Checklist de smoke do backend: `chronos-pulse/docs/smoke.md`.
