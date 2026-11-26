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
