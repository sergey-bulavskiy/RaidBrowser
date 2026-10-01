---@diagnostic disable: undefined-field
RaidBrowser.gui = {}

local search_button = LFRQueueFrameFindGroupButton
local join_button = LFRBrowseFrameInviteButton

local name_column = LFRBrowseFrameColumnHeader1
local gs_list_column = LFRBrowseFrameColumnHeader2
local raid_list_column = LFRBrowseFrameColumnHeader3

local sort_column
local sort_ascending = false

---Order by ascending or descending based on module variable sort_ascending.
---@param a any
---@param b any
---@return boolean
---@nodiscard
local function compare(a, b)
	if sort_ascending then
		return a > b
	else
		return a < b
	end
end

-- Starred ("pinned") messages, keyed by sender and raid, so the star survives the sender repeating or
-- rewording the advert for the same raid. A pinned message is kept in memory (for the session) and stays in
-- the list even after it expires, until the star is removed.
local pinned_messages = {}

---@param info table
---@return string
---@nodiscard
local function star_key(info)
	return info.sender .. '|' .. info.raid_info.name
end

---@param info table
---@return boolean
---@nodiscard
local function is_starred(info)
	return pinned_messages[star_key(info)] ~= nil
end

---@param info table
local function toggle_star(info)
	local key = star_key(info)
	if pinned_messages[key] then
		pinned_messages[key] = nil
	else
		pinned_messages[key] = info
	end
end
RaidBrowser.gui.toggle_star = toggle_star

-- Role columns of the list header (shield, cross, sword icons) and the role each one sorts by.
local role_headers = { [4] = 'tank', [5] = 'healer', [6] = 'dps' }

---Sort key for a role column: messages that need the role come first.
---@param info table
---@param role string
---@return integer
---@nodiscard
local function role_rank(info, role)
	for _, r in pairs(info.roles) do
		if r == role or (role == 'dps' and (r == 'melee_dps' or r == 'ranged_dps')) then
			return 0
		end
	end

	return 1
end

---@param a table
---@param b table
---@return boolean
---@nodiscard
local sort_function = function(a, b)
	-- Starred raids always come first, whatever the selected sort column is.
	local starred_a, starred_b = is_starred(a), is_starred(b)
	if starred_a ~= starred_b then
		return starred_a
	end

	if sort_column == 'tank' or sort_column == 'healer' or sort_column == 'dps' then
		local rank_a, rank_b = role_rank(a, sort_column), role_rank(b, sort_column)
		if rank_a ~= rank_b then
			return compare(rank_a, rank_b)
		end

		-- Keep the order stable between updates
		return a.sender < b.sender
	elseif sort_column == "name" then
		return compare(a.sender, b.sender)
	elseif sort_column == "gs" then
		return compare(a.gs, b.gs)
	elseif sort_column == "raid" then
		return compare(a.raid_info.name, b.raid_info.name)
	else
		return compare(a.time, b.time)
	end
end

---@param column string
local function set_sort(column)
	if sort_column == column then
		sort_ascending = not sort_ascending
	else
		sort_column = column
	end

	if RaidBrowser.gui then
		RaidBrowser.gui.update_list()
	end
end

-- Raid type shown in the list (raid_info.name, e.g. 'toc25nm'); nil shows all raids. Not persisted.
local raid_filter = nil

---Whether the raid list should show the given message. Raids the player is saved to
---are hidden when the "Hide saved" filter is on.
---@param info table
---@return boolean
---@nodiscard
local function is_visible(info)
	if raid_filter and info.raid_info.name ~= raid_filter then return false end
	if not RaidBrowserCharacterHideSaved then return true end

	local locked = RaidBrowser.stats.raid_lock_info(info.raid_info);
	return not locked;
end

---@return table
---@nodiscard
local function get_sorted_messages()
	local keys = {}
	local listed = {}
	for _, info in pairs(RaidBrowser.lfm_messages) do
		local key = star_key(info)
		listed[key] = true
		if pinned_messages[key] then
			pinned_messages[key] = info -- keep the pinned copy fresh while the sender repeats the advert
		end

		if is_visible(info) then
			table.insert(keys, info)
		end
	end

	-- Pinned messages that are no longer (or not yet) among the active ones
	for key, info in pairs(pinned_messages) do
		if not listed[key] and is_visible(info) then
			table.insert(keys, info)
		end
	end

	table.sort(keys, sort_function)
	return keys
