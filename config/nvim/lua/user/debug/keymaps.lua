local status_dap, _ = pcall(require, "dap")
if not status_dap then return end

local status_dapui, _ = pcall(require, "dapui")
if not status_dapui then return end

local opts = { noremap = true, silent = true }

vim.api.nvim_set_keymap("n", "<F4>", ":lua require('dapui').toggle()<CR>", opts)
vim.api.nvim_set_keymap("n", "<F5>", ":lua require('dap').toggle_breakpoint()<CR>", opts)
vim.api.nvim_set_keymap("n", "<F9>", ":lua require('dap').continue()<CR>", opts)

vim.api.nvim_set_keymap("n", "<F1>", ":lua require('dap').step_over()<CR>", opts)
vim.api.nvim_set_keymap("n", "<F2>", ":lua require('dap').step_into()<CR>", opts)
vim.api.nvim_set_keymap("n", "<F3>", ":lua require('dap').step_out()<CR>", opts)

vim.api.nvim_set_keymap("n", "<leader>dsc", ":lua require('dap').continue()<CR>", opts)
vim.api.nvim_set_keymap("n", "<leader>dsv", ":lua require('dap').step_over()<CR>", opts)
vim.api.nvim_set_keymap("n", "<leader>dsi", ":lua require('dap').step_into()<CR>", opts)
vim.api.nvim_set_keymap("n", "<leader>dso", ":lua require('dap').step_out()<CR>", opts)

vim.api.nvim_set_keymap("n", "<leader>dhh", ":lua require('dap.ui.variables').hover()<CR>", opts)
vim.api.nvim_set_keymap("v", "<leader>dhv", ":lua require('dap.ui.variables').visual_hover()<CR>", opts)

vim.api.nvim_set_keymap("n", "<leader>duh", ":lua require('dap.ui.widgets').hover()<CR>", opts)
vim.api.nvim_set_keymap("n", "<leader>duf", ":lua local widgets=require('dap.ui.widgets');widgets.centered_float(widgets.scopes)<CR>", opts)

vim.api.nvim_set_keymap("n", "<leader>dro", ":lua require('dap').repl.open()<CR>", opts)
vim.api.nvim_set_keymap("n", "<leader>drl", ":lua require('dap').repl.run_last()<CR>", opts)

vim.api.nvim_set_keymap("n", "<leader>dbc", ":lua require('dap').set_breakpoint(vim.fn.input('Breakpoint condition: '))<CR>", opts)
vim.api.nvim_set_keymap("n", "<leader>dbm", ":lua require('dap').set_breakpoint({ nil, nil, vim.fn.input('Log point message: ') })<CR>", opts)
vim.api.nvim_set_keymap("n", "<leader>dbt", ":lua require('dap').toggle_breakpoint()<CR>", opts)

vim.api.nvim_set_keymap("n", "<leader>dc", ":lua require('dap.ui.variables').scopes()<CR>", opts)
vim.api.nvim_set_keymap("n", "<leader>di", ":lua require('dapui').toggle()<CR>", opts)
