local WCClient = {}
package.loaded.GUI = nil
WCClient.GUI = require "GUI"
local thread = require "thread"
local event = require "event"
local bit32 = require "bit32"
local buffer = require("doubleBuffering")
package.loaded.AliasNode = nil
local aliasNode = require "AliasNode"

local json = require "json"

WCClient.application = nil
local modem
local srvAddress
local menu
WCClient.data = {}
WCClient.dataOrders = {}
WCClient.dataAliases = {}
WCClient.dataVars = {}
WCClient.dataVarsList = {}
local listenData = {}
listenData.windows = {}
listenData.orders = {}
listenData.orders.windows = {}
listenData.ordersWindows = {}
listenData.aliasesWindows = {}
listenData.alias = {}
listenData.alias.windows = {}
listenData.vars = {}
listenData.vars.windows = {}
listenData.varsWindows = {}

WCClient.dataWindowsLocked = {}
local settings = {}
local customApplis

local port
local settingFile = "settings.json"

package.loaded.dump = nil
local d = require "dump"
--d.newLog()

local loadJsonData = function(fileName, json)
	local f = io.open(fileName, "r")
	local data = json.decode(f:read("*all"))
	f:close()
	return data
end

WCClient.lockWindow = function(windowName, offOn)
	modem.send(srvAddress, port, "LWindow", windowName, offOn)
	d.p("lockWindow "..windowName.." "..tostring(offOn).." sent")
end

WCClient.offOnAlias = function(selectedName, charge)
	modem.send(srvAddress, port, "EAlias", selectedName, charge)
	d.p("offOnAlias "..selectedName.. " "..charge.." sent")
end

WCClient.upDownAlias = function(parentAliasName, index, upDown)
	modem.send(srvAddress, port, "UDAlias", parentAliasName, index, upDown)
	d.p("upDownAlias "..parentAliasName.. " "..index.." "..tostring(upDown).." sent")
end

WCClient.updateAlias = function(oldAliasName, newAliasName, alias)
	modem.send(srvAddress, port, "UAlias", oldAliasName, newAliasName, json.encode(alias))
	d.p("updateAlias "..oldAliasName.. " "..newAliasName.." sent")
end

WCClient.deleteAlias = function(aliasName)
	modem.send(srvAddress, port, "DAlias", aliasName)
	d.p("deleteAlias "..aliasName.." sent")
end

WCClient.insertAlias = function(aliasParentName, aliasName, alias)
	modem.send(srvAddress, port, "IAlias", aliasParentName, aliasName, json.encode(alias))
	d.p("insertAlias "..aliasParentName.. " "..aliasName.." sent")
end

--

WCClient.upDownVar = function(parentVarName, index, upDown)
	modem.send(srvAddress, port, "UDVar", parentVarName, index, upDown)
	d.p("upDownVar "..parentVarName.. " "..index.." "..tostring(upDown).." sent")
end

WCClient.updateVar = function(oldVarName, newVarName, var)
	modem.send(srvAddress, port, "UVar", oldVarName, newVarName, json.encode(var))
	d.p("updateVar "..oldVarName.. " "..newVarName.." sent")
end

WCClient.updateVarValue = function(varName, value)
	modem.send(srvAddress, port, "VVar", varName, value)
	d.p("updateVarValue "..varName.. " "..tostring(value).." sent")
end

WCClient.insertVar = function(varParentName, varName, var)
	modem.send(srvAddress, port, "IVar", varParentName, varName, json.encode(var))
	d.p("insertVar "..varParentName.. " "..varName.." sent")
end

WCClient.deleteVar = function(varName)
	modem.send(srvAddress, port, "DVar", varName)
	d.p("deleteVar "..varName.." sent")
end

--

WCClient.updateOrder = function(oldOrderName, newOrderName, order)
	modem.send(srvAddress, port, "UOrder", oldOrderName, newOrderName, json.encode(order))
	d.p("updateOrder "..oldOrderName.. " "..newOrderName.." sent")
end

WCClient.deleteOrder = function(orderName)
	modem.send(srvAddress, port, "DOrder", orderName)
	d.p("deleteOrder "..orderName.." sent")
end

WCClient.insertOrder = function(orderName, order)
	modem.send(srvAddress, port, "IOrder", orderName, json.encode(order))
	d.p("insertOrder "..orderName.." sent")
end

