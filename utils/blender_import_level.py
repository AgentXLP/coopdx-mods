import bpy

from bpy.props import (StringProperty,
                       BoolProperty,
                       IntProperty,
                       FloatProperty,
                       FloatVectorProperty,
                       EnumProperty,
                       PointerProperty,
                       IntVectorProperty,
                       BoolVectorProperty
                       )
from bpy.types import (Panel,
                       Menu,
                       Operator,
                       PropertyGroup,
                       )
from array import array
import os
from struct import *
import sys
import math
from shutil import copy
from pathlib import Path
from types import ModuleType
from mathutils import Vector, Euler, Matrix, Quaternion
import re
from copy import deepcopy
from dataclasses import dataclass
#from SM64classes import *

bl_info = {
    "name": "SM64 Decomp C Level Importer",
    "description": "Import&Export levels for SM64 Decomp with Fast64",
    "author": "scuttlebug_raiser",
    "version": (1, 0, 0),
    "blender": (2, 83, 0),
    "location": "3D View > Tools",
    "warning": "", # used for warning icon and text in addons panel
    "wiki_url": "",
    "tracker_url": "",
    "category": "Import-Export"
}

Num2LevelName = {
    4:'bbh',
    5:"ccm",
    7:'hmc',
    8:'ssl',
    9:'bob',
    10:'sl',
    11:'wdw',
    12:'jrb',
    13:'thi',
    14:'ttc',
    15:'rr',
    16:"castle_grounds",
    17:'bitdw',
    18:'vcutm',
    19:'bitfs',
    20:'sa',
    21:'bits',
    22:'lll',
    23:'ddd',
    24:'wf',
    25:'ending',
    26:'castle_courtyard',
    27:'pss',
    28:'cotmc',
    29:'totwc',
    30:'bowser_1',
    31:'wmotr',
    33:'bowser_2',
    34:'bowser_3',
    36:'ttm'
}
#Levelname uses a different castle inside name which is dumb
Num2Name = {6:'castle_inside',**Num2LevelName}

class Area():
    def __init__(self, root, geo, levelRoot, num, scene, col):
        self.root = root
        self.geo = geo.strip()
        self.num = num
        self.scene = scene
        #Set level root as parent
        Parent(levelRoot, root)
        #set default vars
        root.sm64_obj_type = 'Area Root'
        root.areaIndex = num
        self.objects = []
        self.col = col
        #self.OjbColl = bpy.data.collections.new("%s Area %d Objects"%(scene.LevelImp.Level,num))
    def AddWarp(self,args):
        #set context to the root
        bpy.context.view_layer.objects.active = self.root
        #call fast64s warp node creation operator
        bpy.ops.bone.add_warp_node()
        warp=self.root.warpNodes[0]
        warp.warpID=args[0]
        warp.destNode=args[3]
        level=args[1].strip().replace("LEVEL_",'').lower()
        if level=='castle':
            level='castle_inside'
        if level.isdigit():
            level=Num2Name.get(eval(level))
            if not level:
                level='bob'
        warp.destLevelEnum=level
        warp.destArea=args[2]
        chkpoint=args[-1].strip()
        #Sorry for the hex users here
        if 'WARP_NO_CHECKPOINT' in chkpoint or int(chkpoint.isdigit()*chkpoint+'0')==0:
            warp.warpFlagEnum='WARP_NO_CHECKPOINT'
        else:
            warp.warpFlagEnum='WARP_CHECKPOINT'
    def AddObject(self,args):
        self.objects.append(args)
    def PlaceObjects(self, col = None):
        if not col:
            col = self.col
        else:
            col = CreateCol(self.root.users_collection[0], col)
        for a in self.objects:
            self.PlaceObject(a, col)
    def PlaceObject(self, args, col):
        #print(args)
        Obj = bpy.data.objects.new('Empty', None)
        col.objects.link(Obj)
        Parent(self.root, Obj)
        Obj.name = "Object {} {}".format(args[8].strip(),args[0].strip())
        Obj.sm64_obj_type= 'Object'
        Obj.sm64_behaviour_enum= 'Custom'
        Obj.sm64_obj_behaviour=args[8].strip()
        #bparam was changed in newer version of fast64
        if hasattr(Obj,"sm64_obj_bparam"):
            Obj.sm64_obj_bparam=args[7]
        else:
            Obj.fast64.sm64.game_object.bparams = args[7]
            Obj.fast64.sm64.game_object.use_individual_params = False
        Obj.sm64_obj_model=args[0]
        loc = [eval(a.strip())/self.scene.blenderToSM64Scale for a in args[1:4]]
        #rotate to fit sm64s axis
        loc = [loc[0],-loc[2],loc[1]]
        Obj.location = loc
        #fast64 just rotations by 90 on x
        rot = Euler( [math.radians(eval(a.strip())) for a in args[4:7]], "ZXY" )
        rot = Rot2Blend(rot)
        Obj.rotation_euler.rotate(rot)
        #set act mask
        mask = args[-1]
        if type(mask) == str and mask.isdigit():
            mask = eval(mask)
        form = 'sm64_obj_use_act{}'
        if mask == 31:
            for i in range(1,7,1):
                setattr(Obj,form.format(i),True)
        else:
            for i in range(1,7,1):
                if mask & (1 << (i - 1)):
                    setattr(Obj,form.format(i),True)
                else:
                    setattr(Obj,form.format(i),False)
    
class Level():
    def __init__(self, scr, scene, root):
        self.script=scr
        self.GetScripts()
        self.scene = scene
        self.Areas = {}
        self.CurrArea = None
        self.root = root
    def ParseScript(self, entry, col = None):
        Start = self.Scripts[entry]
        scale = self.scene.blenderToSM64Scale
        if not col:
            col = self.scene.collection
        for l in Start:
            args = self.StripArgs(l)
            LsW = l.startswith
            #Find an area
            if LsW("AREA"):
                Root = bpy.data.objects.new('Empty',None)
                if self.scene.LevelImp.UseCol:
                    a_col = bpy.data.collections.new(f"{self.scene.LevelImp.Level} area {args[0]}")
                    col.children.link(a_col)
                else:
                    a_col = col
                a_col.objects.link(Root)
                Root.name = "{} Area Root {}".format(self.scene.LevelImp.Level, args[0])
                self.Areas[args[0]] = Area(Root, args[1], self.root, int(args[0]), self.scene, a_col)
                self.CurrArea = args[0]
                continue
            #End an area
            if LsW("END_AREA"):
                self.CurrArea = None
                continue
            #Jumps are only taken if they're in the script.c file for now
            #continues script
            elif LsW("JUMP_LINK"):
                if self.Scripts.get(args[0]):
                    self.ParseScript(args[0], col = col)
                continue
            #ends script, I get arg -1 because sm74 has a different jump cmd
            elif LsW("JUMP"):
                Nentry = self.Scripts.get(args[-1])
                if Nentry:
                    self.ParseScript(args[-1], col = col)
                #for the sm74 port
                if len(args)!=2:
                    break
            #final exit of recursion
            elif LsW("EXIT") or l.startswith("RETURN"):
                return
            #Now deal with data cmds rather than flow control ones
            if LsW("WARP_NODE"):
                self.Areas[self.CurrArea].AddWarp(args)
                continue
            if LsW("OBJECT_WITH_ACTS"):
                #convert act mask from ORs of act names to a number
                mask = args[-1].strip()
                if not mask.isdigit():
                    mask = mask.replace("ACT_",'')
                    mask = mask.split('|')
                    #Attempt for safety I guess
                    try:
                        a=0
                        for m in mask:
                            a += 1 << int(m)
                        mask=a
                    except:
                        mask=31
                self.Areas[self.CurrArea].AddObject([*args[:-1],mask])
                continue
            if LsW("OBJECT"):
                #Only difference is act mask, which I set to 31 to mean all acts
                self.Areas[self.CurrArea].AddObject([*args,31])
                continue
            #Don't support these for now
            if LsW("MACRO_OBJECTS"):
                continue
            if LsW("TERRAIN_TYPE"):
                if not args[0].isdigit():
                    self.Areas[self.CurrArea].root.terrainEnum = args[0].strip()
                else:
                    terrains = {
                        0: "TERRAIN_GRASS",
                        1: "TERRAIN_STONE",
                        2: "TERRAIN_SNOW",
                        3: "TERRAIN_SAND",
                        4: "TERRAIN_SPOOKY",
                        5: "TERRAIN_WATER",
                        6: "TERRAIN_SLIDE",
                        7: "TERRAIN_MASK"
                    }
                    try:
                        num = eval(args[0])
                        self.Areas[self.CurrArea].root.terrainEnum = terrains.get(num)
                    except:
                        print("could not set terrain")
                continue
            if LsW("SHOW_DIALOG"):
                rt = self.Areas[self.CurrArea].root
                rt.showStartDialog = True
                rt.startDialog = args[1].strip()
                continue
            if LsW("TERRAIN"):
                self.Areas[self.CurrArea].terrain = args[0].strip()
                continue
            if LsW("SET_BACKGROUND_MUSIC") or LsW("SET_MENU_MUSIC"):
                rt=self.Areas[self.CurrArea].root
                rt.musicSeqEnum = 'Custom'
                rt.music_seq = args[-1].strip()
        return self.Areas
    def StripArgs(self,cmd):
        a = cmd.find("(")
        end = cmd.rfind(")")-len(cmd)
        return cmd[a+1:end].split(',')
    def GetScripts(self):
        #Get a dictionary made up with keys=level script names
        #and values as an array of all the cmds inside.
        self.Scripts={}
        InlineReg="/\*((?!\*/).)*\*/"
        currScr=0
        skip=0
        for l in self.script:
            comment=l.rfind("//")
            #double slash terminates line basically
            if comment:
                l=l[:comment]
            #check for macro
            if '#ifdef' in l:
                skip=EvalMacro(l)
            if '#elif' in l:
                skip=EvalMacro(l)
            if '#else' in l:
                skip=0
            #Now Check for level script starts
            if "LevelScript" in l and not skip:
                b=l.rfind('[]')
                a=l.find('LevelScript')
                var=l[a+11:b].strip()
                self.Scripts[var] = ""
                currScr=var
                continue
            if currScr and not skip:
                #remove inline comments from line
                while(True):
                    m=re.search(InlineReg,l)
                    if not m:
                        break
                    m=m.span()
                    l=l[:m[0]]+l[m[1]:]
                #Check for end of Level Script array
                if "};" in l:
                    currScr=0
                #Add line to dict
                else:
                    self.Scripts[currScr]+=l
        #Now remove newlines from each script, and then split macro ends
        #This makes each member of the array a single macro
        for k,v in self.Scripts.items():
            v=v.replace("\n",'')
            arr=[]
            x=0
            stack=0
            buf=""
            app=0
            while(x<len(v)):
                char=v[x]
                if char=="(":
                    stack+=1
                    app=1
                if char==")":
                    stack-=1
                if app==1 and stack==0:
                    app=0
                    buf+=v[x:x+2] #get the last parenthesis and comma
                    arr.append(buf.strip())
                    x+=2
                    buf=''
                    continue
                buf+=char
                x+=1
            self.Scripts[k]=arr
        return
        
