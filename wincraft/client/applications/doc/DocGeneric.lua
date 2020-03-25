local DocGeneric = {}
local dmp = require "dump"

local client
local name

function DocGeneric:set(aname)
  client = self; name = aname
end

DocGeneric.display = function()
  local window = client.application:addChild(client.GUI.titledWindow(50, 22, 70, 10, name, true))
  window.actionButtons.close.onTouch = function() client.closeWindow(name) end
  
  local textBox = window:addChild(client.GUI.textBox(2, 2, 68, 8, 0x1EEEEE, 0x2D2D2D, {}, 1, 1, 0))
  
  table.insert(textBox.lines, {text = "Generic Screen", color = 0x880000})
  table.insert(textBox.lines, "")
  table.insert(textBox.lines, "* Displays and allows changing the state of wires ")
  table.insert(textBox.lines, "  (0 (off) - 255 (on))")
  table.insert(textBox.lines, "* The user chooses a redstone block and a side after which")
  table.insert(textBox.lines, "  the window displays the state of the 16 wires concerned")
  table.insert(textBox.lines, "  and allows the user to switch their state.")

  return window
end

return DocGeneric
