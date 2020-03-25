local DocVariables = {}
local dmp = require "dump"

local client
local name

function DocVariables:set(aname)
  client = self; name = aname
end

DocVariables.display = function()
  local window = client.application:addChild(client.GUI.titledWindow(50, 22, 70, 15, name, true))
  window.actionButtons.close.onTouch = function() client.closeWindow(name) end
  
  local textBox = window:addChild(client.GUI.textBox(2, 2, 68, 13, 0x1EEEEE, 0x2D2D2D, {}, 1, 1, 0))
  
  table.insert(textBox.lines, {text = "Variables", color = 0x880000})
  table.insert(textBox.lines, "")
  table.insert(textBox.lines, "Type of variables")
  table.insert(textBox.lines, "* number / string / boolean / alias / order")
  table.insert(textBox.lines, "")
  table.insert(textBox.lines, "save: a variable s value changed via this window is always saved")
  table.insert(textBox.lines, "  but not forcefully if changed by other ways. This tells the ")
  table.insert(textBox.lines, "  program if the variable value needs to be saved on hard drive")
  table.insert(textBox.lines, "  when it is changed by other ways (orders and custom windows).")
  table.insert(textBox.lines, "")

  table.insert(textBox.lines, "Caution: variables can make the program crash if pointing towards")
  table.insert(textBox.lines, "    aliases or orders that don't exist anymore.")

  return window
end

return DocVariables
