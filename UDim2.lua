---@class Sudado.UDim2
---@field scale SDL.FPoint
---@field offset SDL.Point
local UDim2 = {}
UDim2.__index = UDim2

---@param parentSize number
---@param scale number
---@param offset number
function Sudado.calculateUDimSize(parentSize, scale, offset)
	return parentSize * scale + offset
end

---@param parentPosition number
---@param parentSize number
---@param elementSize number
---@param scale number
---@param offset number
---@param anchor number
function Sudado.calculateUDimPosition(parentPosition, parentSize, elementSize, scale, offset, anchor)
	return parentPosition + parentSize * scale + offset - elementSize * anchor
end

---@param scaleX number?
---@param offsetX number?
---@param scaleY number?
---@param offsetY number?
function UDim2.new(scaleX, offsetX, scaleY, offsetY)
	local self = setmetatable({}, UDim2)

	self.scale = SDL.FPoint.new(scaleX and scaleX or 0, scaleY and scaleY or 0)
	self.offset = SDL.Point.new(offsetX and offsetX or 0, offsetY and offsetY or 0)

    return self
end

return UDim2