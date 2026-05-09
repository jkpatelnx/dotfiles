local lastWindow = nil
local currentWindow = nil

hs.window.filter.default:subscribe(
    hs.window.filter.windowFocused,
    function(win)
        if win and currentWindow ~= win then
            lastWindow = currentWindow
            currentWindow = win
        end
    end
)

hs.hotkey.bind({}, "F1", function()
    if lastWindow and lastWindow:isStandard() then
        local temp = currentWindow
        lastWindow:focus()
        currentWindow = lastWindow
        lastWindow = temp
    end
end)

hs.hotkey.bind({}, "F2", function()
    hs.eventtap.keyStroke({"cmd"}, "c")
end)

hs.hotkey.bind({}, "F3", function()
    hs.eventtap.keyStroke({"cmd"}, "v")
end)

hs.hotkey.bind({}, "F4", function()
    hs.eventtap.keyStroke({"cmd"}, "x")
end)


