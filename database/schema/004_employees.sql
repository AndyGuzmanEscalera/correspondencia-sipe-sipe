-- Funcionarios vinculados opcionalmente a cuentas de usuario.

CREATE TABLE employees (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id       UUID UNIQUE REFERENCES users (id) ON DELETE SET NULL,
    full_name     VARCHAR(200) NOT NULL,
    document_id   VARCHAR(30),
    position_id   UUID REFERENCES positions (id) ON DELETE SET NULL,
    unit_id       UUID REFERENCES units (id) ON DELETE SET NULL,
    profession_id UUID REFERENCES professions (id) ON DELETE SET NULL,
    grade_id      UUID REFERENCES grades (id) ON DELETE SET NULL,
    is_active     BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
