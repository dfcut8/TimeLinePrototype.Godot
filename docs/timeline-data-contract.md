# External JSON Content Contract

Status: proposed version 1 contract. This is documentation, including an illustrative JSON block, not a parser, validator, schema implementation, or production dataset.

## 1. Ownership boundary

An external tool or author maintains one UTF-8 JSON document per timeline. Godot reads it, validates it, and builds the browsing experience. The file is the authority for timeline data. The authoring tool's implementation language, storage system, and UI are outside this design.

| External content JSON owns | Godot presentation owns | Local user settings own |
| --- | --- | --- |
| Timeline title and description | Meshes, textures for architecture, and materials | Text scale |
| Events, eras, chronology, and editorial tie order | Left/right assignment and 3D coordinates | Volume and mute |
| Display dates and uncertainty descriptions | Spacing, camera, zoom limits, and motion | Reduced Motion and effects level |
| Text, media paths, transcripts, and descriptions | Fonts, colors, lights, animation, and selection styling | Last position, if later supported |
| Content sources and media credits | Missing-media placeholder appearance and controls | Input preferences, if later supported |

Media references identify **content**, so they belong in JSON even though they produce visible images. A frame texture, shader path, camera angle, per-event color, model name, scene path, font choice, animation name, or explicit position does not belong there. The renderer derives appearance from stable rules; the external author cannot inject Godot resources or executable expressions.

## 2. Document and identity fields

All fields marked required must be present with the stated type. Optional fields are omitted when absent unless null is explicitly permitted. Strings are plain Unicode text; no HTML, BBCode, embedded scripts, or formatting instructions are interpreted. IDs are nonempty, case-sensitive ASCII identifiers using lowercase letters, digits, hyphens, and underscores, starting with a letter.

| Field | Type | Required | Meaning |
| --- | --- | --- | --- |
| `schema_version` | integer | Yes | Exactly `1` for this contract |
| `timeline` | object | Yes | Timeline metadata described below |
| `eras` | array of era objects | Yes | May be empty |
| `events` | array of event objects | Yes | May be empty |

| `timeline` field | Type | Required | Meaning |
| --- | --- | --- | --- |
| `id` | string | Yes | Stable timeline identity |
| `title` | string | Yes | Human-readable archive title |
| `description` | string | Yes | Introduction; may be empty |
| `language` | string | Yes | Content language tag, initially `en`; one language per document |
| `time_axis` | object | Yes | `id`, `label`, and `unit`, all nonempty strings |

`time_axis` explains the normalized chronology to the author and reader. A timeline uses one comparable numeric axis; it can represent fictional years, elapsed days, or another documented unit. It is not a layout scale. Version 1 does not convert calendars in Godot. The external author normalizes mixed calendars into this common axis while preserving appropriate human-readable labels.

An era contains required `id` and `title` strings and an optional `description` string. An era's extent is derived from its member events; there is no separate era start date to drift out of sync. IDs are unique within each collection. Event references to eras must resolve within this document.

## 3. Event fields

| Field | Type | Required | Meaning |
| --- | --- | --- | --- |
| `id` | string | Yes | Stable event identity, independent of array position |
| `kind` | string enum | Yes | `image_text` or `video_text` |
| `title` | string | Yes | Nonempty event title |
| `summary` | string | Yes | Short overview; editorial target of 40 words or fewer |
| `body` | string | Yes | Full explanation; paragraph breaks use JSON newline escapes |
| `date` | object | Yes | Chronological position and human display label |
| `sequence` | integer | Yes | Nonnegative editorial tie-breaker within the same date |
| `era_id` | string | No | Era membership; omitted means no named era |
| `media` | object | Yes | Type-specific media fields below |
| `sources` | array of source objects | No | Evidence for event text, not asset credits |

Each source has a required nonempty `title` and optional `locator` and `url`. `locator` can identify a book edition, part, chapter, or page without requiring a web address. `url`, when present, is an HTTPS reference link. The reader displays source information; it does not silently open or fetch it.

### Dates and deterministic order

