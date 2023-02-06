local M = {}

---@enum Jumplist.Scope
M.enum = {
	global = 1,
	file = 2,
  nearby = 3,
	line = 4,
	cursor = 5,
}

M.default_scope = M.enum.line

return M
