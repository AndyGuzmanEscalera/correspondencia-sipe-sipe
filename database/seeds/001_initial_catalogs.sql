-- Datos iniciales de catálogos (provisional para desarrollo).

INSERT INTO fiscal_years (year, is_active) VALUES
    (2026, TRUE),
    (2025, TRUE),
    (2024, TRUE),
    (2023, FALSE)
ON CONFLICT (year) DO NOTHING;

INSERT INTO correspondence_types (code, name) VALUES
    ('CI', 'Correspondencia Interna'),
    ('CE', 'Correspondencia Externa')
ON CONFLICT (code) DO NOTHING;

INSERT INTO priorities (name, sort_order) VALUES
    ('Alta',  1),
    ('Media', 2),
    ('Baja',  3)
ON CONFLICT (name) DO NOTHING;

INSERT INTO derivation_statuses (code, name) VALUES
    ('PENDING',   'Pendiente de recepción'),
    ('RECEIVED',  'Recibida'),
    ('OBSERVED',  'Observada'),
    ('SENT',      'Enviada'),
    ('CONCLUDED', 'Concluida'),
    ('ARCHIVED',  'Archivada')
ON CONFLICT (code) DO NOTHING;

INSERT INTO instructions (name) VALUES
    ('Para su conocimiento'),
    ('Para atención'),
    ('Para corregir'),
    ('Para respuesta'),
    ('Para archivo')
ON CONFLICT (name) DO NOTHING;

INSERT INTO units (code, name) VALUES
    ('RECEPCION',  'Recepción'),
    ('DESPACHO',   'Despacho'),
    ('SECRETARIA', 'Secretaría Municipal'),
    ('JURIDICA',   'Unidad Jurídica'),
    ('FINANZAS',   'Unidad de Finanzas'),
    ('SISTEMAS',   'Unidad de Sistemas'),
    ('URBANISMO',  'Unidad de Urbanismo')
ON CONFLICT (code) DO NOTHING;

INSERT INTO permissions (code, name) VALUES
    ('CORRESPONDENCE_CREATE',  'Registrar correspondencia'),
    ('CORRESPONDENCE_VIEW',    'Ver correspondencia'),
    ('CORRESPONDENCE_UPDATE',  'Editar correspondencia'),
    ('CORRESPONDENCE_DERIVE',  'Derivar correspondencia'),
    ('CORRESPONDENCE_RECEIVE', 'Recibir correspondencia'),
    ('CORRESPONDENCE_ARCHIVE', 'Archivar correspondencia'),
    ('REPORT_VIEW',            'Ver reportes'),
    ('USER_MANAGE',            'Administrar usuarios')
ON CONFLICT (code) DO NOTHING;

INSERT INTO roles (name, description) VALUES
    ('admin', 'Administrador del sistema')
ON CONFLICT (name) DO NOTHING;

INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
CROSS JOIN permissions p
WHERE r.name = 'admin'
ON CONFLICT DO NOTHING;