end

RaidBrowser.gui.get_sorted_messages = get_sorted_messages

---@return string?
function RaidBrowser.gui.get_raid_filter()
	return raid_filter
end

---@param name string? A raid name as shown in the list, or nil for all raids
function RaidBrowser.gui.set_raid_filter(name)
	raid_filter = name
	RaidBrowser.gui.update_list()
end

---Names of the raids currently in the list (active and pinned messages), sorted.
---@return string[]
---@nodiscard
function RaidBrowser.gui.available_raid_names()
	local seen, names = {}, {}
	local function add(info)
		local name = info.raid_info.name
		if not seen[name] then
			seen[name] = true
			table.insert(names, name)
		end
	end

	-- lfm_messages is created in OnEnable, after this file has loaded
	for _, info in pairs(RaidBrowser.lfm_messages or {}) do add(info) end
	for _, info in pairs(pinned_messages) do add(info) end

	table.sort(names)
	return names
end

name_column:SetScript('OnClick', function() set_sort('name') end)
gs_list_column:SetText('GS')
gs_list_column:SetScript('OnClick', function() set_sort('gs') end)
raid_list_column:SetText('Raid')
raid_list_column:SetScript('OnClick', function() set_sort('raid') end)

for index, role in pairs(role_headers) do
	local header = _G['LFRBrowseFrameColumnHeader' .. index]
	if header then
		header:SetScript('OnClick', function() set_sort(role) end)
	end
end

local function on_join()
	local raid_message = RaidBrowser.lfm_messages[LFRBrowseFrame.selectedName]

	-- The selected row may be a pinned message the sender no longer advertises
	if not raid_message then
		for _, info in pairs(pinned_messages) do
			if info.sender == LFRBrowseFrame.selectedName then
				raid_message = info
				break
			end
		end
	end

	if not raid_message then return end
	local raid_name = raid_message.raid_info.name;
	local message = RaidBrowser.stats.build_join_message(raid_name);
	--print(LFRBrowseFrame.selectedName.." -> "..message)
	SendChatMessage(message, 'WHISPER', nil, LFRBrowseFrame.selectedName);
end

join_button:SetText('Join')
join_button:SetScript('OnClick', on_join)

---@param value integer
---@return string
---@nodiscard
local function format_count(value)
	if value == 1 then
		return ' ';
	end

	return 's ';
end

---@param seconds string
---@return string
---@nodiscard
local function format_seconds(seconds)
	local num_seconds = tonumber(seconds)

	if num_seconds <= 0 then
		return "00 seconds";
	end

	local days_text = '';
	local hours_text = '';
	local minutes_text = '';

	if num_seconds >= 86400 then
		local days = math.floor(num_seconds / 86400);
		days_text = days .. ' day' .. format_count(days);
		num_seconds = num_seconds % 86400;
	end

	if num_seconds >= 3600 then
		local hours = math.floor(num_seconds / 3600);
		hours_text = hours .. ' hr' .. format_count(hours);
		num_seconds = num_seconds % 3600;
	end

	if num_seconds >= 60 then
		local minutes = math.floor(num_seconds / 60);
		minutes_text = minutes .. ' min' .. format_count(minutes);
	end

	return days_text .. hours_text .. minutes_text;
end

-- Hide unused dropdown menu
LFRBrowseFrameRaidDropDown:Hide()

search_button:SetText('Find Raid')
search_button:SetScript('OnClick', function() end)

local function clear_highlights()
	for i = 1, NUM_LFR_LIST_BUTTONS do
		_G["LFRBrowseFrameListButton" .. i]:UnlockHighlight();
	end
end

