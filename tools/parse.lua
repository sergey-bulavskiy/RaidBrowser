-- Offline harness: runs chat lines through RaidBrowser's parser with LuaJIT (Lua 5.1, same as the 3.3.5a client).
-- Usage: luajit tools/parse.lua <chatlog.txt> [-v]
local root = os.getenv('RB_ROOT') or '.'

local addon = {}
function addon:Print(...) if VERBOSE then print('    ' .. table.concat({ ... }, ' ')) end end
LibStub = function() return { NewAddon = function() return addon end } end
RaidBrowser = nil

dofile(root .. '/RaidBrowser/Libs/stdlib/algorithm.lua')
dofile(root .. '/RaidBrowser/core.lua')

local file, verbose = arg[1], arg[2] == '-v'
VERBOSE = verbose
for line in io.lines(file) do
	-- Strip "[18:41:36] [2] [Name]: " style prefix; keep channel tag for display.
	local chan, msg = line:match('^%[[%d:]+%]%s*%[([^%]]+)%]%s*%[[^%]]+%]:%s*(.*)$')
	if msg then
		local info, roles, gs = RaidBrowser.raid_info(msg, verbose)
		if info then
			print(string.format('OK    [%s] %-10s roles=%s gs=%s | %s', chan, info.name, table.concat(roles, ','), gs, msg:sub(1, 70)))
		else
			print(string.format('MISS  [%s] | %s', chan, msg:sub(1, 110)))
		end
	end
end