| `date` field | Type | Required | Meaning |
| --- | --- | --- | --- |
| `start` | finite number or null | Yes | Normalized chronological start; null only for unknown dates |
| `end` | finite number | No | Optional inclusive end for an interval; must be at least `start` |
| `label` | string | Yes | Nonempty display text, such as `Approximately Year 20` |
| `precision` | enum | Yes | `exact`, `approximate`, `range`, or `unknown` |

- `exact`: numeric `start`; no `end`.
- `approximate`: numeric `start` gives the author's best ordering estimate; no `end`. The label must communicate uncertainty.
- `range`: numeric `start` and `end` required. The event is ordered by its start; the label describes the interval. Version 1 presents a single event card, not a duration bar.
- `unknown`: `start` is null and `end` is absent. Its label explicitly says the date is unknown.

Numbers may be negative. Do not use formatted dates as sort keys. Avoid integers outside the exact interoperable range of −9,007,199,254,740,991 to 9,007,199,254,740,991; choose a coarser unit when necessary. NaN and infinity are not valid values.

Order dated records by `date.start` ascending, then `sequence` ascending, then `id` using ordinal ASCII order. File array order has no chronological meaning. `sequence` cannot move an event ahead of an earlier date. Unknown-date records follow in a separately labeled Undated section, ordered by `sequence` then `id`; they are not treated as the latest events.

Era membership must be contiguous in this final order. Treat unassigned events as their own unnamed grouping for this check. An era cannot span dated and undated sections; use a separate era for undated records or omit the membership. Overlapping historical period categories would need a later tagging model; they are not represented as multiple simultaneous era bands in version 1.

## 4. Media fields and delivery

Each event has one primary media item. `kind` selects its media shape; JSON does not separately name a rendering prefab.

| Field | Image + text | Video + text |
| --- | --- | --- |
| `path` | Required string; PNG or JPEG file | Required string; Ogg Theora `.ogv` baseline |
| `description` | Required nonempty image description | Required nonempty description of the video's subject |
| `credit` | Required object | Required object |
| `poster` | Not used | Optional object containing image `path`, `description`, and `credit` |
| `transcript` | Not used | Required nonempty plain-text transcript, or descriptive account for silent video |

A credit object requires `text`, which supplies the displayed creator/provider attribution. Optional `source_url` and `license` record provenance and usage terms. The separate `poster.credit` supports a poster from a different source. Copyright or licensing metadata is supplied by the content owner; Godot does not infer it from a download address.

### Delivery baseline

