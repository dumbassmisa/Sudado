---@class Sudado.RichTextBox : Sudado.Element
---@field font Font
---@field fontHeight integer
---@field text string
---@field richTexts Sudado.RichText[] **NOT** splitted by newline('\n')
---@field readOnlyText Input.ReadOnlyText
---@field offsetX number
---@field offsetY number
local RichTextBox = {
	type = Sudado.ElementType.RICH_TEXT_BOX,
	zIndex = 2
}
RichTextBox.__index = RichTextBox

---@param font Font
---@param fontHeight integer
---@param layout Sudado.Layout?
---@param shouldWrapWidth boolean? default false
---@param shouldWrapHeight boolean? default false
function RichTextBox.new(font, fontHeight, layout, shouldWrapWidth, shouldWrapHeight)
    local self = setmetatable({}, RichTextBox)
    self.rect = SDL.FRect.new(0,0,0,0)

	self.layout = layout
	if self.layout then
		self.onWindowResize = Sudado.defaultOnWindowResize
		self.onResize = Sudado.defaultOnResize
		self.onMove = Sudado.defaultOnMove
		self:onWindowResize(SDL.FPoint.new(1,1), SDL.Point.new(1,1))
	end

	self.font = font
	self.fontHeight = fontHeight

	self.text = ""

	self.readOnlyText = Input.ReadOnlyText.new()
	self.richTexts = {}

	if not shouldWrapWidth then
		self.offsetX = 0
	end
	if not shouldWrapHeight then
		self.offsetY = 0
	end

    return self
end

function RichTextBox:updateScrollbars()
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

--- Gets rect.x + offsetX if offsetX is not nil.
function RichTextBox:getRectX()
	return self.offsetX == nil and self.rect.x or self.rect.x-self.offsetX
end

--- Gets rect.y + offsetY if offsetY is not nil.
function RichTextBox:getRectY()
	return self.offsetY == nil and self.rect.y or self.rect.y-self.offsetY
end

