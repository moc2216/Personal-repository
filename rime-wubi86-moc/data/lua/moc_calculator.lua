-- moc 计算器（从头写）：/calc1+2 -> 3，仅四则运算与括号。斜杠引导，不与五笔冲突。
local function translator(input, seg, env)
    local expr = input:match("^/calc([-+*/().%d]+)$")
    if not expr then return end
    local ok, result = pcall(load("return " .. expr))
    if ok and type(result) == "number" then
        yield(Candidate(input, seg.start, seg._end, tostring(result), "计算"))
    else
        yield(Candidate(input, seg.start, seg._end, expr, "解析失败"))
    end
end
return translator
