# Galactic Library V5 — horizontal spatial concept art

Created 16 September 2026. **Current art direction: horizontal timeline inside a spacious, fully surrounding galactic library, with the camera orbiting the timeline.** The user selected horizontal and requested spatial camera movement; the circular rotunda, dimensions, and component forms below are proposals for review.

Eight selected concept boards cover the scene and its reusable elements. Two initial variants are retained to preserve the generation chain. Generated using the built-in image tool; exact [prompts and references](prompts.md) are included. These are painted design references, not Godot captures, orthographically verified drawings, meshes, textures, or functional UI.

## Review of all earlier concepts

| Existing concept | Carry forward | Superseded or limited |
| --- | --- | --- |
| [01 Browse](../01-timeline-browse.png) | Monumental archive scale; clear active event | Vertical column, gold rings, ornate frames, banners and reflective surfaces |
| [02 Image reader](../02-image-reader.png) | Stable readable overlay; image description and navigation | Gold treatment and vertical background |
| [03 Video reader](../03-video-reader.png) | Explicit playback, transcript, distinct controls | Gold treatment and vertical background |
| [04 Minimal V2](../04-timeline-browse-minimal-v2.png) | Matte graphite, simple silhouettes, restrained focus | Always-expanded media exhibits and vertical rail |
| [05 Line V3 collapsed](../05-timeline-line-collapsed-v3.png) | Fine line, small nodes, compact event strips | Vertical chronology and incidental breaks in the line |
| [06 Line V3 expanded](../06-timeline-line-expanded-v3.png) | One connected reader; neighbors stay compact | Left-side vertical timeline arrangement |
| [07 Horizontal V4 collapsed](../07-timeline-horizontal-collapsed-v4.png) | Primary browse baseline: earlier left, later right, alternating strips | Frontal composition alone does not establish a surrounding room |
| [08 Horizontal V4 expanded](../08-timeline-horizontal-expanded-v4.png) | Timeline above one reader; chronological context remains visible | Needs adaptation to camera orbit and stable reading |
| [Rotating spine alternative](../other-ideas/rotating-spine-billboards-v1.png) | Camera-facing panel principle, depth and rear attachment cues | Rotating vertical assembly: V5 instead moves the camera around a fixed horizontal object |

All concept prompt files and the design, asset brief, data contract, and reference guide were reviewed. The older main design and asset brief describe the original vertical proposal; their orientation, camera limits, ornate era geometry, and large exhibit dimensions do not govern V5. Their separation of external content from presentation, readable overlays, and reusable assets remains useful.

## 01 — Environment key art

![Spacious library with fixed horizontal timeline](01-library-key-art-refined.png)

A broad circular rotunda surrounds the timeline. Repeated record stacks make the place recognizable as a library. Galleries, piers, window bays, roof beams, and an oculus provide depth above and around the camera. The timeline has open space in front, behind, and beyond both ends. Quiet warm shelf light supports a cooler, brighter timeline.

The final refinement removes wall slogans and floor reflections. [Initial key art](01-library-key-art.png) remains because it was the reference for the component sheets. The tiny date-only panels in the wide view are composition placeholders; sheet 04 defines the actual strip contents.

## 02 — Space and camera orbit

![Orbit viewpoints and cutaway](02-spatial-orbit-study.png)

The room and timeline remain fixed. Camera azimuth changes around the vertical up axis through the timeline's focal region, with modest height variation and zero roll. This is not a roll around the horizontal rail. The planet occupies one world direction; it must disappear behind the architecture as the camera turns.

For a first scale study, consider a 14 m visible timeline neighborhood inside a 40 m diameter clear central volume, within a roughly 64 m diameter chamber. These are exploratory proportions, not measurements from the generated art or approved model dimensions. Long timelines would present successive neighborhoods, not require an infinitely long building. The camera path is an annotation, never a physical track.

A broadside default browse view preserves V4's earlier-left/later-right readability. The architecture should support a full surrounding orbit, but a 360-degree orbit necessarily reverses projected chronology from behind and collapses separation near end-on angles. Do not mirror or reorder the underlying records to disguise this. Proposed behavior: keep camera-facing panel content upright, show directional cues that follow the actual projection, and provide Reset View plus chronological index navigation. End-on overlap and useful orbit limits need later graybox evaluation.

Opening a reader should settle and hold the camera, with a stable screen-space horizontal context strip and reader underneath. Closing restores the prior orbit and focus. This resolves the visual intent only; interaction is not implemented. Broadside reading and optional orbital exploration are distinct compositions.

## 03 — Timeline assembly

![Horizontal timeline modular assembly](03-timeline-assembly.png)

Concepts cover the rail housing, recessed light insert, join, start/end caps, event socket, slender connector, small rear panel pivot, era tab, and focus corners. Detail views deliberately enlarge tiny components. The in-scene rail should remain close to V4's fine luminous line; do not scale it into a heavy beam from this sheet. Era tabs carry live labels and replace the original ceremonial rings.

The rear joint suggests independent camera-facing panel orientation. Its mechanism and the illustrated rail cross-sections are exploratory and must be reconciled into one consistent form before modeling.

## 04 — Event panel family

![Panel front rear side and states](04-event-panel-family.png)

One shallow graphite casing supports image, video, and text records. Front, rear, side, top and perspective views expose the silhouette and rear attachment. Idle, hover, keyboard focus and selected states use distinct edge/corner treatments. Collapsed strips contain date, title, type and expansion affordance; thumbnails and long text belong in the reader.

