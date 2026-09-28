"""Render four asset review angles; no Godot interaction."""
import bpy
from pathlib import Path
from mathutils import Vector
OUT=Path(OUTPUT_DIR)
scene=bpy.context.scene
camera=scene.camera
ground=next(o for o in scene.objects if o.name.startswith("REVIEW_ground"))
def render_view(name,location,hide_floor=False):
    ground.hide_render=hide_floor
    camera.location=location
    camera.rotation_euler=(Vector((0,0,H/2))-camera.location).to_track_quat("-Z","Y").to_euler()
    scene.render.filepath=str(OUT/(name+".png"))
    bpy.ops.render.render(write_still=True)
render_view("preview_front",(.82,-1.10,.70))
render_view("preview_rear",(-.82,1.10,.65))
render_view("preview_side",(1.1,0,H/2))
render_view("preview_underside",(.80,-1.10,-.48),True)
ground.hide_render=False
camera.location=(.82,-1.10,.70)
camera.rotation_euler=(Vector((0,0,H/2))-camera.location).to_track_quat("-Z","Y").to_euler()
scene.render.filepath=str(OUT/"preview_front.png")
(OUT/"source").mkdir(exist_ok=True)
bpy.data.libraries.write(str(OUT/NAME+".blend"),{scene},fake_user=True,compress=True)
print("Four review renders saved.")
