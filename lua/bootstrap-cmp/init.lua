local Source = {}-- {{{
local cmp = require("cmp")
local config = require("bootstrap-cmp.config")
local utils = require("bootstrap-cmp.utils.init")
local uv = vim.loop-- }}}

function Source:new()-- {{{
    self.items = {}
    self.cache = {}
    self.classes = {}
    return self
end-- }}}

function read_file(path)-- {{{
    local fd = assert(uv.fs_open(path, "r", 256)) -- 400
    local stat = assert(uv.fs_fstat(fd))
    local data = assert(uv.fs_read(fd, stat.size, 0))
    assert(uv.fs_close(fd))
    return data
end-- }}}

function Source:is_available()-- {{{
    if not vim.tbl_contains(config.get("file_types"), vim.bo.filetype) then
        return false
    end
    return utils.isClassOrClassNameProperty()
end-- }}}

function Source:complete(_, callback)

    local bufnr = vim.api.nvim_get_current_buf()

    if not self.cache[bufnr] then

        -- TODO: Implement file watcher,
        --       ref. https://neovim.io/doc/user/lua.html#vim.uv
        --       ref. https://teukka.tech/vimloop.html

        local project_root_files = { ".git", ".prettierrc.json" }

        local root_dir = vim.fs.dirname(vim.fs.find(project_root_files, {
            type = 'directory',
            upward = true,
            stop = vim.env.HOME,
        })[1])

        -- local css_dir, css_files

        if (string.len(root_dir) >= 1) then
            -- TODO: Make `_build` a user parameter
            -- local css_dir = vim.fs.joinpath(root_dir, 'backend/keypuncher/core/static/css')
            -- local css_dir = '/home/lbr/.shares/lbr_code/mailshot/backend/keypuncher/core/static/css'
            local css_files = vim.fs.find(function(name, _)
                -- TODO: Fix search inside non-minified CSS files
                return name:match('.*%.min%.[sc]ss$')
            end,
                {
                    type = 'file',
                    path = root_dir,
                    limit = math.huge, -- 1 by default
                    upward = false,
                }
            )
            if #css_files >= 1 then
                local css_combined = ''
                for _, file_path in ipairs(css_files) do
                    css_combined = css_combined .. '\n' .. read_file(file_path)
                end
                self.file = css_combined
            end
        else
            vim.print('[ERROR] Unable to detect CSS project root!')
        end

        -- TODO: Doesn't work for regular CSS
        self.rules = utils.extract_rules(self.file)

        self.filtered_table = utils.remove_duplicates(self.rules)

        for _, rule in ipairs(self.filtered_table) do
            table.insert(self.items, {
                label = rule['class_name'],
                kind = cmp.lsp.CompletionItemKind.Enum,
                documentation = {
                    kind = 'markdown',
                    value = '```css\n' .. rule['css_properties'] .. '\n```'
                }
            })
        end

        callback({ items = self.items, isIncomplete = false })
        self.cache[bufnr] = self.items
    else
        callback({ items = self.cache[bufnr], isIncomplete = false })
    end
end

function Source:setup()
    require("cmp").register_source("bootstrap", Source)
end

return Source:new()
