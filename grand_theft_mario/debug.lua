COLOR_RED = 0
COLOR_GREEN = 1
colorTable = {
    [COLOR_RED] = '\x1b[31m',
    [COLOR_GREEN] = '\x1b[32m'
}
function print_debug(script, text, color)
    local output = "[" .. script .. "]: " .. string.gsub(text, "COL", colorTable[color]) .. "\27[0m"
    print(output)
end