---@diagnostic disable: need-check-nil
---@alias Sudado.IsPointCollidingDragRegion fun(self: any, point: SDL.FPoint): boolean
---@alias Sudado.GetResizeRegionFromPointCollision fun(self: any, point: SDL.Point): Sudado.ResizeRegion

---@alias Sudado.OnWindowResize fun(self: Sudado.Element, ratio: SDL.FPoint, delta: SDL.Point)

---@alias Sudado.OnFocus fun(self: Sudado.Element, oldObject: Sudado.Element|nil)
---@alias Sudado.OnUnfocus fun(self: Sudado.Element, newObject: Sudado.Element|nil)

---@alias Sudado.OnHover fun(self: Sudado.Element, oldObject: Sudado.Element|nil)
---@alias Sudado.OnUnhover fun(self: Sudado.Element, newObject: Sudado.Element|nil)

---@alias Sudado.OnResize fun(self: Sudado.Element)
---@alias Sudado.OnMove fun(self: Sudado.Element)

---@alias Sudado.OnMousePress fun(self: Sudado.Element, button: integer, mousePosition: SDL.FPoint)
---@alias Sudado.OnMouseMove fun(self: Sudado.Element, mousePosition: SDL.FPoint, mouseDelta: SDL.Point)
---@alias Sudado.OnMouseUp fun(self: Sudado.Element, button: integer, mousePosition: SDL.FPoint)
---@alias Sudado.OnMouseWheel fun(slef: Sudado.Element, direction: SDL.Point, mousePosition: SDL.FPoint)

---@alias Sudado.Update fun(self: Sudado.Element)
---@alias Sudado.Draw fun(self: Sudado.Element, renderer: Pointer)

---@alias Sudado.OnKeyboardPress fun(self: Sudado.Element, key: SDL.Keyboard.Key, isRepeat: boolean)
---@alias Sudado.OnCharPress fun(self: Sudado.Element, codepoints: string)

---@alias Sudado.Children Sudado.Element[]

---@class Sudado.Element
---@field type Sudado.ElementType
---@field zIndex number DO NOT FORGET TO USE `Sudado.sortElementsByZIndex` WHEN MODIFYING THIS VARIABLE!
---@field visible boolean
---@field _visible boolean Checks if element is visible related to parent.
---@field rect SDL.FRect
---@field draw Sudado.Draw
---@field layout Sudado.Layout?
---@field parent Sudado.Element?
---@field children Sudado.Children?
---@field verticalScrollBar Sudado.VerticalScrollBar?
---@field horizontalScrollBar Sudado.HorizontalScrollBar?
---@field offsetX number?
---@field offsetY number?
---@field minSize SDL.Point?
---@field maxSize SDL.Point?
---@field resizable boolean?
---@field getResizeRegionFromPointCollision Sudado.GetResizeRegionFromPointCollision?
---@field draggable boolean?
---@field isPointCollidingDragRegion Sudado.IsPointCollidingDragRegion?
---@field dragOffset SDL.Point?
---@field backgroundColor SDL.Color?
---@field bordersSizes SDL.Rect|SDL.Point?
---@field borderColor SDL.Color?
---@field updateScrollbars fun(self: Sudado.Element)?
---@field onWindowResize Sudado.OnWindowResize?
---@field onResize Sudado.OnResize? when screen resizes or parent resizes this is called
---@field onMove Sudado.OnMove? when parent moves this is called. This is more for Sudado.Window to move its children
---@field onFocus Sudado.OnFocus?
---@field onUnfocus Sudado.OnUnfocus?
---@field onHover Sudado.OnHover?
---@field onUnhover Sudado.OnUnhover?
---@field onKeyDown Sudado.OnKeyboardPress?
---@field onTextInput Sudado.OnCharPress?
---@field onMouseButtonDown Sudado.OnMousePress?
---@field onMouseMotion Sudado.OnMouseMove?
---@field onMouseButtonUp Sudado.OnMouseUp?
---@field onMouseWheel Sudado.OnMouseWheel?
---@field update Sudado.Update?

