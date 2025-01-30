-- debug.lua
--
-- Shows how to use the DAP plugin to debug your code.
--
-- Primarily focused on configuring the debugger for Go, but can
-- be extended to other languages as well. That's why it's called
-- kickstart.nvim and not kitchen-sink.nvim ;)

return {
  -- NOTE: Yes, you can install new plugins here!
  'mfussenegger/nvim-dap',
  -- NOTE: And you can specify dependencies as well
  dependencies = {
    -- Creates a beautiful debugger UI
    'rcarriga/nvim-dap-ui',

    -- Required dependency for nvim-dap-ui
    'nvim-neotest/nvim-nio',

    -- Installs the debug adapters for you
    'williamboman/mason.nvim',
    'jay-babu/mason-nvim-dap.nvim',

    -- Add your own debuggers here
    'leoluz/nvim-dap-go',
  },
  config = function()
    local dap = require 'dap'
    local dapui = require 'dapui'

    require('mason-nvim-dap').setup {
      -- Makes a best effort to setup the various debuggers with
      -- reasonable debug configurations
      automatic_installation = true,

      -- You can provide additional configuration to the handlers,
      -- see mason-nvim-dap README for more information
      handlers = {},

      -- You'll need to check that you have the required things installed
      -- online, please don't ask me how to install them :)
      ensure_installed = {
        -- Update this to ensure that you have the debuggers for the langs you want
        'delve',
      },
    }

    _G.program_path = nil

    local handle_selection = function(prompt_bufnr)
      local selection = require('telescope.actions.state').get_selected_entry()
      require('telescope.actions').close(prompt_bufnr)

      _G.program_path = selection.path

      dap.continue()
    end

    vim.keymap.set('n', '<F5>', function()
      if dap.session() then
        dap.continue()
        return
      end

      _G.program_path = nil

      local telescope = require 'telescope.builtin'

      telescope.find_files {
        hidden = true, -- Include hidden files
        no_ignore = true, -- Include files that are ignored by .gitignore or other ignore files
        follow = true, -- Follow symlinks
        attach_mappings = function(_, map)
          map('i', '<CR>', function(prompt_bufnr)
            handle_selection(prompt_bufnr)
          end)
          map('n', '<CR>', function(prompt_bufnr)
            handle_selection(prompt_bufnr)
          end)
          map('n', '<Esc>', function(prompt_bufnr)
            require('telescope.actions').close(prompt_bufnr)
            dap.continue()
          end)
          return true
        end,
      }
    end, { desc = 'Debug: Start/Continue' })

    -- Basic debugging keymaps, feel free to change to your liking!
    -- vim.keymap.set('n', '<F5>', dap.continue, { desc = 'Debug: Start/Continue' })
    vim.keymap.set('n', '<F1>', dap.step_into, { desc = 'Debug: Step Into' })
    vim.keymap.set('n', '<F2>', dap.step_over, { desc = 'Debug: Step Over' })
    vim.keymap.set('n', '<F3>', dap.step_out, { desc = 'Debug: Step Out' })
    vim.keymap.set('n', '<F12>', function()
      dap.terminate()
      dapui.toggle()
    end, { desc = 'Debug: Terminate' })
    vim.keymap.set('n', '<leader>b', dap.toggle_breakpoint, { desc = 'Debug: Toggle Breakpoint' })
    vim.keymap.set('n', '<leader>cab', dap.clear_breakpoints, { desc = 'Debug: Clear All Breakpoints' })
    vim.keymap.set('n', '<leader>B', function()
      dap.set_breakpoint(vim.fn.input 'Breakpoint condition: ')
    end, { desc = 'Debug: Set Breakpoint' })

    -- Toggle to see last session result. Without this, you can't see session output in case of unhandled exception.
    vim.keymap.set('n', '<F7>', dapui.toggle, { desc = 'Debug: See last session result.' })

    -- Dap UI setup
    -- For more information, see |:help nvim-dap-ui|
    dapui.setup {
      -- Set icons to characters that are more likely to work in every terminal.
      --    Feel free to remove or use ones that you like more! :)
      --    Don't feel like these are good choices.
      icons = { expanded = '▾', collapsed = '▸', current_frame = '*' },
      controls = {
        icons = {
          pause = '⏸',
          play = '▶',
          step_into = '⏎',
          step_over = '⏭',
          step_out = '⏮',
          step_back = 'b',
          run_last = '▶▶',
          terminate = '⏹',
          disconnect = '⏏',
        },
      },
    }

    -- Define custom icons for breakpoints and other debugger states
    vim.fn.sign_define('DapBreakpoint', { text = '🔴', texthl = '', linehl = '', numhl = '' })
    vim.fn.sign_define('DapBreakpointCondition', { text = '🟡', texthl = '', linehl = '', numhl = '' })
    vim.fn.sign_define('DapLogPoint', { text = '🟢', texthl = '', linehl = '', numhl = '' })
    vim.fn.sign_define('DapStopped', { text = '➡️', texthl = '', linehl = 'DapStoppedLine', numhl = '' })

    dap.listeners.after.event_initialized['dapui_config'] = dapui.open
    dap.listeners.before.event_terminated['dapui_config'] = dapui.close
    dap.listeners.before.event_exited['dapui_config'] = dapui.close

    local debug_program_path = function()
      if _G.program_path then
        return _G.program_path
      end

      return nil
    end

    -- Install golang specific config
    require('dap-go').setup {
      delve = {
        -- On Windows delve must be run attached or it crashes.
        -- See https://github.com/leoluz/nvim-dap-go/blob/main/README.md#configuring
        detached = vim.fn.has 'win32' == 0,
      },
    }

    -- Define PHP debug adapter
    dap.adapters.php = {
      type = 'executable',
      command = 'bash',
      args = { os.getenv 'HOME' .. '/.local/share/nvim/mason/bin/php-debug-adapter' },
    }

    -- GDB debug adapter
    dap.adapters.gdb = {
      type = 'executable',
      command = 'gdb',
      args = { '-i', 'dap' }, -- Use DAP mode
    }

    -- Define Rust launch config
    dap.configurations.rust = {
      {
        name = 'Launch with GDB',
        type = 'gdb',
        request = 'launch',
        program = function()
          return debug_program_path() or vim.fn.getcwd() .. '/target/debug/' .. vim.fn.fnamemodify(vim.fn.getcwd(), ':t')
        end,
        cwd = '${workspaceFolder}',
        args = function()
          local input = vim.fn.input 'Enter arguments: '
          return vim.split(input, ' ') -- Split input into an argument list
        end,
      },
    }
    -- Define C++ launch configuration
    dap.configurations.cpp = {
      {
        name = 'Launch C++ Program with GDB', -- Custom name for the configuration
        type = 'gdb', -- Use gdb as the debugger
        request = 'launch', -- We're launching the program
        program = function()
          local folder_name = vim.fn.fnamemodify(vim.fn.getcwd(), ':t')
          if folder_name == 'dev' then
            folder_name = vim.fn.fnamemodify(vim.fn.getcwd(), ':h:t')
          end
          return debug_program_path() or vim.fn.getcwd() .. folder_name
        end,
        cwd = '${workspaceFolder}', -- Set working directory to the workspace folder
        stopOnEntry = false, -- Don't stop at entry point
        args = function()
          local input = vim.fn.input 'Enter arguments: '
          return vim.split(input, ' ') -- Convert input string into a table of arguments
        end,
      },
    }

    -- Define PHP launch config
    dap.configurations.php = {
      {
        type = 'php',
        request = 'launch',
        name = 'Listen for Xdebug',
        port = 9003, -- Default port for Xdebug
        cwd = '${workspaceFolder}',
        program = function()
          return debug_program_path() or vim.fn.expand '%t'
        end,
        args = function()
          local input = vim.fn.input 'Enter arguments: '
          return vim.split(input, ' ') -- Split input into an argument list
        end,
      },
    }
  end,
}
