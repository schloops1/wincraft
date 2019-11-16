local AliasesModif = {}
local colors = require "colors"
local sides = require "sides"

local client
local name

function AliasesModif:set(aname)
	client = self; name = aname
end

local function treeUpdateAliasListRecursively(tree, node, offset)
	local list = {}
	for k, v in pairs(node) do --or ipairs?
		table.insert(list, k)
	end

	local i, expandables = 1, {}
	while i <= #list do
		if list[i].node == true then
			table.insert(expandables, list[i])
			table.remove(list, i)
		else
			i = i + 1
		end
	end

	--table.sort(expandables, function(a, b) return unicode.lower(a) < unicode.lower(b) end)
	--table.sort(list, function(a, b) return unicode.lower(a) < unicode.lower(b) end)

	--if tree.showMode == GUI.IO_MODE_BOTH or tree.showMode == GUI.IO_MODE_DIRECTORY then
		for i = 1, #expandables do
			tree:addItem(expandables[i], expandables[i], offset, true)

			if tree.expandedItems[expandables[i]] then
				treeUpdateAliasListRecursively(tree, expandables[i], offset + 2)
			end
		end
	--end

	--if tree.showMode == GUI.IO_MODE_BOTH or tree.showMode == GUI.IO_MODE_FILE then
		for i = 1, #list do
			--tree:addItem(list[i], path .. list[i], offset, false, tree.extensionFilters and not tree.extensionFilters[filesystem.extension(path .. list[i], true)] or false)
			tree:addItem(list[i], list[i], offset, false)
		end
	--end
end

local onItemExpanded = function(e1, e2, e3, e4, e5, e6, e7, e8, e9)
	client.GUI.alert("e1: "..e1)
end

local itemSelected = function(e1, e2, e3, e4, e5, e6, e7, e8, e9)
	client.GUI.alert("coucou")
end

local tree

AliasesModif.display = function()
	local window = client.application:addChild(client.GUI.titledWindow(50, 22, 80, 20, name, true))
	window.actionButtons.close.onTouch = function() client.closeWindow(name) end

--	local tree = GUI.tree(x, y, width, height, backgroundColor, expandableColor, notExpandableColor, arrowColor, 
--		backgroundSelectedColor, anySelectionColor, arrowSelectionColor, disabledColor, scrollBarBackground, scrollBarForeground, showMode, selectionMode)
	tree = client.GUI.tree(2, 2, 20, 20, 0x11E1E1, 0x3C3C3C, 0x3C3C3C, 0xA5A5A5, 0x3C3C3C, 0xE1E1E1, 
		0xB4B4B4, 0xA5A5A5, 0xC3C3C3, 0x4B4B4B, client.GUI.IO_MODE_FILE, client.GUI.IO_MODE_FILE)--client.GUI.IO_MODE_BOTH
	window:addChild(tree)
	tree.onItemSelected = itemSelected
	tree.onItemExpanded = onItemExpanded
	--function() tree:updateFileList() end
	
	treeUpdateAliasListRecursively(tree, client.dataAliases, 1)
	
	
	--for k, v in pairs(client.dataAliases) do
	--	tree:addItem(k, k, 1, v.node == true)
	--end
	
	

	--treeAddItem(tree, name, definition, offset, expandable, disabled)
	--tree.addItem

	return window
end	

return AliasesModif