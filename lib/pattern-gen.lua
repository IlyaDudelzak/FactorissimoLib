local font = require("lib.font-data")
local M = {}

function M.make_space_line(number)
    local line = ""
    while true do 
        if #line == number then return line end
        line = line .. " "
    end
end

local function reverse_byte(b)
    local r = 0
    for i = 0, 7 do r = (r * 2) + (b % 2); b = math.floor(b / 2) end
    return r
end

local function byte_to_line(b)
    b = reverse_byte(b)
    local l = ""
    for i = 7, 0, -1 do l = l .. ((bit32.band(b, bit32.lshift(1, i))) ~= 0 and "+" or " ") end
    return l
end

local function get_char_pattern(char)
    local b = font[char:byte()] or {0,0,0,0,0,0,0,0}
    local res = {}
    for i = 1, 8 do res[i] = byte_to_line(b[i]) end
    return res
end

function M.generate_single_line(text)
    local res = {"","","","","","","",""}
    for i = 1, #text do
        local char_p = get_char_pattern(text:sub(i, i))
        for j = 1, 8 do res[j] = res[j] .. char_p[j] end
    end
    return res
end

function M.generate(text)
    text = string.split(text, "\n")
    local max_length = 0
    local pattern = {}
    for _, linetext in ipairs(text) do
        local linepattern = M.generate_single_line(linetext)
        for _, line in ipairs(linepattern) do
            if #line > max_length then max_length = #line end
            table.insert(pattern, line)
        end
        pattern[#pattern+1] = ""
        pattern[#pattern+1] = ""
    end
    for _, line in ipairs(pattern) do
        local diff = (max_length - #line) / 2
        pattern[_] = M.make_space_line(diff) .. line .. M.make_space_line(diff)
    end
    return pattern
end

return M