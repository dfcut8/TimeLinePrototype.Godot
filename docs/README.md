# 3D Timeline — Design Documentation

Status: proposed design, ready for review. Prepared 16 September 2026.

A vertical, navigable 3D archive rendered in Godot. Time begins at the top and advances downward. Visitors select image-and-text or video-and-text events, moving through a science-fiction history with mouse or keyboard. Foundation provides thematic inspiration; the presentation assets will be original.

## Documents

| Document | Purpose |
| --- | --- |
| [Experience and visual design](timeline-design.md) | Spatial composition, wireframes, camera, controls, accessibility, Godot responsibilities, and acceptance criteria. |
| [External JSON content contract](timeline-data-contract.md) | Content ownership, chronology, fields, media references, validation rules, and an illustrative JSON example. |
| [3D asset production brief](timeline-asset-brief.md) | Models, textures, materials, effects, production conventions, and delivery gates. |
| [Reference guide](timeline-references.md) | Annotated visual and technical sources and how to apply them. |
| [Visual concepts](concepts/README.md) | Three generated mockups showing browse, image reader, and video reader states, with review notes and exact prompts. |

Read the experience document first. The content contract and asset brief are companion specifications; the reference guide explains the evidence and inspiration behind them.

## Scope and working assumptions

- This delivery contains documentation and visual concept mockups. No game code, scenes, shaders, 3D models, texture maps, production timeline media, or executable JSON schema is created. The follow-up mockups are static illustrations, not Godot captures.
- The future implementation uses real 3D geometry and a constrained camera, with a 2D overlay for reading and controls.
- The initial target is a desktop application with mouse and keyboard, one timeline loaded at a time, and media prepared separately on disk. This is a proposed baseline, not a confirmed deployment constraint.
- The current project declares Godot `4.7` and `Forward Plus` in [project.godot](../src/project.godot). This is configuration evidence, not verification of an installed engine or working renderer. Pin the actual engine build before implementation.
- Foundation **books** guide the thematic direction. Television material is a secondary visual reference. No canonical timeline or exact fictional dates are established by these documents.
- External JSON controls timeline content and chronological organization. Godot controls appearance, spatial layout, motion, and interaction. User preferences remain separate from both.

## Proposed decisions to revisit during implementation planning

| Decision | Baseline used in these documents | When to revisit |
| --- | --- | --- |
| Chronological spacing | Ordered event slots, with explicit dates and a “spacing is not to scale” note | Before supporting scientifically proportional time spacing |
| Camera | Fixed orientation with vertical movement and bounded zoom | After evaluating a graybox navigation study |
| Reading | Modal reading overlay above the visible 3D archive | During text and input usability review |
| Media delivery | Local content package; PNG/JPEG images and Ogg Theora video | Before choosing a download service or different video backend |
| Content scale | 100 events as a first production target; 1,000-event stress scenario | When representative data and target hardware are available |
| First art direction | Dark archive, brushed metal, warm gold, sparse cyan light | At art review using the asset brief |

These defaults make the proposal concrete. They are not claims of user approval or measured engine performance.