---@class Sudado
Sudado = {
	---@type Sudado.Element[]
	elements = {},
	---@type Sudado.Element|nil
	focusedElement = nil,
	---@type Sudado.Element|nil
	hoveredElement = nil,
	---@type Sudado.Button|nil
	pressedElement = nil,

	---@enum Sudado.ResizeRegion
	ResizeRegion = {
		NONE = 0,
		TOP = 1,
		BOTTOM = 2,
		LEFT = 3,
		RIGHT = 4,
		TOPLEFT = 5,
		TOPRIGHT = 6,
		BOTTOMLEFT = 7,
		BOTTOMRIGHT = 8,
	},

	---@type Sudado.ResizeRegion
	resizeRegion = 0,
	---@type Sudado.ResizeRegion
	hoveredResizeRegion = 0,

	dragging = false,
	resizing = false,
	--- 0 = none; 1 = vertically; 2 = horizontally; 3 = both
	scrolling = 0,

	---@enum Sudado.ElementType
	ElementType = {
		NONE = 0,
		WINDOW = 1,
		BUTTON = 2,
		RECTANGLE = 3,
		TEXT_INPUT = 4,
		TEXT_INPUT_MULTI_LINE = 5,
		TEXT_READ_ONLY = 6,
		TEXT_READ_ONLY_MULTI_LINE = 7,
		RICH_TEXT_BOX = 8,
		VERTICAL_SCROLL_BAR = 9,
		HORIZONTAL_SCROLL_BAR = 10
	},

	codepointSpacing = 1,
	lineSpacing = 2,

	textCursorColor = SDL.Color.new(240,240,240,255),
	textSelectionColor = SDL.Color.new(255,255,255,50),

	cursorBlinkTimer = 0.0,
	cursorBlinkInterval = 0.5,
	shouldDrawCursor = true,

	---@type Font
	defaultFont = nil,
	---@type Font
	defaultBoldFont = nil,
	---@type Font
	defaultItalicFont = nil,

	---@type Pointer?
	currentCursor = nil
}

Sudado.defaultBoldFont = Sudado.defaultFont
Sudado.defaultItalicFont = Sudado.defaultFont

Sudado.UDim2 = require('Sudado.UDim2')
Sudado.Layout = require('Sudado.Layout')
Sudado.RichText = require('Sudado.RichText')

Sudado.setMouseCursor, Sudado.cursorOnMouseMove = require('Sudado.Cursor')()

Sudado.Window = require('Sudado.Element.Window')
Sudado.Button = require('Sudado.Element.Button')
Sudado.Rectangle = require('Sudado.Element.Rectangle')
Sudado.TextInput = require('Sudado.Element.TextInput')
Sudado.TextReadOnly = require('Sudado.Element.TextReadOnly')
Sudado.RichTextBox = require('Sudado.Element.RichTextBox')
Sudado.VerticalScrollBar = require('Sudado.Element.VerticalScrollBar')
Sudado.HorizontalScrollBar = require('Sudado.Element.HorizontalScrollBar')

---@param element Sudado.Element
---@param ratio SDL.Point
function Sudado.defaultOnWindowResize(element, ratio)
	if element.layout == nil then
		jePrint(PrintLevel.ERROR, 'Element with no layout is trying to call default onWindowResize event\n')
		return
	end

	local windowSize = SDL.Video.getWindowSize(engine.getWindow())

	if element.resizable then
		element.rect.w = element.rect.w * ratio.x
		element.rect.h = element.rect.h * ratio.y
	else
		element.rect.w = Sudado.calculateUDimSize(windowSize.x, element.layout.size.scale.x, element.layout.size.offset.x)
		element.rect.h = Sudado.calculateUDimSize(windowSize.y, element.layout.size.scale.y, element.layout.size.offset.y)
	end
	if element.draggable then
		element.rect.x = element.rect.x * ratio.x
		element.rect.y = element.rect.y * ratio.y
	else
		element.rect.x = Sudado.calculateUDimPosition(0, windowSize.x, element.rect.w, element.layout.position.scale.x, element.layout.position.offset.x, element.layout.anchor.x)
		element.rect.y = Sudado.calculateUDimPosition(0, windowSize.y, element.rect.h, element.layout.position.scale.y, element.layout.position.offset.y, element.layout.anchor.y)
	end

	if element.children then
		Sudado.callChildrenTree(element.children, "onResize")
		Sudado.callChildrenTree(element.children, "onMove")
	end

	if element.updateScrollbars then element:updateScrollbars() end
end

