import math
import uuid
from dataclasses import dataclass
from datetime import datetime, timezone

from fastapi import HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.modules.correspondence.constants import (
    CORRESPONDENCE_TYPE_EXTERNAL,
    CORRESPONDENCE_TYPE_INTERNAL,
    MOVEMENT_CREATED,
    MOVEMENT_DERIVED,
    ROUTE_NUMBER_PREFIX,
    STATUS_ACTIVE,
)
from app.modules.correspondence.correspondence import Correspondence
from app.modules.correspondence.correspondence_movement import CorrespondenceMovement
from app.modules.correspondence.correspondence_document_sequence import (
    CorrespondenceDocumentSequence,
)
from app.modules.correspondence.correspondence_route_sequence import (
    CorrespondenceRouteSequence,
)
from app.modules.correspondence.document_type import DocumentType
from app.modules.correspondence.document_type_profiles import (
    DocumentFormProfile,
    resolve_document_form_profile,
    supports_encadenamiento_pdf,
)
from app.modules.correspondence.schemas import (
    CorrespondenceDetail,
    CorrespondenceInboxCountsResponse,
    CorrespondenceListItem,
    CorrespondenceListResponse,
    CorrespondenceMovementResponse,
    CreateCorrespondenceRequest,
    DeriveCorrespondenceRequest,
    DocumentTypeResponse,
    EmployeeOptionResponse,
)
from app.modules.correspondence.pdf.encadenamiento_builder import (
    build_encadenamiento_context,
    movement_type_label,
    resolve_de,
    resolve_para,
)
from app.modules.correspondence.pdf.encadenamiento_pdf import (
    EncadenamientoMovementRow,
    generate_encadenamiento_pdf,
)
from app.modules.identity.user import User
from app.modules.organization.employee import Employee
from app.modules.organization.organizational_unit import OrganizationalUnit
from app.modules.organization.position import Position


@dataclass(frozen=True)
class InstitutionalResponsible:
    user_id: uuid.UUID
    unit_id: uuid.UUID


@dataclass(frozen=True)
class InboxInstitutionalContext:
    user_id: uuid.UUID
    unit_id: uuid.UUID


@dataclass(frozen=True)
class ResolvedOrigin:
    correspondence_type: str
    origin_employee_id: uuid.UUID | None
    origin_unit_id: uuid.UUID | None
    sender_name: str | None
    sender_document: str | None
    sender_contact: str | None
    origin_description: str | None


