---@diagnostic disable: need-check-nil
---@class Sudado.HorizontalScrollBar : Sudado.Element
---@field scrollValue number
---@field thumbX number
---@field thumbWidth number
---@field dragOffsetX number
---@field thumbHovered boolean
local HorizontalScrollBar = {
	type = Sudado.ElementType.HORIZONTAL_SCROLL_BAR,
	zIndex = 255,

	scrollSpeed = 40,

	backgroundColor = SDL.Color.new(10,10,10,255),
	backgroundHoveredColor = SDL.Color.new(5,5,5,255),

	thumbColor = SDL.Color.new(15,15,15,255),
	thumbHoveredColor1 = SDL.Color.new(25,25,25,255),
	thumbHoveredColor2 = SDL.Color.new(30,30,30,255)
}
HorizontalScrollBar.__index = HorizontalScrollBar

---@param layout Sudado.Layout?
---@param backgroundColor SDL.Color?
---@param backgroundHoveredColor SDL.Color?
---@param thumbColor SDL.Color?
---@param thumbHoveredColor1 SDL.Color?
---@param thumbHoveredColor2 SDL.Color?
function HorizontalScrollBar.new(layout, backgroundColor, backgroundHoveredColor, thumbColor, thumbHoveredColor1, thumbHoveredColor2)
	local self = setmetatable({}, HorizontalScrollBar)
	self.rect = SDL.FRect.new(0,0,0,0)

	if backgroundColor then self.backgroundColor = backgroundColor end
	if backgroundHoveredColor then self.backgroundHoveredColor = backgroundHoveredColor end

	if thumbColor then self.thumbColor = thumbColor end
	if thumbHoveredColor1 then self.thumbHoveredColor1 = thumbHoveredColor1 end
	if thumbHoveredColor2 then self.thumbHoveredColor2 = thumbHoveredColor2 end

	self.scrollValue = 0
	self.thumbX = 0
	self.dragOffsetX = 0
	self.thumbWidth = 1
	self.thumbHovered = false

	self.bordersSizes = SDL.Point.new(1,0)
	self.borderColor = SDL.Color.new(0,0,0,255)

	self.layout = layout
	if self.layout then
		self.onMove = Sudado.defaultOnMove
		self:onWindowResize()
	end

	self:updateThumbWidth(1,1)
	self:fitThumb()

	return self
end

function HorizontalScrollBar:getWidthNoBorders()
	return self.rect.w-self.bordersSizes.x*2
end

function HorizontalScrollBar:updateParentOffset()
	self.parent.offsetX = self.parent.rect.w*self.scrollValue
end

function HorizontalScrollBar:shouldBeVisible()
	return self.thumbWidth < self:getWidthNoBorders()
end

function HorizontalScrollBar:onUnhover()
	self.thumbHovered = false
end

---@param button integer
---@param mousePosition SDL.FPoint
function HorizontalScrollBar:onMouseButtonDown(button, mousePosition)
	if button ~= SDL.Mouse.Button.LEFT then return end

	if not SDL.pointInRectFloat(mousePosition, SDL.FRect.new(self.rect.x+self.thumbX, self.rect.y+self.bordersSizes.y, self.thumbWidth, self.rect.h-self.bordersSizes.y*2)) then
		if Sudado.hoveredElement == self then
			self.thumbX = mousePosition.x - self.thumbWidth/2 - self.rect.x
			self:fitThumb()
			self:updateParentOffset()
		else return end
	end

	Sudado.scrolling = 2
	self.dragOffsetX = self.thumbX - mousePosition.x
end

---@param mousePosition SDL.FPoint
function HorizontalScrollBar:onMouseMotion(mousePosition)
	if Sudado.scrolling & 2 ~= 0 then
		self.thumbX = mousePosition.x+self.dragOffsetX
		self:updateParentOffset()
	end

	self:fitThumb()
end

---@param width number
function HorizontalScrollBar:setWidth(width)
	local widthNoBorders = self:getWidthNoBorders()
	if widthNoBorders > 0 then
		self.thumbX = self.thumbX * (width-self.bordersSizes.x*2)/widthNoBorders
	end

	self.rect.w = width
end

function HorizontalScrollBar:onWindowResize()
	local windowSize = SDL.Video.getWindowSize(engine.getWindow())

	self:setWidth(Sudado.calculateUDimSize(windowSize.x, self.layout.size.scale.x, self.layout.size.offset.x))
	self.rect.h = Sudado.calculateUDimSize(windowSize.y, self.layout.size.scale.y, self.layout.size.offset.y)

	self.rect.x = Sudado.calculateUDimPosition(0, windowSize.x, self.rect.w, self.layout.position.scale.x, self.layout.position.offset.x, self.layout.anchor.x)
	self.rect.y = Sudado.calculateUDimPosition(0, windowSize.y, self.rect.h, self.layout.position.scale.y, self.layout.position.offset.y, self.layout.anchor.y)

	if self.children then
		Sudado.callChildrenTree(self.children, "onResize")
		Sudado.callChildrenTree(self.children, "onMove")
	end
end

function HorizontalScrollBar:onResize()
	if self.parent ~= nil then
		self:setWidth(Sudado.calculateUDimSize(self.parent.rect.w, self.layout.size.scale.x, self.layout.size.offset.x))
		self.rect.h = Sudado.calculateUDimSize(self.parent.rect.h, self.layout.size.scale.y, self.layout.size.offset.y)
	end
end

---@param direction SDL.Point
function HorizontalScrollBar:onMouseWheel(direction)
	if direction.x ~= 0 then
		self.thumbX = self.thumbX - direction.x * self.scrollSpeed * (self.thumbWidth/self.rect.w)
	end

	self:fitThumb()
	self:updateParentOffset()
end

function HorizontalScrollBar:fitThumb()
	-- if up limit
	if self.thumbX < 0 then self.thumbX = 0 end

	local width = self:getWidthNoBorders()

	-- if down limit
	if self.thumbX+self.thumbWidth > width then
		self.thumbX = width-self.thumbWidth
	end

	self.scrollValue = self.thumbX / self.thumbWidth
end

---@param viewWidth number
---@param contentWidth number
function HorizontalScrollBar:updateThumbWidth(viewWidth, contentWidth)
	if contentWidth < viewWidth then contentWidth = viewWidth end

	local width = self:getWidthNoBorders()

	local newThumbWidth = (viewWidth / contentWidth) * width
	if newThumbWidth < 1 then
		newThumbWidth = 1
	end

	self.thumbX = self.scrollValue*newThumbWidth
	self.thumbWidth = newThumbWidth
end

---@param renderer Pointer
function HorizontalScrollBar:draw(renderer)
	-- Rect
	local drawColor = Sudado.hoveredElement and self.backgroundHoveredColor or self.backgroundColor
	SDL.Render.setRenderDrawColorEx(renderer, drawColor.r, drawColor.g, drawColor.b, drawColor.a)
	SDL.Render.renderFillRect(renderer, self.rect)

	if self.thumbHovered or (Sudado.scrolling & 2 ~= 0 and Sudado.focusedElement == self) then drawColor = self.thumbHoveredColor2
	elseif Sudado.hoveredElement == self then drawColor = self.thumbHoveredColor1
	else drawColor = self.thumbColor
	end

	-- Thumb
	local drawRect = SDL.FRect.new(self.rect.x+self.bordersSizes.x+self.thumbX, self.rect.y+self.bordersSizes.y, self.thumbWidth, self.rect.h-self.bordersSizes.y*2)
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

return HorizontalScrollBar