-- 原生 CapsLock 保持系统切换；可选 Capslox F18 通知只管理 Rime 内部大写。
local M = {}

function M.init(env)
    env.compat = env.engine.schema.config:get_bool("moc_capslock/capslox_compat") == true
    env.upper = false
    if env.compat then
        env.change = env.engine.context.option_update_notifier:connect(function(_, name)
            if name == "ascii_mode" then env.upper = false end
        end)
    end
end

function M.fini(env)
    if env.change then env.change:disconnect() end
end

function M.func(key, env)
    if env.redispatch or key:release() or key:ctrl() or key:alt() or key:super() then return 2 end
    local ctx = env.engine.context
    if key.keycode == 0xffe5 and not key:shift() then
        if not ctx:get_option("ascii_mode") and ctx.input:match("^[A-Za-z]+$") then
            env.engine:commit_text(ctx.input:upper())
            ctx:clear()
        end
        return 2 -- 原生 CapsLock 继续交给 ascii_composer。
    end
    if not env.compat then return 2 end
    if key.keycode == 0xffcf and not key:shift() then -- F18：Capslox 短按通知。
        if ctx:get_option("ascii_mode") then
            env.upper = not env.upper
        elseif ctx.input:match("^[A-Za-z]+$") then
            env.engine:commit_text(ctx.input:upper())
            ctx:clear()
        end
        return 1
    end
    if env.upper and ctx:get_option("ascii_mode") and
        ((key.keycode >= 65 and key.keycode <= 90) or (key.keycode >= 97 and key.keycode <= 122)) then
        local text = string.char(key.keycode)
        text = key:shift() and text:lower() or text:upper()
        -- 让原生处理器看到字母，避免按住 Shift 打字后松开时误切换中英文。
        env.redispatch = true
        local accepted = env.engine:process_key(KeyEvent(text:byte(), key.modifier))
        env.redispatch = false
        if not accepted then env.engine:commit_text(text) end
        return 1
    end
    return 2
end
return M