class Collision():
    def __init__(self,col,scale):
        self.col=col
        self.scale=scale
        self.vertices=[]
        #key=type,value=tri data
        self.tris={}
        self.type=None
        self.SpecialObjs=[]
        self.Types=[]
        self.WaterBox=[]
    def GetCollision(self):
        for l in self.col:
            args=self.StripArgs(l)
            #to avoid catching COL_VERTEX_INIT
            if l.startswith('COL_VERTEX') and len(args)==3:
                self.vertices.append([eval(v)/self.scale for v in args])
                continue
            if l.startswith('COL_TRI_INIT'):
                self.type=args[0]
                if not self.tris.get(self.type):
                    self.tris[self.type]=[]
                continue
            if l.startswith('COL_TRI') and len(args)>2:
                a=[eval(a) for a in args]
                self.tris[self.type].append(a)
                continue
            if l.startswith('COL_WATER_BOX_INIT'):
                continue
            if l.startswith('COL_WATER_BOX'):
                #id, x1, z1, x2, z2, y
                self.WaterBox.append(args)
            if l.startswith('SPECIAL_OBJECT'):
                self.SpecialObjs.append(args)
        #This will keep track of how to assign mats
        a=0
        for k,v in self.tris.items():
            self.Types.append([a,k,v[0]])
            a+=len(v)
        self.Types.append([a,0])
    def StripArgs(self,cmd):
        a=cmd.find("(")
        return cmd[a+1:-2].split(',')
    def WriteWaterBoxes(self, scene, parent, name,col):
        for i,w in enumerate(self.WaterBox):
            Obj = bpy.data.objects.new('Empty',None)
            scene.collection.objects.link(Obj)
            Parent(parent, Obj)
            Obj.name = "WaterBox_{}_{}".format(name,i)
            Obj.sm64_obj_type= 'Water Box'
            x1 = eval(w[1])/(self.scale)
            x2 = eval(w[3])/(self.scale)
            z1 = eval(w[2])/(self.scale)
            z2 = eval(w[4])/(self.scale)
            y = eval(w[5])/(self.scale)
            Xwidth = abs(x2-x1)/(2)
            Zwidth = abs(z2-z1)/(2)
            loc=[x2-Xwidth,-(z2-Zwidth),y-1]
            Obj.location=loc
            scale = [Xwidth,Zwidth,1]
            Obj.scale = scale
    def WriteCollision(self, scene, name, parent, col = None):
        if not col:
            col = scene.collection
        self.WriteWaterBoxes(scene, parent, name, col)
        mesh = bpy.data.meshes.new(name+' data')
        tris=[]
        for t in self.tris.values():
            #deal with special tris
            if len(t[0])>3:
                t = [a[0:3] for a in t]
            tris.extend(t)
        mesh.from_pydata(self.vertices, [], tris)
        
        obj = bpy.data.objects.new(name+' Mesh',mesh)
        col.objects.link(obj)
        obj.ignore_render = True
        if parent:
            Parent(parent, obj)
        RotateObj(-90, obj, world = 1)
        polys = obj.data.polygons
        x = 0
        bpy.context.view_layer.objects.active = obj
        max = len(polys)
        for i,p in enumerate(polys):
            a = self.Types[x][0]
            if i >= a:
                bpy.ops.object.create_f3d_mat() #the newest mat should be in slot[-1]
                mat = obj.data.materials[x]
                mat.collision_type_simple = 'Custom'
                mat.collision_custom = self.Types[x][1]
                mat.name = "Sm64_Col_Mat_{}".format(self.Types[x][1])
                color = ((max-a)/(max),(max+a)/(2*max-a),a/max,1) #Just to give some variety
                mat.f3d_mat.default_light_color = color
                #check for param
                if len(self.Types[x][2])>3:
                    mat.use_collision_param = True
                    mat.collision_param = str(self.Types[x][2][3])
                x+=1
                override = bpy.context.copy()
                override["material"] = mat
                bpy.ops.material.update_f3d_nodes(override)
            p.material_index=x-1
        return obj

#this will hold tile properties
class Tile():
    def __init__(self):
        self.Fmt = "RGBA"
        self.Siz = "16"
        self.Slow = 32
        self.Tlow = 32
        self.Shigh = 32
        self.Thigh = 32
        self.SMask = 5
        self.TMask = 5
        self.SShift = 0
        self.TShift = 0
        self.Sflags = None
        self.Tflags = None

# this will hold texture properties, dataclass props
# are created in order for me to make comparisons in a set
@dataclass(init=True, eq=True, unsafe_hash=True)
class Texture:
    Timg: tuple
    Fmt: str
    Siz: int
    Width: int = 0
    Height: int = 0
    Pal: tuple = None

    def size(self):
        return self.Width, self.Height

#This is simply a data storage class
class Mat():
    def __init__(self):
        self.TwoCycle = False
        self.GeoSet = []
        self.GeoClear = []
        self.tiles = [Tile() for a in range(8)]
        self.tex0 = None
        self.tex1 = None
    #calc the hash for an f3d mat and see if its equal to this mats hash
    def MatHashF3d(self,f3d,textures):
        #texture,1 cycle combiner, geo modes (once I implement them)
        rdp = f3d.rdp_settings
        if f3d.tex0.tex:
            T = f3d.tex0.tex.name
        else:
            T = ''
        F3Dprops = (T,f3d.combiner1.A,f3d.combiner1.B,f3d.combiner1.C,f3d.combiner1.D,
        f3d.combiner1.A_alpha,f3d.combiner1.B_alpha,f3d.combiner1.C_alpha,f3d.combiner1.D_alpha)
        if hasattr(self,'Combiner'):
            MyT = ''
            if hasattr(self,'Timg'):
                MyT = textures.get(self.Timg)[0].split('/')[-1]
                MyT=MyT.replace("#include ",'').replace('"','').replace("'",'').replace("inc.c","png")
            else:
                pass
            MyProps = (MyT,*self.Combiner[0:8])
            dupe = hash(MyProps) == hash(F3Dprops)
            return dupe
        return False
    def MatHash(self,mat,textures):
        return False
    def LoadTexture(self, ForceNewTex, textures, path, tex):
        Timg = textures.get(tex.Timg)[0].split('/')[-1]
        Timg = Timg.replace("#include ",'').replace('"','').replace("'",'').replace("inc.c","png")
        i = bpy.data.images.get(Timg)
        if not i or ForceNewTex:
            Timg = textures.get(tex.Timg)[0]
            Timg = Timg.replace("#include ",'').replace('"','').replace("'",'').replace("inc.c","png")
            #deal with duplicate pathing (such as /actors/actors etc.)
            Extra = path.relative_to(Path(bpy.context.scene.decompPath))
            for e in Extra.parts:
                Timg = Timg.replace(e+'/','')
            #deal with actor import path not working for shared textures
            if 'textures' in Timg:
                fp = Path(bpy.context.scene.decompPath) / Timg
            else:
                fp = path / Timg
            return bpy.data.images.load(filepath=str(fp))
        else:
            return i
    def ApplyPBSDFMat(self,mat,textures,path,layer):
        nt = mat.node_tree
        nodes = nt.nodes
        links = nt.links
        pbsdf = nodes.get('Principled BSDF')
        tex = nodes.new("ShaderNodeTexImage")
        links.new(pbsdf.inputs[0],tex.outputs[0])
        links.new(pbsdf.inputs[19],tex.outputs[1])
        i = self.LoadTexture(bpy.context.scene.LevelImp.ForceNewTex,textures,path)
        if i:
            tex.image = i
        if layer>4:
            mat.blend_method == 'BLEND'
    def ApplyMatSettings(self,mat,textures,path,layer):
        if bpy.context.scene.LevelImp.AsObj:
            return self.ApplyPBSDFMat(mat,textures,path,layer)
        #make combiner custom
        f3d=mat.f3d_mat #This is kure's custom property class for materials
        f3d.presetName="Custom"
        self.SetCombiner(f3d,layer)
        f3d.draw_layer.sm64 = layer
        if int(layer)>4:
            mat.blend_method == 'BLEND'
        #I set these but they aren't properly stored because they're reset by fast64 or something
        #its better to have defaults than random 2 cycles
        self.SetGeoMode(f3d.rdp_settings,mat)
        if self.TwoCycle:
            f3d.rdp_settings.gdsft_cycletype = 'G_CYC_2CYCLE'
        else:
            f3d.rdp_settings.gdsft_cycletype = 'G_CYC_1CYCLE'
        #Try to set an image
        #texture 0 then texture 1
        if self.tex0:
            i = self.LoadTexture(bpy.context.scene.LevelImp.ForceNewTex,textures,path, self.tex0)
            tex0 = f3d.tex0
            tex0.tex_set = True
            tex0.tex = i
            tex0.tex_format = self.EvalFmt(self.tiles[0])
            tex0.autoprop = False
            Sflags = self.EvalFlags(self.tiles[0].Sflags)
            for f in Sflags:
                setattr(tex0.S,f,True)
            Tflags = self.EvalFlags(self.tiles[0].Tflags)
            for f in Sflags:
                setattr(tex0.T,f,True)
            tex0.S.low = self.tiles[0].Slow
            tex0.T.low = self.tiles[0].Tlow
            tex0.S.high = self.tiles[0].Shigh
            tex0.T.high = self.tiles[0].Thigh
            
            tex0.S.mask = self.tiles[0].SMask
            tex0.T.mask = self.tiles[0].TMask
        if self.tex1:
            i = self.LoadTexture(bpy.context.scene.LevelImp.ForceNewTex,textures,path, self.tex1)
            tex1 = f3d.tex1
            tex1.tex_set = True
            tex1.tex = i
            tex1.tex_format = self.EvalFmt(self.tiles[1])
            Sflags = self.EvalFlags(self.tiles[1].Sflags)
            for f in Sflags:
                setattr(tex1.S,f,True)
            Tflags = self.EvalFlags(self.tiles[1].Tflags)
            for f in Sflags:
                setattr(tex1.T,f,True)
            tex1.S.low = self.tiles[1].Slow
            tex1.T.low = self.tiles[1].Tlow
            tex1.S.high = self.tiles[1].Shigh
            tex1.T.high = self.tiles[1].Thigh
            
            tex1.S.mask = self.tiles[0].SMask
            tex1.T.mask = self.tiles[0].TMask
        #Update node values
        override = bpy.context.copy()
        override["material"] = mat
        bpy.ops.material.update_f3d_nodes(override)
    def EvalFlags(self, flags):
        if not flags:
            return []
        GBIflags = {
            "G_TX_NOMIRROR": None,
            "G_TX_WRAP": None,
            "G_TX_MIRROR": ("mirror"),
            "G_TX_CLAMP": ("clamp"),
            "0": None,
            "1": ("mirror"),
            "2": ("clamp"),
            "3": ("clamp", "mirror"),
        }
        x = []
        fsplit = flags.split("|")
        for f in fsplit:
            z = GBIflags.get(f.strip(), 0)
            if z:
                x.append(z)
        return x
    def SetGeoMode(self,rdp,mat):
        for a in self.GeoSet:
            try:
                setattr(self,a.lower(),True)
            except:
                print(a.lower(),'set')
        for a in self.GeoClear:
            try:
                setattr(self,a.lower(),False)
            except:
                print(a.lower(),'clear')
    #Very lazy for now
    def SetCombiner(self,f3d,layer):
        if not hasattr(self,'Combiner'):
            layer=eval(layer)
            if layer<=4:
                f3d.combiner1.A = 'TEXEL0'
                f3d.combiner1.A_alpha = '0'
                f3d.combiner1.C = 'SHADE'
                f3d.combiner1.C_alpha = '0'
                f3d.combiner1.D = '0'
                f3d.combiner1.D_alpha = '1'
            if layer==4:
                f3d.combiner1.A = 'TEXEL0'
                f3d.combiner1.A_alpha = 'TEXEL0'
                f3d.combiner1.C = 'SHADE'
                f3d.combiner1.C_alpha = 'SHADE'
                f3d.combiner1.D = '0'
                f3d.combiner1.D_alpha = '0'
            if layer==5:
                f3d.combiner1.A = 'TEXEL0'
                f3d.combiner1.A_alpha = 'TEXEL0'
                f3d.combiner1.C = 'SHADE'
                f3d.combiner1.C_alpha = 'PRIMITIVE'
                f3d.combiner1.D = '0'
                f3d.combiner1.D_alpha = '0'
            if layer>=6:
                f3d.combiner1.A = 'TEXEL0'
                f3d.combiner1.B = 'SHADE'
                f3d.combiner1.A_alpha = '0'
                f3d.combiner1.C = 'TEXEL0_ALPHA'
                f3d.combiner1.C_alpha = '0'
                f3d.combiner1.D = 'SHADE'
                f3d.combiner1.D_alpha = 'ENVIRONMENT'
        else:
            f3d.combiner1.A = self.Combiner[0]
            f3d.combiner1.B = self.Combiner[1]
            f3d.combiner1.C = self.Combiner[2]
            f3d.combiner1.D = self.Combiner[3]
            f3d.combiner1.A_alpha = self.Combiner[4]
            f3d.combiner1.B_alpha = self.Combiner[5]
            f3d.combiner1.C_alpha = self.Combiner[6]
            f3d.combiner1.D_alpha = self.Combiner[7]
            f3d.combiner2.A = self.Combiner[8]
            f3d.combiner2.B = self.Combiner[9]
            f3d.combiner2.C = self.Combiner[10]
            f3d.combiner2.D = self.Combiner[11]
            f3d.combiner2.A_alpha = self.Combiner[12]
            f3d.combiner2.B_alpha = self.Combiner[13]
            f3d.combiner2.C_alpha = self.Combiner[14]
            f3d.combiner2.D_alpha = self.Combiner[15]
    def EvalFmt(self, tex):
        GBIfmts = {
        "G_IM_FMT_RGBA":"RGBA",
        "G_IM_FMT_CI":"CI",
        "G_IM_FMT_IA":"IA",
        "G_IM_FMT_I":"I",
        "0":"RGBA",
        "2":"CI",
        "3":"IA",
        "4":"I"
        }
        GBIsiz = {
        "G_IM_SIZ_4b":"4",
        "G_IM_SIZ_8b":"8",
        "G_IM_SIZ_16b":"16",
        "G_IM_SIZ_32b":"32",
        "0":"4",
        "1":"8",
        "2":"16",
        "3":"32"
        }
        return GBIfmts.get(tex.Fmt,"RGBA")+GBIsiz.get(tex.Siz,"16")

