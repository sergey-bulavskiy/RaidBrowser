-- Offline check of RaidBrowser.display_raid_name.
local addon = {}
function addon:Print() end
LibStub = function() return { NewAddon = function() return addon end } end
dofile('RaidBrowser/Libs/stdlib/algorithm.lua')
dofile('RaidBrowser/core.lua')

for _, m in ipairs({ 'LFM VoA18 need all', 'VOA 18 need ele', 'LFM VOA 25 need all', 'LFM VOA 10 need all', 'LFM voa 25 18/25' }) do
	local info = RaidBrowser.raid_info(m)
	print(string.format('%-24s -> %s (internal %s)', m, info and RaidBrowser.display_raid_name(info, m) or 'MISS', info and info.name or '-'))
end
