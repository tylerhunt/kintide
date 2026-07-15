# CLAUDE.md

Patterns and conventions are in the `.claude/` directory:

- [project scope](.claude/scope.md) — overall app definition and requirements
- [operations pattern](.claude/operations.md) — used for all app logic
- [database standards](.claude/database.md) — schema constraints and extensions

## Essential Commands

### Development Server

```bash
bates up # start Rails server (accessible at https://kintide.test)
```

### Testing

```bash
rspec # run all tests
```

### Code Quality

```bash
bundle exec rubocop # Ruby linting
bundle exec rubocop -a # auto-fix Ruby issues (safe only)
```

### Database

```bash
bates up kintide:postgresql # start the database (implicit in `bates up`)
direnv reload # load PG* environment variables after starting database
rails db:migrate # run migrations
rails db:seed # seed database
rails db:reset # drop, create, migrate, seed
```

## Key Architectural Decisions

1. **Operations**: Multi-step business processes with side effects
2. **Query Objects**: Data retrieval without side effects··
3. **System Specs First**: UI tests are primary, avoid controller/request specs
4. **Thin Controllers**: Minimal logic, just request/response
