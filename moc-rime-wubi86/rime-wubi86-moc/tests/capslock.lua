local module = assert(loadfile(arg[1]))()
local processor = type(module) == 'table' and module.func or module
local cases = {
    { input = "abc", expected = "ABC" },
    { input = "trw", expected = "TRW", menu = true },
    { input = "openclaw", expected = "OPENCLAW" },
    { input = "hello", expected = "HELLO", menu = true },
    { input = "MiXeD", expected = "MIXED" },
    { input = "ABC", expected = "ABC" },
    { input = "a", expected = "A" },
    { input = "abc", expected = "ABC", caps = true },
    { input = "" },
    { input = "abc", english = true },
    { input = "abc", release = true },
    { input = "abc", ctrl = true },
    { input = "abc", alt = true },
    { input = "abc", super = true },
    { input = "abc", shift = true },
    { input = "abc", keycode = 97 },
    { input = "abc", keycode = 32 },
    { input = "abc", keycode = 0xff0d },
    { input = "abc", keycode = 0xffe1 },
    { input = "R123" },
    { input = "/rq" },
    { input = "/calc1+2" },
    { input = "`jie" },
    { input = "N20261015" },
    { input = "ab cd" },
    { input = "abc123" },
}

for index, case in ipairs(cases) do
    local key = { keycode = case.keycode or 0xffe5 }
    for _, flag in ipairs({ "release", "ctrl", "alt", "super", "shift", "caps" }) do
        key[flag] = function() return case[flag] or false end
    end
    local committed, cleared = {}, 0
    local ctx = { input = case.input }
    function ctx:get_option(name)
        assert(name == "ascii_mode")
        return case.english or false
    end
    function ctx:has_menu() return case.menu or false end
    function ctx:clear() cleared = cleared + 1; self.input = "" end
    local engine = { context = ctx }
    function engine:commit_text(text) table.insert(committed, text) end
    local result = processor(key, { engine = engine })
    assert(result == 2, "CapsLock must continue to native processing: " .. index)
    assert(#committed == (case.expected and 1 or 0), "wrong commit count: " .. index)
    assert(committed[1] == case.expected, "wrong committed text: " .. index)
    assert(cleared == (case.expected and 1 or 0), "wrong clear count: " .. index)
    assert(ctx.input == (case.expected and "" or case.input), "input unexpectedly changed: " .. index)
    -- A key-up following key-down cannot commit a second copy.
    key.release = function() return true end
    assert(processor(key, { engine = engine }) == 2)
    assert(#committed == (case.expected and 1 or 0))
end
print(#cases .. " cases passed")

-- Stateful compatibility checks use a synthetic context, never a personal table.
local function fixture(enabled)
    local ctx = { input = '', english = false }
    function ctx:get_option(name) assert(name == 'ascii_mode'); return self.english end
    function ctx:clear() self.input = '' end
    function ctx:set_english(value)
        if self.english ~= value then
            self.english = value
            if self.listener then self.listener(self, 'ascii_mode') end
        end
    end
    ctx.option_update_notifier = {}
    local disconnected = false
    function ctx.option_update_notifier:connect(callback)
        ctx.listener = callback
        return { disconnect = function() disconnected = true end }
    end
    local env = { engine = { context = ctx }, output = '', forwarded = 0 }
    env.engine.schema = { config = { get_bool = function(_, name)
        assert(name == 'moc_capslock/capslox_compat'); return enabled
    end } }
    function env.engine:commit_text(text) env.output = env.output .. text end
    function env.engine:process_key(key)
        env.forwarded = env.forwarded + 1
        assert(processor(key, env) == 2, 'redispatch must reach native composer')
        return false
    end
    if type(module) == 'table' then module.init(env) end
    local function press(code, flags)
        local key = { keycode = code, modifier = 0 }
        for _, flag in ipairs({'release', 'ctrl', 'alt', 'super', 'shift'}) do
            key[flag] = function() return flags and flags[flag] or false end
        end
        return processor(key, env)
    end
    return ctx, env, press, function()
        if type(module) == 'table' then module.fini(env); if enabled then assert(disconnected) end end
    end
end
function KeyEvent(code, modifier)
    local key = { keycode = code, modifier = modifier }
    for _, flag in ipairs({'release', 'ctrl', 'alt', 'super', 'shift'}) do
        key[flag] = function() return false end
    end
    return key
end
do
    local ctx, env, press, finish = fixture(true)
    ctx.input = 'qmdh'
    assert(press(0xffcf) == 1 and env.output == 'QMDH' and ctx.input == '',
           'Capslox F18 must commit pending uppercase without leaving Chinese')
    assert(not ctx.english)
    assert(press(0xffcf, {release=true}) == 2 and env.output == 'QMDH')
    ctx.input = 'R123'; press(0xffcf); assert(ctx.input == 'R123')
    ctx.input = '/rq'; press(0xffcf); assert(ctx.input == '/rq')
    ctx.input = '`jie'; press(0xffcf); assert(ctx.input == '`jie')
    ctx:set_english(true); ctx.input = ''; env.output = ''
    assert(press(0xffcf) == 1)
    assert(press(97) == 1 and env.output == 'A' and env.forwarded == 1)
    assert(press(98, {shift=true}) == 1 and env.output == 'Ab')
    assert(press(99, {ctrl=true}) == 2 and env.output == 'Ab')
    assert(press(99, {alt=true}) == 2 and env.output == 'Ab')
    assert(press(99, {super=true}) == 2 and env.output == 'Ab')
    assert(press(49) == 2 and press(32) == 2 and press(0xff08) == 2)
    press(0xffcf); assert(press(99) == 2, 'second tap disables uppercase')
    press(0xffcf); ctx:set_english(false); ctx:set_english(true)
    assert(press(99) == 2, 'leaving English must reset uppercase')
    finish()
end
do
    local ctx, env, press, finish = fixture(false)
    ctx.input = 'abc'; assert(press(0xffcf) == 2 and env.output == '' and ctx.input == 'abc')
    assert(press(0xffffff) == 2 and press(0xffce) == 2)
    finish()
end
print('Capslox cases passed')
