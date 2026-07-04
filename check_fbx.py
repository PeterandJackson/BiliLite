"""
检查 Mixamo FBX 是否有骨骼
"""
import bpy
import sys

fbx_path = sys.argv[-1]

bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)

bpy.ops.import_scene.fbx(filepath=fbx_path)

print("=" * 60)
print("Mixamo FBX 分析:")
print(f"物体总数: {len(bpy.data.objects)}")
print()

# 骨架
armatures = [obj for obj in bpy.data.objects if obj.type == 'ARMATURE']
for arm in armatures:
    print(f"骨架: {arm.name}")
    print(f"骨骼数: {len(arm.data.bones)}")
    print(f"骨骼列表:")
    for bone in arm.data.bones:
        print(f"  - {bone.name}")

# 蒙皮
meshes = [obj for obj in bpy.data.objects if obj.type == 'MESH']
for mesh in meshes:
    print(f"网格: {mesh.name}")
    print(f"  顶点: {len(mesh.data.vertices)}")
    print(f"  三角面: {len(mesh.data.polygons)}")
    for mod in mesh.modifiers:
        if mod.type == 'ARMATURE':
            print(f"  绑定到骨架: {mod.object.name} (修改器: {mod.name})")

print("=" * 60)
