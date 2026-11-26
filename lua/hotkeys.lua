local builtin = require("telescope.builtin")
local conform = require("conform")

vim.keymap.set("n", "π", builtin.commands, { -- Option + p
  desc = "Палитра команд",
})

vim.keymap.set("n", "∏", builtin.find_files, { -- Option + Shift + p
  desc = "Палитра файлов",
})

vim.keymap.set("n", "ƒ", "<Cmd>NvimTreeFocus<CR>", { -- Option + f
  desc = "Фокус на file tree",
})

vim.keymap.set("n", "©", "<Cmd>wincmd l<CR>", { -- Option + g
  desc = "Фокус на текстовый редактор",
})

vim.keymap.set("n", "Ï", function()
  conform.format()
end, {
  desc = "Форматирование текущего файла",
})
