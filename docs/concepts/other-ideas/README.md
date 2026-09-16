# Other ideas — rotating spine and camera-facing panels

An independent concept exploration, created 16 September 2026. The [matte browse concept](../04-timeline-browse-minimal-v2.png) and all earlier concepts remain unchanged. This proposal does not replace the fixed-camera baseline in the main design document.

![Rotating 3D spine with camera-facing content panels](rotating-spine-billboards-v1.png)

## Idea

The slim matte spine and radial connector arms rotate a full 360 degrees about the vertical axis. Event positions travel around that axis at their chronological heights. Each complete image-and-text or video-and-text panel independently keeps its front face aligned with the camera, so its contents remain upright and readable. This camera-facing behavior is commonly called billboarding.

The screenshot-like illustration depicts an indicative 35-degree rotation. Depth comes from the spine's visible cross-section, foreshortened supports, and panels at different distances. The closer video panel appears larger; the farther panels are smaller. The dashed rotation arc is an explanatory annotation, not a solid ring added to the spine.

## Behavior to explore later

- Horizontal drag on empty space rotates the assembly. Vertical scrolling continues to move earlier/later. Proposed mouse buttons and keyboard Left/Right provide equivalent rotation actions while the archive owns focus.
- Rotation preserves every event's chronological height. A full revolution returns the same arrangement; panel faces never rotate away or reveal mirrored text.
- Panel positions rotate with the assembly, but panel orientation stays camera-aligned. Labels, image, and frame rotate together as a single billboard surface, independently of their support arm.
- Full rotation will sometimes align panels with the spine or with one another in screen space. A future prototype must check those views, prevent selected text from being obscured, and retain access through the index and reading overlay. This single illustration does not resolve every occlusion case.
- Keep rotation user-controlled, with no automatic spin. Opening the reader pauses assembly rotation. The existing reading view provides a stable full-size alternative for farther content.

## Deliverables and limits

This is a static generated concept, not a Godot capture or functional rotation demonstration. It establishes an appearance and interaction idea; camera behavior, picking, collision/overlap handling, and readability through all angles require future implementation testing. No existing concept or main specification was overwritten.

Created with the built-in image-generation tool. The [submitted prompts](prompts-rotating-spine.md) include the initial generation and final correction for front-facing panel geometry.
