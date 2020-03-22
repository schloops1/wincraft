local ApplicationFactory = {}
local colors = require "colors"
local sides = require "sides"
local dmp = require "dump"

local client
local name

local dataApplis

function ApplicationFactory:set(aname)
	client = self; name = aname
end

local appli
local appliNameField
local oldAppliNameField
local vsizeField
local vIntervalField
local applisList
local appliItemList

local containerDescription
local containerButtons
local containerFields
local typeField
local idField
local blockField
local sideField
local colorField
local colorEndField
local forceField
local timeField
local aliasField
local orderNameField
local outputNameField
local varNameField
local appliNameToBeSelected = nil

local defaultColors = {2960685, 15790320, 16777024, 0, 6722239, 0}
local posXColors = {54, 66, 54, 66, 54, 66}
local posYColors = {1,1,2,2,3,3}

for iii=1,6,1 do
	ApplicationFactory["color"..iii.."Text"] = {}
	ApplicationFactory["color"..iii.."Text"].textColor = defaultColors[iii]--0xFFEFFF
	ApplicationFactory["color"..iii.."Text"].remove = function() end
end

local isNew = function(name)
	for k, v in ipairs(dataApplis) do
		if v.name == name then return false end
	end
	return true
end

cleanCRUDFields = function()
	containerFields:removeChildren()
	client.application:draw()
end

local readData = function()
	local json = require("json")
	dataApplis = json.decode(io.open("/home/wincraft/client/applications/dataApplis.json", "r"):read("*all"))
	json = nil; package.loaded.json = nil
end

local saveData = function()
	local f=io.open("./wincraft/client/applications/dataApplis.json","w")
	local json = require "json"
	f:write(json.encode(dataApplis))
	f:close()
	package.loaded.json = nil	
end

local saveAppliFile = function(data, name)
	local f=io.open("./wincraft/client/applications/custom/"..name,"w")
	f:write(data)
	f:close()
end

deleteAppliFile = function(fileName)
	local aFileName 
	if fileName == nil then aFileName = appli.name else aFileName = fileName end

	local fs = require "filesystem"; fs.remove("/home/wincraft/client/applications/custom/"..aFileName..".lua")
end

