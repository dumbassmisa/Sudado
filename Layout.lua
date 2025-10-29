---@class Sudado.Layout
---@field anchor SDL.FPoint
---@field size Sudado.UDim2
---@field position Sudado.UDim2
local Layout = {}
Layout.__index = Layout

---@param anchorX number?
---@param anchorY number?
---@param position Sudado.UDim2?
---@param size Sudado.UDim2?
function Layout.new(anchorX, anchorY, position, size)
	local self = setmetatable({}, Layout)

	self.anchor = SDL.FPoint.new(anchorX, anchorY)
	self.position = position and position or Sudado.UDim2.new(0,0,0,0)
	self.size = size and size or Sudado.UDim2.new(0,100,0,100)

    return self
end

return Layout