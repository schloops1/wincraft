local WCServer = {}
local port

local event = require("event")
local co = require("component")
local mo = co.modem
local address = mo.address
local rs = co.redstone
local thread = require("thread")
local serialization = require "serialization"
package.loaded.dump = nil
local d = require "dump"
package.loaded.AliasNode = nil
local json = require "json"
local aliasNode = require "AliasNode"
local settings
local data = {}
local dataOrders = {}
local dataAliases = {}
local dataVariables = {}
local dataVariablesList = {}
local dataWindowsLocked = {}

local threads = {}

local saveBlocks = function(blocks)	d.dmpFile(blocks, "blocks.json") end

local loadJsonData = function(fileName)
	local f = io.open("./wincraft/server/"..fileName, "r")
	local data = json.decode(f:read("*all"))
	f:close()
	return data
end

local saveJsonData = function(fileName, data)
	local f=io.open("./wincraft/server/"..fileName,"w")
	f:write(json.encode(data))
	f:close()
end

local updateVariableFromSave = function(varName)
	local fs = require("filesystem")
	if fs.exists("/home/wincraft/server/variables/"..varName) then
		local f = io.open("./wincraft/server/variables/"..varName, "r")
		local data = f:read("*all")
		f:close()
		local aType = dataVariablesList[varName]["type"]
		if aType == "String" or aType == "Order" or aType == "Alias" then
			dataVariablesList[varName].value = data --tostring(data)
		elseif aType == "Number" then
			dataVariablesList[varName].value = tonumber(data)
		elseif aType == "Boolean" then
			if data == "true" then
				dataVariablesList[varName].value = true
			else
				dataVariablesList[varName].value = false
			end
		end
		fs.remove("/home/wincraft/server/variables/"..varName)
	end
end

local loadVariables = function()
	local fs = require("filesystem")
	dataVariables = loadJsonData("dataVariables.json")
	dataVariablesList = loadJsonData("dataVariablesList.json")

	--for fileName in fs.list("/home/wincraft/server/variables") do
	--	local f = io.open("./wincraft/server/variables/"..fileName, "r")  	
	--  	dataVariablesList[fileName].value = f:read("*all") --json.decode(f:read("*all") )
	--  	f:close()
	--end
	for k, _ in pairs (dataVariablesList) do
		updateVariableFromSave(k)
	end
end

--local loadVariable = function(fileName)
--	local f = io.open("./wincraft/server/variables/"..fileName, "r")
--	local data = f:read("*all")
--	f:close()
--	return data
--end

local saveVariable = function(fileName, data)
	local f=io.open("./wincraft/server/variables/"..fileName,"w")
	f:write(tostring(data))
	f:close()
end

--local saveVariables = function()
--	local f=io.open("./wincraft/server/variables/dataVariables.json","w")
--	f:write(json.encode(dataVariables))
--	f:close()
	
--	f=io.open("./wincraft/server/variables/dataVariablesList.json","w")
--	f:write(json.encode(dataVariablesList))
--	f:close()
--end

--local saveVariable = function(fileName)
--	local f=io.open("./wincraft/server/variables/"..fileName..".json","w")
--	f:write(json.encode(dataVariablesList[fileName]).value)
--	f:close()
--end

local saveOrder = function(fileName, data)
	local f = io.open("./wincraft/server/orders/"..fileName..".lua","w")
	f:write(data)
	f:close()
end

local removeOrder = function(fileName)
	local fs = require "filesystem"; fs.remove("/home/wincraft/server/orders/"..fileName..".lua")
end

WCServer.setBundledOutput = function(block, side, color, charge)
	block.setBundledOutput(side, color, charge)
	if settings.higherThan_1_7_10 == false then
		event.push("redstone_changed", block.address, side, charge, charge, color)
	end
end

local fetchData = function()
	--saveBlocks(co.list("redstone"))
	dataAliases = loadJsonData("dataAliases.json")
	dataOrders = loadJsonData("dataOrders.json")	
	dataWindowsLocked = loadJsonData("dataWindowsLocked.json")
	loadVariables()

	for k, v in pairs (dataOrders) do v.offOn = false end
	
	local block; local offOn; local binairyValue
	data = {}
	for key,value in pairs(co.list("redstone")) do 
		block = co.proxy(key)
		if block.getInput ~= nil then
			data[key] = {}
			for side = 0,5 do 
				binairyValue = 0
				for color = 0, 15 do
					if block.getBundledOutput(side, color) > 0 then offOn = 1 else offOn = 0 end
					binairyValue = binairyValue + offOn * 2^color
				end
				data[key][side] = binairyValue
			end
		end
	end
	
	return data
