local function setup_lsp_rust(capabilities)
  local util = require 'lspconfig/util'
  local extension_path = vim.fn.expand("$HOME/.vscode-oss/extensions/vadimcn.vscode-lldb-1.7.0/", nil, nil)
  local codelldb_path = extension_path .. 'adapter/codelldb'
  local liblldb_path = extension_path .. 'lldb/lib/liblldb.so'
  require 'rust-tools'.setup {
    tools = {
      hover_with_actions = false,
    },
    hover_actions = {
      auto_focus = true,
    },
    server = {
      standalone = false,
      root_dir = util.root_pattern("Cargo.lock", "rust-project.json"),
      init_options = {
        publishDecorations = true;
      },
      capabilities = capabilities,
      settings = {
        ['rust-analyzer'] = {
          cargo = {
            loadOutDirsFromCheck = true,
            allFeatures = true,
          },
          procMacro = {
            -- enable = true,
            ignored = {
              -- ['async-trait'] = { 'async_trait' },
            },
          },
        },
      },
    },
    dap = {
      adapter = require 'rust-tools.dap'.get_codelldb_adapter(codelldb_path, liblldb_path, nil)
    }
  }
end

local function setup_lsp_go(capabilities)
  local cmd
  if vim.fn.executable('gopls') then
    cmd = 'gopls'
  elseif vim.fn.getenv('GOPATH') ~= vim.NIL then
    cmd = vim.fn.expand('$GOPATH/bin/gopls')
  else
    cmd = vim.fn.expand('$HOME/go/bin/gopls')
  end
  require 'lspconfig'.gopls.setup {
    inlay_hints = { enable = true },
    cmd = { cmd },
    capabilities = capabilities,
  }
end

local function setup_lsp_lua(capabilities)
  require 'neodev'.setup {
    override = function(root_dir, library)
      if root_dir:find("/home/unreal/Resource/nix-config", 1, true) == 1 then
        library.enabled = true
        library.plugins = true
      end
    end,
  }
  require 'lspconfig'.lua_ls.setup({
    on_init = function(client)
      local path = client.workspace_folders[1].name
      if not vim.loop.fs_stat(path..'/.luarc.json') and not vim.loop.fs_stat(path..'/.luarc.jsonc') then
        client.config.settings = vim.tbl_deep_extend('force', client.config.settings, {
          Lua = {
            runtime = {
              version = 'LuaJIT'
            },
            diagnostics = {
              globals = { 'vim' },
            },
            -- Make the server aware of Neovim runtime files
            workspace = {
              checkThirdParty = false,
              library = {
                vim.env.VIMRUNTIME
              }
            }
          }
        })

        client.notify("workspace/didChangeConfiguration", { settings = client.config.settings })
      end
      return true
    end,
    capabilities = capabilities,
  })
end

local function setup_lsp_nix(capabilities)
  require 'lspconfig'.nil_ls.setup {
    capabilities = capabilities,
  }
end

local function setup_lsp()
  local capabilities = require('cmp_nvim_lsp').default_capabilities()

  capabilities.textDocument.completion.completionItem.snippetSupport = true
  capabilities.textDocument.completion.completionItem.resolveSupport = {
    properties = {
      'documentation',
      'detail',
      'additionalTextEdits',
    },
  }
  setup_lsp_rust(capabilities)
  setup_lsp_go(capabilities)
  setup_lsp_lua(capabilities)
  setup_lsp_nix(capabilities)

  vim.lsp.handlers['textDocument/codeAction'] = require 'lsputil.codeAction'.code_action_handler
  vim.lsp.handlers['textDocument/references'] = require 'lsputil.locations'.references_handler
  vim.lsp.handlers['textDocument/definition'] = require 'lsputil.locations'.definition_handler
  vim.lsp.handlers['textDocument/declaration'] = require 'lsputil.locations'.declaration_handler
  vim.lsp.handlers['textDocument/typeDefinition'] = require 'lsputil.locations'.typeDefinition_handler
  vim.lsp.handlers['textDocument/implementation'] = require 'lsputil.locations'.implementation_handler
  vim.lsp.handlers['textDocument/documentSymbol'] = require 'lsputil.symbols'.document_handler
  vim.lsp.handlers['workspace/symbol'] = require 'lsputil.symbols'.workspace_handler
end

return {
  setup = setup_lsp,
}
