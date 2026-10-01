-- Offline check of RaidBrowser.stats.build_join_message with a stubbed 3.3.5a talent API.
local addon = {}
function addon:Print() end
LibStub = function() return { NewAddon = function() return addon end } end
GetLocale = function() return 'enUS' end
dofile('RaidBrowser/Libs/stdlib/algorithm.lua')
dofile('RaidBrowser/core.lua')

-- saved raidsets drive 'Both'
local active_group = 1
local trees = {
	[1] = { { 'Holy', 0, 'PaladinHoly' }, { 'Protection', 51, 'PaladinProtection' }, { 'Retribution', 20, 'PaladinCombat' } },
	[2] = { { 'Holy', 0, 'PaladinHoly' }, { 'Protection', 5, 'PaladinProtection' }, { 'Retribution', 51, 'PaladinCombat' } },
}
GetActiveTalentGroup = function() return active_group end
GetNumTalentGroups = function() return 2 end
GetTalentTabInfo = function(i, _, _, g) local t = trees[g or active_group][i]; return t[1], '', t[2], t[3] end
GetAchievementInfo = function() return nil, nil, nil, false end
GetAchievementNumCriteria = function() return 0 end
GearScore_GetScore = function() return 5700 end
UnitName = function() return 'me' end
RaidBrowserCharacterRaidsets = { Primary = { spec = 'Protection Paladin', gs = 5700 }, Secondary = { spec = 'Retribution Paladin', gs = 5200 } }

dofile('RaidBrowser/stats.lua')
for _, sel in ipairs({ 'Active', 'Both', 'Primary', 'Secondary' }) do
	RaidBrowserCharacterCurrentRaidset = sel
	print(sel .. ' -> ' .. RaidBrowser.stats.build_join_message('toc25hc'))
end
GearScore_GetScore = nil
RaidBrowserCharacterCurrentRaidset = 'Both'
print('Both, no GearScore -> ' .. RaidBrowser.stats.build_join_message('toc25hc'))
RaidBrowserCharacterRaidsets = { Primary = { spec = 'Protection Paladin', gs = 5700 } }
print('Both, only Primary saved -> ' .. RaidBrowser.stats.build_join_message('toc25hc'))
RaidBrowserCharacterRaidsets = {}
GearScore_GetScore = function() return 5700 end
print('Both, nothing saved -> ' .. RaidBrowser.stats.build_join_message('toc25hc'))