class F3d():
    def __init__(self,scene):
        self.VB={}
        self.Gfx={}
        self.diff={}
        self.amb={}
        self.Lights={}
        self.Textures={}
        self.scene=scene
    #Textures only contains the texture data found inside the model.inc.c file and the texture.inc.c file
    def GetGenericTextures(self,path):
        for t in ['cave.c','effect.c','fire.c','generic.c','grass.c','inside.c','machine.c','mountain.c','outside.c','sky.c','snow.c','spooky.c','water.c']:
            t = path/'bin'/t
            t=open(t,'r')
            tex=t.readlines()
            #For textures, try u8, and s16 aswell
            self.Textures.update(FormatDat(tex,'Texture',[None,None]))
            self.Textures.update(FormatDat(tex,'u8',[None,None]))
            self.Textures.update(FormatDat(tex,'s16',[None,None]))
            t.close()
    #recursively parse the display list in order to return a bunch of model data
    def GetDataFromModel(self,start):
        DL = self.Gfx.get(start)
        self.VertBuff = [0]*32 #If you're doing some fucky shit with a larger vert buffer it sucks to suck I guess
        if not DL:
            raise Exception("Could not find DL {}".format(start))
        self.Verts = []
        self.Tris = []
        self.UVs = []
        self.VCs = []
        self.Mats = []
        self.LastMat = Mat()
        self.ParseDL(DL)
        self.NewMat = 0
        self.StartName=start
        return [self.Verts,self.Tris]
    def ParseDL(self,DL):
        #This will be the equivalent of a giant switch case
        x=-1
        while(x<len(DL)):
            #manaual iteration so I can skip certain children efficiently
            x+=1
            l=DL[x]
            LsW=l.startswith
            args=self.StripArgs(l)
            #Deal with control flow first
            if LsW('gsSPEndDisplayList'):
                return
            if LsW('gsSPBranchList'):
                NewDL=self.Gfx.get(args[0].strip())
                if not DL:
                    raise Exception("Could not find DL {} in levels/{}/{}leveldata.inc.c".format(NewDL,self.scene.LevelImp.Level,self.scene.LevelImp.Prefix))
                self.ParseDL(NewDL)
                break
            if LsW('gsSPDisplayList'):
                NewDL=self.Gfx.get(args[0].strip())
                if not DL:
                    raise Exception("Could not find DL {} in levels/{}/{}leveldata.inc.c".format(NewDL,self.scene.LevelImp.Level,self.scene.LevelImp.Prefix))
                self.ParseDL(NewDL)
                continue
            #Vertices
            if LsW('gsSPVertex'):
                #vertex references commonly use pointer arithmatic. I will deal with that case here, but not for other things unless it somehow becomes a problem later
                if '+' in args[0]:
                    ref, add = args[0].split('+')
                else:
                    ref = args[0]
                    add = '0'
                VB = self.VB.get(ref.strip())
                if not VB:
                    raise Exception("Could not find VB {} in levels/{}/{}leveldata.inc.c".format(ref,self.scene.LevelImp.Level,self.scene.LevelImp.Prefix))
                Verts = VB[int(add.strip()):int(add.strip())+eval(args[1])] #If you use array indexing here then you deserve to have this not work
                Verts = [self.ParseVert(v) for v in Verts]
                for k,i in enumerate(range(eval(args[2]),eval(args[1]),1)):
                    self.VertBuff[i] = [Verts[k],eval(args[2])]
                #These are all independent data blocks in blender
                self.Verts.extend([v[0] for v in Verts])
                self.UVs.extend([v[1] for v in Verts])
                self.VCs.extend([v[2] for v in Verts])
                self.LastLoad = eval(args[1])
                continue
            #Triangles
            if LsW('gsSP2Triangles'):
                self.MakeNewMat()
                Tri1 = self.ParseTri(args[:3])
                Tri2 = self.ParseTri(args[4:7])
                self.Tris.append(Tri1)
                self.Tris.append(Tri2)
                continue
            if LsW('gsSP1Triangle'):
                self.MakeNewMat()
                Tri = self.ParseTri(args[:3])
                self.Tris.append(Tri)
                continue
            #materials
            #Mats will be placed sequentially. The first item of the list is the triangle number
            #The second is the material class
            if LsW('gsSPClearGeometryMode'):
                self.NewMat = 1
                self.LastMat.GeoClear.append(args[0].strip())
                continue
            if LsW('gsSPSetGeometryMode'):
                self.NewMat = 1
                self.LastMat.GeoSet.append(args[0].strip())
                continue
            if LsW('gsSPGeometryMode'):
                self.NewMat = 1
                self.LastMat.GeoClear.append(args[0].strip())
                self.LastMat.GeoSet.append(args[1].strip())
                continue
            if LsW('gsDPSetCycleType'):
                self.LastMat.TwoCycle=True
                continue
            if LsW('gsDPSetCombineMode'):
                self.NewMat = 1
                self.LastMat.Combiner = self.EvalCombiner(args)
                continue
            if LsW('gsDPSetCombineLERP'):
                self.NewMat = 1
                self.LastMat.Combiner = [a.strip() for a in args]
                continue
            #tells us what tile the last loaded mat goes into
            if LsW('gsDPLoadBlock'):
                try:
                    tex = self.LastMat.loadtex
                    tile = self.EvalTile(args[0].strip())
                    tex.tile = tile
                    if tile == 7:
                        self.LastMat.tex0 = tex
                    elif tile == 6:
                        self.LastMat.tex1 = tex
                    #if loaded in block 5, it is a palette
                    #there shouldn't be a reason to not use these tiles
                    #other than something that probably won't work
                    #here anyway
                except:
                    print("load block before set texture image. DL error??")
                continue
            if LsW('gsDPSetTextureImage'):
                self.NewMat = 1
                Timg = args[3].strip()
                Fmt = args[1].strip()
                Siz = args[2].strip()
                loadtex = Texture(Timg, Fmt, Siz)
                self.LastMat.loadtex = loadtex
                continue
            #catch tile size
            if LsW('gsDPSetTileSize'):
                tile = self.LastMat.tiles[self.EvalTile(args[0])]
                tile.Slow = self.EvalImFrac(args[1].strip())
                tile.Tlow = self.EvalImFrac(args[2].strip())
                tile.Shigh = self.EvalImFrac(args[3].strip())
                tile.Thigh = self.EvalImFrac(args[4].strip())
                continue
            if LsW('gsDPSetTile'):
                self.NewMat = 1
                tile = self.LastMat.tiles[self.EvalTile(args[4].strip())]
                tile.Fmt = args[0].strip()
                tile.Siz = args[1].strip()
                tile.Tflags = args[6].strip()
                tile.TMask = self.EvalTile(args[7].strip())
                tile.TShift = self.EvalTile(args[8].strip())
                tile.Sflags = args[9].strip()
                tile.SMask = self.EvalTile(args[10].strip())
                tile.SShift = self.EvalTile(args[11].strip())
    def EvalCombiner(self,arg):
        #two args
        GBI_CC_Macros = {
            'G_CC_PRIMITIVE': ['0', '0', '0', 'PRIMITIVE', '0', '0', '0', 'PRIMITIVE'],
            'G_CC_SHADE': ['0', '0', '0', 'SHADE', '0', '0', '0', 'SHADE'],
            'G_CC_MODULATEI': ['TEXEL0', '0', 'SHADE', '0', '0', '0', '0', 'SHADE'],
            'G_CC_MODULATEIDECALA': ['TEXEL0', '0', 'SHADE', '0', '0', '0', '0', 'TEXEL0'],
            'G_CC_MODULATEIFADE': ['TEXEL0', '0', 'SHADE', '0', '0', '0', '0', 'ENVIRONMENT'],
            'G_CC_MODULATERGB': ['TEXEL0', '0', 'SHADE', '0', '0', '0', '0', 'SHADE'],
            'G_CC_MODULATERGBDECALA': ['TEXEL0', '0', 'SHADE', '0', '0', '0', '0', 'TEXEL0'],
            'G_CC_MODULATERGBFADE': ['TEXEL0', '0', 'SHADE', '0', '0', '0', '0', 'ENVIRONMENT'],
            'G_CC_MODULATEIA': ['TEXEL0', '0', 'SHADE', '0', 'TEXEL0', '0', 'SHADE', '0'],
            'G_CC_MODULATEIFADEA': ['TEXEL0', '0', 'SHADE', '0', 'TEXEL0', '0', 'ENVIRONMENT', '0'],
            'G_CC_MODULATEFADE': ['TEXEL0', '0', 'SHADE', '0', 'ENVIRONMENT', '0', 'TEXEL0', '0'],
            'G_CC_MODULATERGBA': ['TEXEL0', '0', 'SHADE', '0', 'TEXEL0', '0', 'SHADE', '0'],
            'G_CC_MODULATERGBFADEA': ['TEXEL0', '0', 'SHADE', '0', 'ENVIRONMENT', '0', 'TEXEL0', '0'],
            'G_CC_MODULATEI_PRIM': ['TEXEL0', '0', 'PRIMITIVE', '0', '0', '0', '0', 'PRIMITIVE'],
            'G_CC_MODULATEIA_PRIM': ['TEXEL0', '0', 'PRIMITIVE', '0', 'TEXEL0', '0', 'PRIMITIVE', '0'],
            'G_CC_MODULATEIDECALA_PRIM': ['TEXEL0', '0', 'PRIMITIVE', '0', '0', '0', '0', 'TEXEL0'],
            'G_CC_MODULATERGB_PRIM': ['TEXEL0', '0', 'PRIMITIVE', '0', 'TEXEL0', '0', 'PRIMITIVE', '0'],
            'G_CC_MODULATERGBA_PRIM': ['TEXEL0', '0', 'PRIMITIVE', '0', 'TEXEL0', '0', 'PRIMITIVE', '0'],
            'G_CC_MODULATERGBDECALA_PRIM': ['TEXEL0', '0', 'PRIMITIVE', '0', '0', '0', '0', 'TEXEL0'],
            'G_CC_FADE': ['SHADE', '0', 'ENVIRONMENT', '0', 'SHADE', '0', 'ENVIRONMENT', '0'],
            'G_CC_FADEA': ['TEXEL0', '0', 'ENVIRONMENT', '0', 'TEXEL0', '0', 'ENVIRONMENT', '0'],
            'G_CC_DECALRGB': ['0', '0', '0', 'TEXEL0', '0', '0', '0', 'SHADE'],
            'G_CC_DECALRGBA': ['0', '0', '0', 'TEXEL0', '0', '0', '0', 'TEXEL0'],
            'G_CC_DECALFADE': ['0', '0', '0', 'TEXEL0', '0', '0', '0', 'ENVIRONMENT'],
            'G_CC_DECALFADEA': ['0', '0', '0', 'TEXEL0', 'TEXEL0', '0', 'ENVIRONMENT', '0'],
            'G_CC_BLENDI': ['ENVIRONMENT', 'SHADE', 'TEXEL0', 'SHADE', '0', '0', '0', 'SHADE'],
            'G_CC_BLENDIA': ['ENVIRONMENT', 'SHADE', 'TEXEL0', 'SHADE', 'TEXEL0', '0', 'SHADE', '0'],
            'G_CC_BLENDIDECALA': ['ENVIRONMENT', 'SHADE', 'TEXEL0', 'SHADE', '0', '0', '0', 'TEXEL0'],
            'G_CC_BLENDRGBA': ['TEXEL0', 'SHADE', 'TEXEL0_ALPHA', 'SHADE', '0', '0', '0', 'SHADE'],
            'G_CC_BLENDRGBDECALA': ['TEXEL0', 'SHADE', 'TEXEL0_ALPHA', 'SHADE', '0', '0', '0', 'TEXEL0'],
            'G_CC_BLENDRGBFADEA': ['TEXEL0', 'SHADE', 'TEXEL0_ALPHA', 'SHADE', '0', '0', '0', 'ENVIRONMENT'],
            'G_CC_ADDRGB': ['TEXEL0', '0', 'TEXEL0', 'SHADE', '0', '0', '0', 'SHADE'],
            'G_CC_ADDRGBDECALA': ['TEXEL0', '0', 'TEXEL0', 'SHADE', '0', '0', '0', 'TEXEL0'],
            'G_CC_ADDRGBFADE': ['TEXEL0', '0', 'TEXEL0', 'SHADE', '0', '0', '0', 'ENVIRONMENT'],
            'G_CC_REFLECTRGB': ['ENVIRONMENT', '0', 'TEXEL0', 'SHADE', '0', '0', '0', 'SHADE'],
            'G_CC_REFLECTRGBDECALA': ['ENVIRONMENT', '0', 'TEXEL0', 'SHADE', '0', '0', '0', 'TEXEL0'],
            'G_CC_HILITERGB': ['PRIMITIVE', 'SHADE', 'TEXEL0', 'SHADE', '0', '0', '0', 'SHADE'],
            'G_CC_HILITERGBA': ['PRIMITIVE', 'SHADE', 'TEXEL0', 'SHADE', 'PRIMITIVE', 'SHADE', 'TEXEL0', 'SHADE'],
            'G_CC_HILITERGBDECALA': ['PRIMITIVE', 'SHADE', 'TEXEL0', 'SHADE', '0', '0', '0', 'TEXEL0'],
            'G_CC_SHADEDECALA': ['0', '0', '0', 'SHADE', '0', '0', '0', 'TEXEL0'],
            'G_CC_SHADEFADEA': ['0', '0', '0', 'SHADE', '0', '0', '0', 'ENVIRONMENT'],
            'G_CC_BLENDPE': ['PRIMITIVE', 'ENVIRONMENT', 'TEXEL0', 'ENVIRONMENT', 'TEXEL0', '0', 'SHADE', '0'],
            'G_CC_BLENDPEDECALA': ['PRIMITIVE', 'ENVIRONMENT', 'TEXEL0', 'ENVIRONMENT', '0', '0', '0', 'TEXEL0'],
            '_G_CC_BLENDPE': ['ENVIRONMENT', 'PRIMITIVE', 'TEXEL0', 'PRIMITIVE', 'TEXEL0', '0', 'SHADE', '0'],
            '_G_CC_BLENDPEDECALA': ['ENVIRONMENT', 'PRIMITIVE', 'TEXEL0', 'PRIMITIVE', '0', '0', '0', 'TEXEL0'],
            '_G_CC_TWOCOLORTEX': ['PRIMITIVE', 'SHADE', 'TEXEL0', 'SHADE', '0', '0', '0', 'SHADE'],
            '_G_CC_SPARSEST': ['PRIMITIVE', 'TEXEL0', 'LOD_FRACTION', 'TEXEL0', 'PRIMITIVE', 'TEXEL0', 'LOD_FRACTION', 'TEXEL0'],
            'G_CC_TEMPLERP': ['TEXEL1', 'TEXEL0', 'PRIM_LOD_FRAC', 'TEXEL0', 'TEXEL1', 'TEXEL0', 'PRIM_LOD_FRAC', 'TEXEL0'],
            'G_CC_TRILERP': ['TEXEL1', 'TEXEL0', 'LOD_FRACTION', 'TEXEL0', 'TEXEL1', 'TEXEL0', 'LOD_FRACTION', 'TEXEL0'],
            'G_CC_INTERFERENCE': ['TEXEL0', '0', 'TEXEL1', '0', 'TEXEL0', '0', 'TEXEL1', '0'],
            'G_CC_1CYUV2RGB': ['TEXEL0', 'K4', 'K5', 'TEXEL0', '0', '0', '0', 'SHADE'],
            'G_CC_YUV2RGB': ['TEXEL1', 'K4', 'K5', 'TEXEL1', '0', '0', '0', '0'],
            'G_CC_PASS2': ['0', '0', '0', 'COMBINED', '0', '0', '0', 'COMBINED'],
            'G_CC_MODULATEI2': ['COMBINED', '0', 'SHADE', '0', '0', '0', '0', 'SHADE'],
            'G_CC_MODULATEIA2': ['COMBINED', '0', 'SHADE', '0', 'COMBINED', '0', 'SHADE', '0'],
            'G_CC_MODULATERGB2': ['COMBINED', '0', 'SHADE', '0', '0', '0', '0', 'SHADE'],
            'G_CC_MODULATERGBA2': ['COMBINED', '0', 'SHADE', '0', 'COMBINED', '0', 'SHADE', '0'],
            'G_CC_MODULATEI_PRIM2': ['COMBINED', '0', 'PRIMITIVE', '0', '0', '0', '0', 'PRIMITIVE'],
            'G_CC_MODULATEIA_PRIM2': ['COMBINED', '0', 'PRIMITIVE', '0', 'COMBINED', '0', 'PRIMITIVE', '0'],
            'G_CC_MODULATERGB_PRIM2': ['COMBINED', '0', 'PRIMITIVE', '0', '0', '0', '0', 'PRIMITIVE'],
            'G_CC_MODULATERGBA_PRIM2': ['COMBINED', '0', 'PRIMITIVE', '0', 'COMBINED', '0', 'PRIMITIVE', '0'],
            'G_CC_DECALRGB2': ['0', '0', '0', 'COMBINED', '0', '0', '0', 'SHADE'],
            'G_CC_BLENDI2': ['ENVIRONMENT', 'SHADE', 'COMBINED', 'SHADE', '0', '0', '0', 'SHADE'],
            'G_CC_BLENDIA2': ['ENVIRONMENT', 'SHADE', 'COMBINED', 'SHADE', 'COMBINED', '0', 'SHADE', '0'],
            'G_CC_CHROMA_KEY2': ['TEXEL0', 'CENTER', 'SCALE', '0', '0', '0', '0', '0'],
            'G_CC_HILITERGB2': ['ENVIRONMENT', 'COMBINED', 'TEXEL0', 'COMBINED', '0', '0', '0', 'SHADE'],
            'G_CC_HILITERGBA2': ['ENVIRONMENT', 'COMBINED', 'TEXEL0', 'COMBINED', 'ENVIRONMENT', 'COMBINED', 'TEXEL0', 'COMBINED'],
            'G_CC_HILITERGBDECALA2': ['ENVIRONMENT', 'COMBINED', 'TEXEL0', 'COMBINED', '0', '0', '0', 'TEXEL0'],
            'G_CC_HILITERGBPASSA2': ['ENVIRONMENT', 'COMBINED', 'TEXEL0', 'COMBINED', '0', '0', '0', 'COMBINED'],
        }
        return GBI_CC_Macros.get(arg[0].strip(), ['TEXEL0', '0', 'SHADE', '0', 'TEXEL0', '0', 'SHADE', '0']) + \
            GBI_CC_Macros.get(arg[1].strip(), ['TEXEL0', '0', 'SHADE', '0', 'TEXEL0', '0', 'SHADE', '0'])
    def EvalImFrac(self, arg):
        if type(arg) == int:
            return arg
        arg2 = arg.replace("G_TEXTURE_IMAGE_FRAC", "2")
        return eval(arg2)
    def EvalTile(self, arg):
        #are ther more enums??
        Tiles = {
            "G_TX_LOADTILE": 7,
            "G_TX_RENDERTILE": 0,
            "G_TX_NOMASK": 0,
            "G_TX_NOLOD": 0,
        }
        t = Tiles.get(arg)
        if t == None:
            arg = arg.replace("G_TX_RENDERTILE", "0")
            print(arg, type(arg))
            t = eval(arg)
        return t
    def MakeNewMat(self):
        if self.NewMat:
            self.NewMat = 0
            self.Mats.append([len(self.Tris)-1, self.LastMat])
            self.LastMat = deepcopy(self.LastMat) #for safety
    def ParseVert(self,Vert):
        v = Vert.replace('{','').replace('}','').split(',')
        num = (lambda x: [eval(a) for a in x])
        pos = num(v[:3])
        uv = num(v[4:6])
        vc = num(v[6:10])
        return [pos,uv,vc]
    def ParseTri(self,Tri):
        L=len(self.Verts)
        return [eval(a)+L-self.LastLoad for a in Tri]
    def StripArgs(self,cmd):
        a=cmd.find("(")
        return cmd[a+1:-2].split(',')
    def ApplyDat(self,obj,mesh,layer,path):
        tris = mesh.polygons
        bpy.context.view_layer.objects.active = obj
        ind = -1
        UVmap = obj.data.uv_layers.new(name='UVMap')
        #try to make color attribute first, then do vertex color if it fails
        try:
            Vcol = obj.data.color_attributes.new(name='Col', type="FLOAT_COLOR", domain="CORNER")
            Valph = obj.data.vertex_colors.new(name='Alpha', type="FLOAT_COLOR", domain="CORNER")
        except:
            Vcol = obj.data.vertex_colors.new(name = 'Col')
            Valph = obj.data.vertex_colors.new(name = 'Alpha')
        self.Mats.append([len(tris),0])
        for i,t in enumerate(tris):
            if i > self.Mats[ind+1][0]:
                self.Create_new_f3d_mat(self.Mats[ind+1][1],self.Textures,mesh)
                ind += 1
                mat = mesh.materials[ind]
                mat.name = "SM64 {} F3D Mat {}".format(self.StartName, ind)
                self.Mats[ind][1].ApplyMatSettings(mat,self.Textures,path,layer)
            #if somehow there is no material assigned to the triangle or something is lost
            if ind != -1:
                t.material_index = ind
                #Get texture size or assume 32, 32 otherwise
                i = mesh.materials[ind].f3d_mat.tex0.tex
                if not i:
                    WH = (32, 32)
                else:
                    WH = i.size
                #Set UV data and Vertex Color Data
                for v,l in zip(t.vertices,t.loop_indices):
                    uv = self.UVs[v]
                    vcol = self.VCs[v]
                    #scale verts. I just copy/pasted this from kirby tbh Idk
                    UVmap.data[l].uv = [a*(1/(32*b)) if b > 0 else a*.001*32 for a, b in zip(uv,WH)]
                    #increase vert UV pos by 1
                    UVmap.data[l].uv[1] -= 1
                    #idk why this is necessary. N64 thing or something?
                    UVmap.data[l].uv[1] = UVmap.data[l].uv[1]*-1
                    Vcol.data[l].color = [a/255 for a in vcol]
    def Create_new_f3d_mat(self,mat,textures,mesh):
        #check if this mat was used already in another mesh (or this mat if DL is garbage or something)
        #even looping n^2 is probably faster than duping 3 mats with blender speed
        if not bpy.context.scene.LevelImp.AsObj:
            if not bpy.context.scene.LevelImp.ForceNewTex:
                for F3Dmat in bpy.data.materials:
                    if F3Dmat.is_f3d:
                        dupe = mat.MatHashF3d(F3Dmat.f3d_mat,textures)
                        if dupe:
                            mesh.materials.append(F3Dmat)
                            return F3Dmat
            bpy.ops.object.create_f3d_mat() #the newest mat should be in slot[-1] for the mesh materials
            return None
        else:
            if not bpy.context.scene.LevelImp.ForceNewTex:
                for mat in bpy.data.materials:
                    if 0:
                        dupe = mat.MatHash(mat,textures)
                        if dupe:
                            mesh.materials.append(mat)
                            return mat
            NewMat = bpy.data.materials.new("material")
            mesh.materials.append(NewMat) #the newest mat should be in slot[-1] for the mesh materials
            NewMat.use_nodes = True
        return None

