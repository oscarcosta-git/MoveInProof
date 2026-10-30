"""Generates the Section 3 architecture diagram as Docs/architecture-diagram.svg and .html.

Run from the repo root, then export PNG and PDF with Chrome:
  python3 Tools/MakeArchitectureDiagram.py Docs
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless --hide-scrollbars --window-size=1754,1240 \
    --screenshot=Docs/ArchitectureDiagram.png Docs/architecture-diagram.html
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless --no-pdf-header-footer \
    --print-to-pdf=Docs/ArchitectureDiagram.pdf Docs/architecture-diagram.html
"""
import sys

W, H = 1754, 1240
INK = "#222"
GREY = "#777"
LINE = "#444"
ACC = "#1F6F64"   # single accent: the traced path
LANE_FILL = "#F3F3F3"

out = []
def add(s): out.append(s)

def text(x, y, s, size=14, weight="normal", fill=INK, anchor="start", style=""):
    add(f'<text x="{x}" y="{y}" font-size="{size}" font-weight="{weight}" fill="{fill}" text-anchor="{anchor}" {style}>{s}</text>')

def box(x, y, w, h, title, sub=None, accent=False, dashed=False):
    stroke = ACC if accent else LINE
    sw = 2 if accent else 1.2
    dash = ' stroke-dasharray="5 4"' if dashed else ""
    add(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="3" fill="#fff" stroke="{stroke}" stroke-width="{sw}"{dash}/>')
    if sub:
        text(x + w / 2, y + h / 2 - 3, title, 13.5, "bold" if accent else "normal", ACC if accent else INK, "middle")
        text(x + w / 2, y + h / 2 + 14, sub, 11.5, fill=GREY, anchor="middle")
    else:
        text(x + w / 2, y + h / 2 + 5, title, 13.5, "bold" if accent else "normal", ACC if accent else INK, "middle")

def arrow(points, color=LINE, width=1.2, dashed=False, marker="arr"):
    d = "M " + " L ".join(f"{x},{y}" for x, y in points)
    dash = ' stroke-dasharray="6 4"' if dashed else ""
    add(f'<path d="{d}" fill="none" stroke="{color}" stroke-width="{width}"{dash} marker-end="url(#{marker})"/>')

def label(x, y, s, color=ACC, anchor="start"):
    add(f'<text x="{x}" y="{y}" font-size="12.5" fill="{color}" text-anchor="{anchor}" font-style="italic">{s}</text>')

add(f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}" '
    'font-family="Helvetica Neue, Helvetica, Arial, sans-serif">')
add('<defs>'
    f'<marker id="arr" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="8" markerHeight="8" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="{LINE}"/></marker>'
    f'<marker id="acc" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="8" markerHeight="8" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="{ACC}"/></marker>'
    '</defs>')
add(f'<rect width="{W}" height="{H}" fill="#fff"/>')

# Title
text(40, 52, "MoveIn Proof: architecture and data flow", 24, "bold")
text(40, 76, "MVVM + use cases + repositories. SwiftUI, SwiftData, AVFoundation, WidgetKit. All storage is on the device.", 14, fill=GREY)

# Swimlanes
X0, X1 = 40, 1290
LABEL_W = 150
lanes = [
    ("View", "SwiftUI screens", 100, 285),
    ("ViewModel", "@Observable, @MainActor", 285, 470),
    ("Use cases", "business rules,", 470, 655),
    ("Repositories", "protocols (top line)", 655, 850),
    ("Storage and", "platform services", 850, 1050),
]
extra = {"Use cases": "throw MoveInError", "Repositories": "implementations (below)"}
for name, sub, y0, y1 in lanes:
    add(f'<rect x="{X0}" y="{y0}" width="{X1 - X0}" height="{y1 - y0}" fill="#fff" stroke="#BBB" stroke-width="1"/>')
    add(f'<rect x="{X0}" y="{y0}" width="{LABEL_W}" height="{y1 - y0}" fill="{LANE_FILL}" stroke="#BBB" stroke-width="1"/>')
    text(X0 + 14, y0 + 30, name, 15, "bold")
    text(X0 + 14, y0 + 50, sub, 12, fill=GREY)
    if name in extra:
        text(X0 + 14, y0 + 66, extra[name], 12, fill=GREY)