class CorrespondenceService:
    """Business logic for correspondence milestone 1."""

    def __init__(self, db: Session) -> None:
        self._db = db

    # ── Public API ───────────────────────────────────────────────────

    def list_document_types(self) -> list[DocumentTypeResponse]:
        rows = self._db.scalars(
            select(DocumentType)
            .where(DocumentType.is_active == True)  # noqa: E712
            .order_by(DocumentType.name)
        ).all()
        return [
            DocumentTypeResponse(id=row.id, code=row.code, name=row.name)
            for row in rows
        ]

    def list_active_employees(self) -> list[EmployeeOptionResponse]:
        rows = self._db.scalars(
            select(Employee)
            .where(Employee.is_active == True)  # noqa: E712
            .order_by(Employee.last_name, Employee.first_name)
        ).all()
        return [self._to_employee_option(row) for row in rows]

    def list_correspondences(
        self,
        *,
        page: int,
        page_size: int,
        status_filter: str | None,
        correspondence_type: str | None,
        search: str | None,
        active_only: bool = True,
    ) -> CorrespondenceListResponse:
        """Operational listing. Routers MUST pass active_only=True; audit/admin
        access to inactive records will use a dedicated endpoint later."""
        query = self._base_correspondence_query(active_only=active_only)
        query = self._apply_list_filters(
            query,
            status_filter=status_filter,
            correspondence_type=correspondence_type,
            search=search,
        )
        return self._paginate_correspondences(query, page=page, page_size=page_size)

    def list_inbox(
        self,
        user: User,
        *,
        scope: str,
        page: int,
        page_size: int,
        search: str | None,
    ) -> CorrespondenceListResponse:
        """Inbox listing scoped to the authenticated user's institutional identity."""
        if scope not in {"mine", "unit"}:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="scope debe ser 'mine' o 'unit'",
            )

        context = self._resolve_inbox_context(user)
        if context is None:
            return self._empty_correspondence_page(page=page, page_size=page_size)

        query = self._base_correspondence_query(active_only=True).where(
            Correspondence.status == STATUS_ACTIVE
        )
        if scope == "mine":
            query = query.where(Correspondence.current_user_id == context.user_id)
        else:
            query = query.where(Correspondence.current_unit_id == context.unit_id)

        query = self._apply_search_filter(query, search)
        return self._paginate_correspondences(query, page=page, page_size=page_size)

    def get_inbox_counts(self, user: User) -> CorrespondenceInboxCountsResponse:
        context = self._resolve_inbox_context(user)
        if context is None:
            return CorrespondenceInboxCountsResponse(mine=0, unit=0)

        base = self._base_correspondence_query(active_only=True).where(
            Correspondence.status == STATUS_ACTIVE
        )
        mine = self._db.scalar(
            select(func.count())
            .select_from(base.where(Correspondence.current_user_id == context.user_id).subquery())
        ) or 0
        unit = self._db.scalar(
            select(func.count())
            .select_from(base.where(Correspondence.current_unit_id == context.unit_id).subquery())
        ) or 0
        return CorrespondenceInboxCountsResponse(mine=mine, unit=unit)

    def get_correspondence(
        self,
        correspondence_id: uuid.UUID,
        *,
        active_only: bool = True,
    ) -> CorrespondenceDetail:
        correspondence = self._get_correspondence_or_404(
            correspondence_id,
            active_only=active_only,
        )
        return self._to_detail(correspondence)

    def create_correspondence(
        self,
        user: User,
        body: CreateCorrespondenceRequest,
    ) -> CorrespondenceDetail:
        responsible = self._resolve_institutional_responsible(user)
        doc_type = self._validate_document_type(body.document_type_id)
        profile = resolve_document_form_profile(doc_type.code)

        origin = self._resolve_origin_fields(body, profile, user=user)
        subject = self._resolve_subject(body, profile)
        description = self._normalize_optional_text(body.description)

        route_year, route_sequence, route_number = self._allocate_route_number()
        doc_year, doc_sequence, doc_number = self._allocate_document_number(
            body.document_type_id
        )

        self._validate_destination(body.initial_to_unit_id, body.initial_to_user_id)

        correspondence = Correspondence(
            route_number=route_number,
            route_sequence=route_sequence,
            route_year=route_year,
            document_sequence=doc_sequence,
            document_year=doc_year,
            document_number=doc_number,
            correspondence_type=origin.correspondence_type,
            document_type_id=body.document_type_id,
            subject=subject,
            reference=self._normalize_optional_text(body.reference),
            description=description,
            priority=body.priority,
            status=STATUS_ACTIVE,
            sender_name=origin.sender_name,
            sender_document=origin.sender_document,
            sender_contact=origin.sender_contact,
            origin_description=origin.origin_description,
            origin_unit_id=origin.origin_unit_id,
            origin_user_id=None,
            origin_employee_id=origin.origin_employee_id,
            current_unit_id=body.initial_to_unit_id,
            current_user_id=body.initial_to_user_id,
            created_by_user_id=user.id,
            is_active=True,
        )
        self._db.add(correspondence)
        self._db.flush()

        self._add_movement(
            correspondence=correspondence,
            sequence_number=1,
            movement_type=MOVEMENT_CREATED,
            from_unit_id=None,
            from_user_id=None,
            to_unit_id=responsible.unit_id,
            to_user_id=responsible.user_id,
            instruction=None,
            observation=None,
            created_by_user_id=user.id,
        )

        self._add_movement(
            correspondence=correspondence,
            sequence_number=2,
            movement_type=MOVEMENT_DERIVED,
            from_unit_id=responsible.unit_id,
            from_user_id=responsible.user_id,
            to_unit_id=body.initial_to_unit_id,
            to_user_id=body.initial_to_user_id,
            instruction=body.initial_instruction,
            observation=None,
            created_by_user_id=user.id,
        )

        self._db.commit()
        self._db.refresh(correspondence)
        return self._to_detail(correspondence)

    def derive_correspondence(
        self,
        user: User,
        correspondence_id: uuid.UUID,
        body: DeriveCorrespondenceRequest,
    ) -> CorrespondenceDetail:
        correspondence = self._db.scalar(
            select(Correspondence)
            .where(Correspondence.id == correspondence_id)
            .with_for_update()
        )
        if correspondence is None or not correspondence.is_active:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Correspondencia no encontrada",
            )
        if correspondence.status != STATUS_ACTIVE:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="Solo se pueden derivar trámites activos",
            )

        self._validate_destination(body.to_unit_id, body.to_user_id)

        next_sequence = self._next_movement_sequence(correspondence.id)

        self._add_movement(
            correspondence=correspondence,
            sequence_number=next_sequence,
            movement_type=MOVEMENT_DERIVED,
            from_unit_id=correspondence.current_unit_id,
            from_user_id=correspondence.current_user_id,
            to_unit_id=body.to_unit_id,
            to_user_id=body.to_user_id,
            instruction=body.instruction,
            observation=body.observation,
            created_by_user_id=user.id,
        )

        correspondence.current_unit_id = body.to_unit_id
        correspondence.current_user_id = body.to_user_id
        correspondence.updated_at = datetime.now(timezone.utc)

        self._db.commit()
        self._db.refresh(correspondence)
        return self._to_detail(correspondence)

    def generate_encadenamiento_pdf_bytes(
        self,
        correspondence_id: uuid.UUID,
        *,
        active_only: bool = True,
    ) -> tuple[bytes, str]:
        """Genera on-demand el PDF de encadenamiento desde el estado actual."""
        correspondence = self._get_correspondence_or_404(
            correspondence_id,
            active_only=active_only,
        )
        doc_type = self._document_type(correspondence.document_type_id)
        if not supports_encadenamiento_pdf(doc_type.code):
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail=(
                    "El PDF de encadenamiento solo aplica al tipo de documento "
                    "Encadenamiento"
                ),
            )
        movement_rows = self._load_encadenamiento_movements(correspondence_id)
        generated_at = datetime.now(timezone.utc)
        issued_at = correspondence.created_at
        if issued_at.tzinfo is None:
            issued_at = issued_at.replace(tzinfo=timezone.utc)

        settings = get_settings()
        logo_path = settings.institutional_logo_path
        if logo_path is not None and not logo_path.is_file():
            logo_path = None

        para = resolve_para(
            current_unit_name=self._unit_name(correspondence.current_unit_id),
            current_user_name=self._user_display_name(correspondence.current_user_id),
            movement_rows=movement_rows,
        )
        de = resolve_de(
            correspondence=correspondence,
            origin_employee_name=self._employee_display_name(
                correspondence.origin_employee_id
            ),
            origin_unit_name=self._unit_name(correspondence.origin_unit_id),
            origin_position_name=self._employee_position_name(
                correspondence.origin_employee_id
            ),
        )

        try:
            context = build_encadenamiento_context(
                correspondence=correspondence,
                movement_rows=movement_rows,
                para=para,
                de=de,
                issued_at=issued_at,
                generated_at=generated_at,
                logo_path=logo_path,
            )
            pdf_bytes = generate_encadenamiento_pdf(context)
        except ImportError as exc:
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail=(
                    "Generación de PDF no disponible: falta instalar reportlab "
                    "en el backend (pip install -r requirements.txt o rebuild Docker)."
                ),
            ) from exc
        except Exception as exc:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="No se pudo generar el PDF de encadenamiento",
            ) from exc

        safe_route = correspondence.route_number.replace("/", "-")
        filename = f"encadenamiento_{safe_route}.pdf"
        return pdf_bytes, filename

    def list_movements(
        self,
        correspondence_id: uuid.UUID,
        *,
        active_only: bool = True,
    ) -> list[CorrespondenceMovementResponse]:
        self._get_correspondence_or_404(correspondence_id, active_only=active_only)
        rows = self._db.scalars(
            select(CorrespondenceMovement)
            .where(CorrespondenceMovement.correspondence_id == correspondence_id)
            .order_by(CorrespondenceMovement.sequence_number)
        ).all()
        return [self._to_movement(row) for row in rows]

    # ── Internal helpers ─────────────────────────────────────────────

    def _get_correspondence_or_404(
        self,
        correspondence_id: uuid.UUID,
        *,
        active_only: bool,
    ) -> Correspondence:
        query = select(Correspondence).where(Correspondence.id == correspondence_id)
        if active_only:
            query = query.where(Correspondence.is_active == True)  # noqa: E712
        correspondence = self._db.scalar(query)
        if correspondence is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Correspondencia no encontrada",
            )
        return correspondence

    def _resolve_inbox_context(self, user: User) -> InboxInstitutionalContext | None:
        """Institutional identity for inbox queries (session-derived, never from client)."""
        if user.employee_id is None:
            return None
        employee = self._db.get(Employee, user.employee_id)
        if employee is None or not employee.is_active:
            return None
        if employee.unit_id is None:
            return None
        unit = self._db.get(OrganizationalUnit, employee.unit_id)
        if unit is None or not unit.is_active:
            return None
        return InboxInstitutionalContext(user_id=user.id, unit_id=employee.unit_id)

    @staticmethod
    def _base_correspondence_query(*, active_only: bool):
        query = select(Correspondence)
        if active_only:
            query = query.where(Correspondence.is_active == True)  # noqa: E712
        return query

    @staticmethod
    def _apply_search_filter(query, search: str | None):
        if not search:
            return query
        term = f"%{search.strip()}%"
        return query.where(
            Correspondence.subject.ilike(term)
            | Correspondence.route_number.ilike(term)
            | Correspondence.cite.ilike(term)
            | Correspondence.reference.ilike(term)
        )

    @staticmethod
    def _apply_list_filters(
        query,
        *,
        status_filter: str | None,
        correspondence_type: str | None,
        search: str | None,
    ):
        if status_filter:
            query = query.where(Correspondence.status == status_filter)
        if correspondence_type:
            query = query.where(
                Correspondence.correspondence_type == correspondence_type
            )
        return CorrespondenceService._apply_search_filter(query, search)

    def _paginate_correspondences(
        self,
        query,
        *,
        page: int,
        page_size: int,
    ) -> CorrespondenceListResponse:
        total = self._db.scalar(
            select(func.count()).select_from(query.subquery())
        ) or 0
        total_pages = max(1, math.ceil(total / page_size)) if total else 0
        offset = (page - 1) * page_size

        rows = self._db.scalars(
            query.order_by(Correspondence.created_at.desc())
            .offset(offset)
            .limit(page_size)
        ).all()

        items = [self._to_list_item(row) for row in rows]
        return CorrespondenceListResponse(
            items=items,
            page=page,
            page_size=page_size,
            total=total,
            total_pages=total_pages,
        )

    @staticmethod
    def _empty_correspondence_page(
        *,
        page: int,
        page_size: int,
    ) -> CorrespondenceListResponse:
        return CorrespondenceListResponse(
            items=[],
            page=page,
            page_size=page_size,
            total=0,
            total_pages=0,
        )

    def _resolve_institutional_responsible(self, user: User) -> InstitutionalResponsible:
        if user.employee_id is None:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail=(
                    "El usuario no tiene un funcionario asociado. "
                    "No puede registrar correspondencia."
                ),
            )
        employee = self._db.get(Employee, user.employee_id)
        if employee is None or not employee.is_active:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="El funcionario asociado no está activo",
            )
        if employee.unit_id is None:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail=(
                    "El funcionario no tiene una unidad organizacional asignada. "
                    "No puede registrar correspondencia."
                ),
            )
        unit = self._db.get(OrganizationalUnit, employee.unit_id)
        if unit is None or not unit.is_active:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="La unidad organizacional del funcionario no está activa",
            )
        return InstitutionalResponsible(user_id=user.id, unit_id=employee.unit_id)

    def _validate_document_type(self, document_type_id: uuid.UUID) -> DocumentType:
        doc_type = self._db.get(DocumentType, document_type_id)
        if doc_type is None or not doc_type.is_active:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="Tipo de documento inválido",
            )
        return doc_type

    def _resolve_origin_fields(
        self,
        body: CreateCorrespondenceRequest,
        profile: DocumentFormProfile,
        *,
        user: User,
    ) -> ResolvedOrigin:
        if profile in {
            DocumentFormProfile.TECHNICAL_REPORT,
            DocumentFormProfile.INTERNAL_NOTE,
        }:
            self._reject_external_sender_fields(body)
            employee = self._require_active_employee(body.origin_employee_id)
            return ResolvedOrigin(
                correspondence_type=CORRESPONDENCE_TYPE_INTERNAL,
                origin_employee_id=employee.id,
                origin_unit_id=employee.unit_id,
                sender_name=None,
                sender_document=None,
                sender_contact=None,
                origin_description=None,
            )

        if profile == DocumentFormProfile.CHAINING:
            if body.correspondence_type == CORRESPONDENCE_TYPE_EXTERNAL:
                sender_name = self._normalize_optional_text(body.sender_name)
                if not sender_name:
                    raise HTTPException(
                        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                        detail="El nombre del remitente externo es obligatorio",
                    )
                return ResolvedOrigin(
                    correspondence_type=CORRESPONDENCE_TYPE_EXTERNAL,
                    origin_employee_id=None,
                    origin_unit_id=None,
                    sender_name=sender_name,
                    sender_document=self._normalize_optional_text(body.sender_document),
                    sender_contact=self._normalize_optional_text(body.sender_contact),
                    origin_description=self._normalize_optional_text(
                        body.origin_description
                    ),
                )

            employee = self._require_active_employee(body.origin_employee_id)
            return ResolvedOrigin(
                correspondence_type=CORRESPONDENCE_TYPE_INTERNAL,
                origin_employee_id=employee.id,
                origin_unit_id=employee.unit_id,
                sender_name=None,
                sender_document=None,
                sender_contact=None,
                origin_description=None,
            )

        # Perfil genérico: conservar comportamiento previo simplificado.
        if body.correspondence_type == CORRESPONDENCE_TYPE_EXTERNAL:
            sender_name = self._normalize_optional_text(body.sender_name)
            if not sender_name:
                raise HTTPException(
                    status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                    detail="sender_name es obligatorio para correspondencia externa",
                )
            return ResolvedOrigin(
                correspondence_type=CORRESPONDENCE_TYPE_EXTERNAL,
                origin_employee_id=None,
                origin_unit_id=None,
                sender_name=sender_name,
                sender_document=self._normalize_optional_text(body.sender_document),
                sender_contact=self._normalize_optional_text(body.sender_contact),
                origin_description=self._normalize_optional_text(body.origin_description),
            )

        employee_id = body.origin_employee_id or user.employee_id
        employee = self._require_active_employee(employee_id)
        return ResolvedOrigin(
            correspondence_type=CORRESPONDENCE_TYPE_INTERNAL,
            origin_employee_id=employee.id,
            origin_unit_id=employee.unit_id,
            sender_name=None,
            sender_document=None,
            sender_contact=None,
            origin_description=None,
        )

    def _resolve_subject(
        self,
        body: CreateCorrespondenceRequest,
        profile: DocumentFormProfile,
    ) -> str:
        subject = self._normalize_optional_text(body.subject)
        description = self._normalize_optional_text(body.description)
        reference = self._normalize_optional_text(body.reference)

        if profile in {
            DocumentFormProfile.TECHNICAL_REPORT,
            DocumentFormProfile.INTERNAL_NOTE,
        }:
            if not description:
                raise HTTPException(
                    status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                    detail="La descripción es obligatoria para este tipo de documento",
                )
            if subject:
                return subject[:500]
            return description[:500]

        if profile == DocumentFormProfile.CHAINING:
            if subject:
                return subject[:500]
            if reference:
                return reference[:500]
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="El asunto o la referencia es obligatorio",
            )

        if not subject:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="El asunto es obligatorio",
            )
        return subject[:500]

    def _reject_external_sender_fields(self, body: CreateCorrespondenceRequest) -> None:
        if any(
            self._normalize_optional_text(value)
            for value in (
                body.sender_name,
                body.sender_document,
                body.sender_contact,
                body.origin_description,
            )
        ):
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="Los campos de remitente externo no aplican a este tipo de documento",
            )
        if body.correspondence_type == CORRESPONDENCE_TYPE_EXTERNAL:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="Este tipo de documento requiere origen interno (funcionario)",
            )

    def _require_active_employee(self, employee_id: uuid.UUID | None) -> Employee:
        if employee_id is None:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="Debe seleccionar el funcionario de origen",
            )
        employee = self._db.get(Employee, employee_id)
        if employee is None or not employee.is_active:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="Funcionario de origen no encontrado o inactivo",
            )
        if employee.unit_id is None:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="El funcionario de origen no tiene unidad asignada",
            )
        unit = self._db.get(OrganizationalUnit, employee.unit_id)
        if unit is None or not unit.is_active:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="La unidad del funcionario de origen no está activa",
            )
        return employee

    @staticmethod
    def _normalize_optional_text(value: str | None) -> str | None:
        if value is None:
            return None
        trimmed = value.strip()
        return trimmed or None

    def _allocate_document_number(
        self,
        document_type_id: uuid.UUID,
    ) -> tuple[int, int, str]:
        year = datetime.now(timezone.utc).year
        self._db.execute(
            insert(CorrespondenceDocumentSequence)
            .values(document_type_id=document_type_id, year=year, last_sequence=0)
            .on_conflict_do_nothing(
                index_elements=["document_type_id", "year"],
            )
        )
        seq_row = self._db.scalar(
            select(CorrespondenceDocumentSequence)
            .where(
                CorrespondenceDocumentSequence.document_type_id == document_type_id,
                CorrespondenceDocumentSequence.year == year,
            )
            .with_for_update()
        )
        if seq_row is None:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="No se pudo reservar secuencia del documento",
            )
        seq_row.last_sequence += 1
        sequence = seq_row.last_sequence
        return year, sequence, str(sequence)

    def _validate_destination(
        self,
        to_unit_id: uuid.UUID,
        to_user_id: uuid.UUID | None,
    ) -> None:
        unit = self._db.get(OrganizationalUnit, to_unit_id)
        if unit is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Unidad destino no encontrada",
            )
        if not unit.is_active:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="La unidad destino no está activa",
            )
        if to_user_id is None:
            return

        dest_user = self._db.get(User, to_user_id)
        if dest_user is None or not dest_user.is_active:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="Usuario destino no encontrado o inactivo",
            )
        if dest_user.employee_id is None:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="El usuario destino no tiene funcionario asociado",
            )
        employee = self._db.get(Employee, dest_user.employee_id)
        if employee is None or not employee.is_active:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="El funcionario destino no está activo",
            )
        if employee.unit_id != to_unit_id:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="El usuario destino no pertenece a la unidad indicada",
            )

    def _allocate_route_number(self) -> tuple[int, int, str]:
        year = datetime.now(timezone.utc).year
        self._db.execute(
            insert(CorrespondenceRouteSequence)
            .values(year=year, last_sequence=0)
            .on_conflict_do_nothing(index_elements=["year"])
        )
        seq_row = self._db.scalar(
            select(CorrespondenceRouteSequence)
            .where(CorrespondenceRouteSequence.year == year)
            .with_for_update()
        )
        if seq_row is None:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="No se pudo reservar secuencia de hoja de ruta",
            )
        seq_row.last_sequence += 1
        sequence = seq_row.last_sequence
        route_number = f"{ROUTE_NUMBER_PREFIX}-{year}-{sequence:06d}"
        return year, sequence, route_number

    def _next_movement_sequence(self, correspondence_id: uuid.UUID) -> int:
        current_max = self._db.scalar(
            select(func.max(CorrespondenceMovement.sequence_number)).where(
                CorrespondenceMovement.correspondence_id == correspondence_id
            )
        )
        return (current_max or 0) + 1

    def _load_encadenamiento_movements(
        self,
        correspondence_id: uuid.UUID,
    ) -> list[EncadenamientoMovementRow]:
        rows = self._db.scalars(
            select(CorrespondenceMovement)
            .where(CorrespondenceMovement.correspondence_id == correspondence_id)
            .order_by(CorrespondenceMovement.sequence_number)
        ).all()
        return [
            EncadenamientoMovementRow(
                sequence_number=row.sequence_number,
                movement_type=row.movement_type,
                movement_type_label=movement_type_label(row.movement_type),
                from_unit=self._unit_name(row.from_unit_id),
                from_user=self._user_display_name(row.from_user_id),
                to_unit=self._unit_name(row.to_unit_id),
                to_user=self._user_display_name(row.to_user_id),
                instruction=row.instruction,
                created_at=row.created_at,
                is_cancelled=row.cancelled_at is not None,
                cancellation_reason=row.cancellation_reason,
            )
            for row in rows
        ]

    def _add_movement(
        self,
        *,
        correspondence: Correspondence,
        sequence_number: int,
        movement_type: str,
        from_unit_id: uuid.UUID | None,
        from_user_id: uuid.UUID | None,
        to_unit_id: uuid.UUID | None,
        to_user_id: uuid.UUID | None,
        instruction: str | None,
        observation: str | None,
        created_by_user_id: uuid.UUID,
    ) -> CorrespondenceMovement:
        movement = CorrespondenceMovement(
            correspondence_id=correspondence.id,
            sequence_number=sequence_number,
            movement_type=movement_type,
            from_unit_id=from_unit_id,
            from_user_id=from_user_id,
            to_unit_id=to_unit_id,
            to_user_id=to_user_id,
            instruction=instruction,
            observation=observation,
            created_by_user_id=created_by_user_id,
        )
        self._db.add(movement)
        return movement

    def _unit_name(self, unit_id: uuid.UUID | None) -> str | None:
        if unit_id is None:
            return None
        unit = self._db.get(OrganizationalUnit, unit_id)
        return unit.name if unit else None

    def _user_display_name(self, user_id: uuid.UUID | None) -> str | None:
        if user_id is None:
            return None
        user = self._db.get(User, user_id)
        if user is None:
            return None
        if user.employee_id:
            return self._employee_display_name(user.employee_id)
        return user.username

    def _user_is_active(self, user_id: uuid.UUID | None) -> bool | None:
        if user_id is None:
            return None
        user = self._db.get(User, user_id)
        if user is None:
            return None
        return user.is_active

    def _employee_display_name(self, employee_id: uuid.UUID | None) -> str | None:
        if employee_id is None:
            return None
        employee = self._db.get(Employee, employee_id)
        if employee is None:
            return None
        return f"{employee.first_name} {employee.last_name}".strip()

    def _employee_position_name(self, employee_id: uuid.UUID | None) -> str | None:
        if employee_id is None:
            return None
        employee = self._db.get(Employee, employee_id)
        if employee is None or employee.position_id is None:
            return None
        position = self._db.get(Position, employee.position_id)
        return position.name if position else None

    def _to_employee_option(self, employee: Employee) -> EmployeeOptionResponse:
        unit_name = self._unit_name(employee.unit_id)
        position_name = self._employee_position_name(employee.id)
        return EmployeeOptionResponse(
            id=employee.id,
            full_name=self._employee_display_name(employee.id) or "",
            unit_id=employee.unit_id,
            unit_name=unit_name,
            position_name=position_name,
            document_number=employee.document_number,
        )

    def _document_type(self, document_type_id: uuid.UUID) -> DocumentType:
        doc_type = self._db.get(DocumentType, document_type_id)
        if doc_type is None:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Tipo de documento no encontrado",
            )
        return doc_type

    def _to_list_item(self, correspondence: Correspondence) -> CorrespondenceListItem:
        doc_type = self._document_type(correspondence.document_type_id)
        return CorrespondenceListItem(
            id=correspondence.id,
            route_number=correspondence.route_number,
            route_year=correspondence.route_year,
            route_sequence=correspondence.route_sequence,
            document_number=correspondence.document_number,
            document_sequence=correspondence.document_sequence,
            document_year=correspondence.document_year,
            correspondence_type=correspondence.correspondence_type,
            document_type_code=doc_type.code,
            document_type_name=doc_type.name,
            subject=correspondence.subject,
            reference=correspondence.reference,
            priority=correspondence.priority,
            status=correspondence.status,
            current_unit_id=correspondence.current_unit_id,
            current_unit_name=self._unit_name(correspondence.current_unit_id),
            current_user_id=correspondence.current_user_id,
            current_user_name=self._user_display_name(correspondence.current_user_id),
            current_user_is_active=self._user_is_active(correspondence.current_user_id),
            cite=correspondence.cite,
            registered_at=correspondence.created_at,
        )

    def _to_detail(self, correspondence: Correspondence) -> CorrespondenceDetail:
        base = self._to_list_item(correspondence)
        creator = self._db.get(User, correspondence.created_by_user_id)
        return CorrespondenceDetail(
            **base.model_dump(),
            description=correspondence.description,
            sender_name=correspondence.sender_name,
            sender_document=correspondence.sender_document,
            sender_contact=correspondence.sender_contact,
            origin_description=correspondence.origin_description,
            origin_unit_id=correspondence.origin_unit_id,
            origin_unit_name=self._unit_name(correspondence.origin_unit_id),
            origin_user_id=correspondence.origin_user_id,
            origin_user_name=self._user_display_name(correspondence.origin_user_id),
            origin_employee_id=correspondence.origin_employee_id,
            origin_employee_name=self._employee_display_name(
                correspondence.origin_employee_id
            ),
            cite_sequence=correspondence.cite_sequence,
            cite_year=correspondence.cite_year,
            concluded_at=correspondence.concluded_at,
            reopened_at=correspondence.reopened_at,
            created_by_user_id=correspondence.created_by_user_id,
            created_by_username=creator.username if creator else "",
        )

    def _to_movement(self, movement: CorrespondenceMovement) -> CorrespondenceMovementResponse:
        creator = self._db.get(User, movement.created_by_user_id)
        return CorrespondenceMovementResponse(
            id=movement.id,
            sequence_number=movement.sequence_number,
            movement_type=movement.movement_type,
            from_unit_name=self._unit_name(movement.from_unit_id),
            from_user_name=self._user_display_name(movement.from_user_id),
            to_unit_name=self._unit_name(movement.to_unit_id),
            to_user_name=self._user_display_name(movement.to_user_id),
            instruction=movement.instruction,
            observation=movement.observation,
            created_by_username=creator.username if creator else "",
            created_at=movement.created_at,
            cancelled_at=movement.cancelled_at,
            cancellation_reason=movement.cancellation_reason,
        )
