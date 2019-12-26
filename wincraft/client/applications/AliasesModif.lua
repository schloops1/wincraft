local AliasesModif = {}
local colors = require "colors"
local sides = require "sides"
local dmp = require "dump"

local aliasNode = require "AliasNode"

local client
local name

function AliasesModif:set(aname)
	client = self; name = aname
end

local tree
local containerHEAD, containerCRUD, containerButtons
local nameField
local oldName
local typeField, doorField, blockField, sideField, colorField

local function cleanUp()
	containerHEAD:removeChildren()
	containerCRUD:removeChildren()
	client.stopListeningToWindowWires(name)
end

local function offOnAlias(charge)
	local selectedName = tree:getSelectedName()
	client.offOnAlias(selectedName, charge)
end

local function upDownAlias(upDown)
	local selectedName = tree:getSelectedName()
	local selectedAlias = tree.getDataNode(tree.dataNode, selectedName)
	local selectedParentAlias = tree.getParentDataNode(tree.dataNode, selectedName)
	local i 
	local max
	for k, v in ipairs(selectedParentAlias.children) do
		if selectedAlias.name == v.name then
			i = k
		end
		max = k
	end
	if upDown then
		if i >= max then return end
	else
		if i <= 1 then return end
	end
	client.upDownAlias(selectedParentAlias.name, i, upDown)
end

local function updateAlias()
	if oldName ~= nameField.text and not aliasNode.isNew(tree.dataNode, nameField.text) then return end
	local origAlias = tree.getDataNode(tree.dataNode, tree:getSelectedName())
	local alias = {}
	alias.name = nameField.text
	alias.node = origAlias.node
	if alias.node then
		alias.exp = origAlias.exp		
		alias.children = origAlias.children
	else
		if doorField.selectedItem == 1 then	alias.door = false else alias.door = true end
		alias.block = blockField:getItem(blockField.selectedItem).text
		alias.side = sides[sideField:getItem(sideField.selectedItem).text]
		alias.color = colors[colorField:getItem(colorField.selectedItem).text]
	end
	client.updateAlias(oldName, alias.name, alias)
	cleanUp()
end

local function deleteAlias()
	local alias = tree.getDataNode(tree.dataNode, tree:getSelectedName())
	if alias.node and #alias.children > 0 then return end
	client.deleteAlias(alias.name)
	cleanUp()
end

local function insertAliasNode()
	if oldName == nameField.text or not aliasNode.isNew(tree.dataNode, nameField.text) then return end
	local parent
	local selected = tree.getDataNode(tree.dataNode, tree:getSelectedName())
	if selected.node then
		parent = selected
	else
		parent = tree.getParentDataNode(tree.dataNode, tree:getSelectedName())
	end
	local alias = {}
	alias.name = nameField.text
	alias.node = true
	alias.exp = true
	alias.children = {}
	client.insertAlias(parent.name, alias.name, alias)
	cleanUp()
end

local function insertAliasLeaf()
	if oldName == nameField.text or not aliasNode.isNew(tree.dataNode, nameField.text) then return end
	local parent
	local selected = tree.getDataNode(tree.dataNode, tree:getSelectedName())
	if selected.node then
		parent = selected
	else
		parent = tree.getParentDataNode(tree.dataNode, tree:getSelectedName())
	end
	local alias = {}
	alias.name = nameField.text
	alias.node = false
	if 	blockField ~= nil then
		if doorField.selectedItem == 1 then	alias.door = false else alias.door = true end
		alias.block = blockField:getItem(blockField.selectedItem).text
		alias.side = sides[sideField:getItem(sideField.selectedItem).text]
		alias.color = colors[colorField:getItem(colorField.selectedItem).text]
	else
		for k, v in pairs(client.data) do
			alias.block = k; break
		end
		alias.side = 1
		alias.color = 1
	end
	client.insertAlias(parent.name, alias.name, alias)
	cleanUp()
end

local function displayHEAD(alias)
	containerHEAD:addChild(client.GUI.text(2, 2, 0xFFFFFF, "Name:"))
	nameField = containerHEAD:addChild(client.GUI.input(8, 2, 19, 1, 0xEEEEEE, 0x555555, 0x999999, 0xFFFFFF, 0x2D2D2D, "", ""))
	oldName = alias.name
	nameField.text = alias.name
	local isNode; if alias.node then isNode = "yes" else isNode = "no" end
	containerHEAD:addChild(client.GUI.text(30, 2, 0xFFFFFF, "Node: "..isNode))
	
	local offButton = containerHEAD:addChild(client.GUI.button(2, 4, 8, 1, 0xFFEFFF, 0x555555, 0x880000, 0xFFFFFF, "Off"))
	offButton.onTouch = function() offOnAlias(0) end
	local onButton = containerHEAD:addChild(client.GUI.button(12, 4, 8, 1, 0xFFEFFF, 0x555555, 0x880000, 0xFFFFFF, "On"))
	onButton.onTouch = function() offOnAlias(255) end
	
	if alias.node == false then
		local displayState = client.addSyncRectangle(alias.block, alias.side, alias.color, name)
		displayState.x = 22; displayState.y = 4; displayState.width = 6
		containerHEAD:addChild(displayState)
	end
end

