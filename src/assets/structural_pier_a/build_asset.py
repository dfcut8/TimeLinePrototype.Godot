"""Original pier authoring source. Blender --background --python this_file [-- b].

Creates an isolated scene; writes only the chosen pier's generated outputs.
Shared dimensions are in metres. Blender -Y becomes Godot +Z (front).
"""
import bpy
import bmesh
import json
import sys
from pathlib import Path
from mathutils import Vector

ROOT = Path(__file__).resolve().parent.parent


def build(narrow=False):
    name = 'structural_pier_b' if narrow else 'structural_pier_a'
    out = ROOT / name
    (out / 'source').mkdir(parents=True, exist_ok=True)
    (out / 'source' / '.gdignore').touch()
    scene = bpy.data.scenes.new(name)
    bpy.context.window.scene = scene
    scene.unit_settings.system = 'METRIC'
    width = .4 if narrow else .8
    def ring(w, d, z):
        x, y, c = w/2, d/2, .012
        return [(-x+c,-y,z),(x-c,-y,z),(x,-y+c,z),(x,y-c,z),
                (x-c,y,z),(-x+c,y,z),(-x,y-c,z),(-x,-y+c,z)]
    verts = []
    for w, d, z in [(width+.1,.8,0),(width+.1,.8,.16),(width,.6,.26),(width,.6,4.75)]:
        verts += ring(w,d,z)
    faces = [tuple(reversed(range(8))), tuple(range(24,32))]
    for layer in range(3):
        for i in range(8):
            a, b = layer*8+i, layer*8+(i+1)%8
            faces.append((a,b,b+8,a+8))
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(verts, [], faces)
    obj = bpy.data.objects.new(name,mesh)
    scene.collection.objects.link(obj)
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    # A real blind pocket, not a dark polygon pasted over the front.
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0,-.30,.39))
    cutter = bpy.context.object
    cutter.dimensions = (.24,.24,.16)
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    bpy.context.view_layer.objects.active = obj
    modifier = obj.modifiers.new('Reserved uplight pocket', 'BOOLEAN')
    modifier.operation = 'DIFFERENCE'
    modifier.object = cutter
    bpy.ops.object.modifier_apply(modifier=modifier.name)
    bpy.data.objects.remove(cutter, do_unlink=True)
    obj.data.materials.clear()
    for mat_name, color, rough, metal in [
        ('archive_basalt_ceramic',(.085,.103,.117),.81,0),
        ('archive_graphite',(.048,.060,.073),.68,.22)]:
        mat = bpy.data.materials.new(mat_name)
        mat.use_nodes = True
        shader = next(n for n in mat.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
        shader.inputs['Base Color'].default_value = (*color,1)
        shader.inputs['Roughness'].default_value = rough
        shader.inputs['Metallic'].default_value = metal
        mat.diffuse_color = (*color,1)
        obj.data.materials.append(mat)
    for poly in obj.data.polygons:
        p = poly.center
        poly.material_index = int(p.z < .261 or (abs(p.x)<.121 and .309<p.z<.471 and p.y<-.179))
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    bmesh.ops.triangulate(bm, faces=list(bm.faces))
    bm.to_mesh(obj.data)
    bm.free()
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.smart_project(island_margin=.02)
    bpy.ops.object.mode_set(mode='OBJECT')
    bpy.ops.export_scene.gltf(filepath=str(out / (name+'.glb')), use_selection=True,
        use_active_scene=True, export_animations=False, export_cameras=False,
        export_lights=False, export_yup=True)
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    report = dict(issue=17 if narrow else 16, blender_version=bpy.app.version_string,
        triangles=len(obj.data.polygons), materials=len(obj.data.materials),
        non_manifold_edges=sum(not e.is_manifold for e in bm.edges),
        degenerate_faces=sum(f.calc_area()<1e-10 for f in bm.faces),
        signed_volume_m3=bm.calc_volume(signed=True), uv_layers=len(obj.data.uv_layers),
        dimensions_godot_m=[width+.1,4.75,.8], shaft_godot_m=[width,4.49,.6],
        pocket_godot_m=[.24,.16,.12], identity_transform=all(abs(v-1)<1e-8 for v in obj.scale),
        mcp='Both live connection checks failed; local Blender CLI fallback')
    bm.free()
    assert report['non_manifold_edges']==report['degenerate_faces']==0
    assert report['signed_volume_m3']>0 and report['uv_layers']==1
    (out/'validation.json').write_text(json.dumps(report,indent=2))
    world = bpy.data.worlds.new(name+'_Studio')
    world.use_nodes = True
    bg = next(n for n in world.node_tree.nodes if n.type=='BACKGROUND')
    bg.inputs[0].default_value = (.12,.14,.17,1)
    bg.inputs[1].default_value = .7
    scene.world=world
    camera = bpy.data.objects.new('ReviewCamera',bpy.data.cameras.new('ReviewCamera'))
    scene.collection.objects.link(camera)
    camera.data.type='ORTHO'
    camera.data.ortho_scale=5.8
    scene.camera=camera
    center=Vector((0,0,2.375))
    def aim(ob,pos,target=center):
        ob.location=Vector(pos)
        ob.rotation_euler=(target-ob.location).to_track_quat('-Z','Y').to_euler()
    for label,pos,power in [('Key',(3,-5,7),1700),('Fill',(-4,-1,4),1000),('Rim',(2,4,5),1600),('Under',(0,-3,-4),800)]:
        data=bpy.data.lights.new(label,'AREA')
        data.energy=power
        data.size=5
        lamp=bpy.data.objects.new(label,data)
        scene.collection.objects.link(lamp)
        aim(lamp,pos)
    scene.render.engine='CYCLES'
    scene.cycles.samples=24
    scene.render.resolution_x=600
    scene.render.resolution_y=800
    scene.render.resolution_percentage=100
    scene.render.image_settings.file_format='PNG'
    for label,pos in [('front',(5,-9,5)),('rear',(-5,9,5)),('underside',(5,-9,-3)),('top',(3,-5,10))]:
        aim(camera,pos)
        scene.render.filepath=str(out/('preview_'+label+'.png'))
        bpy.ops.render.render(write_still=True)
    aim(camera,(5,-9,5))
    bpy.data.libraries.write(str(out/'source'/(name+'.blend')),{scene},fake_user=True,compress=True)
    print(json.dumps(report))


if __name__=='__main__':
    build('--' in sys.argv and 'b' in sys.argv[sys.argv.index('--')+1:])