# Grid of columns inside the lanes
COLS = [210 + i * 176 for i in range(6)]
BW = 160
BH = 44
def col(i): return COLS[i]
def cx(i): return COLS[i] + BW / 2

# Lane 1: views
r1, r2 = 135, 205
for i, n in enumerate(["SetupView", "HomeView", "ReportView", "CaptureView", "RoomDetailView", "IssueDetailView"]):
    box(col(i), r1, BW, BH, n, accent=(n == "CaptureView"))
box(col(0), r2, BW, BH, "TenancySettingsView")
box(col(1), r2, BW, BH, "CompareView")
box(col(2), r2, BW, BH, "ExportView")
box(col(4), r2, BW * 2 + 16, BH, "Shared UI: Theme, components,", "Dynamic Type helper, error alert")

# Lane 2: view models
r1, r2 = 320, 390
for i, n in enumerate(["SetupViewModel", "HomeViewModel", "CameraController", "CaptureViewModel", "RoomDetailViewModel", "IssueDetailViewModel"]):
    box(col(i), r1, BW, BH, n, accent=(n == "CaptureViewModel"))
box(col(0), r2, BW, BH, "RootViewModel")
box(col(1), r2, BW, BH, "TenancySettings VM")
box(col(2), r2, BW, BH, "ExportViewModel")
box(col(4), r2, BW * 2 + 16, BH, "AppDependencies", "builds repositories, creates ViewModels", dashed=True)
# CaptureViewModel uses CameraController
arrow([(col(3), r1 + BH / 2), (col(2) + BW + 1, r1 + BH / 2)], LINE)

# Lane 3: use cases
r1, r2 = 505, 575
for i, n in enumerate(["CreateTenancy", "UpdateTenancy", "ManageRooms", "CapturePhoto", "FlagIssue", "UpdateIssue"]):
    box(col(i), r1, BW, BH, n, accent=(n == "CapturePhoto"))
for i, n in [(0, "LoadTenancy"), (1, "DeleteAllData"), (2, "CompleteRoom"), (4, "DeletePhoto"), (5, "ExportReport")]:
    box(col(i), r2, BW, BH, n)

# Lane 4: repository protocols with their implementation underneath
r1 = 700
RH = 56
box(col(1), r1, BW, RH, "TenancyRepository", "SwiftData implementation")
box(col(3), r1, BW, RH, "InspectionRepository", "SwiftData implementation", accent=True)
box(col(4), r1, BW, RH, "PhotoFileStorage", "LocalPhotoFileStorage", accent=True)
box(col(5), r1, BW, RH, "ReportRenderer", "PDFReportRenderer")
box(col(0), r1, BW, RH, "Mock repositories", "MoveInProofTests", dashed=True)
text(col(0) + BW / 2, r1 + RH + 22, "20 unit tests replace the", 11.5, fill=GREY, anchor="middle")
text(col(0) + BW / 2, r1 + RH + 37, "real implementations", 11.5, fill=GREY, anchor="middle")

# Lane 5: storage and platform
r1, r2 = 885, 970
box(col(1), r1, BW * 3 + 32, BH, "SwiftData store (ModelContainer)", "Tenancy, Room, Photo, Issue", accent=True)
box(col(4), r1, BW, BH, "Photos folder", "JPEG, file protection", accent=True)
box(col(5), r1, BW, BH, "ConditionReportPDF", "UIKit, share sheet / Files")
box(col(0), r1, BW, BH, "AVFoundation", "back camera")
box(col(2), r2, BW, BH, "WidgetSync")
box(col(3), r2, BW, BH, "App Group", "UserDefaults snapshot")
box(col(4), r2, BW, BH, "Widget extension", "WidgetKit")

