local Container = require('basinhd.elm.Container')

--- @class Frame : Container
--- @field protected _className string The name of the element's class
--- @field dragable boolean Whether or not the Frame can be dragged
--- @field private _onDragStartX integer The initial x-position of the Frame when dragging began
--- @field private _onDragStartY integer The initial y-position of the Frame when dragging began
--- @field private _onDragMouseX integer The initial x-position of the Mouse when dragging began
--- @field private _onDragMouseY integer The initial y-position of the Mouse when dragging began
--- @field _isDragging boolean Whether or not the Frame is currently being dragged
local Frame = setmetatable({}, { __index = Container })
Frame.__index = Frame
Frame._className = 'Frame'

--- Sets whether or not you can drag the Frame by the Mouse Cursor
--- @generic T : Frame
--- @param self T
--- @param dragable boolean Whether or not the Frame can be dragged by the Mouse Cursor
--- @return T self T:Frame Instance
function Frame:setDragable(dragable)
    self.dragable = dragable
    if not dragable then
        self:_onDragEnded()
    end
    return self
end

--- Initializes the dragging state of the Frame (Should not be used in production)
--- @generic T : Frame
--- @param self T
--- @param x integer The x-position of the Mouse Cursor
--- @param y integer The y-position of the Mouse Cursor
function Frame:_onDragStarted(x, y)
    x, y = math.ensureInteger(x), math.ensureInteger(y)
    if self.dragable then
        self._isDragging = true
        self._onDragStartX, self._onDragStartY = self.x, self.y
        self._onDragMouseX, self._onDragMouseY = x, y
    end
end

--- Deinitializes the dragging state of the Frame (Should not be used in production)
--- @generic T : Frame
--- @param self T
function Frame:_onDragEnded()
    self._isDragging = false
    self._onDragStartX, self._onDragStartY = 0, 0
    self._onDragMouseX, self._onDragMouseY = 0, 0
end

--- Handles the movement of the Frame while being dragged (Should not be used in production)
--- @generic T : Frame
--- @param self T
--- @param x integer The new Mouse Cursor x-position
--- @param y integer The new Mouse Cursor y-position
function Frame:_onDragMove(x, y)
    x, y = math.ensureInteger(x), math.ensureInteger(y)
    if self._isDragging and self.dragable then
        self.x, self.y = math.clamp(self._onDragStartX + (x - self._onDragMouseX), 1, 1 + self.parent._renderWidth - self._renderWidth),
            math.clamp(self._onDragStartY + (y - self._onDragMouseY), 1, 1 + self.parent._renderHeight - self._renderHeight)
    end
end

--- @protected
function Frame:_postInit()
    Container._postInit(self)

    self.dragable = false
    self._onDragStartX, self._onDragStartY, self._onDragMouseX, self._onDragMouseY = 0, 0, 0, 0
    self._isDragging = false
end

return Frame
