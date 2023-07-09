--- @class Dialog
--- @field public id integer
--- @field public name string
--- @field public lines string[]
--- @field public speed number

--- @class DialogState
--- @field public currentDialog Dialog
--- @field public currentLine integer
--- @field public currentChar integer
--- @field public currentLineContents string
--- @field public canProceed boolean
--- @field public skip boolean
--- @field public npc Object
--- @field public dialogTimer integer
--- @field public cutscene boolean
--- @field public overrideCurrent boolean
--- @field public cutsceneDistToCamera number

--- @type Dialog[]
gDialogs = {
    {
        id = 1,
        name = "Old Man",
        lines = {
            "You there! Traveler!",
            "Wait... That mustache, those eyes...",
            "Nevermind. I don't know who you are.",
            "Anyways, I see you fell from the    surface...",
            "I've been trapped in this place for a very long time.",
            "But I discovered a way we could get out of here.",
            "I think what just happened was a    once in a lifetime event.",
            "I mean, the Castle just raised out  of the ground, didn't it?",
            "It must mean something...",
            "Anyways, If we are to get out of    here you must help me.",
            "Explore this Underworld, collect allof the Soul Stars.",
            "West of here is Bob-omb Battlefield.You should head there first.",
            "Once you have done that, return to  me."
        },
        speed = 1
    },
    {
        id = 2,
        name = "Old Man",
        lines = {
            "What are you doing standing around?",
            "You have to collect $STARS   "
        },
        speed = 1
    },
    {
        id = 3,
        name = "Old Man",
        lines = {
            "Heheheh. I see you've collected all of the Soul Stars as I wanted.",
            "Very good $CHARNAME.",
            "I can just feel the power of the    stars...",
            "As for you, you no longer serve any purpose.",
            "You have fulfilled it thus I will   discard of you now.",
            "Heheheh. Goodbye $CHARNAME.",
            "Wow... I can't believe you really   fell for my façade.",
            "Do you want to learn the truth now  that you're useless?",
            "A very long time ago, I was the     greatest troll in the land.",
            "And one day, I discovered an ancientpower to draw from.",
            "Noise.",
            "I began terrorizing the land with   this new power.",
            "But of course, I had to be met with opposition.",
            "6 heroes, the people labeled The    Moderators.",
            "I was forced to battle them or I wasdead.",
            "I gave it everything I had, but     unfortunately...",
            "It wasn't enough.",
            "I was able to best and destroy one  moderator however.",
            "His name was Yoshi.",
            "That is why I only sense 5          descendants, heh.",
            "Without Yoshi, their magic was      weaker.",
            "Still though, they managed to wear  me down.",
            "And then they all used their        combined power on me.",
            "I could not withstand it. I was     sealed away.",
            "Unfortunately for them, the seal    wasn't strong enough.",
            "Without Yoshi, the seal could not bemade permanent.",
            "It slowly waded away over time,     until it broke today.",
            "My power was finally unleashed once more.",
            "I rose the castle out of the ground using the Noise.",
            "Drawing a descendant in was my goal all along.",
            "I knew only they would be capable ofcollecting the stars.",
            "Soul Stars are unobtainable by the  regular and the cursed.",
            "But now... You got them for me, likea fool.",
            "Now if you'll excuse me I have to   just step into the massive laser.",
            "It will bring me to the Overworld.",
            "I'm sure that fling broke your back and rendered you useless.",
            "See you never."
        },
        speed = 1
    },
    {
        id = 4,
        name = "The Shitilizer",
        lines = {
            "You little pest...",
            "Do you ever give up? Why must I     still put up with you.",
            "You're almost too late...",
            "I have nearly finished corrupting   Castle Courtyard with my noise.",
            "Standing in it will slowly kill you.",
            "I will follow suit with the rest of the Mushroom Kingdom.",
            "It will be destroyed and put into   ruin once my noise reaches it.",
            "And you...",
            "You aren't going to stop me in my   conquest.",
            "I will finish what I started long   ago...",
            "With no one in my way this time.",
            "Consider yourself lucky I have not  reached my full power level yet.",
            "I will finally get my revenge on youall...",
            "The descendants of those who sealed me away.",
            "So long, $CHARNAME."
        },
        speed = 1
    },
    {
        id = 5,
        name = "The Shitilizer",
        lines = {
            "NO! THIS CANNOT BE!",
            "Curse myself! I knew I should have  ended you in the Underworld.",
            "I underestimated you $CHARNAME. A       mistake I will never make again.",
            "I know I can take you all down, I   slayed one ancestor.",
            "It won't be like this next time...",
            "I'll be back, and stronger than     ever."
        },
        speed = 1
    }
}