--- **It does not call self:updateTextOffset() nor self:updateScrollbars()**
---@param text string
---@param flags integer?
---@param color SDL.Color?
---@param splitNewLine boolean? default is true
function RichTextBox:appendText(text, flags, color, splitNewLine)
	if splitNewLine == true or splitNewLine == nil then
		local richTexts = Sudado.RichText.splitNewLineToRichText(text, self.font, self.fontHeight, flags, color)

		for _, richText in pairs(richTexts) do
			self.richTexts[#self.richTexts+1] = richText
		end

		self.text = self.text .. text
	else
		local beginIndex = #self.text+1
		self.text = self.text .. text
		self.richTexts[#self.richTexts+1] = Sudado.RichText.new(self.text:sub(beginIndex), self.font, self.fontHeight, flags, color)
	end
end

function RichTextBox:clearText()
	self.text = ""
	self.richTexts = {}
	if self.offsetX ~= nil then
		self.offsetX = 0
	end
	if self.offsetY ~= nil then
		self.offsetY = 0
	end

	self.readOnlyText:resetSelection()
	self:updateScrollbars()
end

---@param index integer
function RichTextBox:popRichText(index)
	if #self.richTexts == index then
		self.richTexts[index] = nil
	end

	local textIndex = 1
	for i=1, #self.richTexts do
		if i == index then
			self.text = self.text:sub(0, textIndex-1) .. self.text:sub(textIndex+self.richTexts[i].length)
			break
		end
		textIndex = textIndex + self.richTexts[i].length
	end


	for i=index, #self.richTexts do
		self.richTexts[i] = self.richTexts[i+1]
	end
end

function RichTextBox:updateTextOffset()
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
		local previousTextLength, addedNewlines, wrappedText
		local textIndex = 1
		for _,richText in pairs(self.richTexts) do
			if richText.width > self.rect.w then
				wrappedText, _ = Util.wrapText(self.text, self.rect.w, self.font, self.fontHeight, Sudado.codepointSpacing, Sudado.lineSpacing)

				if textIndex == 1 then
					self.text = wrappedText .. self.text:sub(textIndex+richText.length)
				else
					self.text = self.text:sub(1, textIndex) .. wrappedText ..  self.text:sub(textIndex+richText.length)
				end

				richText:updateText(wrappedText, self.font, self.fontHeight)
			end

			textIndex = textIndex+richText.length
		end
	elseif Sudado.scrolling & 2 ~= 0 then -- follow offsetX with mouse
		-- if cursor x + offset is further than width / if offset is not updated to the cursorPosition
		if cursorPosition.x-self.offsetX > self.rect.w then
			-- set offset to cursorPosition + width of '_'
			self.offsetX = cursorPosition.x-self.rect.w+self.font:measureText('_', self.fontHeight, Sudado.codepointSpacing, Sudado.lineSpacing).x

		-- offset is further than it should be
		elseif self.offsetX > cursorPosition.x then
			self.offsetX = cursorPosition.x
		end
	end

	if self.offsetY ~= nil and Sudado.scrolling & 1 ~= 0 then
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
function RichTextBox:onKeyDown(key, isRepeat)
	if Sudado.focusedElement ~= self then return end

	self.readOnlyText:onKeyDown(self.text, key, isRepeat)
end

---@param button integer
---@param mousePosition SDL.FPoint
function RichTextBox:onMouseButtonDown(button, mousePosition)
	if Sudado.focusedElement ~= self then return end

	if button == SDL.Mouse.Button.LEFT then
		if #self.text ~= 0 then
			self.readOnlyText:onMouseButtonDown(
				self.text,
				self:getRectX(),
				self:getRectY(),
				mousePosition,
				self.font,
				self.fontHeight,
				Sudado.codepointSpacing,
				Sudado.lineSpacing
			)
		end

		self:updateTextOffset()
	end
end

---@param mousePosition SDL.FPoint
function RichTextBox:onMouseMotion(mousePosition)
	if Sudado.focusedElement ~= self then return end

	if SDL.Mouse.isButtonDown(SDL.Mouse.Button.LEFT) then
		if #self.richTexts ~= 0 then
			self.readOnlyText:onMouseMotion(
				self.text,
				self:getRectX(),
				self:getRectY(),
				mousePosition,
				self.font,
				self.fontHeight,
				Sudado.codepointSpacing,
				Sudado.lineSpacing
			)
		end

		if Input.getTextSelectMode() == 2 then
			self:updateTextOffset()
		end
	end
end

---@param renderer Pointer
function RichTextBox:draw(renderer)
	if #self.richTexts == 0 then return end

	local originalPosition = SDL.FPoint.new(self:getRectX(), self:getRectY())
	local position = SDL.FPoint.new(originalPosition.x, originalPosition.y)

	SDL.Render.setRenderClipRect(renderer, SDL.fRectToRect(self.rect))

	local textIndex = 1
	for i=1, #self.richTexts do
		self.richTexts[i]:draw(renderer, self.text, textIndex, position, self.font, self.fontHeight)

		if self.text:sub(textIndex+self.richTexts[i].length-1, textIndex+self.richTexts[i].length-1) == '\n' then
			position.x = originalPosition.x
			position.y = position.y + self.richTexts[i].height
		else
			position.x = position.x + self.richTexts[i].width + Sudado.codepointSpacing
		end

		textIndex = textIndex+self.richTexts[i].length
	end

	SDL.Render.renderTextSelection(renderer, self.text, Sudado.textSelectionColor, originalPosition, self.readOnlyText.selectionBegin, self.readOnlyText.selectionEnd, self.font, self.fontHeight, Sudado.codepointSpacing, Sudado.lineSpacing)

	SDL.Render.setRenderClipRect(renderer, nil)
end

return RichTextBox