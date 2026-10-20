-- Runs tests/lfm_tests.lua (written for the in-game /rb test) outside the game with LuaJIT.
-- Usage: luajit tools/run_unit_tests.lua [repo-root]   (default: current directory)
-- Prints the failing messages and the totals; exit code 1 if any test failed.
local root = arg[1] or '.'
GetLocale = function() return 'enUS' end
local failed, current = {}, nil
local addon = {}
function addon.Print(a, b) -- works for both RaidBrowser.Print(text) and RaidBrowser:Print(text)
	local text = b or a
	if type(text) == 'string' then
		if text:find('^Testing: ') then current = text:sub(10) end
		if text:find('^Original message: ') then current = text:sub(19) end
		if text:find('^Test failed: ') then failed[#failed + 1] = (current or '?') .. '   <- ' .. text:sub(14) end
		if text:find('^There were ') then print(text) end
	end
end
LibStub = function() return { NewAddon = function() return addon end } end
RaidBrowser = addon
dofile(root .. '/RaidBrowser/Libs/stdlib/algorithm.lua')
dofile(root .. '/RaidBrowser/core.lua')
print = (function(p) return function(...) if select('#', ...) > 0 and tostring((...)):find('^There were') then p(...) end end end)(print)
dofile(root .. '/tests/lfm_tests.lua')
io.write(string.format('%d failing tests\n', #failed))
for _, f in ipairs(failed) do io.write('  FAIL: ' .. f .. '\n') end
os.exit(#failed > 0 and 1 or 0)
