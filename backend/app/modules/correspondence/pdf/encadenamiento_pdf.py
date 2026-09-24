"""Generador PDF — Encadenamiento de documentos internos y externos (GAM Sipe Sipe)."""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime
from io import BytesIO
from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.pagesizes import letter
from reportlab.lib.units import inch
from reportlab.pdfgen import canvas

MONTHS_ES = (
    "ENERO",
    "FEBRERO",
    "MARZO",
    "ABRIL",
    "MAYO",
    "JUNIO",
    "JULIO",
    "AGOSTO",
    "SEPTIEMBRE",
    "OCTUBRE",
    "NOVIEMBRE",
    "DICIEMBRE",
)

MOVEMENT_TYPE_LABELS = {
    "CREATED": "Registro",
    "DERIVED": "Derivación",
    "RECEIVED": "Recepción",
    "RESPONDED": "Respuesta",
    "CONCLUDED": "Conclusión",
    "REOPENED": "Reapertura",
    "CANCELLED": "Cancelación",
    "ANNULLED": "Anulación",
}

RECIPIENTS_ON_FIRST_PAGE = 4
RECIPIENTS_ON_CONTINUATION_PAGE = 4

RECIPIENT_ORDINALS = (
    "Primer",
    "Segundo",
    "Tercer",
    "Cuarto",
    "Quinto",
    "Sexto",
    "Séptimo",
    "Octavo",
    "Noveno",
    "Décimo",
)


@dataclass(frozen=True, slots=True)
class EncadenamientoMovementRow:
    sequence_number: int
    movement_type: str
    movement_type_label: str
    from_unit: str | None
    from_user: str | None
    to_unit: str | None
    to_user: str | None
    instruction: str | None
    created_at: datetime
    is_cancelled: bool
    cancellation_reason: str | None


@dataclass(frozen=True, slots=True)
class EncadenamientoPdfContext:
    route_number: str
    route_sequence: int
    document_number: str
    correspondence_type: str
    para: str
    de: str
    referencia: str
    issued_at: datetime
    generated_at: datetime
    page_count_label: str = "—"
    is_urgent: bool = False
    movements: tuple[EncadenamientoMovementRow, ...] = ()
    logo_path: Path | None = None


def generate_encadenamiento_pdf(context: EncadenamientoPdfContext) -> bytes:
    buffer = BytesIO()
    page_width, page_height = letter
    margin = 0.45 * inch
    inner_left = margin
    inner_right = page_width - margin
    inner_bottom = margin
    inner_top = page_height - margin
    inner_width = inner_right - inner_left

    c = canvas.Canvas(buffer, pagesize=letter)
    recipients = [
        movement
        for movement in context.movements
        if movement.movement_type == "DERIVED"
    ]

    if not recipients:
        _draw_page_frame(c, inner_left, inner_bottom, inner_width, inner_top - inner_bottom)
        y = _draw_header(c, context, inner_left, inner_top, inner_width, inner_right)
        y = _draw_general_section(c, context, inner_left, inner_width, y)
        y -= 0.15 * inch
        c.setFont("Helvetica-Oblique", 9)
        c.drawString(inner_left + 0.12 * inch, y, "Sin destinatarios registrados.")
        _draw_footer(c, context, inner_left, inner_right, inner_bottom + 0.12 * inch)
        c.showPage()
        c.save()
        return buffer.getvalue()

    first_chunk = recipients[:RECIPIENTS_ON_FIRST_PAGE]
    remaining = recipients[RECIPIENTS_ON_FIRST_PAGE:]
    recipient_offset = 0

    _draw_page_frame(c, inner_left, inner_bottom, inner_width, inner_top - inner_bottom)
    y = _draw_header(c, context, inner_left, inner_top, inner_width, inner_right)
    y = _draw_general_section(c, context, inner_left, inner_width, y)
    _draw_recipient_blocks(
        c,
        inner_left,
        inner_right,
        y - 0.08 * inch,
        first_chunk,
        start_index=recipient_offset,
    )
    _draw_footer(c, context, inner_left, inner_right, inner_bottom + 0.12 * inch)
    c.showPage()
    recipient_offset += len(first_chunk)

    while remaining:
        chunk = remaining[:RECIPIENTS_ON_CONTINUATION_PAGE]
        remaining = remaining[RECIPIENTS_ON_CONTINUATION_PAGE:]

        _draw_page_frame(c, inner_left, inner_bottom, inner_width, inner_top - inner_bottom)
        y = _draw_continuation_header(
            c,
            context,
            inner_left,
            inner_top,
            inner_width,
            inner_right,
        )
        _draw_recipient_blocks(
            c,
            inner_left,
            inner_right,
            y - 0.08 * inch,
            chunk,
            start_index=recipient_offset,
            continuation=True,
        )
        _draw_footer(c, context, inner_left, inner_right, inner_bottom + 0.12 * inch)
        c.showPage()
        recipient_offset += len(chunk)

    c.save()
    return buffer.getvalue()