function Sudado.defaultOnResize(element)
	if element.layout == nil then
		jePrint(PrintLevel.ERROR, 'Element with no layout is trying to call default onResize event\n')
		return
	end

	if element.parent ~= nil then
		element.rect.w = Sudado.calculateUDimSize(element.parent.rect.w, element.layout.size.scale.x, element.layout.size.offset.x)
		element.rect.h = Sudado.calculateUDimSize(element.parent.rect.h, element.layout.size.scale.y, element.layout.size.offset.y)
	end

	if element.updateScrollbars then element:updateScrollbars() end
end

function Sudado.defaultOnMove(element)
	if element.layout == nil then
		jePrint(PrintLevel.WARNING, 'Element with no layout using default onMove event\n')
		return
	end

	if element.parent ~= nil then
		element.rect.x = Sudado.calculateUDimPosition(element.parent.rect.x, element.parent.rect.w, element.rect.w, element.layout.position.scale.x, element.layout.position.offset.x, element.layout.anchor.x)
		element.rect.y = Sudado.calculateUDimPosition(element.parent.rect.y, element.parent.rect.h, element.rect.h, element.layout.position.scale.y, element.layout.position.offset.y, element.layout.anchor.y)
	end
end

---@param element Sudado.Element
function Sudado.getRootParent(element)
	---@type Sudado.Element
	local rootParent = element
	while rootParent.parent ~= nil do
		---@type Sudado.Element
		rootParent = rootParent.parent
	end

	return rootParent
end

--- Required when setting element zIndex. If missed, input can be messed up.
---@param a Sudado.Element
---@param b Sudado.Element
function Sudado.sortElementsByZIndex(a, b)
	return a.zIndex < b.zIndex
end