createAppliFile = function()
	local xCtrl = 18
	local aliasNode = require("AliasNode")
	local astring = "local "..appli.name.." = {} "
	astring = astring.."local name, client "
	astring = astring.."function "..appli.name..":set(aname) client = self; name = aname end "
	astring = astring..appli.name..".display = function() "
	astring = astring.."local window = client.application:addChild(client.GUI.titledWindow(50, 22, 42, "..(appli.vsize)..", name, true,"..appli.color1..")) "
	astring = astring.."window.actionButtons.close.onTouch = function() client.closeWindow(name) end "
	astring = astring.."local container = window:addChild(client.GUI.container(2, 2, 40, "..(appli.vsize - 1)..")); "
	
	for k, v in pairs(appli.items) do--0x123512
		if v["type"] == "output" then
			astring = astring.."container:addChild(client.GUI.text(2, "..k * appli.interval..", "..appli.color2..", '"..v.text.."')); "
			astring = astring.."local ctrl"..k.." = client.addSyncSwitchNoLabel('"..v.block.."', "..v.side..", "..v.color..", '"..appli.name.."', "..appli.color3..", "..appli.color4..", "..appli.color5.."); "
			astring = astring.."ctrl"..k..".y = "..k*appli.interval.."; ctrl"..k..".x = "..xCtrl.."; "
			astring = astring.."container:addChild(ctrl"..k.."); "
		elseif v["type"] == "display" then
			astring = astring.."container:addChild(client.GUI.text(2, "..k * appli.interval..", "..appli.color2..", '"..v.text.."')); "
			astring = astring.."local ctrl"..k.." = client.addSyncRectangle('"..v.block.."', "..v.side..", "..v.color..", '"..appli.name.."', "..appli.color3..", "..appli.color4.."); "
			astring = astring.."ctrl"..k..".y = "..k*appli.interval.."; ctrl"..k..".x = "..xCtrl.."; ctrl"..k..".width=11; "
			astring = astring.."container:addChild(ctrl"..k.."); "
		elseif v["type"] == "execOrder" then
			astring = astring.."container:addChild(client.GUI.text(2, "..k*appli.interval..", "..appli.color2..", '"..v.name.."')); "
			astring = astring.."local ctrl"..k.." = client.addSyncSwitchOrderNoLabel('"..appli.name.."', 'offOn', '"..v.name.."', "..appli.color3..", "..appli.color4..", "..appli.color5.."); "
			astring = astring.."ctrl"..k..".y = "..k*appli.interval.."; ctrl"..k..".x = "..xCtrl.."; "
			astring = astring.."container:addChild(ctrl"..k.."); "
		elseif v["type"] == "outAlias" then	
			local alias = aliasNode.getDataNode(client.dataAliases, v.alias)
			astring = astring.."container:addChild(client.GUI.text(2, "..k*appli.interval..", "..appli.color2..", '"..v.alias.."')); "
			if alias.node then
				astring = astring.."local offButton"..k.." = container:addChild(client.GUI.button("..xCtrl..", "..k*appli.interval..", 5, 1, "..appli.color5..", "..appli.color6..", "..appli.color3..", "..appli.color4..", 'Off'))"
				astring = astring.."offButton"..k..".onTouch = function() client.offOnAlias('"..v.alias.."', 0) end "
				astring = astring.."local onButton"..k.." = container:addChild(client.GUI.button("..(xCtrl + 6)..", "..k*appli.interval..", 5, 1, "..appli.color5..", "..appli.color6..", "..appli.color3..", "..appli.color4..", 'On'))"
				astring = astring.."onButton"..k..".onTouch = function() client.offOnAlias('"..v.alias.."', 255) end "
			else
				astring = astring.."local ctrl"..k.." = client.addSyncSwitchNoLabel('"..alias.block.."', "..alias.side..", "..alias.color..", '"..appli.name.."', "..appli.color3..", "..appli.color4..", "..appli.color5.."); "
				astring = astring.."ctrl"..k..".y = "..k*appli.interval.."; ctrl"..k..".x = "..xCtrl.." ; "
				astring = astring.."container:addChild(ctrl"..k.."); "
			end
		elseif v["type"] == "variable" then
			astring = astring.."container:addChild(client.GUI.text(2, "..k*appli.interval..", "..appli.color2..", '"..v.var.."')); "
			astring = astring.."local ctrl"..k.." = client.addSynchVarTxt('"..appli.name.."', '"..v.var.."'); "
			astring = astring.."ctrl"..k..".y = "..k*appli.interval.."; ctrl"..k..".x = "..xCtrl.."; "
			astring = astring.."container:addChild(ctrl"..k.."); "	
		elseif v["type"] == "updVar" then
			astring = astring.."container:addChild(client.GUI.text(2, "..k*appli.interval..", "..appli.color2..", '"..v.var.."')); "
			astring = astring.."local ctrl"..k.." = client.addSynchVarEditable('"..appli.name.."', '"..v.var.."'); "
			astring = astring.."ctrl"..k..".y = "..k*appli.interval.."; ctrl"..k..".x = "..xCtrl.."; "
			astring = astring.."container:addChild(ctrl"..k.."); "	
			astring = astring.."local ctrlb"..k.." = client.addSynchVarTxtButton('"..appli.name.."', '"..v.var.."', ctrl"..k..", "..appli.color5..", "..appli.color6..", "..appli.color3..", "..appli.color4.."); "
			astring = astring.."ctrlb"..k..".y = "..k*appli.interval.."; ctrlb"..k..".x = "..(xCtrl + 18).."; "
			astring = astring.."container:addChild(ctrlb"..k.."); "	
		elseif v["type"] == "disMul" then
      astring = astring.."container:addChild(client.GUI.text(2, "..k * appli.interval..", "..appli.color2..", '"..v.text.."')); "
		  astring = astring.."local switches = client.addSyncRectangleArray('"..v.block.. "', "..v.side..", "..v.color..", "..v.colorEnd..", '"..appli.name.."', "..appli.color2..", "..appli.color4..") "
      astring = astring.."for i, switch in ipairs(switches) do "
      astring = astring.."switches[i].y = "..k*appli.interval.."; switches[i].x = switches[i].x - 1 + "..xCtrl.." ; "
      astring = astring.."container:addChild(switches[i]); "  
      astring = astring.."end "
		end
	end
	astring = astring.."return window end ".."return "..appli.name
	return astring
