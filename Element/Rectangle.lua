---@class Sudado.Rectangle : Sudado.Element
---@field minSize SDL.Point
---@field maxSize SDL.Point 0 = no limit
---@field draggable boolean|nil
---@field dragOffset SDL.Point
---@field resizable boolean|nil
---@field resizeAreasSizes SDL.Rect x = left, y = top, w = right, h = bottom; mixes such as topleft are the sizes of their areas combined
---@field bordersSizes SDL.Rect x = left, y = top, w = right, h = bottom
---@field borderColor SDL.Color
local Rectangle = {
	type = Sudado.ElementType.RECTANGLE,
	zIndex = 1
}
Rectangle.__index = Rectangle

---@param layout Sudado.Layout?
function Rectangle.new(layout)
    local self = setmetatable({}, Rectangle)
    self.rect = SDL.FRect.new(0,0,0,0)

	self.layout = layout
	if self.layout then
		self.onWindowResize = Sudado.defaultOnWindowResize
		self.onResize = Sudado.defaultOnResize
		self.onMove = Sudado.defaultOnMove
		self:onWindowResize(SDL.FPoint.new(1,1), SDL.Point.new(1,1))
	end

	-- self.minSize = SDL.Point.new(6,6)
	-- self.maxSize = SDL.Point.new(0,0)

	self.backgroundColor = SDL.Color.new(30,30,30,255)

	-- top, bottom, left, right
	self.bordersSizes = SDL.Rect.new(1,1,1,1)
	self.borderColor = SDL.Color.new(80,80,80,255)
    return self
end

---@param renderer Pointer
function Rectangle:draw(renderer)
	SDL.Render.setRenderDrawColorEx(renderer, self.backgroundColor.r, self.backgroundColor.g, self.backgroundColor.b, self.backgroundColor.a)
    SDL.Render.renderFillRect(renderer, self.rect)

	-- Borders
	SDL.Render.setRenderDrawColorEx(renderer, self.borderColor.r, self.borderColor.g, self.borderColor.b, self.borderColor.a)

	-- Left
	local borderRect = SDL.FRect.new(self.rect.x, self.rect.y, self.bordersSizes.x, self.rect.h)
	SDL.Render.renderFillRect(renderer, borderRect)

	-- Top
	borderRect.w = self.rect.w
	borderRect.h = self.bordersSizes.y
	SDL.Render.renderFillRect(renderer, borderRect)

	-- Right
	borderRect.x = self.rect.x+self.rect.w-self.bordersSizes.w
	borderRect.w = self.bordersSizes.w
	borderRect.h = self.rect.h
	SDL.Render.renderFillRect(renderer, borderRect)

	-- Bottom
	borderRect.x = self.rect.x
	borderRect.y = self.rect.y+self.rect.h-self.bordersSizes.h
	borderRect.w = self.rect.w
	borderRect.h = self.bordersSizes.h
	SDL.Render.renderFillRect(renderer, borderRect)
end

return Rectangle