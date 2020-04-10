local DocOrders = {}
local dmp = require "dump"

local client
local name

function DocOrders:set(aname)
  client = self; name = aname
end

DocOrders.display = function()
  local window = client.application:addChild(client.GUI.titledWindow(50, 22, 70, 20, name, true))
  window.actionButtons.close.onTouch = function() client.closeWindow(name) end
  
  local textBox = window:addChild(client.GUI.textBox(2, 2, 68, 18, 0x1EEEEE, 0x2D2D2D, {}, 1, 1, 0))
  
  table.insert(textBox.lines, {text = "Orders (mouse scroll for more)", color = 0x880000})
  table.insert(textBox.lines, "")
  
  table.insert(textBox.lines, "Orders contain order commands. Executing an order will create")
  table.insert(textBox.lines, "  a thread on the server and then execute the order commands in")
  table.insert(textBox.lines, "  their respective order. An order can be killed. ")
  table.insert(textBox.lines, "  Repeat repeats all the commands the specified amount of times.")
  table.insert(textBox.lines, "")
  table.insert(textBox.lines, "Type of order commands:")
  table.insert(textBox.lines, "* output: sets the state (0-255) of a triplet (block/side/wire)")
  table.insert(textBox.lines, "* outputAlias: sets the state (0-255) of an alias")
  table.insert(textBox.lines, "  and all it's leaves if it's a node")
  table.insert(textBox.lines, "* wait: sets an amount of seconds to wait")
  table.insert(textBox.lines, "* input: waits for the state of the specified wire to be >= of") 
  table.insert(textBox.lines, "  the specified state")
  table.insert(textBox.lines, "* execOrder: executes the specified order")
  table.insert(textBox.lines, "* killOrder: ends the specified order")
  table.insert(textBox.lines, "* cleanOut: clean commands are executed at the end of ther list") 
  table.insert(textBox.lines, "  of commands and if/when a command is killed.")
  table.insert(textBox.lines, "* cleanOAl: same as cleanOut but uses an alias")
  table.insert(textBox.lines, "* cleanW: same as wait but executed at the end or when")
  table.insert(textBox.lines, "  an order is killed")
  table.insert(textBox.lines, "")

  table.insert(textBox.lines, "Type of order commands linked to variables:")
  table.insert(textBox.lines, "* varSet: sets a variable. A number can be set, incremented and ")
  table.insert(textBox.lines, "  decremented by a value. Strings, booleans, alias and order types ")
  table.insert(textBox.lines, "  can be set depending on their type.")
  table.insert(textBox.lines, "* execVAl: equivalent to outputAlias but to the alias the specified")
  table.insert(textBox.lines, "  variable points to")
  table.insert(textBox.lines, "* execVOr: equivalent to execOrder but to the order the specified ")
  table.insert(textBox.lines, "  variable points to")
  table.insert(textBox.lines, "* inpVar: equivalent to input but listens for a change of value ")
  table.insert(textBox.lines, "  of the specified variable")
  table.insert(textBox.lines, "* trigVar: triggers any inpVar listening for the specified variable")
  table.insert(textBox.lines, "* ifV_A: if a boolean variable is in the specified state then ")
  table.insert(textBox.lines, "  a specified Alias will be set to the specified state")
  table.insert(textBox.lines, "* ifV_O: if a boolean variable is in the specified state then")
  table.insert(textBox.lines, "  a specified order will be executed")

  return window
end

return DocOrders