--- @type DialogState
gDialogState = {
    currentDialog = nil,
    currentLine = 1,
    currentChar = 1,
    currentLineContents = "",
    canProceed = false,
    skip = false,
    npc = nil,
    dialogTimer = 0,
    cutscene = true,
    overrideCurrent = false,
    cutsceneDistToCamera = 0
}

-- localize functions to improve performance
local set_mario_action,obj_get_first_with_behavior_id,obj_mark_for_deletion,dist_between_objects,max = set_mario_action,obj_get_first_with_behavior_id,obj_mark_for_deletion,dist_between_objects,max

function reset_dialog_line()
    gDialogState.currentChar = 1
    gDialogState.currentLineContents = ""
    gDialogState.canProceed = false
end

-- also serves as a cutscene end function for dialog cutscenes
function reset_dialog_state()
    gDialogState.currentDialog = nil
    gDialogState.currentLine = 1
    gDialogState.currentChar = 1
    gDialogState.currentLineContents = ""
    gDialogState.canProceed = false
    gDialogState.skip = false
    if gDialogState.npc ~= nil then
        gDialogState.npc.oNpcTalkingTo = -1
        gDialogState.npc = nil
    end
    gDialogState.dialogTimer = 0
    gDialogState.cutscene = true
    gDialogState.overrideCurrent = false
    gDialogState.cutsceneDistToCamera = 0
end

--- @param npc Object
function start_dialog(dialogId, npc, cutscene, overrideCurrent, distToCamera)
    if gDialogState.currentDialog ~= nil then return end

    if overrideCurrent then
        end_custom_cutscene()
    end
    gDialogState.currentDialog = gDialogs[dialogId]
    gDialogState.npc = npc
    gDialogState.cutscene = cutscene
    gDialogState.overrideCurrent = overrideCurrent
    gDialogState.cutsceneDistToCamera = distToCamera
    set_prev_cam_pos_and_focus()
end

function end_dialog()
    local oldId = 0
    if gDialogState.currentDialog ~= nil then
        oldId = gDialogState.currentDialog.id
    end

    if gDialogState.cutscene then end_custom_cutscene() end
    reset_dialog_state()
    if gMarioStates[0].action == ACT_CUTSCENE then
        set_mario_action(gMarioStates[0], ACT_IDLE, 0)
    end

    if oldId == 5 then
        local apparition = obj_get_first_with_behavior_id(id_bhvApparition)
        if apparition ~= nil then
            apparition.oAction = 100
            network_send_object(apparition, true)
        end
    end
end

--- @param o Object
local function bhv_dialog_trigger_init(o)
    if gGlobalSyncTable.stars > 0 then
        obj_mark_for_deletion(o)
        return
    end

    network_init_object(o, false, {})
end

--- @param o Object
local function bhv_dialog_trigger_loop(o)
    if dist_between_objects(o, gMarioStates[0].marioObj) < 600 then
        local npc = get_npc_with_id(max(o.oBehParams >> 24, 1))
        if npc ~= nil and npc.oNpcTalkingTo < 0 then
            npc.oNpcTalkingTo = gNetworkPlayers[0].globalIndex
            npc.oDialogId = max(o.oBehParams2ndByte, 1)
            obj_mark_for_deletion(o)
        end
    end
end

id_bhvDialogTrigger = hook_behavior(nil, OBJ_LIST_LEVEL, true, bhv_dialog_trigger_init, bhv_dialog_trigger_loop)