end

insertAppli = function()
	if not isNew(appliNameField.text) or appliNameField.text == "" then return end
	if string.len(appliNameField.text) > 16 then appliNameField.text = string.sub(appliNameField.text, 1, 16) end
	local aAppli = {}
	aAppli.name = appliNameField.text
	aAppli.vsize = vsizeField.selectedItem + 5
	aAppli.interval = vIntervalField.selectedItem
	
	if ApplicationFactory.color1Text == nil or ApplicationFactory.color1Text.textColor == nil then
		for i=1,6,1 do
			ApplicationFactory["color"..i.."Text"] = {}
			ApplicationFactory["color"..i.."Text"].textColor = 0xFFFFFF
			ApplicationFactory["color"..i.."Text"].remove = function() end
		end	
	end
	
	for ii=1,6,1 do
		aAppli["color"..ii] = ApplicationFactory["color"..ii.."Text"].textColor
	end
	
	cleanCRUDFields()
	aAppli.items = {}
	table.insert(dataApplis, aAppli)
	appli = aAppli
	saveData()
	saveAppliFile(createAppliFile(), appli.name..".lua")
	client.insertCustomMenu(aAppli.name)
	displayApplis()
end

deleteAppli = function()
	if appliNameField.text == "" then return end
	for k, v in ipairs(dataApplis) do
		if v.name == appliNameField.text then
			table.remove(dataApplis, k)
		end
	end
	cleanCRUDFields()
	saveData()
	deleteAppliFile()
	client.deleteCustomMenu(appliNameField.text)
	displayApplis()
end

updateAppli = function()
	if appliNameField.text ~= oldAppliNameField.text and not isNew(appliNameField.text) then return end
	if appliNameField.text == "" then return end
	if string.len(appliNameField.text) > 16 then appliNameField.text = string.sub(appliNameField.text, 1, 16) end
	appli.name = appliNameField.text
	appli.vsize = vsizeField.selectedItem + 5
	appli.interval = vIntervalField.selectedItem
	
	for ii=1,6,1 do
		appli["color"..ii] = ApplicationFactory["color"..ii.."Text"].textColor
	end
	
	cleanCRUDFields()
	saveData()
	deleteAppliFile(oldAppliNameField.text)
	saveAppliFile(createAppliFile(), appli.name..".lua")
	client.updateCustomMenu(oldAppliNameField.text, appliNameField.text)
	displayApplis()
end

insertAppliItem = function()
	if applisList:count() == 0 then return end
	local id = 0
	if appliItemList:count() ~= 0 then id = appliItemList.selectedItem end
	local appliItem = {}
	appliItem["id"] = id
	appliItem["type"] = typeField:getItem(typeField.selectedItem).text
	if appliItem["type"] == "output" or appliItem["type"] == "display" then
		if appliItem["type"] == "output" then
			if tonumber(forceField.text) == nil then return end
			if tonumber(forceField.text) > 255 then forceField.text = "255" end
		end
		appliItem["block"] = blockField:getItem(blockField.selectedItem).text
		appliItem["side"] = sideField.selectedItem - 1
		appliItem["color"] = colorField.selectedItem - 1
		if appliItem["type"] == "output" then appliItem["force"] = forceField.text end
		appliItem["text"] = outputNameField.text
	elseif appliItem["type"] == "outAlias" then	
		if tonumber(forceField.text) == nil then return end
		if tonumber(forceField.text) > 255 then forceField.text = "255" end
		appliItem["alias"] = aliasField:getItem(aliasField.selectedItem).text
		appliItem["force"] = forceField.text
	elseif appliItem["type"] == "execOrder" then
		appliItem["name"] = orderNameField:getItem(orderNameField.selectedItem).text
	elseif appliItem["type"] == "display" then
		
	elseif appliItem["type"] == "nothing" then
	
	elseif appliItem["type"] == "variable" then
		appliItem["var"] = varField:getItem(varField.selectedItem).text
		
	elseif appliItem["type"] == "updVar" then
		appliItem["var"] = varField:getItem(varField.selectedItem).text
	
	elseif appliItem["type"] == "disMul" then
    appliItem["block"] = blockField:getItem(blockField.selectedItem).text
    appliItem["side"] = sideField.selectedItem - 1
    appliItem["color"] = colorField.selectedItem - 1
    appliItem["colorEnd"] = colorEndField.selectedItem - 1
		appliItem["text"] = outputNameField.text
	end

	local items = appli.items
	for k, v in ipairs(items) do
		if v.id >= id then v.id = v.id + 1 end
	end
	table.insert(items, id + 1, appliItem)
	appliItemList.selectedItem = id + 1

	saveData()
	saveAppliFile(createAppliFile(), appli.name..".lua")
	cleanCRUDFields()
	displayApplis(appli.name)