end

local makeAlias = function()
	local alias = {}

end

local gWindowsLocked = function(eventType,dest,src,aport)
	mo.send(src, port, "GWinLock", serialization.serialize(dataWindowsLocked))
end

local gServerVars = function(_, _, src)
	mo.send(src, port, "GVars", serialization.serialize(dataVariables), serialization.serialize(dataVariablesList))
end

local gOrders = function(eventType,dest,src,aport)
	mo.send(src, port, "GOrders", serialization.serialize(dataOrders))
end

local gServerAliases = function(_, _, src)
	mo.send(src, port, "GAliases", serialization.serialize(dataAliases))
end

local gServerRefresh = function(_, _, src)
	mo.send(src, port, "GRefresh", serialization.serialize(data))
end

local gServerRedBlocks = function(eventType,dest,src,aport)
	mo.send(src, port, "GServerRedBlocks", serialization.serialize(co.list("redstone")))
end

local gServerAddress = function(_, _, addressInNeed)
	mo.send(addressInNeed, port, "GServerAddress", mo.address)
end

local tSignal = function(eventType,dest,src,aport,strength,order, block, side, color)
	local charge
	rs = co.proxy(block)
	if rs.getBundledOutput(side, color) == 0 then
		charge = 255
	else charge = 0 end
	--rs.setBundledOutput(side, color, charge)
	WCServer.setBundledOutput(rs, side, color, charge)
end

local sSignalTime = function(eventType,dest,src,aport,strength,order, block, side, color, offOn, time)
	thread.create(function(eventType,dest,src,aport,strength,order, block, side, color, offOn, time)
		WCServer.sSignal(eventType,dest,src,port,strength,order, block, side, color, offOn)
		os.sleep(time)
		WCServer.sSignal(eventType,dest,src,port,strength,order, block, side, color, not offOn)
	end, eventType,dest,src,port,strength,order, block, side, color, offOn, time)
end

local sSignal = function(eventType,dest,src,aport,strength,order, block, side, color, offOn)
	if offOn == false then charge = 0 else charge = 255	end
	rs = co.proxy(block)
	--rs.setBundledOutput(side, color, charge)
	WCServer.setBundledOutput(rs, side, color, charge)
end

local gSignal = function(eventType,dest,src,aport,strength,order, block, side, color, offOn)
	rs = co.proxy(block)
	mo.send(src, port, rs.getBundledOutput(side, color))
end

local saveOrderExecFile = function(orderName)
	local i = "local "..orderName.." = {} local WCServer function "..orderName..":set() WCServer = self end "
	local o = orderName..".run = function() local co = require 'component'; local os = require 'os'; local thread = require 'thread';	local event = require 'event'; "
	o = o.."return thread.create(function() "
	local f = " "
	local ff = " "..orderName..".finalize = function() local co = require 'component'; local os = require 'os'; local thread = require 'thread'; "
	ff = ff.."return thread.create(function() "
	if dataOrders[orderName]["repeat"] ~= "0" then o = o.." for i=0, "..dataOrders[orderName]["repeat"].." do " end
	for k, v in pairs (dataOrders[orderName].orders) do
		if v["type"] == "output" then
			--o = o.."co.proxy('"..v.block.."').setBundledOutput("..v.side..", "..v.color..", "..v.force.."); "
			o = o.."WCServer.setBundledOutput(co.proxy('"..v.block.."'),"..v.side..", "..v.color..", "..v.force.."); "
			
		elseif v["type"] == "cleanOut" then	
			--f = f.."co.proxy('"..v.block.."').setBundledOutput("..v.side..", "..v.color..", "..v.force.."); "
			f = f.."WCServer.setBundledOutput(co.proxy('"..v.block.."'),"..v.side..", "..v.color..", "..v.force.."); "
			
		elseif v["type"] == "wait" then
			o = o.."os.sleep("..v["time"].."); "
		elseif v["type"] == "cleanW" then	
			f = f.."os.sleep("..v["time"].."); "
		elseif v["type"] == "input" then
			o = o.." while true do "
			o = o.."  eventType,block,side,origValue,newValue,color = event.pull(); "
			o = o.."  if eventType == 'redstone_changed' then "
			o = o.."   if block == '"..v.block.."' and side == "..v.side.." and color == "..v.color.." and newValue > "..v.force.." then break end "
			o = o.."  end "
			o = o.." end "
		elseif v["type"] == "execOrder" then
			o = o.." WCServer.eOrder(_, _, _, _, _, _, '"..v.name.."', 'offOn', true); "
		elseif v["type"] == "killOrder" then
			o = o.." WCServer.eOrder(_, _, _, _, _, _, '"..v.name.."', 'offOn', false); "
		elseif v["type"] == "outAlias" then
			o = o.." WCServer.eAlias(_, _, _, _, _, _, '"..v.alias.."',"..v['force'].."); "	
		elseif v["type"] == "cleanOAl" then
			f = f.." WCServer.execAlias('"..v.alias.."',"..v['force'].."); "		
		end
	end
	if dataOrders[orderName]["repeat"] ~= "0" then o = o.." end " end
	ff = ff..f.."end) end "
	o = o..f
	o = o.." os.sleep(1); WCServer.threadEnded('"..orderName.."') end) end " 
	
	saveOrder(orderName, i..ff..o.."return "..orderName)
