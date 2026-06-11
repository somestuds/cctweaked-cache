local VisualElement = require('basinhd.elm.VisualElement')

--- @generic T : VisualElement
--- @class Container : VisualElement
--- @field protected _className string The name of the element's class
--- @field children T[] The children of the Container
local Container = setmetatable({}, { __index = VisualElement })
Container.__index = Container
Container._className = 'Container'

--- Adds a Button to the Container
--- @generic T : Container
--- @param self T
--- @return Button button The Button that was added
function Container:addButton()
    local Button = require('basinhd.elm.Button')
    local button = Button:new(self)
    table.insert(self.children, button)
    return button
end

--- Adds a TextLabel to the Container
--- @generic T : Container
--- @param self T
--- @return TextLabel textlabel The TextLabel that was added
function Container:addText()
    local TextLabel = require('basinhd.elm.TextLabel')
    local text = TextLabel:new(self)
    table.insert(self.children, text)
    return text
end

--- Adds a Frame to the Container
--- @generic T : Container
--- @param self T
--- @return Frame frame The Frame that was added
function Container:addFrame()
    local Frame = require('basinhd.elm.Frame')
    local frame = Frame:new(self)
    table.insert(self.children, frame)
    return frame
end

--- Adds a Image to the Container
--- @generic T : Container
--- @param self T
--- @return Image image The Image that was added
function Container:addImage()
    local Image = require('basinhd.elm.Image')
    local image = Image:new(self)
    table.insert(self.children, image)
    return image
end

--- @protected
function Container:_postInit()
    VisualElement._postInit(self)

    self.width = 60
    self.height = 40
    self.children = {}
end

--- Renders the Container to the screen (should not be used in production)
--- @return boolean success Whether or not the Container was rendered
function Container:_render()
    local rendered = VisualElement._render(self)
    if not rendered then return false end

    table.sort(self.children, function(a, b)
        return a._definitionPeriod < b._definitionPeriod
    end)
    for i = 1, #self.children do
        local child = self.children[i]
        --child:_alignToParent()
        child:_render()
    end

    return true
end

return Container
