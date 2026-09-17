# 3D Asset Production Brief

> Historical production brief. The current [horizontal spatial-library concept pack](concepts/spatial-library-v5/README.md) supersedes this document's vertical proportions, gold-era monuments and fixed-front assumptions. It provides concept coverage for the full scene kit, including rear surfaces for camera orbit. Budgets and production conventions below remain provisional; no models or maps have been produced.

Status: production plan only. All geometry, textures, materials, effects, and interface artwork listed here remain to be created. Event images, posters, and videos are supplied separately by the content workflow.

## 1. Visual goal

Build an original science-fiction archive with the restraint of a museum and the scale of a civilization. Large simple shapes establish depth; small bevels, seams, and light accents supply material detail. The visual anchor is a narrow luminous spine with suspended media frames. Foundation is an inspiration for historical scope and knowledge preservation, not a requirement to reproduce a particular screen adaptation's sets or objects.

Prioritize four readable silhouettes: the vertical spine, an event frame, an era marker, and a selected-event bracket. They should remain recognizable with textures removed and effects disabled. The [experience document](timeline-design.md) supplies composition and color tokens; the [reference guide](timeline-references.md) links the research material.

## 2. Model inventory

Budgets below are starting targets per highest-detail instance, not measured requirements. Reuse meshes and material sets across all events; do not model a new exhibit for each content record.

| Asset | Quantity / variants to author | Modeling brief | Initial triangle target |
| --- | --- | --- | --- |
| Spine segment | 1 tileable module | Dark structural housing, narrow recessed luminous channel, seamless vertical ends | 500–1,500 |
| Spine cap | Top and bottom | Clear start/end silhouettes with plaques supplied as live text | 300–800 each |
| Event frame | 1 shared frame, image/video indicator variants | Beveled rectangular surround; independent media insert; neutral lower title zone | 1,000–3,000 |
| Connector arm | 1 reusable adjustable assembly | Short rigid arm from frame to spine; minimal joints and an emissive groove | 100–400 |
| Event marker | 1 socket + optional selection ring | Readable small solid marker; simple collision volume independent of ornament | 200–600 |
| Era monument | 1 segmented arch/ring, 2 trim variants | Wider interruption in the spine rhythm; large title mount; open center | 2,000–5,000 |
| Background rib | 2 repeatable silhouettes | Sparse architectural depth; low-contrast surfaces; no text | 500–1,500 each |
| Archive pedestal | 1 optional focal prop | Simple original ceremonial shape for beginning or era transitions | 2,000–5,000 |
| Focus brackets | 1 reusable set | Clear corner geometry or graphic overlay, adjustable to frame dimensions | Under 200 |

Also plan simple collision proxies for frames/markers and low-detail variants where needed. Decorative objects do not receive selection collision. No characters, ships, cityscapes, terrain, or per-event dioramas are required for the initial timeline. Those would be separate art scope, not dependencies for presenting external media.

### Prototype dimensions

Adopt 1 Godot unit = 1 meter for asset authoring consistency. Initial frame outer size: 3.4 m wide × 2.55 m high × 0.16 m deep, with a 3.2 m × 1.8 m media opening and space for labels below. These units provide a consistent kit rather than a literal real-world scale for the archive.

Start with 3.8 m vertical event slots and a spine width around 0.18 m. Place alternating frame centers near X = −2.3 m and +2.3 m, leaving a clear central spine. Test framing at the proposed camera angle before committing to final geometry. Do not nonuniformly stretch finished bevels to accommodate portrait media; keep a stable frame and contain the image within its opening.

Frames pivot at their media center, spine segments at the lower seam, connectors at their spine attachment, and era markers at their central timeline crossing. All visible fronts face local +Z toward a camera looking along −Z. Apply consistent transforms on export and document attachment points.

## 3. Texture and material inventory

| Set | Maps / treatment | Initial delivery size | Uses |
| --- | --- | --- | --- |
| Archive metal trim | Base color, normal, packed occlusion/roughness/metallic, emission mask | One shared 2048 × 2048 set | Spine, frame trim, connectors |
| Dark panel surface | Base color and subtle roughness/normal detail | 1024 × 1024 tileable set | Frame backings, ribs |
| Era surface | Stone/ceramic-like base color, normal, roughness; sparing metallic accents | 2048 × 2048 set | Monuments and optional pedestal |
| Light masks | Clean grooves, brackets, and small marker accents | Shared 512 × 512 atlas | Selection and spine light |
| Space background | Original star distribution and very low-contrast haze; procedural or baked | Start at 2048 × 1024 if baked | Environment backdrop |
| UI symbols | Image, video, play/pause, restart, volume, close, index, zoom, help | Crisp scalable source plus export atlas if needed | Media types and controls |

