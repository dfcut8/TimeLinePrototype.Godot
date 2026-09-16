# Reference Guide

Researched 16 September 2026. Links are references; no reference media was downloaded. A later visual-review pass created three original [concept mockups](concepts/README.md), separate from production assets and timeline media. Each application below is a proposed design interpretation unless explicitly described as an engine capability.

## 1. Narrative and visual references

| Reference | What to study | Application to this timeline |
| --- | --- | --- |
| [Foundation — publisher description](https://penguinrandomhouselibrary.com/book/?isbn=9780553293357) | The broad premise of a long-lived Galactic Empire and a future historical transition | Give the archive an institutional scale and organize it into meaningful eras. The publisher's search-indexed description was available; direct page retrieval failed during research. Use the books themselves for event-level facts. |
| [Foundation — official Apple TV press gallery](https://www.apple.com/tv-pr/originals/foundation/photos/) | Available adaptation imagery as a visual study of architecture, scale, light, and costume/material contrast | A secondary mood reference for a restrained monumental setting. Create original silhouettes and surface treatments; the books remain the narrative reference. |
| [Foundation — official episode imagery](https://www.apple.com/ca/tv-pr/originals/foundation/episodes-images/) | A broader set of environments and compositions for later mood-board selection | Compare close, medium, and wide compositions when planning how an exhibit should read at different zooms. This page includes adaptation spoilers and is not a book chronology source. |
| [ESA — interactive Gaia sky map](https://www.esa.int/ESA_Multimedia/Images/2020/12/Interactive_map_of_the_sky_from_Gaia_s_Early_Data_Release_3) | Density, dark regions, and brightness hierarchy in a large-scale star map | Inspire an original low-contrast background with varied density. Keep the timeline clearer and brighter than the environment. |
| [ESA — Gaia Sky visualization](https://www.cosmos.esa.int/en/web/gaia/gaiadr2_gaiasky) | Navigating and simplifying a very large spatial dataset | Inform the separation between detailed nearby exhibits and compact distant markers. It is a navigation reference, not a required integration. |

The palette, archive spine, alternating frames, segmented era rings, and reading overlay are original proposals in these documents. They are not asserted to be objects or interfaces from Foundation. Television images are not evidence for book dates or events. A future Foundation dataset should cite a chosen book edition and chapter for each record and document its fictional calendar conventions.

### Later mood-board brief

Select a small set of references around four questions: What establishes monumental scale? What makes the active object obvious? What suggests age and preservation without visual clutter? What makes a long history readable? Annotate each selected image with one property to study and one concrete application to the original asset kit.

The first visual-review pass now includes [browse, image-reader, and video-reader concepts](concepts/README.md), alongside the wireframes in the [design document](timeline-design.md). These establish a proposed appearance; playable mockups, movement studies, and final artwork remain later work. External reference images are study material, not delivered project assets.

## 2. Godot technical references

| Official documentation | Verified relevance | Design consequence |
| --- | --- | --- |
| [Playing videos](https://docs.godotengine.org/en/stable/tutorials/animation/playing_videos.html) | Documents Ogg Theora playback, CPU decoding, 3D video surfaces, and lack of direct URL streaming | Use local prepared video, an explicit playback action, and one active decoder in the baseline. |
| [VideoStreamPlayer](https://docs.godotengine.org/en/stable/classes/class_videostreamplayer.html) | Documents pause, play, stop, volume, stream position, and video texture access | Build reader controls around a single playback session. Validate any later seek UI on the actual target build and media. |
| [Using a SubViewport as a texture](https://docs.godotengine.org/en/stable/tutorials/shaders/using_viewport_as_texture.html) | Shows viewport output applied to a 3D material | Provides an option for a future selected in-world video surface without allocating one live viewport per record. |
| [3D text](https://docs.godotengine.org/en/stable/tutorials/3d/3d_text.html) | Describes Label3D, TextMesh, projected controls, and text-rendering limitations | Keep world labels brief and move long reading into a stable Control-based overlay. |
| [Available 3D formats](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/available_formats.html) | Recommends glTF 2.0 and explains Blender/glTF import choices | Deliver an editable source kit with consistent glTF exports and material assignments. |
| [Runtime file loading and saving](https://docs.godotengine.org/en/stable/tutorials/io/runtime_file_loading_and_saving.html) | Distinguishes runtime loading of external files/images from imported project assets | Keep external content packages independent from Godot's visual asset authoring workflow. |

The `/stable/` documentation is a moving reference. The repository currently declares Godot 4.7, but no installed build was verified during this task. At implementation kickoff, record the exact engine build and recheck video decoding, file loading in exported applications, input focus, text rendering, and renderer behavior against that version. Documentation links are evidence of an available design path, not proof that this project already implements it.

## 3. Decisions and uncertainty

| Topic | Current design position | Still to establish |
| --- | --- | --- |
| Foundation chronology | Thematic reference only; sample records are invented | Book coverage, editions, source citations, calendar, and spoiler boundaries |
| Visual language | Original archive kit with restrained gold/cyan accents | Art review using actual concept frames and a graybox |
| Hardware | Desktop-first assumption | Minimum machine, operating systems, exact engine/renderer, and measured budgets |
| Media pipeline | Prepared local image/video package | External authoring tool, media conversion workflow, and representative test files |
| Advanced playback | Basic controls and readable transcript | Seeking, timed captions, codecs beyond the baseline, and any network delivery |
| Accessibility | Keyboard parity, readable overlay, text scaling, reduced motion | Platform screen-reader behavior and testing with representative users |

Use the [asset brief](timeline-asset-brief.md) to plan original production and the [content contract](timeline-data-contract.md) to plan external authoring. No source link in this guide automatically becomes an event-media download or a requirement to reproduce another work's art.
