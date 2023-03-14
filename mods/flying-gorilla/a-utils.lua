function switch(param, case_table)
    local case = case_table[param]
    if case then return case() end
    local def = case_table['default']
    return def and def() or nil
end

function approach_number(current, target, inc, dec)
    if current < target then
        current = current + inc
        if current > target then
            current = target
        end
    else
        current = current - dec
        if current < target then
            current = target
        end
    end
    return current
end

function if_then_else(cond, if_true, if_false)
    if cond then return if_true end
    return if_false
end

function s16(num)
    num = math.floor(num) & 0xFFFF
    if num >= 32768 then return num - 65536 end
    return num
end