stopListeningToAliasesList = function(windowName)
	listenData.aliasesWindows[windowName] = nil
	d.p("stopListeningToAliasesList "..windowName.." done")
end

applyChangesAliasesList = function()
	for k, v in pairs (listenData.aliasesWindows) do
		listenData.aliasesWindows[k].switch.refresh()
	end
	d.p("applyChangesAliasesList done")
end

WCClient.listenToAliasesList = function(control, windowName)
	listenData.aliasesWindows[windowName] = control
	d.p("listenToAliasesList "..windowName.." done")
	return control
end

--

stopListeningToVarsList = function(windowName)
	listenData.varsWindows[windowName] = nil
	d.p("stopListeningToVarsList "..windowName.." done")
end

applyChangesVarsList = function()
	for k, v in pairs (listenData.varsWindows) do
		listenData.varsWindows[k].switch.refresh()
	end
	d.p("applyChangesVarsList done")
end

WCClient.listenToVarsList = function(control, windowName)
	listenData.varsWindows[windowName] = control
	d.p("listenToVarsList "..windowName.." done")
	return control
end

--

stopListeningToOrdersList = function(windowName)
	listenData.ordersWindows[windowName] = nil
	d.p("stopListeningToOrdersList "..windowName.." done")
end

applyChangesOrdersList = function()
	for k, v in pairs (listenData.ordersWindows) do
		listenData.ordersWindows[k].switch.refresh()
	end
	d.p("applyChangesOrdersList done")
end

listenToOrdersList = function(control, windowName)
	listenData.ordersWindows[windowName] = control
	d.p("listenToOrdersList "..windowName.." done")
	return control
end


WCClient.stopListeningToWindowWires = function(windowsName)
	listenData.windows[windowsName] = nil
	d.p("stopListeningToWindowWires "..windowsName.." done")
end

stopListeningToWire = function(windowsName, block, side, color)
	--not tested -- need removing tostring probably
	listenData.windows[windowsName][block][side][color] = nil
	d.p("stopListeningToWire "..windowsName.." "..block.." "..side.." "..color.." done")
end

WCClient.stopListeningToWindowOrders = function(windowName)
	listenData.orders.windows[windowName] = nil
	d.p("stopListeningToWindowOrders "..windowName.." done")
end

WCClient.closeWindow = function(name)
	settings.windows[name].control:close()
	WCClient.stopListeningToWindowWires(name)
	WCClient.stopListeningToWindowOrders(name)
	WCClient.stopListeningToWindowVars(name)
	stopListeningToAliasesList(name)
	stopListeningToOrdersList(name)
	settings.windows[name].control = nil
	settings.windows[name].opened = false
	WCClient.dataWindowsLocked[name] = false 
	if settings.windows[name].lockable == true then
		WCClient.lockWindow(name, false)
	end
	WCClient.application:draw()
	d.p("window closed: "..name)
end

openWindow = function(name)
    if settings.windows[name].opened == true then return 0 end
    if WCClient.dataWindowsLocked[name] ~= nil 
    	and WCClient.dataWindowsLocked[name] == true then 
		d.p("window is locked: "..name)
	else    
		package.loaded[name] = nil
		local win = require(name)
		win.set(WCClient, name)
		settings.windows[name].control = win.display()
		settings.windows[name].opened = true
		if settings.windows[name].lockable == true then
			WCClient.lockWindow(name, true)
		end
		WCClient.application:draw()
		return 1
    end    
    d.p("window opened: "..name)
end

getOffOn = function(block, side, color)
	local charge = bit32.band(WCClient.data[block][side], 2^color)
    local offOn = (charge > 0)
    return bit32.band(WCClient.data[block][side], 2^color) > 0
end

WCClient.scrollFromTo = function(percent, amountOrders, scrollSize, layout, displayLine)
	--print("percent "..percent)
	if amountOrders == 0 or scrollSize == 0 then return end
	layout:removeChildren()
	if percent == 0 then percent = 0.01 else percent = percent / 100 end
	--print("percent "..percent)
	local astart
	local aend
	astart = math.floor(amountOrders * percent)
	--print("astart "..astart)
	--if all fit, display all
	if scrollSize >= amountOrders then
		--print("all fit")
		astart = 0
		aend = amountOrders - 1
	else 
		--if not enough from astart
		if scrollSize > amountOrders - astart then
			--print("not enough from astart")
			--aend = amountOrders - 1
			aend = amountOrders - 1
			astart = aend - scrollSize + 1
		else
			--more than enough to fill scrollSize
			--print("more than enough to fill")
			aend = astart + scrollSize - 1	
		end
	end
	--print("astart "..astart)
	--print("aend "..aend)
	for i = astart, aend do
		displayLine(i)
	end