The casing and blank insert can become model components; titles, dates, icons and focus treatments remain replaceable presentation elements. Illustrative text is not a texture specification. The small reader thumbnail is a style hint; sheet 08 governs the fuller reader concept.

## 05 — Architecture kit

![Modular architecture pieces](05-architecture-kit.png)

Two pier silhouettes, window frame, gallery slab/parapet and underside, floor slab and curved edge, oculus curb, radial beam, wall infill, passage frame, base uplight recess and shelf light channel cover the architectural forms visible in the room. Repeating gallery and shelf modules establish scale without filling the center.

Finish back faces, undersides, end caps and joins that an orbiting camera can reveal. Keep floor and structural surfaces matte. Windows are openings onto a shared distant environment, not individual pictures containing duplicated planets.

## 06 — Archive storage and furnishings

![Record stacks cassettes and peripheral furniture](06-library-furnishings.png)

The library uses a repeatable record stack, closed back, stack end, corner module, and three cassette sizes. Small neutral index accents and shelf spacing provide detail without ornate lettering.

The catalog lectern, reading bench and archive plinth are **optional peripheral dressing**. They do not imply new interactive features. Do not place them below the timeline or inside the camera's clear volume. No statue, character, robot, ship, city model or event-specific diorama is required. Distant spires that appear in atmosphere imagery are background motifs only.

## 07 — Materials, lighting and atmosphere

![Material and light concept studies](07-material-light-atmosphere-refined.png)

Matte graphite, basalt-like ceramic and dark panel surfaces form the opaque kit. The rail core is a recessed pale cyan-white light; selected-event cyan is more saturated. Warm shelf lights should be quieter than the focal timeline. Original stars, a distant planet limb, light depth haze and optional sparse dust complete the environment.

The [initial material board](07-material-light-atmosphere.png) incorrectly depicted PALE CORE as stone; the refined board corrects it. The panel-face swatch is a surface-finish study, not permission to make reading panels pale gray. Follow the dark backing in sheets 04 and 08. Floor reflections in small lighting vignettes are not desired; the refined key art governs the matte finish. These swatches are not production material maps.

## 08 — Reader presentation and symbols

![Image video and text readers](08-reader-presentation.png)

Image, paused-video and text-only reader studies preserve horizontal event context. Media, body text, descriptions, transcripts and sources sit on a stable opaque overlay. This is 2D presentation concept art; it does not add large physical display objects to the library. At wide sizes retain V4's media/text columns; these narrow comparative panels illustrate a stacked arrangement.

The icon row explores image/video/text, expand/collapse, navigation, zoom/reset, index/help/settings and close. Final interface artwork must be authored separately. Generated prose, source names, dates, decorative captions and repeated Collapse buttons are illustrative, not approved content or a final interaction specification. The existing V1 JSON contract permits only image_text and video_text; text-only support needs a future explicit contract revision.

## Scene-element coverage for later modeling

| Family | Elements covered | Art reference | Future deliverable category |
| --- | --- | --- | --- |
| Timeline | Rail module, housing, light insert, join, start/end caps | 03 | Reusable meshes + material |
| Connections | Socket, connector, rear pivot | 03–04 | Reusable meshes |
| Records | Shared strip casing, backing and media insert | 04 | Mesh casing + replaceable presentation |
| Era and focus | Small era tab, label mount, node emphasis, corner brackets | 03–04 | Small mesh and/or overlay |
| Structure | Pier A/B, wall/window/portal bays | 05 | Modular meshes |
| Galleries | Curved slab, parapet, end and underside surfaces | 05 | Modular meshes |
| Floor and roof | Floor slabs, curved perimeter edges, oculus and radial beam | 05 | Modular meshes |
| Light fixtures | Uplight recess, shelf channel | 05–07 | Small meshes + emission |
| Library storage | Stack bay, back, end, corner, three record cassette sizes | 06 | Instanced meshes |
| Optional furnishings | Lectern, bench, archive plinth | 06 | Optional meshes |
| Surface language | Graphite, ceramic, panel face, pale core, cyan, warm light | 07 | Later authored materials |
| Distant environment | Sparse stars, planet limb, haze, dust | 01–02, 07 | Sky/background/effects; not necessarily meshes |
| Readers and controls | Image/video/text overlay and symbol family | 08 | 2D artwork/UI; no model required |

All scene-element families in this selected direction have concept coverage. Original gold era monuments and oversized physical media frames are deliberately retired. Actual event images/videos, font files, production textures and models are outside this concept-art delivery.

## Visual QA and handoff limits

The eight selected boards were visually inspected. The final key art and corrected light swatch received targeted revisions. Silhouettes, missing rear surfaces and relative visual hierarchy are exposed for review, but the drawings are not guaranteed to agree at every joint or projection.

Use written V5 notes to resolve incidental generation artifacts: ignore slogans and tiny scale figures in secondary sheets; the cutaway's oculus leader is misplaced and the actual oculus is overhead; dashed arcs and camera positions are schematic, not a surveyed path. Several nominal orthographic views retain perspective, and panel proportions vary slightly between views. Future modeling needs one resolved dimensional drawing per part.

Later validation must establish camera clearance, overlap handling, readable text at oblique angles, consistent material response and actual module fit. No code, Godot scene, shader, 3D model, texture map or runtime test is part of this delivery.