---@param instance Sudado.Element
---@param parent Sudado.Element
function Sudado.setParent(instance, parent)
	if parent == nil then
		if instance.parent ~= nil then
			for k,v in pairs(instance.parent) do
				if v == instance then
					table.remove(instance.parent, k)
					break
				end
			end
		end

		instance.parent = nil
		instance._visible = instance.visible

		if instance.onWindowResize then
			instance:onWindowResize(SDL.FPoint.new(1,1), SDL.Point.new(1,1))
		else
			if instance.onResize then
				instance:onResize()
			else
				jePrint(PrintLevel.WARNING, 'No onResize event found for neither root parent, parent or instance when setting parent\n')
				return
			end

			if instance.onMove then
				instance:onMove()
			else
				jePrint(PrintLevel.WARNING, 'No onMove event found for neither root parent, parent or instance when setting parent\n')
				return
			end
		end
		return
	end

	if parent.children == nil then
		parent.children = {}
	end

	if instance.parent and instance.parent.children ~= nil then
		for i,child in pairs(instance.parent.children) do
			if child == instance then
				instance.parent.children[i] = nil
				break
			end
		end
		if #instance.parent.children == 0 then instance.parent.children = nil end
	end

	parent.children[#parent.children+1] = instance
	instance.parent = parent

	local rootParent = Sudado.getRootParent(parent)
	if rootParent.onWindowResize then
		rootParent:onWindowResize(SDL.FPoint.new(1,1), SDL.Point.new(1,1))
	else
		if rootParent.onResize then
			rootParent:onResize()
		elseif parent.onResize then
			parent:onResize()
		elseif instance.onResize then
			instance:onResize()
		else
			jePrint(PrintLevel.WARNING, 'No onResize event found for neither root parent, parent or instance when setting parent\n')
			return
		end
		if rootParent.onMove then
			rootParent:onMove()
		elseif parent.onMove then
			parent:onMove()
		elseif instance.onMove then
			instance:onMove()
		else
			jePrint(PrintLevel.WARNING, 'No onMove event found for neither root parent, parent or instance when setting parent\n')
			return
		end
	end

	Sudado.setVisibility(instance, instance.visible)
end

---@param element Sudado.Element
function Sudado.setFocusedElement(element)
	if Sudado.focusedElement and Sudado.focusedElement.onUnfocus then
		Sudado.focusedElement:onUnfocus(Sudado.hoveredElement)
	end
	if element and element.onFocus then
		element:onFocus(Sudado.focusedElement)
	end

	Sudado.focusedElement = element
end

--- Children is checked and seen if they have funcName. Their children are ignored.
---@param children Sudado.Children
---@param funcName string
function Sudado.callChildren(children, funcName)
	for _,v in pairs(children) do
		if v[funcName] then
			v[funcName](v)
		end
	end
end

--- Every child is checked and seen if they have funcName.
---@param children Sudado.Children
---@param funcName string
function Sudado.callChildrenTree(children, funcName)
	local temp = {{children=children, index=0}}

	children = temp[1].children
	local i = 0
	while #temp ~= 0 do
		i = i + 1
		temp[#temp].index = i

		if children[i][funcName] then
			children[i][funcName](children[i])
		end

		if children[i].children then
			temp[#temp+1] = {children=children[i].children, index=0}
			children = temp[#temp].children
			i = 0
		end

		while i >= #children do
			temp[#temp] = nil
			if temp[#temp] == nil then -- weird looking code
				break
			end

			children = temp[#temp].children
			i = temp[#temp].index
		end
	end
end

--- Calls callback for every child there is connected to the children parameter
---@param children Sudado.Children
---@param callback fun(children: Sudado.Children, index: integer)
function Sudado.customChildrenTreeCallback(children, callback)
	local temp = {{children=children, index=0}}

	children = temp[1].children
	local i = 0
	while #temp ~= 0 do
		i = i + 1
		temp[#temp].index = i

		callback(children, i)

		if children[i].children then
			temp[#temp+1] = {children=children[i].children, index=0}
			children = temp[#temp].children
			i = 0
		end

		while i >= #children do
			temp[#temp] = nil
			if temp[#temp] == nil then -- weird looking code
				break
			end

			children = temp[#temp].children
			i = temp[#temp].index
		end
	end
end

function Sudado.resetTextCursor()
	Sudado.cursorBlinkTimer = 0.0
	Sudado.shouldDrawCursor = true
end

---@param key SDL.Keyboard.Key
---@param isRepeat boolean
function Sudado.onKeyDown(key, isRepeat)
	Sudado.resetTextCursor()

	if Sudado.focusedElement and Sudado.focusedElement.onKeyDown then
		Sudado.focusedElement:onKeyDown(key, isRepeat)
	end

	-- I don't know why would the hover element care about char press but I did this anyway : Suado Cowboy - 2025-06-11
	if Sudado.hoveredElement and Sudado.focusedElement ~= Sudado.hoveredElement and Sudado.hoveredElement.onKeyDown then
		Sudado.hoveredElement:onKeyDown(key, isRepeat)
	end
end

---@param codepoints string
function Sudado.onTextInput(codepoints)
	if Sudado.focusedElement and Sudado.focusedElement.onTextInput then
		Sudado.focusedElement:onTextInput(codepoints)
	end

	-- I don't know why would the hover element care about char press but I did this anyway : Suado Cowboy - 2025-06-11
	if Sudado.hoveredElement and Sudado.focusedElement ~= Sudado.hoveredElement and Sudado.focusedElement ~= Sudado.hoveredElement and Sudado.hoveredElement.onTextInput then
		Sudado.hoveredElement:onTextInput(codepoints)
	end
end

---@param button integer
---@param mousePosition SDL.FPoint
function Sudado.onMouseButtonDown(button, mousePosition)
	Sudado.resetTextCursor()

	if Sudado.hoveredElement ~= Sudado.focusedElement then
		Sudado.setFocusedElement(Sudado.hoveredElement)
	end

	if Sudado.focusedElement and Sudado.focusedElement.onMouseButtonDown then Sudado.focusedElement:onMouseButtonDown(button, mousePosition) end
	if Sudado.hoveredElement and Sudado.focusedElement ~= Sudado.hoveredElement and Sudado.hoveredElement.onMouseButtonDown then Sudado.hoveredElement:onMouseButtonDown(button, mousePosition) end
end

---@param mousePosition SDL.FPoint
---@param mouseDelta SDL.Point
function Sudado.onMouseMotion(mousePosition, mouseDelta)
	---@type Sudado.Element?
	local newHoveredElement = nil
	for _, e in ipairs(Sudado.elements) do
		if SDL.pointInRectFloat(mousePosition, e.rect) then
			newHoveredElement = e
		end
	end

	-- if not hovering anything
	if newHoveredElement ~= Sudado.hoveredElement then
		if Sudado.hoveredElement and Sudado.hoveredElement.onUnhover then
			Sudado.hoveredElement:onUnhover(newHoveredElement)
		end
		if newHoveredElement and newHoveredElement.onHover then
			newHoveredElement:onHover(Sudado.hoveredElement)
		end

		Sudado.hoveredElement = newHoveredElement
	end

	if Sudado.focusedElement and Sudado.focusedElement.onMouseMotion then
		Sudado.focusedElement:onMouseMotion(mousePosition, mouseDelta)
	end
	if Sudado.hoveredElement and Sudado.focusedElement ~= Sudado.hoveredElement and Sudado.hoveredElement.onMouseMotion then
		Sudado.hoveredElement:onMouseMotion(mousePosition, mouseDelta)
	end

	-- If neither the focused or hovered elements are resizable
	if (Sudado.focusedElement == nil or Sudado.focusedElement.resizable ~= true)
	and (Sudado.hoveredElement == nil or Sudado.hoveredElement.resizable ~= true) then
		Sudado.resizeRegion = Sudado.ResizeRegion.NONE
	end

	Sudado.cursorOnMouseMove(mousePosition)
end


---@param button integer
---@param mousePosition SDL.FPoint
function Sudado.onMouseButtonUp(button, mousePosition)
	if Sudado.focusedElement and Sudado.focusedElement.onMouseButtonUp then Sudado.focusedElement:onMouseButtonUp(button, mousePosition) end
	if Sudado.hoveredElement and Sudado.focusedElement ~= Sudado.hoveredElement and Sudado.hoveredElement.onMouseButtonUp then Sudado.hoveredElement:onMouseButtonUp(button, mousePosition) end

	Sudado.resizeRegion = Sudado.ResizeRegion.NONE
	Sudado.resizing = false
	Sudado.dragging = false
	Sudado.scrolling = 0

	Input.textOnMouseUp();
end

---@param direction SDL.Point
---@param mousePosition SDL.FPoint
function Sudado.onMouseWheel(direction, mousePosition)
	if Sudado.focusedElement and Sudado.focusedElement.onMouseWheel then Sudado.focusedElement:onMouseWheel(direction, mousePosition) end

	if Sudado.hoveredElement then
		if Sudado.focusedElement ~= Sudado.hoveredElement and Sudado.hoveredElement.onMouseWheel then Sudado.hoveredElement:onMouseWheel(direction, mousePosition) end

		if Sudado.hoveredElement.verticalScrollBar then
			Sudado.hoveredElement.verticalScrollBar:onMouseWheel(direction)
		end
		if Sudado.hoveredElement.horizontalScrollBar then
			Sudado.hoveredElement.horizontalScrollBar:onMouseWheel(direction)
		end
	end

end

function Sudado.update()
	Sudado.cursorBlinkTimer = Sudado.cursorBlinkTimer + engine.getDeltaTime()
	if Sudado.cursorBlinkTimer >= Sudado.cursorBlinkInterval then
		Sudado.shouldDrawCursor = not Sudado.shouldDrawCursor
		Sudado.cursorBlinkTimer = 0.0
	end

	for _, e in ipairs(Sudado.elements) do
		if e and e.update then e:update() end
	end
end

---@param ratio SDL.FPoint
---@param delta SDL.Point
function Sudado.onWindowResize(ratio, delta)
	for _,e in pairs(Sudado.elements) do
		if e.parent == nil and e.onWindowResize then e:onWindowResize(ratio, delta) end
	end
end

---@param renderer Pointer
function Sudado.draw(renderer)
	for _, e in ipairs(Sudado.elements) do
		if e and e._visible then
			e:draw(renderer)
		end
	end
end

---@param element Sudado.Element
---@param visible boolean? true by default
function Sudado.add(element, visible)
	Sudado.setVisibility(element, visible ~= nil and visible or true)

	table.insert(Sudado.elements, element)

	if #Sudado.elements > 1 and Sudado.elements[#Sudado.elements-1].zIndex > element.zIndex then
		table.sort(Sudado.elements, Sudado.sortElementsByZIndex)
	end
end

---@param element Sudado.Element
---@param visible boolean
function Sudado.setVisibility(element, visible)
	element.visible = visible

	if visible then
		local parent = element.parent
		while parent ~= nil do
			if not parent._visible then
				element._visible = false
				return
			end

			parent = parent.parent
		end

		element._visible = true
	else
		element._visible = false
	end

	if element.children ~= nil then
		---@param children Sudado.Children
		---@param i integer
		Sudado.customChildrenTreeCallback(element.children, function(children, i)
			if children[i].visible then
				children[i]._visible = element._visible
			end
		end)
	end
end

return Sudado