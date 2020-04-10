local DocAliases = {}
local dmp = require "dump"

local client
local name

function DocAliases:set(aname)
  client = self; name = aname
end

DocAliases.display = function()
  local window = client.application:addChild(client.GUI.titledWindow(50, 22, 70, 10, name, true))
  window.actionButtons.close.onTouch = function() client.closeWindow(name) end
  
  local textBox = window:addChild(client.GUI.textBox(2, 2, 68, 8, 0x1EEEEE, 0x2D2D2D, {}, 1, 1, 0))
  
  table.insert(textBox.lines, {text = "Aliases", color = 0x880000})
  table.insert(textBox.lines, "")
  table.insert(textBox.lines, "* an alias is a node or a leaf of a tree item (think directory)")
  table.insert(textBox.lines, "* more readable than a triplet of redstone block/side/wire")
  table.insert(textBox.lines, "* allows regrouping wires so one command can change all of them")
  table.insert(textBox.lines, "* aliases are executed on the server in a different thread")
  table.insert(textBox.lines, "* IsDoor: allows to make sure doors are opened or closed")

  return window
end

return DocAliases
