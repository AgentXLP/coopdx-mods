-- name: Personal Models
-- description: Personal Models\nBy \\#00ffff\\Blocky\\#dcdcdc\\ and \\#ec7731\\Agent X\\#dcdcdc\\\n\nThis mod makes certain have their own custom playermodels that sync for everyone.

local E_MODEL_WEEDCAT = smlua_model_util_get_id("cosmic_geo")
local E_MODEL_SPOOMPLES = smlua_model_util_get_id("sst_player_geo")
local E_MODEL_TRASHCAM = smlua_model_util_get_id("trashcam_geo")
local E_MODEL_WOOPER = smlua_model_util_get_id("woop_geo")
local E_MODEL_YUYAKE = smlua_model_util_get_id("yuyake_geo")
local E_MODEL_CJ = smlua_model_util_get_id("cjred_geo")
local E_MODEL_EROS = smlua_model_util_get_id("eros_geo")
local E_MODEL_SSM = smlua_model_util_get_id("paisanoe_geo")
local E_MODEL_FREEMAN = smlua_model_util_get_id("gordon_geo")
local E_MODEL_PRINCESS = smlua_model_util_get_id("peach_player_geo")
local E_MODEL_OWO = smlua_model_util_get_id("mawio_geo")
local E_MODEL_BLOCKY = smlua_model_util_get_id("blocky_geo")
local E_MODEL_YOSHI = smlua_model_util_get_id("yoshi_player_geo")
local E_MODEL_RTLB = smlua_model_util_get_id("rtlb64_player_geo")
local E_MODEL_BESTIES = smlua_model_util_get_id("besties")
local E_MODEL_KING = smlua_model_util_get_id("king_geo")
local E_MODEL_CROC = smlua_model_util_get_id("croc_geo")
local E_MODEL_CHEESY_NACHO = smlua_model_util_get_id("cheesynacho_geo")
local E_MODEL_SILLY = smlua_model_util_get_id("silly_geo")
local E_MODEL_MATHEW = smlua_model_util_get_id("mathew_geo")
-- local E_MODEL_STEVEN = smlua_model_util_get_id("steven_geo")
local E_MODEL_FLUFFA = smlua_model_util_get_id("fluffa_geo")
local E_MODEL_KAN = smlua_model_util_get_id("kan_geo")
local E_MODEL_BOYO = smlua_model_util_get_id("boyo_geo")

local obj_set_model_extended = obj_set_model_extended

local idTable = {
    ["461771557531025409"] = E_MODEL_SPOOMPLES,
    ["767513529036832799"] = E_MODEL_WEEDCAT,
    ["827596624590012457"] = E_MODEL_TRASHCAM,
    ["489114867215630336"] = E_MODEL_WOOPER,
    ["397891541160558593"] = E_MODEL_YUYAKE,
    ["469181223957299200"] = E_MODEL_CJ,
    ["376304957168812032"] = E_MODEL_EROS,
    ["202263195820228608"] = E_MODEL_SSM,
    ["490613035237507091"] = E_MODEL_FREEMAN,
    ["732244024567529503"] = E_MODEL_PRINCESS,
    ["371344058167328768"] = E_MODEL_OWO,
    ["584329002689363968"] = E_MODEL_BLOCKY,
    ["561647968084557825"] = E_MODEL_YOSHI,
    ["491581215782993931"] = E_MODEL_YOSHI,
    ["583407621147721728"] = E_MODEL_RTLB,
    ["376426041788465173"] = E_MODEL_BESTIES,
    ["361984642590441474"] = E_MODEL_BESTIES,
    ["352245778858639360"] = E_MODEL_BESTIES,
    ["452585486389870592"] = E_MODEL_BESTIES,
    ["443963592220344320"] = E_MODEL_BESTIES,
    ["713176109126123531"] = E_MODEL_BESTIES,
    ["678794043018182675"] = E_MODEL_BESTIES,
    ["356531273449078784"] = E_MODEL_BESTIES,
    ["294232888398839809"] = E_MODEL_BESTIES,
    ["688726610022891622"] = E_MODEL_YOSHI,
    ["248160341610070026"] = E_MODEL_BESTIES,
    ["572658876223062016"] = E_MODEL_BESTIES,
    ["956289784748331068"] = E_MODEL_BESTIES,
    ["556930233014681631"] = E_MODEL_BESTIES,
    ["739009810875416619"] = E_MODEL_BESTIES,
    ["399584538377846794"] = E_MODEL_BESTIES,
    ["990768765652308058"] = E_MODEL_BESTIES,
    ["603198923120574494"] = E_MODEL_BESTIES,
    ["463414359419518986"] = E_MODEL_BESTIES,
    ["611686357865201664"] = E_MODEL_BESTIES,
    ["770596365126074379"] = E_MODEL_KING,
    ["282702284608110593"] = E_MODEL_CROC,
    ["296308342505078786"] = E_MODEL_CHEESY_NACHO,
    ["772577068449923113"] = E_MODEL_SILLY,
    ["468134163493421076"] = E_MODEL_MATHEW,
    ["754700807345143819"] = E_MODEL_OWO,
    ["143120925066264576"] = E_MODEL_FLUFFA,
    ["799106550874243083"] = E_MODEL_KAN,
    ["564540703120687104"] = E_MODEL_BOYO
}

--- @param m MarioState
local function mario_update(m)
    if not gNetworkPlayers[m.playerIndex].connected then return end

    if gPlayerSyncTable[m.playerIndex].modelId ~= nil then
        obj_set_model_extended(m.marioObj, gPlayerSyncTable[m.playerIndex].modelId)
    end
end

--- @param m MarioState
local function on_player_connected(m)
    gPlayerSyncTable[m.playerIndex].modelId = idTable[network_discord_id_from_local_index(m.playerIndex)]
end

hook_event(HOOK_MARIO_UPDATE, mario_update)
hook_event(HOOK_ON_PLAYER_CONNECTED, on_player_connected)

for i = 0, (MAX_PLAYERS - 1) do
    gPlayerSyncTable[i].modelId = nil
end