end

-- ************************************************************************************************************************

WCClient.addSyncRectangle = function(block, side, color, name)
	local offOn = getOffOn(block, side, color)
	local object = WCClient.GUI.object(2, 2, 1, 1)
	object.switch = {}
	object.switch.setState = function(self, state) offOn = state; end
	object.draw = function(object)
		if offOn == true then
			buffer.drawRectangle(object.x, object.y, object.width, object.height, 0x33FF80, 0x0, " ")
		else
			buffer.drawRectangle(object.x, object.y, object.width, object.height, 0x333330, 0x0, " ")
		end
	end
	listenToWire(object, name, block, side, color)
	return object
end

-- ************************************************************************************************************************

applyChangesOrderAction = function(orderName, action, offOn)
	for k, v in pairs (listenData.orders.windows) do
		if listenData.orders.windows[k][orderName] ~= nil and listenData.orders.windows[k][orderName][action] ~= nil then
			listenData.orders.windows[k][orderName][action].switch:setState(offOn)
			WCClient.application:draw()
		end
	end
end

switchValueOrder = function(aOrderName, action, offOn)
	if action == "offOn" then
		modem.send(srvAddress, port, "EOrder", aOrderName, action, offOn)
		d.p("switchValueOrder "..aOrderName.." "..action..tostring(offOn).." sent")
	end
end

listenToOrder = function(control, windowName, orderName, action)
	if listenData.orders.windows[windowName] == nil then listenData.orders.windows[windowName] = {}; end
	if listenData.orders.windows[windowName][orderName] == nil then listenData.orders.windows[windowName][orderName] = {}; end
	if listenData.orders.windows[windowName][orderName][action] == nil then listenData.orders.windows[windowName][orderName][action] = control; end
	d.p("listenToOrder "..windowName.." "..orderName.." "..action)
	return control
end

WCClient.addSyncSwitchOrderNoLabel = function(windowName, action, aOrderName)
	local offOn = WCClient.dataOrders[aOrderName][action]
    local switch = WCClient.GUI.switch(1, 1, 10, 0x66DB80, 0x1D1D1D, 0xEEEEEE, offOn)
    switch.onStateChanged = function() switchValueOrder(aOrderName, action, switch.state); switch.onStateChanged2() end
	switch.onStateChanged2 = function() end
	listenToOrder(switch, windowName, aOrderName, action)
	return switch
end

WCClient.addSyncSwitchOrder = function(windowName, action, aOrderName, text)
	local offOn = WCClient.dataOrders[aOrderName][action]
    local switchAndLabel = WCClient.GUI.switchAndLabel(1, 1, 36, 8, 0x66DB80, 0x1D1D1D, 0xEEEEEE, 0x999999, "        "..text, offOn)
    switchAndLabel.switch.onStateChanged = function() switchValueOrder(aOrderName, action, switchAndLabel.switch.state); switchAndLabel.switch.onStateChanged2() end
	switchAndLabel.switch.onStateChanged2 = function() end
	listenToOrder(switchAndLabel, windowName, aOrderName, action)
	return switchAndLabel
end	

-- ************************************************************************************************************************

applyChanges = function(block, side, origValue, newValue, color)
	d.p("entering apply changes")
	local offOn; local charge
	d.p("value of original block data: "..WCClient.data[block][side])
	if newValue == 0 then 
		offOn = false
		WCClient.data[block][side] = bit32.band(WCClient.data[block][side], 65535 - 2^color)
	else 
		offOn = true
		WCClient.data[block][side] = bit32.bor(WCClient.data[block][side], 2^color)
	end
	d.p("value of new block data: "..WCClient.data[block][side])
	for k, v in pairs (listenData.windows) do
		d.p("inside applyChanges loop")
		if listenData.windows[k][block] ~= nil and listenData.windows[k][block][side] ~= nil 
				and listenData.windows[k][block][side][color] ~= nil then
			d.p("record found tostring(side) "..tostring(side).." tostring(color) "..tostring(color).." offOn: "..tostring(offOn))
			--check type for different control types
			listenData.windows[k][block][side][color].switch:setState(offOn)
			WCClient.application:draw()
			--d.p("end loop")
		end
	end
