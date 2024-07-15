# homebrew-postgresql
Custom builds for the lastest betas of PostgreSQL

## How-To
```bash
brew tap absolutejunkyarddog/postgresql
brew install absolutejunkyarddog/postgresql/postgresql@<VERSION>

# start postgresql as a service
brew services start postgresql@17

# start postgresql from the cli
/opt/homebrew/opt/postgresql@<VERSION>/bin/pg_start -D /opt/homebrew/var/postgresql@<VERSION>

# first use
/opt/homebrew/opt/postgresql@<VERSION>/binpsql -d postgres
```

## Supported Versions
- postgresql@17 (17beta2)