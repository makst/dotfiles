---@diagnostic disable-next-line: unused-local
local status, _luasnip = pcall(require, 'luasnip')
if (not status) then return end

local luasnip_loaders = require('luasnip.loaders.from_vscode');
luasnip_loaders.lazy_load()

local luasnip = require('luasnip');
luasnip.filetype_extend('typescript', { 'javascript' })