end

swithValue = function(block, side, color)
	modem.send(srvAddress, port, "TSignal", block, side, color)
end

listenToWire = function(control, windowsName, block, side, color)
	d.p("listen to wire params: "..windowsName.." "..block.." "..side.." "..color)
	if listenData.windows[windowsName] == nil then listenData.windows[windowsName] = {}; end
	if listenData.windows[windowsName][block] == nil then listenData.windows[windowsName][block] = {}; end
	if listenData.windows[windowsName][block][side] == nil then listenData.windows[windowsName][block][side] = {}; end	
	listenData.windows[windowsName][block][side][color] = control
	return control
end

WCClient.addSyncSwitchNoLabel = function(block, side, color, name)
	local offOn = getOffOn(block, side, color)
    local switch = WCClient.GUI.switch(1, 1, 10, 0x66DB80, 0x1D1D1D, 0xEEEEEE, offOn)--0x999999, 
    --local switch = WCClient.GUI.switch(1, 1, 10, 0x2B6FAB, 0x1D1D1D, 0xEEEEEE, offOn)
     --local switch = WCClient.GUI.switch(1, 1, 10, 0x663380, 0x15151D, 0x22EE22, offOn)--0x999999, 
    switch.onStateChanged = function() swithValue(block, side, color) end
	listenToWire(switch, name, block, side, color)
	return switch
end

WCClient.addSyncSwitch = function(block, side, color, text, name)
	local offOn = getOffOn(block, side, color)
    local switchAndLabel = WCClient.GUI.switchAndLabel(2, 2, 25, 8, 0x66DB80, 0x1D1D1D, 0xEEEEEE, 0x999999, text, offOn)
    switchAndLabel.switch.onStateChanged = function() swithValue(block, side, color) end
	listenToWire(switchAndLabel, name, block, side, color)
	return switchAndLabel
end	

-- ************************************************************************************************************************

WCClient.stopListeningToWindowVars = function(windowsName)
	listenData.vars.windows[windowsName] = nil
	d.p("stopListeningToWindowVars "..windowsName.." done")
end

stopListeningToVar = function(windowsName, varName)
	--not tested -- need removing tostring probably
	listenData.vars.windows[windowsName][varName] = nil
	d.p("stopListeningToVar "..windowsName.." "..varName.." done")
end

applyChangesVar = function(varName, value)
	d.p("applyChangesVar "..varName.." "..tostring(value).." done")
	
	--d.p(d.dmp(listenData.vars.windows))
	
	for k, v in pairs (listenData.vars.windows) do
	d.p("cucou")
		if listenData.vars.windows[k][varName] ~= nil then
		
		d.p("found")
		
			listenData.vars.windows[k][varName].switch:setState(value)
			WCClient.application:draw()
		end
	end
end

listenToVar = function(control, windowName, varName)
	if listenData.vars.windows[windowName] == nil then listenData.vars.windows[windowName] = {}; end
	if listenData.vars.windows[windowName][varName] == nil then listenData.vars.windows[windowName][varName] = control; end
	d.p("listenToVar "..windowName.." "..varName)
	return control
end

-- ************************************************************************************************************************

WCClient.addSynchVarTxtButton = function(windowName, varName, control)
	local btn = WCClient.GUI.button(1, 1, 5, 1, 0xFFEFFF, 0x555555, 0x880000, 0xFFFFFF, "Upd")
	btn.onTouch = function() WCClient.updateVarValue(varName, control.getValue()) end
	return btn
end

