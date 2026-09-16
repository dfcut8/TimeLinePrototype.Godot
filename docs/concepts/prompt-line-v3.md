# Line timeline V3 — prompts and interaction notes

Created 16 September 2026 with the built-in image-generation tool. Static visual concepts, not captures of a running Godot scene.

## Files and references

- `05-timeline-line-collapsed-v3.png`: initial browse state.
- `06-timeline-line-expanded-v3.png`: selected video event expanded.
- Existing `04-timeline-browse-minimal-v2.png`: app identity and matte spatial archive reference.
- User-supplied horizontal timeline photograph: reference for the luminous line and point treatment only. Its orientation and text are not requirements.

## Proposed interaction

All events begin collapsed. Each short strip exposes a date, title, content type, and expansion affordance. The whole strip and its timeline point are clickable; keyboard focus alone does not open it. Enter or Space opens the focused event.

Only one event is expanded at a time. Opening another collapses the current event. Earlier events remain above later events. In the expanded concept the timeline shifts left and compact neighbors collect to its left, creating room for a large connected reader. Collapse or Escape restores the previous browsing composition, scroll position, and keyboard focus. This temporary rearrangement is a proposed layout choice, not a requirement from the reference photograph.

- Image + text: large image, title, summary, body, and source/credit; no playback controls.
- Video + text: poster before explicit Play, playback controls, explanatory text, and transcript. Collapsing or switching events stops playback.
- Text only: title and readable body with a comfortable line length; omit the media region and playback controls entirely.

The video screenshot illustrates the expanded layout. Image and text-only behavior is specified here, not shown in separate V3 screenshots. Example records are illustrative, not canonical history.

## Review limits

The images establish appearance and the two interaction states; they are not clickable implementations. Animation, responsive layout, picking, text scaling, media behavior, and focus restoration still need runtime validation. Generated corner lettering and era-line interruptions are incidental image artifacts; implementation should use exact UI strings and a continuous vertical spine. The existing main design, content contract, and asset brief predate this revision and have not been fully reconciled with it, including text-only records.

## Collapsed browse — submitted prompt

```text
Use case: ui-mockup.
Create a refined screenshot-like concept for the existing GALACTIC ARCHIVE vertical 3D timeline.
Input 1 is the existing matte archive concept and is the edit target for overall app identity, palette and spatial atmosphere. Input 2 is a style reference ONLY for the thin luminous line and little bright event points; do not reproduce its horizontal orientation, buildings, or any lettering.
Primary change: replace the large always-open exhibits with VERY SHORT clickable collapsed event strips. This is the initial browsing state: every event is collapsed.
Composition: wide 16:9 desktop screenshot, carefully legible typography. A single hairline pale cyan-white vertical line runs down the center from near top to near bottom, with five tiny luminous circular nodes. Earlier at top, later below. Short fine horizontal connectors alternate left, right, left, right, left. The line is the principal visual organizing element, no thick solid column, rings or metal housing. Restrained soft halo like the reference but no aggressive bloom.
Each collapsed event is a shallow matte graphite strip about 350 pixels wide and 58 pixels high in a 1600px-wide view. Each strip has a date in small text, a concise event title in readable text, a tiny media-type icon and label, and a plus at the far end to signal expansion. NO large thumbnails, NO exposed body copy, NO big media panels. The full strip reads as clickable. All strips stay distinctly separated with generous negative space.
Five sample records in downward chronological order, titles and metadata verbatim:
left: "YEAR 0" / "The Archive Charter" / "IMAGE" / "+"
right: "c. YEAR 12" / "The First Transmission" / "VIDEO" / "+"
left: "YEAR 48" / "The Outward Exchange" / "IMAGE" / "+"
right: "YEAR 73" / "The Council Record" / "TEXT" / "+"
left: "YEAR 106" / "The New Observatory" / "IMAGE" / "+".
The First Transmission strip is keyboard-focused, indicated by a fine cyan outline and brighter node, but remains COLLAPSED like the other strips. Tiny era caption "THE PRESERVATION ERA" near top; "THE EXPANSION ERA" between year 73 and 106. Do not break the timeline line for the era caption.
Atmosphere: retain subtle 3D depth, slim physical strip edges and a spacious blue-black archive, but fade background columns and stars much darker so the glowing line and text dominate. Dry matte graphite surfaces, no shiny metal, no gold ornament, no elaborate buildings. Flat front-facing content with subtle spatial grounding. Professional quiet information design.
Header "GALACTIC ARCHIVE", small corner label "CONCEPT / LINE V3", top-right "Index   Help   Settings". Small "Earlier" with up arrow near upper left and "Later" with down arrow near lower left. Compact subdued bottom controls "First", "Previous", "Next", "Last", "−", "Reset view", "+"; footer "Spacing is not to scale". Subtle helper line near footer: "Select an event to expand".
One complete app screenshot, no comparisons, no explanatory arrows outside the interface, no device frame. This is a visual concept not an actual runtime capture.
```

