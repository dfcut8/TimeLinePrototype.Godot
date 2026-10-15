"""Author reusable prototype scenes. Run from the repository root; no editor API required."""
from pathlib import Path
import json
import math
import re

ROOT = Path(__file__).resolve().parents[1] / 'src'
OUT = ROOT / 'prototype'


class Scene:
    def __init__(self, resources=''):
        self.text = '[gd_scene format=3]\n' + resources + '\n'

    def node(self, name, kind=None, parent=None, props='', instance=None, unique=False):
        line = f'[node name="{name}"'
        if kind:
            line += f' type="{kind}"'
        if parent is not None:
            line += f' parent="{parent}"'
        if instance:
            line += f' instance=ExtResource("{instance}")'
        self.text += line + ']\n'
        if unique:
            self.text += 'unique_name_in_owner = true\n'
        self.text += props + '\n'

    def save(self, path):
        (OUT / path).write_text(self.text, encoding='utf-8')


def ext(kind, path, key):
    return f'[ext_resource type="{kind}" path="res://{path}" id="{key}"]\n'


FULL = 'layout_mode = 1\nanchors_preset = 15\nanchor_right = 1.0\nanchor_bottom = 1.0\ngrow_horizontal = 2\ngrow_vertical = 2\n'
EXPAND = 'size_flags_horizontal = 3\nsize_flags_vertical = 3\n'


def button(scene, name, label, parent, extra=''):
    scene.node(name, 'Button', parent, f'text = {json.dumps(label, ensure_ascii=False)}\nfocus_mode = 2\n' + extra, unique=True)


def label(scene, name, text, parent, props=''):
    scene.node(name, 'Label', parent, f'text = {json.dumps(text, ensure_ascii=False)}\n' + props, unique=True)


def modal(name):
    scene = Scene()
    scene.node(name, 'Control', props=FULL + 'visible = false\n')
    scene.node('Shade', 'ColorRect', '.', FULL + 'color = Color(0.01, 0.025, 0.045, 0.82)\n')
    scene.node('Panel', 'PanelContainer', '.', FULL + 'offset_left = 32.0\noffset_top = 90.0\noffset_right = -32.0\noffset_bottom = -30.0\n')
    scene.node('Margin', 'MarginContainer', 'Panel', 'theme_override_constants/margin_left = 22\ntheme_override_constants/margin_right = 22\ntheme_override_constants/margin_top = 18\ntheme_override_constants/margin_bottom = 18\n')
    scene.node('Column', 'VBoxContainer', 'Panel/Margin', 'theme_override_constants/separation = 12\n')
    return scene, 'Panel/Margin/Column'


