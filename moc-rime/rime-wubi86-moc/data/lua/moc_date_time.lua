-- moc 日期/时间（从头写）：/rq 日期、/sj 时间。斜杠引导，不与五笔字根冲突。
local function translator(input, seg, env)
    if input == "/rq" then
        yield(Candidate(input, seg.start, seg._end, os.date("%Y-%m-%d"), "日期"))
        yield(Candidate(input, seg.start, seg._end, os.date("%Y年%m月%d日"), "日期"))
    elseif input == "/sj" then
        yield(Candidate(input, seg.start, seg._end, os.date("%H:%M"), "时间"))
        yield(Candidate(input, seg.start, seg._end, os.date("%H:%M:%S"), "时间"))
    end
end
return translator