Create the material source files as part of production. Procedural materials must have editable source graphs or documented parameters; bake portable texture maps when required. Font files are a separately chosen typography dependency, not event media. Select a readable licensed family with sufficient language coverage, record its source and license, and author consistent heading/body/date treatments.

Use the glTF convention for a packed ORM texture: red occlusion, green roughness, blue metallic. Color/emission imagery and numeric surface maps must use appropriate color-space handling during import. Keep media on a neutral unshaded surface; lighting and gold trim should not change the color of historical images or video. Text remains live text, never baked into event-frame textures.

Favor opaque surfaces. Place emissive edges on solid geometry instead of stacking transparent shells. Reserve transparency for limited effects where visual testing justifies it. Bloom is optional polish; the spine, focus state, and titles must still read when it is off.

## 4. Motion, lighting, and effects to author

| Effect | Desired behavior | Reduced / low-effects behavior |
| --- | --- | --- |
| Hover | 100–150 ms bracket or border transition | Immediate border change |
| Selection | 180–250 ms connection highlight and camera settling | Immediate selection and centering |
| Era arrival | Brief gentle light emphasis on the era plaque | Static marker |
| Ambient atmosphere | Slow sparse dust/star movement in the background | Disabled |
| Loading | Small progress indication in the selected media area | Static text or restrained progress indicator |

These timings are proposed tuning values. Avoid loops that pulse all frames, dramatic fly-throughs, scanlines over body text, or shimmer over media. A light rig should reveal bevels with few lights and controlled highlights. Use emissive materials for repeated small lights instead of a dynamic light per event. Bake or fake decorative detail where it preserves the intended look.

Optional interface audio, if later desired, consists of quiet focus/open/close cues and an ambient bed. It must not be necessary to understand state. No audio assets are required or generated in this documentation task.

## 5. Authoring and delivery workflow

1. **Graybox kit:** create primitive spine, frame, connector, and era marker at the proposed dimensions. Review at browse, reading, and far zoom before detailing.
2. **Finished art slice:** produce one complete example of each essential asset and the shared material set. Evaluate bright/dark images, portrait footage, long titles, and high text scale.
3. **Modular expansion:** make caps, trim variants, architectural ribs, selection graphics, and optional focal prop from the approved kit.
4. **Import review:** inspect scale, orientation, pivot, normal direction, UV seams, color, material slots, and surface readability in the pinned Godot build.
5. **Optimization and handoff:** add low-detail meshes where justified, review texture memory, remove hidden geometry, and record the final budgets and source provenance.

Proposed source tool: Blender for modeling and UVs, with a suitable texture-authoring tool chosen during production. Keep editable sources, export meshes as glTF 2.0 `.glb`, and retain shared textures separately where that improves reuse. Godot recommends glTF 2.0 and documents both binary and separate-file delivery. [Godot: available 3D formats](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/available_formats.html).

Use consistent names such as `archive_spine_segment`, `archive_event_frame`, and `archive_era_ring`. Keep visual assets in the Godot project's presentation asset hierarchy; keep external content packages outside that authoring hierarchy. Folder creation and actual exports belong to a later task.

Each delivered asset needs its editable source, exported mesh where applicable, required maps, material assignment notes, dimensions/pivot notes, license/provenance record, triangle/material counts, and a preview render made during production. A preview image for asset review is distinct from event media.

## 6. Art acceptance checklist

- The top-to-bottom timeline is readable in an untextured silhouette view and with effects disabled.
- Repeating spine segments connect without visible gaps; connectors meet the frame and spine cleanly.
- Media surfaces preserve aspect ratio, show correct orientation, and retain source colors.
- Long titles, the reader overlay, and focus brackets stay clear of ornamental geometry.
- No essential interaction relies on tiny, transparent, or visually obscured details.
- Shared materials and textures work across all variants; each frame does not duplicate large texture sets.
- The art slice performs within the later agreed runtime budgets and shows no distracting shimmer or transparency overlap.
- Every required asset has editable source and documented delivery details. Event-media credits remain attached to their content records.

Do not proceed from a graybox to a full asset library until the frame size, camera composition, and readability have been evaluated together. This is a future production gate, not a request to create assets during the present documentation task.
