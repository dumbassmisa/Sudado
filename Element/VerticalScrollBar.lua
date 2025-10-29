---@diagnostic disable: need-check-nil
---@class Sudado.VerticalScrollBar : Sudado.Element
---@field scrollValue number
---@field thumbY number
---@field thumbHeight number
---@field dragOffsetY number
---@field thumbHovered boolean
local VerticalScrollBar = {
	type = Sudado.ElementType.VERTICAL_SCROLL_BAR,
	zIndex = 255,

	scrollSpeed = 40,

	backgroundColor = SDL.Color.new(10,10,10,255),
	backgroundHoveredColor = SDL.Color.new(5,5,5,255),

	thumbColor = SDL.Color.new(15,15,15,255),
	thumbHoveredColor1 = SDL.Color.new(25,25,25,255),
	thumbHoveredColor2 = SDL.Color.new(30,30,30,255)
}
VerticalScrollBar.__index = VerticalScrollBar

---@param layout Sudado.Layout?
---@param backgroundColor SDL.Color?
---@param backgroundHoveredColor SDL.Color?
---@param thumbColor SDL.Color?
---@param thumbHoveredColor1 SDL.Color?
---@param thumbHoveredColor2 SDL.Color?
function VerticalScrollBar.new(layout, backgroundColor, backgroundHoveredColor, thumbColor, thumbHoveredColor1, thumbHoveredColor2)
	local self = setmetatable({}, VerticalScrollBar)
	self.rect = SDL.FRect.new(0,0,0,0)

	if backgroundColor then self.backgroundColor = backgroundColor end
	if backgroundHoveredColor then self.backgroundHoveredColor = backgroundHoveredColor end

	if thumbColor then self.thumbColor = thumbColor end
	if thumbHoveredColor1 then self.thumbHoveredColor1 = thumbHoveredColor1 end
	if thumbHoveredColor2 then self.thumbHoveredColor2 = thumbHoveredColor2 end

	self.scrollValue = 0
	self.thumbY = 0
	self.dragOffsetY = 0
	self.thumbHeight = 1
	self.thumbHovered = false

	self.bordersSizes = SDL.Point.new(1,0)
	self.borderColor = SDL.Color.new(0,0,0,255)

	self.layout = layout
	if self.layout then
		self.onMove = Sudado.defaultOnMove
		self:onWindowResize()
	end

	self:updateThumbHeight(1,1)
	self:fitThumb()

	return self
end

function VerticalScrollBar:getHeightNoBorders()
	return self.rect.h-self.bordersSizes.y*2
end

function VerticalScrollBar:updateParentOffset()
	self.parent.offsetY = self.parent.rect.h*self.scrollValue
end

function VerticalScrollBar:shouldBeVisible()
	return self.thumbHeight < self:getHeightNoBorders()
end

function VerticalScrollBar:onUnhover()
	self.thumbHovered = false
end

---@param button integer
---@param mousePosition SDL.FPoint
function VerticalScrollBar:onMouseButtonDown(button, mousePosition)
	if button ~= SDL.Mouse.Button.LEFT then return end

	if not SDL.pointInRectFloat(mousePosition, SDL.FRect.new(self.rect.x+self.bordersSizes.x, self.rect.y+self.thumbY, self.rect.w-self.bordersSizes.x*2, self.thumbHeight)) then
		if Sudado.hoveredElement == self then
			self.thumbY = mousePosition.y - self.thumbHeight/2 - self.rect.y
			self:fitThumb()
			self:updateParentOffset()
		else return end
	end

	Sudado.scrolling = 1
	self.dragOffsetY = self.thumbY - mousePosition.y
end

---@param mousePosition SDL.FPoint
function VerticalScrollBar:onMouseMotion(mousePosition)
	if Sudado.scrolling & 1 ~= 0 then
		self.thumbY = mousePosition.y+self.dragOffsetY
		self:updateParentOffset()
	end

	self:fitThumb()
end

---@param height number
function VerticalScrollBar:setHeight(height)
	local heightNoBorders = self:getHeightNoBorders()
	if heightNoBorders > 0 then
		self.thumbY = self.thumbY * (height-self.bordersSizes.y*2)/heightNoBorders
	end

	self.rect.h = height
end

