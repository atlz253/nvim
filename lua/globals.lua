-- включаем подсказки команд
vim.opt.wildmenu = true
vim.opt.wildmode = "longest:full,full"
vim.opt.wildoptions = "pum"

-- отключаем стандартный файловый менеджер netrw во избежание конфликтов с nvim-tree
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- закрытие всех окон при :q и :wq
vim.cmd("cnoreabbrev q qa")
vim.cmd("cnoreabbrev wq wqa")

