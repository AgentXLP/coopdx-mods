-------------------------------------
-- This code is from underworld-dx --
-- Modification year: 2025         --
-------------------------------------

--- @param v Vec3f
--- @param rotate Vec3f
--- Rotates `dest` around the Z, Y, and X axes
local function vec3f_rotate_zyx(v, rotate)
    local sx = sins(rotate.x)
    local cx = coss(rotate.x)
    local sy = sins(rotate.y)
    local cy = coss(rotate.y)
    local sz = sins(rotate.z)
    local cz = coss(rotate.z)

    -- x axis
    local xz = v.x * cz - v.y * sz
    local yz = v.x * sz + v.y * cz
    local zz = v.z

    -- y axis
    local xy = xz * cy + zz * sy
    local yy = yz
    local zy = -xz * sy + zz * cy

    -- z axis
    v.x = xy
    v.y = yy * cx - zy * sx
    v.z = yy * sx + zy * cx

    return v
end

local LIGHTING_OFFSET = { x = 0x28 / 0xFF, y = 0x28 / 0xFF, z = 0x28 / 0xFF }

--- Updates the SM64 shading to be world-space instead of screen-space
function shading_update()
    local l = gLakituState
    local pitch = calculate_pitch(l.pos, l.focus)
    local yaw = calculate_yaw(l.pos, l.focus)
    local roll = l.roll

    local lightingDir = { x = -1, y = 1, z = -1 }
    vec3f_rotate_zyx(lightingDir, { x = -pitch, y = -yaw, z = roll })
    vec3f_sub(lightingDir, LIGHTING_OFFSET)

    set_lighting_dir(0, lightingDir.x)
    set_lighting_dir(1, lightingDir.y)
    set_lighting_dir(2, lightingDir.z)
end