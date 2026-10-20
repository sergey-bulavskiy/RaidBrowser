-- Offline check: the "Raidset saved" message must not fail without GearScoreLite (gs == nil).
local printed = {}
local function frame() local o = {}; return setmetatable(o, { __index = function() return function() return frame() end end }) end
CreateFrame = frame
LFRBrowseFrame = frame()
RaidBrowserRaidSetMenu = frame()
RaidBrowserRaidSetMenuButton = frame()
RaidBrowserRaidSetSaveButton = frame()
UIDropDownMenu_SetWidth, UIDropDownMenu_SetText, UIDropDownMenu_Initialize, ToggleDropDownMenu = function() end, function() end, function() end, function() end
EasyMenu_Initialize = function() end

local addon = { gui = { raidset = {} }, stats = {} }
function addon:Print(text) printed[#printed + 1] = text end
RaidBrowser = addon
RaidBrowserCharacterCurrentRaidset = 'Primary'

local current = { 'Holy Paladin', nil }
RaidBrowser.stats.get_raidset = function() return nil end
RaidBrowser.stats.save_primary_raidset = function() end
RaidBrowser.stats.save_secondary_raidset = function() end
RaidBrowser.stats.current_raidset = function() return current[1], current[2] end

dofile('RaidBrowser/raidset_frame.lua')
RaidBrowser.gui.raidset.initialize()

for _, case in ipairs({ { 'Holy Paladin', nil }, { 'Holy Paladin', 5700 } }) do
	current = case
	local ok, err = pcall(RaidBrowser.gui.raidset.save)
	print((ok and 'ok   ' or 'FAIL ') .. (printed[#printed] or err))
end
