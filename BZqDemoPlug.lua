PLUGIN.Title = "Demo script for BZQueue"
PLUGIN.Description = "send queued webrequest on server init"
PLUGIN.Version = "1"
PLUGIN.ConfigVersion = "1"
PLUGIN.Author = "BadZombi"
PLUGIN.configName = "Demo4BZqueue"
print( "Loading " .. PLUGIN.Title .. " plugin v" .. PLUGIN.Version .. " ..." )

local function touri(datatable)
	if datatable ~= nil then
		local uri = ''
		for k,v in pairs(datatable) do 
			uri = uri .. "&" .. k .. "=" .. v 
		end

		return uri
	else

	end
end

function PLUGIN:Init()
	local b, res = config.Read( self.Title )
	self.Config = res or {}
	if (not b) then
		print("Loading Default '" .. self.Title .. "' Config...")
		self:LoadDefaultConfig()
		if (res) then config.Save( self.Title ) end
	end
	if ( self.Config.configVersion ~= self.ConfigVersion) then
		print("Out of date '" .. self.Title .."' Config, Updating!")
		--Note old values will be replaced until update 1.5
		self:LoadDefaultConfig()
		config.Save( self.configName )
	end
	self:AddChatCommands();
end

function PLUGIN:AddChatCommands()
    self:AddChatCommand( "bzdemoq", self.demoQstuff );
end

function PLUGIN:LoadDefaultConfig()
	self.Config.configVersion = self.ConfigVersion
	self.Config.logToWebsite = true
	self.Config.useQueue = true
	self.Config.serverAddress = "http://rustard.com/_old/" 
	self.Config.serverScript = "logger.php"
end

function PLUGIN:updatesite(wrqData)
	if self.Config.logToWebsite then
		local BASEURL = self.Config.serverAddress .. self.Config.serverScript
		local URLSTRING = "?commonVar1=someData&commonVar2=moredata" .. touri(wrqData);
		print("demo URL/data to send: " .. BASEURL .. URLSTRING)
		if self.Config.useQueue then
			api.Call("BZQueueBind", "QueueMsg", self.Title, BASEURL, URLSTRING)
		else
			local b = webrequest.Send(( BASEURL .. URLSTRING), function( code, response )
				-- add stuff here to handle any non queued responses...
			end )
		end
	end	
end

function PLUGIN:demoQstuff(netuser)
	local locData = {}
    if (not netuser:CanAdmin()) then
        return
    end
	locData['demodata'] = "some stuff here"
    locData['playername'] = netuser.displayName
    self:updatesite(locData)
end