## Expanded video — submitted prompt

```text
Use case: ui-mockup. Edit the provided GALACTIC ARCHIVE LINE V3 concept into its expanded-event state. Preserve the design identity, matte blue-black spatial archive, thin cyan-white VERTICAL timeline, tiny glowing nodes, exact header, discreet footer controls and clear earlier-at-top chronology. This is a second screenshot of the same app, not a comparison.
Primary change: user has clicked the collapsed strip "The First Transmission". That one strip has expanded into a large, comfortable VIDEO + TEXT reader, still visually attached to its original luminous node by a short connector. Other visible events remain very short collapsed strips, never show multiple expanded panels.
Reframe the browsing canvas slightly to make room: timeline vertical line at approximately 35% of the wide screenshot width. Expanded selected panel fills the right 58% of the canvas, about 920 pixels wide and 590 high on a 1672x941 screenshot. Short collapsed neighboring strips stay on the left of the line where needed, maintaining chronological heights; one earlier and two later neighbors remain visible as context. This focused layout gently shifts neighbors aside while one panel is open. Do not place a large panel over any neighboring strip.
Expanded panel: opaque matte dark graphite, thin restrained cyan border, subtly solid edge, generous padding. Header small "c. YEAR 12 · VIDEO", title "The First Transmission", explicit top right control "− Collapse". Large landscape video poster of the original archive transmission dish under a dark starry sky, with centered Play triangle. Poster occupies about 60% of the expanded content area width, on the left. On the right readable text headed "Knowledge crosses the frontier", body "The archive sends its first message beyond the home system. A shared record becomes a promise to distant settlements." Below, section label "Transcript", text "We send these records so that knowledge may endure, wherever our descendants make their home." Video is stopped and has not autoplayed. Below video, restrained buttons "Play", "Restart", "Mute", "Volume" with a small volume slider. Bottom of expanded panel: "Previous event" and "Next event". All these contents must fit with ample readable breathing room.
Visible collapsed neighbors left of the vertical line: above selected node "YEAR 0 / The Archive Charter / IMAGE / +"; below selected node "YEAR 48 / The Outward Exchange / IMAGE / +"; farther below "YEAR 73 / The Council Record / TEXT / +". Each very short narrow strip no thumbnail no body. Their text is smaller than expanded reader but legible. Keep their chronological order top to bottom. If YEAR 106 does not fit omit it below the visible viewport rather than rearranging order. Only active selected event node glows strongly.
Top-left clean exact small label "CONCEPT / LINE V3", header "GALACTIC ARCHIVE". Top-right "Index   Help   Settings". Earlier up and Later down on left. Footer controls preserve original; helper "Collapse to continue browsing · Spacing is not to scale".
No gold ornate frames, no shiny metal, no large cylinder or ring, no horizontal timeline, no fake perspective skew of readable text. Single refined complete app screenshot.
```

