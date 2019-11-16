local WCClient = {}
package.loaded.GUI = nil
WCClient.GUI = require "GUI"
local thread = require "thread"
local event = require "event"
local bit32 = require "bit32"
local buffer = require("doubleBuffering")

WCClient.application = nil
local modem
local srvAddress
WCClient.data = {}
WCClient.dataOrders = {}
WCClient.dataAliases = {}
local listenData = {}
listenData.windows = {}
listenData.orders = {}
listenData.orders.windows = {}
listenData.ordersWindows = {}

WCClient.dataWindowsLocked = {}
local settings = {}

local port
local settingFile = "settings.json"

package.loaded.dump = nil
local d = require "dump"
d.newLog()

WCClient.lockWindow = function(windowName, offOn)
	modem.send(srvAddress, port, "LWindow", windowName, offOn)
end

WCClient.updateOrder = function(oldOrderName, newOrderName, order)
	local json = require "json"
	modem.send(srvAddress, port, "UOrder", oldOrderName, newOrderName, json.encode(order))
	package.loaded.json = nil
end

WCClient.deleteOrder = function(orderName)
	modem.send(srvAddress, port, "DOrder", orderName)
end

WCClient.insertOrder = function(orderName, order)
	local json = require "json"
	modem.send(srvAddress, port, "IOrder", orderName, json.encode(order))
	package.loaded.json = nil
end

swithValue = function(block, side, color)
	modem.send(srvAddress, port, "TSignal", block, side, color)
end

applyChanges = function(block, side, origValue, newValue, color)
	d.p("entering apply changes")
	local offOn; local charge
	d.p("value of original data: "..WCClient.data[block][side])
	if newValue == 0 then 
		offOn = false
		WCClient.data[block][side] = bit32.band(WCClient.data[block][side], 65535 - 2^color)
	else 
		offOn = true
		WCClient.data[block][side] = bit32.bor(WCClient.data[block][side], 2^color)
	end
	d.p("value of new data: "..WCClient.data[block][side])
	for k, v in pairs (listenData.windows) do
		d.p("inside applyChanges loop")
		if listenData.windows[k][block] ~= nil and listenData.windows[k][block][tostring(side)] ~= nil 
				and listenData.windows[k][block][tostring(side)][tostring(color)] ~= nil then
			d.p("record found"); d.p("tostring(side) "..tostring(side)); d.p("tostring(color) "..tostring(color)); d.p("offOn: "..tostring(offOn))
			--check type for different control types
			listenData.windows[k][block][tostring(side)][d.okv(color)].switch:setState(offOn)
			WCClient.application:draw()
			d.p("end loop")
		end
	end
end

stopListeningToOrdersList = function(windowName)
	listenData.ordersWindows[windowName] = nil
end

applyChangesOrdersList = function()
	for k, v in pairs (listenData.ordersWindows) do
		listenData.ordersWindows[k].switch.refresh()
	end
end

listenToOrdersList = function(control, windowName)
	listenData.ordersWindows[windowName] = control
	return control
end

listenToWire = function(control, windowsName, block, side, color)
	d.p("listen to wire params: "..windowsName.." "..block.." "..side.." "..color)
	if listenData.windows[windowsName] == nil then listenData.windows[windowsName] = {}; end
	if listenData.windows[windowsName][block] == nil then listenData.windows[windowsName][block] = {}; end
	if listenData.windows[windowsName][block][tostring(side)] == nil then listenData.windows[windowsName][block][tostring(side)] = {}; end
	d.p("ready to insert listen data")
	listenData.windows[windowsName][block][tostring(side)][d.okv(color)] = control
	d.p("control set")
	return control
end

WCClient.stopListeningToWindowWires = function(windowsName)
	listenData.windows[windowsName] = nil
end

stopListeningToWire = function(windowsName, block, side, color)
	--not tested
	listenData.windows[windowsName][block][tostring(side)][tostring(color)] = nil
end

WCClient.stopListeningToWindowOrders = function(windowName)
	listenData.orders.windows[windowName] = nil
end

WCClient.closeWindow = function(name)
	settings.windows[name].control:close()
	WCClient.stopListeningToWindowWires(name)
	WCClient.stopListeningToWindowOrders(name)
	stopListeningToOrdersList(name)
	settings.windows[name].control = nil
	settings.windows[name].opened = false
	WCClient.dataWindowsLocked[name] = false 
	if settings.windows[name].lockable == true then
		WCClient.lockWindow(name, false)
	end
	WCClient.application:draw()
end

openWindow = function(name)
    if settings.windows[name].opened == true then return 0 end
    if WCClient.dataWindowsLocked[name] ~= nil 
    	and WCClient.dataWindowsLocked[name] == true then 
    		--WCClient.GUI.alert("Window "..name.." is locked")
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
end

getOffOn = function(block, side, color)
	local charge = bit32.band(WCClient.data[block][tostring(side)], 2^color)
    local offOn = (charge > 0)
    return bit32.band(WCClient.data[block][tostring(side)], 2^color) > 0
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

