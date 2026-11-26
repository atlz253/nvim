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

-- автозапуск
vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
        require("nvim-tree.api").tree.open()
    end,
})

-- закрытие всех окон при :q и :wq
vim.cmd("cnoreabbrev q qa")
vim.cmd("cnoreabbrev wq wqa")

-- утилита для проверки сочетания клавиш
vim.api.nvim_create_user_command("AtlzKeyTest", function()
    print("Press any key combination (Esc to exit)")

    while true do
        local key = vim.fn.getcharstr()
        local translated = vim.fn.keytrans(key)

        if translated == "<Esc>" then
            break
        end

        print("Key: " .. translated .. " | Unicode: " .. vim.fn.char2nr(key))
    end

    print("KeyTest finished")
end, {
    desc = "Test keyboard combinations",
})