#creates a new collection and links it to parent
def CreateCol(parent, name):
    col = bpy.data.collections.new(name)
    parent.children.link(col)
    return col


def RotateObj(deg, obj, world = 0):
    deg = Euler((math.radians(-deg), 0, 0))
    deg = deg.to_quaternion().to_matrix().to_4x4()
    if world:
        obj.matrix_world = obj.matrix_world @ deg
        obj.select_set(True)
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.transform_apply(rotation = True)
    else:
        obj.matrix_basis = obj.matrix_basis @ deg


#reverse of what fast64 uses
transform_mtx_blender_to_n64 = lambda: Matrix(((1, 0, 0, 0), (0, 0, 1, 0), (0, -1, 0, 0), (0, 0, 0, 1)))

def Rot2Blend(rotation):
    new_rot = transform_mtx_blender_to_n64().inverted() @ rotation.to_matrix().to_4x4() @ transform_mtx_blender_to_n64()
    new_rot = new_rot.to_quaternion().to_euler('XYZ')
    return new_rot

#if keep, then it doesn't inherit parent trasnform
def Parent(parent, child, keep = 0):
    if not keep:
        child.parent = parent
        child.matrix_local = child.matrix_parent_inverse
    else:
        parent.select_set(True)
        child.select_set(True)
        bpy.context.view_layer.objects.active = parent
        bpy.ops.object.parent_set()
        parent.select_set(False)
        child.select_set(False)

