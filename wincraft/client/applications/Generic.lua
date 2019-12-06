local Generic = {}
--local bit32 = require "bit32"
local client
local name = "Generic"

local colors = require "colors"
local sides = require "sides"

function Generic:set(aname)
	client = self; name = aname
end

--layout:addChild(client.addSyncRectangle("679688be-2198-4fdc-bc31-246d90fff87a", "2", "15", name))	
local comboBlock
local comboSide
local layoutColors	

local switchValues = function()
	layoutColors:removeChildren()
	client.stopListeningToWindowWires(name)
	for i = 0, 15 do
		layoutColors:addChild(client.addSyncSwitch(
			comboBlock:getItem(comboBlock.selectedItem).text, 
			sides[comboSide:getItem(comboSide.selectedItem).text], i, colors[i], name))
			--comboSide.selectedItem - 1, i, colors[i], name))
	end
end
	
Generic.display = function()
	local window = client.application:addChild(client.GUI.titledWindow(50, 22, 58, 22, name, true))
	window.actionButtons.close.onTouch = function() client.closeWindow(name) end--; window:close() end
	local panelHeader = window:addChild(client.GUI.panel(2, 2, window.width -2, 3, 0x880000))
	--local panelSwitches = window:addChild(client.GUI.panel(17, 6, 10, 16, 0x880000))
	local panelSwitches = window:addChild(client.GUI.panel(16, 6, 12, 16, 0x880000))
	
	local layoutChoice = window:addChild(client.GUI.layout(2, 2, window.width -2, 3, 2, 1))
	comboBlock = layoutChoice:setPosition(1, 1, layoutChoice:addChild(client.GUI.comboBox(2, 2, 20, 1, 0xEEEEEE, 0x2D2D2D, 0xCCCCCC, 0x888888)))
	for k, v in pairs (client.data) do
		comboBlock:addItem(k)
	end
	comboBlock.itemChanged = switchValues
	
	comboSide = layoutChoice:setPosition(2, 1, layoutChoice:addChild(client.GUI.comboBox(2, 2, 12, 1, 0xEEEEEE, 0x2D2D2D, 0xCCCCCC, 0x888888)))
	for i = 0, 5 do
		comboSide:addItem(sides[i])
	end
	comboSide.itemChanged = switchValues
	
	layoutColors = window:addChild(client.GUI.layout(2, 5, window.width / 2 -4, window.height -4, 1, 1))
	layoutColors:setSpacing(1,1,0)
	return window
end
	
return Generic