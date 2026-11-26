vim.api.nvim_create_user_command("AtlzFormat", function()
  require("conform").format()
end, {
  desc = "Форматировать текущий файл",
})
