"""Route sheet renderer; all institutional and issuance data is frozen."""

from app.modules.correspondence.pdf.operational_document_pdf import (
    generate_operational_document_pdf,
)


def route_sheet_story(snapshot, p, heading):
    origin = snapshot["origin"]
    origin_label = " · ".join(
        filter(
            None,
            [
                origin.get("employee_name"),
                origin.get("position_name"),
                origin.get("unit_name"),
            ],
        )
    )
    authority = snapshot.get("authority") or {}
    return [
        p("HOJA DE RUTA", heading),
        p("N.º " + snapshot["route_number"]),
        p("PARA: " + (authority.get("para_label") or "")),
        p("DE: " + origin_label),
        p("REFERENCIA: " + (snapshot.get("reference") or "")),
        p("FECHA DE EMISIÓN: " + snapshot["emission_date"]),
        p("HORA: " + snapshot["emission_time"]),
        p("NÚMERO DE HOJAS: " + str(snapshot["page_count"])),
    ]


def generate_route_sheet_pdf(snapshot):
    return generate_operational_document_pdf(snapshot, story_builder=route_sheet_story)