end

local function openCloseDoor(node, open)
	local red = co.proxy(node.block)
	if red.getBundledOutput(node.side, node.color) == 255 then 
		--red.setBundledOutput(node.side, node.color, 0) 
		WCServer.setBundledOutput(red, node.side, node.color, 0)
		if open then 
			--red.setBundledOutput(node.side, node.color, 255)
			WCServer.setBundledOutput(red, node.side, node.color, 255)
		end
	else
		WCServer.setBundledOutput(red, node.side, node.color, 255)
		--red.setBundledOutput(node.side, node.color, 255)
		if not open then 
			--red.setBundledOutput(node.side, node.color, 0) 
			WCServer.setBundledOutput(red, node.side, node.color, 0)
		end	
	end
end

WCServer.execAlias = function(name, charge)
	local alias = aliasNode.getDataNode(dataAliases, name)	
	if alias == nil then return end
	WCServer.execAliasNode(alias, charge)	
end

WCServer.execAliasNode = function(anode, charge)
	if anode.node then
		for _, node in ipairs(anode.children) do
			if node.node == true then
				local f = WCServer.execAliasNode(node, charge)
			else
				if node.door then
					openCloseDoor(node, charge > 0)
				else
					--co.proxy(node.block).setBundledOutput(node.side, node.color, charge)
					WCServer.setBundledOutput(co.proxy(node.block), node.side, node.color, charge)
				end
			end
		end
	else
		if anode.door then
			openCloseDoor(anode, charge > 0)
		else
			--co.proxy(anode.block).setBundledOutput(anode.side, anode.color, charge)
			WCServer.setBundledOutput(co.proxy(anode.block), anode.side, anode.color, charge)
		end
	end
end

WCServer.eAlias = function(eventType,dest,src,aport,strength,order, name, charge)
	local alias = aliasNode.getDataNode(dataAliases, name)	
	if alias == nil then return end
	local t = thread.create(function() return WCServer.execAliasNode(alias, charge) end)
end

local udAlias = function(eventType,dest,src,aport,strength,order, parentAliasName, index, upDown)
	--up (false) - down (true) alias
	local parentAlias = aliasNode.getDataNode(dataAliases, parentAliasName)
	if upDown then
		local selectedAlias = parentAlias.children[index]
		table.remove(parentAlias.children, index)
		table.insert(parentAlias.children, index + 1, selectedAlias)
	else
		local aliasToBeSwapped = parentAlias.children[index - 1]
		table.remove(parentAlias.children, index - 1)
		table.insert(parentAlias.children, index, aliasToBeSwapped)
	end
	saveJsonData("dataAliases.json", dataAliases)
	mo.broadcast(port, "remote_alias_changed", "updown", parentAliasName, index, upDown)
end

local uAlias = function(eventType,dest,src,aport,strength,order, oldAliasName, newAliasName, actualAlias)
	local parentNode = aliasNode.getParentDataNode(dataAliases, oldAliasName)
	local i
	for k, v in ipairs(parentNode.children) do
		if v.name == oldAliasName then i = k; break	end
	end
	table.remove(parentNode.children, i)
	table.insert(parentNode.children, i, json.decode(actualAlias))
	saveJsonData("dataAliases.json", dataAliases)
	mo.broadcast(port, "remote_alias_changed", "upd", oldAliasName, newAliasName, actualAlias)
end

local iAlias = function(eventType,dest,src,aport,strength,order, aliasParentName, aliasName, actualAlias)
	local aliasParent = aliasNode.getDataNode(dataAliases, aliasParentName)
	table.insert(aliasParent.children, json.decode(actualAlias))
	saveJsonData("dataAliases.json", dataAliases)
	mo.broadcast(port, "remote_alias_changed", "ins", aliasParentName, aliasName, actualAlias)---
