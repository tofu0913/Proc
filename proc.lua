_addon.name = 'Proc'
_addon.author = 'Cliff'
_addon.version = '1.0.0'

require('chat')
require('logger')
-- require('coroutine')
texts = require 'texts'

require('lor/lor_utils')
_libs.lor.req('all')
_libs.lor.debug = false
settings = _libs.lor.settings.load('data/settings.lua', {})

text_box = texts.new(settings['textBox'])

local enable = false
local showLog = true
local autowsDelay = 2

local mode = nil -- nil(waiting), kill, procing
local confirming = nil
local queue = {}
local blist = {}

local function proclog(str)
    if showLog then
        atcf(262, str)
    end
end

local function parseProc(text, tail)
    head = string.find(text, settings["head"])
    if head and tail then
        return string.sub(text, head+3, tail-1)
    end
    return nil
end

local function parseLevel(text, tail)
    level = 0
    if string.find(text, settings["big"]) then
        level = 3
    elseif string.find(text, settings["mid"]) then
        level = 2
    elseif string.find(text, settings["small"]) then
        level = 1
    end
    return level
end

local function actionToItem(action, typ, confirm)
    items = {}
    for k, v in pairs(action["action"]) do
        item = {}
        if action["eqset"] ~= nil then
            item["eqset"] = action["eqset"]
        end
        item["confirm"] = confirm
        item["action"] = v
        item["type"] = typ
        items[#items+1] = item
    end
    return items
end

local function mergeTable(t1, t2)
    local t3 = {unpack(t1)}
    for I = 1,#t2 do
        t3[#t1+I] = t2[I]
    end
    return t3
end

function DisplayBox()

    new_text = 
        "[Queue] ".. (tostring(#queue)) .. "    " .. "[Mode] ".. (tostring(mode)) 
    text_box:text(new_text)
    text_box:visible(true)

end

windower.register_event('incoming text', function(_, text, _, _, blocked)
    if blocked or text == '' or enable == false then
        return
    end

    if confirming and string.find(text, confirming, 1, true) ~= nil then
        if string.find(text, settings["miss"]) == nil then
            proclog("Proc confirmed, %s, q:%s":format(confirming ,#queue))
            confirming = nil
            table.remove(queue, 1)
            if mode ~= "kill" and #queue == 0 then
                mode = nil
                DisplayBox()
            end
        end
    end

    if string.find(text, settings["start"]) then
        proclog("Proc start")
        mode = nil
        blist = {}
        queue = {}
        DisplayBox()
        
    elseif string.find(text, settings["proced"]) then
        proclog("Proc gotcha!")
        if mode ~= "kill" then 
            mode = nil
        end
        blist = {}
        queue = {}
        DisplayBox()
        
    elseif string.find(text, settings["max"]) or string.find(text, settings["max2"]) then
        proclog("Proc kill mode")
        mode = "kill"
        DisplayBox()

    else
        if mode == "kill" then
            return
        end
        for k, v in pairs(settings["procs"]) do
            kw = string.find(text, v["kw"])
            if kw then
                typ = parseProc(text, kw)
                if typ then
                    level = parseLevel(text)
                    if v["actions"][typ] and not blist[typ] then
                        mode = "procing"
                        if level == 3 or k ~= "ws" then
                            queue = mergeTable(actionToItem(v["actions"][typ], k, v["confirm"]), queue)
                            -- proclog("Proc insert")
                        else
                            queue = mergeTable(queue, actionToItem(v["actions"][typ], k, v["confirm"]))
                        end
                        blist[typ] = {}
                        proclog("Proc typ:%s, q:%s":format(typ ,#queue))
                        DisplayBox()
                    end
                end
            end
        end
    end

end)


local function launchProc(item)

    if item["type"] == "ws" then
        confirming = item["action"] .. item["confirm"]
        -- proclog(('input /ws %s <t>, waiting %s'):format(item["action"], confirming))
        windower.send_command(('input /ws %s <t>'):format(item["action"]))
        
    elseif item["type"] == "bma" then
        confirming = item["action"] .. item["confirm"]
        -- proclog(('input /ma %s <t>, waiting %s'):format(item["action"], confirming))
        windower.send_command(('input /ma %s <t>'):format(item["action"]))

    elseif item["type"] == "ja" then
        confirming = item["action"]
        -- proclog(('input /ma %s <t>, waiting %s'):format(item["action"], confirming))
        windower.send_command(('input /ja %s <t>'):format(item["action"]))
    end
end

local function makesureEq(item)
    local items = windower.ffxi.get_items()
    local i,bag = items.equipment.main, items.equipment.main_bag
    skill = res.skills[res.items[items['wardrobe2'][i].id].skill].en
    if item['en'] ~= skill then
        windower.send_command(string.format('input /equipset %s;', item['eqset']))
        return 0
    end
    return 1
end

windower.register_event('prerender', function()
    if enable == true then
		local now = os.clock()
        if (now - autowsLastCheck) >= autowsDelay then
			local player = windower.ffxi.get_player()
			if (player ~= nil) and (player.status == 1) then
                if mode == "kill" then
                    item = settings['killmode']
                    if makesureEq(item) and player.vitals.tp > 999 then
                        launchProc(item)
                    end
                elseif mode == nil then
                    item = settings['zergmode']
                    if makesureEq(item) and player.vitals.tp > 999 then
                        launchProc(item)
                    end
                else
                    if #queue>0 then
                        item = queue[1]
                        if item["type"] == "ws" then
                            if makesureEq(item) and player.vitals.tp > 999 then
                                launchProc(item)
                            end
                        elseif item["type"] == "bma" then
                            launchProc(item)
                        elseif item["type"] == "ja" then
                            if makesureEq(item) then
                                launchProc(item)
                            end
                        end
                    end
                end
            end
			autowsLastCheck = now
        end
    end
end)

windower.register_event('load', function()
    if not _libs.lor then
        windower.add_to_chat(39,'ERROR: .../Windower/addons/libs/lor/ not found! Please download: https://github.com/lorand-ffxi/lor_libs')
    end
    atcf(262, 'Proc loaded')
    autowsLastCheck = os.clock()
    enable = true
end)

windower.register_event('addon command', function(...)
    if #arg == 1 then
        if arg[1]:lower() == 'debug' then
            showLog = not showLog
            atcf(262, 'Proc debug log %s':format(tostring(debug)))

        elseif arg[1]:lower() == 'enable' then
            enable = not enable
            atcf(262, 'Proc enable %s':format(tostring(debug)))

        end
    end
end)
