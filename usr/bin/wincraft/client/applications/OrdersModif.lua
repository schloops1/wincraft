local OrdersModif = {}
local colors = require "colors"
local sides = require "sides"
local dmp = require "dump"

local client
local name

function OrdersModif:set(aname)
	client = self; name = aname
end

local orderName
local oldOrderName
local orderRepeat
local ordersList
local orderItemList

local containerDescription
local containerButtons
local containerFields
local typeField
local idField
local blockField
local sideField
local colorField
local forceField
local timeField
local aliasField
local orderNameField

local varValueField
local varModField
local varNameField
local varTrueFalseField
      
local orderNameToBeSelected = nil

cleanFields = function()
	containerFields:removeChildren()
	client.application:draw()
end

getNextOrderId = function()
	local maxId = 0
	for k, v in pairs (client.dataOrders) do
		if v.id > maxId then maxId = v.id end
	end
	return maxId + 1
end

clearOrderHeader = function()
	oldOrderName.text = ""
	orderName.text = ""
	orderRepeat.text = "0"
end

insertOrder = function()
	if client.dataOrders[orderName.text] ~= nil or orderName.text:gsub("%s+", "") == "" then return end
	if tonumber(orderRepeat.text) == nil then return end
	orderName.text = string.gsub(orderName.text, '%W','')
	if string.len(orderName.text) > 16 then orderName.text = string.sub(orderName.text, 1, 16) end
	newOrder = {}
	newOrder.id = getNextOrderId()
	newOrder["repeat"] = orderRepeat.text
	newOrder["offOn"] = false
	newOrder.orders = {}
	client.dataOrders[orderName.text] = newOrder
	orderNameToBeSelected = orderName.text
	client.insertOrder(orderName.text, newOrder)
	clearOrderHeader()
	containerFields:removeChildren()
	orderItemList:removeChildren()
end

deleteOrder = function()
	if ordersList:count() == 0 then return end
	if client.dataOrders[oldOrderName.text].offOn == true then return end
	orderNameToBeSelected = nil
	client.deleteOrder(oldOrderName.text)
	client.dataOrders[oldOrderName.text] = nil
	orderName.text = ""
	orderRepeat.text = "0"
	
	clearOrderHeader()--2 down
  ordersList.selectedItem = 0
	containerFields:removeChildren()
	orderItemList:removeChildren()
	client.application:draw()
end

updateOrder = function()
	if ordersList:count() == 0 or oldOrderName.text == "" then return end
	if client.dataOrders[oldOrderName.text].offOn == true then return end
	if tonumber(orderRepeat.text) == nil then return end
	orderName.text = string.gsub(orderName.text, '%W','')
	if string.len(orderName.text) > 16 then orderName.text = string.sub(orderName.text, 1, 16) end
	local order = client.dataOrders[oldOrderName.text]
	local orderValue = {}
	orderValue.id = order.id
	orderValue["repeat"] = orderRepeat.text
	orderValue.offOn = order.offOn
	orderValue.orders = order.orders
	client.dataOrders[oldOrderName.text] = nil
	client.dataOrders[orderName.text] = orderValue
	orderNameToBeSelected = orderName.text
	client.updateOrder(oldOrderName.text, orderName.text, orderValue)
	containerFields:removeChildren()
end

