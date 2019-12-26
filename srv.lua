package.loaded.WCServer = nil
--print(package.path)
if not string.find(package.path, "/home/wincraft/lib") then
	package.path = package.path..";/home/wincraft/lib/?.lua"
	if not string.find(package.path, "/home/wincraft/server") then
		package.path = package.path..";/home/wincraft/server/?.lua"
		package.path = package.path..";/home/wincraft/server/orders/?.lua"
	end
end
--print(package.path)
local WCServer = require "WCServer"
WCServer.start()