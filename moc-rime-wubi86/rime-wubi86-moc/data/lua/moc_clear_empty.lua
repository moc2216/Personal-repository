-- moc 无候选上屏（从头写）：当前输入无候选时，空格/回车把原始字母上屏。
-- 词表外词（如 openclaw）打全后空格上屏；打错编码按 Esc 清空（express_editor 默认）。有候选交 selector。
local function processor(key, env)
    if key:release() or key:alt() or key:ctrl() or key:super() then return 2 end
    local ctx = env.engine.context
    if ctx.input == "" or ctx:has_menu() then return 2 end
    local r = key:repr()
    if r == "space" or r == "Return" then
        env.engine:commit_text(ctx.input)
        ctx:clear()
        return 1
    end
    return 2
end
return processor
