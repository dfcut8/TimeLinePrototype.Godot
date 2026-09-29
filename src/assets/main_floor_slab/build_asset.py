"""Original V5 slab / fixture sources. Run in isolated Blender with -- [uplight]."""
import bpy
import bmesh
import json
import sys
import math
from pathlib import Path
from mathutils import Vector

ROOT = Path(__file__).resolve().parent.parent

def build(uplight=False):
    name = 'base_uplight_recess_housing' if uplight else 'main_floor_slab'
    out = ROOT / name
    (out/'source').mkdir(parents=True, exist_ok=True)
    (out/'source'/'.gdignore').touch()
    scene = bpy.data.scenes.new(name)
    bpy.context.window.scene = scene
    scene.unit_settings.system = 'METRIC'
    def material(name, color, rough, metal=0, emission=False):
        mat = bpy.data.materials.new(name)
        mat.use_nodes = True
        node = next(n for n in mat.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
        node.inputs['Base Color'].default_value = (*color,1)
        node.inputs['Roughness'].default_value = rough
        node.inputs['Metallic'].default_value = metal
        if emission:
            node.inputs['Emission Color'].default_value = (*color,1)
            node.inputs['Emission Strength'].default_value = .35
        mat.diffuse_color = (*color,1)
        return mat
    basalt = material('archive_basalt_ceramic',(.085,.103,.117),.81)
    graphite = material('archive_graphite',(.048,.060,.073),.68,.22)
    def cube(label, size, center):
        bpy.ops.object.select_all(action='DESELECT')
        bpy.ops.mesh.primitive_cube_add(size=1, location=center)
        ob = bpy.context.object
        ob.name = label
        ob.dimensions = size
        bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
        return ob
    if not uplight:
        # Full footprint below the tiny top chamfer: no through gaps between tiles.
        verts = [(x,y,z) for z,s in [(-.25,2),(-.002,2),(0,1.998)]
                 for x,y in [(-s,-s),(s,-s),(s,s),(-s,s)]]
        faces = [(3,2,1,0),(8,9,10,11)]
        for level in range(2):
            for i in range(4):
                a,b=level*4+i,level*4+(i+1)%4
                faces.append((a,b,b+4,a+4))
        mesh=bpy.data.meshes.new(name)
        mesh.from_pydata(verts,[],faces)
        ob=bpy.data.objects.new(name,mesh)
        scene.collection.objects.link(ob)
        ob.data.materials.append(basalt)
        objects=[ob]
    else:
        ob=cube('Housing',(.232,.108,.14),(0,-.054,0))
        cutter=cube('CavityTool',(.208,.12,.114),(0,-.07,.001))
        bpy.context.view_layer.objects.active=ob
        mod=ob.modifiers.new('Blind front recess','BOOLEAN')
        mod.operation='DIFFERENCE'
        mod.object=cutter
        bpy.ops.object.modifier_apply(modifier=mod.name)
        bpy.data.objects.remove(cutter,do_unlink=True)
        ob.data.materials.clear()
        ob.data.materials.append(graphite)
        for poly in ob.data.polygons:
            poly.material_index=0
        lens=cube('EmissionInsert',(.192,.055,.006),(0,0,0))
        lens.rotation_euler.x=math.radians(35)
        lens.location=(0,-.060,-.036)
        bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
        lens.data.materials.clear()
        lens.data.materials.append(material('archive_warm_diffuser',(.52,.32,.15),.72,emission=True))
        objects=[ob,lens]
    rows=[]
    for ob in objects:
        bpy.ops.object.select_all(action='DESELECT')
        ob.select_set(True)
        bpy.context.view_layer.objects.active=ob
        bm=bmesh.new()
        bm.from_mesh(ob.data)
        bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
        bmesh.ops.triangulate(bm,faces=list(bm.faces))
        bm.to_mesh(ob.data)
        row=dict(name=ob.name,triangles=len(bm.faces),non_manifold_edges=sum(not e.is_manifold for e in bm.edges),
                 degenerate_faces=sum(f.calc_area()<1e-12 for f in bm.faces),volume_m3=bm.calc_volume(signed=True))
        assert row['non_manifold_edges']==row['degenerate_faces']==0 and row['volume_m3']>0
        bm.free()
        bpy.ops.object.mode_set(mode='EDIT')
        bpy.ops.mesh.select_all(action='SELECT')
        bpy.ops.uv.smart_project(island_margin=.02)
        bpy.ops.object.mode_set(mode='OBJECT')
        rows.append(row)
    bpy.ops.object.select_all(action='DESELECT')
    for ob in objects: ob.select_set(True)
    bpy.ops.export_scene.gltf(filepath=str(out/(name+'.glb')),use_selection=True,use_active_scene=True,
                              export_animations=False,export_cameras=False,export_lights=False,export_yup=True)
    report=dict(issue=26 if uplight else 20,blender_version=bpy.app.version_string,meshes=rows,
                materials=2 if uplight else 1,uv_sets=1,dimensions_godot_m=[.232,.14,.108] if uplight else [4,.25,4],
                mcp='Unavailable; isolated Blender CLI fallback')
    (out/'validation.json').write_text(json.dumps(report,indent=2))
    world=bpy.data.worlds.new(name+'_Studio')
    world.use_nodes=True
    bg=next(n for n in world.node_tree.nodes if n.type=='BACKGROUND')
    bg.inputs[0].default_value=(.12,.14,.17,1)
    bg.inputs[1].default_value=.7
    scene.world=world
    camera=bpy.data.objects.new('ReviewCamera',bpy.data.cameras.new('ReviewCamera'))
    scene.collection.objects.link(camera)
    camera.data.type='ORTHO'
    camera.data.ortho_scale=.34 if uplight else 6.3
    scene.camera=camera
    target=Vector((0,-.054,0) if uplight else (0,0,-.125))
    scale=.06 if uplight else 1
    def aim(ob,position):
        ob.location=target+Vector(position)*scale
        ob.rotation_euler=(target-ob.location).to_track_quat('-Z','Y').to_euler()
    for label,pos,power in [('Key',(3,-5,7),1700),('Fill',(-4,-1,4),1000),('Rim',(2,4,5),1600),('Under',(0,-3,-4),800)]:
        data=bpy.data.lights.new(label,'AREA')
        data.energy=power*scale*scale
        data.size=5*scale
        lamp=bpy.data.objects.new(label,data)
        scene.collection.objects.link(lamp)
        aim(lamp,pos)
    scene.render.engine='CYCLES'
    scene.cycles.samples=24
    scene.render.resolution_x=800
    scene.render.resolution_y=600
    scene.render.resolution_percentage=100
    scene.render.image_settings.file_format='PNG'
    for label,pos in [('front',(5,-9,6)),('rear',(-5,9,4)),('underside',(5,-9,-5)),('side',(9,-1,2))]:
        aim(camera,pos)
        scene.render.filepath=str(out/('preview_'+label+'.png'))
        bpy.ops.render.render(write_still=True)
    aim(camera,(5,-9,6))
    bpy.data.libraries.write(str(out/'source'/(name+'.blend')),{scene},fake_user=True,compress=True)
    print(json.dumps(report))

if __name__=='__main__':
    build('--' in sys.argv and 'uplight' in sys.argv[sys.argv.index('--')+1:])
