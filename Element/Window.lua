---@class Sudado.Window : Sudado.Element
---@field getResizeRegionFromPointCollision Sudado.GetResizeRegionFromPointCollision
---@field getResizeArea fun(self: Sudado.Window, x: number, y: number): boolean
---@field minSize SDL.Point
---@field maxSize SDL.Point 0 = no limit
---@field draggable boolean|nil
---@field dragOffset SDL.Point
---@field resizable boolean|nil
---@field resizeAreasSizes SDL.Rect x = left, y = top, w = right, h = bottom; mixes such as topleft are the sizes of their areas combined
---@field bordersSizes SDL.Rect x = left, y = top, w = right, h = bottom
---@field borderColor SDL.Color
local Window = {
	---@type integer
	zIndex = 0
}
Window.__index = Window

---@param layout Sudado.Layout?
---@param draggable boolean?
---@param resizable boolean?
function Window.new(layout, draggable, resizable)
    local self = setmetatable({}, Window)
    self.rect = SDL.FRect.new(0,0,0,0)

	self.layout = layout
	if self.layout then
		self.onWindowResize = Sudado.defaultOnWindowResize
		self.onResize = Sudado.defaultOnResize
		self.onMove = Sudado.defaultOnMove
		self:onWindowResize(SDL.FPoint.new(1,1), SDL.Point.new(1,1))
	end

	self.minSize = SDL.Point.new(6,14)
	self.maxSize = SDL.Point.new(0,0)

    self.draggable = draggable or false
	self.dragOffset = SDL.Point.new(0,0)

    self.resizable = resizable or false
	self.resizeAreasSizes = SDL.Rect.new(3,3,3,3)

	self.backgroundColor = SDL.Color.new(10,10,10,255)

	-- top, bottom, left, right
	self.bordersSizes = SDL.Rect.new(2,10,2,2)
	self.borderColor = SDL.Color.new(20,20,20,255)
    return self
end

---@param point SDL.Point
function Window:isPointCollidingDragRegion(point)
    return point.x >= self.rect.x and point.x <= self.rect.x + self.rect.w and point.y >= self.rect.y and point.y <= self.rect.y + self.bordersSizes.y
end

---@param point SDL.Point
function Window:getResizeRegionFromPointCollision(point)
	-- 1 = left; 2 = right
	local leftOrRight = 0

	-- left, right
	if point.y >= self.rect.y and point.y <= self.rect.y+self.rect.h then
		-- left
		if point.x >= self.rect.x and point.x <= self.rect.x+self.resizeAreasSizes.x then
			leftOrRight = 1

		-- right
		elseif point.x >= self.rect.x+self.rect.w-self.resizeAreasSizes.w and point.x <= self.rect.x+self.rect.w then
			leftOrRight = 2
		end
	end

	-- top, bottom
	if point.x >= self.rect.x and point.x <= self.rect.x+self.rect.w then
		-- top
		if point.y >= self.rect.y and point.y <= self.rect.y+self.resizeAreasSizes.y then
			if leftOrRight == 1 then
				return Sudado.ResizeRegion.TOPLEFT
			elseif leftOrRight == 2 then
				return Sudado.ResizeRegion.TOPRIGHT
			else
				return Sudado.ResizeRegion.TOP
			end

		-- bottom
		elseif point.y >= self.rect.y+self.rect.h-self.resizeAreasSizes.h and point.y <= self.rect.y+self.rect.h then
			if leftOrRight == 1 then
				return Sudado.ResizeRegion.BOTTOMLEFT
			elseif leftOrRight == 2 then
				return Sudado.ResizeRegion.BOTTOMRIGHT
			else
				return Sudado.ResizeRegion.BOTTOM
			end
		end
	end


	if leftOrRight == 1 then
		return Sudado.ResizeRegion.LEFT
	elseif leftOrRight == 2 then
		return Sudado.ResizeRegion.RIGHT
	else
		return Sudado.ResizeRegion.NONE
	end
end

