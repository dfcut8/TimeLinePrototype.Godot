# Working Galactic Archive prototype

Implemented 15 October 2026 against Godot **4.7.2 stable**, Forward+/D3D12. The implementation follows the [V5 spatial library](concepts/spatial-library-v5/README.md) and the [V1 content contract](timeline-data-contract.md). V5's horizontal chronology and orbit replace the historical vertical layout and fixed camera.

![Captured from the exported prototype pack](prototype-preview.png)

## Run

Open `src/project.godot` in Godot and press **F5**. The main scene is `res://prototype/galactic_archive.tscn`. No additional add-ons or content downloads are needed for the demo. The existing Godot MCP add-on remains available for development.

From PowerShell in the repository root:

```powershell
& 'C:/home/bin/Godot_v4.7.2-stable_win64/Godot_v4.7.2-stable_win64.exe' --path src
```

The local exported data pack is `build/GalacticArchive.pck` (generated, ignored by Git). Run it with the same engine:

```powershell
& 'C:/home/bin/Godot_v4.7.2-stable_win64/Godot_v4.7.2-stable_win64.exe' --main-pack build/GalacticArchive.pck
```

## Implemented experience

The rotunda contains a continuous floor and perimeter, two gallery tiers, radial roof beams and oculus, populated reading alcoves, peripheral catalog stations and cassette displays. A fixed sky places the planet in one world direction. Cyan rail lighting and warm shelf pools establish the timeline as the focal object.

Every distinct object is a reusable scene. The application instances the library, atmosphere, orbit camera, existing configurable rail, six reusable event records, era markers and UI scenes. Existing asset GLBs are reused. `prototype/gallery/curved_gallery.glb` is a byte-identical copy of the finished gallery asset, placed outside its review folder's `.gdignore` so Godot can import it. No new model geometry was authored.

Chronology runs along +X. Dates, editorial tie order and ASCII IDs determine event order. A six-record neighborhood and a short configurable rail replace the active neighborhood on large jumps; dates do not create huge coordinates. The full index retains every record and offers era jumps. Undated records have their own section, and empty eras remain visible in the index.

The camera supports a surrounding orbit, modest elevation and bounded zoom. Panel content faces the camera upright. Rear views reverse the projected directional cue; end-on views explicitly suggest Index or Reset View because overlap is unavoidable. Reading settles the camera broadside and holds it; closing restores the previous orbit and zoom. Previous/Next updates the record returned to when the reader closes.

Readers display plain text, sources, media descriptions, attribution, and video transcripts. Images preserve aspect ratio. One Theora decoder supports explicit play/pause, restart, mute, volume, elapsed time, and pause on application focus loss. Enlarging shares that decoder and restores text scroll on return. Changing or closing a record releases its media. A missing or invalid file preserves readable content and offers Retry.

Settings persist text size (100/125/150/200%), Reduced Motion, low effects, volume and mute in `user://archive_settings.cfg`. Modal panels own input and restore focus; hidden browse controls cannot enter their Tab cycle. Text columns stack for narrow windows or larger text, with scrolling to keep content reachable.

## Controls

| Action | Mouse | Keyboard |
| --- | --- | --- |
| Previous/next event | Wheel, Previous/Next, overview slider | Left/Right, Up/Down |
| First/last; larger jump | First/Last, Index | Home/End; Page Up/Down |
| Open event | Click its casing/socket, Open button, index entry | Enter |
| Orbit | Drag empty space, Orbit buttons | Q/E |
| Zoom; default view | +/−, Ctrl+wheel; Reset View | +/−; R |
| Index; help | Header controls | I; F1 |
| Move between controls | Click | Tab / Shift+Tab |
| Reader previous/next | Reader buttons | Alt+Left / Alt+Right |
| Read long text | Wheel/scrollbar | Tab to body, arrows/Page Up/Page Down/Home/End |
| Video | Playback controls | Tab to controls; Space on video |
| Close top layer | Close/Return | Escape |

Toolbar controls retain their own keyboard focus. Click empty archive space or Tab to the archive to resume archive shortcuts. A drag exceeding six logical pixels does not open a record when released.

## Content handoff

The bundled `src/content/demo/timeline.json` contains **20 original illustrative records**, four eras, equal dates, an approximate date, an interval, undated entries, image records and two video records. It is not Foundation canon. Its three images are the project's AI-generated concept boards. Its six-second 640×360/24 fps Ogg Theora clip is an FFmpeg calibration pattern with a quiet tone. Record 9 intentionally references a missing image to demonstrate recovery.

Use **Settings → Choose timeline JSON** for another content package, or Reload after editing the current file. An empty archive also exposes Choose Timeline directly. Media paths resolve relative to the selected JSON; no scene edits are needed to replace content. Missing media is recoverable. Malformed or semantically invalid replacement documents retain the previous valid archive. Successful reload preserves the selected stable ID where it still exists.

The loader validates required types, V1 kinds, identities, duplicate JSON keys (including escaped keys), numeric dates and editorial order, contiguous eras, source fields, media paths, transcripts and content-size limits. Absolute paths, engine/network schemes and parent traversal are rejected; filesystem links are resolved to enforce package boundaries. Unknown fields are ignored with diagnostics in Settings. Content cannot supply Godot resources, transforms or formatting markup.

## Validation

Run the integration suite with an isolated application-data directory:

```powershell
$env:APPDATA = "$PWD/.prototype-user"
& 'C:/home/bin/Godot_v4.7.2-stable_win64/Godot_v4.7.2-stable_win64_console.exe' --headless --path src --script res://prototype/tests/verify_prototype.gd
```

The suite passes **109 checks** against both source and exported PCK resources. It covers actual keyboard and pointer events, picking, complete-card framing, chronology, malformed content, media playback and cleanup, external PNG/Theora loading, modal ownership, orbit restoration, scroll restoration, 1280×720 at 150/200% text (including long headings), empty content, and rapid 100/1,000-event jumps with six resident records and no browse decoders.

Live **Godot MCP** checks confirmed the intended project, imported/opened and ran the main scene, checked physical picking and runtime state, inspected front/rear and reader screenshots, and validated **112 unique meshes / 128 surfaces** without integrity findings. Editor import errors and the game's runtime log were checked separately. Two existing CP1252 SVG dimension drawings were converted to UTF-8 to clear their import errors, with their package manifest hashes updated.

**Blender MCP was unavailable**: both add-on status and scene-info calls failed. The fallback reused the completed GLBs and authored their Godot scene composition; no Blender authoring or new Blender validation is claimed.

The exported PCK was exercised by running this same external test script with `--main-pack build/GalacticArchive.pck`. Rebuild it using the `Prototype pack` export preset, or:

```powershell
& 'C:/home/bin/Godot_v4.7.2-stable_win64/Godot_v4.7.2-stable_win64_console.exe' --headless --recovery-mode --path src --export-pack 'Prototype pack' ../build/GalacticArchive.pck
```

The preset explicitly includes resources instantiated by scripts and the bundled media. A standalone Windows executable requires the matching export templates; none were installed in this environment. Cross-machine performance, other platforms, and a full hardware memory/frame-time budget remain unmeasured. The live RTX 4080 SUPER session reported 60 FPS in a spot check; this is not a benchmark. End-on overlap is handled through navigation cues and the index. Content images remain illustrative concept art.

`tools/build_prototype_scenes.py` is the original scene-authoring utility. Running it regenerates the prototype UI, room, atmosphere, demo JSON and export resource list; preserve subsequent manual scene edits before regenerating.
