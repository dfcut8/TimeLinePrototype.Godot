# 3D Timeline — Design Documentation

Status: concept-art review. Updated 16 September 2026. Horizontal layout is the selected direction; detailed forms remain proposals.

A horizontal, navigable 3D archive inside a spacious galactic library. The camera orbits the central timeline; the default browse view reads earlier left and later right. Start with the [V5 spatial-library concept pack](concepts/spatial-library-v5/README.md): eight selected art boards, a review of every prior concept, and complete scene-element coverage for future modeling. Foundation provides thematic inspiration; the presentation assets are original concepts.

The experience specification and original asset brief below preserve the older vertical proposal. Their camera, orientation and ornate geometry requirements are superseded by V5 and need reconciliation before implementation.

## Documents

| Document | Purpose |
| --- | --- |
| [Experience and visual design](timeline-design.md) | Spatial composition, wireframes, camera, controls, accessibility, Godot responsibilities, and acceptance criteria. |
| [External JSON content contract](timeline-data-contract.md) | Content ownership, chronology, fields, media references, validation rules, and an illustrative JSON example. |
| [3D asset production brief](timeline-asset-brief.md) | Models, textures, materials, effects, production conventions, and delivery gates. |
| [Reference guide](timeline-references.md) | Annotated visual and technical sources and how to apply them. |
| [Visual concepts](concepts/README.md) | Full concept history, horizontal layout studies, and the current eight-board spatial-library art pack with exact prompts. |

Read the V5 concept pack first for current art direction. The older experience document, content contract and asset brief preserve prior planning; the reference guide explains the original evidence and inspiration.

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
| Camera | Orbit around the fixed horizontal timeline; stable default browse and reading views | Graybox camera clearance, end-on overlap and reverse-view chronology |
| Reading | Modal reading overlay above the visible 3D archive | During text and input usability review |
| Media delivery | Local content package; PNG/JPEG images and Ogg Theora video | Before choosing a download service or different video backend |
| Content scale | 100 events as a first production target; 1,000-event stress scenario | When representative data and target hardware are available |
| Current art direction | Spacious surrounding library, matte graphite/ceramic, warm shelf light, fine cyan-white timeline | Review V5 concepts before modeling |

These defaults make the proposal concrete. They are not claims of user approval or measured engine performance.
