-- Offline check of starred ("pinned") messages in gui.lua, with WoW frames stubbed out.
local stub = setmetatable({}, {})
getmetatable(stub).__index = function(t, k) if k == 'GetNumPoints' then return function() return 0 end end return t end
getmetatable(stub).__call = function(t) return t end
getmetatable(stub).__concat = function(a, b) return 'x' end
setmetatable(_G, { __index = function(_, k) if k ~= 'RaidBrowserCharacterHideSaved' then return stub end end })
NUM_LFR_LIST_BUTTONS = 19
RaidBrowser = { gui = {}, stats = { raid_lock_info = function() return false end }, lfm_messages = {} }
dofile('RaidBrowser/gui.lua')

local function msg(sender, raid, text, t)
	return { sender = sender, raid_info = { name = raid }, message = text, roles = { 'dps' }, gs = ' ', time = t }
end
local function names()
	local out = {}
	for _, m in ipairs(RaidBrowser.gui.get_sorted_messages()) do out[#out + 1] = m.sender .. ':' .. m.raid_info.name .. ':' .. m.message end
	return table.concat(out, ' | ')
end

local star_me = msg('Bob', 'toc25nm', 'LFM TOC 25 need all', 0)
RaidBrowser.lfm_messages = { Alice = msg('Alice', 'voa25', 'LFM VOA', 0), Bob = star_me, Carl = msg('Carl', 'icc10nm', 'LFM ICC', 0) }
print('1 before star : ' .. names())
RaidBrowser.gui.toggle_star(star_me)
print('2 starred first: ' .. names())

RaidBrowser.lfm_messages.Bob = msg('Bob', 'toc25nm', 'LFM TOC 25 need healers', 50)
print('3 reworded    : ' .. names())

RaidBrowser.lfm_messages.Bob = nil
print('4 expired     : ' .. names())

RaidBrowser.lfm_messages.Bob = msg('Bob', 'voa25', 'LFM VOA now', 70)
print('5 other raid  : ' .. names())

RaidBrowser.gui.toggle_star(star_me)
RaidBrowser.lfm_messages.Bob = nil
print('6 unstarred   : ' .. names())

-- Roles follow the newest message of a pinned sender+raid
RaidBrowser.lfm_messages = {}
local first = msg('Dan', 'toc25nm', 'LFM TOC 25 need tank', 0); first.roles = { 'tank' }
RaidBrowser.lfm_messages.Dan = first
RaidBrowser.gui.toggle_star(first)
local second = msg('Dan', 'toc25nm', 'LFM TOC 25 need healers and dps', 40); second.roles = { 'healer', 'dps' }
RaidBrowser.lfm_messages.Dan = second
local shown = RaidBrowser.gui.get_sorted_messages()[1]
print('7 roles live  : ' .. table.concat(shown.roles, ','))
RaidBrowser.lfm_messages.Dan = nil
print('8 roles after expiry: ' .. table.concat(RaidBrowser.gui.get_sorted_messages()[1].roles, ','))
RaidBrowser.gui.toggle_star(second)
