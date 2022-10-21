local status, nvim_comment = pcall(require, "nvim_comment")
if (not status) then return end

nvim_comment.setup()
