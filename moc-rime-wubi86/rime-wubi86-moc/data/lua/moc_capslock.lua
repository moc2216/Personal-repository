-- CapsLock：中文输入中的纯字母编码转为大写上屏，再交原生处理切换大小写。
local function processor(key, env)
    if key.keycode ~= 0xffe5 or key:release() or key:shift()
        or key:ctrl() or key:alt() or key:super() then return 2 end
    local ctx = env.engine.context
    if ctx:get_option("ascii_mode") or not ctx.input:match("^[A-Za-z]+$") then return 2 end
    env.engine:commit_text(ctx.input:upper())
    ctx:clear()
    -- kNoop：不吞 CapsLock，让 ascii_composer 保留系统大写锁定及中英切换。
    return 2
end
return processor
