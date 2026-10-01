-- Dropdown under the raid set menu that filters the list by raid type (same names as the Raid column).
local ALL_RAIDS = 'All raids';

local frame = CreateFrame('Frame', 'RaidBrowserRaidFilterMenu', LFRBrowseFrame, 'UIDropDownMenuTemplate')
UIDropDownMenu_SetWidth(frame, 150)
frame:SetPoint('TOPLEFT', RaidBrowserRaidSetMenu, 'BOTTOMLEFT', 0, 14)

local function refresh_text()
	UIDropDownMenu_SetText(frame, RaidBrowser.gui.get_raid_filter() or ALL_RAIDS)
end

---@param _ any
---@param raid_name string?
local function on_select(_, raid_name)
	RaidBrowser.gui.set_raid_filter(raid_name)
	refresh_text()
end

-- The menu is rebuilt every time it opens, so it lists the raids that are in the list right now.
local function initialize(_, level)
	local selected = RaidBrowser.gui.get_raid_filter()

	local info = {}
	info.text = ALL_RAIDS
	info.arg1 = nil
	info.func = on_select
	info.checked = selected == nil
	UIDropDownMenu_AddButton(info, level)

	local names = RaidBrowser.gui.available_raid_names()

	-- Keep the selected raid in the menu even if nobody advertises it right now.
	if selected then
		local found = false
		for _, name in ipairs(names) do
			if name == selected then found = true end
		end

		if not found then
			table.insert(names, selected)
			table.sort(names)
		end
	end

	for _, name in ipairs(names) do
		info = {}
		info.text = name
		info.arg1 = name
		info.func = on_select
		info.checked = selected == name
		UIDropDownMenu_AddButton(info, level)
	end
end

UIDropDownMenu_Initialize(frame, initialize)
refresh_text()
