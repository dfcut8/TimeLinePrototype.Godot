# Horizontal timeline V4 — prompts and interaction notes

Created 16 September 2026 with the built-in image-generation tool. These are static screenshot-like concepts, not captures of a running Godot scene.

## Files and references

- `07-timeline-horizontal-collapsed-v4.png`: horizontal browse, all five events collapsed.
- `08-timeline-horizontal-expanded-v4.png`: selected video reader below the horizontal timeline.
- Browse style reference: `05-timeline-line-collapsed-v3.png`.
- Expanded references: the new horizontal browse and `06-timeline-line-expanded-v3.png`.

## Proposed interaction

Chronology runs left to right, with editorial spacing rather than a proportional date scale. Browse strips alternate above and below a continuous luminous line. Each strip contains the date, title, media type, and an expand control. The cyan outline on the collapsed transmission event represents keyboard focus.

Selecting an event opens one reader. The horizontal line shifts upward and the compact strips gather above it, preserving their left-to-right order. The selected node connects downward to the reader; other events remain collapsed. Collapse or Escape should restore the browse arrangement, position, and focus. Left/Right should focus previous/next events while the archive owns keyboard focus; Enter or Space opens the focused event. Dragging the empty canvas horizontally would browse earlier/later records.

The video view shows a stopped poster with explicit Play, playback controls, explanatory text, and transcript. Image records would use image + text without playback controls. Text-only records would omit the media region. Switching or collapsing an event should stop video playback. These are proposed behaviors for a future implementation.

## Visual review and limits

Both PNGs are 1672 × 941. The concepts preserve the dark spatial archive, matte strips, fine luminous nodes, and restrained cyan emphasis of V3. All five records remain in chronological order and visible in both states. The expanded reader is connected to the selected node without covering its neighbors.

The concepts do not demonstrate functional interaction, animation, playback, responsive layout, contrast compliance, or focus restoration. Era captions appear in browse and are omitted in the expanded view to reserve reading space. Sample content is illustrative. This horizontal alternative does not revise the existing vertical runtime design or data contract.

## Collapsed browse — submitted prompt

```text
Use case: ui-mockup.
Asset type: static screenshot concept for the GALACTIC ARCHIVE desktop application, horizontal timeline V4.
Input image 1 is a style reference: preserve its restrained dark blue-black spatial archive, faint architectural columns and distant planet, matte graphite strips, white typography, muted warm date labels, and fine cyan focus outline. Recompose into a HORIZONTAL timeline. This is a new sibling concept, not a rotated screenshot.
Create one polished wide 16:9 desktop screenshot, approximately 1672x941. Upright legible UI and generous negative space.
Header at top: small "CONCEPT / HORIZONTAL V4", large spaced "GALACTIC ARCHIVE"; top-right "Index   Help   Settings".
A SINGLE continuous thin pale cyan-white HORIZONTAL timeline runs from left margin to right margin at 50% canvas height. Five small glowing circular nodes progress in chronological order strictly LEFT TO RIGHT. Restrained halo. No vertical main spine. Small "Earlier" with left arrow at left end and "Later" with right arrow at right end.
All events are collapsed: five short matte graphite clickable strips, each about 280px wide and 78px tall. Alternate above/below the line using short thin vertical connectors: event 1 above, event 2 below, event 3 above, event 4 below, event 5 above. Place node centers at approximately 13%, 31.5%, 50%, 68.5%, 87% width. Cards stay within viewport and never collide. Each card has a small date, concise readable title, compact media-type label, and a plus at far right. No thumbnail, no body copy, no expanded cards.
Exact event records in left-to-right order:
"YEAR 0" / "The Archive Charter" / "IMAGE" / "+"
"c. YEAR 12" / "The First Transmission" / "VIDEO" / "+"
"YEAR 48" / "The Outward Exchange" / "IMAGE" / "+"
"YEAR 73" / "The Council Record" / "TEXT" / "+"
"YEAR 106" / "The New Observatory" / "IMAGE" / "+".
The second event The First Transmission has a fine cyan focus outline and brighter node but remains collapsed.
Small unobtrusive era captions above the timeline grouping: "THE PRESERVATION ERA" over the earlier four records, "THE EXPANSION ERA" near final record. Do not interrupt the line for text. No evenly spaced date ticks that imply proportional time.
Atmosphere matches reference: subtle depth and thin physical strip edges in quiet monumental archive, background subdued enough for text clarity, no glossy ornament. Timeline is the visual anchor. Content stays front-facing and horizontal; no tilted typography.
Bottom persistent toolbar: "First", "Previous", "Next", "Last" at left; "−", "Reset view", "+" at right. Center helper: "Select an event to expand · Spacing is not to scale".
One complete app screenshot only, no device, no comparison, no outside annotations, no explanatory arrows, no watermark. This is a visual mockup, not runtime implementation.
```
## Expanded video — submitted prompt

