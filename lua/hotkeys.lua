local builtin = require("telescope.builtin")
local conform = require("conform")
local workspace = require("workspace")

vim.keymap.set("n", "π", builtin.commands, { -- Option + p
  desc = "Палитра команд",
})

vim.keymap.set("n", "∏", builtin.find_files, { -- Option + Shift + p
  desc = "Палитра файлов",
})

vim.keymap.set("n", "ƒ", workspace.focus_sidebar, { -- Option + f
  desc = "Фокус на активную вкладку левой панели",
})

vim.keymap.set("n", "©", workspace.focus_editor, { -- Option + g
  desc = "Фокус на текстовый редактор",
})

-- Терминал может передавать сочетания с Option как символы macOS или последовательности Meta.
local option_digits = { "¡", "™", "£", "¢", "∞", "§", "¶", "•", "ª", "º" }
for index, char in ipairs(option_digits) do
  local function select_tab()
    workspace.select_tab(index)
  end
  local opts = { desc = ("Выбрать вкладку %d"):format(index) }
  vim.keymap.set("n", char, select_tab, opts)
  vim.keymap.set("n", ("<M-%d>"):format(index % 10), select_tab, opts)
end

local function close_tab()
  workspace.close_tab(false)
end

local close_opts = {
  desc = "Закрыть файловую вкладку и сохранить окно редактора",
}
vim.keymap.set("n", "∑", close_tab, close_opts) -- Option + w

vim.keymap.set("n", "Ï", function()
  conform.format()
end, {
  desc = "Форматирование текущего файла",
})
