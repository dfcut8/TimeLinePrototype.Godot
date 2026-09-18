"""Run in the live asset review scene after build_asset.py."""
import bpy
from pathlib import Path
from mathutils import Vector
OUT=Path(__file__).resolve().parent
scene=bpy.context.scene
camera=scene.camera
for name,loc in [('front',(2.8,-3,1.7)),('rear',(-.5,3,.8)),('underside',(2.6,-3,-1.4))]:
    camera.location=loc
    camera.rotation_euler=(Vector((1,0,0))-camera.location).to_track_quat('-Z','Y').to_euler()
    scene.render.filepath=str(OUT/('preview_'+name+'.png'))
    bpy.ops.render.render(write_still=True)
camera.location=(2.8,-3,1.7)
camera.rotation_euler=(Vector((1,0,0))-camera.location).to_track_quat('-Z','Y').to_euler()
