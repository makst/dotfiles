---@diagnostic disable-next-line: unused-local
local status_ok, _mason_lspconfig = pcall(require, "mason-lspconfig")
if not status_ok then return end

local mason_lspconfig = require("mason-lspconfig")

mason_lspconfig.setup({
  ensure_installed = { "sumneko_lua", "tsserver", "eslint", "yamlls" }
})