def EvalMacro(line):
    scene=bpy.context.scene
    if scene.LevelImp.Version in line:
        return False
    if scene.LevelImp.Target in line:
        return False
    return True

def ParseAggregat(dat,str,path):
    dat.seek(0) #so it may be read multiple times
    ldat = dat.readlines()
    cols=[]
    #assume this follows naming convention
    for l in ldat:
        if str in l:
            comment=l.rfind("//")
            #double slash terminates line basically
            if comment:
                l=l[:comment]
            cols.append(l.strip())
    #remove include and quotes inefficiently. Now cols is a list of relative paths
    cols = [c.replace("#include ",'').replace('"','').replace("'",'') for c in cols]
    #deal with duplicate pathing (such as /actors/actors etc.)
    Extra = path.relative_to(Path(bpy.context.scene.decompPath))
    for e in Extra.parts:
        cols = [c.replace(e+'/','') for c in cols]
    if cols:
        return [path/c for c in cols]
    else:
        return []

def FindCollisions(model,lvl,scene,path):
    leveldat = open(model,'r')
    cols=ParseAggregat(leveldat,'collision.inc.c',path)
    #catch fast64 includes
    fast64=ParseAggregat(leveldat,'leveldata.inc.c',path)
    if fast64:
        f64dat = open(fast64[0],'r')
        cols+=ParseAggregat(f64dat,'collision.inc.c',path)
    leveldat.close()
    #search for the area terrain in each file
    for k,v in lvl.Areas.items():
        terrain = v.terrain
        found=0
        for c in cols:
            if os.path.isfile(c):
                c=open(c,'r')
                c=c.readlines()
                for i,l in enumerate(c):
                    if terrain in l:
                        #Trim Collision to be just the lines that have the file
                        v.ColFile=c[i:]
                        break
                else:
                    c=None    
                    continue
                break
            else:
                c=None
        if not c:
            raise Exception('Collision {} not found in levels/{}/{}leveldata.c'.format(terrain,scene.LevelImp.Level,scene.LevelImp.Prefix))
        Collisions = FormatDat(v.ColFile,'Collision',['(',')'])
        v.ColFile = Collisions[terrain]
    return lvl

def CleanCollision(ColFile):
    #Now do the same post processing to macros for potential fuckery that I did to scripts.
    #This means removing comments, dealing with potential multi line macros and making sure each line is one macro
    InlineReg="/\*((?!\*/).)*\*/"
    started=0
    skip=0
    col=''
    for l in ColFile:
        #remove line comment
        comment=l.rfind("//")
        if comment:
            l=l[:comment]
        #check for macro
        if '#ifdef' in l:
            skip=EvalMacro(l)
        if '#elif' in l:
            skip=EvalMacro(l)
        if '#else' in l:
            skip=0
            continue
        #Now Check for col start
        if "Collision" in l and not skip:
            started=1
            continue
        if started and not skip:
            #remove inline comments from line
            while(True):
                m=re.search(InlineReg,l)
                if not m:
                    break
                m=m.span()
                l=l[:m[0]]+l[m[1]:]
            #Check for end of Level Script array
            if "};" in l:
                started=0
            #Add line to dict
            else:
                col+=l
    #Now remove newlines from each script, and then split macro ends
    #This makes each member of the array a single macro
    col=col.replace("\n",'')
    arr=[]
    x=0
    stack=0
    buf=""
    app=0
    while(x<len(col)):
        char=col[x]
        if char=="(":
            stack+=1
            app=1
        if char==")":
            stack-=1
        if app==1 and stack==0:
            app=0
            buf+=col[x:x+2] #get the last parenthesis and comma
            arr.append(buf.strip())
            x+=2
            buf=''
            continue
        buf+=char
        x+=1
    return arr

def WriteLevelCollision(lvl, scene, cleanup, col = None):
    for k,v in lvl.Areas.items():
        if not col:
            col = v.root.users_collection[0]
        else:
            col = CreateCol(v.root.users_collection[0], col)
        #dat is a class that holds all the collision files data
        dat = Collision(v.ColFile, scene.blenderToSM64Scale)
        dat.GetCollision()
        name = "SM64 {} Area {} Col".format(scene.LevelImp.Level,k)
        obj = dat.WriteCollision(scene, name, v.root, col = col)
        #final operators to clean stuff up
        if cleanup:
            obj.data.validate()
            obj.data.update(calc_edges=True)
            #shade smooth
            obj.select_set(True)
            bpy.context.view_layer.objects.active = obj
            bpy.ops.object.shade_smooth()
            bpy.ops.object.mode_set(mode='EDIT')
            bpy.ops.mesh.remove_doubles()
            bpy.ops.object.mode_set(mode='OBJECT')
        

