local processor = assert(loadfile(arg[1]))()
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