end

updateAppliItem = function()
	if appliItemList:count() == 0 then return end
	--if client.dataOrders[oldOrderName.text].offOn == true then return end
	local id = appliItemList.selectedItem
	local appliItem = appli.items[id]
	appliItem["type"] = typeField:getItem(typeField.selectedItem).text
	if appliItem["type"] == "output" or appliItem["type"] == "display" then
		if appliItem["type"] == "output" then
			if tonumber(forceField.text) == nil then return end
			if tonumber(forceField.text) > 255 then forceField.text = "255" end
		end
		appliItem["block"] = blockField:getItem(blockField.selectedItem).text
		appliItem["side"] = sideField.selectedItem - 1
		appliItem["color"] = colorField.selectedItem - 1
		if appliItem["type"] == "output" then appliItem["force"] = forceField.text end
		appliItem["text"] = outputNameField.text
	elseif appliItem["type"] == "outAlias" then	
		if tonumber(forceField.text) == nil then return end
		if tonumber(forceField.text) > 255 then forceField.text = "255" end
		appliItem["alias"] = aliasField:getItem(aliasField.selectedItem).text
		appliItem["force"] = forceField.text
	elseif appliItem["type"] == "execOrder" then
		appliItem["name"] = orderNameField:getItem(orderNameField.selectedItem).text	
	elseif appliItem["type"] == "nothing" then
	
	elseif appliItem["type"] == "variable" then
		appliItem["var"] = varField:getItem(varField.selectedItem).text
	
	elseif appliItem["type"] == "updVar" then
		appliItem["var"] = varField:getItem(varField.selectedItem).text
		
	elseif appliItem["type"] == "disMul" then
		appliItem["block"] = blockField:getItem(blockField.selectedItem).text
    appliItem["side"] = sideField.selectedItem - 1
    appliItem["color"] = colorField.selectedItem - 1
    appliItem["colorEnd"] = colorEndField.selectedItem - 1
    appliItem["text"] = outputNameField.text		
	end
	
	saveData()
	saveAppliFile(createAppliFile(), appli.name..".lua")
	cleanCRUDFields()
	displayApplis(appli.name)
end

deleteAppliItem = function()
	if appliItemList:count() == 0 then return end
	--if client.dataOrders[oldOrderName.text].offOn == true then return end
	--cleanFields()
	local id = appliItemList.selectedItem
	local items = appli.items
	table.remove(items, id)
	for k, v in ipairs(items) do
		if v.id >= id then v.id = v.id - 1 end
	end
	if appliItemList:count() > 0 then appliItemList.selectedItem = 1 end
	
	saveData()
	saveAppliFile(createAppliFile(), appli.name..".lua")
	cleanCRUDFields()
	displayApplis(appli.name)
end

local getAppli = function(name)
	for k, v in pairs(dataApplis) do
		if v.name == name then return v end
	end
end

getItem = function(id)
	for _, item in ipairs(appli.items) do
	    if item.id == id then return item end
	end
end

