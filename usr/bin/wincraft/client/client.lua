package.loaded.client = nil

--print(package.path)
if not string.find(package.path, "/usr/lib/wincraft") then
	package.path = package.path..";/usr/lib/wincraft/?.lua"
end
if not string.find(package.path, "/usr/bin/wincraft/client") then
	package.path = package.path..";/usr/bin/wincraft/client/?.lua"
	package.path = package.path..";/usr/bin/wincraft/client/applications/?.lua"
	package.path = package.path..";/usr/bin/wincraft/client/applications/custom/?.lua"
	package.path = package.path..";/usr/bin/wincraft/client/applications/doc/?.lua"
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
