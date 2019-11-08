local WCServer = {}
local port

local event = require("event")
local co = require("component")
local mo = co.modem
local address = mo.address
local rs = co.redstone
local thread = require("thread")
local serialization = require "serialization"
local d = require "dump"
d.newLog()
local data = {}
local dataOrders = {}
local dataBlockAliases = {}
local dataAliases = {}
local dataAliasesList = {}
local dataWindowsLocked = {}

local threads = {}

local saveBlocks = function(blocks)	d.dmpFile(blocks, "blocks.json") end

local loadJsonData = function(fileName, json)
	local f = io.open("./wincraft/server/"..fileName, "r")
	local data = json.decode(f:read("*all"))
	f:close()
	--io.close(f)
	return data
end

local saveJsonData = function(fileName, data)
	local f=io.open("./wincraft/server/"..fileName,"w")
	local json = require "json"
	f:write(json.encode(data))
	f:close()
	package.loaded.json = nil	
end

local saveOrder = function(fileName, data)
	local f = io.open("./wincraft/server/orders/"..fileName..".lua","w")
	f:write(data)
	f:close()
end

local removeOrder = function(fileName)
	local fs = require "filesystem"; fs.remove("/home/wincraft/server/orders/"..fileName..".lua")
end

local fetchData = function()
	local json = require "json"
	
	dataBlockAliases = loadJsonData("dataBlockAliases.json", json)
	dataAliases = loadJsonData("dataAliases.json", json)
	dataAliasesList = loadJsonData("dataAliasesList.json", json)
	dataOrders = loadJsonData("dataOrders.json", json)	
	dataWindowsLocked = loadJsonData("dataWindowsLocked.json", json)

	for k, v in pairs (dataOrders) do v.offOn = false end
	
	local block; local offOn; local binairyValue
	data = {}
	for key,value in pairs(co.list("redstone")) do 
		block = co.proxy(key)
		data[key] = {}
		for side = 0,5 do 
			binairyValue = 0
			for color = 0, 15 do
				if block.getBundledOutput(side, color) > 0 then offOn = 1 else offOn = 0 end
				binairyValue = binairyValue + offOn * 2^color
			end
			data[key][tostring(side)] = binairyValue
		end
	end
	--saveBlocks(co.list("redstone"))
	package.loaded.json = nil
	return data
end

local makeAlias = function()
	local alias = {}

end

--local saveOrders = function()
--	local file=io.open("./wincraft/".."dataOrders.json","w")
--	local json = require "json"
--	file:write(json.encode(dataOrders))
--	package.loaded.json = nil	
--	file:close()
--end

--local saveWindowsLocked = function()
--	local file=io.open("./wincraft/".."dataWindowsLocked.json","w")
--	local json = require "json"
--	file:write(json.encode(dataWindowsLocked))
--	package.loaded.json = nil	
--	file:close()
--end

local gWindowsLocked = function(eventType,dest,src,aport)
	mo.send(src, port, "GWinLock", serialization.serialize(dataWindowsLocked))
end

local gOrders = function(eventType,dest,src,aport)
	mo.send(src, port, "GOrders", serialization.serialize(dataOrders))
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
	if rs.getBundledOutput(tonumber(side), tonumber(color)) == 0 then
		charge = 255
	else charge = 0 end
	rs.setBundledOutput(tonumber(side), tonumber(color), charge)
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
	rs.setBundledOutput(tonumber(side), tonumber(color), charge)
end

local gSignal = function(eventType,dest,src,aport,strength,order, block, side, color, offOn)
	rs = co.proxy(block)
	mo.send(src, port, rs.getBundledOutput(tonumber(side), tonumber(color)))
end

