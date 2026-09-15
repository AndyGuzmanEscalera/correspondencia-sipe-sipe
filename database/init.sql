-- Script maestro de inicialización.
-- Ejecutar contra una base PostgreSQL vacía.

\i schema/001_extensions.sql
\i schema/002_catalogs.sql
\i schema/003_auth.sql
\i schema/004_employees.sql
\i schema/005_correspondence.sql
\i schema/006_audit.sql
\i schema/007_indexes.sql
\i seeds/001_initial_catalogs.sql
