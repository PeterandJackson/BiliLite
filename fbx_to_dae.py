"""
Blender 命令行脚本：FBX → Collada (.dae) 转换
"""
import bpy
import sys
import os

fbx_path = sys.argv[-1]
output_dir = os.path.dirname(fbx_path)
basename = os.path.splitext(os.path.basename(fbx_path))[0]
dae_path = os.path.join(output_dir, basename + ".dae")

print(f"[ClothingAR] 输入: {fbx_path}")

# ── 清空 ──
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)

# ── 导入 FBX ──
bpy.ops.import_scene.fbx(filepath=fbx_path)
print(f"[ClothingAR] 物体数: {len(bpy.data.objects)}")

# 列出所有物体
for obj in bpy.data.objects:
    print(f"[ClothingAR]   物体: {obj.name} 类型: {obj.type}")
    if obj.type == 'MESH':
        print(f"[ClothingAR]     顶点: {len(obj.data.vertices)}")
        print(f"[ClothingAR]     三角面: {len(obj.data.polygons)}")
        for mod in obj.modifiers:
            print(f"[ClothingAR]     修改器: {mod.type}")

# ── 检查骨架 ──
armatures = [obj for obj in bpy.data.objects if obj.type == 'ARMATURE']
if armatures:
    print(f"[ClothingAR] 骨架: {len(armatures)} 个")
    for arm in armatures:
        print(f"[ClothingAR]   骨骼数: {len(arm.data.bones)}")
else:
    print("[ClothingAR] ⚠️ 无骨架！此模型没有骨骼绑定")

# ── 尝试各种 Collada 导出操作符名 ──
operators = [
    ("wm.collada_export", {}),
    ("export_scene.dae", {"filepath": dae_path}),
    ("export_scene.collada", {"filepath": dae_path}),
]

exported = False
for op_name, base_kwargs in operators:
    try:
        kwargs = {
            "filepath": dae_path,
            "check_existing": False,
            "export_global_forward_selection": 'Y',
            "apply_global_orientation": True,
            "selected": False,
            "include_armatures": True,
            "include_children": True,
            "include_shapekeys": True,
            "include_uv_textures": True,
            "include_material_textures": True,
            "triangulate": True,
        }
        kwargs.update(base_kwargs)
        getattr(bpy.ops, op_name.split(".")[0]).__getattr__(op_name.split(".")[1])(**kwargs)
        exported = True
        print(f"[ClothingAR] 导出成功 (操作符: {op_name})")
        break
    except Exception as e:
        print(f"[ClothingAR]   尝试 {op_name} 失败: {e}")

if not exported:
    # 启用 Collada 插件再试
    try:
        bpy.ops.preferences.addon_enable(module="io_scene_dae")
        bpy.ops.wm.collada_export(
            filepath=dae_path,
            check_existing=False,
            selected=False,
            include_armatures=True,
            include_children=True,
            include_shapekeys=True,
            triangulate=True,
        )
        exported = True
        print("[ClothingAR] 启用插件后导出成功")
    except Exception as e:
        print(f"[ClothingAR] 启用插件后仍失败: {e}")

if exported and os.path.exists(dae_path):
    size_mb = os.path.getsize(dae_path) / 1024 / 1024
    print(f"[ClothingAR] ✅ DAE 文件: {size_mb:.1f} MB")
else:
    print("[ClothingAR] ❌ 导出失败")

print("[ClothingAR] 完成")