local saveOrderExecFile = function(orderName)
	local i = "local "..orderName.." = {} local WCServer function "..orderName..":set() WCServer = self end "
	local o = orderName..".run = function() local co = require 'component'; local os = require 'os'; local thread = require 'thread';	local event = require 'event'; "
	o = o.."return thread.create(function() "
	local f = " "
	local ff = " "..orderName..".finalize = function() local co = require 'component'; local os = require 'os'; local thread = require 'thread'; "
	ff = ff.."return thread.create(function() "
	if dataOrders[orderName]["repeat"] ~= "0" then o = o.." for i=0, "..d.okv(dataOrders[orderName]["repeat"]).." do " end
	for k, v in pairs (dataOrders[orderName].orders) do
		if v["type"] == "output" then
			o = o.."co.proxy('"..v.block.."').setBundledOutput("..d.okv(v.side)..", "..d.okv(v.color)..", "..d.okv(v.force).."); "
		elseif v["type"] == "cleanOut" then	
			f = f.."co.proxy('"..v.block.."').setBundledOutput("..d.okv(v.side)..", "..d.okv(v.color)..", "..d.okv(v.force).."); "
		elseif v["type"] == "wait" then
			o = o.."os.sleep("..d.okv(v["time"]).."); "
		elseif v["type"] == "cleanW" then	
			f = f.."os.sleep("..d.okv(v["time"]).."); "
		elseif v["type"] == "input" then
			o = o.." while true do "
			o = o.."  eventType,block,side,origValue,newValue,color = event.pull(); "
			o = o.."  if eventType == 'redstone_changed' then "
			o = o.."   if block == '"..v.block.."' and side == "..d.okv(v.side).." and color == "..d.okv(v.color).." and newValue > "..d.okv(v.force).." then break end "
			o = o.."  end "
			o = o.." end "
		elseif v["type"] == "execOrder" then
			o = o.." WCServer.eOrder(_, _, _, _, _, _, '"..v.name.."', 'offOn', true); "
		elseif v["type"] == "killOrder" then
			o = o.." WCServer.eOrder(_, _, _, _, _, _, '"..v.name.."', 'offOn', false); "
		end
	end
	if dataOrders[orderName]["repeat"] ~= "0" then o = o.." end " end
	ff = ff..f.."end) end "
	--o = o.." WCServer.finalize() "
	o = o..f
	o = o.." os.sleep(1); WCServer.threadEnded('"..orderName.."') end) end " 
	
	saveOrder(orderName, i..ff..o.."return "..orderName)
	
	--local file=io.open("./wincraft/orders/"..orderName..".lua","w")
	----file:write(i..o.."return "..orderName)
	--file:write(i..ff..o.."return "..orderName)
	--file:close()
end

local uOrder = function(eventType,dest,src,aport,strength,order, oldOrderName, newOrderName, actualOrder)
	local json = require "json"
	dataOrders[newOrderName] = json.decode(actualOrder)
	if oldOrderName ~= newOrderName then
		dataOrders[oldOrderName] = nil
	end
	package.loaded.json = nil
	saveJsonData("dataOrders.json", dataOrders)
	--saveOrders()
	
	--local fs = require "filesystem"; fs.remove("/home/"..oldOrderName..".lua")
	removeOrder(oldOrderName)
	
	saveOrderExecFile(newOrderName)
	package.loaded[newOrderName] = nil
	package.loaded[oldOrderName] = nil
	mo.broadcast(port, "remote_order_changed", "upd", oldOrderName, newOrderName, actualOrder)
end

local dOrder = function(eventType,dest,src,aport,strength,order, orderName)
	dataOrders[orderName] = nil
	--saveOrders()
	saveJsonData("dataOrders.json", dataOrders)
	
	--local fs = require "filesystem"; fs.remove("/home/"..orderName..".lua")
	removeOrder(orderName)
	
	package.loaded[orderName] = nil
	mo.broadcast(port, "remote_order_changed", "del", orderName)
end

local iOrder = function(eventType,dest,src,aport,strength,order, orderName, actualOrder)
	local json = require "json"
	dataOrders[orderName] = json.decode(actualOrder)
	package.loaded.json = nil
	--saveOrders()
	saveJsonData("dataOrders.json", dataOrders)
	
	saveOrderExecFile(orderName)
	package.loaded[orderName] = nil
	mo.broadcast(port, "remote_order_changed", "ins", orderName, actualOrder)
end

local lWindow = function(eventType,dest,src,aport,strength,order, windowName, offOn)
	dataWindowsLocked[windowName] = offOn
	--saveWindowsLocked()
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

WCServer.start = function(aport)
	os.sleep(1)
	port = aport
	fetchData()
	mo.open(port)
	for k, v in pairs (dataOrders) do 
		mo.broadcast(port, "remote_execute_order_changed", k, "offOn", false)
	end
	print("Server port: "..port.." opened: "..(mo.isOpen(port) and 'true' or 'false').." -- press 't' to exit")
	local block, side, origValue, newValue, color
	local orders = {}
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
			    	data[block][tostring(side)] = bit32.bor(data[block][tostring(side)], 2^color)
			    else	
			    	data[block][tostring(side)] = bit32.band(data[block][tostring(side)], 65535 - 2^color)
			    end
			    mo.broadcast(port, "remote_redstone_changed", block, side, origValue, newValue, color)
			end
		else
			--print(d.okv(eventType).." "..d.okv(src).." "..d.okv(aport).." "..d.okv(strength).." "..d.okv(order).." "..d.okv(p7).." "..d.okv(p8).." "..d.okv(p9).." "..d.okv(p10))
			if src == 116 then os.exit() end
		end
	end
end

return WCServer