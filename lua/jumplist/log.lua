local M = nil

local ok, log = pcall(require, "vlog")

local level = "info"

if not ok then
	M = setmetatable({}, {
		__index = function(_, key)
			return function(...)
				if key == "error" then
					print("ERROR:", ...)
				end
			end
		end,
	})
else
	M = log.new({
		plugin = "global-jumplist",
		use_file = false,
		level = level,
	}, true)
end

return M