WCClient.addSynchVarEditable = function(windowName, varName)
	local object-- = {}
	local varType = WCClient.dataVarsList[varName]["type"]
	local value = WCClient.dataVarsList[varName]["value"]
	if varType == "String" or varType == "Number" then
		object = WCClient.GUI.input(1, 1, 16, 1, 0xEEEEEE, 0x555555, 0x999999, 0xFFFFFF, 0x2D2D2D, "", value)
		object.switch = {}
		object.switch.setState = function(self, value) object.text = value end
	else
		object = WCClient.GUI.comboBox(1, 1, 16, 1, 0xEEEEEE, 0x2D2D2D, 0xCCCCCC, 0x888888)

		local i = 1; local selected = 1
		
		if WCClient.dataVarsList[varName]["type"] == "Order" then
			for k, v in pairs (WCClient.dataOrders) do 
				object:addItem(k)
				if k == WCClient.dataVarsList[varName].value then selected = i end
				i = i + 1
			end
			object.selectedItem = selected
		elseif WCClient.dataVarsList[varName]["type"] == "Alias" then
			local aliases = {}
			aliasNode.getAllAliases(WCClient.dataAliases, aliases)
			for k, v in pairs (aliases) do 
				object:addItem(v)
				if v == WCClient.dataVarsList[varName].value then selected = i end
				i = i + 1
			end
			object.selectedItem = selected
		elseif WCClient.dataVarsList[varName]["type"] == "Boolean" then
			object:addItem("false")
			object:addItem("true")
			if WCClient.dataVarsList[varName].value == true then object.selectedItem = 2 else object.selectedItem = 1 end	
		end		
			
		object.switch = {}
		object.switch.setState = function(self, value) 
			local ii = 1
			local iSelected = 1
			if WCClient.dataVarsList[varName]["type"] == "Order" then
				for k, v in pairs (WCClient.dataOrders) do 
					if k == WCClient.dataVarsList[varName].value then iSelected = ii end
					ii = ii + 1
				end
				object.selectedItem = iSelected
				--draw?
			elseif WCClient.dataVarsList[varName]["type"] == "Alias" then
				local aliases = {}
				aliasNode.getAllAliases(WCClient.dataAliases, aliases)
				for k, v in pairs (aliases) do 
					if v == WCClient.dataVarsList[varName].value then iSelected = ii end
					ii = ii + 1
				end
				object.selectedItem = iSelected
			elseif WCClient.dataVarsList[varName]["type"] == "Boolean" then
				if value == true then object.selectedItem = 2 else object.selectedItem = 1 end	
			end
		end
	end
	object.getValue = function(self)
		if varType == "String" or varType == "Number" then
			return object.text
		elseif varType == "Boolean" then
		
			--d.p("object.selectedITem: "..self.selectedItem)
		
			if object.selectedItem == 2 then return true else return false end
		else
			return object:getItem(object.selectedItem).text
		end
	end
	listenToVar(object, windowName, varName)
	return object
end

WCClient.addSynchVarTxt = function(windowName, varName)
	local value = WCClient.dataVarsList[varName].value
	local txtField = WCClient.GUI.text(1, 1, 0xFFFFFF, tostring(value))
	txtField.switch = {}
	txtField.switch.setState = function(self, value) txtField.text = tostring(value) end
	listenToVar(txtField, windowName, varName)
	return txtField
end

-- ************************************************************************************************************************

WCClient.insertCustomMenu = function(name)
	settings.windows[name] = {};settings.windows[name].opened = false; settings.windows[name].lockable = false; settings.windows[name].control = ""
	customApplis = loadJsonData("/home/wincraft/client/applications/dataApplis.json", json)
	table.remove(menu.children, 4)
	local contextMenu3 = menu:addContextMenu("Custom")
	for k, v in pairs (customApplis) do	
		contextMenu3:addItem(v.name).onTouch = function() openWindow(v.name) end
	end
	customApplis = nil
end

WCClient.updateCustomMenu = function(oldName, newName)
	if oldName == newName then return end
	customApplis = loadJsonData("/home/wincraft/client/applications/dataApplis.json", json)
	settings.windows[oldName] = nil
	settings.windows[newName] = {};settings.windows[newName].opened = false; settings.windows[newName].lockable = false; settings.windows[newName].control = ""
	table.remove(menu.children, 4)
	local contextMenu3 = menu:addContextMenu("Custom")
	for k, v in pairs (customApplis) do	
		contextMenu3:addItem(v.name).onTouch = function() openWindow(v.name) end
	end
	customApplis = nil
end

WCClient.deleteCustomMenu = function(name)
	settings.windows[name] = nil
	customApplis = loadJsonData("/home/wincraft/client/applications/dataApplis.json", json)
	table.remove(menu.children, 4)
	local contextMenu3 = menu:addContextMenu("Custom")
	for k, v in pairs (customApplis) do	
		contextMenu3:addItem(v.name).onTouch = function() openWindow(v.name) end
	end
	customApplis = nil
end

