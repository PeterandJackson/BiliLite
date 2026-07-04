"""
Blender 脚本：Mixamo FBX → glTF (.glb) 导出
保留骨骼、蒙皮、贴图引用
"""
import bpy
import sys
import os

fbx_path = sys.argv[-1]
output_dir = os.path.dirname(fbx_path)
basename = os.path.splitext(os.path.basename(fbx_path))[0].replace(" ", "_")
glb_path = os.path.join(output_dir, basename + ".glb")

# 清空
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)

# 导入
bpy.ops.import_scene.fbx(filepath=fbx_path)
print(f"导入完成，物体: {len(bpy.data.objects)}")

# 导出 glTF
bpy.ops.export_scene.gltf(
    filepath=glb_path,
    check_existing=False,
    export_format='GLB',
    use_selection=False,
    export_apply=True,
    export_animations=False,
    export_skins=True,
    export_morph=False,
    export_texcoords=True,
    export_normals=True,
    export_materials='EXPORT',
    export_image_format='AUTO',
)

size_mb = os.path.getsize(glb_path) / 1024 / 1024
print(f"glB 导出完成: {glb_path} ({size_mb:.1f} MB)")