def ui():
    scene = Scene()
    scene.node('ArchiveHUD', 'Control', props=FULL + 'mouse_filter = 2\n')
    scene.node('Top', 'MarginContainer', '.', 'offset_left = 28.0\noffset_top = 20.0\noffset_right = -28.0\nanchor_right = 1.0\nmouse_filter = 2\n')
    scene.node('Header', 'HFlowContainer', 'Top', 'mouse_filter = 2\ntheme_override_constants/h_separation = 14\n')
    scene.node('Brand', 'VBoxContainer', 'Top/Header', 'size_flags_horizontal = 3\nmouse_filter = 2\ncustom_minimum_size = Vector2(240, 0)\n')
    label(scene, 'Title', 'GALACTIC ARCHIVE', 'Top/Header/Brand', 'theme_override_font_sizes/font_size = 24\nautowrap_mode = 3\nmax_lines_visible = 2\ntext_overrun_behavior = 3\n')
    label(scene, 'Era', 'A library of possible futures', 'Top/Header/Brand', 'theme_override_colors/font_color = Color(0.53, 0.74, 0.8, 1)\nautowrap_mode = 3\nmax_lines_visible = 2\ntext_overrun_behavior = 3\n')
    for name, text in [('Choose', 'Choose timeline…'), ('Index', 'Index  [I]'), ('Help', 'Help  [F1]'), ('Settings', 'Settings')]:
        button(scene, name, text, 'Top/Header')
    scene.node('Bottom', 'PanelContainer', '.', 'layout_mode = 1\nanchor_top = 1.0\nanchor_right = 1.0\nanchor_bottom = 1.0\noffset_left = 24.0\noffset_top = -184.0\noffset_right = -24.0\noffset_bottom = -20.0\ngrow_vertical = 0\n', unique=True)
    scene.node('Margin', 'MarginContainer', 'Bottom', 'theme_override_constants/margin_left = 18\ntheme_override_constants/margin_right = 18\ntheme_override_constants/margin_top = 12\ntheme_override_constants/margin_bottom = 12\n')
    scene.node('Column', 'VBoxContainer', 'Bottom/Margin', 'theme_override_constants/separation = 8\n')
    label(scene, 'Current', 'Select a record to begin', 'Bottom/Margin/Column', 'autowrap_mode = 3\n')
    scene.node('Controls', 'HFlowContainer', 'Bottom/Margin/Column', 'theme_override_constants/h_separation = 8\ntheme_override_constants/v_separation = 6\n')
    for name, text in [('First', '|<'), ('Previous', '< Previous'), ('Open', 'Open record  [Enter]'), ('Next', 'Next >'), ('Last', '>|'), ('OrbitLeft', 'Orbit <'), ('OrbitRight', 'Orbit >'), ('ZoomOut', '−'), ('Reset', 'Reset view'), ('ZoomIn', '+')]:
        button(scene, name, text, 'Bottom/Margin/Column/Controls')
    scene.node('Overview', 'HSlider', 'Bottom/Margin/Column', 'step = 1.0\nmax_value = 19.0\nfocus_mode = 2\n', unique=True)
    label(scene, 'Status', 'Earlier ←   → Later · Spacing is not to scale · Drag to orbit · Wheel to browse', 'Bottom/Margin/Column', 'autowrap_mode = 3\ntheme_override_font_sizes/font_size = 14\n')
    scene.node('ArchiveFocus', 'Control', '.', 'focus_mode = 2\nmouse_filter = 2\n', unique=True)
    scene.save('archive_hud.tscn')

    scene = Scene(ext('Script', 'prototype/media_view.gd', 'script'))
    scene.node('MediaView', 'VBoxContainer', props='script = ExtResource("script")\nsize_flags_horizontal = 3\nsize_flags_vertical = 3\ntheme_override_constants/separation = 8\n')
    scene.node('Surface', 'AspectRatioContainer', '.', 'size_flags_horizontal = 3\nsize_flags_vertical = 3\ncustom_minimum_size = Vector2(180, 180)\nratio = 1.77778\n', unique=True)
    scene.node('Backdrop', 'ColorRect', 'Surface', 'color = Color(0.025, 0.045, 0.065, 1)\nmouse_filter = 2\n')
    scene.node('Image', 'TextureRect', 'Surface', 'expand_mode = 1\nstretch_mode = 5\nmouse_filter = 2\n', unique=True)
    scene.node('Video', 'VideoStreamPlayer', 'Surface', 'expand = true\nautoplay = false\nvisible = false\nfocus_mode = 2\n', unique=True)
    label(scene, 'MediaStatus', 'Media', '.', 'autowrap_mode = 3\nmax_lines_visible = 3\ntext_overrun_behavior = 3\n')
    scene.node('Controls', 'HFlowContainer', '.', unique=True)
    for name, text in [('Play', 'Play'), ('Restart', 'Restart'), ('Mute', 'Mute'), ('Retry', 'Retry media')]:
        button(scene, name, text, 'Controls')
    scene.node('Volume', 'HSlider', 'Controls', 'custom_minimum_size = Vector2(120, 32)\nmax_value = 1.0\nstep = 0.05\nvalue = 0.5\nfocus_mode = 2\n', unique=True)
    label(scene, 'Elapsed', '0:00', 'Controls')
    scene.save('media_view.tscn')

    scene, parent = modal('RecordReader')
    scene.text = scene.text.replace('[gd_scene format=3]', '[gd_scene format=3]\n' + ext('PackedScene', 'prototype/media_view.tscn', 'media'))
    label(scene, 'ContextStrip', '', '.', 'anchor_right = 1.0\noffset_left = 32.0\noffset_right = -32.0\noffset_top = 18.0\noffset_bottom = 72.0\nautowrap_mode = 3\nmax_lines_visible = 1\ntext_overrun_behavior = 3\nhorizontal_alignment = 1\n')
    scene.node('Context', 'HFlowContainer', parent)
    for name, text in [('Previous', '< Previous event'), ('Next', 'Next event >'), ('Enlarge', 'Enlarge media'), ('Close', 'Close  [Esc]')]:
        button(scene, name, text, parent + '/Context')
    label(scene, 'Date', '', parent, 'autowrap_mode = 3\nmax_lines_visible = 2\ntext_overrun_behavior = 3\n')
    label(scene, 'Title', '', parent, 'autowrap_mode = 3\nmax_lines_visible = 2\ntext_overrun_behavior = 3\ntheme_override_font_sizes/font_size = 26\n')
    scene.node('ContentScroll', 'ScrollContainer', parent, EXPAND + 'horizontal_scroll_mode = 0\n', unique=True)
    scene.node('Columns', 'BoxContainer', parent + '/ContentScroll', EXPAND + 'theme_override_constants/separation = 24\n', unique=True)
    scene.node('Media', parent=parent + '/ContentScroll/Columns', instance='media', props=EXPAND, unique=True)
    scene.node('Body', 'RichTextLabel', parent + '/ContentScroll/Columns', 'size_flags_horizontal = 3\nsize_flags_vertical = 3\nsize_flags_stretch_ratio = 0.7\ncustom_minimum_size = Vector2(260, 240)\nfit_content = true\nscroll_active = false\nselection_enabled = true\nfocus_mode = 2\nbbcode_enabled = false\n', unique=True)
    scene.save('record_reader.tscn')

    scene, parent = modal('EventIndex')
    label(scene, 'Heading', 'CHRONOLOGICAL INDEX', parent, 'theme_override_font_sizes/font_size = 24\n')
    scene.node('EraRow', 'HFlowContainer', parent, unique=True)
    scene.node('List', 'ItemList', parent, EXPAND + 'allow_reselect = true\n', unique=True)
    scene.node('Actions', 'HFlowContainer', parent)
    button(scene, 'Open', 'Open selected record', parent + '/Actions')
    button(scene, 'Close', 'Close  [Esc]', parent + '/Actions')
    scene.save('event_index.tscn')

    scene, parent = modal('ArchiveSettings')
    label(scene, 'Heading', 'ARCHIVE SETTINGS', parent, 'theme_override_font_sizes/font_size = 24\n')
    scene.node('Scroll', 'ScrollContainer', parent, EXPAND + 'horizontal_scroll_mode = 0\n')
    scene.node('Options', 'VBoxContainer', parent + '/Scroll', 'size_flags_horizontal = 3\ntheme_override_constants/separation = 12\n')
    options = parent + '/Scroll/Options'
    label(scene, 'ScaleLabel', 'Text size', options)
    scene.node('TextScale', 'OptionButton', options, 'item_count = 4\nselected = 0\npopup/item_0/text = "100%"\npopup/item_0/id = 0\npopup/item_1/text = "125%"\npopup/item_1/id = 1\npopup/item_2/text = "150%"\npopup/item_2/id = 2\npopup/item_3/text = "200%"\npopup/item_3/id = 3\n', unique=True)
    scene.node('ReducedMotion', 'CheckButton', options, 'text = "Reduced motion"\n', unique=True)
    scene.node('LowEffects', 'CheckButton', options, 'text = "Low effects (disable glow and fog)"\n', unique=True)
    label(scene, 'VolumeLabel', 'Media volume', options)
    scene.node('Volume', 'HSlider', options, 'max_value = 1.0\nstep = 0.05\nvalue = 0.5\ncustom_minimum_size = Vector2(150, 32)\n', unique=True)
    scene.node('Mute', 'CheckButton', options, 'text = "Mute media"\n', unique=True)
    scene.node('Files', 'HFlowContainer', options)
    button(scene, 'Choose', 'Choose timeline JSON…', options + '/Files')
    button(scene, 'Reload', 'Reload content', options + '/Files')
    label(scene, 'Source', '', options, 'autowrap_mode = 3\n')
    label(scene, 'Diagnostics', '', options, 'autowrap_mode = 3\n')
    button(scene, 'Close', 'Close  [Esc]', parent)
    scene.save('archive_settings.tscn')

    scene, parent = modal('ArchiveHelp')
    label(scene, 'Title', 'EXPLORE THE ARCHIVE', parent, 'theme_override_font_sizes/font_size = 24\n')
    scene.node('Body', 'RichTextLabel', parent, EXPAND + 'focus_mode = 2\ntext = ' + json.dumps('The room and timeline remain fixed. The camera moves around them.\n\nBROWSE\nLeft/Right or Up/Down: previous/next record\nPage Up/Down: jump five records · Home/End: first/last\nEnter: open focused record · I: index · F1: help\nMouse wheel: browse · Ctrl + wheel or + / −: zoom\nDrag empty space: orbit · Q/E: orbit · R: reset view\nUse the on-screen orbit buttons for mouse-only exploration.\n\nREAD\nEscape closes one layer at a time. Alt + Left/Right changes records.\nVideo starts only when you press Play. Space on the video pauses/resumes.\nEnlarge media preserves playback and your reading position.\nTab / Shift+Tab moves through visible controls.\n\nCONTENT\nChoose a local timeline JSON in Settings. Images and Ogg Theora video resolve relative to it. Reload keeps the previous valid archive when the replacement is invalid.\n\nEarlier/later describes chronological order, not distance. From behind, the projected direction reverses; near an end-on view use the index or Reset View. Undated records are a separate section.\n\nThe bundled 20-record archive is original illustrative fiction. Concept images are presentation studies; the calibration clip is a generated playback test. It is not Foundation canon.', ensure_ascii=False) + '\n')
    button(scene, 'Close', 'Return to archive  [Esc]', parent)
    scene.save('archive_help.tscn')


