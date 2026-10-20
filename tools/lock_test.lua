-- Offline check of the lockout lookup: normal and heroic must not be mixed up (stubbed saved instances).
GetLocale = function() return 'enUS' end
local addon = {}
function addon:Print() end
LibStub = function() return {} end
RaidBrowser = addon
dofile('RaidBrowser/Libs/stdlib/algorithm.lua')

local saved = {}
GetNumSavedInstances = function() return #saved end
GetSavedInstanceInfo = function(i) local s = saved[i]; return s.name, 1, 1000, s.difficulty, true, false, 0, true, s.size end
dofile('RaidBrowser/stats.lua')

local function raid(name, instance, size) return { name = name, instance_name = instance, size = size } end
local TOC, ICC = 'Trial of the Crusader', 'Icecrown Citadel'
local checks = {
	{ 'toc25nm', TOC, 25 }, { 'toc25hc', TOC, 25 }, { 'toc10nm', TOC, 10 }, { 'toc10hc', TOC, 10 },
	{ 'icc25nm', ICC, 25 }, { 'icc10hc', ICC, 10 }, { 'icc10wq', ICC, 10 }, { 'icc10rep', ICC, 10 },
}
local function run(title, instances)
	saved = instances
	local out = {}
	for _, c in ipairs(checks) do
		local locked = RaidBrowser.stats.raid_lock_info(raid(c[1], c[2], c[3]))
		if locked then out[#out + 1] = c[1] end
	end
	print(string.format('%-34s -> locked: %s', title, #out > 0 and table.concat(out, ' ') or '-'))
end

run('saved: nothing', {})
run('saved: ToC 25 heroic', { { name = TOC, size = 25, difficulty = 4 } })
run('saved: ToC 25 normal', { { name = TOC, size = 25, difficulty = 2 } })
run('saved: ToC 10 heroic', { { name = TOC, size = 10, difficulty = 3 } })
run('saved: ToC 10 normal', { { name = TOC, size = 10, difficulty = 1 } })
run('saved: ICC 10 heroic', { { name = ICC, size = 10, difficulty = 3 } })
run('saved: ICC 10 normal', { { name = ICC, size = 10, difficulty = 1 } })
