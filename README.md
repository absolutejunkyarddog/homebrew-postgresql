# homebrew-postgresql
Custom builds for the latest betas of PostgreSQL

## How-To
```bash
# tap repo and install
brew tap absolutejunkyarddog/postgresql
brew install absolutejunkyarddog/postgresql/postgresql@<VERSION>

# start postgresql as a service
brew services start postgresql@<VERSION>

# start postgresql from the cli
/opt/homebrew/opt/postgresql@<VERSION>/bin/pg_start -D /opt/homebrew/var/postgresql@<VERSION>

# first use
/opt/homebrew/opt/postgresql@<VERSION>/bin/psql -d postgres
```

## Supported Versions
- postgresql@17 (17beta2)