local display = function()
	WCClient.application = WCClient.GUI.application()
	WCClient.application:addChild(WCClient.GUI.panel(1, 1, WCClient.application.width, WCClient.application.height, 0x2D2D2D))
	menu = WCClient.application:addChild(WCClient.GUI.menu(1, 1, WCClient.application.width, 0xEEEEEE, 0x666666, 0x3366CC, 0xFFFFFF))
	local contextMenu = menu:addContextMenu("File")
		contextMenu:addItem("Exit").onTouch = function()
			term = require "term"; term.clear(); WCClient.application:stop(); os.exit(); 
	end
	local contextMenu2 = menu:addContextMenu("Application")
	
	--local tkeys = {}
	--for k in pairs(settings.windows) do table.insert(tkeys, k) end
	--table.sort(tkeys)
	--table.sort(settings.windows, function(a,b) return a.order < b.order end)
	local sorted = {}
	for k, v in pairs(settings.windows) do
	    table.insert(sorted,{k,v})
	end
	table.sort(sorted, function(a,b) return a[2].order < b[2].order end)
	
	for k, v in ipairs(sorted) do
	    contextMenu2:addItem(v[1]).onTouch = function() openWindow(v[1]) end
	    d.p("added window: "..k)
	end
	
--	for k, v in ipairs (settings.windows) do
--	for k, v in pairs (settings.windows) do	
		--contextMenu2:addItem(k).onTouch = function() openWindow(k) end
--		d.p("added window: "..k)
--	end
	
	local contextMenu3 = menu:addContextMenu("Locks")
	contextMenu3:addItem("Unlock OrdersModif Window").onTouch = function() WCClient.lockWindow("OrdersModif", false) end

	local contextMenu4 = menu:addContextMenu("Custom")
	for k, v in pairs (customApplis) do	
		contextMenu4:addItem(v.name).onTouch = function() openWindow(v.name) end
		settings.windows[v.name] = {};settings.windows[v.name].opened = false; settings.windows[v.name].lockable = false; settings.windows[v.name].control = ""
		d.p("added custom window: "..v.name)
	end
	customApplis = nil
	
	WCClient.application:draw(true)
	WCClient.application:start()
end

