local function setup_autocommands()
  local group = vim.api.nvim_create_augroup("FugitiveDeleteBuf", { clear = true })
  vim.api.nvim_create_autocmd("BufReadPost", {
    pattern = "fugitive://*",
    callback = function() vim.opt.bufhidden = "delete" end,
    group = group,
  })
end

return {
  setup = setup_autocommands,
}
