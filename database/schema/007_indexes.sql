-- Índices para bandejas, búsquedas y analítica futura.

CREATE INDEX idx_units_parent ON units (parent_unit_id);
CREATE INDEX idx_units_active ON units (is_active);

CREATE INDEX idx_employees_unit ON employees (unit_id);
CREATE INDEX idx_employees_position ON employees (position_id);
CREATE INDEX idx_employees_active ON employees (is_active);
CREATE INDEX idx_employees_user ON employees (user_id);

CREATE INDEX idx_correspondences_fiscal_year ON correspondences (fiscal_year_id);
CREATE INDEX idx_correspondences_type ON correspondences (type_id);
CREATE INDEX idx_correspondences_registered_by ON correspondences (registered_by);
CREATE INDEX idx_correspondences_registered_at ON correspondences (registered_at);
CREATE INDEX idx_correspondences_current_derivation ON correspondences (current_derivation_id);
CREATE INDEX idx_correspondences_cite ON correspondences (cite);

CREATE INDEX idx_derivations_correspondence ON derivations (correspondence_id);
CREATE INDEX idx_derivations_sender ON derivations (sender_employee_id);
CREATE INDEX idx_derivations_recipient ON derivations (recipient_employee_id);
CREATE INDEX idx_derivations_origin_unit ON derivations (origin_unit_id);
CREATE INDEX idx_derivations_destination_unit ON derivations (destination_unit_id);
CREATE INDEX idx_derivations_status ON derivations (status_id);
CREATE INDEX idx_derivations_sent_at ON derivations (sent_at);
CREATE INDEX idx_derivations_received_at ON derivations (received_at);

CREATE INDEX idx_attachments_correspondence ON attachments (correspondence_id);
CREATE INDEX idx_attachments_derivation ON attachments (derivation_id);

CREATE INDEX idx_audit_logs_user ON audit_logs (user_id);
CREATE INDEX idx_audit_logs_entity ON audit_logs (entity_type, entity_id);
CREATE INDEX idx_audit_logs_created_at ON audit_logs (created_at);