-- Assignment operator for LFR buttons
---@param button Button
---@param host_name string
---@param lfm_info any
---@param index integer
local function assign_lfr_button(button, host_name, lfm_info, index)
	local offset = FauxScrollFrame_GetOffset(LFRBrowseFrameListScrollFrame);
	button.index = index;
	index = index - offset;

	button.lfm_info = lfm_info;
	button.raid_info = lfm_info.raid_info;

	-- Update selected LFR raid host name
	button.unitName = host_name;

	-- Update button text with raid host name , GS, Raid, and role information
	button.name:SetText(host_name);
	button.level:SetText(button.lfm_info.gs); -- Previously level, now GS

	-- Raid name
	button.class:SetText(button.raid_info.name);

	button.raid_locked, button.raid_reset_time = RaidBrowser.stats.raid_lock_info(button.raid_info);
	button.type = "party";

	button.partyIcon:Hide(); -- always the same crown, carries no information

	-- The former crown column is used to star messages (starred messages are listed first).
	if not button.star_button then
		local star = CreateFrame('Button', nil, button)
		star:SetWidth(16)
		star:SetHeight(16)
		star:SetPoint('CENTER', button.partyIcon, 'CENTER', 0, 0)

		star.texture = star:CreateTexture(nil, 'OVERLAY')
		star.texture:SetAllPoints(star)
		star.texture:SetTexture('Interface\\TargetingFrame\\UI-RaidTargetingIcons')
		star.texture:SetTexCoord(0, 0.25, 0, 0.25)

		star:SetScript('OnClick', function(self)
			local info = self.lfm_info
			if not info then return end

			toggle_star(info)
			RaidBrowser.gui.update_list()
		end)

		star:SetScript('OnEnter', function(self)
			GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
			if self.lfm_info and is_starred(self.lfm_info) then
				GameTooltip:SetText('Remove the star')
			else
				GameTooltip:SetText('Star this message (starred messages are listed first)')
			end
			GameTooltip:Show()
		end)
		star:SetScript('OnLeave', function() GameTooltip:Hide() end)

		button.star_button = star
	end

	button.star_button.lfm_info = lfm_info
	button.star_button.texture:SetAlpha(is_starred(lfm_info) and 1 or 0.25)
	button.star_button:Show()

	button.tankIcon:Hide();
	button.healerIcon:Hide();
	button.damageIcon:Hide();

	-- Get all the roles from the lfm info table
	for _, role in pairs(button.lfm_info.roles) do
		if role == 'tank' then
			button.tankIcon:Show()
		end

		if role == 'healer' then
			button.healerIcon:Show();
		end

		if role == 'melee_dps' or role == 'ranged_dps' or role == 'dps' then
			button.damageIcon:Show();
		end
	end

	button:Enable();
	button.name:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)
	button.level:SetTextColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);

	-- If the raid is saved, then color the raid text in the list as red
	if button.raid_locked then
		button.class:SetTextColor(1, 0, 0);
	else
		button.class:SetTextColor(0, 1, 1);
	end

	-- Set up the corresponding textures for the roles columns
	button.tankIcon:SetTexture("Interface\\LFGFrame\\LFGRole");
	button.healerIcon:SetTexture("Interface\\LFGFrame\\LFGRole");
	button.damageIcon:SetTexture("Interface\\LFGFrame\\LFGRole");
	button.partyIcon:SetTexture("Interface\\LFGFrame\\LFGRole");

	button:SetScript('OnEnter',
		function(lfr_button)
			GameTooltip:SetOwner(lfr_button, 'ANCHOR_RIGHT');

			local seconds = time() - lfr_button.lfm_info.time;
			local last_sent = string.format('Last sent: %d seconds ago', seconds);
			GameTooltip:AddLine(lfr_button.lfm_info.message, 1, 1, 1, true);
			GameTooltip:AddLine(last_sent);

			if lfr_button.raid_locked then
				GameTooltip:AddLine('\nYou are |cffff0000saved|cffffd100 for ' .. lfr_button.raid_info.name);
				GameTooltip:AddLine('Lockout expires in ' .. format_seconds(lfr_button.raid_reset_time));
			else
				GameTooltip:AddLine('\nYou are |cff00ffffnot saved|cffffd100 for ' .. lfr_button.raid_info.name);
			end

			GameTooltip:Show();
		end
	)

	button:SetScript('OnLeave',
		function(_)
			GameTooltip:Hide();
		end
	)
end

---@param button Button
---@param index integer
local function insert_lfm_button(button, index)
	local count = 1;

	local sortedMessages = get_sorted_messages()

	for _, lfm_info in pairs(sortedMessages) do
		if count == index then
			assign_lfr_button(button, lfm_info.sender, lfm_info, index);
			break;
		end

		count = count + 1;
	end

end

