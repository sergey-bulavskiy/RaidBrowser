-- Offline check: starred messages come first regardless of the selected sort (mirrors gui.lua).
local starred_messages = { ['b|lfm toc'] = true }
local function star_key(info) return info.sender .. '|' .. info.message end
local function is_starred(info) return starred_messages[star_key(info)] == true end
local msgs = {
	{ sender = 'a', message = 'lfm voa' },
	{ sender = 'b', message = 'lfm toc' },
	{ sender = 'c', message = 'lfm icc' },
	{ sender = 'b', message = 'lfm other' },
}
for _, asc in ipairs({ false, true }) do
	table.sort(msgs, function(x, y)
		local sx, sy = is_starred(x), is_starred(y)
		if sx ~= sy then return sx end
		if asc then return x.sender > y.sender end
		return x.sender < y.sender
	end)
	local out = {}
	for _, m in ipairs(msgs) do out[#out + 1] = m.sender .. ':' .. m.message end
	print((asc and 'desc' or 'asc') .. ' -> ' .. table.concat(out, ' | '))
end