def FormatModel(gfx, model, path):
    #For each data type, make an attribute where it cleans the input of the model files
    gfx.VB.update(FormatDat(model,'Vtx',["{","}"]))
    gfx.Gfx.update(FormatDat(model,'Gfx',["(",")"]))
    gfx.diff.update(FormatDat(model,'Light_t',[None,None]))
    gfx.amb.update(FormatDat(model,'Ambient_t',[None,None]))
    gfx.Lights.update(FormatDat(model,'Lights1',[None,None]))
    #For textures, try u8, and s16 aswell
    gfx.Textures.update(FormatDat(model,'Texture',[None,None]))
    gfx.Textures.update(FormatDat(model,'u8',[None,None]))
    gfx.Textures.update(FormatDat(model,'s16',[None,None]))
    return gfx

#Heavily copied from CleanGeo
def FormatDat(model,Type,Chars):
    #Get a dictionary made up with keys=level script names
    #and values as an array of all the cmds inside.
    Models={}
    InlineReg="/\*((?!\*/).)*\*/"
    currScr=0
    skip=0
    for l in model:
        comment=l.rfind("//")
        #double slash terminates line basically
        if comment:
            l=l[:comment]
        #check for macro
        if '#ifdef' in l:
            skip=EvalMacro(l)
        if '#elif' in l:
            skip=EvalMacro(l)
        if '#else' in l:
            skip=0
            continue
        #Now Check for level script starts
        regX='\[[0-9a-fx]*\]'
        match = re.search(regX,l,flags=re.IGNORECASE)
        if Type in l and re.search(regX,l) and not skip:
            b=match.span()[0]
            a=l.find(Type)
            var=l[a+len(Type):b].strip()
            Models[var] = ""
            currScr=var
            continue
        if currScr and not skip:
            #remove inline comments from line
            while(True):
                m=re.search(InlineReg,l)
                if not m:
                    break
                m=m.span()
                l=l[:m[0]]+l[m[1]:]
            #Check for end of Level Script array
            if "};" in l:
                currScr=0
            #Add line to dict
            else:
                Models[currScr]+=l
    #Now remove newlines from each script, and then split macro ends
    #This makes each member of the array a single macro
    for k,v in Models.items():
        v=v.replace("\n",'')
        arr=[]
        x=0
        stack=0
        buf=""
        app=0
        while(x<len(v)):
            char=v[x]
            if char==Chars[0]:
                stack+=1
                app=1
            if char==Chars[1]:
                stack-=1
            if app==1 and stack==0:
                app=0
                buf+=v[x:x+2] #get the last parenthesis and comma
                arr.append(buf.strip())
                x+=2
                buf=''
                continue
            buf+=char
            x+=1
        #for when the control flow characters are nothing
        if buf:
            arr.append(buf)
        Models[k]=arr
    return Models

#given a geo.c file and a path, return cleaned up geo layouts in a dict
def GetGeoLayouts(geo, path):
    layouts = ParseAggregat(geo,'geo.inc.c',path)
    if not layouts:
        return
    #because of fast64, these can be recursively defined (though I expect only a depth of one)
    for l in layouts:
        geoR = open(l,'r')
        layouts += ParseAggregat(geoR,'geo.inc.c',path)
    GeoLayouts = {} #stores cleaned up geo layout lines
    for l in layouts:
        l = open(l,'r')
        lines = l.readlines()
        GeoLayouts.update(FormatDat(lines,'GeoLayout',["(",")"]))
    return GeoLayouts

#Find DL references given a level geo file and a path to a level folder
def FindLvlModels(geo, lvl, scene, path, col = None):
    GeoLayouts = GetGeoLayouts(geo, path)
    for k, v in lvl.Areas.items():
        GL = v.geo
        rt = v.root
        if col:
            gfxcol = CreateCol(v.root.users_collection[0], col)
        else:
            gfxcol = col
        Geo = GeoLayout(GeoLayouts, rt, scene, "GeoRoot {} {}".format(scene.LevelImp.Level,k), rt, col = gfxcol)
        Geo.ParseLevelGeosStart(GL, scene)
        v.geo = Geo
    return lvl

#Parse an aggregate group file or level data file for geo layouts
def FindActModels(geo, Layout, scene, rt, path, col = None):
    GeoLayouts = GetGeoLayouts(geo, path)
    Geo = GeoLayout(GeoLayouts, rt, scene, "{}".format(Layout), rt, col = col)
    Geo.ParseLevelGeosStart(Layout, scene)
    return Geo

#Parse an aggregate group file or level data file for f3d data
def FindModelDat(model, scene, path):
    leveldat = open(model,'r')
    models=ParseAggregat(leveldat,'model.inc.c',path)
    models+=ParseAggregat(leveldat,'painting.inc.c',path)
    #fast64 makes a leveldata.inc.c file and puts custom content there, I want to catch that as well
    #this isn't the best way to do this, but I will be lazy here
    fast64=ParseAggregat(leveldat,'leveldata.inc.c',path)
    if fast64:
        f64dat = open(fast64[0],'r')
        models+=ParseAggregat(f64dat,'model.inc.c',path)
    leveldat.close()
    leveldat = open(model,'r') #some fuckery where reading lines causes it to have issues
    textures=ParseAggregat(leveldat,'texture.inc.c',path) #Only deal with textures that are actual .pngs
    leveldat.close()
    leveldat = open(model,'r') #some fuckery where reading lines causes it to have issues
    textures.extend(ParseAggregat(leveldat,'textureNew.inc.c',path)) #For RM2C support
    #Get all modeldata in the level
    Models=F3d(scene)
    for m in models:
        md=open(m,'r')
        lines=md.readlines()
        Models=FormatModel(Models,lines,path)
    #Update file to have texture.inc.c textures, deal with included textures in the model.inc.c files aswell
    for t in [*textures,*models]:
        t=open(t,'r')
        tex=t.readlines()
        #For textures, try u8, and s16 aswell
        Models.Textures.update(FormatDat(tex,'Texture',[None,None]))
        Models.Textures.update(FormatDat(tex,'u8',[None,None]))
        Models.Textures.update(FormatDat(tex,'s16',[None,None]))
        t.close()
    return Models

#holds model found by geo
@dataclass
class ModelDat():
    translate: tuple
    rotate: tuple
    layer: int
    model: str
    scale: float = 1.0