def _draw_page_frame(
    c: canvas.Canvas,
    left: float,
    bottom: float,
    width: float,
    height: float,
) -> None:
    c.setLineWidth(1)
    c.rect(left, bottom, width, height)


def _draw_header(
    c: canvas.Canvas,
    context: EncadenamientoPdfContext,
    inner_left: float,
    inner_top: float,
    inner_width: float,
    inner_right: float,
) -> float:
    y = inner_top - 0.15 * inch

    logo_size = 0.85 * inch
    logo_x = inner_left + 0.12 * inch
    logo_y = y - logo_size
    if context.logo_path and context.logo_path.is_file():
        c.drawImage(
            str(context.logo_path),
            logo_x,
            logo_y,
            width=logo_size,
            height=logo_size,
            preserveAspectRatio=True,
            mask="auto",
        )
    else:
        c.setLineWidth(0.75)
        c.rect(logo_x, logo_y, logo_size, logo_size)
        c.setFont("Helvetica-Bold", 7)
        c.drawCentredString(logo_x + logo_size / 2, logo_y + logo_size / 2 - 4, "SIPE")
        c.drawCentredString(logo_x + logo_size / 2, logo_y + logo_size / 2 - 14, "SIPE")

    header_center_x = inner_left + inner_width / 2
    c.setFont("Helvetica-Bold", 11)
    c.drawCentredString(header_center_x, y - 0.12 * inch, "GOBIERNO AUTÓNOMO MUNICIPAL DE SIPE SIPE")
    c.setFont("Helvetica", 9)
    c.drawCentredString(
        header_center_x,
        y - 0.28 * inch,
        "SEGUNDA SECCIÓN DE LA PROVINCIA QUILLACOLLO",
    )
    c.setFont("Helvetica-Oblique", 8.5)
    c.drawCentredString(
        header_center_x,
        y - 0.42 * inch,
        '"Sipe Sipe Construyendo Nuestro Futuro"',
    )

    number_box_w = 0.95 * inch
    number_box_h = 0.45 * inch
    number_box_x = inner_right - number_box_w - 0.1 * inch
    number_box_y = y - 0.05 * inch - number_box_h
    c.setLineWidth(0.75)
    c.rect(number_box_x, number_box_y, number_box_w, number_box_h)
    c.setFont("Helvetica-Bold", 9)
    c.drawString(number_box_x + 6, number_box_y + number_box_h - 14, "Nº:")
    c.setFillColor(colors.red)
    c.setFont("Helvetica-Bold", 11)
    c.drawString(number_box_x + 28, number_box_y + 6, context.document_number or "—")
    c.setFillColor(colors.black)

    y -= 0.95 * inch
    title_h = 0.32 * inch
    title_x = inner_left + 0.35 * inch
    title_w = inner_width - 0.7 * inch
    c.roundRect(title_x, y - title_h, title_w, title_h, 8)
    c.setFont("Helvetica-Bold", 9.5)
    c.drawCentredString(
        inner_left + inner_width / 2,
        y - title_h / 2 - 3,
        "ENCADENAMIENTO DE DOCUMENTOS INTERNOS Y EXTERNOS",
    )
    return y - title_h - 0.18 * inch


def _draw_continuation_header(
    c: canvas.Canvas,
    context: EncadenamientoPdfContext,
    inner_left: float,
    inner_top: float,
    inner_width: float,
    inner_right: float,
) -> float:
    y = inner_top - 0.2 * inch
    c.setFont("Helvetica-Bold", 10)
    c.drawString(inner_left + 0.12 * inch, y, f"HR: {context.route_number}")
    c.setFont("Helvetica", 8.5)
    c.drawRightString(
        inner_right - 0.12 * inch,
        y,
        "ENCADENAMIENTO — continuación",
    )
    y -= 0.22 * inch
    _draw_horizontal_rule(c, inner_left + 0.08 * inch, inner_right - 0.08 * inch, y)
    return y - 0.12 * inch


