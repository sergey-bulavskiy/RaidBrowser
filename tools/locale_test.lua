-- Offline check: stats.lua must load (and define raid_lock_info) on a non-English client, with the shipped library.
local mode = arg[1] or 'with-lib'
GetLocale = function() return 'ruRU' end
strmatch, strfind, format, strsub, strlen, strlower = string.match, string.find, string.format, string.sub, string.len, string.lower
geterrorhandler = function() return print end
local addon = {}
function addon:Print() end
dofile('RaidBrowser/Libs/LibStub/LibStub.lua')
if mode == 'with-lib' then
	dofile('RaidBrowser/Libs/LibBabble-3.0/LibBabble-3.0.lua')
	dofile('RaidBrowser/Libs/LibBabble-3.0/LibBabble-Zone-3.0.lua')
end
RaidBrowser = addon
dofile('RaidBrowser/Libs/stdlib/algorithm.lua')
GetNumSavedInstances = function() return 1 end
local saved_name = 'Icecrown Citadel'
if mode == 'with-lib' then saved_name = LibStub('LibBabble-Zone-3.0'):GetUnstrictLookupTable()['Icecrown Citadel'] end
print('client name of Icecrown Citadel: ' .. tostring(saved_name))
GetSavedInstanceInfo = function() return saved_name, nil, 100, nil, true, nil, nil, nil, 10 end
dofile('RaidBrowser/stats.lua')
print(mode .. ': raid_lock_info is ' .. type(RaidBrowser.stats.raid_lock_info))
if mode == 'with-lib' then
	print('Icecrown Citadel 10 locked -> ' .. tostring((RaidBrowser.stats.raid_lock_info({ instance_name = 'Icecrown Citadel', size = 10 }))))
end
