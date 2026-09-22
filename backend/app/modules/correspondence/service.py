import math
import uuid
from dataclasses import dataclass
from datetime import datetime, timezone

from fastapi import HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.orm import Session

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
from app.modules.correspondence.correspondence_route_sequence import (
    CorrespondenceRouteSequence,
)
from app.modules.correspondence.document_type import DocumentType
from app.modules.correspondence.schemas import (
    CorrespondenceDetail,
    CorrespondenceListItem,
    CorrespondenceListResponse,
    CorrespondenceMovementResponse,
    CreateCorrespondenceRequest,
    DeriveCorrespondenceRequest,
    DocumentTypeResponse,
)
from app.modules.identity.user import User
from app.modules.organization.employee import Employee
from app.modules.organization.organizational_unit import OrganizationalUnit


@dataclass(frozen=True)
class InstitutionalResponsible:
    user_id: uuid.UUID
    unit_id: uuid.UUID


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
        query = select(Correspondence)
        if active_only:
            query = query.where(Correspondence.is_active == True)  # noqa: E712
        if status_filter:
            query = query.where(Correspondence.status == status_filter)
        if correspondence_type:
            query = query.where(
                Correspondence.correspondence_type == correspondence_type
            )
        if search:
            term = f"%{search.strip()}%"
            query = query.where(
                Correspondence.subject.ilike(term)
                | Correspondence.route_number.ilike(term)
                | Correspondence.cite.ilike(term)
            )

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
        self._validate_document_type(body.document_type_id)

        if body.correspondence_type == CORRESPONDENCE_TYPE_INTERNAL:
            origin_unit_id = responsible.unit_id
            origin_user_id = responsible.user_id
            sender_name = None
            sender_document = None
            sender_contact = None
            origin_description = None
        else:
            if not body.sender_name or not body.sender_name.strip():
                raise HTTPException(
                    status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                    detail="sender_name es obligatorio para correspondencia externa",
                )
            origin_unit_id = None
            origin_user_id = None
            sender_name = body.sender_name.strip()
            sender_document = body.sender_document
            sender_contact = body.sender_contact
            origin_description = body.origin_description

        route_year, route_sequence, route_number = self._allocate_route_number()

        self._validate_destination(body.initial_to_unit_id, body.initial_to_user_id)

        correspondence = Correspondence(
            route_number=route_number,
            route_sequence=route_sequence,
            route_year=route_year,
            correspondence_type=body.correspondence_type,
            document_type_id=body.document_type_id,
            subject=body.subject.strip(),
            reference=body.reference,
            priority=body.priority,
            status=STATUS_ACTIVE,
            sender_name=sender_name,
            sender_document=sender_document,
            sender_contact=sender_contact,
            origin_description=origin_description,
            origin_unit_id=origin_unit_id,
            origin_user_id=origin_user_id,
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

    def _validate_document_type(self, document_type_id: uuid.UUID) -> None:
        doc_type = self._db.get(DocumentType, document_type_id)
        if doc_type is None or not doc_type.is_active:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="Tipo de documento inválido",
            )

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
            employee = self._db.get(Employee, user.employee_id)
            if employee:
                return f"{employee.first_name} {employee.last_name}".strip()
        return user.username

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
            correspondence_type=correspondence.correspondence_type,
            document_type_code=doc_type.code,
            document_type_name=doc_type.name,
            subject=correspondence.subject,
            priority=correspondence.priority,
            status=correspondence.status,
            current_unit_name=self._unit_name(correspondence.current_unit_id),
            current_user_name=self._user_display_name(correspondence.current_user_id),
            cite=correspondence.cite,
            registered_at=correspondence.created_at,
        )

    def _to_detail(self, correspondence: Correspondence) -> CorrespondenceDetail:
        base = self._to_list_item(correspondence)
        creator = self._db.get(User, correspondence.created_by_user_id)
        return CorrespondenceDetail(
            **base.model_dump(),
            reference=correspondence.reference,
            sender_name=correspondence.sender_name,
            sender_document=correspondence.sender_document,
            sender_contact=correspondence.sender_contact,
            origin_description=correspondence.origin_description,
            origin_unit_id=correspondence.origin_unit_id,
            origin_unit_name=self._unit_name(correspondence.origin_unit_id),
            origin_user_id=correspondence.origin_user_id,
            origin_user_name=self._user_display_name(correspondence.origin_user_id),
            current_unit_id=correspondence.current_unit_id,
            current_user_id=correspondence.current_user_id,
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