--fill CRUD fields
displayAppliItemCRUD = function(id, action, typeValue)
	local item = nil
	if id ~= nil and typeValue == nil and action ~= "ins" then item = getItem(id) end

	containerFields:removeChildren()
	idField = containerFields:addChild(client.GUI.text(2, 2, 0xFFFFFF, "Id:"..dmp.okv(id)))
	typeField = containerFields:addChild(client.GUI.comboBox(9, 2, 10, 1, 0xEEEEEE, 0x2D2D2D, 0xCCCCCC, 0x888888))
	typeField:addItem("output").onTouch = function() displayAppliItemCRUD(id, action, "output") end
	typeField:addItem("outAlias").onTouch = function() displayAppliItemCRUD(id, action, "outAlias") end
	typeField:addItem("execOrder").onTouch = function() displayAppliItemCRUD(id, action, "execOrder") end
	typeField:addItem("display").onTouch = function() displayAppliItemCRUD(id, action, "display") end
	typeField:addItem("nothing").onTouch = function() displayAppliItemCRUD(id, action, "nothing") end
	typeField:addItem("variable").onTouch = function() displayAppliItemCRUD(id, action, "variable") end
	typeField:addItem("updVar").onTouch = function() displayAppliItemCRUD(id, action, "updVar") end
	typeField:addItem("disMul").onTouch = function() displayAppliItemCRUD(id, action, "disMul") end

	if (item ~= nil and item["type"] == "output") or (action ~= nil and action == "ins" and typeValue == nil) or (typeValue ~= nil and typeValue == "output") then 
		typeField.selectedItem = 1
	elseif (item ~= nil and item["type"] == "outAlias") or (typeValue ~= nil and typeValue == "outAlias") then 
		typeField.selectedItem = 2
	elseif (item ~= nil and item["type"] == "execOrder") or (typeValue ~= nil and typeValue == "execOrder") then 
		typeField.selectedItem = 3
	elseif (item ~= nil and item["type"] == "display") or (typeValue ~= nil and typeValue == "display") then 
		typeField.selectedItem = 4
	elseif (item ~= nil and item["type"] == "nothing") or (typeValue ~= nil and typeValue == "nothing") then 
		typeField.selectedItem = 5	
	elseif (item ~= nil and item["type"] == "variable") or (typeValue ~= nil and typeValue == "variable") then 
		typeField.selectedItem = 6	
	elseif (item ~= nil and item["type"] == "updVar") or (typeValue ~= nil and typeValue == "updVar") then 
		typeField.selectedItem = 7
	elseif (item ~= nil and item["type"] == "disMul") or (typeValue ~= nil and typeValue == "disMul") then 
		typeField.selectedItem = 8
	end
	
	if typeField.selectedItem == 1 or typeField.selectedItem == 4 then --output, display
		blockField = containerFields:addChild(client.GUI.comboBox(20, 2, 12, 1, 0xEEEEEE, 0x2D2D2D, 0xCCCCCC, 0x888888))
		local ii = 1
		local iiSelected
		for k, v in pairs (client.data) do
			blockField:addItem(k)
			if item ~= nil and k == item.block then iiSelected = ii end
			ii = ii + 1
		end
		if iiSelected == nil then iiSelected = 1 end
		blockField.selectedItem = iiSelected

		sideField = containerFields:addChild(client.GUI.comboBox(33, 2, 10, 1, 0xEEEEEE, 0x2D2D2D, 0xCCCCCC, 0x888888))
		for i = 0, 5 do
			sideField:addItem(sides[i])
		end
		if item ~= nil then sideField.selectedItem = item.side + 1 end

		colorField = containerFields:addChild(client.GUI.comboBox(44, 2, 10, 1, 0xEEEEEE, 0x2D2D2D, 0xCCCCCC, 0x888888))
		for i = 0, 15 do
			colorField:addItem(colors[i])
		end
		if item ~= nil then colorField.selectedItem = item.color + 1 end

		if typeField.selectedItem == 1 then
			forceField = containerFields:addChild(client.GUI.input(55, 2, 6, 1, 0xEEEEEE, 0x555555, 0x999999, 0xFFFFFF, 0x2D2D2D, "", ""))
			if item ~= nil then forceField.text = item.force end
		end
		
		containerFields:addChild(client.GUI.text(20, 3, 0xFFFFFF, "Text:"))
		outputNameField = containerFields:addChild(client.GUI.input(28, 3, 16, 1, 0xEEEEEE, 0x555555, 0x999999, 0xFFFFFF, 0x2D2D2D, "", ""))
		if item ~= nil then outputNameField.text = item.text end
		
	elseif typeField.selectedItem == 2 then --outAlias
		local listAliases = {}
		local aliasNode = require "AliasNode"		
		aliasNode.getAllAliases(client.dataAliases, listAliases)
		aliasField = containerFields:addChild(client.GUI.comboBox(20, 2, 16, 1, 0xEEEEEE, 0x2D2D2D, 0xCCCCCC, 0x888888))
		local iiSelected = 1
		for k, v in ipairs(listAliases) do
			aliasField:addItem(v)
			if item ~= nil and v == item.alias then iiSelected = k end
		end
		aliasField.selectedItem = iiSelected

		forceField = containerFields:addChild(client.GUI.input(37, 2, 6, 1, 0xEEEEEE, 0x555555, 0x999999, 0xFFFFFF, 0x2D2D2D, "", ""))
		if item ~= nil then forceField.text = item.force end
	elseif typeField.selectedItem == 3 then --execOrder
		orderNameField = containerFields:addChild(client.GUI.comboBox(20, 2, 20, 1, 0xEEEEEE, 0x2D2D2D, 0xCCCCCC, 0x888888))
		local tkeys = {}; for k in pairs(client.dataOrders) do table.insert(tkeys, k) end; table.sort(tkeys)
		local i = 1; local iSelected = 0
		for _, k in ipairs (tkeys) do
			orderNameField:addItem(k)
			if item ~= nil and k == item.name then iSelected = i end
			i = i + 1
		end
		if iSelected ~= 0 then orderNameField.selectedItem = iSelected else orderNameField.selectedItem = 1 end
	elseif typeField.selectedItem == 5 then --nothing

	elseif typeField.selectedItem == 6 or typeField.selectedItem == 7 then --variable, updVar
		varField = containerFields:addChild(client.GUI.comboBox(20, 2, 20, 1, 0xEEEEEE, 0x2D2D2D, 0xCCCCCC, 0x888888))
		local iiSelected = 1
		local ii = 1
		for k, v in pairs(client.dataVarsList) do
  			varField:addItem(k)
  			if item ~= nil and k == item.var then iiSelected = ii end
  			ii = ii + 1
		end
		varField.selectedItem = iiSelected
  elseif typeField.selectedItem == 8 then --disMul
    blockField = containerFields:addChild(client.GUI.comboBox(20, 2, 12, 1, 0xEEEEEE, 0x2D2D2D, 0xCCCCCC, 0x888888))
    local ii = 1
    local iiSelected
    for k, v in pairs (client.data) do
      blockField:addItem(k)
      if item ~= nil and k == item.block then iiSelected = ii end
      ii = ii + 1
    end
    if iiSelected == nil then iiSelected = 1 end
    blockField.selectedItem = iiSelected

    sideField = containerFields:addChild(client.GUI.comboBox(33, 2, 10, 1, 0xEEEEEE, 0x2D2D2D, 0xCCCCCC, 0x888888))
    for i = 0, 5 do
      sideField:addItem(sides[i])
    end
    if item ~= nil then sideField.selectedItem = item.side + 1 end

    colorField = containerFields:addChild(client.GUI.comboBox(44, 2, 9, 1, 0xEEEEEE, 0x2D2D2D, 0xCCCCCC, 0x888888))
    for i = 0, 15 do
      colorField:addItem(colors[i])
    end
    if item ~= nil then colorField.selectedItem = item.color + 1 end
    
    colorEndField = containerFields:addChild(client.GUI.comboBox(54, 2, 9, 1, 0xEEEEEE, 0x2D2D2D, 0xCCCCCC, 0x888888))
    for i = 0, 15 do
      colorEndField:addItem(colors[i])
    end
    if item ~= nil then colorEndField.selectedItem = item.colorEnd + 1 end    

    containerFields:addChild(client.GUI.text(20, 3, 0xFFFFFF, "Text:"))
    outputNameField = containerFields:addChild(client.GUI.input(28, 3, 16, 1, 0xEEEEEE, 0x555555, 0x999999, 0xFFFFFF, 0x2D2D2D, "", ""))
    if item ~= nil then outputNameField.text = item.text end
    
	end
	
	displayAppliCRUDCommands(action)
	client.application:draw()	
	
	