insertOrderItem = function()
	if ordersList:count() == 0 then return end
	if client.dataOrders[oldOrderName.text].offOn == true then return end
	local id = 0
	if orderItemList:count() ~= 0 then id = orderItemList.selectedItem end
	local orderItem = {}
	orderItem["id"] = id
	orderItem["type"] = typeField:getItem(typeField.selectedItem).text
	if orderItem["type"] == "output" or orderItem["type"] == "input" or orderItem["type"] == "cleanOut" then
		if tonumber(forceField.text) == nil then return end
		if tonumber(forceField.text) > 255 then forceField.text = "255" end
		orderItem["block"] = blockField:getItem(blockField.selectedItem).text
		orderItem["side"] = sideField.selectedItem - 1
		orderItem["color"] = colorField.selectedItem - 1
		orderItem["force"] = forceField.text
	elseif orderItem["type"] == "outAlias" or orderItem["type"] == "cleanOAl" then	
		if tonumber(forceField.text) == nil then return end
		if tonumber(forceField.text) > 255 then forceField.text = "255" end
		orderItem["alias"] = aliasField:getItem(aliasField.selectedItem).text
		orderItem["force"] = forceField.text
	elseif orderItem["type"] == "wait" or orderItem["type"] == "cleanW" then
		if tonumber(timeField.text) == nil then return end
		orderItem["time"] = timeField.text
	elseif orderItem["type"] == "execOrder" or orderItem["type"] == "killOrder" then
		orderItem["name"] = orderNameField:getItem(orderNameField.selectedItem).text
  elseif orderItem["type"] == "varSet" then
    --orderItem["typeVar"] = varTypeField:getItem(varTypeField.selectedItem).text
    orderItem["name"] = varNameField:getItem(varNameField.selectedItem).text
    local typeVar = client.dataVarsList[orderItem["name"]]["type"]
    if typeVar == "String" then
      orderItem["value"] = varValueField.text
    elseif typeVar == "Number" then
      orderItem["mod"] = varModField:getItem(varModField.selectedItem).text
      orderItem["value"] = tonumber(varValueField.text)
    elseif typeVar == "Boolean" then 
      if varValueField.selectedItem == 1 then orderItem["value"] = false else orderItem["value"] = true end
    elseif typeVar == "Alias" then
      orderItem["value"] = varValueField:getItem(varValueField.selectedItem).text
    elseif typeVar == "Order" then
      orderItem["value"] = varValueField:getItem(varValueField.selectedItem).text
    end
  elseif orderItem["type"] == "execVAl" then
    if tonumber(forceField.text) == nil then return end
    orderItem["name"] = varNameField:getItem(varNameField.selectedItem).text
    orderItem["force"] = tonumber(forceField.text)
  elseif orderItem["type"] == "execVOr" then
    orderItem["name"] = varNameField:getItem(varNameField.selectedItem).text
  elseif orderItem["type"] == "trigVar" then
    orderItem["name"] = varNameField:getItem(varNameField.selectedItem).text
  elseif orderItem["type"] == "inpVar" then
    orderItem["name"] = varNameField:getItem(varNameField.selectedItem).text
  elseif orderItem["type"] == "ifV_A" then
    orderItem["name"] = varNameField:getItem(varNameField.selectedItem).text
    if varTrueFalseField.selectedItem == 1 then orderItem["is"] = false else orderItem["is"] = true end
    orderItem["alias"] = aliasField:getItem(aliasField.selectedItem).text
    orderItem["force"] = tonumber(forceField.text)
  elseif orderItem["type"] == "ifV_O" then
    orderItem["name"] = varNameField:getItem(varNameField.selectedItem).text
    if varTrueFalseField.selectedItem == 1 then orderItem["is"] = false else orderItem["is"] = true end
    orderItem["order"] = orderNameField:getItem(orderNameField.selectedItem).text  
	end
	local orders = client.dataOrders[oldOrderName.text].orders
	for k, v in ipairs(orders) do
		if v.id >= id then v.id = v.id + 1 end
	end
	table.insert(orders, id + 1, orderItem)
	client.updateOrder("", orderName.text, client.dataOrders[orderName.text])
	orderItemList.selectedItem = id + 1
end

updateOrderItem = function()
	if orderItemList:count() == 0 then return end
	if client.dataOrders[oldOrderName.text].offOn == true then return end--might change?
	local id = orderItemList.selectedItem
	local orderItem = client.dataOrders[oldOrderName.text].orders[id]
	
	--orderItem = {}
	--client.dataOrders[oldOrderName.text].orders[id] = orderItem 
	--orderItem.id = id
		
	orderItem["type"] = typeField:getItem(typeField.selectedItem).text
	if orderItem["type"] == "output" or orderItem["type"] == "input" or orderItem["type"] == "cleanOut" then
		if tonumber(forceField.text) == nil then return end
		if tonumber(forceField.text) > 255 then forceField.text = "255" end
		orderItem["block"] = blockField:getItem(blockField.selectedItem).text
		orderItem["side"] = sideField.selectedItem - 1
		orderItem["color"] = colorField.selectedItem - 1
		orderItem["force"] = forceField.text
	elseif orderItem["type"] == "outAlias" or orderItem["type"] == "cleanOAl" then	
		if tonumber(forceField.text) == nil then return end
		if tonumber(forceField.text) > 255 then forceField.text = "255" end
		orderItem["alias"] = aliasField:getItem(aliasField.selectedItem).text
		orderItem["force"] = forceField.text
	elseif orderItem["type"] == "wait" or orderItem["type"] == "cleanW" then
		if tonumber(timeField.text) == nil then return end
		orderItem["time"] = timeField.text
	elseif orderItem["type"] == "execOrder" or orderItem["type"] == "killOrder" then
		orderItem["name"] = orderNameField:getItem(orderNameField.selectedItem).text
	elseif orderItem["type"] == "varSet" then
		--orderItem["typeVar"] = varTypeField:getItem(varTypeField.selectedItem).text
		orderItem["name"] = varNameField:getItem(varNameField.selectedItem).text
		local typeVar = client.dataVarsList[orderItem["name"]]["type"]
		if typeVar == "String" then
			orderItem["value"] = varValueField.text
		elseif typeVar == "Number" then
			orderItem["mod"] = varModField:getItem(varModField.selectedItem).text
			orderItem["value"] = tonumber(varValueField.text)
		elseif typeVar == "Boolean" then 
			if varValueField.selectedItem == 1 then orderItem["value"] = false else orderItem["value"] = true end
		elseif typeVar == "Alias" then
			orderItem["value"] = varValueField:getItem(varValueField.selectedItem).text
		elseif typeVar == "Order" then
			orderItem["value"] = varValueField:getItem(varValueField.selectedItem).text
		end
  elseif orderItem["type"] == "execVAl" then
    if tonumber(forceField.text) == nil then return end
		orderItem["name"] = varNameField:getItem(varNameField.selectedItem).text
		orderItem["force"] = tonumber(forceField.text)
  elseif orderItem["type"] == "execVOr" then
    orderItem["name"] = varNameField:getItem(varNameField.selectedItem).text
  elseif orderItem["type"] == "trigVar" then
    orderItem["name"] = varNameField:getItem(varNameField.selectedItem).text
  elseif orderItem["type"] == "inpVar" then
    orderItem["name"] = varNameField:getItem(varNameField.selectedItem).text
  elseif orderItem["type"] == "ifV_A" then
    orderItem["name"] = varNameField:getItem(varNameField.selectedItem).text
		if varTrueFalseField.selectedItem == 1 then orderItem["is"] = false else orderItem["is"] = true end
    orderItem["alias"] = aliasField:getItem(aliasField.selectedItem).text
		orderItem["force"] = tonumber(forceField.text)
  elseif orderItem["type"] == "ifV_O" then
    orderItem["name"] = varNameField:getItem(varNameField.selectedItem).text
		if varTrueFalseField.selectedItem == 1 then orderItem["is"] = false else orderItem["is"] = true end
    orderItem["order"] = orderNameField:getItem(orderNameField.selectedItem).text
	end
	client.updateOrder("", orderName.text, client.dataOrders[orderName.text])
