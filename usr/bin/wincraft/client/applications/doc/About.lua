local About = {}
local dmp = require "dump"

local client
local name

function About:set(aname)
  client = self; name = aname
end

About.display = function()
  local window = client.application:addChild(client.GUI.titledWindow(50, 22, 70, 15, name, true))
  window.actionButtons.close.onTouch = function() client.closeWindow(name) end
  
  local textBox = window:addChild(client.GUI.textBox(2, 2, 68, 13, 0x1EEEEE, 0x2D2D2D, {}, 1, 1, 0))
  
  table.insert(textBox.lines, {text = "Wincraft -version: alpha 4", color = 0x880000})
  table.insert(textBox.lines, "Author: schloops (schloops1)")
  table.insert(textBox.lines, "Home: https://github.com/schloops1/wincraft")
  table.insert(textBox.lines, "License: MIT")
  table.insert(textBox.lines, "")
  table.insert(textBox.lines, "Uses the following third party libraries:")
  table.insert(textBox.lines, "* https://github.com/IgorTimofeev/GUI")
  table.insert(textBox.lines, "* https://github.com/rxi/json.lua")
  table.insert(textBox.lines, "")
  table.insert(textBox.lines, "Special thanks to:")
  table.insert(textBox.lines, "* OpenComputers s developers")
  table.insert(textBox.lines, "* IgorTimofeev and rxi for their library")
  table.insert(textBox.lines, "* anybody that uses this program")

  return window
end

return About