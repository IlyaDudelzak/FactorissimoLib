local color_utils = require("colors")

string.split = function(s, separator)
    local result = {}
    for match in (s .. separator):gmatch("(.-)" .. separator) do
        result[#result + 1] = match
    end
    return result
end

string.is_digit = function(s) return s:match("%d") ~= nil end
string.starts_with = function(s, start) return s:sub(1, #start) == start end

factorissimo.color_normalize = color_utils.color_normalize
factorissimo.color_combine = color_utils.color_combine