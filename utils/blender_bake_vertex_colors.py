import bpy

# filmic is mid
bpy.context.scene.view_settings.view_transform = 'Standard'

def bake_all_meshes(self, context):
    # save choice of renderer
    renderer = bpy.context.scene.render.engine

    # setup settings for baking
    bpy.context.scene.render.engine = "CYCLES"
    bpy.context.scene.cycles.device = "GPU"
    bpy.context.scene.cycles.bake_type = "DIFFUSE"
    bpy.context.scene.render.bake.target = "VERTEX_COLORS"
    
    # create placeholder material for the actual lighting
    placeholder = bpy.data.materials.get("Placeholder")
    if placeholder is None:
        placeholder = bpy.data.materials.new(name="Placeholder")
    
    # setup backup material array
    materials = []
    i = 0

    # select every mesh and prepare for baking
    for obj in bpy.context.selected_objects:
        if obj.type != "MESH" or obj.hide_render:
            self.report({ "WARNING" }, "Please make sure you have only meshes selected and they do not have hide render on.")
            ret = True
            return
        bpy.ops.object.editmode_toggle()
        bpy.ops.mesh.select_all(action="SELECT")
        bpy.ops.paint.vertex_paint_toggle()
        bpy.data.brushes["Draw"].color = (1, 1, 1)
        bpy.data.brushes["Draw"].secondary_color = (1, 1, 1)
        bpy.ops.paint.vertex_color_set()
        bpy.ops.paint.vertex_paint_toggle()

        # override materials with special one to ensure the lighting bakes properly
        for slot in obj.material_slots:
            if slot.material is not None:
                materials.append(slot.material)
                slot.material = placeholder
                bpy.context.object.active_material.use_nodes = True

    # bake into vertex colors
    bpy.ops.object.bake()

    # reset materials
    for obj in bpy.context.selected_objects:
        for slot in obj.material_slots:
            if slot.material is not None:
                slot.material = materials[i]
                i += 1

    #reset render engine
    bpy.context.scene.render.engine = renderer

class SM64_BAKE_PT_BakePanel(bpy.types.Panel):
    bl_label = "SM64 Bake"
    bl_idname = "SM64_BAKE_PT_BakePanel"
    bl_space_type = "VIEW_3D"
    bl_region_type = "UI"
    bl_category = "SM64"
    
    def draw(self, context):
        self.layout.operator("wm.bake_button")
        
class SM64_BAKE_OT_BakePanelBakeOperator(bpy.types.Operator):
    bl_label = "Bake Lights Into Vertex Colors"
    bl_idname = "wm.bake_button"
    
    def execute(self, context):
        bake_all_meshes(self, context)
        return { "FINISHED" }

def register():
    bpy.utils.register_class(SM64_BAKE_PT_BakePanel)
    bpy.utils.register_class(SM64_BAKE_OT_BakePanelBakeOperator)
    
def unregister():
    bpy.utils.unregister_class(SM64_BAKE_PT_BakePanel)
    bpy.utils.unregister_class(SM64_BAKE_OT_BakePanelBakeOperator)
    
if __name__ == "__main__":
    register()