local BlocksModif = {}
local colors = require "colors"
local sides = require "sides"

local client
local name

function BlocksModif:set(aname)
	client = self; name = aname
end

BlocksModif.display = function()
	local window = client.application:addChild(client.GUI.titledWindow(50, 22, 80, 20, name, true))
	window.actionButtons.close.onTouch = function() client.closeWindow(name) end

	local panel = window:addChild(client.GUI.panel(2, 2, 78, 18, 0x880000))

	--local containerFilter = window:addChild(client.GUI.container(2, 2, 70, 10))

	--local filterField = containerFilter:addChild(client.GUI.input(2, 2, 16, 1, 0xEEEEEE, 0x555555, 0x999999, 0xFFFFFF, 0x2D2D2D, "", ""))
	--containerFilter:addChild(client.GUI.button(20, 2, 10, 1, 0xFFFFFF, 0x555555, 0x880000, 0xFFFFFF, "Filter"))



	--local aa = containerFilter:addChild(client.GUI.text(2, 2, 0xFFFFFF, "Id:"..dmp.okv(id)))

	return window
end	

return BlocksModif