end

deleteOrderItem = function()
	if orderItemList:count() == 0 then return end
	if client.dataOrders[oldOrderName.text].offOn == true then return end
	cleanFields()
	local id = orderItemList.selectedItem
	local orders = client.dataOrders[oldOrderName.text].orders
	table.remove(orders, id)
	for k, v in ipairs(orders) do
		if v.id >= id then v.id = v.id - 1 end
	end
	client.updateOrder("", orderName.text, client.dataOrders[orderName.text])
	if orderItemList:count() > 0 then orderItemList.selectedItem = 1 end
end

displayOrderHudAndItems = function(name)
	orderName.text = name
	oldOrderName.text = name
	orderRepeat.text = dmp.okv(client.dataOrders[name]["repeat"])
	containerFields:removeChildren()
	orderItemList:removeChildren()
	local orders = client.dataOrders[name]["orders"]
	table.sort(orders, function(a,b) return a.id < b.id end)
	for k, v in ipairs(orders) do
		local astring = dmp.okv(v.id)
		if v["type"] == "output" then
			astring = astring.." O block:"..string.sub(v.block, 1, 8).." side:"..sides[v.side].." color:"..colors[v.color].." "..v["force"]
		elseif v["type"] == "input" then
			astring = astring.." I block:"..string.sub(v.block, 1, 8).." side:"..sides[v.side].." color:"..colors[v.color].." "..v["force"]
		elseif v["type"] == "cleanOut" then
			astring = astring.." CO block:"..string.sub(v.block, 1, 8).." side:"..sides[v.side].." color:"..colors[v.color].." "..v["force"]
		elseif v["type"] == "outAlias" then
			astring = astring.." OA alias:"..v.alias.." "..v["force"]
		elseif v["type"] == "cleanOAl" then
			astring = astring.." COA alias:"..v.alias.." "..v["force"]	
		elseif v["type"] == "wait" then
			astring = astring.." W wait "..dmp.okv(v.time).."s"
		elseif v["type"] == "execOrder" then
			astring = astring.." EO name "..v.name
		elseif v["type"] == "killOrder" then
			astring = astring.." KO name "..v.name
		elseif v["type"] == "cleanW" then
			astring = astring.." CW wait "..dmp.okv(v.time).."s"
		elseif v["type"] == "varSet" then
		  if client.dataVarsList[v.name] ~= nil then
  			local typeVar = client.dataVarsList[v.name]["type"]
  			if typeVar == "Number" then
  				astring = astring.." VS "..dmp.okv(v.name).." "..dmp.okv(v.mod).." "..tostring(v.value)				
  			else
  				astring = astring.." VS "..dmp.okv(v.name).." "..tostring(v.value)
  			end
  		else	
  		  astring = astring.." VS "..dmp.okv(v.name).." unrecognized"
  		end
		elseif v["type"] == "execVAl" then	
			astring = astring.." EVA "..dmp.okv(v.name).." "..dmp.okv(v.force)
		elseif v["type"] == "execVOr" then  
      astring = astring.." EVO "..dmp.okv(v.name)	
    elseif v["type"] == "trigVar" then  
      astring = astring.." TV "..dmp.okv(v.name) 
    elseif v["type"] == "inpVar" then  
      astring = astring.." IV "..dmp.okv(v.name) 
    elseif v["type"] == "ifV_A" then  
      astring = astring.." ifVA "..dmp.okv(v.name).." "..tostring(v.is).." "..v.alias.." "..tostring(v.force)
    elseif v["type"] == "ifV_O" then  
      astring = astring.." ifVO "..dmp.okv(v.name).." "..tostring(v.is).." "..v.order
		end
		orderItemList:addItem(astring).onTouch = cleanFields
	end
	
	client.application:draw()
end

getOrder = function(id)
	for _, order in ipairs(client.dataOrders[orderName.text]["orders"]) do
	    if order.id == id then return order end
	end
end