end

local appliSelected = function()
	appliItemList:removeChildren()
	--fill header
	appliNameField.text = appli.name
	oldAppliNameField.text = appli.name
	vsizeField.selectedItem = (appli.vsize - 5)
	vIntervalField.selectedItem = appli.interval
	
	for i=1,6,1 do
		ApplicationFactory.onColorSelected(i, appli["color"..i])
	end

	local items = appli.items
	table.sort(items, function(a,b) return a.id < b.id end)

	for k, v in ipairs(items) do
		local astring = dmp.okv(v.id)
		if v["type"] == "output" then
			--astring = astring.." O block:"..string.sub(v.block, 1, 8).." side:"..sides[v.side].." color:"..colors[v.color].." "..v["force"]
			astring = astring.." O text:"..v.text.." "..v["force"]
		elseif v["type"] == "outAlias" then
			astring = astring.." OA alias:"..v.alias.." "..v["force"]
		elseif v["type"] == "execOrder" then
			astring = astring.." EO name "..v.name	
		elseif v["type"] == "display" then
			astring = astring.." D "
		elseif v["type"] == "nothing" then
			astring = astring.." N "
		elseif v["type"] == "variable" then
			astring = astring.." V "..v.var	
		elseif v["type"] == "updVar" then
			astring = astring.." UV "..v.var	
		elseif v["type"] == "disMul" then
			astring = astring.." DisMul "..v.block:sub(1, 6).." "..sides[v.side].." "..colors[v.color].." "..colors[v.colorEnd]
		end			
	
		appliItemList:addItem(astring).onTouch = cleanCRUDFields
	end
	client.application:draw()
