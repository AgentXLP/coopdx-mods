--- @param cond boolean
--- Human readable ternary operator
function if_then_else(cond, ifTrue, ifFalse)
    if cond then return ifTrue end
    return ifFalse
end

function switch(param, caseTable)
    local case = caseTable[param]
    if case then return case() end

    local def = caseTable["default"]
    return def and def() or nil
end

--- @param m MarioState
--- Checks if a player is currently active
function active_player(m)
    local np = gNetworkPlayers[m.playerIndex]
    if m.playerIndex == 0 then
        return true
    end
    if not np.connected then
        return false
    end
    if np.currCourseNum ~= gNetworkPlayers[0].currCourseNum then
        return false
    end
    if np.currActNum ~= gNetworkPlayers[0].currActNum then
        return false
    end
    if np.currLevelNum ~= gNetworkPlayers[0].currLevelNum then
        return false
    end
    if np.currAreaIndex ~= gNetworkPlayers[0].currAreaIndex then
        return false
    end

    return true
end

--- @param s string
--- Splits a string into a table by spaces
function string.split(s)
    local result = {}
    for match in (s):gmatch(string.format("[^%s]+", " ")) do
        table.insert(result, match)
    end
    return result
end

--- @param key string
--- `mod_storage_load_bool` except it returns true by default
function mod_storage_load_bool_2(key)
    local value = mod_storage_load(key)
    if value == nil then return true end
    return value == "true"
end

local rainbowState = 0
local rainbowColor = { r = 255, g = 0, b = 0 }
--- @param speed number
--- @return Color
--- Updates and returns a rainbow color
function update_rainbow_color(speed)
	switch(rainbowState, {
		[0] = function()
			rainbowColor.r = rainbowColor.r + speed
			if rainbowColor.r >= 255 then rainbowState = 1 end
        end,
		[1] = function()
			rainbowColor.b = rainbowColor.b - speed
			if rainbowColor.b <= 0 then rainbowState = 2 end
        end,
		[2] = function()
			rainbowColor.g = rainbowColor.g + speed
			if rainbowColor.g >= 255 then rainbowState = 3 end
        end,
		[3] = function()
			rainbowColor.r = rainbowColor.r - speed
			if rainbowColor.r <= 0 then rainbowState = 4 end
        end,
		[4] = function()
			rainbowColor.b = rainbowColor.b + speed
			if rainbowColor.b >= 255 then rainbowState = 5 end
        end,
		[5] = function()
			rainbowColor.g = rainbowColor.g - speed
			if rainbowColor.g <= 0 then rainbowState = 0 end
        end
	})

	rainbowColor.r = math.clamp(math.round(rainbowColor.r), 0, 255)
    rainbowColor.g = math.clamp(math.round(rainbowColor.g), 0, 255)
    rainbowColor.b = math.clamp(math.round(rainbowColor.b), 0, 255)
	return rainbowColor
end

--- @param r integer
--- @param g integer
--- @param b integer
--- Sets the fog color with R, G, and B values
function set_fog_color_rgb(r, g, b)
	set_fog_color(0, r)
	set_fog_color(1, g)
	set_fog_color(2, b)
end

--- @param r integer
--- @param g integer
--- @param b integer
--- Sets the lighting color with R, G, and B values
function set_lighting_color_rgb(r, g, b)
	set_lighting_color(0, r)
	set_lighting_color(1, g)
	set_lighting_color(2, b)
end

--- @param r integer
--- @param g integer
--- @param b integer
--- Sets the vertex color with `r`, `g`, and `b` values
function set_vertex_color_rgb(r, g, b)
	set_vertex_color(0, r)
	set_vertex_color(1, g)
	set_vertex_color(2, b)
end

--- @param levelNum LevelNum
--- Returns whether or not the local player is in a vanilla level
function in_vanilla_level(levelNum)
    return gNetworkPlayers[0].currLevelNum == levelNum and level_is_vanilla_level(levelNum)
end

--- @param dlName string
--- @param meshIndex integer
--- @param bufferIndex integer
--- Changes the vertex colors on a tilting platform displaylist's underside to blue
function freeze_lava_dl(dlName, meshIndex, bufferIndex)
	local platformGfx = gfx_get_from_name(dlName) -- this is the main displaylist for the platform
	local triangleGfx = gfx_get_display_list(gfx_get_command(platformGfx, meshIndex)) -- gsSPDisplayList(...), is the 9th command in the displaylist
	local triangleVtx = gfx_get_vertex_buffer(gfx_get_command(triangleGfx, bufferIndex)) -- gsSPVertex(..., 10, 0), is the 4th command in the displaylist
	-- we have 10 vertices and a pointer to the first one in the buffer so we only have to loop for the next 9
	while triangleVtx ~= nil do
	    triangleVtx.r = 0
	    triangleVtx.g = 150
	    triangleVtx.b = 255

	    triangleVtx = vtx_get_next_vertex(triangleVtx)
	end
end

--- @param cmd Gfx
--- Combs through a displaylist and if a vertex buffer is found, set the alpha of every vertex to 0
function nullify_dl_alpha(cmd)
    while cmd ~= nil do
        local op = gfx_get_op(cmd)
        if op == G_DL then
            nullify_dl_alpha(gfx_get_display_list(cmd))
        elseif op == G_VTX or op == G_VTX_EXT then
            local buffer = gfx_get_vertex_buffer(cmd)
            while buffer ~= nil do
                buffer.a = 0
                buffer = vtx_get_next_vertex(buffer)
            end
        end

        cmd = gfx_get_next_command(cmd)
    end
end

--- @param a number
--- @param b number
--- @param t number
--- Linearly interpolates between two points using a delta but rounds the final value
function lerp_round(a, b, t)
    return math.round(math.lerp(a, b, t))
end

--- @param a Color
--- @param b Color
--- @param t number
--- @return Color
--- Linearly interpolates between two colors using a delta
function color_lerp(a, b, t)
    return {
        r = lerp_round(a.r, b.r, t),
        g = lerp_round(a.g, b.g, t),
        b = lerp_round(a.b, b.b, t)
    }
end

--- @param a Vec3f
--- @param b Vec3f
--- @return Vec3f
function vec3f_lerp(a, b, t)
    return {
        x = math.lerp(a.x, b.x, t),
        y = math.lerp(a.y, b.y, t),
        z = math.lerp(a.z, b.z, t)
    }
end

--- @param behaviorId BehaviorId
--- @param modelId ModelExtendedId
--- @param x number
--- @param y number
--- @param z number
--- @return Object
--- Spawns a non sync object without a parent. The actual function parents the object to Mario by default
function spawn_object(behaviorId, modelId, x, y, z)
    local obj = spawn_non_sync_object(
        behaviorId,
        modelId,
        x, y, z,
        nil
    )
    obj.parentObj = nil
    obj_set_face_angle(obj, 0, 0, 0)
    return obj
end