function VerticalScrollBar:onWindowResize()
	local windowSize = SDL.Video.getWindowSize(engine.getWindow())

	self.rect.w = Sudado.calculateUDimSize(windowSize.x, self.layout.size.scale.x, self.layout.size.offset.x)
	self:setHeight(Sudado.calculateUDimSize(windowSize.y, self.layout.size.scale.y, self.layout.size.offset.y))

	self.rect.x = Sudado.calculateUDimPosition(0, windowSize.x, self.rect.w, self.layout.position.scale.x, self.layout.position.offset.x, self.layout.anchor.x)
	self.rect.y = Sudado.calculateUDimPosition(0, windowSize.y, self.rect.h, self.layout.position.scale.y, self.layout.position.offset.y, self.layout.anchor.y)

	if self.children then
		Sudado.callChildrenTree(self.children, "onResize")
		Sudado.callChildrenTree(self.children, "onMove")
	end
end

function VerticalScrollBar:onResize()
	if self.parent ~= nil then
		self.rect.w = Sudado.calculateUDimSize(self.parent.rect.w, self.layout.size.scale.x, self.layout.size.offset.x)
		self:setHeight(Sudado.calculateUDimSize(self.parent.rect.h, self.layout.size.scale.y, self.layout.size.offset.y))
	end
end

---@param direction SDL.Point
function VerticalScrollBar:onMouseWheel(direction)
	if direction.y ~= 0 then
		self.thumbY = self.thumbY - direction.y * self.scrollSpeed * (self.thumbHeight/self.rect.h)
	end

	self:fitThumb()
	self:updateParentOffset()
end

function VerticalScrollBar:fitThumb()
	-- if up limit
	if self.thumbY < 0 then self.thumbY = 0 end

	local height = self:getHeightNoBorders()

	-- if down limit
	if self.thumbY+self.thumbHeight > height then
		self.thumbY = height-self.thumbHeight
	end

	self.scrollValue = self.thumbY / self.thumbHeight
end

---@param viewHeight number
---@param contentHeight number
function VerticalScrollBar:updateThumbHeight(viewHeight, contentHeight)
	if contentHeight < viewHeight then contentHeight = viewHeight end

	local height = self:getHeightNoBorders()

	local newThumbHeight = (viewHeight / contentHeight) * height
	if newThumbHeight < 1 then
		newThumbHeight = 1
	end

	self.thumbY = self.scrollValue*newThumbHeight
	self.thumbHeight = newThumbHeight
end

---@param renderer Pointer
function VerticalScrollBar:draw(renderer)
	-- Rect
	local drawColor = Sudado.hoveredElement and self.backgroundHoveredColor or self.backgroundColor
	SDL.Render.setRenderDrawColorEx(renderer, drawColor.r, drawColor.g, drawColor.b, drawColor.a)
	SDL.Render.renderFillRect(renderer, self.rect)

	if self.thumbHovered or (Sudado.scrolling & 1 ~= 0 and Sudado.focusedElement == self) then drawColor = self.thumbHoveredColor2
	elseif Sudado.hoveredElement == self then drawColor = self.thumbHoveredColor1
	else drawColor = self.thumbColor
	end

	-- Thumb
	local drawRect = SDL.FRect.new(self.rect.x+self.bordersSizes.x, self.rect.y+self.bordersSizes.y+self.thumbY, self.rect.w-self.bordersSizes.x*2, self.thumbHeight)
	SDL.Render.setRenderDrawColorEx(renderer, drawColor.r, drawColor.g, drawColor.b, drawColor.a)
	SDL.Render.renderFillRect(renderer, drawRect)

	-- Borders
	drawRect.x = self.rect.x
	drawRect.y = self.rect.y
	drawRect.w = self.bordersSizes.x
	drawRect.h = self.rect.h

	-- Left
	SDL.Render.setRenderDrawColorEx(renderer, self.borderColor.r, self.borderColor.g, self.borderColor.b, self.borderColor.a)
	SDL.Render.renderFillRect(renderer, drawRect)

	-- Top
	drawRect.h = self.bordersSizes.y
	SDL.Render.renderFillRect(renderer, drawRect)

	-- Right
	drawRect.x = self.rect.x+self.rect.w-self.bordersSizes.x
	drawRect.w = self.bordersSizes.x
	drawRect.h = self.rect.h
	SDL.Render.renderFillRect(renderer, drawRect)

	-- Bottom
	drawRect.x = self.rect.x
	drawRect.y = self.rect.y+self.rect.h-self.bordersSizes.y
	drawRect.w = self.rect.w
	drawRect.h = self.bordersSizes.y
	SDL.Render.renderFillRect(renderer, drawRect)
end

return VerticalScrollBar