--fill CRUD fields
displayOrderItemCRUD = function(id, action, typeValue, varName)
	local order = nil
	if id ~= nil and typeValue == nil and action ~= "ins" then order = getOrder(id) end
	
	containerFields:removeChildren()
	idField = containerFields:addChild(client.GUI.text(2, 2, 0xFFFFFF, "Id:"..dmp.okv(id)))
	typeField = containerFields:addChild(client.GUI.comboBox(9, 2, 10, 1, 0xEEEEEE, 0x2D2D2D, 0xCCCCCC, 0x888888))
	typeField:addItem("output").onTouch = function() displayOrderItemCRUD(id, action, "output") end
	typeField:addItem("outAlias").onTouch = function() displayOrderItemCRUD(id, action, "outAlias") end
	typeField:addItem("wait").onTouch = function() displayOrderItemCRUD(id, action, "wait") end
	typeField:addItem("input").onTouch = function() displayOrderItemCRUD(id, action, "input") end
	typeField:addItem("execOrder").onTouch = function() displayOrderItemCRUD(id, action, "execOrder") end
	typeField:addItem("killOrder").onTouch = function() displayOrderItemCRUD(id, action, "killOrder") end
	typeField:addItem("cleanOut").onTouch = function() displayOrderItemCRUD(id, action, "cleanOut") end
	typeField:addItem("cleanOAl").onTouch = function() displayOrderItemCRUD(id, action, "cleanOAl") end
	typeField:addItem("cleanW").onTouch = function() displayOrderItemCRUD(id, action, "cleanW") end
	typeField:addItem("varSet").onTouch = function() displayOrderItemCRUD(id, action, "varSet") end
	typeField:addItem("execVAl").onTouch = function() displayOrderItemCRUD(id, action, "execVAl") end
	typeField:addItem("execVOr").onTouch = function() displayOrderItemCRUD(id, action, "execVOr") end
	typeField:addItem("trigVar").onTouch = function() displayOrderItemCRUD(id, action, "trigVar") end
	typeField:addItem("inpVar").onTouch = function() displayOrderItemCRUD(id, action, "inpVar") end
  
  typeField:addItem("ifV_A").onTouch = function() displayOrderItemCRUD(id, action, "ifV_A") end
  typeField:addItem("ifV_O").onTouch = function() displayOrderItemCRUD(id, action, "ifV_O") end

	if (order ~= nil and order["type"] == "output") or (action ~= nil and action == "ins" and typeValue == nil) or (typeValue ~= nil and typeValue == "output") then 
		typeField.selectedItem = 1
	elseif (order ~= nil and order["type"] == "outAlias") or (typeValue ~= nil and typeValue == "outAlias") then 
		typeField.selectedItem = 2
	elseif (order ~= nil and order["type"] == "wait") or (typeValue ~= nil and typeValue == "wait") then 
		typeField.selectedItem = 3
	elseif (order ~= nil and order["type"] == "input") or (typeValue ~= nil and typeValue == "input") then 
		typeField.selectedItem = 4
	elseif (order ~= nil and order["type"] == "execOrder") or (typeValue ~= nil and typeValue == "execOrder") then 
		typeField.selectedItem = 5
	elseif (order ~= nil and order["type"] == "killOrder") or (typeValue ~= nil and typeValue == "killOrder") then 
		typeField.selectedItem = 6
	elseif (order ~= nil and order["type"] == "cleanOut") or (typeValue ~= nil and typeValue == "cleanOut") then 
		typeField.selectedItem = 7
	elseif (order ~= nil and order["type"] == "cleanOAl") or (typeValue ~= nil and typeValue == "cleanOAl") then 
		typeField.selectedItem = 8
	elseif (order ~= nil and order["type"] == "cleanW") or (typeValue ~= nil and typeValue == "cleanW") then 
		typeField.selectedItem = 9
	elseif (order ~= nil and order["type"] == "varSet") or (typeValue ~= nil and typeValue == "varSet") then 
		typeField.selectedItem = 10
  elseif (order ~= nil and order["type"] == "execVAl") or (typeValue ~= nil and typeValue == "execVAl") then 
    typeField.selectedItem = 11
  elseif (order ~= nil and order["type"] == "execVOr") or (typeValue ~= nil and typeValue == "execVOr") then 
    typeField.selectedItem = 12
  elseif (order ~= nil and order["type"] == "trigVar") or (typeValue ~= nil and typeValue == "trigVar") then 
    typeField.selectedItem = 13
  elseif (order ~= nil and order["type"] == "inpVar") or (typeValue ~= nil and typeValue == "inpVar") then 
    typeField.selectedItem = 14
  elseif (order ~= nil and order["type"] == "ifV_A") or (typeValue ~= nil and typeValue == "ifV_A") then 
    typeField.selectedItem = 15
  elseif (order ~= nil and order["type"] == "ifV_O") or (typeValue ~= nil and typeValue == "ifV_O") then 
    typeField.selectedItem = 16
	end
	
	if typeField.selectedItem == 1 or typeField.selectedItem == 4 or typeField.selectedItem == 7 then --output, input, cleanOut
		blockField = containerFields:addChild(client.GUI.comboBox(20, 2, 12, 1, 0xEEEEEE, 0x2D2D2D, 0xCCCCCC, 0x888888))
		local ii = 1
		local iiSelected
		for k, v in pairs (client.data) do
			blockField:addItem(k)
			if order ~= nil and k == order.block then iiSelected = ii end
			ii = ii + 1
		end
		if iiSelected == nil then iiSelected = 1 end
		blockField.selectedItem = iiSelected

		sideField = containerFields:addChild(client.GUI.comboBox(33, 2, 10, 1, 0xEEEEEE, 0x2D2D2D, 0xCCCCCC, 0x888888))
		for i = 0, 5 do
			sideField:addItem(sides[i])
		end
		if order ~= nil then sideField.selectedItem = order.side + 1 end

		colorField = containerFields:addChild(client.GUI.comboBox(44, 2, 10, 1, 0xEEEEEE, 0x2D2D2D, 0xCCCCCC, 0x888888))
		for i = 0, 15 do
			colorField:addItem(colors[i])
		end
		if order ~= nil then colorField.selectedItem = order.color + 1 end

		forceField = containerFields:addChild(client.GUI.input(55, 2, 6, 1, 0xEEEEEE, 0x555555, 0x999999, 0xFFFFFF, 0x2D2D2D, "", ""))
		if order ~= nil then forceField.text = order.force end
	elseif typeField.selectedItem == 2 or typeField.selectedItem == 8 then --outAlias, cleanOAl
		local listAliases = {}
		local aliasNode = require "AliasNode"		
		aliasNode.getAllAliases(client.dataAliases, listAliases)
		aliasField = containerFields:addChild(client.GUI.comboBox(20, 2, 16, 1, 0xEEEEEE, 0x2D2D2D, 0xCCCCCC, 0x888888))
		local iiSelected = 1
		for k, v in ipairs(listAliases) do
			aliasField:addItem(v)
			if order ~= nil and v == order.alias then iiSelected = k end
		end
		aliasField.selectedItem = iiSelected

		forceField = containerFields:addChild(client.GUI.input(37, 2, 6, 1, 0xEEEEEE, 0x555555, 0x999999, 0xFFFFFF, 0x2D2D2D, "", ""))
		if order ~= nil then forceField.text = order.force end

	elseif typeField.selectedItem == 3 or typeField.selectedItem == 9 then --wait, cleanW
		timeField = containerFields:addChild(client.GUI.input(20, 2, 12, 1, 0xEEEEEE, 0x555555, 0x999999, 0xFFFFFF, 0x2D2D2D, "", ""))
		if order ~= nil then timeField.text = order.time end
		
	elseif typeField.selectedItem == 5 or typeField.selectedItem == 6 then --execOrder, killOrder
		orderNameField = containerFields:addChild(client.GUI.comboBox(20, 2, 20, 1, 0xEEEEEE, 0x2D2D2D, 0xCCCCCC, 0x888888))
		local tkeys = {}; for k in pairs(client.dataOrders) do table.insert(tkeys, k) end; table.sort(tkeys)
 		local i = 1; local iSelected = 0
 		for _, k in ipairs (tkeys) do
			orderNameField:addItem(k)
			if order ~= nil and k == order.name then iSelected = i end
			i = i + 1
		end
		if iSelected ~= 0 then orderNameField.selectedItem = iSelected else orderNameField.selectedItem = 1 end
	
	elseif typeField.selectedItem == 10 then
		varNameField = containerFields:addChild(client.GUI.comboBox(20, 2, 16, 1, 0xEEEEEE, 0x2D2D2D, 0xCCCCCC, 0x888888))
		local i = 0; iSelected = 1
		for k, v in pairs (client.dataVarsList) do
			if client.dataVarsList[k].node == false then
  			i = i + 1
  			varNameField:addItem(k).onTouch = function() displayOrderItemCRUD(id, action, "varSet", k) end
  			if (order ~= nil and order.name == k) or (varName ~= nil and varName == k) then iSelected = i	end
  		end
		end
    if i == 0 then return end
    varNameField.selectedItem = iSelected

    local typeVariable = client.dataVarsList[varNameField:getItem(varNameField.selectedItem).text].type 

		if typeVariable == "String" then
			varValueField = containerFields:addChild(client.GUI.input(38, 2, 16, 1, 0xEEEEEE, 0x555555, 0x999999, 0xFFFFFF, 0x2D2D2D, "", ""))
			if order ~= nil and order.value ~= nil then varValueField.text = order.value end
		elseif typeVariable == "Number" then
			varModField = containerFields:addChild(client.GUI.comboBox(38, 2, 11, 1, 0xEEEEEE, 0x2D2D2D, 0xCCCCCC, 0x888888))
			varModField:addItem("equal")
			varModField:addItem("increment")
			varModField:addItem("decrement")
			if order ~= nil then 
				if order.mod == "equal" then 
					varModField.selectedItem = 1 
				elseif order.mod == "increment" then 
					varModField.selectedItem = 2 
				elseif order.mod == "decrement" then 
					varModField.selectedItem = 3 
				end 
			end

			varValueField = containerFields:addChild(client.GUI.input(51, 2, 12, 1, 0xEEEEEE, 0x555555, 0x999999, 0xFFFFFF, 0x2D2D2D, "", ""))
			if order ~= nil and order.value ~= nil then varValueField.text = order.value end
			
		elseif typeVariable == "Boolean" then
			varValueField = containerFields:addChild(client.GUI.comboBox(37, 2, 10, 1, 0xEEEEEE, 0x2D2D2D, 0xCCCCCC, 0x888888))
			varValueField:addItem("false")
			varValueField:addItem("true")
			if order ~= nil then 
				if order.value == false then varValueField.selectedItem = 1 else varValueField.selectedItem = 2 end 
			end 
		elseif typeVariable == "Alias" then
			local listAliases = {}
			local aliasNode = require "AliasNode"
			aliasNode.getAllAliases(client.dataAliases, listAliases)

			varValueField = containerFields:addChild(client.GUI.comboBox(38, 2, 16, 1, 0xEEEEEE, 0x2D2D2D, 0xCCCCCC, 0x888888))
			local iiSelected = 1
			for k, v in ipairs(listAliases) do
				varValueField:addItem(v)
				if order ~= nil and v == order.value then iiSelected = k end
			end
			varValueField.selectedItem = iiSelected
		elseif typeVariable == "Order" then
			varValueField = containerFields:addChild(client.GUI.comboBox(38, 2, 20, 1, 0xEEEEEE, 0x2D2D2D, 0xCCCCCC, 0x888888))
			local tkeys = {}; for k in pairs(client.dataOrders) do table.insert(tkeys, k) end; table.sort(tkeys)
			local i = 1; local iSelected = 0
			for _, k in ipairs (tkeys) do
				varValueField:addItem(k)
				if order ~= nil and k == order.value then iSelected = i end
				i = i + 1
			end
			if iSelected ~= 0 then varValueField.selectedItem = iSelected else varValueField.selectedItem = 1 end
		end
	
	elseif typeField.selectedItem == 11 then --execVAl
    varNameField = containerFields:addChild(client.GUI.comboBox(20, 2, 16, 1, 0xEEEEEE, 0x2D2D2D, 0xCCCCCC, 0x888888))
    local i = 0; iSelected = 1
    for k, v in pairs (client.dataVarsList) do
      if client.dataVarsList[k].node == false and client.dataVarsList[k]["type"] == "Alias" then
        i = i + 1
        varNameField:addItem(k)--.onTouch = function() displayOrderItemCRUD(id, action, "execVAl", k) end
        if (order ~= nil and order.name == k) or (varName ~= nil and varName == k) then iSelected = i end
      end
    end
    if i == 0 then return end
    varNameField.selectedItem = iSelected

    forceField = containerFields:addChild(client.GUI.input(38, 2, 6, 1, 0xEEEEEE, 0x555555, 0x999999, 0xFFFFFF, 0x2D2D2D, "", ""))
    if order ~= nil and order.force ~= nil then forceField.text = order.force else forceField.text = 0 end

  elseif typeField.selectedItem == 12 then --execVOr
    varNameField = containerFields:addChild(client.GUI.comboBox(20, 2, 16, 1, 0xEEEEEE, 0x2D2D2D, 0xCCCCCC, 0x888888))
    local i = 0; iSelected = 1
    for k, v in pairs (client.dataVarsList) do
      if client.dataVarsList[k].node == false and client.dataVarsList[k]["type"] == "Order" then
        i = i + 1
        varNameField:addItem(k)--.onTouch = function() displayOrderItemCRUD(id, action, "execVOr", k) end
        if (order ~= nil and order.name == k) or (varName ~= nil and varName == k) then iSelected = i end
      end
    end
    if i == 0 then return end
    varNameField.selectedItem = iSelected  
		
  elseif typeField.selectedItem == 13 then --trigVar	
    varNameField = containerFields:addChild(client.GUI.comboBox(20, 2, 16, 1, 0xEEEEEE, 0x2D2D2D, 0xCCCCCC, 0x888888))
    local i = 0; iSelected = 1
    for k, v in pairs (client.dataVarsList) do
      if client.dataVarsList[k].node == false then
        i = i + 1
        varNameField:addItem(k)--.onTouch = function() displayOrderItemCRUD(id, action, "trigVar", k) end
        if (order ~= nil and order.name == k) or (varName ~= nil and varName == k) then iSelected = i end
      end
    end
    if i == 0 then return end
    varNameField.selectedItem = iSelected  

  elseif typeField.selectedItem == 14 then --inpVar
    varNameField = containerFields:addChild(client.GUI.comboBox(20, 2, 16, 1, 0xEEEEEE, 0x2D2D2D, 0xCCCCCC, 0x888888))
    local i = 0; iSelected = 1
    for k, v in pairs (client.dataVarsList) do
      if client.dataVarsList[k].node == false then
        i = i + 1
        varNameField:addItem(k)--.onTouch = function() displayOrderItemCRUD(id, action, "trigVar", k) end
        if (order ~= nil and order.name == k) or (varName ~= nil and varName == k) then iSelected = i end
      end
    end
    if i == 0 then return end
    varNameField.selectedItem = iSelected  

  elseif typeField.selectedItem == 15 then --ifV_A
    varNameField = containerFields:addChild(client.GUI.comboBox(20, 2, 16, 1, 0xEEEEEE, 0x2D2D2D, 0xCCCCCC, 0x888888))
    local i = 0; iSelected = 1
    for k, v in pairs (client.dataVarsList) do
      if not client.dataVarsList[k].node and client.dataVarsList[k]["type"] == "Boolean" then
        i = i + 1
        varNameField:addItem(k)--.onTouch = function() displayOrderItemCRUD(id, action, "trigVar", k) end
        if (order ~= nil and order.name == k) or (varName ~= nil and varName == k) then iSelected = i end
      end
    end
    if i == 0 then return end
    varNameField.selectedItem = iSelected  
    
    varTrueFalseField = containerFields:addChild(client.GUI.comboBox(37, 2, 8, 1, 0xEEEEEE, 0x2D2D2D, 0xCCCCCC, 0x888888))
    varTrueFalseField:addItem("false")
    varTrueFalseField:addItem("true")
    if (order ~= nil and order.is == true) then varTrueFalseField.selectedItem = 2 else varTrueFalseField.selectedItem = 1 end

    local listAliases = {}
    local aliasNode = require "AliasNode"   
    aliasNode.getAllAliases(client.dataAliases, listAliases)
    aliasField = containerFields:addChild(client.GUI.comboBox(46, 2, 16, 1, 0xEEEEEE, 0x2D2D2D, 0xCCCCCC, 0x888888))
    local iiSelected = 1
    for k, v in ipairs(listAliases) do
      aliasField:addItem(v)
      if order ~= nil and v == order.alias then iiSelected = k end
    end
    aliasField.selectedItem = iiSelected

    forceField = containerFields:addChild(client.GUI.input(48, 3, 6, 1, 0xEEEEEE, 0x555555, 0x999999, 0xFFFFFF, 0x2D2D2D, "", ""))
    if order ~= nil then forceField.text = order.force end
    
  elseif typeField.selectedItem == 16 then --ifV_O
    varNameField = containerFields:addChild(client.GUI.comboBox(20, 2, 16, 1, 0xEEEEEE, 0x2D2D2D, 0xCCCCCC, 0x888888))
    local i = 0; iSelected = 1
    for k, v in pairs (client.dataVarsList) do
      if not client.dataVarsList[k].node and client.dataVarsList[k]["type"] == "Boolean" then
        i = i + 1
        varNameField:addItem(k)--.onTouch = function() displayOrderItemCRUD(id, action, "trigVar", k) end
        if (order ~= nil and order.name == k) or (varName ~= nil and varName == k) then iSelected = i end
      end
    end
    if i == 0 then return end
    varNameField.selectedItem = iSelected  
    
    varTrueFalseField = containerFields:addChild(client.GUI.comboBox(37, 2, 8, 1, 0xEEEEEE, 0x2D2D2D, 0xCCCCCC, 0x888888))
    varTrueFalseField:addItem("false")
    varTrueFalseField:addItem("true")
    if (order ~= nil and order.is == true) then varTrueFalseField.selectedItem = 2 else varTrueFalseField.selectedItem = 1 end
    
    orderNameField = containerFields:addChild(client.GUI.comboBox(46, 2, 16, 1, 0xEEEEEE, 0x2D2D2D, 0xCCCCCC, 0x888888))
    local tkeys = {}; for k in pairs(client.dataOrders) do table.insert(tkeys, k) end; table.sort(tkeys)
    local i = 1; local iSelected = 0
    for _, k in ipairs (tkeys) do
      orderNameField:addItem(k)
      if order ~= nil and k == order.order then iSelected = i end
      i = i + 1
    end
    if iSelected ~= 0 then orderNameField.selectedItem = iSelected else orderNameField.selectedItem = 1 end
	end
	
	displayOrderCRUDCommands(action)
	
	client.application:draw()
