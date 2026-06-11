local _res = false
local gpu = peripheral.find('tm_gpu')
local basinhd = require('basinhd')

function table.reverse(self)
    local t = self

    local i, j = 1, #t
    while i < j do
        t[i], t[j] = t[j], t[i]
        i = i + 1
        j = j - 1
    end

    return self
end

basinhd:setMouseCursorEnabled(true)
local mainFrame = basinhd:getMainFrame(gpu)

mainFrame:addText()
    :setTextScale(5)
    :setText('Sami is a pig')
    :setForeground('#00FF00')
    :setTextAnchor('right', 'bottom')

local fr = mainFrame:addFrame()
    :setSize(512, 320)
    :setPosition(1, 1)
    :setScale(1.55)
    :setBackground('#d92b90')
    :setDragable(true)

fr:addButton()
    :setSize(80, 64)
    :setBackground('#d9512b')
    :setText('hello guys')
    :anchorTo('topLeft')
    :setAnchorOffset(16, 32)

fr:addButton()
    :setSize(100, 49)
    :setPosition(200, 100)
    :setBackground('#9d55ad')
    :setText('didney worl')
    :setTextAnchor('left', 'bottom')
    :anchorTo('bottomLeft')

fr:addImage()
    :setDesiredSize(320, 180)
    :setImage('https://img.youtube.com/vi/PMM2L13f-0Q/mqdefault.jpg')
    :setPosition(-320, -180)

mainFrame:addButton()
    :setSize(64, 64)
    :setBackground('#000000')
    :setText('X')
    :setTextScale(4)
    :anchorTo('topRight')
    :onHover(function(self, hovering)
        --- @type table
        local colors = { 0x000000, 0xFF0000 }
        self:animateMethod('setBackground', 0.15, table.unpack(hovering and colors or table.reverse(colors)))

        -- self:setBackground(hovering and colors.lerp(0x000000, 0xFF0000, 0.1) or '#000000')
    end)
    :onClick(function()
        _res = true
        basinhd:stop()
    end)

-- local f = mainFrame:addFrame()
--     :setSize(336, 336)
--     :setBackground('#00ccff')
--     :setDragable(true)

-- f:addButton()
--     :setSize(64, 64)
--     :setPosition(1, 1)
--     :setBackground('#aaaaaa')
--     :onHover(function(self, hovering)
--         local colors = {'#aaaaaa', '#ff0000'}
--         self:animateMethod('setBackground', .3, table.unpack(hovering and colors or table.reverse(colors)))
--     end)

-- f:addButton()
--     :setSize(64, 64)
--     :setPosition(33, 33)
--     :setBackground('#555555')
--     :onHover(function(self, hovering)
--         local colors = { '#555555', '#0000ff' }
--         self:animateMethod('setBackground', .3, table.unpack(hovering and colors or table.reverse(colors)))
--     end)

basinhd:run()
if _res then
    shell.run(debug.getinfo(1, 'S').short_src)
end