def room():
    scene = Scene(ext('PackedScene', 'prototype/gallery/curved_gallery.glb', 'model'))
    scene.node('GallerySector', 'Node3D')
    scene.node('Model', parent='.', instance='model')
    scene.save('gallery/gallery_sector.tscn')
    resources = ''.join(ext('PackedScene', p, k) for k, p in [
        ('perimeter', 'assets/wall_infill_bay/library_catalog_perimeter.tscn'),
        ('floor', 'assets/grounded_room_review/library_floor.tscn'),
        ('row', 'assets/reading_bench/configurable_reading_alcove.tscn'),
        ('gallery', 'prototype/gallery/gallery_sector.tscn'),
        ('beam', 'assets/radial_roof_beam/radial_roof_beam.tscn'),
        ('curb', 'assets/oculus_curb_segment/oculus_curb_segment.tscn'),
        ('island', 'assets/record_stack_end_cap/configurable_archive_island.tscn'),
    ])
    scene = Scene(resources)
    scene.node('GalacticLibrary', 'Node3D')
    scene.node('Perimeter', parent='.', instance='perimeter')
    scene.node('Floor', parent='.', instance='floor')
    for i in range(24):
        a = math.radians(i * 15)
        for tier in [5.0, 10.0]:
            scene.node(f'Gallery{i}_{int(tier)}', parent='.', instance='gallery', props=f'position = Vector3(0, {tier}, 0)\nrotation = Vector3(0, {a}, 0)\n')
        scene.node(f'Beam{i}', parent='.', instance='beam', props=f'position = Vector3({10.15 * math.cos(a)}, 14.75, {-10.15 * math.sin(a)})\nrotation = Vector3(0, {a}, 0)\n')
        scene.node(f'Curb{i}', parent='.', instance='curb', props=f'position = Vector3(0, 14.15, 0)\nrotation = Vector3(0, {a}, 0)\n')
    for i, degrees in enumerate([30, 60, 120, 150, 210, 240, 300, 330]):
        a = math.radians(degrees)
        scene.node(f'ReadingAlcove{i}', parent='.', instance='row', props=f'position = Vector3({21.5*math.sin(a)}, 0, {-21.5*math.cos(a)})\nrotation_degrees = Vector3(0, {-degrees}, 0)\nbay_count = 3\n')
    scene.save('galactic_library.tscn')

    scene = Scene('''[sub_resource type="Shader" id="sky_shader"]
code = "shader_type sky; void sky() { vec3 d = normalize(EYEDIR); float h = max(d.y, 0.0); vec3 col = mix(vec3(0.015,0.025,0.052), vec3(0.004,0.009,0.025), h); vec2 cell = floor(vec2(atan(d.z,d.x)*160.0, asin(d.y)*160.0)); float star = fract(sin(dot(cell,vec2(12.9898,78.233)))*43758.5453); if(star>0.993) col += vec3(0.28,0.43,0.55)*pow((star-0.993)/0.007,3.0); float planet = dot(d,normalize(vec3(0.93,0.24,-0.27))); if(planet>0.986) col = mix(vec3(0.04,0.10,0.17),vec3(0.28,0.44,0.53),smoothstep(0.986,0.988,planet))*(0.4+0.6*max(dot(d,normalize(vec3(-0.4,0.8,0.2))),0.0)); COLOR = col; }"
[sub_resource type="ShaderMaterial" id="sky_material"]
shader = SubResource("sky_shader")
[sub_resource type="Sky" id="sky"]
sky_material = SubResource("sky_material")
[sub_resource type="Environment" id="environment"]
background_mode = 2
sky = SubResource("sky")
ambient_light_source = 3
ambient_light_color = Color(0.38, 0.56, 0.7, 1)
ambient_light_energy = 0.3
reflected_light_source = 2
tonemap_mode = 2
glow_enabled = true
glow_intensity = 0.35
fog_enabled = true
fog_light_color = Color(0.075, 0.12, 0.18, 1)
fog_density = 0.002
''')
    scene.node('ArchiveAtmosphere', 'Node3D')
    scene.node('WorldEnvironment', 'WorldEnvironment', '.', 'environment = SubResource("environment")\n')
    scene.node('Key', 'DirectionalLight3D', '.', 'rotation_degrees = Vector3(-35, -30, 0)\nlight_color = Color(0.7, 0.85, 1, 1)\nlight_energy = 0.65\n')
    scene.node('Fill', 'DirectionalLight3D', '.', 'rotation_degrees = Vector3(25, 145, 0)\nlight_color = Color(0.6, 0.72, 0.86, 1)\nlight_energy = 0.3\nlight_specular = 0.0\n')
    for i in range(8):
        a = math.radians(i * 45 + 22.5)
        scene.node(f'ShelfGlow{i}', 'OmniLight3D', '.', f'position = Vector3({20 * math.sin(a)}, 2.5, {-20 * math.cos(a)})\nlight_color = Color(1, 0.62, 0.28, 1)\nlight_energy = 4.0\nomni_range = 10.0\nlight_specular = 0.2\n')
    scene.save('archive_atmosphere.tscn')

    scene = Scene(ext('PackedScene', 'assets/era_label_tab/era_label_tab.tscn', 'tab'))
    scene.node('EraMarker', 'Node3D')
    scene.node('Tab', parent='.', instance='tab')
    scene.node('Label', 'Label3D', '.', 'position = Vector3(0, 0.22, 0.06)\npixel_size = 0.002\nfont_size = 36\nmodulate = Color(0.6, 0.85, 0.9, 1)\nbillboard = 1\n')
    scene.save('era_marker.tscn')

    resources = ext('Script', 'prototype/archive.gd', 'script')
    for key, path in [('library', 'galactic_library'), ('atmosphere', 'archive_atmosphere'), ('camera', 'orbit_camera'), ('hud', 'archive_hud'), ('reader', 'record_reader'), ('index', 'event_index'), ('settings', 'archive_settings'), ('help', 'archive_help')]:
        resources += ext('PackedScene', 'prototype/' + path + '.tscn', key)
    resources += ext('PackedScene', 'assets/timeline_rail_housing/centered_timeline_rail.tscn', 'rail')
    scene = Scene(resources)
    scene.node('GalacticArchive', 'Node3D', props='script = ExtResource("script")\n')
    for key, name in [('library', 'Library'), ('atmosphere', 'Atmosphere'), ('camera', 'OrbitCamera')]:
        scene.node(name, parent='.', instance=key)
    scene.node('Timeline', parent='.', instance='rail', props='position = Vector3(0, 1.8, 0)\nmodule_count = 7\n')
    scene.node('Records', 'Node3D', '.')
    scene.node('EraMarkers', 'Node3D', '.')
    scene.node('Interface', 'CanvasLayer', '.')
    for key, name in [('hud', 'HUD'), ('reader', 'Reader'), ('index', 'Index'), ('settings', 'Settings'), ('help', 'Help')]:
        scene.node(name, parent='Interface', instance=key)
    scene.node('ChooseTimeline', 'FileDialog', 'Interface', 'title = "Choose a timeline JSON"\nsize = Vector2i(900, 550)\naccess = 2\nfile_mode = 0\nfilters = PackedStringArray("*.json ; Timeline JSON")\n')
    scene.node('LoadError', 'AcceptDialog', 'Interface', 'title = "Timeline could not be loaded"\nsize = Vector2i(600, 200)\n')
    scene.save('galactic_archive.tscn')


