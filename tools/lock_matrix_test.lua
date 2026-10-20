-- End to end check: adverts -> parser -> lockout, for every combination of saved difficulties.
-- Saved difficulty codes of GetSavedInstanceInfo: 1 = 10 normal, 2 = 25 normal, 3 = 10 heroic, 4 = 25 heroic.
GetLocale = function() return 'enUS' end
local addon = {}
function addon:Print() end
LibStub = function() return { NewAddon = function() return addon end } end
dofile('RaidBrowser/Libs/stdlib/algorithm.lua')
dofile('RaidBrowser/core.lua')

local saved = {}
GetNumSavedInstances = function() return #saved end
GetSavedInstanceInfo = function(i) local s = saved[i]; return s.name, 1, 1000, s.code, true, false, 0, true, (s.code == 1 or s.code == 3) and 10 or 25 end
dofile('RaidBrowser/stats.lua')

-- advert, instance name in the client, expected size, expected heroic (nil = difficulty not part of the advert)
local adverts = {
	{ 'LFM TOC 10 NEED ALL', 'Trial of the Crusader', 10, false },
	{ 'LFM TOC 25 NEED ALL', 'Trial of the Crusader', 25, false },
	{ 'LFM TOC25 (NM) NEED HEALERS', 'Trial of the Crusader', 25, false },
	{ 'LFM TOC 10 HC NEED ALL', 'Trial of the Crusader', 10, true },
	{ 'LFM TOC 25 HC NEED ALL', 'Trial of the Crusader', 25, true },
	{ 'LFM TOGC 10 NEED ALL', 'Trial of the Crusader', 10, true },
	{ 'LFM TOGC 25 NEED ALL', 'Trial of the Crusader', 25, true },
	{ 'LFM TOGC25 NEED ALL', 'Trial of the Crusader', 25, true },
	{ 'LFM TOCG 25 NEED ALL', 'Trial of the Crusader', 25, true },
	-- Heroic is recognised from the achievement alone ...
	{ 'LFM [A Tribute to Mad Skill (25 player)] NEED ALL', 'Trial of the Crusader', 25, true },
	{ 'LFM [A Tribute to Insanity (10 player)] NEED ALL', 'Trial of the Crusader', 10, true },
	{ 'LFM [A Tribute to Immortality] NEED ALL', 'Trial of the Crusader', 25, true },
	{ 'LFM [A Tribute to Dedicated Insanity] NEED ALL', 'Trial of the Crusader', 10, true },
	-- ... and it wins over a raid name given before it
	{ 'LFM TOC 25 NEED ALL [A Tribute to Mad Skill (25 player)]', 'Trial of the Crusader', 25, true },
	{ 'LFM TOC 10 NEED ALL [A Tribute to Insanity (10 player)]', 'Trial of the Crusader', 10, true },
	{ 'LFM TOC 25 NM NEED ALL [A Tribute to Immortality]', 'Trial of the Crusader', 25, true },
	{ 'LFM TOC 25 NEED ALL [Call of the Crusade (25 player)]', 'Trial of the Crusader', 25, false },
	{ 'LFM ICC 10 NM NEED ALL', 'Icecrown Citadel', 10, false },
	{ 'LFM ICC 25 NEED ALL', 'Icecrown Citadel', 25, false },
	{ 'LFM ICC 10 HC NEED ALL', 'Icecrown Citadel', 10, true },
	{ 'LFM ICC 25 HC NEED ALL', 'Icecrown Citadel', 25, true },
	{ 'LFM RS 10 NEED ALL', 'The Ruby Sanctum', 10, false },
	{ 'LFM RS 25 HC NEED ALL', 'The Ruby Sanctum', 25, true },
	{ 'LFM VOA 10 NEED ALL', 'Vault of Archavon', 10, nil },
	{ 'LFM VOA 25 NEED ALL', 'Vault of Archavon', 25, nil },
}

local instances = { 'Trial of the Crusader', 'Icecrown Citadel', 'The Ruby Sanctum', 'Vault of Archavon' }
local failures, checks = 0, 0

for _, a in ipairs(adverts) do
	local info = RaidBrowser.raid_info(a[1])
	if not info then
		print('NOT PARSED: ' .. a[1]); failures = failures + 1
	else
		-- Every subset of the four saved difficulties of the advert's instance
		for mask = 0, 15 do
			saved = {}
			for code = 1, 4 do
				if mask % (2 ^ code) >= 2 ^ (code - 1) then saved[#saved + 1] = { name = a[2], code = code } end
			end
			-- Saves in other instances must never matter
			for _, other in ipairs(instances) do
				if other ~= a[2] then saved[#saved + 1] = { name = other, code = 1 }; saved[#saved + 1] = { name = other, code = 4 } end
			end

			local expected = false
			for _, s in ipairs(saved) do
				if s.name == a[2] then
					local size = (s.code == 1 or s.code == 3) and 10 or 25
					local heroic = s.code >= 3
					if size == a[3] and (a[4] == nil or heroic == a[4]) then expected = true end
				end
			end

			local locked = RaidBrowser.stats.raid_lock_info(info)
			checks = checks + 1
			if locked ~= expected then
				failures = failures + 1
				print(string.format('MISMATCH %-28s (%s) saved mask %2d: got %s expected %s', a[1], info.name, mask, tostring(locked), tostring(expected)))
			end
		end
	end
end

print(string.format('%d checks, %d failures', checks, failures))
