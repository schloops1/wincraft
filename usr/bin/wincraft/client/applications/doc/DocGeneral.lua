local DocGeneral = {}
local dmp = require "dump"

local client
local name

function DocGeneral:set(aname)
  client = self; name = aname
end

DocGeneral.display = function()
  local window = client.application:addChild(client.GUI.titledWindow(50, 22, 70, 16, name, true))
  window.actionButtons.close.onTouch = function() client.closeWindow(name) end
  
  local textBox = window:addChild(client.GUI.textBox(2, 2, 68, 14, 0x1EEEEE, 0x2D2D2D, {}, 1, 1, 0))
  
  table.insert(textBox.lines, {text = "General Help", color = 0x880000})
  table.insert(textBox.lines, "")

  table.insert(textBox.lines, {text = "Architecture", color = 0x880000})
  table.insert(textBox.lines, "* one server that controls and reports the state of the wires")
  table.insert(textBox.lines, "* one or more clients displaying data and allowing users to")
  table.insert(textBox.lines, " interact with the server")
  table.insert(textBox.lines, "* transparently uses lan and/or wi-fi")
  table.insert(textBox.lines, " ")
    
  table.insert(textBox.lines, {text = "Signal Basics", color = 0x880000})
  table.insert(textBox.lines, "* The server is connected to redstone block(s) via special cables")
  table.insert(textBox.lines, "* Signal cables are connected to sides of redstone block(s)")
  table.insert(textBox.lines, "* Each cable contains 16 different colored wires")
  table.insert(textBox.lines, "* The server individually reports and modifies the state of wires")
  table.insert(textBox.lines, " ")  

  return window
end

return DocGeneral
