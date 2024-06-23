local M = {}
local VALID_PREFIXES = { 'class', 'className' }
local VALID_QUOTES = { [["]], [[']] }

function M.isClassOrClassNameProperty()-- {{{
    local line = vim.api.nvim_get_current_line()

    for _, prefix in pairs(VALID_PREFIXES) do
        local quotes_alternation = '([' .. table.concat(VALID_QUOTES) .. '])'
        -- Full pattern: class%s-=%s-(["']).-%1
        local pattern = prefix .. '%s-=%s-' .. quotes_alternation .. '.-%1'

        local start_pos, end_pos = line:find(pattern)
        local cursor_pos = vim.api.nvim_win_get_cursor(0)

        if (start_pos and end_pos and cursor_pos[2] > start_pos and cursor_pos[2] <= end_pos) then
            return true
        end
    end

    return false
end-- }}}

local function beautify_css_properties(p)-- {{{
-- CSS properties from the Bootstrap css file is minified, they look like this:
-- display:flex!important;justify-content:center!important;align-items:center!important;
--
-- This function "beautify" them, into this:
-- display: flex !important;
-- justify-content: center !important;
-- align-items: center !important;
    return p:gsub('[:!;]', function(match)
        if match == '!' then
            return ' !'
        elseif match == ':' then
            return ': '
        elseif match == ';' then
            return ';\n'
        else
            return '%1'
        end
    end)
end-- }}}

function M.extract_rules(tbl)-- {{{
    local rules_pattern = "%.([a-zA-Z_][%w-]*){(.-)}"
    local rules = {}

    for class_name, properties in tbl:gmatch(rules_pattern) do
        table.insert(rules, { class_name = class_name, css_properties = beautify_css_properties(properties) })
    end

    return rules
end-- }}}

function M.remove_duplicates(t)-- {{{
    local seen = {}
    local result = {}

    for _, value in ipairs(t) do
        if not seen[value['class_name']] then
            table.insert(result, value)
            seen[value['class_name']] = true
        end
    end

    return result
end-- }}}

return M