local function displayCRUD(alias)
	if not alias.node then
		containerCRUD:addChild(client.GUI.text(2, 2, 0xFFFFFF, "Type:"))
		typeField = containerCRUD:addChild(client.GUI.comboBox(8, 2, 10, 1, 0xEEEEEE, 0x2D2D2D, 0xCCCCCC, 0x888888))
		typeField:addItem("Output")
	
		containerCRUD:addChild(client.GUI.text(20, 2, 0xFFFFFF, "IsDoor:"))
		doorField = containerCRUD:addChild(client.GUI.comboBox(28, 2, 6, 1, 0xEEEEEE, 0x2D2D2D, 0xCCCCCC, 0x888888))
		doorField:addItem("No");doorField:addItem("Yes")
		if alias ~= nil and alias.door then doorField.selectedItem = 2 else doorField.selectedItem = 1 end
	
		blockField = containerCRUD:addChild(client.GUI.comboBox(2, 4, 40, 1, 0xEEEEEE, 0x2D2D2D, 0xCCCCCC, 0x888888))
		local ii = 1
		local iiSelected
		for k, v in pairs (client.data) do
			blockField:addItem(k)
			if alias ~= nil and k == alias.block then iiSelected = ii end
			ii = ii + 1
		end
		if iiSelected == nil then iiSelected = 1 end
		blockField.selectedItem = iiSelected

		containerCRUD:addChild(client.GUI.text(2, 6, 0xFFFFFF, "Side:"))
		sideField = containerCRUD:addChild(client.GUI.comboBox(8, 6, 10, 1, 0xEEEEEE, 0x2D2D2D, 0xCCCCCC, 0x888888))
		for i = 0, 5 do
			sideField:addItem(sides[i])
		end
		if alias ~= nil then sideField.selectedItem = alias.side + 1 end

		containerCRUD:addChild(client.GUI.text(20, 6, 0xFFFFFF, "Color:"))
		colorField = containerCRUD:addChild(client.GUI.comboBox(27, 6, 10, 1, 0xEEEEEE, 0x2D2D2D, 0xCCCCCC, 0x888888))
		for i = 0, 15 do
			colorField:addItem(colors[i])
		end
		if alias ~= nil then colorField.selectedItem = alias.color + 1 end
	end	
end

local function displayButtons()
	local updateButton = containerButtons:addChild(client.GUI.button(2, 2, 5, 1, 0xFFEFFF, 0x555555, 0x880000, 0xFFFFFF, "Upd"))
	updateButton.onTouch = function() updateAlias() end
	local deleteButton = containerButtons:addChild(client.GUI.button(9, 2, 5, 1, 0xFFEFFF, 0x555555, 0x880000, 0xFFFFFF, "Del"))
	deleteButton.onTouch = function() deleteAlias() end
	local newNodeButton = containerButtons:addChild(client.GUI.button(16, 2, 8, 1, 0xFFEFFF, 0x555555, 0x880000, 0xFFFFFF, "New Node"))
	newNodeButton.onTouch = function() insertAliasNode() end
	local newLeafButton = containerButtons:addChild(client.GUI.button(26, 2, 8, 1, 0xFFEFFF, 0x555555, 0x880000, 0xFFFFFF, "New Leaf"))
	newLeafButton.onTouch = function() insertAliasLeaf() end
	
	local upButton = containerButtons:addChild(client.GUI.button(35, 2, 3, 1, 0xFFEFFF, 0x555555, 0x880000, 0xFFFFFF, "U"))
	upButton.onTouch = function() upDownAlias(false) end
	local downButton = containerButtons:addChild(client.GUI.button(39, 2, 3, 1, 0xFFEFFF, 0x555555, 0x880000, 0xFFFFFF, "D"))
	downButton.onTouch = function() upDownAlias(true) end
end

local itemSelected = function(e1, e2, e3, e4, e5, e6, e7, e8, e9)
	cleanUp()
	local alias = tree.getDataNode(tree.dataNode, tree:getSelectedName())
	displayHEAD(alias)
	displayCRUD(alias)
end

local onItemExpanded = function(e1, e2, e3, e4, e5, e6, e7, e8, e9)
end

local refresh = function()
	tree:refresh()
	client.application:draw()
end

AliasesModif.display = function()
	local window = client.application:addChild(client.GUI.titledWindow(50, 22, 74, 21, name, true))
	window.actionButtons.close.onTouch = function() client.closeWindow(name) end

	tree = client.GUI.aliasTree(client.dataAliases, 2, 2, 28, 19, 0x11E1E1, 0x3C3C3C, 0x3C3C3C, 0xA5A5A5, 0x3C3C3C, 0xE1E1E1, 
		0xB4B4B4, 0xA5A5A5, 0xC3C3C3, 0x4B4B4B)
	window:addChild(tree); tree.onItemSelected = itemSelected; tree.onItemExpanded = onItemExpanded

	tree.switch.refresh = refresh
	client.listenToAliasesList(tree, name)

	local panelHEAD = window:addChild(client.GUI.panel(32, 2, 42, 5, 0x880000))
	containerHEAD = window:addChild(client.GUI.container(panelHEAD.x, panelHEAD.y, panelHEAD.width, panelHEAD.height))

	local panelCRUD = window:addChild(client.GUI.panel(32, 8, 42, 9, 0x880000))
	containerCRUD = window:addChild(client.GUI.container(panelCRUD.x, panelCRUD.y, panelCRUD.width, panelCRUD.height))

	local panelBUTTONS = window:addChild(client.GUI.panel(32, 18, 42, 3, 0x880000))
	containerButtons = window:addChild(client.GUI.container(panelBUTTONS.x, panelBUTTONS.y, panelBUTTONS.width, panelBUTTONS.height))

	displayButtons()

	return window
end

return AliasesModif