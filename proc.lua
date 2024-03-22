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

local function check_fume()
    if curLv == 0 then
        windower.send_command('input /fume')
    end
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
        coroutine.schedule(check_fume, 90)
        
    elseif string.find(text, settings["proced"]) then
       atcf(262, "Proc gotcha!")
       curLv = 0
        
    else
        head = string.find(text, settings["head"])
        tail = string.find(text, settings["tail"])
        if head and tail then
            found = string.sub(text, head+3, tail-1)
            if string.find(text, settings["big"]) then
                level = 3
            elseif string.find(text, settings["mid"]) then
                level = 2
            elseif string.find(text, settings["small"]) then
                level = 1
            end
            -- atcf(262, "Proc found:%s, level:%s", found, level)
                
            if level > curLv and settings[found] and curSet ~= settings[found] then
                curSet = settings[found]
                curLv = level
                windower.send_command(string.format('input /equipset %s;wait 1;input //lua r autows;wait 1;input //aws rnd', settings[found]))
                atcf(262, "Proc target:%s, level:%s", found, level)
            end
        end
    end

end)

-- windower.register_event('load', function()
       -- windower.send_command(string.format('input /equipset 39;wait 1;input //lua r autows;wait 1;input //aws on'))
-- end)


