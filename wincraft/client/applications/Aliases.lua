local Aliases = {}
local dmp = require "dump"
local aliasNode = require "AliasNode"

local tree
local containerButtons

local client
local name

function Aliases:set(aname)
  client = self; name = aname
end

local function offOnAlias(charge)
  local selectedName = tree:getSelectedName()
  client.offOnAlias(selectedName, charge)
end


local function displayButtons(alias)
  containerButtons:removeChildren()
  client.stopListeningToWindowWires(name)

  --containerButtons:addChild(client.GUI.text(30, 2, 0xFFFFFF, "Node: "..isNode))
  
  local offButton = containerButtons:addChild(client.GUI.button(2, 2, 8, 1, 0xFFEFFF, 0x555555, 0x880000, 0xFFFFFF, "Off"))
  offButton.onTouch = function() offOnAlias(0) end
  local onButton = containerButtons:addChild(client.GUI.button(20, 2, 8, 1, 0xFFEFFF, 0x555555, 0x880000, 0xFFFFFF, "On"))
  onButton.onTouch = function() offOnAlias(255) end
  
  if alias.node == false then
    local displayState = client.addSyncRectangle(alias.block, alias.side, alias.color, name)
    displayState.x = 12; displayState.y = 2; displayState.width = 6
    containerButtons:addChild(displayState)
  end


end

local itemSelected = function(e1, e2, e3, e4, e5, e6, e7, e8, e9)
  --cleanUp()
  local alias = tree.getDataNode(tree.dataNode, tree:getSelectedName())
  displayButtons(alias)
end

local onItemExpanded = function(e1, e2, e3, e4, e5, e6, e7, e8, e9)
end

local refresh = function()
  tree:refresh()
  tree.selectedItem = 1 
  client.application:draw()
end

Aliases.display = function()
  local window = client.application:addChild(client.GUI.titledWindow(50, 22, 30, 25, name, true))
  window.actionButtons.close.onTouch = function() client.closeWindow(name) end

  tree = client.GUI.aliasTree(client.dataAliases, 2, 2, 28, 19, 0x11E1E1, 0x3C3C3C, 0x3C3C3C, 0xA5A5A5, 0x3C3C3C, 0xE1E1E1, 
    0xB4B4B4, 0xA5A5A5, 0xC3C3C3, 0x4B4B4B)
  window:addChild(tree); tree.onItemSelected = itemSelected; tree.onItemExpanded = onItemExpanded

  tree.switch.refresh = refresh
  client.listenToAliasesList(tree, name)

  local panelBUTTONS = window:addChild(client.GUI.panel(2, 22, 28, 3, 0x880000))
  containerButtons = window:addChild(client.GUI.container(panelBUTTONS.x, panelBUTTONS.y, panelBUTTONS.width, panelBUTTONS.height))

  --displayButtons()

  return window
end

return Aliases