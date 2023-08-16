--- @class Dialog
--- @field public id integer -- ID of the dialog
--- @field public nameEnglish string -- Name of the thing speaking in English
--- @field public nameSpanish string -- Name of the thing speaking in Spanish
--- @field public nameFrench string -- Name of the thing speaking in French
--- @field public linesEnglish string[] -- Dialog lines in English
--- @field public linesSpanish string[] -- Dialog lines in Spanish
--- @field public linesFrench string[] -- Dialog lines in French...
--- @field public specialLineEnglish integer -- A line that cutscenes can read to trigger events
--- @field public specialLineSpanish integer -- A line that cutscenes can read to trigger events
--- @field public specialLineFrench integer -- A line that cutscenes can read to trigger events
--- @field public speed number -- How many frames it takes to push a new character

--- @class DialogState
--- @field public currentDialog Dialog -- Current dialog that stores important information such as the lines
--- @field public currentLine integer -- Current line that is being shown
--- @field public currentChar integer -- Current character index in the line
--- @field public currentLineContents string -- What gets printed to the screen, characters are pushed to this string
--- @field public canProceed boolean -- Can proceed to the next dialog
--- @field public skip boolean -- Can skip all of the characters being pushed, set to true when you press B
--- @field public npc Object -- Object for the dialog cutscene to show
--- @field public dialogTimer integer -- How many frames the dialog has been shown for
--- @field public cutscene boolean -- Use dialog cutscene
--- @field public overrideCurrent boolean -- Override current dialog
--- @field public cutsceneDistToCamera number -- How many units the camera should be away from `npc`