WCClient.addSyncRectangle = function(block, side, color, name)
	local offOn = not getOffOn(block, side, color)
	local object = WCClient.GUI.object(2, 2, 1, 1)
	object.switch = {}
	object.switch.setState = function(self, state) offOn = state end
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

--here needs modification
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
	end
end

listenToOrder = function(control, windowName, orderName, action)
	if listenData.orders.windows[windowName] == nil then listenData.orders.windows[windowName] = {}; end
	if listenData.orders.windows[windowName][orderName] == nil then listenData.orders.windows[windowName][orderName] = {}; end
	if listenData.orders.windows[windowName][orderName][action] == nil then listenData.orders.windows[windowName][orderName][action] = control; end
	return control
end

WCClient.addSyncSwitchOrder = function(windowName, action, aOrderName, text)
	local offOn = WCClient.dataOrders[aOrderName][action]
    local switchAndLabel = WCClient.GUI.switchAndLabel(1, 1, 36, 8, 0x66DB80, 0x1D1D1D, 0xEEEEEE, 0x999999, "        "..text, offOn)
    switchAndLabel.switch.onStateChanged = function() switchValueOrder(aOrderName, action, switchAndLabel.switch.state); switchAndLabel.switch.onStateChanged2() end
	switchAndLabel.switch.onStateChanged2 = function() end
	listenToOrder(switchAndLabel, windowName, aOrderName, action)
	return switchAndLabel
end	

WCClient.addSyncSwitch = function(block, side, color, text, name)
	local offOn = getOffOn(block, side, color)
    local switchAndLabel = WCClient.GUI.switchAndLabel(2, 2, 25, 8, 0x66DB80, 0x1D1D1D, 0xEEEEEE, 0x999999, text, offOn)
    switchAndLabel.switch.onStateChanged = function() swithValue(block, side, color) end
	listenToWire(switchAndLabel, name, block, side, color)
	return switchAndLabel
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
	for k, v in pairs (settings.windows) do
		contextMenu2:addItem(k).onTouch = function() openWindow(k) end
		d.p("added window: "..k)
	end
	local contextMenu3 = menu:addContextMenu("Locks")
	contextMenu3:addItem("Unlock OrdersModif Window").onTouch = function() WCClient.lockWindow("OrdersModif", false) end
	
	WCClient.application:draw(true)
	WCClient.application:start()
end

local mainLoop = function()
	thread.create(function()
		local offOn
		while true do
			--eventType,dest,src,aport,strength,order, block, side, origValue, newValue, color
			p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11 = event.pullMultiple("modem_message", "redstone_changed")
			local eventType = p1;
			if eventType == "modem_message" then
				d.p("modem message received")
				local dest = p2; local src = p3; local aport = p4; local strength = p5; local order = p6 
				
				if order == "remote_redstone_changed" then
					local block = p7; local side = tostring(p8); local origValue = p9; local newValue = p10; local color = tostring(p11)
					d.p("remote_redstone_changed received")
					if newValue == 0 then offOn = false else offOn = true end
					applyChanges(block, side, origValue, newValue, color)
				elseif order == "remote_order_changed" then
					local action = p7; local orderName = p8; 
					if action == "ins" and src ~= modem.address then
						local actualOrder = p9
						local json = require "json"
						WCClient.dataOrders[orderName] = json.decode(actualOrder)
						package.loaded.json = nil
					elseif action == "upd" and src ~= modem.address then
						local newOrderName = p9; local actualOrder = p10
						local json = require "json"
						WCClient.dataOrders[newOrderName] = json.decode(actualOrder)
						if newOrderName ~= orderName then
							WCClient.dataOrders[orderName] = nil
						end
						package.loaded.json = nil
					elseif action == "del" and src ~= modem.address then
						WCClient.dataOrders[orderName] = nil
					end
					applyChangesOrdersList()
				elseif order == "remote_locked_changed"	then
					local windowName = p7; local offOn = p8; 
					WCClient.dataWindowsLocked[windowName] = offOn
					if offOn == false and src ~= modem.address and settings.windows[windowName].opened == true then WCClient.closeWindow(windowName) end
				elseif order == "remote_execute_order_changed"	then
					local orderName = p7; local action = p8; local offOn = p9
					applyChangesOrderAction(orderName, action, offOn)
				end
			elseif eventType == "redstone_changed" then
				d.p("redstone message received")
				local block = p2; local side = tostring(p3); local origValue = p4; local newValue = p5; local color = tostring(p6)
				
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
	local json = require("json")
	settings = json.decode(io.open("/home/wincraft/client/"..settingFile, "r"):read("*all"))
	json = nil; package.loaded.json = nil
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
	getWindowsLocked()
	d.p("* Server dataWindowsLocked received")
	mainLoop()
	d.p("* main loop launched")
	display()
	d.p("* display launched")
end

start()

return WCClient