def demo():
    titles = ['The Archive Charter', 'A Room for Every Voice', 'The First Transmission', 'Two Messages, One Day', 'The Record Keepers', 'The Outer Libraries', 'A Map of Shared Memory', 'The Quiet Century', 'The Lost Dispatch', 'An Open Catalog', 'The Relay Network', 'A New Reading Room', 'The Long Crossing', 'The Return of the Surveyors', 'The Public Collection', 'A Common Calendar', 'The Renewal Assembly', 'An Archive Without Walls', 'An Unattributed Fragment', 'An Unfinished Letter']
    eras = [{'id': k, 'title': t, 'description': ''} for k, t in [('preservation', 'I · Preservation'), ('connection', 'II · Connection'), ('renewal', 'III · Renewal'), ('fragments', 'Undated fragments')]]
    data = {'schema_version': 1, 'timeline': {'id': 'possible-futures', 'title': 'GALACTIC ARCHIVE', 'description': 'A library of possible futures · Original prototype fiction', 'language': 'en', 'time_axis': {'id': 'charter-years', 'label': 'Years since the archive charter', 'unit': 'year'}}, 'eras': eras, 'events': []}
    dates = [0, 3, 12, 12, 20, 35, 60, 100, 140, 200, 215, 280, 340, 500, 700, 720, 900, 1200, None, None]
    for i, title in enumerate(titles):
        video = i in [2, 10]
        path = 'media/calibration.ogv' if video else ['media/library.png', 'media/orbit.png', 'media/records.png'][i % 3]
        if i == 8:
            path = 'media/missing-dispatch.png'
        media = {'path': path, 'description': 'A generated color and motion calibration chart with a quiet 220 Hz tone.' if video else 'Original concept art showing the proposed galactic library and archive objects.', 'credit': {'text': 'Original prototype calibration clip generated with FFmpeg.' if video else 'Project concept art · AI-generated spatial library study'}}
        if video:
            media['poster'] = {'path': 'media/orbit.png', 'description': 'The spatial library concept study.', 'credit': {'text': 'Project concept art · AI-generated'}}
            media['transcript'] = 'Playback calibration: colored bands and a moving test pattern repeat over six seconds. A quiet constant tone demonstrates volume, mute and pause. This is test media, not narrative footage.'
        date = {'start': dates[i], 'label': f'Year {dates[i]}' if dates[i] is not None else 'Date unknown', 'precision': 'exact' if dates[i] is not None else 'unknown'}
        if i == 5:
            date.update(label='Approximately Year 35', precision='approximate')
        if i == 7:
            date.update(label='Years 100–130', precision='range', end=130)
        body = f'{title} marks a chapter in this original illustrative history. Communities across a scattered civilization contribute their observations to a shared archive. Each record preserves a particular point of view, and the catalog keeps its context visible.\n\nThe library was designed for readers who might never meet the people who made these records. Dates provide order; descriptions preserve uncertainty. The spaces between entries are editorial, so a century can be crossed as easily as a day.\n\nThis record is sample content for the working prototype. Replace this JSON document and its local media with your own timeline without changing a Godot scene.'
        if i == 8:
            body += '\n\nThis media file is intentionally absent. The reader must keep this text, descriptions, credit and navigation available and offer Retry.'
        data['events'].append({'id': f'record-{i+1:02}', 'kind': 'video_text' if video else 'image_text', 'title': title, 'summary': 'An original account from a civilization learning to preserve and share its memory.', 'body': body, 'date': date, 'sequence': i, 'era_id': eras[0 if i < 6 else 1 if i < 12 else 2 if i < 18 else 3]['id'], 'media': media, 'sources': [{'title': 'Original prototype fiction', 'locator': 'Demonstration record; no historical or canonical claim.'}]})
    (ROOT / 'content/demo/timeline.json').write_text(json.dumps(data, indent=2, ensure_ascii=False), encoding='utf-8')


