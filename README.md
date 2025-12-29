# TodoApp Phoenix SaaS

A modern, multi-tenant Todo application built with Elixir/Phoenix framework featuring real-time updates and passwordless authentication.

## Features

- 🔐 **Passwordless Authentication** - Email-based magic link authentication
- 👥 **Multi-tenant Architecture** - Complete data isolation between users
- ⚡ **Real-time Updates** - Phoenix LiveView for instant UI updates
- 🎨 **Modern UI** - DaisyUI components with dark mode support
- 📊 **Statistics Dashboard** - Track task completion progress
- 🏢 **Organizations & Workspaces** - Foundation for team collaboration (infrastructure ready)

## Tech Stack

- **Backend**: Elixir 1.18.4, Phoenix 1.8.3
- **Frontend**: Phoenix LiveView, TailwindCSS, DaisyUI
- **Database**: PostgreSQL 16
- **Development**: Nix flakes for reproducible environment
- **Email**: Swoosh with local mailbox viewer

## Quick Start

### Prerequisites

- Nix with flakes enabled
- PostgreSQL (or use the one in Nix shell)

### Setup

1. Clone the repository:
```bash
git clone https://github.com/hnkNkm/todo_phoenix.git
cd todo_phoenix
```

2. Enter the Nix development shell:
```bash
nix develop
```

3. Install dependencies:
```bash
mix deps.get
```

4. Create and migrate database:
```bash
mix ecto.setup
```

5. Start Phoenix server:
```bash
mix phx.server
```

Now visit [`http://localhost:4000`](http://localhost:4000) from your browser.

## Development

### Email Testing

In development, emails are captured and can be viewed at:
[`http://localhost:4000/dev/mailbox`](http://localhost:4000/dev/mailbox)

### Database

The application uses PostgreSQL on port 5433 (configurable in `config/dev.exs`).

### Testing

```bash
mix test
```

## Features in Detail

### Authentication System
- Email-based passwordless login
- Magic link authentication
- Session management with "remember me" option

### Task Management
- Create, read, update, delete tasks
- Mark tasks as complete/incomplete
- Add descriptions to tasks
- Real-time statistics

### Multi-tenancy
- User-level data isolation
- Organization and workspace models (ready for expansion)
- Secure data separation

## Architecture

The application follows Phoenix's standard architecture with:
- Contexts for business logic (`Todos`, `Accounts`, `Organizations`)
- LiveView for real-time UI
- PubSub for broadcasting updates
- Ecto for database operations

## Phoenix Framework

* Official website: https://www.phoenixframework.org/
* Guides: https://hexdocs.pm/phoenix/overview.html
* Docs: https://hexdocs.pm/phoenix
* Forum: https://elixirforum.com/c/phoenix-forum
* Source: https://github.com/phoenixframework/phoenix
