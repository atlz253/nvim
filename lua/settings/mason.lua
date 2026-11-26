require("mason").setup({})

-- установка отсутствующих пакетов при первичной инициализации редактора
local packages = {
    "lua-language-server",
}

local registry = require("mason-registry")

registry.refresh(function()
    for _, name in ipairs(packages) do
        local package = registry.get_package(name)

        if not package:is_installed()
            and not package:is_installing() then
            package:install()
        end
    end
end)

