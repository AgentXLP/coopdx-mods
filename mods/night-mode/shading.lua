-- localize functions to improve performance
local sins,coss,calculate_pitch,vec3f_sub,set_lighting_dir = sins,coss,calculate_pitch,vec3f_sub,set_lighting_dir

--- @param vec Vec3f
--- @param rotate Vec3f
--- Rotates `dest` around the Z, Y, and X axes
local function translate_to_worldspace(vec, rotate)
    local sx = sins(rotate.x)
    local cx = coss(rotate.x)
    local sy = sins(rotate.y)
    local cy = coss(rotate.y)
    local sz = sins(rotate.z)
    local cz = coss(rotate.z)

    -- x axis
    local xz = vec.x * cz - vec.y * sz
    local yz = vec.x * sz + vec.y * cz
    local zz = vec.z

    -- y axis
    local xy = xz * cy + zz * sy
    local yy = yz
    local zy = -xz * sy + zz * cy

    -- z axis
    vec.x = xy
    vec.y = yy * cx - zy * sx
    vec.z = yy * sx + zy * cx

    return vec
end

function shading_update()
    local lightingDir = gVec3fOne()
    translate_to_worldspace(lightingDir, {
        x = -calculate_pitch(gLakituState.pos, gLakituState.focus),
        y = -calculate_pitch(gLakituState.pos, gLakituState.focus),
        z = gLakituState.roll
    })
    vec3f_sub(lightingDir, { x = 0x28 / 0xFF, y = 0x28 / 0xFF, z = 0x28 / 0xFF })

    set_lighting_dir(0, lightingDir.x)
    set_lighting_dir(1, lightingDir.y)
    set_lighting_dir(2, lightingDir.z)
end