-- Correspondencia, hoja de ruta (derivaciones) y adjuntos.

CREATE TABLE correspondences (
    id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    unique_number        INTEGER      NOT NULL,
    fiscal_year_id       UUID         NOT NULL REFERENCES fiscal_years (id),
    cite                 VARCHAR(150),
    type_id              UUID         NOT NULL REFERENCES correspondence_types (id),
    priority_id          UUID REFERENCES priorities (id) ON DELETE SET NULL,
    reference_id         UUID REFERENCES references_catalog (id) ON DELETE SET NULL,
    subject              TEXT         NOT NULL,
    external_sender      VARCHAR(300),
    external_recipient   VARCHAR(300),
    registered_by        UUID         NOT NULL REFERENCES employees (id),
    overall_status       VARCHAR(50),
    observations         TEXT,
    registered_at        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    created_at           TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_correspondences_number_year UNIQUE (fiscal_year_id, unique_number)
);

CREATE TABLE derivations (
    id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    correspondence_id    UUID         NOT NULL REFERENCES correspondences (id) ON DELETE CASCADE,
    sequence_number      INTEGER      NOT NULL,
    sender_employee_id   UUID         NOT NULL REFERENCES employees (id),
    recipient_employee_id UUID        NOT NULL REFERENCES employees (id),
    origin_unit_id       UUID         NOT NULL REFERENCES units (id),
    destination_unit_id  UUID         NOT NULL REFERENCES units (id),
    instruction_id       UUID REFERENCES instructions (id) ON DELETE SET NULL,
    status_id            UUID         NOT NULL REFERENCES derivation_statuses (id),
    observation          TEXT,
    sent_at              TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    received_at          TIMESTAMPTZ,
    concluded_at         TIMESTAMPTZ,
    archived_at          TIMESTAMPTZ,
    created_at           TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_derivations_correspondence_sequence UNIQUE (correspondence_id, sequence_number),
    CONSTRAINT chk_derivations_sequence_positive CHECK (sequence_number > 0)
);

-- Puntero opcional a la derivación activa para consultas rápidas de bandejas.
ALTER TABLE correspondences
    ADD COLUMN current_derivation_id UUID REFERENCES derivations (id) ON DELETE SET NULL;

CREATE TABLE attachments (
    id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    correspondence_id  UUID         NOT NULL REFERENCES correspondences (id) ON DELETE CASCADE,
    derivation_id        UUID REFERENCES derivations (id) ON DELETE SET NULL,
    original_name        VARCHAR(255) NOT NULL,
    storage_path         VARCHAR(500) NOT NULL,
    mime_type            VARCHAR(100),
    size_bytes           BIGINT,
    file_hash            VARCHAR(128),
    uploaded_by          UUID         NOT NULL REFERENCES employees (id),
    uploaded_at          TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    created_at           TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
