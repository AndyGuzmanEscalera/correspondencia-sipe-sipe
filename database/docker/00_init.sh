#!/bin/bash
set -euo pipefail

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    \i /docker-entrypoint-initdb.d/schema/001_extensions.sql
    \i /docker-entrypoint-initdb.d/schema/002_catalogs.sql
    \i /docker-entrypoint-initdb.d/schema/003_auth.sql
    \i /docker-entrypoint-initdb.d/schema/004_employees.sql
    \i /docker-entrypoint-initdb.d/schema/005_correspondence.sql
    \i /docker-entrypoint-initdb.d/schema/006_audit.sql
    \i /docker-entrypoint-initdb.d/schema/007_indexes.sql
    \i /docker-entrypoint-initdb.d/seeds/001_initial_catalogs.sql
EOSQL