end

displayOrderCRUDCommands = function(action)
	if action == "upd" then
		local updateButton = containerFields:addChild(client.GUI.button(64, 2, 6, 1, 0xFFEFFF, 0x555555, 0x880000, 0xFFFFFF, "Upd"))
		updateButton.onTouch = function() updateOrderItem() end
	else
		local insertButton = containerFields:addChild(client.GUI.button(64, 2, 6, 1, 0xFFEFFF, 0x555555, 0x880000, 0xFFFFFF, "New"))
		insertButton.onTouch = function() insertOrderItem() end
	end
	local cancelButton = containerFields:addChild(client.GUI.button(71, 2, 6, 1, 0xFFEFFF, 0x555555, 0x880000, 0xFFFFFF, "Cancel"))
	cancelButton.onTouch = function() cleanFields() end
end

displayOrderCommands = function()
	local updateButton = containerDescription:addChild(client.GUI.button(46, 1, 5, 1, 0xFFEFFF, 0x555555, 0x880000, 0xFFFFFF, "Upd"))
	updateButton.onTouch = function() updateOrder() end
	local deleteButton = containerDescription:addChild(client.GUI.button(46, 2, 5, 1, 0xFFEFFF, 0x555555, 0x880000, 0xFFFFFF, "Del"))
	deleteButton.onTouch = function() deleteOrder() end
	local newButton = containerDescription:addChild(client.GUI.button(46, 3, 5, 1, 0xFFEFFF, 0x555555, 0x880000, 0xFFFFFF, "New"))
	newButton.onTouch = function() insertOrder() end
