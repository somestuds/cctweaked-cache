-- local basinhd = {}

-- local _BUTTONS = {}

-- local function getCornerCoordinators(self, x, y, w, h)
--     local function clamp(v, min, max)
--         return math.min(math.max(v, min), max)
--     end
--     return { x1 = x, y1 = y, x2 = clamp(-1 + x + w, 1, self.gpu_size[1]), y2 = clamp(-1 + y + h, 1, self.gpu_size[2]) }
-- end
-- local function generate_guid()
--     local template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
--     return string.gsub(template, '[xy]', function(c)
--         local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
--         return string.format('%x', v)
--     end)
-- end

-- function basinhd:Button(x, y, w, h, onClick)
--     local base = getCornerCoordinators(self, x, y, w, h)
--     base['onClick'] = onClick
--     base['guid'] = generate_guid()
--     self.gpu.filledRectangle(x, y, w, h, 0xffcccccc)
--     _BUTTONS[base.guid] = base
--     self.gpu.sync()
-- end

-- function basinhd:TextLabel(x, y, text, color)
--     self.gpu.drawText(x, y, text, color, 0x00)
--     self.gpu.sync()
-- end

-- function basinhd:run()
--     self.gpu.sync()
--     local function onQuit()
--         while true do
--             os.sleep(0)
--             local _, key = os.pullEventRaw("key_up")
--             if key == keys.q then
--                 self.gpu.fill()
--                 self.gpu.sync()
--                 break
--             end
--         end
--     end
--     local function mainThread()
--         while true do
--             os.sleep(0)
--             local _, _, x, y = os.pullEvent("tm_monitor_touch")
--             for _, button in pairs(_BUTTONS) do
--                 if x >= button.x1 and x <= button.x2 and y >= button.y1 and y <= button.y2 then
--                     button.onClick()
--                 end
--             end
--         end
--     end
--     parallel.waitForAny(onQuit, mainThread)
-- end

-- ---@param gpu_peripheral ccTweaked.peripheral.wrappedPeripheral
-- return function(gpu_peripheral)
--     gpu_peripheral.refreshSize()
--     gpu_peripheral.setSize(64)
--     gpu_peripheral.fill()
--     gpu_peripheral.sync()
--     local gpu_size = { gpu_peripheral.getSize() }
--     return setmetatable(basinhd, { __index = { gpu = gpu_peripheral, gpu_size = gpu_size } })
-- end
-- 
local uslessvariable = 'hi'

function t()
    for i, v in pairs(debug.getinfo(2, 'S')) do
        print(i, v)
    end
end
--t('heoi')