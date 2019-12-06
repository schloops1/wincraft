local AliasNode = {}

AliasNode.getAllAliases = function(anode, fillMe)
	table.insert(fillMe, anode.name)
	for _, node in ipairs(anode.children) do
		if node.node then
			AliasNode.getAllAliases(node, fillMe)
		else
			table.insert(fillMe, node.name)	
		end
	end
end

AliasNode.getParentDataNode = function(anode, name)
	if anode.name == name then return anode end
	--if anode.exp then
		for _, node in ipairs(anode.children) do
			if node.name == name then return anode end
			if node.node == true then
				local f = AliasNode.getParentDataNode(node, name)
				if f ~= nil then return f end
			end
		end
	--end
end

AliasNode.getDataNode = function(anode, name)
	if anode.name == name then return anode end
	--if anode.exp then
		for _, node in ipairs(anode.children) do
			if node.name == name then return node end
			if node.node == true then
				local f = AliasNode.getDataNode(node, name)
				if f ~= nil then return f end
			end
		end
	--end
end



local function checkNew(anode, name)
--local checkNewI = function(anode, name) --fucks up for some insane reason
	if anode.name == name then return true end
	if anode.exp then
		for _, node in ipairs(anode.children) do
			if node.name == name then return true end
			if node.node == true then
				local f = checkNew(node, name)
				if f == true then return true end
			end
		end
	end
end

AliasNode.isNew = function(anode, name)
	local isNew = checkNew(anode, name)
	isNew = not isNew
	return isNew
end

return AliasNode