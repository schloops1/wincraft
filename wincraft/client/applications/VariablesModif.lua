local VariablesModif = {}
--local colors = require "colors"
--local sides = require "sides"
local dmp = require "dump"

local aliasNode = require "AliasNode"

local client
local name

function VariablesModif:set(aname)
	client = self; name = aname
end

local tree
local containerHEAD, containerCRUD, containerButtons
local nameField
local oldName
local typeField, valueField, saveField

local function cleanUp()
	containerHEAD:removeChildren()
	containerCRUD:removeChildren()
	typeField = nil
	valueField = nil
	client.stopListeningToWindowVars(name)
end

local function upDownVar(upDown)
	local selectedName = tree:getSelectedName()
	local selectedVar = tree.getDataNode(tree.dataNode, selectedName)
	local selectedParentVar = tree.getParentDataNode(tree.dataNode, selectedName)
	local i 
	local max
	for k, v in ipairs(selectedParentVar.children) do
		if selectedVar.name == v.name then
			i = k
		end
		max = k
	end
	if upDown then
		if i >= max then return end
	else
		if i <= 1 then return end
	end
	client.upDownVar(selectedParentVar.name, i, upDown)
end

local function setTypeFields(var)
	local selectedType = typeField:getItem(typeField.selectedItem).text
	var["type"] = selectedType
	if selectedType == "Number" then
		var.value = tonumber(valueField.text)
	elseif selectedType == "String" then
		var.value = valueField.text
	elseif selectedType == "Boolean" then
		if valueField.selectedItem == 1 then var.value = false else var.value = true end
	elseif selectedType == "Order" then
		var.value = valueField:getItem(valueField.selectedItem).text
	elseif selectedType == "Alias" then
		var.value = valueField:getItem(valueField.selectedItem).text
	end
end

local function validateFields(isNode)
	nameField.text = string.gsub(nameField.text, '%W','')
	if nameField.text == "" then return end
	if string.len(nameField.text) > 16 then nameField.text = string.sub(nameField.text, 1, 16) end
	if nameField.text ~= oldName and client.dataVarsList[nameField.text] ~= nil then return end
	if typeField ~= nil and not isNode then
		local selectedType = typeField:getItem(typeField.selectedItem).text
		if selectedType == "Number" then
			if tonumber(valueField.text) == nil then return false end
		elseif selectedType == "String" then
		elseif selectedType == "Boolean" then
			--if valueField.text ~= "false" and valueField.text ~= "true" then return false end
		elseif selectedType == "Order" then
		elseif selectedType == "Alias" then
		end
	end
	return true	
end

local function updateVar()
	--if oldName ~= nameField.text and not aliasNode.isNew(tree.dataNode, nameField.text) then return end
	local origVar = tree.getDataNode(tree.dataNode, tree:getSelectedName())
	if not validateFields(origVar.node) then return end
	local var = {}
	var.name = nameField.text
	var.node = origVar.node
	if var.node then
		var.exp = origVar.exp		
		var.children = origVar.children
	else
		setTypeFields(var)
		if saveField:getItem(saveField.selectedItem).text == "Always" then var.saveAlways = true else var.saveAlways = false end
	end
	client.updateVar(oldName, var.name, var)
	cleanUp()
end

local function deleteVar()
	local var = tree.getDataNode(tree.dataNode, tree:getSelectedName())
	if var.node and #var.children > 0 then return end
	client.deleteVar(var.name)
	cleanUp()
end

local function insertVarNode()
	--if oldName == nameField.text or not aliasNode.isNew(tree.dataNode, nameField.text) then return end

	if not validateFields(true) then return end

	local parent
	local selected = tree.getDataNode(tree.dataNode, tree:getSelectedName())
	if selected.node then
		parent = selected
	else
		parent = tree.getParentDataNode(tree.dataNode, tree:getSelectedName())
	end
	local var = {}
	var.name = nameField.text
	var.node = true
	var.exp = true
	var.children = {}
	client.insertVar(parent.name, var.name, var)
	cleanUp()
end

local function insertVarLeaf()
	--if oldName == nameField.text or not aliasNode.isNew(tree.dataNode, nameField.text) then return end

	if not validateFields(false) then return end

	local parent
	local selected = tree.getDataNode(tree.dataNode, tree:getSelectedName())
	if selected.node then
		parent = selected
	else
		parent = tree.getParentDataNode(tree.dataNode, tree:getSelectedName())
	end
	local var = {}
	var.name = nameField.text
	var.node = false
	
	if typeField ~= nil then
		setTypeFields(var)
		if saveField:getItem(saveField.selectedItem).text == "Always" then var.saveAlways = true else var.saveAlways = false end
	else
		var["type"] = "Number"
		var.value = 0
		var.saveAlways = true
	end
	client.insertVar(parent.name, var.name, var)
	cleanUp()
end

local function displayHEAD(var)
	containerHEAD:addChild(client.GUI.text(2, 2, 0xFFFFFF, "Name:"))
	nameField = containerHEAD:addChild(client.GUI.input(8, 2, 19, 1, 0xEEEEEE, 0x555555, 0x999999, 0xFFFFFF, 0x2D2D2D, "", ""))
	oldName = var.name
	nameField.text = var.name
	local isNode; if var.node then isNode = "yes" else isNode = "no" end
	containerHEAD:addChild(client.GUI.text(30, 2, 0xFFFFFF, "Node: "..isNode))
end

