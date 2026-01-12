local font = require("lib.font")
local bit32 = require("bit32")
local p = {}

local function reverse_byte(b)
  local r = 0
  for i = 0, 7 do r = (r * 2) + (b % 2); b = math.floor(b / 2) end
  return r
end

local function byte_to_line(b)
  b = reverse_byte(b)
  local l = ""
  for i = 7, 0, -1 do l = l .. ((b & (bit32.lshift(1, i))) ~= 0 and "+" or " ") end
  return l
end

local function get_char_pattern(char)
  local b = font[char:byte()] or {0,0,0,0,0,0,0,0}
  local res = {}
  for i = 1, 8 do res[i] = byte_to_line(b[i]) end
  return res
end

p.make = function(text)
  local res = {"","","","","","","",""}
  for i = 1, #text do
    local char_p = get_char_pattern(text:sub(i, i))
    for j = 1, 8 do res[j] = res[j] .. char_p[j] end
  end
  return res
end

return p