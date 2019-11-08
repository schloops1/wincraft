local dump = {}

dump.pOffOn = true

dump.dmp = function (o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump.dmp(v) .. ',\n'
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

dump.dmpFile = function (o, fileName)
	local fil = io.open(fileName, "w")
	fil:write(dump.dmp(o))
	fil:close()
end

dump.dmpJsonFile = function (o, fileName)
	local json = require "json"
	local fil = io.open(fileName, "w")
	string = json.encode(o)
	fil:write(string)
	fil:close()
end





dump.ok = function(k)
	if k == true or k == false then
		return tostring(k)
	elseif k == nil then 
		return ""
	elseif k == 0 then
		return "0"
	else	
		return k	
	end
end

dump.okv = function(k)
	local kk = dump.ok(k)
	if kk == "" then 
		return "-" 
	else
		return kk
	end
end

dump.newLog = function()
	io.open("log.txt","w"):close()
end

dump.p = function(text)
  if dump.pOffOn == false then return end
  local f=io.open("log.txt","a")
  f:write(text)
  f:write("\n")
  f:close()
end

return dump