end

displayOrderItemCommands = function()
	local updateButton = containerButtons:addChild(client.GUI.button(27, 2, 5, 1, 0xFFEFFF, 0x555555, 0x880000, 0xFFFFFF, "Upd"))
	updateButton.onTouch = function() if orderItemList:count() == 0 then return end; displayOrderItemCRUD(orderItemList.selectedItem - 1, "upd") end
	local deleteButton = containerButtons:addChild(client.GUI.button(34, 2, 5, 1, 0xFFEFFF, 0x555555, 0x880000, 0xFFFFFF, "Del"))
	deleteButton.onTouch = function() deleteOrderItem() end
	local newButton = containerButtons:addChild(client.GUI.button(41, 2, 5, 1, 0xFFEFFF, 0x555555, 0x880000, 0xFFFFFF, "New"))
	newButton.onTouch = function() if ordersList:count() == 0 then return end; displayOrderItemCRUD(orderItemList.selectedItem - 1, "ins") end
end

displayOrders = function()
  local selected
  if ordersList.selectedItem > 0 then 
    selected = ordersList:getItem(ordersList.selectedItem).text 
  end

	ordersList:removeChildren()
	local tkeys = {}
	for k in pairs(client.dataOrders) do table.insert(tkeys, k) end
	table.sort(tkeys)
 	local i = 1
 	for _, k in ipairs (tkeys) do
		ordersList:addItem(k).onTouch = function() displayOrderHudAndItems(ordersList:getItem(k).text) end
		if selected ~= nil and k == selected then ordersList.selectedItem = i; displayOrderHudAndItems(selected) end
		if orderNameToBeSelected ~= nil and k == orderNameToBeSelected then	ordersList.selectedItem = i; displayOrderHudAndItems(orderNameToBeSelected)	end
		i = i + 1
 	end
  if selected == nil and ordersList:count() > 0 then ordersList.selectedItem = 1; displayOrderHudAndItems(ordersList:getItem(1).text) end 	
 	
 	orderNameToBeSelected = nil
 	
	client.application:draw()