# Plain dependency arrows (grey) between other layers, kept to a few representative ones
g1 = col(1) - 8  # gutter left of column 1
arrow([(cx(1), 135 + BH), (cx(1), 192), (g1, 192), (g1, 300), (cx(1), 300), (cx(1), 320)])  # HomeView -> HomeViewModel
arrow([(cx(1), 320 + BH), (cx(1), 377), (g1, 377), (g1, 488), (cx(1), 488), (cx(1), 505)])  # HomeVM -> UpdateTenancy
arrow([(cx(1), 505 + BH + 70), (cx(1), 700)])       # DeleteAllData row -> TenancyRepository
arrow([(cx(1), 700 + RH), (cx(1), 885)])            # TenancyRepository -> store
arrow([(cx(5), 575 + BH), (cx(5), 700)])            # ExportReport -> ReportRenderer
arrow([(cx(5), 700 + RH), (cx(5), 885)])            # ReportRenderer -> PDF
arrow([(cx(0), 885), (cx(0), 830), (col(2) - 8, 830), (col(2) - 8, 342), (col(2), 342)], "#999", dashed=False)  # AVFoundation -> CameraController

# Traced path (accent): taking a photo
arrow([(cx(3), 135 + BH), (cx(3), 320)], ACC, 2, marker="acc")
label(cx(3) + 8, 270, "1  tap shutter")
arrow([(cx(3), 320 + BH), (cx(3), 505)], ACC, 2, marker="acc")
label(cx(3) + 8, 455, "2  takePhoto()")
arrow([(cx(3), 505 + BH), (cx(3), 700)], ACC, 2, marker="acc")
label(cx(3) + 8, 640, "3  add records")
arrow([(col(3) + BW, 527), (col(3) + BW + 8, 527), (col(3) + BW + 8, 662), (cx(4), 662), (cx(4), 700)], ACC, 2, marker="acc")
label(cx(4) + 8, 690, "3  save JPEG")
arrow([(cx(3), 700 + RH), (cx(3), 885)], ACC, 2, marker="acc")
label(cx(3) + 8, 830, "4  saveChanges()")
arrow([(cx(4), 700 + RH), (cx(4), 885)], ACC, 2, marker="acc")
# Return path: store changes observed by the UI (dashed, in the gap between columns 2 and 3)
gx = col(3) - 8
arrow([(col(3) + 20, 885), (col(3) + 20, 865), (gx, 865), (gx, 200), (col(3) + 14, 200), (col(3) + 14, 135 + BH + 1)], ACC, 1.6, dashed=True, marker="acc")
label(gx - 8, 290, "5  changes observed", anchor="end")
# Widget refresh
arrow([(cx(2), 885 + BH), (cx(2), 970)], LINE, dashed=True)
label(cx(2) + 6, 962, "on save", GREY)
arrow([(col(2) + BW, 970 + BH / 2), (col(3), 970 + BH / 2)])
arrow([(col(3) + BW, 970 + BH / 2), (col(4), 970 + BH / 2)])

# Right column
RX = 1320
text(RX, 125, "Taking a photo", 17, "bold")
steps = [
    ("1", "CaptureView sends the tap to CaptureViewModel."),
    ("2", "The ViewModel captures the image with CameraController,"),
    ("", "stamps the date and time on it and calls CapturePhoto."),
    ("3", "CapturePhoto saves the JPEG through PhotoFileStorage and"),
    ("", "adds the Photo (and an Issue if tagged) through"),
    ("", "InspectionRepository."),
    ("4", "saveChanges() commits to SwiftData. If that fails the"),
    ("", "JPEG is deleted and MoveInError.storageFailed is thrown."),
    ("5", "SwiftData observation updates the screen. Errors are"),
    ("", "shown as an alert by the ViewModel."),
    ("", "WidgetSync also writes a snapshot for the widget."),
]
y = 152
for n, s in steps:
    if n:
        text(RX, y, n + ".", 13.5, "bold", ACC)
    text(RX + 20, y, s, 13.5)
    y += 21