end

local dAlias = function(eventType,dest,src,aport,strength,order, aliasName)
	local parent = aliasNode.getParentDataNode(dataAliases, aliasName)
	for k, v in ipairs(parent.children) do
		if v.name == aliasName then table.remove(parent.children, k); break end
	end
	saveJsonData("dataAliases.json", dataAliases)
	mo.broadcast(port, "remote_alias_changed", "del", aliasName)
end

local udVar = function(eventType,dest,src,aport,strength,order, parentVarName, index, upDown)
	--up (false) - down (true) var
	local parentVar = aliasNode.getDataNode(dataVariables, parentVarName)
	if upDown then
		local selectedVar = parentVar.children[index]
		table.remove(parentVar.children, index)
		table.insert(parentVar.children, index + 1, selectedVar)
	else
		local varToBeSwapped = parentVar.children[index - 1]
		table.remove(parentVar.children, index - 1)
		table.insert(parentVar.children, index, varToBeSwapped)
	end
	saveJsonData("dataVariables.json", dataVariables)
	mo.broadcast(port, "remote_var_changed", "updown", parentVarName, index, upDown)
end

local vVar = function(eventType,dest,src,aport,strength,order, varName, newValue)
	dataVariablesList[varName].value = newValue
	if dataVariablesList[varName].saveAlways == true then
		saveVariable(varName, newValue)
	end
	mo.broadcast(port, "remote_var_val_changed", varName, newValue)
end

local uVar = function(eventType,dest,src,aport,strength,order, oldVarName, newVarName, actualVar)
	local parentNode = aliasNode.getParentDataNode(dataVariables, oldVarName)
	local i
	for k, v in ipairs(parentNode.children) do
		if v.name == oldVarName then i = k; break end
	end
	table.remove(parentNode.children, i)
	table.insert(parentNode.children, i, json.decode(actualVar))
	saveJsonData("dataVariables.json", dataVariables)
	
	dataVariablesList[oldVarName] = nil
	dataVariablesList[newVarName] = json.decode(actualVar)
	saveJsonData("dataVariablesList.json", dataVariablesList)
	
	mo.broadcast(port, "remote_var_changed", "upd", oldVarName, newVarName, actualVar)
	
	vVar(_, _, _, _, _, _, newVarName, dataVariablesList[newVarName].value)
end

local iVar = function(eventType,dest,src,aport,strength,order, varParentName, varName, actualVar)
	local varParent = aliasNode.getDataNode(dataVariables, varParentName)

	table.insert(varParent.children, json.decode(actualVar))
	saveJsonData("dataVariables.json", dataVariables)
	
	dataVariablesList[varName] = json.decode(actualVar)
	saveJsonData("dataVariablesList.json", dataVariablesList)
	
	mo.broadcast(port, "remote_var_changed", "ins", varParentName, varName, actualVar)---
end

local dVar = function(eventType,dest,src,aport,strength,order, varName)
	local parent = aliasNode.getParentDataNode(dataVariables, varName)
	for k, v in ipairs(parent.children) do
		if v.name == varName then table.remove(parent.children, k); break end
	end
	saveJsonData("dataVariables.json", dataVariables)
	
	dataVariablesList[varName] = nil
	saveJsonData("dataVariablesList.json", dataVariablesList)
	
	mo.broadcast(port, "remote_var_changed", "del", varName)
end

local uOrder = function(eventType,dest,src,aport,strength,order, oldOrderName, newOrderName, actualOrder)
	dataOrders[newOrderName] = json.decode(actualOrder)
	if oldOrderName ~= newOrderName then dataOrders[oldOrderName] = nil	end
	saveJsonData("dataOrders.json", dataOrders)
	removeOrder(oldOrderName)
	saveOrderExecFile(newOrderName)
	package.loaded[newOrderName] = nil
	package.loaded[oldOrderName] = nil
	mo.broadcast(port, "remote_order_changed", "upd", oldOrderName, newOrderName, actualOrder)
end

local dOrder = function(eventType,dest,src,aport,strength,order, orderName)
	dataOrders[orderName] = nil
	saveJsonData("dataOrders.json", dataOrders)
	removeOrder(orderName)
	package.loaded[orderName] = nil
	mo.broadcast(port, "remote_order_changed", "del", orderName)
end

local iOrder = function(eventType,dest,src,aport,strength,order, orderName, actualOrder)
	dataOrders[orderName] = json.decode(actualOrder)
	saveJsonData("dataOrders.json", dataOrders)
	saveOrderExecFile(orderName)
	package.loaded[orderName] = nil
	mo.broadcast(port, "remote_order_changed", "ins", orderName, actualOrder)