end

OrdersModif.display = function()
	local window = client.application:addChild(client.GUI.titledWindow(50, 22, 80, 26, name, true))
	window.actionButtons.close.onTouch = function() client.closeWindow(name) end

	local panelOrders = window:addChild(client.GUI.panel(2, 2, 21, 20, 0x880000))
	local panelDescription = window:addChild(client.GUI.panel(25, 2, 55, 16, 0x880000))
	local panelCommands = window:addChild(client.GUI.panel(25, 19, 55, 3, 0x880000))
	local panelCrud = window:addChild(client.GUI.panel(2, 23, window.width -2, 3, 0x880000))
	
	containerButtons = window:addChild(client.GUI.container(2, 19, window.width - 2, 3))
	containerFields = window:addChild(client.GUI.container(2, 23, window.width - 2, 3))
	
	containerDescription = client.GUI.container(panelDescription.x, panelDescription.y, panelDescription.width, panelDescription.height)
	window:addChild(containerDescription)

	displayOrderCommands()	
	displayOrderItemCommands()

	--list of orders
	ordersList = window:addChild(client.GUI.list(3, 3, 19, 18, 1, 0, 0xE1E1E1, 0x4B4B4B, 0xD2D2D2, 0x4B4B4B, 0x3366CC, 0xFFFFFF, false))
	ordersList.selectedItem = 0
	
	--description of order	
	containerDescription:addChild(client.GUI.text(2, 1, 0xFFFFFF, "Old:"))
	oldOrderName = containerDescription:addChild(client.GUI.text(8, 1, 0xFFFFFF, ""))
	
	containerDescription:addChild(client.GUI.text(2, 2, 0xFFFFFF, "Name:"))
	orderName = containerDescription:addChild(client.GUI.input(8, 2, 19, 1, 0xEEEEEE, 0x555555, 0x999999, 0xFFFFFF, 0x2D2D2D, "", ""))
	containerDescription:addChild(client.GUI.text(28, 2, 0xFFFFFF, "Repeat:"))
	orderRepeat = containerDescription:addChild(client.GUI.input(36, 2, 8, 1, 0xEEEEEE, 0x555555, 0x999999, 0xFFFFFF, 0x2D2D2D, "0", "0"))

	--order lines	
	orderItemList = window:addChild(client.GUI.list(26, 5, 53, 12, 1, 0, 0xE1E1E1, 0x4B4B4B, 0xD2D2D2, 0x4B4B4B, 0x3366CC, 0xFFFFFF, false))

	displayOrders()
	orderItemList.switch = {}
	orderItemList.switch.refresh = displayOrders
	listenToOrdersList(orderItemList, name)
	
	return window
end	
 	
return OrdersModif