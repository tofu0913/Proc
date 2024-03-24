_addon.name = 'Proc'
_addon.author = 'Cliff'
_addon.version = '0.0.1'

require('chat')
require('logger')
require('coroutine')

require('lor/lor_utils')
_libs.lor.req('all')
_libs.lor.debug = false
settings = _libs.lor.settings.load('data/settings.lua', {})

local curSet = 0
local curLv = 0
local fumeCheck = 0
local killmode = 0

local function check_fume()
    if killmode == 1 then
        return
    end
    fumeCheck = fumeCheck +1
    if (curLv == 0 and fumeCheck > 40) or 
       (curLv < 3 and fumeCheck > 80) or 
        (curLv ==3 and fumeCheck> 200) then
        windower.send_command('input /fume')
        curSet = 38
        windower.send_command(string.format('input /equipset %s;wait 1;input //lua r autows;wait 1;input //aws on', curSet))
        curLv = 0
        fumeCheck = 0
    end
    coroutine.schedule(check_fume, 2)
end

windower.register_event('incoming text', function(_, text, _, _, blocked)
    if blocked or text == '' then
        return
    end

    if string.find(text, settings["start"]) then
       atcf(262, "Proc start")
       curSet = 38
       windower.send_command(string.format('input /equipset %s;wait 1;input //lua r autows;wait 1;input //aws on', curSet))
       curLv = 0
       fumeCheck = 0
        killmode = 0
       -- coroutine.schedule(check_fume, 2)
        
    elseif string.find(text, settings["proced"]) then
       atcf(262, "Proc gotcha!")
       curLv = 0
       curSet = 0
       fumeCheck = 0
       windower.send_command(string.format('input /equipset %s;wait 1;input //lua r autows;wait 1;input //aws on', 38))
        
    elseif string.find(text, settings["max"]) or string.find(text, settings["max2"]) then
        atcf(262, "Proc kill mode")
        windower.send_command(string.format('input /equipset 39;wait 1;input //lua r autows;wait 1;input //aws on'))
        killmode = 1

    else
        if killmode == 1 then
            return
        end
        head = string.find(text, settings["head"])
        tail = string.find(text, settings["tail"])
        if head and tail then
            found = string.sub(text, head+3, tail-1)
            level = 0
            if string.find(text, settings["big"]) then
                level = 3
            elseif string.find(text, settings["mid"]) then
                level = 2
            elseif string.find(text, settings["small"]) then
                level = 1
            end
            atcf(262, "Proc found:%s, level:%s", found, level)
                
            if level > curLv and settings[found] and curSet ~= settings[found] then
                curSet = settings[found]
                curLv = level
                fumeCheck = 0
                windower.send_command(string.format('input /equipset %s;wait 1;input //lua r autows;wait 1;input //aws rnd', settings[found]))
                atcf(262, "Proc target:%s, level:%s", found, level)
            -- elseif level == curLv and curSet == settings[found] then  -- Set again
                -- windower.send_command(string.format('input /equipset %s;wait 1;input //lua r autows;wait 1;input //aws rnd', settings[found]))
                -- atcf(262, "Proc target again:%s, level:%s", found, level)
            end
        end
    end

end)


-- windower.register_event('load', function()
    -- coroutine.schedule(check_fume, 2)
-- end)