end

displayApplis = function(name)
	if name ~= nil then appli = getAppli(name) end
	applisList:removeChildren()
	appliItemList:removeChildren()
	local sort_func = function( a,b ) return a.name < b.name end
	table.sort( dataApplis, sort_func )
	
 	local i = 1
 	for k, v in ipairs (dataApplis) do
		applisList:addItem(v.name).onTouch = function() cleanCRUDFields(); appli = getAppli(v.name); appliSelected() end
		if appli ~= nil and v.name == appli.name then i = k end
		--if appliNameToBeSelected ~= nil and k == appliNameToBeSelected then	applisList.selectedItem = i; displayAppliHudAndItems(orderNameToBeSelected)	end
		--i = i + 1
 	end
 	
 	applisList.selectedItem = i
 	if appli == nil and applisList:count() > 0 then appli = getAppli(applisList:getItem(1).text) end
	
	if appli ~= nil then appliSelected(appli.name) end
	client.application:draw()
end

displayAppliCRUDCommands = function(action)
	if action == "upd" then
		local updateButton = containerFields:addChild(client.GUI.button(64, 2, 6, 1, 0xFFEFFF, 0x555555, 0x880000, 0xFFFFFF, "Upd"))
		updateButton.onTouch = function() updateAppliItem() end
	else
		local insertButton = containerFields:addChild(client.GUI.button(64, 2, 6, 1, 0xFFEFFF, 0x555555, 0x880000, 0xFFFFFF, "New"))
		insertButton.onTouch = function() insertAppliItem() end
	end
	local cancelButton = containerFields:addChild(client.GUI.button(71, 2, 6, 1, 0xFFEFFF, 0x555555, 0x880000, 0xFFFFFF, "Cancel"))
	cancelButton.onTouch = function() cleanCRUDFields() end
end

displayAppliCommands = function()
	local updateButton = containerDescription:addChild(client.GUI.button(46, 1, 5, 1, 0xFFEFFF, 0x555555, 0x880000, 0xFFFFFF, "Upd"))
	updateButton.onTouch = function() updateAppli() end
	local deleteButton = containerDescription:addChild(client.GUI.button(46, 2, 5, 1, 0xFFEFFF, 0x555555, 0x880000, 0xFFFFFF, "Del"))
	deleteButton.onTouch = function() deleteAppli() end
	local newButton = containerDescription:addChild(client.GUI.button(46, 3, 5, 1, 0xFFEFFF, 0x555555, 0x880000, 0xFFFFFF, "New"))
	newButton.onTouch = function() insertAppli() end
end

displayAppliItemCommands = function()
	local updateButton = containerButtons:addChild(client.GUI.button(27, 2, 5, 1, 0xFFEFFF, 0x555555, 0x880000, 0xFFFFFF, "Upd"))
	updateButton.onTouch = function() if appliItemList:count() == 0 then return end; displayAppliItemCRUD(appliItemList.selectedItem - 1, "upd") end
	local deleteButton = containerButtons:addChild(client.GUI.button(34, 2, 5, 1, 0xFFEFFF, 0x555555, 0x880000, 0xFFFFFF, "Del"))
	deleteButton.onTouch = function() deleteAppliItem() end
	local newButton = containerButtons:addChild(client.GUI.button(41, 2, 5, 1, 0xFFEFFF, 0x555555, 0x880000, 0xFFFFFF, "New"))
	newButton.onTouch = function() if applisList:count() == 0 then return end; displayAppliItemCRUD(appliItemList.selectedItem - 1, "ins") end
	
	for i=1,6,1 do
		containerButtons:addChild(client.GUI.button(posXColors[i] + 8, posYColors[i], 3, 1, 0xFFEFFF, 0x555555, 0x880000, 0xFFFFFF, "U")).onTouch = function()
			local object = {}; object.onColorSelected = ApplicationFactory.changeColor
			client.GUI.colorChooser(client.application, object, i, 0xFFEFFF)
		end
	end