class GeoLayout():
    def __init__(self, GeoLayouts, root, scene, name, Aroot, col = None):
        self.GL = GeoLayouts
        self.parent = root
        self.models = []
        self.Children = []
        self.scene = scene
        self.RenderRange = None
        self.Aroot = Aroot #for properties that can only be written to area
        self.root = root
        self.ParentTransform = [[0,0,0], [0,0,0]]
        self.LastTransform = [[0,0,0], [0,0,0]]
        self.name = name
        self.obj = None #last object on this layer of the tree, will become parent of next child
        if not col:
            self.col = Aroot.users_collection[0]
        else:
            self.col = col
    def MakeRt(self, name, root):
        #make an empty node to act as the root of this geo layout
        #use this to hold a transform, or an actual cmd, otherwise rt is passed
        E = bpy.data.objects.new(name, None)
        self.obj = E
        self.col.objects.link(E)
        Parent(root, E)
        return E
    def ParseLevelGeosStart(self, start, scene):
        GL = self.GL.get(start)
        if not GL:
            raise Exception("Could not find geo layout {} from levels/{}/{}geo.c".format(start,scene.LevelImp.Level,scene.LevelImp.Prefix))
        self.ParseLevelGeos(GL, 0)
    #So I can start where ever for child nodes
    def ParseLevelGeos(self, GL, depth):
        #I won't parse the geo layout perfectly. For now I'll just get models. This is mostly because fast64
        #isn't a bijection to geo layouts, the props are sort of handled all over the place
        x =- 1
        while(x < len(GL)):
            #manaual iteration so I can skip certain children efficiently
            x += 1
            l = GL[x]
            LsW = l.startswith
            args = self.StripArgs(l)
            #Jumps are only taken if they're in the script.c file for now
            #continues script
            if LsW("GEO_BRANCH_AND_LINK"):
                NewGL=self.GL.get(args[0].strip())
                if NewGL:
                    self.ParseLevelGeos(NewGL,depth)
                continue
            #continues
            elif LsW("GEO_BRANCH"):
                NewGL=self.GL.get(args[1].strip())
                if NewGL:
                    self.ParseLevelGeos(NewGL,depth)
                if eval(args[0]):
                    continue
                else:
                    break
            #final exit of recursion
            elif LsW("GEO_END") or l.startswith("GEO_RETURN"):
                return
            #on an open node, make a child
            elif LsW("GEO_CLOSE_NODE"):
                #if there is no more open nodes, then parent this to last node
                if depth:
                    return
            elif LsW("GEO_OPEN_NODE"):
                if self.obj:
                    GeoChild = GeoLayout(self.GL, self.obj, self.scene, self.name, self.Aroot, col = self.col)
                else:
                    GeoChild = GeoLayout(self.GL, self.root, self.scene, self.name, self.Aroot, col = self.col)
                GeoChild.ParentTransform = self.LastTransform
                GeoChild.ParseLevelGeos(GL[x+1:], depth+1)
                x = self.SkipChildren(GL, x)
                self.Children.append(GeoChild)
                continue
            #Append to models array. Only check this one for now
            elif LsW("GEO_DISPLAY_LIST"):
                #translation, rotation, layer, model
                self.models.append( ModelDat(*self.ParentTransform,*args) )
                continue
            #shadows aren't naturally supported but we can emulate them with custom geo cmds
            elif LsW("GEO_SHADOW"):
                obj = self.MakeRt(self.name + "shadow empty", self.root)
                obj.sm64_obj_type = 'Custom Geo Command'
                obj.customGeoCommand = "GEO_SHADOW"
                obj.customGeoCommandArgs = ','.join(args)
                continue
            #bones aren't supported with this class
            elif LsW("GEO_ANIMATED_PART"):
                #layer, translation, DL
                layer = args[0]
                Tlate = [float(a)/bpy.context.scene.blenderToSM64Scale for a in args[1:4]]
                Tlate = [Tlate[0],-Tlate[2],Tlate[1]]
                model = args[-1]
                self.LastTransform = [Tlate,self.LastTransform[1]]
                if model.strip() != "NULL":
                    self.models.append( ModelDat(Tlate, (0,0,0), layer, model) )
                else:
                    obj = self.MakeRt(self.name + "animated empty", self.root)
                    obj.location = Tlate
                continue
            elif LsW("GEO_ROTATE") or LsW("GEO_ROTATION_NODE"):
                layer = args[0]
                Rotate = [math.radians(float(a)) for a in [args[1], args[2], args[3]]]
                Rotate = Rot2Blend(Euler(Rotate,'ZXY').to_quaternion())
                self.LastTransform = [[0,0,0], Rotate]
                self.LastTransform=[[0,0,0], self.LastTransform[1]]
                obj = self.MakeRt(self.name + "rotate", self.root)
                obj.rotation_euler = Rotate
                if LsW("GEO_ROTATE"):
                    obj.sm64_obj_type = 'Geo Translate/Rotate'
                else:
                    obj.sm64_obj_type = 'Geo Rotation Node'
            elif LsW("GEO_ROTATE_WITH_DL") or LsW("GEO_ROTATION_NODE_WITH_DL"):
                layer = args[0]
                Rotate = [math.radians(float(a)) for a in [args[1], args[2], args[3]]]
                Rotate = Rot2Blend(Euler(Rotate,'ZXY').to_quaternion())
                self.LastTransform = [[0,0,0], Rotate]
                model = args[-1]
                self.LastTransform=[[0,0,0], self.LastTransform[1]]
                if model.strip() != "NULL":
                    self.models.append( ModelDat([0,0,0], Rotate, layer, model) )
                else:
                    obj = self.MakeRt(self.name + "rotate", self.root)
                    obj.rotation_euler = Rotate
                    if LsW("GEO_ROTATE_WITH_DL"):
                        obj.sm64_obj_type = 'Geo Translate/Rotate'
                    else:
                        obj.sm64_obj_type = 'Geo Rotation Node'
            elif LsW("GEO_TRANSLATE_ROTATE_WITH_DL"):
                layer = args[0]
                Tlate = [float(a)/bpy.context.scene.blenderToSM64Scale for a in args[1:4]]
                Tlate = [Tlate[0], -Tlate[2], Tlate[1]]
                Rotate = [math.radians(float(a)) for a in [args[4], args[5], args[6]]]
                Rotate = Rot2Blend(Euler(Rotate,'ZXY').to_quaternion())
                self.LastTransform = [Tlate, Rotate]
                model = args[-1]
                self.LastTransform=[Tlate, self.LastTransform[1]]
                if model.strip() != "NULL":
                    self.models.append( ModelDat(Tlate, Rotate, layer, model) )
                else:
                    obj = self.MakeRt(self.name + "translate rotate", self.root)
                    obj.location = Tlate
                    obj.rotation_euler = Rotate
                    obj.sm64_obj_type = 'Geo Translate/Rotate'
            elif LsW("GEO_TRANSLATE_ROTATE"):
                Tlate = [float(a)/bpy.context.scene.blenderToSM64Scale for a in args[1:4]]
                Tlate = [Tlate[0], -Tlate[2], Tlate[1]]
                Rotate = [math.radians(float(a)) for a in [args[4], args[5], args[6]]]
                Rotate = Rot2Blend(Euler(Rotate,'ZXY').to_quaternion())
                self.LastTransform = [Tlate, Rotate]
                obj = self.MakeRt(self.name + "translate", self.root)
                obj.location = Tlate
                obj.rotation_euler = Rotate
                obj.sm64_obj_type = 'Geo Translate/Rotate'
                continue
            elif LsW("GEO_TRANSLATE_NODE_WITH_DL") or LsW("GEO_TRANSLATE_WITH_DL"):
                #translation, layer, model
                layer = args[0]
                Tlate = [float(a)/bpy.context.scene.blenderToSM64Scale for a in args[1:4]]
                Tlate = [Tlate[0], -Tlate[2], Tlate[1]]
                model = args[-1]
                self.LastTransform = [Tlate, (0, 0, 0)]
                if model.strip() != "NULL":
                    self.models.append( ModelDat(Tlate, (0, 0, 0), layer, model) )
                else:
                    obj = self.MakeRt(self.name + "translate", self.root)
                    obj.location = Tlate
                    obj.rotation_euler = Rotate
                    if LsW("GEO_TRANSLATE_WITH_DL"):
                        obj.sm64_obj_type = 'Geo Translate/Rotate'
                    else:
                        obj.sm64_obj_type = 'Geo Translate Node'
                    continue
            elif LsW("GEO_TRANSLATE_NODE") or LsW("GEO_TRANSLATE"):
                Tlate = [float(a)/bpy.context.scene.blenderToSM64Scale for a in args[1:4]]
                Tlate = [Tlate[0], -Tlate[2], Tlate[1]]
                self.LastTransform = [Tlate, self.LastTransform[1]]
                obj = self.MakeRt(self.name + "translate", self.root)
                obj.location = Tlate
                if LsW("GEO_TRANSLATE"):
                    obj.sm64_obj_type = 'Geo Translate/Rotate'
                else:
                    obj.sm64_obj_type = 'Geo Translate Node'
                continue                
            elif LsW("GEO_SCALE_WITH_DL"):
                scale = eval(args[1].strip()) / 0x10000
                model = args[-1]
                self.LastTransform = [(0,0,0), self.LastTransform[1]]
                self.models.append( ModelDat((0,0,0), (0,0,0), layer, model, scale = scale) )
                continue
            elif LsW("GEO_SCALE"):
                obj = self.MakeRt(self.name + "scale", self.root)
                scale = eval(args[1].strip()) / 0x10000
                obj.scale = (scale, scale, scale)
                obj.sm64_obj_type = 'Geo Scale'
                continue
            elif LsW("GEO_ASM"):
                obj = self.MakeRt(self.name + "asm", self.root)
                asm = self.obj.fast64.sm64.geo_asm
                self.obj.sm64_obj_type = 'Geo ASM'
                asm.param = args[0].strip()
                asm.func = args[1].strip()
                continue
            elif LsW("GEO_SWITCH_CASE"):
                obj = self.MakeRt(self.name + "switch", self.root)
                Switch = self.obj
                Switch.sm64_obj_type = 'Switch'
                Switch.switchParam = eval(args[0])
                Switch.switchFunc = args[1].strip()
                continue
            #This has to be applied to meshes
            elif LsW("GEO_RENDER_RANGE"):
                self.RenderRange = args
                continue
            #can only apply type to area root
            elif LsW("GEO_CAMERA"):
                self.Aroot.camOption = 'Custom'
                self.Aroot.camType = args[0]
                continue
            #Geo backgrounds is pointless because the only background possible is the one
            #loaded in the level script. This is the only override
            elif LsW("GEO_BACKGROUND_COLOR"):
                self.Aroot.areaOverrideBG = True
                color = eval(args[0])
                A = color&1
                B = (color&0x3E)>1
                G = (color&(0x3E<<5))>>6
                R = (color&(0x3E<<10))>>11
                self.Aroot.areaBGColor = (R/0x1F,G/0x1F,B/0x1F,A)
    def SkipChildren(self,GL,x):
        open=0
        opened=0
        while(x<len(GL)):
            l=GL[x]
            if l.startswith('GEO_OPEN_NODE'):
                opened=1
                open+=1
            if l.startswith('GEO_CLOSE_NODE'):
                open-=1
            if open==0 and opened:
                break
            x+=1
        return x
    def StripArgs(self,cmd):
        a=cmd.find("(")
        return cmd[a+1:-2].split(',')

#Dict converting
Layers={
    'LAYER_FORCE':'0',
    'LAYER_OPAQUE':'1',
    'LAYER_OPAQUE_DECAL':'2',
    'LAYER_OPAQUE_INTER':'3',
    'LAYER_ALPHA':'4',
    'LAYER_TRANSPARENT':'5',
    'LAYER_TRANSPARENT_DECAL':'6',
    'LAYER_TRANSPARENT_INTER':'7',
}

#from a geo layout, create all the mesh's
def ReadGeoLayout(geo, scene, models, path, meshes, cleanup = True, col = None):
    if geo.models:
        rt = geo.root
        if not col:
            col = geo.col
        #create a mesh for each one.
        for m in geo.models:
            name = m.model +' Data'
            if name in meshes.keys():
                mesh = meshes[name]
                name = 0
            else:
                mesh = bpy.data.meshes.new(name)
                meshes[name] = mesh
                [verts,tris] = models.GetDataFromModel(m.model.strip())
                mesh.from_pydata(verts, [], tris)

            obj = bpy.data.objects.new(m.model + ' Obj', mesh)
            layer = m.layer
            if not layer.isdigit():
                layer = Layers.get(layer)
                if not layer:
                    layer = 1
            obj.draw_layer_static = layer
            col.objects.link(obj)
            Parent(rt, obj)
            RotateObj(-90, obj)
            scale = m.scale / scene.blenderToSM64Scale
            obj.scale = [scale,scale,scale]
            obj.location = m.translate
            obj.ignore_collision = True
            if name:
                models.ApplyDat(obj, mesh, layer, path)
                if cleanup:
                    #clean up after applying dat
                    mesh.validate()
                    mesh.update(calc_edges = True)
                    #final operators to clean stuff up
                    #shade smooth
                    obj.select_set(True)
                    bpy.context.view_layer.objects.active = obj
                    bpy.ops.object.shade_smooth()
                    bpy.ops.object.mode_set(mode = 'EDIT')
                    bpy.ops.mesh.remove_doubles()
                    bpy.ops.object.mode_set(mode = 'OBJECT')
    if not geo.Children:
        return
    for g in geo.Children:
        ReadGeoLayout(g, scene, models, path, meshes, cleanup = cleanup)

def WriteLevelModel(lvl, scene, path, modelDat, cleanup = True):
    for k,v in lvl.Areas.items():
        #Parse the geolayout class I created earlier to look for models
        meshes = {} #re use mesh data when the same DL is referenced (bbh is good example)
        ReadGeoLayout(v.geo, scene, modelDat, path, meshes, cleanup = cleanup)
    return lvl

def ParseScript(script, scene, col = None):
    scr = open(script,'r')
    Root = bpy.data.objects.new('Empty', None)
    if not col:
        scene.collection.objects.link(Root)
    else:
        col.objects.link(Root)
    Root.name = "Level Root {}".format(scene.LevelImp.Level)
    Root.sm64_obj_type = 'Level Root'
    #Now parse the script and get data about the level
    #Store data in attribute of a level class then assign later and return class
    scr = scr.readlines()
    lvl = Level(scr, scene, Root)
    entry = scene.LevelImp.Entry.format(scene.LevelImp.Level)
    lvl.ParseScript(entry, col = col)
    return lvl

def WriteObjects(lvl, col = None):
    for area in lvl.Areas.values():
        area.PlaceObjects(col = col)

def ImportLvlVisual(geo, lvl, scene, path, model, cleanup = True, col = None):
    lvl = FindLvlModels(geo, lvl, scene, path, col = col)
    models = FindModelDat(model, scene, path)
    #just a try, in case you are importing from not the base decomp repo
    try:
        models.GetGenericTextures(path)
    except:
        print("could not import genric textures, if this errors later from missing textures this may be why")
    lvl = WriteLevelModel(lvl, scene, path, models, cleanup = cleanup)
    return lvl

def ImportLvlCollision(model, lvl, scene, path, cleanup, col = None):
    lvl = FindCollisions(model, lvl, scene, path) #Now Each area has its collision file nicely formatted
    WriteLevelCollision(lvl, scene, cleanup, col = col)
    return lvl

