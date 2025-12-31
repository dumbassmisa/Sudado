---@class Sudado.TextReadOnly : Sudado.Element
---@field font Font
---@field fontHeight integer
---@field text string
---@field textColor SDL.Color
---@field readOnlyText Input.ReadOnlyText
---@field offsetX number?
---@field offsetY number?
local TextReadOnly = {
	type = Sudado.ElementType.TEXT_READ_ONLY,
	zIndex = 2,
	textColor = SDL.Color.new(255,255,255,255)
}
TextReadOnly.__index = TextReadOnly

---@param font Font
---@param fontHeight integer?
---@param layout Sudado.Layout?
---@param textColor SDL.Color?
---@param shouldWrapWidth boolean? default = false
---@param shouldWrapHeight boolean? default = false
function TextReadOnly.new(font, fontHeight, layout, textColor, shouldWrapWidth, shouldWrapHeight)
    local self = setmetatable({}, TextReadOnly)
    self.rect = SDL.FRect.new(0,0,0,0)

	self.layout = layout
	if self.layout then
		self.onWindowResize = Sudado.defaultOnWindowResize
		self.onResize = Sudado.defaultOnResize
		self.onMove = Sudado.defaultOnMove
		self:onWindowResize(SDL.FPoint.new(1,1), SDL.Point.new(1,1))
	end

	self.font = font
	self.fontHeight = fontHeight and fontHeight or self.font:getFontHeight()
	
	self.readOnlyText = Input.ReadOnlyText.new()
	self.text = ""
	if textColor then self.textColor = textColor end

	if shouldWrapWidth then
		self.offsetX = 0
	end
	if shouldWrapHeight then
		self.offsetY = 0
	end

    return self
end

function TextReadOnly:clearText()
	self.text = ''
	if self.offsetX ~= nil then
		self.offsetX = 0
	end
	if self.offsetY ~= nil then
		self.offsetY = 0
	end

	self.readOnlyText:resetSelection()
	self:updateScrollbars()
end

---@param self Sudado.TextReadOnly
function TextReadOnly:updateTextOffset()
	if self.offsetX == nil and self.offsetY == nil then return end

	if #self.text == 0 then
		if self.offsetX ~= nil then self.offsetX = 0 end
		if self.offsetY ~= nil then self.offsetY = 0 end
		return
	end

	local cursorPosition = Util.getTextPointFromIndex(
		self.text,
		self.readOnlyText.movingFromEnd and self.readOnlyText.selectionEnd or self.readOnlyText.selectionBegin,
		self.font, self.fontHeight,
		Sudado.codepointSpacing, Sudado.lineSpacing)

	if self.offsetX == nil then -- wrap text
		self.text, _ = Util.wrapText(self.text, self.rect.w, self.font, self.fontHeight, Sudado.codepointSpacing, Sudado.lineSpacing)
	else -- follow offsetX with mouse
		-- if cursor x + offset is further than width / if offset is not updated to the cursorPosition
		if cursorPosition.x-self.offsetX > self.rect.w then
			-- set offset to cursorPosition + width of '_'
			self.offsetX = cursorPosition.x-self.rect.w+self.font:measureText('_', self.fontHeight, Sudado.codepointSpacing, Sudado.lineSpacing).x

		-- offset is further than it should be
		elseif self.offsetX > cursorPosition.x then
			self.offsetX = cursorPosition.x
		end
	end

	if self.offsetY ~= nil then
		-- if cursor y + offset is further than height / if offset is not updated to the cursorPosition
		if cursorPosition.y-self.offsetY > self.rect.h then
			-- set offset to cursorPosition + height of '_'
			self.offsetY = cursorPosition.y-self.rect.h

		-- offset is further than it should be
		elseif self.offsetY > cursorPosition.y then
			self.offsetY = cursorPosition.y
		end
	end
end

---@param key SDL.Keyboard.Key
---@param isRepeat boolean
function TextReadOnly:onKeyDown(key, isRepeat)
	if Sudado.focusedElement ~= self then return end

	self.readOnlyText:onKeyDown(self.text, key, isRepeat)
end

---@param button integer
---@param mousePosition SDL.FPoint
function TextReadOnly:onMouseButtonDown(button, mousePosition)
	if Sudado.focusedElement ~= self then return end

	if button == SDL.Mouse.Button.LEFT then
		self.readOnlyText:onMouseButtonDown(
			self.text,
			self.offsetX == nil and self.rect.x or self.rect.x-self.offsetX,
			self.offsetY == nil and self.rect.y or self.rect.y-self.offsetY,
			mousePosition,
			self.font,
			self.fontHeight,
			Sudado.codepointSpacing,
			Sudado.lineSpacing
		)

		self:updateTextOffset()
	end
end

---@param mousePosition SDL.FPoint
function TextReadOnly:onMouseMotion(mousePosition)
	if Sudado.focusedElement ~= self then return end

	if SDL.Mouse.isButtonDown(SDL.Mouse.Button.LEFT) then
		self.readOnlyText:onMouseMotion(
			self.text,
			self.offsetX == nil and self.rect.x or self.rect.x-self.offsetX,
			self.offsetY == nil and self.rect.y or self.rect.y-self.offsetY,
			mousePosition,
			self.font,
			self.fontHeight,
			Sudado.codepointSpacing,
			Sudado.lineSpacing
		)

		if Input.getTextSelectMode() == 2 then
			self:updateTextOffset()
		end
	end
end

---@param renderer Pointer
function TextReadOnly:draw(renderer)
	local position = SDL.FPoint.new(self.offsetX == nil and self.rect.x or self.rect.x-self.offsetX, self.offsetY == nil and self.rect.y or self.rect.y-self.offsetY)

	SDL.Render.setRenderClipRect(renderer, SDL.fRectToRect(self.rect))

	self.font:render(renderer, self.text, self.fontHeight, position.x, position.y, self.textColor.r, self.textColor.g, self.textColor.b, self.textColor.a, Sudado.codepointSpacing, Sudado.lineSpacing)

	SDL.Render.renderTextSelection(renderer, self.text, Sudado.textSelectionColor, position, self.readOnlyText.selectionBegin, self.readOnlyText.selectionEnd, self.font, self.fontHeight, Sudado.codepointSpacing, Sudado.lineSpacing)

	SDL.Render.setRenderClipRect(renderer, nil)
end

function TextReadOnly:updateScrollbars()
	if self.verticalScrollBar == nil and self.horizontalScrollBar == nil then
		return
	end

	local contentSize = self.font:measureText(self.text, self.fontHeight, Sudado.codepointSpacing, Sudado.lineSpacing)
	if self.horizontalScrollBar ~= nil then
		self.horizontalScrollBar:updateThumbWidth(self.rect.w, contentSize.x)
		self.horizontalScrollBar:fitThumb()
		self.horizontalScrollBar:updateParentOffset()
		Sudado.setVisibility(self.horizontalScrollBar, self.horizontalScrollBar:shouldBeVisible())
	end

	if self.verticalScrollBar ~= nil then
		self.verticalScrollBar:updateThumbHeight(self.rect.h, contentSize.y)
		self.verticalScrollBar:fitThumb()
		self.verticalScrollBar:updateParentOffset()
		Sudado.setVisibility(self.verticalScrollBar, self.verticalScrollBar:shouldBeVisible())
	end
end

return TextReadOnly