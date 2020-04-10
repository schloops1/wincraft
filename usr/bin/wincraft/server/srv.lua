package.loaded.WCServer = nil

--print(package.path)
if not string.find(package.path, "/usr/lib/wincraft") then
	package.path = package.path..";/usr/lib/wincraft/?.lua"
end
if not string.find(package.path, "/usr/bin/wincraft/server") then
	package.path = package.path..";/usr/bin/wincraft/server/?.lua"
	package.path = package.path..";/usr/bin/wincraft/server/orders/?.lua"
	package.path = package.path..";/usr/bin/wincraft/server/variables/?.lua"
end
--print(package.path)

local WCServer = require "WCServer"
WCServer.start()