end

local lWindow = function(eventType,dest,src,aport,strength,order, windowName, offOn)
	dataWindowsLocked[windowName] = offOn
	saveJsonData("dataWindowsLocked.json", dataWindowsLocked)
	mo.broadcast(port, "remote_locked_changed", windowName, offOn)
end

WCServer.eOrder = function(eventType,dest,src,aport,strength,order, orderName, action, offOn)
	dataOrders[orderName].offOn = offOn
	if action == "offOn" then
		if offOn == true then
			if threads[orderName] ~= nil then return end 
			local orderExec = require(orderName)
			orderExec.set(WCServer)
			threads[orderName] = orderExec.run()
		else
			if threads[orderName] ~= nil then 
				threads[orderName]:kill() 
				threads[orderName] = nil
				local order = require(orderName)
				order.finalize()
			end
			package.loaded[orderName] = nil
		end
	end
	mo.broadcast(port, "remote_execute_order_changed", orderName, action, offOn)
end

WCServer.threadEnded = function(orderName)
	dataOrders[orderName].offOn = false
	threads[orderName] = nil
	mo.broadcast(port, "remote_execute_order_changed", orderName, "offOn", false)
end

WCServer.start = function()
	os.sleep(1)
	
	settings = loadJsonData("settings.json")
	if settings.debug then d.setLogOn(true) end
	port = settings.port

	fetchData()
	mo.open(port)
	for k, v in pairs (dataOrders) do 
		mo.broadcast(port, "remote_execute_order_changed", k, "offOn", false)
	end
	print("Server port: "..port.." opened: "..(mo.isOpen(port) and 'true' or 'false').." -- press 't' to exit")
	local block, side, origValue, newValue, color
	local orders = {}
	orders["GVars"] = gServerVars
	orders["GAliases"] = gServerAliases
	orders["GServerAddress"] = gServerAddress
	orders["GRefresh"] = gServerRefresh
	orders["GSignal"] = gSignal
	orders["SSignal"] = sSignal
	orders["TSignal"] = tSignal
	orders["SSignalTime"] = sSignalTime
	orders["GServerRedBlocks"] = gServerRedBlocks
	orders["GOrders"] = gOrders
	orders["UOrder"] = uOrder
	orders["DOrder"] = dOrder
	orders["IOrder"] = iOrder
	orders["GWinLock"] = gWindowsLocked
	orders["LWindow"] = lWindow
	orders["EOrder"] = WCServer.eOrder
	orders["IAlias"] = iAlias
	orders["UAlias"] = uAlias
	orders["DAlias"] = dAlias
	orders["UDAlias"] = udAlias
	orders["IVar"] = iVar
	orders["UVar"] = uVar
	orders["DVar"] = dVar
	orders["UDVar"] = udVar
	orders["VVar"] = vVar
	
	orders["EAlias"] = WCServer.eAlias

	while true do
		eventType,dest,src,aport,strength,order, p7, p8, p9, p10, p11 = event.pull()
		if eventType ~= "key_up" and eventType ~= "key_down" and eventType ~= "touch" and eventType ~= "drop" then
			print(d.okv(eventType).." "..d.okv(src).." "..d.okv(aport).." "..d.okv(strength).." "..d.okv(order).." "..d.okv(p7).." "..d.okv(p8).." "..d.okv(p9).." "..d.okv(p10))
			--"modem_message", dest, src, port, signal, order, block, side, color
			--"redstone_changed", block, side, origValue, newValue, color
			if eventType == "modem_message" then
				orders[order](eventType,dest,src,aport,strength,order, p7, p8, p9, p10, p11)
			elseif eventType == "redstone_changed" then
				side = src; origValue = aport; newValue = strength; block = dest; color = order
			    if(newValue) > 0 then
			    	data[block][side] = bit32.bor(data[block][side], 2^color)
			    else	
			    	data[block][side] = bit32.band(data[block][side], 65535 - 2^color)
			    end
			    mo.broadcast(port, "remote_redstone_changed", block, side, origValue, newValue, color)
			end
		else
			--print(d.okv(eventType).." "..d.okv(src).." "..d.okv(aport).." "..d.okv(strength).." "..d.okv(order).." "..d.okv(p7).." "..d.okv(p8).." "..d.okv(p9).." "..d.okv(p10))
			if src == 116 then os.exit() end
		end
		p7, p8, p9, p10, p11 = nil, nil, nil, nil, nil
	end
end

return WCServer