```text
Use case: ui-mockup.
Asset type: horizontal timeline V4 expanded-video state, second matching app screenshot.
Input 1 is the horizontal browse screenshot: preserve its exact visual identity, background archive architecture, typography, matte graphite, header and footer. Input 2 is the earlier vertical expanded reader: use only as a reference for video content and reader styling. The final timeline MUST BE HORIZONTAL, chronological left to right.
Create a single wide 16:9 desktop screenshot approximately 1672x941 of GALACTIC ARCHIVE after selecting "The First Transmission". Only one expanded reader. All UI text remains upright, no rotated interface.
Recompose to leave room: move the thin continuous horizontal timeline to about 29% screenshot height. Keep the same five chronological nodes spread across the width at 13%,31.5%,50%,68.5%,87%. Put five compact matte event strips ABOVE the line in a single row, all readable, approximately 290px wide and 70px high. Thin vertical connectors run DOWN from each strip to its node. Chronological order left to right:
"YEAR 0" / "The Archive Charter" / "IMAGE" / "+"
"c. YEAR 12" / "The First Transmission" / "VIDEO" / "−"
"YEAR 48" / "The Outward Exchange" / "IMAGE" / "+"
"YEAR 73" / "The Council Record" / "TEXT" / "+"
"YEAR 106" / "The New Observatory" / "IMAGE" / "+".
The second strip and node glow cyan as selected; its minus indicates the open state. Neighbor strips stay collapsed, no thumbnails or body. Small "Earlier" with left arrow at left end of timeline; "Later" with right arrow at right. A short cyan connector descends from selected second node directly to top edge of expanded reader below, clearly attached to that node.
Expanded reader below line at roughly x=14% to 86%, y=34% to 88%, with opaque matte blue-black background, restrained thin cyan border, generous padding. No overlap with timeline or neighbor strips. Header small "c. YEAR 12 · VIDEO", large title "The First Transmission", top-right "− Collapse".
Reader left half: large landscape poster of the archive radio transmission dish under a dark starry sky, centered Play triangle. Video is stopped. Under poster compact controls "Play", "Restart", "Mute", "Volume" with a short slider.
Reader right half: heading "Knowledge crosses the frontier"; body "The archive sends its first message beyond the home system. A shared record becomes a promise to distant settlements." Divider, heading "Transcript"; body "We send these records so that knowledge may endure, wherever our descendants make their home."
Reader bottom: "Previous event" and "Next event". All text readable and contained within panel with no clipped lines.
Persistent top header exact "CONCEPT / HORIZONTAL V4", "GALACTIC ARCHIVE", and "Index   Help   Settings". Bottom toolbar "First", "Previous", "Next", "Last" at left; "−", "Reset view", "+" at right. Footer helper "Collapse to continue browsing · Spacing is not to scale".
Match the quiet dark spatial archive, distant planet, thin panel edges and restrained cyan accents of input 1. No gold ornament, no bulky metal spine, no vertical main timeline, no explanatory outside annotations. Single complete app screenshot, no comparison, no device frame. Static visual concept.
```
