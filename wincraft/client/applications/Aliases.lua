local Aliases = {}
--local bit32 = require "bit32"
local client
local name -- = "Aliases"

local colors = require "colors"
local sides = require "sides"

function Aliases:set(aname)
	client = self; name = aname
end

Aliases.display = function()
	local window = client.application:addChild(client.GUI.titledWindow(50, 22, 58, 22, name, true))
	window.actionButtons.close.onTouch = function() client.closeWindow(name) end--; window:close() end


	--window:addChild(client.addSyncSwitchAlias(name, "offOn", "light1", "light1"))

	return window
end
  	
return Aliases