class SM64_OT_Act_Import(Operator):
    bl_label = "Import Actor"
    bl_idname = "wm.sm64_import_actor"
    bl_options = {"REGISTER","UNDO"}
    
    cleanup: bpy.props.BoolProperty(name = "Cleanup Mesh", default = 1)

    def execute(self, context):
        scene = context.scene
        rt_col = context.collection
        scene.gameEditorMode = 'SM64'
        path = Path(scene.decompPath)
        folder = path / scene.ActImp.FolderType
        Layout = scene.ActImp.GeoLayout
        prefix = scene.ActImp.Prefix
        #different name schemes and I have no clean way to deal with it
        if 'actor' in scene.ActImp.FolderType:
            geo = folder/(prefix+'_geo.c')
            leveldat = folder/(prefix+'.c')
        else:
            geo = folder/(prefix+'geo.c')
            leveldat = folder/(prefix+'leveldata.c')
        geo = open(geo,'r')
        Root = bpy.data.objects.new('Empty',None)
        Root.name = 'Actor %s'%scene.ActImp.GeoLayout
        rt_col.objects.link(Root)
        
        Geo = FindActModels(geo, Layout, scene, Root, folder, col = rt_col) #return geo layout class and write the geo layout
        models = FindModelDat(leveldat, scene, folder)
        #just a try, in case you are importing from not the base decomp repo
        try:
            models.GetGenericTextures(path)
        except:
            print("could not import genric textures, if this errors later from missing textures this may be why")
        meshes = {} #re use mesh data when the same DL is referenced (bbh is good example)
        ReadGeoLayout(Geo, scene, models, folder, meshes, cleanup = self.cleanup, col = rt_col)
        return {'FINISHED'}

class SM64_OT_Lvl_Import(Operator):
    bl_label = "Import Level"
    bl_idname = "wm.sm64_import_level"
    
    cleanup = True
    
    def execute(self, context):
        scene = context.scene
        
        col = context.collection
        if scene.LevelImp.UseCol:
            obj_col = f"{scene.LevelImp.Level} obj"
            gfx_col = f"{scene.LevelImp.Level} gfx"
            col_col = f"{scene.LevelImp.Level} col"
        else:
            obj_col = gfx_col = col_col = None
        
        scene.gameEditorMode = 'SM64'
        prefix = scene.LevelImp.Prefix
        path = Path(scene.decompPath)
        level = path / 'levels' / scene.LevelImp.Level
        script = level / (prefix + 'script.c')
        geo = level / (prefix + 'geo.c')
        leveldat = level / (prefix + 'leveldata.c')
        geo = open(geo,'r')
        lvl = ParseScript(script, scene, col = col) #returns level class
        WriteObjects(lvl, col = obj_col)
        lvl = ImportLvlCollision(leveldat, lvl, scene, path, self.cleanup, col = col_col)
        lvl = ImportLvlVisual(geo, lvl, scene, path, leveldat, cleanup = self.cleanup, col = gfx_col)
        return {'FINISHED'}

class SM64_OT_Lvl_Gfx_Import(Operator):
    bl_label = "Import Gfx"
    bl_idname = "wm.sm64_import_level_gfx"
    
    cleanup = True
    
    def execute(self, context):
        scene = context.scene
        
        col = context.collection
        if scene.LevelImp.UseCol:
            gfx_col = f"{scene.LevelImp.Level} gfx"
        else:
            gfx_col = None
            
        scene.gameEditorMode = 'SM64'
        prefix = scene.LevelImp.Prefix
        path = Path(scene.decompPath)
        level = path/'levels'/scene.LevelImp.Level
        script = level/(prefix + 'script.c')
        geo = level/(prefix + 'geo.c')
        model = level/(prefix + 'leveldata.c')
        geo = open(geo,'r')
        lvl = ParseScript(script, scene, col = col) #returns level class
        lvl = ImportLvlVisual(geo, lvl, scene, path, model, cleanup = self.cleanup, col = gfx_col)
        return {'FINISHED'}

class SM64_OT_Lvl_Col_Import(Operator):
    bl_label = "Import Collision"
    bl_idname = "wm.sm64_import_level_col"

    cleanup = True
    
    def execute(self, context):
        scene = context.scene
        
        col = context.collection
        if scene.LevelImp.UseCol:
            col_col = f"{scene.LevelImp.Level} collisiion"
        else:
            col_col = None
            
        scene.gameEditorMode = 'SM64'
        prefix = scene.LevelImp.Prefix
        path = Path(scene.decompPath)
        level = path/'levels'/scene.LevelImp.Level
        script= level/(prefix + 'script.c')
        geo = level/(prefix + 'geo.c')
        model = level/(prefix + 'leveldata.c')
        geo = open(geo,'r')
        lvl = ParseScript(script, scene, col = col) #returns level class
        lvl = ImportLvlCollision(model, lvl, scene, path, self.cleanup, col = col_col)
        return {'FINISHED'}

class SM64_OT_Obj_Import(Operator):
    bl_label = "Import Objects"
    bl_idname = "wm.sm64_import_object"

    def execute(self, context):
        scene = context.scene
        
        col = context.collection
        if scene.LevelImp.UseCol:
            obj_col = f"{scene.LevelImp.Level} objs"
        else:
            obj_col = None
            
        scene.gameEditorMode = 'SM64'
        prefix = scene.LevelImp.Prefix
        path = Path(scene.decompPath)
        level = path/'levels'/scene.LevelImp.Level
        script =  level/(prefix+'script.c')
        lvl = ParseScript(script, scene, col = col) #returns level class
        WriteObjects(lvl, col = obj_col)
        return {'FINISHED'}

class ActorImport(PropertyGroup):
    GeoLayout: StringProperty(
        name = "GeoLayout",
        description="Name of GeoLayout"
        )
    FolderType: EnumProperty(
        name = "Source",
        description="Whether the actor is from a level or from a group",
        items=[
        ('actors','actors',''),
        ('levels','levels',''),
        ]
    )
    Prefix: StringProperty(
        name = "Prefix",
        description="Prefix before expected aggregator files like script.c, leveldata.c and geo.c",
        default=""
    )
    Version: EnumProperty(
        name='Version',
        description="Version of the game for any ifdef macros",
        items=[
        ('VERSION_US','VERSION_US',''),
        ('VERSION_JP','VERSION_JP',''),
        ('VERSION_EU','VERSION_EU',''),
        ('VERSION_SH','VERSION_SH',''),
        ]
    )
    Target: StringProperty(
        name = "Target",
        description="The platform target for any #ifdefs in code",
        default="TARGET_N64"
    )

class LevelImport(PropertyGroup):
    Level: EnumProperty(
        name = "Level",
        description="Choose a level",
        items=[
            ('bbh','bbh',''),
            ('ccm','ccm',''),
            ('hmc','hmc',''),
            ('ssl','ssl',''),
            ('bob','bob',''),
            ('sl','sl',''),
            ('wdw','wdw',''),
            ('jrb','jrb',''),
            ('thi','thi',''),
            ('ttc','ttc',''),
            ('rr','rr',''),
            ('castle_grounds','castle_grounds',''),
            ('castle_inside','castle_inside',''),
            ('bitdw','bitdw',''),
            ('vcutm','vcutm',''),
            ('bitfs','bitfs',''),
            ('sa','sa',''),
            ('bits','bits',''),
            ('lll','lll',''),
            ('ddd','ddd',''),
            ('wf','wf',''),
            ('ending','ending',''),
            ('castle_courtyard','castle_courtyard',''),
            ('pss','pss',''),
            ('cotmc','cotmc',''),
            ('totwc','totwc',''),
            ('bowser_1','bowser_1',''),
            ('wmotr','wmotr',''),
            ('bowser_2','bowser_2',''),
            ('bowser_3','bowser_3',''),
            ('ttm','ttm','')
        ]
        )
    Prefix: StringProperty(
        name = "Prefix",
        description="Prefix before expected aggregator files like script.c, leveldata.c and geo.c",
        default=""
    )
    Entry: StringProperty(
        name = "Entrypoint",
        description="The name of the level script entry variable",
        default="level_{}_entry"
    )
    Version: EnumProperty(
        name='Version',
        description="Version of the game for any ifdef macros",
        items=[
        ('VERSION_US','VERSION_US',''),
        ('VERSION_JP','VERSION_JP',''),
        ('VERSION_EU','VERSION_EU',''),
        ('VERSION_SH','VERSION_SH',''),
        ]
    )
    Target: StringProperty(
        name = "Target",
        description="The platform target for any #ifdefs in code",
        default="TARGET_N64"
    )
    ForceNewTex: BoolProperty(
        name = "ForceNewTex",
        description="Forcefully load new textures even if duplicate path/name is detected",
        default=False
    )
    AsObj: BoolProperty(
        name = "As OBJ",
        description="Make new materials as PBSDF so they export to obj format",
        default=False
    )
    UseCol: BoolProperty(
        name = "Use Col",
        description = "Make new collections to organzie content during imports",
        default = True
    )

class Level_PT_Panel(Panel):
    bl_label = "SM64 Level Importer"
    bl_idname = "sm64_level_importer"
    bl_space_type = "VIEW_3D"   
    bl_region_type = "UI"
    bl_category = "SM64 C Importer"
    bl_context = "objectmode"   

    @classmethod
    def poll(self,context):
        return context.scene is not None

    def draw(self, context):
        layout = self.layout
        scene = context.scene
        LevelImp = scene.LevelImp
        layout.prop(LevelImp, "Level")
        layout.prop(LevelImp,"Entry")
        layout.prop(LevelImp,"Prefix")
        layout.prop(LevelImp,"Version")
        layout.prop(LevelImp,"Target")
        row = layout.row()
        row.prop(LevelImp,"ForceNewTex")
        row.prop(LevelImp,"AsObj")
        row.prop(LevelImp,"UseCol")
        layout.operator("wm.sm64_import_level")
        layout.operator("wm.sm64_import_level_gfx")
        layout.operator("wm.sm64_import_level_col")
        layout.operator("wm.sm64_import_object")

class Actor_PT_Panel(Panel):
    bl_label = "SM64 Actor Importer"
    bl_idname = "sm64_actor_importer"
    bl_space_type = "VIEW_3D"   
    bl_region_type = "UI"
    bl_category = "SM64 C Importer"
    bl_context = "objectmode"   

    @classmethod
    def poll(self,context):
        return context.scene is not None

    def draw(self, context):
        layout = self.layout
        scene = context.scene
        ActImp = scene.ActImp
        layout.prop(ActImp,"FolderType")
        layout.prop(ActImp, "GeoLayout")
        layout.prop(ActImp, "Prefix")
        layout.prop(ActImp,"Version")
        layout.prop(ActImp,"Target")
        layout.operator("wm.sm64_import_actor")


classes = (
    LevelImport,
    ActorImport,
    SM64_OT_Lvl_Import,
    SM64_OT_Lvl_Gfx_Import,
    SM64_OT_Lvl_Col_Import,
    SM64_OT_Obj_Import,
    SM64_OT_Act_Import,
    Level_PT_Panel,
    Actor_PT_Panel
)


def register():
    from bpy.utils import register_class
    for cls in classes:
        register_class(cls)

    bpy.types.Scene.LevelImp = PointerProperty(type=LevelImport)
    bpy.types.Scene.ActImp = PointerProperty(type=ActorImport)

def unregister():
    from bpy.utils import unregister_class
    for cls in reversed(classes):
        unregister_class(cls)
    del bpy.types.Scene.my_tool

if __name__ == "__main__":
    register()