local co = require "component"
local term = require "term"

--local screAddress = "a6402dec-5bcf-4263-9297-18e2440a7b81"
local scrAddress = "389430e7-0670-4cb5-890d-f1498f3cf189"

local scr = co.proxy(scrAddress)

term.clear()
local kb = scr.getKeyboards()
co.setPrimary("keyboard", kb[1])
os.sleep(.05)
co.gpu.bind(scrAddress,true)
os.sleep(.05)
print("server setup")