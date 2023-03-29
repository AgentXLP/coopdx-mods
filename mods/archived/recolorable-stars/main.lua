-- name: Recolorable Stars
-- description: Recolorable Stars\nBy \\#ec7731\\Agent X\\#dcdcdc\\\n\nThis mod adds recolorable stars to sm64ex-coop. I would have released this as a DynOS pack had it not been for stars always matching the color palette of the host which was fixable with Lua.

--- @param o Object
local function bhv_star_init(o)
    o.globalPlayerIndex = gNetworkPlayers[0].globalIndex
end

id_bhvStar = hook_behavior(id_bhvStar, OBJ_LIST_LEVEL, false, bhv_star_init, nil)