--- @type Dialog[]
gDialogs = {
    {
        id = 1,
        nameEnglish = "Old Man",
        nameSpanish = "Anciano",
        nameFrench = "Vieil Homme",
        linesEnglish = {
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
        linesSpanish = {
            "Hey tu! Viajero!",
            "Espera... Ese bigote, esos ojos...",
            "Olvídalo. No se quien eres.",
            "Como sea, Veo que caíste de la     superficie...",
            "He estado atrapado en este lugar porun muy largo tiempo.",
            "Pero he descubierto una manera en laque podriamos salir de aquí.",
            "Creo que lo que pasó fue una cosa  de solo una vez en la vida.",
            "El Castillo simplemente se levantó del piso, no?",
            "Debe significar algo...",
            "Como sea, Si vamos a salir de aquí,tendrás que ayudarme.",
            "Explora este Submundo, obtén     todas las Estrellas Anímicas.",
            "Una vez hayas hecho eso, vuelve a   mi."
        },
        linesFrench = {
            "Hé, toi! Voyageur!",
            "Attends.. Cette moustache, ces yeux...",
            "Laisse tomber. Je ne te connais pas.",
            "Bref, je vois que tu viens de la surface.",
            "Je suis coincé dans cet endroit depuis  très longtemps.",
            "Mais j'ai découvert un moyen de nous    échapper.",
            "Enfin, le château vient de sortir du    sol, non?",
            "Ça veut forcément dire quelque chose.",
            "Explore le Monde Souterrain, et collecte toutes les étoiles d'âme.",
            "Reviens me voir une fois que tu auras    fini."
        },
        specialLineEnglish = 0,
        specialLineSpanish = 0,
        specialLineFrench = 0,
        speed = 1
    },
    {
        id = 2,
        nameEnglish = "Old Man",
        nameSpanish = "Anciano",
        nameFrench = "Vieil Homme",
        linesEnglish = {
            "What are you doing standing around?",
            "You have to collect $STARS."
        },
        linesSpanish = {
            "Que haces ahí parado?",
            "Tienes que recolectar $STARS."
        },
        linesFrench = {
            "Qu'est-ce que tu fais à rester planter  ici?",
            "Tu dois collecter $STARS."
        },
        specialLineEnglish = 0,
        specialLineSpanish = 0,
        specialLineFrench = 0,
        speed = 1
    },
    {
        id = 3,
        nameEnglish = "Old Man",
        nameSpanish = "Anciano",
        nameFrench = "Vieil Homme",
        linesEnglish = {
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
            "Heh.",
            "See you never."
        },
        linesSpanish = {
            "Jejeje. Veo que has recolectado     todas las Estrellas Anímicas.",
            "Bien hecho, $CHARNAME.",
            "Puedo sentir el poder de las        estrellas...",
            "En cuanto a ti, tu ya no sirves paraningun propósito.",
            "Tu ya has cumplido, así que ahora  me desharé de tí.",
            "Jejeje. Adios, $CHARNAME.",
            "Wow... No puedo creer que realmente caíste por mi fachada.",
            "Quieres saber la verdad ahora que   eres inutil?",
            "Hace mucho tiempo atrás, yo era el troll más grande de la tierra.",
            "Y un día, Descubrí un poder       antiguo para manipular el.",
            "Ruido.",
            "Empecé a terrorizar al mundo con este nuevo poder.",
            "Pero por supuesto, Me encontré una oposición.",
            "6 héroes, la gente bajo el título de Los Moderadores.",
            "Estuve forzado a pelear con ellos o estaba muerto.",
            "Di todo lo que tenía, pero         desafortunadamente...",
            "No era suficiente.",
            "Sin embargo, fuí capaz de vencer y destruir a uno de ellos.",
            "Su nombre era Yoshi.",
            "Eso es porqué solo siento 5        descendientes, Je.",
            "Sin Yoshi, sus poderes mágicos se  debilitaron.",
            "Aún así, se las arreglaron para   derrotarme.",
            "Y entonces usaron todo su poder     combinado en mi.",
            "No pude contrarrestarlo. Fuí       sellado.",
            "Desafortunadamente, el sello no era lo suficientemente fuerte.",
            "Sín Yoshi, el sello no podía ser  permanente.",
            "Lentamente se iba desvaneciendo con el tiempo.",
            "Mi poder finalmente fue desatado unavez más.",
            "Separé el castillo del piso usando el Ruido.",
            "Manipular un descendiente siempre   fue mi meta en todo esto.",
            "Sabía que solo ellos eran capaces  de recolectar las Estrellas.",
            "Estas son inobteníbles por una persona normal y te maldicen.",
            "Pero ahora... Obtuviste todas para  mi, como un idiota.",
            "Ahora, si me disculpas, Simplemente tengo que entrar al láser masívo.",
            "Me llevará devuelta al Mundo       exterior.",
            "Estoy seguro que el viaje te rompióla espalda y te dejó inutil.",
            "Je.",
            "Hasta nunca."
        },
        linesFrench = {
            "Heheheh. Je vois que tu as               collecté toutes les étoiles d'âme.",
            "Très bien $CHARNAME.",
            "Je peux ressentir la puissance des       étoiles...",
            "Et toi, tu ne sers plus à rien          désormais.",
            "Tu as rempli ton objectif alors          maintenant je vais me débarasser de toi.",
            "Heheheh. Adieu, $CHARNAME.",
            "Wow.. J'ai du mal à croire que tu sois  vraiment tombé dans le panneau.",
            "Tu veux connaître la vérité maintenantque tu es inutile?",
            "Il y a très longtemps, j'étais le      meilleur des trolls dans le royaume.",
            "Et un jour, j'ai découvert un pouvoir   ancien que je pouvais exploiter.",
            "Le Bruitage.",
            "J'ai commencé à terroriser le royaume  avec ce nouveau pouvoir.",
            "Mais forcément, des gens se sont        opposés à moi.",
            "6 héros, dénommés Les Modérateurs.",
            "J'étais obligé de les combattre sinon  ils allaient me tuer.",
            "J'ai fait tout ce que j'ai pu, mais      malheureusement...",
            "Ça n'a pas suffi.",
            "En revanche, j'ai pu vaincre et détruirel'un d'entre eux.",
            "Son nom était Yoshi.",
            "C'est pour ça que je ne ressens plus que5 descendants, heh.",
            "Sans Yoshi, leur magie était plus       faible.",
            "Malgré ça, ils ont réussi à          m'épuiser.",
            "Et ensuite ils ont combiné leurs        pouvoirs contre moi.",
            "J'étais incapable de résister. Ils     m'ont scellé.",
            "Malheureusement pour eux, le sceau       n'était pas assez puissant.",
            "Sans Yoshi, la sceau ne pouvait pas êtrerendu permanent.",
            "Au fil du temps, il s'est affaibli.",
            "Ma puissance était enfin libérée à   nouveau.",
            "J'ai élevé le château en utilisant le Bruitage.",
            "Piéger un descendant ici était mon     objectif pendant tout ce temps.",
            "Je savais que seuls eux auraient été   capables de collecter les étoiles.",
            "Les étoiles d'âmes ne peuvent pas êtreobtenues par les maudits et les normaux.",
            "Mais maintenant.. Tu les as récupéréespour moi, tel un idiot.",
            "Si ça ne te dérange pas, je dois juste aller au grand laser.",
            "Il me permettra de revenir à la surface.",
            "Je suis certain que ce jet a brisé ton  dos et t'a rendu inutile.",
            "Heh.",
            "Qu'on ne se revoie jamais."
        },
        specialLineEnglish = 6,
        specialLineSpanish = 6,
        specialLineFrench = 6,
        speed = 0.5
    },
    {
        id = 4,
        nameEnglish = "The Shitilizer",
        nameSpanish = "El Shitilizer",
        nameFrench = "Le Shitilizer",
        linesEnglish = {
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
        linesSpanish = {
            "Maldita peste...",
            "Alguna vez te rindes? Porqué tengo que seguir aguantandote?.",
            "Casi estás tarde...",
            "Casi termino de corromper el Patio  trasero del Castillo con mi ruido.",
            "Estar ahí te va a matar lentamente.",
            "Haré lo mismo con todo el Reino    Champiñón",
            "Va a ser destruido y hecho ruinas   una vez mi ruido lo alcance.",
            "Y tú...",
            "Tú no vas a detenerme en mi        conquista.",
            "Voy a terminar lo que inicié hace  mucho tiempo...",
            "Con nadie en mi camino esta vez.",
            "Considerate suertudo, ya que no he  alcanzado todo mi poder aún.",
            "Finalmente voy a tener mi venganza  en ustedes...",
            "Los descendientes de aquellos que   alguna vez me sellaron.",
            "Nos vemos, $CHARNAME."
        },
        linesFrench = {
            "Espèce de sale peste..",
            "Tu n'abandonneras donc jamais?",
            "C'est presque trop tard.",
            "J'ai quasiment fini de corrompre la cour du château avec mon bruitage.",
            "Marcher dessus te tuera lentement.",
            "Je ferai de même avec le reste du       Royaume Champignon.",
            "Il sera détruit et mis en ruines une    fois que mon bruitage l'aura atteint.",
            "Et toi...",
            "Tu ne m'arrêteras pas dans ma conquête.",
            "Je vais terminer ce que j'ai commencé   depuis longtemps.",
            "Sans que personne ne se mette au travers de mon chemin cette fois.",
            "Estime-toi chanceux que je n'aie pas     encore atteint ma puissance maximale.",
            "Je vais enfin avoir ma revanche sur vous tous...",
            "Les descendants de ceux qui m'ont scellé",
            "Adieu, $CHARNAME."
        },
        specialLineEnglish = 0,
        specialLineSpanish = 0,
        specialLineFrench = 0,
        speed = 0.5
    },
    {
        id = 5,
        nameEnglish = "The Shitilizer",
        nameSpanish = "El Shitilizer",
        nameFrench = "Le Shitilizer",
        linesEnglish = {
            "NO! THIS CANNOT BE!",
            "Curse myself! I knew I should have  ended you in the Underworld.",
            "I underestimated you $CHARNAME. A       mistake I will never make again.",
            "It won't be like this next time...",
            "I'll be back, and stronger than     ever."
        },
        linesSpanish = {
            "¡NO! ¡ESTO NO PUEDE SER!",
            "¡Maldición! Sabía que te tuve quehaber exterminado en el Submundo.",
            "Te subestimé $CHARNAME. Un error que nunca jamás volveré a hacer.",
            "No será de esta manera la próxima vez...",
            "Volveré, y más fuerte que nunca."
        },
        linesFrench = {
            "NON! C'EST IMPOSSIBLE!",
            "J'aurais dû te tuer dans le Monde Souterrain.",
            "Je t'ai sous-estimé $CHARNAME. Une erreur   que je ne commettrai plus jamais.",
            "Je sais que je peux tous vous éliminer, j'ai tué un ancêtre.",
            "Ça ne se passera pas comme ça la       prochaine fois...",
            "Je reviendrai, plus fort que jamais."
        },
        specialLineEnglish = 0,
        specialLineSpanish = 0,
        specialLineFrench = 0,
        speed = 2
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
local set_mario_action,obj_get_first_with_behavior_id,obj_mark_for_deletion,dist_between_objects,max,djui_hud_set_resolution,djui_hud_get_screen_height,minf,djui_hud_set_color,djui_hud_render_rect,audio_sample_play,djui_hud_print_text,play_sound,smlua_text_utils_dialog_replace = set_mario_action,obj_get_first_with_behavior_id,obj_mark_for_deletion,dist_between_objects,max,djui_hud_set_resolution,djui_hud_get_screen_height,minf,djui_hud_set_color,djui_hud_render_rect,audio_sample_play,djui_hud_print_text,play_sound,smlua_text_utils_dialog_replace

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


function handle_special_words(string)
    local starsLeft = STARS - gGlobalSyncTable.stars

    return string
        :gsub("$CHARNAME", gMarioStates[0].character.name)
        :gsub("$STARS", starsLeft .. " " .. XLANG(TEXT_STAR) .. if_then_else(starsLeft == 1, "", "s"))
end

function hud_render_dialog()
    djui_hud_set_resolution(RESOLUTION_N64)

    local height = djui_hud_get_screen_height()

    if gDialogState.currentDialog ~= nil then
        local lines = gDialogState.currentDialog["lines" .. get_language()] or gDialogState.currentDialog.linesEnglish

        if gDialogState.npc ~= nil and gDialogState.cutscene and not gCustomCutscene.playing then
            start_custom_cutscene_generic(
                gDialogState.npc.oPosX + sins(gDialogState.npc.header.gfx.angle.y) * gDialogState.cutsceneDistToCamera,
                gDialogState.npc.oPosY + 200,
                gDialogState.npc.oPosZ + coss(gDialogState.npc.header.gfx.angle.y) * gDialogState.cutsceneDistToCamera,
                gDialogState.npc.oPosX,
                gDialogState.npc.oPosY + 100,
                gDialogState.npc.oPosZ,
                25,
                false,
                gDialogState.overrideCurrent
            )
        end
        gDialogState.dialogTimer = gDialogState.dialogTimer + 1

        local alphaNormalized = minf(gDialogState.dialogTimer / 15, 1)
        djui_hud_set_color(0, 0, 0, alphaNormalized * 127)
        djui_hud_render_rect(6, height - 55, 200, 50)

        local pos = { x = gLakituState.pos.x + sins(gLakituState.yaw), y = gLakituState.pos.y, z = gLakituState.pos.z + coss(gLakituState.yaw) }

        if gDialogState.skip then
            gDialogState.currentLineContents = handle_special_words(lines[gDialogState.currentLine])
            gDialogState.canProceed = true
        else
            for _ = 1, get_factor(gDialogState.currentDialog.speed) do
                if gDialogState.dialogTimer % gDialogState.currentDialog.speed == 0 then
                    if gDialogState.currentChar <= #handle_special_words(lines[gDialogState.currentLine]) then
                        local char = handle_special_words(lines[gDialogState.currentLine]):sub(gDialogState.currentChar, gDialogState.currentChar)
                        gDialogState.currentLineContents = gDialogState.currentLineContents .. char
                        gDialogState.currentChar = gDialogState.currentChar + 1

                        if char ~= " " then
                            audio_sample_play(SOUND_CUSTOM_APPARITION_DIALOG, pos, 0.8)
                        end
                    else
                        gDialogState.canProceed = true
                    end
                end
            end
        end

        local french = get_language() == "French"
        local scale = if_then_else(french, 0.9, 1)
        local split = if_then_else(french, 41, 36)
        local multiplier = if_then_else(french, 0.97, 1)
        local splitLines = split_string(gDialogState.currentLineContents, split)
        if splitLines ~= nil and splitLines[1] ~= nil then
            djui_hud_set_color(255, 255, 255, alphaNormalized * 255)

            if gDialogState.currentDialog.id == 3 and gDialogState.currentLine >= 6 then
                djui_hud_print_text(XLANG(TEXT_SHITILIZER), 10, height - 70, 1)
            else
                djui_hud_print_text(gDialogState.currentDialog["name" .. get_language()], 10, height - 70, 1)
            end

            if splitLines[2] == nil then
                djui_hud_print_text(gDialogState.currentLineContents, 10, height - 37 * multiplier, scale)
            else
                djui_hud_print_text(splitLines[1], 10, height - 47 * multiplier, scale)
                djui_hud_print_text(splitLines[2], 10, height - 33 * multiplier, scale)
            end
        end

        if gDialogState.canProceed then
            djui_hud_set_color(255, 255, 255, (math.sin(gDialogState.dialogTimer * 0.3) * 127.5) + 127.5)
            djui_hud_print_text("[A]", 185, height - 23, 1)

            if (gMarioStates[0].controller.buttonPressed & (A_BUTTON | B_BUTTON)) ~= 0 then
                play_sound(SOUND_MENU_MESSAGE_NEXT_PAGE, gMarioStates[0].marioObj.header.gfx.cameraToObject)
                if (gMarioStates[0].controller.buttonPressed & B_BUTTON) ~= 0 then
                    audio_sample_play(SOUND_CUSTOM_APPARITION_DIALOG, pos, 0.8)
                    gDialogState.skip = true
                else
                    gDialogState.skip = false
                end

                gDialogState.currentLine = gDialogState.currentLine + 1
                if gDialogState.currentLine > #lines then
                    end_dialog()
                else
                    reset_dialog_line()
                end
            end
        end
    end
end

smlua_text_utils_dialog_replace(DIALOG_000, 1, 1, 1, 200, "Sex in Minecraft")