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
  -- менеджер пакетов для универсального запуска neovim между системами
  {
    src = "https://github.com/mason-org/mason.nvim",
    version = vim.version.range("^2.0.0"),
  },
})