local mainLoop = function()
	thread.create(function()
		local offOn
		while true do
			--eventType,dest,src,aport,strength,order, block, side, origValue, newValue, color
			p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11 = nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil
			p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11 = event.pullMultiple("modem_message", "redstone_changed")
			d.p(d.okv(p1).." "..d.okv(p2).." "..d.okv(p3).." "..d.okv(p4).." "..d.okv(p5).." "..d.okv(p6).." "..d.okv(p7).." "..d.okv(p8).." "..d.okv(p9).." "..d.okv(p10).." "..d.okv(p11))
			local eventType = p1;
			if eventType == "modem_message" then
				d.p("modem message received")
				local dest = p2; local src = p3; local aport = p4; local strength = p5; local order = p6 
				if order == "remote_redstone_changed" then
					d.p("remote_redstone_changed received")
					--local block = p7; local side = tostring(p8); local origValue = p9; local newValue = p10; local color = tostring(p11)
					local block = p7; local side = p8; local origValue = p9; local newValue = p10; local color = p11
					
					if origValue == "" then origValue = 0 end---
					if newValue == "" then newValue = 0 end---
					if side == "" then side = 0 end---
					if color == "" then color = 0 end---
					if newValue == 0 then offOn = false else offOn = true end
					
					applyChanges(block, side, origValue, newValue, color)
					d.p("remote_redstone_changed --applyChanges done")
				elseif order == "remote_var_val_changed" then
					--p7 varName - p8 value
					WCClient.dataVarsList[p7].value = p8
					
					d.p("remote_var_val_changed")
					applyChangesVar(p7, p8)

				elseif order == "remote_var_changed" then
					d.p("remote_var_changed")
				
					local action = p7;
					if action == "ins" then
						d.p("ins")
						local parentVar = p8
						local varName = p9; 
						local actualVar = p10
						local parentNode = aliasNode.getDataNode(WCClient.dataVars, parentVar)
						local decodedVar = json.decode(actualVar)
						table.insert(parentNode.children, decodedVar)
						WCClient.dataVarsList[varName] = actualVar
					elseif action == "upd" then
						d.p("upd")
						local oldVarName = p8; 
						local newVarName = p9; local actualVar = p10
						local parentNode = aliasNode.getParentDataNode(WCClient.dataVars, oldVarName)
						local i
						for k, v in ipairs(parentNode.children) do
							if v.name == oldVarName then	i = k;	break end
						end
						table.remove(parentNode.children, i)
						table.insert(parentNode.children, i, json.decode(actualVar))
						
						WCClient.dataVarsList[oldVarName] = nil
						WCClient.dataVarsList[newVarName] = json.decode(actualVar)
						
						d.p("coucou")
						d.p(d.dmp(WCClient.dataVars))
						d.p(d.dmp(WCClient.dataVarsList))
						
						
						
					elseif action == "del" then
						d.p("del")
						local varName = p8; 
						local parentNode = aliasNode.getParentDataNode(WCClient.dataVars, varName)
						for k, v in ipairs(parentNode.children) do
							if v.name == varName then table.remove(parentNode.children, k); break	end
						end
						WCClient.dataVarsList[varName] = nil
					elseif action == "updown" then
						d.p("updown")
						local parentVarName = p8
						local index = p9
						local upDown = p10
						local parentVar = aliasNode.getDataNode(WCClient.dataVars, parentVarName)
						if upDown then
							local selectedVar = parentVar.children[index]
							table.remove(parentVar.children, index)
							table.insert(parentVar.children, index + 1, selectedVar)
						else
							local varToBeSwapped = parentVar.children[index - 1]
							table.remove(parentVar.children, index - 1)
							table.insert(parentVar.children, index, varToBeSwapped)
						end
					end
					applyChangesVarsList()
					d.p("remote_var_changed --applyChangesVarList done")
					
					--varName, value
				elseif order == "remote_order_changed" then
					d.p("remote_order_changed")
					local action = p7; local orderName = p8; 
					if action == "ins" and src ~= modem.address then
						d.p("ins")
						local actualOrder = p9
						--local json = require "json"
						WCClient.dataOrders[orderName] = json.decode(actualOrder)
						--package.loaded.json = nil
					elseif action == "upd" and src ~= modem.address then
						d.p("upd")
						local newOrderName = p9; local actualOrder = p10
						--local json = require "json"
						WCClient.dataOrders[newOrderName] = json.decode(actualOrder)
						if newOrderName ~= orderName then
							WCClient.dataOrders[orderName] = nil
						end
						--package.loaded.json = nil
					elseif action == "del" and src ~= modem.address then
						d.p("del")
						WCClient.dataOrders[orderName] = nil
					end
					applyChangesOrdersList()
					d.p("remote_order_changed --applyChangesOrdersList done")
				elseif order == "remote_alias_changed" then	
					d.p("remote_alias_changed")
					local action = p7;
					if action == "ins" then
						d.p("ins")
						local parentAlias = p8
						local aliasName = p9; 
						local actualAlias = p10
						local parentNode = aliasNode.getDataNode(WCClient.dataAliases, parentAlias)
						local decodedAlias = json.decode(actualAlias)
						table.insert(parentNode.children, decodedAlias)
					elseif action == "upd" then
						d.p("upd")
						local oldAliasName = p8; 
						local newAliasName = p9; local actualAlias = p10
						local parentNode = aliasNode.getParentDataNode(WCClient.dataAliases, oldAliasName)
						local i
						for k, v in ipairs(parentNode.children) do
							if v.name == oldAliasName then	i = k;	break end
						end
						table.remove(parentNode.children, i)
						table.insert(parentNode.children, i, json.decode(actualAlias))
					elseif action == "del" then
						d.p("del")
						local aliasName = p8; 
						local parentNode = aliasNode.getParentDataNode(WCClient.dataAliases, aliasName)
						for k, v in ipairs(parentNode.children) do
							if v.name == aliasName then table.remove(parentNode.children, k); break	end
						end
					elseif action == "updown" then
						d.p("updown")
						local parentAliasName = p8
						local index = p9
						local upDown = p10
						local parentAlias = aliasNode.getDataNode(WCClient.dataAliases, parentAliasName)
						if upDown then
							local selectedAlias = parentAlias.children[index]
							table.remove(parentAlias.children, index)
							table.insert(parentAlias.children, index + 1, selectedAlias)
						else
							local aliasToBeSwapped = parentAlias.children[index - 1]
							table.remove(parentAlias.children, index - 1)
							table.insert(parentAlias.children, index, aliasToBeSwapped)
						end
					end
					applyChangesAliasesList()
					d.p("remote_alias_changed --applyChangesAliasesList done")
				elseif order == "remote_locked_changed"	then
					d.p("remote_locked_changed")
					local windowName = p7; local offOn = p8; 
					WCClient.dataWindowsLocked[windowName] = offOn
					if offOn == false and src ~= modem.address and settings.windows[windowName].opened == true then WCClient.closeWindow(windowName) end
					d.p("remote_locked_changed --done")
				elseif order == "remote_execute_order_changed"	then
					d.p("remote_execute_order_changed")
					local orderName = p7; local action = p8; local offOn = p9
					--WCClient.GUI.alert("fucking holy shit")
					applyChangesOrderAction(orderName, action, offOn)
					d.p("remote_execute_order_changed --applyChangesOrderAction done")
				end
			elseif eventType == "redstone_changed" then
				d.p("redstone message received")
				local block = p2; local side = p3; local origValue = p4; local newValue = p5; local color = p6
				d.p("not implemented yet")
			end
		end
	end)