end

ApplicationFactory.changeColor = function(colorNbr, color)
	ApplicationFactory.onColorSelected(colorNbr, color)
	updateAppli()
end

ApplicationFactory.onColorSelected = function(colorNbr, color)
	local thingy = ApplicationFactory["color"..colorNbr.."Text"]
	if thingy ~= nil then thingy:remove() end
	thingy.textColor = color
	thingy = containerButtons:addChild(client.GUI.text(posXColors[colorNbr], posYColors[colorNbr], color, "Color "..colorNbr..":"))
	client.application:draw()
end

displayHeaderFields = function()
	containerDescription:addChild(client.GUI.text(2, 1, 0xFFFFFF, "Old:"))
	oldAppliNameField = containerDescription:addChild(client.GUI.text(8, 1, 0xFFFFFF, ""))
	
	containerDescription:addChild(client.GUI.text(2, 2, 0xFFFFFF, "Name:"))
	appliNameField = containerDescription:addChild(client.GUI.input(8, 2, 19, 1, 0xEEEEEE, 0x555555, 0x999999, 0xFFFFFF, 0x2D2D2D, "", ""))

	containerDescription:addChild(client.GUI.text(29, 1, 0xFFFFFF, "VSize:"))
	vsizeField = containerDescription:addChild(client.GUI.comboBox(36, 1, 5, 1, 0xEEEEEE, 0x2D2D2D, 0xCCCCCC, 0x888888))
	for i = 6, 42 do
		vsizeField:addItem(i)
	end
	containerDescription:addChild(client.GUI.text(29, 2, 0xFFFFFF, "Interval:"))
	vIntervalField = containerDescription:addChild(client.GUI.comboBox(39, 2, 5, 1, 0xEEEEEE, 0x2D2D2D, 0xCCCCCC, 0x888888))
	for i = 1, 3 do
		vIntervalField:addItem(i)
	end
end

ApplicationFactory.display = function()
	local window = client.application:addChild(client.GUI.titledWindow(50, 22, 80, 26, name, true))
	window.actionButtons.close.onTouch = function() client.closeWindow(name) end

	local panelApplis = window:addChild(client.GUI.panel(2, 2, 21, 20, 0x880000))
	local panelDescription = window:addChild(client.GUI.panel(25, 2, 55, 16, 0x880000))
	local panelElements = window:addChild(client.GUI.panel(25, 19, 55, 3, 0x880000))
	local panelCrud = window:addChild(client.GUI.panel(2, 23, window.width -2, 3, 0x880000))
	containerButtons = window:addChild(client.GUI.container(2, 19, window.width - 2, 3))
	containerFields = window:addChild(client.GUI.container(2, 23, window.width - 2, 3))
	containerDescription = client.GUI.container(panelDescription.x, panelDescription.y, panelDescription.width, panelDescription.height)
	window:addChild(containerDescription)

	--get data
	readData()

	--list of applis
	applisList = window:addChild(client.GUI.list(3, 3, 19, 18, 1, 0, 0xE1E1E1, 0x4B4B4B, 0xD2D2D2, 0x4B4B4B, 0x3366CC, 0xFFFFFF, false))
	
	--header of appli	
	displayHeaderFields()

	--appli items
	appliItemList = window:addChild(client.GUI.list(26, 5, 53, 12, 1, 0, 0xE1E1E1, 0x4B4B4B, 0xD2D2D2, 0x4B4B4B, 0x3366CC, 0xFFFFFF, false))
	
	--buttons
	displayAppliCommands()	
	displayAppliItemCommands()

	displayApplis()
	
	return window
end	
 	
return ApplicationFactory
