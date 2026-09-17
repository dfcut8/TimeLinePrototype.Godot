# Galactic Archive — Visual Concepts

## Current direction: horizontal spatial library V5

The horizontal layout is the selected direction. The new [spatial library concept pack](spatial-library-v5/README.md) reviews all nine earlier images and adds eight concept boards covering the surrounding library, camera orbit, timeline assembly, panels, architecture, storage, materials and readers. The camera moves around a fixed horizontal timeline. Earlier concepts below are preserved as design history.

![Spatial galactic library](spatial-library-v5/01-library-key-art-refined.png)

Screenshot-like design mockups generated on 16 September 2026 using the built-in image-generation tool, based on the [timeline design](../timeline-design.md) and [asset brief](../timeline-asset-brief.md). The three original views are followed by a revised browse direction. These are static concept images, not screenshots of a running Godot scene or production media assets. No GIF or runtime implementation is included.

## Horizontal V4 — layout foundation

![Horizontal timeline with collapsed event strips](07-timeline-horizontal-collapsed-v4.png)

The V3 archive style becomes a left-to-right timeline. Compact event strips alternate above and below the thin luminous line, with earlier records on the left and later records on the right.

![Horizontal timeline with one expanded video reader](08-timeline-horizontal-expanded-v4.png)

Opening a record shifts the timeline upward and gathers the compact strips above it, leaving room for a connected reader below. All five records retain their chronological order. These static concepts were generated with the built-in image-generation tool; they are not a running implementation. The [exact prompts and proposed interactions](prompt-horizontal-v4.md) are saved for iteration.

## Previous revision: vertical line with expandable strips

![Vertical line with compact collapsed event strips](05-timeline-line-collapsed-v3.png)

The reference image's luminous line and small event points become a vertical timeline: earlier at the top, later below. All events initially show only a short clickable strip containing the date, title, content type, and an expand control. Image, video, and text-only records share this collapsed treatment.

![One video event expanded while neighboring events remain compact](06-timeline-line-expanded-v3.png)

Selecting a strip opens one large connected reader. This screenshot explores shifting the timeline left and gathering compact neighbors beside it to leave room for the selected content. Collapse restores the browsing arrangement. Image events use image + text; video events use video + text; text-only events omit the media region.

These two static concepts were created with the built-in image-generation tool. They do not implement clicking, expansion, or playback. The [exact prompts and interaction notes](prompt-line-v3.md) record the proposed behavior and remaining implementation questions. Earlier concepts and specifications remain available for comparison.

## Previous revision: minimal, matte browse

![Minimal matte 3D timeline concept](04-timeline-browse-minimal-v2.png)

Responds to feedback that the metal was too shiny and the spine too elaborate. A slender dark rail replaces the luminous column and large era rings. Thin connectors, small markers, matte graphite frames, and typographic era labels create a more modern appearance. The background architecture is simplified, while the existing events and alternating layout remain recognizable. Cyan is concentrated on the active event.

This is the previous concept exploration; the original images below are preserved for comparison. The original reader concepts still show the earlier gold treatment. This revision does not change the written asset dimensions or constitute a finished material specification. The [revision prompt](prompt-minimal-v2.md) is preserved verbatim.

## Browse

![3D archive browse concept](01-timeline-browse.png)

Shows the downward chronology, physical spine and exhibit frames, era monuments, cyan keyboard focus, overview bar, and mouse navigation toolbar. The event dates increase downward. The small media previews and extra sample records are illustrative, not Foundation canon.

## Image reader

![Selected image event concept](02-image-reader.png)

Shows a large readable panel in front of the archive, with an image, summary, description, and event navigation. The architecture preview is illustrative; its accompanying sample description is not a finalized accessible description of that generated image.

## Video reader

![Selected video event concept](03-video-reader.png)

Shows the video before playback, with a poster, Play, Restart, Mute, volume, and a readable transcript. The volume slider is not a video seek bar. No functional playback is present in the image.

## What the original V1 concepts established

- A consistent graphite, gold, and cyan visual language.
- A clear vertical timeline with physical depth and a stable upright camera.
- A distinction between the dimensional archive and the readable screen-space panel.
- A shared reading layout for both media types.

## Differences to review before implementation

The browse concept explores compact horizontal exhibits with media beside the title. The written asset brief instead starts with a wider media opening and text below it; the generated composition is a layout alternative, not an automatic change to the specification. The background architecture is also more elaborate than the proposed sparse kit, so a simpler version should be evaluated for readability and production cost. Decorative wall lettering is incidental generation detail and is not part of the required asset inventory.

The reader images emphasize media and text hierarchy; they do not demonstrate exact camera return position, the selected background frame, focus behavior, responsive layout, contrast compliance, or performance. Those remain governed by the written specification and future runtime validation. Final media, credits, and descriptions will come from external content.

The [exact prompts](prompts.md) are saved for revision. All three images are 1672 × 941 PNG files. The images are for visual review; their pixels are not reusable 3D geometry, texture maps, or UI implementation.
