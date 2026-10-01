-- Offline check of the role-sort comparator logic in gui.lua (copied helpers, no WoW frames needed).
local src = io.open('RaidBrowser/gui.lua'):read('*a')
local block = src:match("(local function role_rank.-\n\tend\n\n\treturn 1\nend)")
assert(block, 'role_rank not found')
local role_rank = assert(loadstring(block .. '\nreturn role_rank'))()
local msgs = {
	{ sender = 'a', roles = { 'dps' } },
	{ sender = 'b', roles = { 'tank', 'healer' } },
	{ sender = 'c', roles = { 'healer' } },
	{ sender = 'd', roles = { 'dps', 'tank', 'healer' } },
}
for _, role in ipairs({ 'tank', 'healer', 'dps' }) do
	table.sort(msgs, function(x, y)
		local rx, ry = role_rank(x, role), role_rank(y, role)
		if rx ~= ry then return rx < ry end
		return x.sender < y.sender
	end)
	local out = {}
	for _, m in ipairs(msgs) do out[#out + 1] = m.sender .. (role_rank(m, role) == 0 and '*' or '') end
	print(role .. ': ' .. table.concat(out, ' '))
end
