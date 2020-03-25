local Orders = {}
 
local client
local name
 
function Orders:set(aname)
 	client = self; name = aname
end
  
local memory = {}
 
local layoutOrder
local amountOrders
 
displayOrderLine = function(key)
 	layoutOrder:addChild(memory[key])
end
 
local scrollSize = 16
 
displayOrders = function()
 	layoutOrder:removeChildren()
 	client.stopListeningToWindowOrders(name)
 	local i = 0	
 	memory = {}
 	
 	local tkeys = {}
	for k in pairs(client.dataOrders) do table.insert(tkeys, k) end
	table.sort(tkeys)
 	
 	for _, k in ipairs (tkeys) do
		local cont = client.GUI.container(1, 1, 36, 1) 
		memory[i] = cont:addChild(client.addSyncSwitchOrder(name, "offOn", k, k))
		i = i+1
 	end
 	amountOrders = i
 	client.scrollFromTo(0, amountOrders, scrollSize, layoutOrder, displayOrderLine)
 	client.application:draw()
end
 
Orders.display = function()
 	local window = client.application:addChild(client.GUI.titledWindow(50, 22, 36, 20, name, true))
 	window.actionButtons.close.onTouch = function() client.closeWindow(name) end
 
 	--local panelOrdersNames = window:addChild(client.GUI.panel(3, 3, 17, 16, 0xEEEEEE))
 	local panelOrders = window:addChild(client.GUI.panel(20, 2, 15, 18, 0x880000))
 	local panelOrders2 = window:addChild(client.GUI.panel(2, 2, 18, 1, 0x880000))
 	local panelOrders3 = window:addChild(client.GUI.panel(2, 3, 1, 17, 0x880000))
 	local panelOrders4 = window:addChild(client.GUI.panel(3, 19, 17, 1, 0x880000))
 	
 	local layout = window:addChild(client.GUI.layout(4, 3, 40, scrollSize, 2, 1))
 	layoutOrder = layout:addChild(client.GUI.layout(2, 2, 36, scrollSize, 1, 1))
 	layoutOrder:setSpacing(1,1,0)
 	layoutOrder.switch = {}; 
 	layoutOrder.switch.refresh = displayOrders
 	
 	displayOrders()
 	listenToOrdersList(layoutOrder, name)
 
 	local verticalScrollBar = layout:addChild(client.GUI.scrollBar(1, 1, 1, scrollSize, 0x444444, 0x888888, 1, 100, 1, 10, 1, true))
 	layout:setPosition(2, 1, verticalScrollBar)
 	verticalScrollBar.onTouch = function() client.scrollFromTo(verticalScrollBar.value, amountOrders, scrollSize, layoutOrder, displayOrderLine) end
 	
 	return window
end	
 	
return Orders