local function update_buttons()
	LFRBrowseFrameSendMessageButton:Enable();
	LFRBrowseFrameInviteButton:Enable();
end

local function clear_list()
	for i = 1, NUM_LFR_LIST_BUTTONS do
		local button = _G["LFRBrowseFrameListButton" .. i];
		button:Hide();
		button:UnlockHighlight();
	end
end

function RaidBrowser.gui.update_list()
	LFRBrowseFrameRefreshButton.timeUntilNextRefresh = LFR_BROWSE_AUTO_REFRESH_TIME;

	local numResults = #get_sorted_messages()
	FauxScrollFrame_Update(LFRBrowseFrameListScrollFrame, numResults, NUM_LFR_LIST_BUTTONS, 16);

	local offset = FauxScrollFrame_GetOffset(LFRBrowseFrameListScrollFrame);
	clear_list();

	-- Update button information
	for i = 1, NUM_LFR_LIST_BUTTONS do
		local button = _G["LFRBrowseFrameListButton" .. i];
		if (i <= numResults) then
			insert_lfm_button(button, i + offset);
			button:Show();
		else
			button:Hide();
		end
	end

	clear_highlights();

	-- Update button highlights
	for i = 1, NUM_LFR_LIST_BUTTONS do
		local button = _G["LFRBrowseFrameListButton" .. i];
		if (LFRBrowseFrame.selectedName == button.unitName) then
			button:LockHighlight();
		else
			button:UnlockHighlight();
		end

		update_buttons();
	end
end

-- The rightmost header carries the (former crown) icon that now stands for stars: swap it for the same star.
-- The header's icon is the last texture of the rightmost column header that uses an LFG texture.
local function replace_party_header_icon()
	local icon
	for i = 1, 10 do
		local header = _G['LFRBrowseFrameColumnHeader' .. i]
		if header and header.GetRegions then
			for _, region in ipairs({ header:GetRegions() }) do
				if region.GetObjectType and region:GetObjectType() == 'Texture' then
					local texture = region:GetTexture()
					if texture and tostring(texture):lower():find('lfg') then
						icon = region
					end
				end
			end
		end
	end

	if icon then
		icon:SetTexture('Interface\\TargetingFrame\\UI-RaidTargetingIcons')
		icon:SetTexCoord(0, 0.25, 0, 0.25)
	end
end

replace_party_header_icon()

-- "Hide saved" filter: hides raids the player is already saved to.
local hide_saved_checkbox = CreateFrame('CheckButton', 'RaidBrowserHideSavedCheckbox', LFRBrowseFrame, 'UICheckButtonTemplate')
hide_saved_checkbox:SetWidth(18)
hide_saved_checkbox:SetHeight(18)
hide_saved_checkbox:SetPoint('BOTTOMLEFT', name_column, 'TOPLEFT', 36, -2)
_G[hide_saved_checkbox:GetName() .. 'Text']:SetText('Hide saved raids')
hide_saved_checkbox:SetScript('OnClick', function(self)
	RaidBrowserCharacterHideSaved = self:GetChecked() and true or false
	RaidBrowser.gui.update_list()
end)
hide_saved_checkbox:SetScript('OnEnter', function(self)
	GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
	GameTooltip:SetText('Hide raids you are already saved to')
	GameTooltip:Show()
end)
hide_saved_checkbox:SetScript('OnLeave', function() GameTooltip:Hide() end)

-- Saved variables are only available after the addon has loaded.
function RaidBrowser.gui.initialize_filters()
	-- The save button is created in raidset_frame.lua, which loads after this file.
	if RaidBrowserRaidSetSaveButton then
		hide_saved_checkbox:ClearAllPoints()
		hide_saved_checkbox:SetPoint('TOPLEFT', RaidBrowserRaidSetSaveButton, 'BOTTOMLEFT', 0, 1)
	end

	hide_saved_checkbox:SetChecked(RaidBrowserCharacterHideSaved)
end

-- Setup LFR browser hooks
LFRBrowse_UpdateButtonStates = update_buttons
LFRBrowseFrameList_Update = RaidBrowser.gui.update_list
LFRBrowseFrameListButton_SetData = insert_lfm_button

-- Set the "Browse" tab to be active.
LFRFrame_SetActiveTab(2)

LFRParentFrameTab1:Hide();
LFRParentFrameTab2:Hide();
