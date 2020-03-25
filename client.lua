package.loaded.client = nil
--print(package.path)
if not string.find(package.path, "/home/wincraft/lib") then
	package.path = package.path..";/home/wincraft/lib/?.lua"
	if not string.find(package.path, "/home/wincraft/client") then
		package.path = package.path..";/home/wincraft/client/?.lua"
		package.path = package.path..";/home/wincraft/client/applications/?.lua"
		package.path = package.path..";/home/wincraft/client/applications/custom/?.lua"
		package.path = package.path..";/home/wincraft/client/applications/doc/?.lua"
	end
end
--print(package.path)

local function prequire(m) 
  local ok, err = pcall(require, m) 
  if not ok then return nil, err end
  return err
end

local safe = true
--set to true to avoid error msg when exiting; sadly hides most error msg
if safe == true then
	local mod = prequire("WCClient")
	os.exit()
else
	local client = require "WCClient"
	client.start()
end
