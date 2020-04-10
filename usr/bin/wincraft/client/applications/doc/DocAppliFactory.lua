local DocAppliFactory = {}
local dmp = require "dump"

local client
local name

function DocAppliFactory:set(aname)
  client = self; name = aname
end

DocAppliFactory.display = function()
  local window = client.application:addChild(client.GUI.titledWindow(50, 22, 70, 20, name, true))
  window.actionButtons.close.onTouch = function() client.closeWindow(name) end
  
  local textBox = window:addChild(client.GUI.textBox(2, 2, 68, 18, 0x1EEEEE, 0x2D2D2D, {}, 1, 1, 0))
  
  table.insert(textBox.lines, {text = "AppliFactory (mouse scroll for more)", color = 0x880000})
  table.insert(textBox.lines, "")
  table.insert(textBox.lines, "This screen:")
  table.insert(textBox.lines, "* creates custom applications to be found under the Custom menu")
  table.insert(textBox.lines, "* those are only created for the computer they were created on")
  table.insert(textBox.lines, "* vertical list of controls")
  table.insert(textBox.lines, "* has a name, a vertical size, distance between vertical elements")
  table.insert(textBox.lines, "* contains a list of controls you want to see appear")
  table.insert(textBox.lines, "* can set the colors of the created window and controls")
  table.insert(textBox.lines, "")
  table.insert(textBox.lines, "Control options:")
  table.insert(textBox.lines, "* output: a title, a triplet (redstone block/side/wire) ")
  table.insert(textBox.lines, "  and a charge when on (off is 0) - allows controlling it")
  table.insert(textBox.lines, "* outAlias: same for an alias")
  table.insert(textBox.lines, "* execOrder: controls an order")
  table.insert(textBox.lines, "* display: a title, a triplet (redstone block/side/wire)")
  table.insert(textBox.lines, "  and a charge when on (off is 0) - only displays the info")
  table.insert(textBox.lines, "* nothing: adds a vertical space")
  table.insert(textBox.lines, "* variable: displays the value of a variable")
  table.insert(textBox.lines, "* updVar: displays and allow modifying the value of a variable")
  table.insert(textBox.lines, "* disMul: displays the state of wires of a block/side belonging")
  table.insert(textBox.lines, "  to the specified range of colors")

  return window
end

return DocAppliFactory
