-- включаем подсказки команд
vim.opt.wildmenu = true
vim.opt.wildmode = "longest:full,full"
vim.opt.wildoptions = "pum"

-- отключаем стандартный файловый менеджер netrw во избежание конфликтов с nvim-tree
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

vim.pack.add({
  -- иконки файлов в file tree
  {
    src = 'https://github.com/nvim-tree/nvim-web-devicons'
  },
  -- file tree
  {
    src = 'https://github.com/nvim-tree/nvim-tree.lua',
    version = vim.version.range("*"),
  },
  -- вспомогательная библиотека, зависимость telescope
  {
    src = "https://github.com/nvim-lua/plenary.nvim",
  },
  -- палитра команд
  {
    src = "https://github.com/nvim-telescope/telescope.nvim",
    version = vim.version.range("*"),
  },
})

-- настройки
require("nvim-tree").setup()

-- горячие клавиши

local builtin = require("telescope.builtin")

-- палитра команд
vim.keymap.set("n", "<C-p>", builtin.commands, {
    desc = "Command palette",
})

-- палитра файлов
vim.keymap.set("n", "<C-S-p>", builtin.find_files, {
    desc = "Find files",
})

-- автозапуск
vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
        require("nvim-tree.api").tree.open()
    end,
})

-- закрытие всех окон при :q
vim.cmd("cnoreabbrev q qa")
