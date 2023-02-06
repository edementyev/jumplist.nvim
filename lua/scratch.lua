local u = require("jumplist.util")

print(vim.inspect(u.splice({ 1, 2, 3 }, 4, 0, { 4, 5, 6 }, true)))

local t = {}
table.insert(t, 31, "value")
table.insert(t, 51, ";laksejf")

for i, value in pairs(t) do
  print(i, " ", value)
end