The content package contains the JSON file and media below the same directory. Paths use forward slashes and resolve relative to the JSON file, for example `media/records/event-01.jpg`. They are not `res://` paths and do not require the Godot editor to import external content. Godot supports runtime image/file loading separately from project resource imports. [Runtime file loading and saving](https://docs.godotengine.org/en/stable/tutorials/io/runtime_file_loading_and_saving.html).

For version 1, paths must remain inside the content package after canonical resolution. Reject absolute paths, parent traversal, engine URI schemes, and network URLs as media paths. A credits URL is metadata, not a media path. The user or an external preparation tool downloads media separately, places it in the package, and updates the JSON references. The viewer is not a downloader.

Godot's documented core video format is Ogg Theora, with optional Vorbis audio; its player does not stream video directly from a URL. This baseline therefore uses prepared local `.ogv` files. Other formats require a separately evaluated backend or conversion outside the viewer. [Godot: playing videos](https://docs.godotengine.org/en/stable/tutorials/animation/playing_videos.html).

Proposed delivery limits are images up to 4096 pixels on either axis and video up to 1920 × 1080 at 30 fps, preserving source aspect ratio. Generate thumbnails during later content preparation, or derive them at runtime within the cache budget; thumbnails are not separate visual styling instructions. Validate decoded dimensions before retaining a full texture. Unsupported or oversized media produces a readable fallback, not a document crash.

Content loads on explicit file selection or Reload, not continuous file watching. Authors save a complete replacement atomically. During reload, retain the previous valid document until the new one passes structural validation. Preserve selection by stable event ID if it still exists; otherwise return to the first available record. Never write visual positions or user settings back into source JSON.

## 5. Illustrative document

These records and dates are invented to demonstrate the contract. They are **not Foundation canon**. Media paths are placeholders; no referenced files are supplied or required for this documentation task.

```json
{
  "schema_version": 1,
  "timeline": {
    "id": "archive-study",
    "title": "A Civilization in Transition",
    "description": "An original science-fiction content example.",
    "language": "en",
    "time_axis": {
      "id": "archive-years",
      "label": "Years since the archive charter",
      "unit": "year"
    }
  },
  "eras": [
    {
      "id": "preservation",
      "title": "The Preservation Era",
      "description": "The first efforts to protect a shared record."
    }
  ],
  "events": [
    {
      "id": "archive-charter",
      "kind": "image_text",
      "title": "The Archive Charter",
      "summary": "An independent archive begins collecting records.",
      "body": "A council establishes a common repository.\n\nThis is illustrative copy for the reader layout.",
      "date": { "start": 0, "label": "Year 0", "precision": "exact" },
      "sequence": 0,
      "era_id": "preservation",
      "media": {
        "path": "media/archive-charter.jpg",
        "description": "A monumental chamber surrounding a central record pedestal.",
        "credit": { "text": "Placeholder: credit to be supplied with the image" }
      }
    },
    {
      "id": "first-transmission",
      "kind": "video_text",
      "title": "The First Transmission",
      "summary": "The archive shares its first public message.",
      "body": "The transmission describes the archive's purpose and invites distant settlements to contribute.",
      "date": {
        "start": 12,
        "label": "Approximately Year 12",
        "precision": "approximate"
      },
      "sequence": 0,
      "era_id": "preservation",
      "media": {
        "path": "media/first-transmission.ogv",
        "description": "A speaker addresses an assembly from the archive chamber.",
        "credit": { "text": "Placeholder: credit to be supplied with the video" },
        "poster": {
          "path": "media/first-transmission-poster.jpg",
          "description": "The archive speaker before the transmission begins.",
          "credit": { "text": "Placeholder: credit to be supplied with the poster" }
        },
        "transcript": "Illustrative transcript: We preserve this record for those who follow."
      }
    }
  ]
}
```

## 6. Validation and failure policy

| Condition | Required response |
| --- | --- |
| Invalid JSON, duplicate JSON property, missing required field, wrong type, unsupported version or kind | Reject the new document; retain any previously loaded valid timeline |
| Duplicate ID, invalid date, unresolved era, noncontiguous era block, forbidden media path | Reject with the event ID and field location where possible |
| Missing/corrupt media, unsupported codec, decode failure, media exceeds delivery limits | Keep the event; show text, placeholder, reason, and Retry |
| Missing poster file | Show the neutral video placeholder; video remains independently playable |
| Empty `events` | Show a valid empty archive and Choose Timeline |
| Optional field omitted | Use the absence behavior specified above; no fabricated sources, dates, or credits |
| Unknown field in version 1 | Ignore it with an author-facing diagnostic; it must not alter presentation |

Initial guardrails to confirm during implementation: a 10 MiB JSON file limit, at most 10,000 event records, title length of 200 characters, summary length of 1,000 characters, and body/transcript length of 100,000 characters each. Exceeding a limit rejects the document with a specific diagnostic. These are bounded-input design limits, not parser performance claims; 1,000 events remain the first stress-test target.

The future validator must check semantics after JSON parsing. Successful parsing alone does not establish usable IDs, dates, or paths. Reader-facing errors should be concise; author diagnostics can include JSON field paths such as `events[1].media.path`. Media file absence is intentionally recoverable so authors can work before downloading every asset.

## 7. Versioning and deferred features

Breaking field changes require a new `schema_version`. Migrations belong in the external content workflow; the viewer must report unsupported versions instead of guessing. Keep IDs stable across revisions for navigation and possible future bookmarks.

Future versions can add translations, timed captions, multiple media per event, event relationships, tags, or remote delivery manifests. None may introduce model paths, colors, transforms, or shader parameters into the content contract. A machine-readable JSON Schema and validation fixtures should be created only in a later implementation task.