def _draw_general_section(
    c: canvas.Canvas,
    context: EncadenamientoPdfContext,
    inner_left: float,
    inner_width: float,
    y: float,
) -> float:
    c.setFont("Helvetica", 9)
    y = _draw_labeled_line(
        c, inner_left + 0.12 * inch, y, inner_width - 0.24 * inch, "PARA:", context.para
    )
    y = _draw_labeled_line(
        c, inner_left + 0.12 * inch, y, inner_width - 0.24 * inch, "DE:", context.de
    )
    y = _draw_labeled_line(
        c,
        inner_left + 0.12 * inch,
        y,
        inner_width - 0.24 * inch,
        "REFERENCIA:",
        context.referencia,
    )

    day = context.issued_at.day
    month = MONTHS_ES[context.issued_at.month - 1]
    year = context.issued_at.year
    hour = context.issued_at.strftime("%H:%M")
    fecha_text = f"{day:02d} DE {month} {year}"
    y -= 0.04 * inch
    c.setFont("Helvetica-Bold", 9)
    c.drawString(inner_left + 0.12 * inch, y, "FECHA DE EMISIÓN:")
    c.setFont("Helvetica", 9)
    c.drawString(inner_left + 1.35 * inch, y, fecha_text)
    c.setFont("Helvetica-Bold", 9)
    c.drawString(inner_left + 4.2 * inch, y, "HORA:")
    c.setFont("Helvetica", 9)
    c.drawString(inner_left + 4.75 * inch, y, hour)
    c.setFont("Helvetica-Bold", 9)
    c.drawString(inner_left + 5.55 * inch, y, "Nº DE HOJAS:")
    c.setFont("Helvetica", 9)
    c.drawString(inner_left + 6.45 * inch, y, context.page_count_label)

    y -= 0.18 * inch
    c.setFont("Helvetica-Bold", 9)
    c.drawString(inner_left + 0.12 * inch, y, "URGENTE:")
    c.setFont("Helvetica-Bold", 9)
    if context.is_urgent:
        c.drawString(inner_left + 0.85 * inch, y, "SÍ")
    else:
        c.drawString(inner_left + 0.85 * inch, y, "NO")

    c.setFont("Helvetica-Bold", 9)
    c.drawString(inner_left + 2.2 * inch, y, "HOJA DE RUTA:")
    c.setFont("Helvetica", 9)
    c.drawString(inner_left + 3.35 * inch, y, context.route_number)

    y -= 0.12 * inch
    return y


def _recipient_label(index: int, *, continuation: bool = False) -> str:
    if index < len(RECIPIENT_ORDINALS):
        return f"{RECIPIENT_ORDINALS[index]} destinatario"
    if continuation:
        return f"Destinatario {index + 1}"
    return f"Destinatario {index + 1}"


def _draw_recipient_blocks(
    c: canvas.Canvas,
    inner_left: float,
    inner_right: float,
    y: float,
    movements: list[EncadenamientoMovementRow],
    *,
    start_index: int,
    continuation: bool = False,
) -> float:
    block_width = inner_right - inner_left - 0.2 * inch
    block_x = inner_left + 0.1 * inch

    for offset, movement in enumerate(movements):
        label = _recipient_label(start_index + offset, continuation=continuation)
        block_h = 0.95 * inch
        y -= block_h + 0.08 * inch

        c.setLineWidth(0.75)
        c.rect(block_x, y, block_width, block_h)
        c.setFont("Helvetica-Bold", 8.5)
        c.drawString(block_x + 6, y + block_h - 12, label.upper())

        text_y = y + block_h - 28
        c.setFont("Helvetica", 8)
        c.drawString(block_x + 8, text_y, f"Unidad: {_truncate(movement.to_unit or '—', 70)}")
        text_y -= 12
        c.drawString(block_x + 8, text_y, f"Funcionario: {_truncate(movement.to_user or '—', 70)}")
        text_y -= 12
        c.drawString(
            block_x + 8,
            text_y,
            f"Instructivo / Proveído: {_truncate(movement.instruction or '—', 70)}",
        )
        text_y -= 12
        c.drawString(
            block_x + 8,
            text_y,
            f"Fecha: {_format_datetime(movement.created_at)}   Estado: {_movement_status(movement)}",
        )
        if movement.is_cancelled and movement.cancellation_reason:
            text_y -= 12
            c.setFont("Helvetica-Oblique", 7.5)
            c.drawString(
                block_x + 8,
                text_y,
                f"Motivo cancelación: {_truncate(movement.cancellation_reason, 80)}",
            )

        sig_y = y + 8
        c.setFont("Helvetica", 7)
        c.drawString(block_x + block_width * 0.55, sig_y + 18, "Firma:")
        c.line(block_x + block_width * 0.55, sig_y + 12, inner_right - 0.18 * inch, sig_y + 12)

    return y