local function displayCRUD(var, aType)
	if aType ~= nil then dmp.p("aType "..aType) end

	if var == nil then client.GUI.alert("var est nul") end

	local var2 = client.dataVarsList[var.name] 

	containerCRUD:removeChildren()
	if not var2.node then
		containerCRUD:addChild(client.GUI.text(2, 2, 0xFFFFFF, "Type:"))
		typeField = containerCRUD:addChild(client.GUI.comboBox(8, 2, 10, 1, 0xEEEEEE, 0x2D2D2D, 0xCCCCCC, 0x888888))
		typeField:addItem("Number").onTouch =  function() var2.value = 0; displayCRUD(var2, "Number") end
		typeField:addItem("String").onTouch =  function() var2.value = ""; displayCRUD(var2, "String") end
		typeField:addItem("Boolean").onTouch = function() var2.value = "false"; displayCRUD(var2, "Boolean") end
		typeField:addItem("Order").onTouch =   function() var2.value = nil; displayCRUD(var2, "Order") end
		typeField:addItem("Alias").onTouch =   function() var2.value = nil; displayCRUD(var2, "Alias") end
		local selected = 1
		for k, v in pairs (typeField:getChildren()) do 
			if (aType ~= nil and aType == v.text) or (aType == nil and var2 ~= nil and var2["type"] == v.text) then selected = k end
		end
		typeField.selectedItem = selected
		
		local selectedType = typeField:getItem(typeField.selectedItem).text
		var2["type"] = selectedType
		
		valueField = client.addSynchVarEditable(name, var.name)
		valueField.x = 20; valueField.y = 2; valueField.width = 20; --valueField.height = 1;
		containerCRUD:addChild(valueField)

		containerCRUD:addChild(client.GUI.text(2, 4, 0xFFFFFF, "Save:"))
		saveField = containerCRUD:addChild(client.GUI.comboBox(8, 4, 10, 1, 0xEEEEEE, 0x2D2D2D, 0xCCCCCC, 0x888888))
		saveField:addItem("Always")
		saveField:addItem("OnDemand")
		if var2 ~= nil and var2.saveAlways == false then
			saveField.selectedItem = 2
		else
			saveField.selectedItem = 1
		end
		
		client.dataVarsList[var2.name] = var2
	end	
end

local function displayButtons()
	local updateButton = containerButtons:addChild(client.GUI.button(2, 2, 5, 1, 0xFFEFFF, 0x555555, 0x880000, 0xFFFFFF, "Upd"))
	updateButton.onTouch = function() updateVar() end
	local deleteButton = containerButtons:addChild(client.GUI.button(9, 2, 5, 1, 0xFFEFFF, 0x555555, 0x880000, 0xFFFFFF, "Del"))
	deleteButton.onTouch = function() deleteVar() end
	local newNodeButton = containerButtons:addChild(client.GUI.button(16, 2, 8, 1, 0xFFEFFF, 0x555555, 0x880000, 0xFFFFFF, "New Node"))
	newNodeButton.onTouch = function() insertVarNode() end
	local newLeafButton = containerButtons:addChild(client.GUI.button(26, 2, 8, 1, 0xFFEFFF, 0x555555, 0x880000, 0xFFFFFF, "New Leaf"))
	newLeafButton.onTouch = function() insertVarLeaf() end
	
	local upButton = containerButtons:addChild(client.GUI.button(35, 2, 3, 1, 0xFFEFFF, 0x555555, 0x880000, 0xFFFFFF, "U"))
	upButton.onTouch = function() upDownVar(false) end
	local downButton = containerButtons:addChild(client.GUI.button(39, 2, 3, 1, 0xFFEFFF, 0x555555, 0x880000, 0xFFFFFF, "D"))
	downButton.onTouch = function() upDownVar(true) end
end

local itemSelected = function(e1, e2, e3, e4, e5, e6, e7, e8, e9)
	cleanUp()
	local var = tree.getDataNode(tree.dataNode, tree:getSelectedName())
	
	displayHEAD(var)
	displayCRUD(var)
end

local onItemExpanded = function(e1, e2, e3, e4, e5, e6, e7, e8, e9)
end

local refresh = function()
	dmp.p("refresh_")
	tree:refresh()
	itemSelected()--
	client.application:draw()
end

VariablesModif.display = function()
	local window = client.application:addChild(client.GUI.titledWindow(50, 22, 74, 21, name, true))--, 0x0000FF))
	window.actionButtons.close.onTouch = function() client.closeWindow(name) end

	tree = client.GUI.aliasTree(client.dataVars, 2, 2, 28, 19, 0xFFA500, 0x3C3C3C, 0x3C3C3C, 0xA5A5A5, 0x3C3C3C, 0xE1E1E1, 
		0xB4B4B4, 0xA5A5A5, 0xC3C3C3, 0x4B4B4B)
	window:addChild(tree); tree.onItemSelected = itemSelected; tree.onItemExpanded = onItemExpanded

	tree.switch.refresh = refresh
	client.listenToVarsList(tree, name)

	--for value changes
	--tree.switch.setState = refresh

	local panelHEAD = window:addChild(client.GUI.panel(32, 2, 42, 5, 0x880000))
	containerHEAD = window:addChild(client.GUI.container(panelHEAD.x, panelHEAD.y, panelHEAD.width, panelHEAD.height))

	local panelCRUD = window:addChild(client.GUI.panel(32, 8, 42, 9, 0x880000))
	containerCRUD = window:addChild(client.GUI.container(panelCRUD.x, panelCRUD.y, panelCRUD.width, panelCRUD.height))

	local panelBUTTONS = window:addChild(client.GUI.panel(32, 18, 42, 3, 0x880000))
	containerButtons = window:addChild(client.GUI.container(panelBUTTONS.x, panelBUTTONS.y, panelBUTTONS.width, panelBUTTONS.height))

	displayButtons()

	return window
end

return VariablesModif