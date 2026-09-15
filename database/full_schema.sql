-- Esquema completo en un solo archivo.
-- Uso: psql -U sipe_app -d correspondencia_sipe -f database/full_schema.sql

\ir schema/001_extensions.sql
\ir schema/002_catalogs.sql
\ir schema/003_auth.sql
\ir schema/004_employees.sql
\ir schema/005_correspondence.sql
\ir schema/006_audit.sql
\ir schema/007_indexes.sql
\ir seeds/001_initial_catalogs.sql