def _draw_movements_table(
    c: canvas.Canvas,
    inner_left: float,
    inner_right: float,
    y: float,
    movements: list[EncadenamientoMovementRow],
    *,
    title: str,
) -> float:
    c.setFont("Helvetica-Bold", 9)
    c.drawString(inner_left + 0.12 * inch, y, title)
    y -= 0.16 * inch

    columns = [
        ("Sec.", 0.35 * inch),
        ("Tipo", 0.75 * inch),
        ("Desde", 1.35 * inch),
        ("Hacia", 1.35 * inch),
        ("Instrucción", 1.45 * inch),
        ("Fecha", 0.85 * inch),
        ("Estado", 0.65 * inch),
    ]
    x = inner_left + 0.1 * inch
    c.setFont("Helvetica-Bold", 7.5)
    for label, width in columns:
        c.drawString(x + 2, y, label)
        x += width
    y -= 0.06 * inch
    _draw_horizontal_rule(c, inner_left + 0.08 * inch, inner_right - 0.08 * inch, y)
    y -= 0.14 * inch

    row_height = 0.34 * inch
    c.setFont("Helvetica", 7.2)
    for movement in movements:
        x = inner_left + 0.1 * inch
        values = [
            str(movement.sequence_number),
            movement.movement_type_label,
            _format_route(movement.from_unit, movement.from_user),
            _format_route(movement.to_unit, movement.to_user),
            _truncate(movement.instruction or "—", 42),
            _format_datetime(movement.created_at),
            _movement_status(movement),
        ]
        for value, (_, width) in zip(values, columns, strict=True):
            c.drawString(x + 2, y, value)
            x += width
        if movement.is_cancelled and movement.cancellation_reason:
            c.setFont("Helvetica-Oblique", 6.8)
            c.drawString(
                inner_left + 0.12 * inch,
                y - 0.11 * inch,
                f"Motivo: {_truncate(movement.cancellation_reason, 90)}",
            )
            c.setFont("Helvetica", 7.2)
            y -= 0.11 * inch
        y -= row_height

    return y


def _draw_footer(
    c: canvas.Canvas,
    context: EncadenamientoPdfContext,
    inner_left: float,
    inner_right: float,
    y: float,
) -> None:
    generated = context.generated_at.strftime("%d/%m/%Y %H:%M")
    c.setFont("Helvetica", 7)
    c.drawString(
        inner_left + 0.12 * inch,
        y,
        f"Generado: {generated} UTC",
    )
    c.drawRightString(
        inner_right - 0.12 * inch,
        y,
        f"HR {context.route_number}",
    )


def _format_route(unit: str | None, user: str | None) -> str:
    unit = (unit or "").strip()
    user = (user or "").strip()
    if unit and user:
        return _truncate(f"{unit} / {user}", 28)
    return _truncate(unit or user or "—", 28)


def _format_datetime(value: datetime) -> str:
    return value.strftime("%d/%m/%Y %H:%M")


def _movement_status(movement: EncadenamientoMovementRow) -> str:
    if movement.is_cancelled:
        return "CANCELADO"
    return "VIGENTE"


def _truncate(value: str, max_len: int) -> str:
    text = value.strip()
    if len(text) <= max_len:
        return text
    return text[: max_len - 1] + "…"


def _draw_labeled_line(
    c: canvas.Canvas,
    x: float,
    y: float,
    width: float,
    label: str,
    value: str,
) -> float:
    c.setFont("Helvetica-Bold", 9)
    c.drawString(x, y, label)
    label_width = c.stringWidth(label, "Helvetica-Bold", 9)
    line_start = x + label_width + 4
    c.setFont("Helvetica", 9)
    if value.strip():
        c.drawString(line_start, y, value.strip())
    else:
        c.line(line_start, y - 2, x + width, y - 2)
    return y - 0.2 * inch


def _draw_horizontal_rule(c: canvas.Canvas, left: float, right: float, y: float) -> None:
    c.setLineWidth(0.75)
    c.line(left, y, right, y)