---@param point SDL.Point
function Window:resizeToPoint(point)
	if Sudado.resizeRegion == Sudado.ResizeRegion.TOP or Sudado.resizeRegion == Sudado.ResizeRegion.TOPLEFT or Sudado.resizeRegion == Sudado.ResizeRegion.TOPRIGHT then
		local originalHeight = self.rect.h
		self.rect.h = self.rect.h + self.rect.y - point.y
		if self.rect.h < self.minSize.y then
			self.rect.y = self.rect.y + originalHeight - self.minSize.y
			self.rect.h = self.minSize.y
		else
			self.rect.y = point.y
		end
	end

	if Sudado.resizeRegion == Sudado.ResizeRegion.LEFT or Sudado.resizeRegion == Sudado.ResizeRegion.TOPLEFT or Sudado.resizeRegion == Sudado.ResizeRegion.BOTTOMLEFT then
		local originalWidth = self.rect.w
		self.rect.w = self.rect.w + self.rect.x - point.x
		if self.rect.w < self.minSize.x then
			self.rect.x = self.rect.x + originalWidth - self.minSize.x
			self.rect.w = self.minSize.x
		else
			self.rect.x = point.x
		end
	end

	if Sudado.resizeRegion == Sudado.ResizeRegion.BOTTOM or Sudado.resizeRegion == Sudado.ResizeRegion.BOTTOMRIGHT or Sudado.resizeRegion == Sudado.ResizeRegion.BOTTOMLEFT then
		self.rect.h = math.max(self.minSize.y, point.y-self.rect.y)
		if self.maxSize.y ~= 0 then
			self.rect.h = math.min(self.maxSize.y, self.rect.h)
		end
	end

	if Sudado.resizeRegion == Sudado.ResizeRegion.RIGHT or Sudado.resizeRegion == Sudado.ResizeRegion.BOTTOMRIGHT or Sudado.resizeRegion == Sudado.ResizeRegion.TOPRIGHT then
		self.rect.w = math.max(self.minSize.x, point.x-self.rect.x)
		if self.maxSize.x ~= 0 then
			self.rect.w = math.min(self.maxSize.x, self.rect.w)
		end
	end

	if self.children then
		if self.onResize then self:onResize() end
		Sudado.callChildrenTree(self.children, "onResize")

		if self.onMove then self:onMove() end
		Sudado.callChildrenTree(self.children, "onMove")
	end
end

---@param button integer
---@param mousePosition SDL.FPoint
function Window:onMouseButtonDown(button, mousePosition)
	if Sudado.focusedElement ~= self then return end

	if button ~= SDL.Mouse.Button.LEFT then
		return
	end

	if Sudado.resizeRegion ~= Sudado.ResizeRegion.NONE then
		Sudado.resizing = true

	elseif self.draggable and self:isPointCollidingDragRegion(mousePosition) then
		Sudado.dragging = true
		self.dragOffset.x = mousePosition.x - self.rect.x
		self.dragOffset.y = mousePosition.y - self.rect.y
	end
end

---@param mousePosition SDL.FPoint
---@param _mouseDelta SDL.Point
function Window:onMouseMotion(mousePosition, _mouseDelta)
	if self.resizable and not Sudado.resizing then
		Sudado.resizeRegion = self:getResizeRegionFromPointCollision(mousePosition)
	end

	if Sudado.focusedElement ~= self then return end

    if Sudado.dragging then
        self.rect.x = mousePosition.x - self.dragOffset.x
        self.rect.y = mousePosition.y - self.dragOffset.y

		if self.onMove then self:onMove() end

		if self.children then
			Sudado.callChildrenTree(self.children, "onMove")
		end
    elseif Sudado.resizing then
		self:resizeToPoint(mousePosition)
	end
end

---@param renderer Pointer
function Window:draw(renderer)
	SDL.Render.setRenderDrawColorEx(renderer, self.backgroundColor.r, self.backgroundColor.g, self.backgroundColor.b, self.backgroundColor.a)
    SDL.Render.renderFillRect(renderer, self.rect)

	-- Borders
	SDL.Render.setRenderDrawColorEx(renderer, self.borderColor.r, self.borderColor.g, self.borderColor.b, self.borderColor.a)

	-- Left
	local drawRect = SDL.FRect.new(self.rect.x, self.rect.y, self.bordersSizes.y, self.rect.h)
	SDL.Render.renderFillRect(renderer, drawRect)

	-- Top
	drawRect.w = self.rect.w
	drawRect.h = self.bordersSizes.y
	SDL.Render.renderFillRect(renderer, drawRect)

	-- Right
	drawRect.x = self.rect.x+self.rect.w-self.bordersSizes.w
	drawRect.w = self.bordersSizes.w
	drawRect.h = self.rect.h
	SDL.Render.renderFillRect(renderer, drawRect)

	-- Bottom
	drawRect.x = self.rect.x
	drawRect.y = self.rect.y+self.rect.h-self.bordersSizes.h
	drawRect.w = self.rect.w
	drawRect.h = self.bordersSizes.h
	SDL.Render.renderFillRect(renderer, drawRect)
end

return Window