def export_preset():
    # Explicitly include PackedScenes loaded by scripts as well as scene-tree dependencies.
    pending = ['res://prototype/galactic_archive.tscn', 'res://addons/godot_mcp/game_bridge/mcp_game_bridge.gd']
    for directory in ('game_bridge', 'core'):
        pending += ['res://' + str(p.relative_to(ROOT)).replace('\\', '/') for p in (ROOT / 'addons/godot_mcp' / directory).glob('*.gd')]
    pending += ['res://content/demo/media/' + name for name in ('library.png', 'orbit.png', 'records.png', 'calibration.ogv')]
    resources = set()
    while pending:
        resource = pending.pop()
        if resource in resources:
            continue
        path = ROOT / resource.removeprefix('res://')
        if not path.is_file():
            continue
        resources.add(resource)
        if path.suffix in ('.tscn', '.gd', '.tres'):
            pending.extend(re.findall(r'"(res://[^"\n]+)"', path.read_text(encoding='utf-8')))
    preset = ROOT / 'export_presets.cfg'
    text = preset.read_text(encoding='utf-8')
    text = re.sub(r'export_files=PackedStringArray\([^\n]*\)', 'export_files=PackedStringArray(' + ', '.join(json.dumps(p) for p in sorted(resources)) + ')', text)
    preset.write_text(text, encoding='utf-8')


if __name__ == '__main__':
    ui()
    room()
    demo()
    export_preset()
