local gpu = peripheral.find('tm_gpu')
local basinhd = require("lib")(gpu)


-- Actual Code here
--
--

local function lerp(a, b, t)
    return a + (b - a) * t
end

local i = 0
basinhd:Button(4, 12, 30, 16, function()
    i = i + 1
    gpu.filledRectangle(1, 80, 256, 8)
    basinhd:TextLabel(1, 80, "Sami is a " .. i .. "x pig", lerp(0xFFFFFF, 0xFF69B4, i / 75))
end)

print("Running")
basinhd:run()
