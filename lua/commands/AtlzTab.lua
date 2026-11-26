local workspace = require("workspace")

vim.api.nvim_create_user_command("AtlzTabNext", function()
  workspace.cycle_tab(true)
end, {
  desc = "Следующая вкладка активной панели",
})

vim.api.nvim_create_user_command("AtlzTabPrev", function()
  workspace.cycle_tab(false)
end, {
  desc = "Предыдущая вкладка активной панели",
})

vim.api.nvim_create_user_command("AtlzTabClose", function(opts)
  workspace.close_tab(opts.bang)
end, {
  bang = true,
  desc = "Закрыть файловую вкладку и сохранить окно редактора",
})
