package.loaded.client = nil
--print(package.path)
if not string.find(package.path, "/home/wincraft/lib") then
	package.path = package.path..";/home/wincraft/lib/?.lua"
	if not string.find(package.path, "/home/wincraft/client") then
		package.path = package.path..";/home/wincraft/client/?.lua"
		package.path = package.path..";/home/wincraft/client/applications/?.lua"
	end
end
--print(package.path)

local function prequire(m) 
  local ok, err = pcall(require, m) 
  if not ok then return nil, err end
  return err
end
local mod = prequire("WCClient")
os.exit()

--local client = require "client"
--client.start(1002)
