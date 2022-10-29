-- FerretExecutableArguments default: vimgrep --no-heading --no-config --max-columns 4096
vim.cmd(
  [[ 
   let g:FerretExecutableArguments = { 'rg': '--vimgrep --no-heading --no-config --max-columns 4096 --hidden --ignore-case --glob !.git/' }
  ]]
)
