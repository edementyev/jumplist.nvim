local u = require("global-jumplist.util")

print(vim.inspect(u.splice({1, 2, 3}, 1, -1, {4, 5, 6}, true)))