y += 22
text(RX, y, "Data model", 17, "bold")
y += 18
def ent(x, y, n):
    add(f'<rect x="{x}" y="{y}" width="92" height="34" rx="2" fill="#fff" stroke="{LINE}" stroke-width="1.2"/>')
    text(x + 46, y + 22, n, 13.5, anchor="middle")
ent(RX, y, "Tenancy"); ent(RX + 140, y, "Room"); ent(RX + 280, y, "Photo")
ent(RX + 140, y + 74, "Issue")
add(f'<line x1="{RX + 92}" y1="{y + 17}" x2="{RX + 140}" y2="{y + 17}" stroke="{LINE}" stroke-width="1.2"/>')
add(f'<line x1="{RX + 232}" y1="{y + 17}" x2="{RX + 280}" y2="{y + 17}" stroke="{LINE}" stroke-width="1.2"/>')
add(f'<line x1="{RX + 186}" y1="{y + 34}" x2="{RX + 186}" y2="{y + 74}" stroke="{LINE}" stroke-width="1.2"/>')
add(f'<polyline points="{RX + 232},{y + 91} {RX + 326},{y + 91} {RX + 326},{y + 34}" fill="none" stroke="{LINE}" stroke-width="1.2"/>')
for (tx, ty, t) in [(RX + 96, y + 12, "1"), (RX + 128, y + 12, "*"), (RX + 236, y + 12, "1"), (RX + 268, y + 12, "*"),
                    (RX + 190, y + 47, "1"), (RX + 190, y + 70, "*"), (RX + 236, y + 86, "1"), (RX + 330, y + 46, "*")]:
    text(tx, ty, t, 12, fill=GREY)
text(RX, y + 132, "Deleting a room cascades to its photos and issues.", 12.5, fill=GREY)
text(RX, y + 149, "Deleting an issue keeps its photos.", 12.5, fill=GREY)

y += 190
text(RX, y, "Notes", 17, "bold")
notes = [
    "Each layer only calls the one below it.",
    "Views never import SwiftData; use cases only",
    "see repository protocols.",
    "UI state runs on the main actor; the camera",
    "session has its own serial queue.",
    "No network access. The widget reads a copy of",
    "the key dates from the App Group.",
]
y += 24
for s in notes:
    text(RX, y, s, 13.5); y += 20

y += 20
text(RX, y, "Key", 17, "bold")
y += 22
add(f'<line x1="{RX}" y1="{y - 4}" x2="{RX + 40}" y2="{y - 4}" stroke="{LINE}" stroke-width="1.2" marker-end="url(#arr)"/>')
text(RX + 52, y, "calls / depends on", 13.5)
y += 22
add(f'<line x1="{RX}" y1="{y - 4}" x2="{RX + 40}" y2="{y - 4}" stroke="{ACC}" stroke-width="2" marker-end="url(#acc)"/>')
text(RX + 52, y, "path traced above", 13.5)
y += 22
add(f'<line x1="{RX}" y1="{y - 4}" x2="{RX + 40}" y2="{y - 4}" stroke="{LINE}" stroke-width="1.2" stroke-dasharray="6 4" marker-end="url(#arr)"/>')
text(RX + 52, y, "notification / observation", 13.5)
y += 22
add(f'<rect x="{RX}" y="{y - 14}" width="40" height="18" fill="#fff" stroke="{LINE}" stroke-dasharray="5 4"/>')
text(RX + 52, y, "wiring or test-only component", 13.5)

add('</svg>')
svg = "\n".join(out)
open(sys.argv[1] + "/architecture-diagram.svg", "w").write(svg)
html = f"""<!doctype html>
<html><head><meta charset="utf-8"><title>MoveIn Proof Architecture</title>
<style>@page {{ size: {W}px {H}px; margin: 0; }} html, body {{ margin: 0; width: {W}px; height: {H}px; overflow: hidden; }} svg {{ display: block; }}</style>
</head><body>
{svg}
</body></html>"""
open(sys.argv[1] + "/architecture-diagram.html", "w").write(html)
print("ok")