end

local getWindowsLocked = function()
	serialization = require "serialization"
	modem.send(srvAddress, port, "GWinLock")
	while true do
		a1, a2, a3, a4, a5, order, srvData, a8, a9 = event.pull("modem_message")
		if order == "GWinLock" then 
			WCClient.dataWindowsLocked = serialization.unserialize(srvData)
			d.p(d.dmp(WCClient.dataWindowsLocked))
			break
		end
	end
end

local getServerDataOrders = function()
	serialization = require "serialization"
	modem.send(srvAddress, port, "GOrders")
	while true do
		a1, a2, a3, a4, a5, order, srvData, a8, a9 = event.pull("modem_message")
		if order == "GOrders" then 
			WCClient.dataOrders = serialization.unserialize(srvData)
			d.p(d.dmp(WCClient.data))
			break
		end
	end
end

local getServerVars = function()
	serialization = require "serialization"
	modem.send(srvAddress, port, "GVars")
	while true do
		a1, a2, a3, a4, a5, order, srvData, a8, a9 = event.pull("modem_message")
		if order == "GVars" then 
			WCClient.dataVars = serialization.unserialize(srvData)
			WCClient.dataVarsList = serialization.unserialize(a8)
			d.p(d.dmp(WCClient.dataVars))
			d.p(d.dmp(WCClient.dataVarsList))
			--need some variables setted to nil
			break
		end
	end
end

local getServerAliases = function()
	serialization = require "serialization"
	modem.send(srvAddress, port, "GAliases")
	while true do
		a1, a2, a3, a4, a5, order, srvData, a8, a9 = event.pull("modem_message")
		if order == "GAliases" then 
			WCClient.dataAliases = serialization.unserialize(srvData)
			d.p(d.dmp(WCClient.dataAliases))
			break
		end
	end
end

local getServerData = function()
	serialization = require "serialization"
	modem.send(srvAddress, port, "GRefresh")
	while true do
		a1, a2, a3, a4, a5, order, srvData, a8, a9 = event.pull("modem_message")
		if order == "GRefresh" then 
			WCClient.data = serialization.unserialize(srvData)
			d.p(d.dmp(WCClient.data))
			break
		end
	end
end

local connect = function()
	modem = require("component").modem
	modem.open(port)
	d.p("modem opening was: "..(modem.isOpen(port) and 'true' or 'false'))
	modem.broadcast(port, "GServerAddress")
	while true do
		_, _, _, _, _, order, srvAddress = event.pull("modem_message")
		if order == "GServerAddress" then d.p("received server address"); break end
	end
end

local loadConfig = function()
	settings = loadJsonData("/home/wincraft/client/"..settingFile, json)
	if settings.debug then d.setLogOn(true) end
	customApplis = loadJsonData("/home/wincraft/client/applications/dataApplis.json", json)
	port = settings.port
end

local start = function()
	os.sleep(1)
	d.p("* start")
	loadConfig()
	d.p("* config loaded")
	connect()
	d.p("* connected to server")
	getServerData()
	d.p("* Server data received")
	getServerDataOrders()
	d.p("* Server dataOrders received")
	getServerAliases()
	d.p("* Server aliases received")
	getServerVars()
	d.p("* Server vars received")
	getWindowsLocked()
	d.p("* Server dataWindowsLocked received")
	mainLoop()
	d.p("* main loop launched")
	display()
	d.p("* display launched")
end

start()

return WCClient