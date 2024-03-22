_addon.name = 'Proc'
_addon.author = 'Cliff'
_addon.version = '0.0.1'

require('chat')
require('logger')

require('lor/lor_utils')
_libs.lor.req('all')
_libs.lor.debug = false
settings = _libs.lor.settings.load('data/settings.lua', {})

local curSet = 0

windower.register_event('incoming text', function(_, text, _, _, blocked)
    if blocked or text == '' then
        return
    end

    if string.find(text, settings["keyword"]) then
        tail = string.find(text, settings["tail"])
        if tail and tail > 0 then
            found = string.sub(text, string.find(text, settings["head"])+3, tail-1)
            atcf(262, "found:%s.", found)
            if settings[found] and curSet ~= settings[found] then
                curSet = settings[found]
                windower.send_command(string.format('setkey ctrl down;wait 0.5;setkey %s down;wait 0.5;setkey %s up;setkey ctrl up', settings[found], settings[found]))
                atcf(262, "found:%s, ready %s", found, curSet)
            else -- big proc missed, just kill it
                curSet = 0
                windower.send_command(string.format('setkey alt down;wait 0.5;setkey 2 down;wait 0.5;setkey 2 up;setkey alt up'))
            end
        end
    end

end)

-- windower.register_event('load', function()
    -- windower.send_command(string.format('setkey ctrl down;wait 0.5;setkey %s down;wait 0.5;setkey %s up;setkey ctrl up', 2, 2))
-- end)