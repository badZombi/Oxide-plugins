PLUGIN.Title = "BZQueue"
PLUGIN.Description = "Queue data for webrequest..."
PLUGIN.Version = "0.5.6"
PLUGIN.ConfigVersion = "0.2"
PLUGIN.Author = "BadZombi"
print( "Loading " .. PLUGIN.Title .. " plugin v" .. PLUGIN.Version .. " ..." )


PLUGIN.queue = {};
PLUGIN.failcount = 0;

-- Use this to know if we are waiting
PLUGIN.availableConnections = 3;
PLUGIN.usedConnections = 0;
PLUGIN.GetTime = util.GetStaticPropertyGetter( UnityEngine.Time, "realtimeSinceStartup");

function PLUGIN:tablelength(stuff)
	self.count = 0
	for k in pairs(stuff) do 
		self.count = self.count + 1
	end
	return self.count
end

function PLUGIN:Init()
	local b, res = config.Read( self.Title )
	self.Config = res or {}
	if (not b) then
		print("Creating new " .. self.Title .. " Config...")
		self:LoadDefaultConfig()
		if (res) then config.Save( self.Title ) end
	end
	if ( self.Config.configVersion ~= self.ConfigVersion) then
		print( self.Title .." config file is out of date... Creating new file. Be sure to update settings!")
		self:LoadDefaultConfig()
		config.Save( self.Title )
	end
	
	self:AddChatCommands()
	self:StartQueue()
	
	print("Completed loading of " .. self.Title .. " plugin.")
end

function PLUGIN:AddChatCommands()
    self:AddChatCommand( "restartqueue", self.RestartQueue );
end

function PLUGIN:RestartQueue(netuser)

	if (not netuser:CanAdmin()) then
        return
    end

    self:StartQueue()

end

function PLUGIN:debug(message, forcetolog)
	if forcetolog ~= nil then
		forcetolog = true;
	end

	if self.Config.chatDebug then
		rust.BroadcastChat("debug", message)
	end

	if self.Config.logDebug or forcetolog == true then
		print(self.Title .. " debug message: " .. message)
	end

end


function PLUGIN:StartQueue()
	if self.myTimer == nil then
		self.myTimer = timer.Repeat(self.Config.timer, 0, function() self:RunTransmitTask() end)
		self:debug("Queue is up and running.", true)
	else
		self:debug("Attempted to restart an already running queue.", true)
	end
end

function PLUGIN:LoadDefaultConfig()
	self.Config.configIntructions = "Leave version alone. Timer is how many seconds between rechecking queue. Chat Debug currently broadcasts to all players. Log debug places a LOT of text in the Oxide log so only use when needed. Requeue on fail will try to save data for later if a send fails. Max failures is the number of failed attempts before plugin will shut off the timer and stop sending data. Admin can attempt to restart with /restartqueue command. Config will be created on first run so you will need to edit file and restart. This is why you don't want to mess with the config version."
	self.Config.configVersion = self.ConfigVersion
	self.Config.timer = 10
	self.Config.chatDebug = false
	self.Config.logDebug = false
	self.Config.requeueOnFail = false
	self.Config.maxFailures = 25
end

function PLUGIN:QueueMsg(CallingPlugin, url, data, callback)
	self:debug("adding 1 to queue... ")
	-- check for optional callback dont know if I actually need to do this with lua
	-- self:debug('sending with callback: '..callback)

	local callRequest = {CallingPlugin, url, data, callback}
	
	table.insert( self.queue, callRequest) 
	
end

-- Called once a second, checks for the queue size, if less than three it adds items
function PLUGIN:RunTransmitTask()

	self.queued = self:tablelength(self.queue);
	if self.queued >= 1 then

		if self.Config.showDebug then
			self:debug("post-check dynamic queue count: " .. self.queued)
			self:debug("Connections: A:" .. self.availableConnections .. " U:" .. self.usedConnections)
		end

		if self.usedConnections < 3 then
			local availableConnections = 3 - self.usedConnections
			for addTask = 1, availableConnections, 1 do
				local task = table.remove(self.queue)
				
				if task ~= nil then
					local tmpCallingPlugin = task[1]
					local tmpurl = task[2]
					local tmpdata = task[3]
					local tmpcallback = false

					if task[4] then
						tmpcallback = task[4]
						self:debug('callback as task[4]: ' .. tmpcallback)
					end 

					local url = tmpurl .. tmpdata
					self:debug("Sending data")
					
					self.usedConnections = self.usedConnections + 1 
					webrequest.Send( url, function(resCode, response) 
						self.usedConnections = self.usedConnections -1
						self:debug("Recieved Response: " .. resCode .. " with message: " .. response)
						
						-- check for 200 code and requeue if failed use config to requeue or drop data
						if resCode == 200 then
							-- check for callback and execute if needed. send response with callback json array maybe?
							-- add parsing of returned json so we dont have to mess with headers and can return full error messages from server. e.g. success=false | reason=you fucked up
							if tmpcallback then
								self:debug("callback: " .. tmpcallback)
								api.Call(tmpCallingPlugin.."Bind", tmpcallback, response)
							else
								self:debug("no callback")
							end

							
							
						else
							self.failcount = self.failcount + 1;
							
							if tonumber(self.failcount) >= tonumber(self.Config.maxFailures) then

								self:debug("Too mainy failed sends to remote server... No longer sending data.")
								if self.myTimer ~= nil then
									self.myTimer:Destroy()
									self.myTimer = nil;
									self.failcount = 0;
								end
								
								
							end
							self:debug("Send failed, checking requeue setting...")
							-- requeue if config says to
							if self.Config.requeueOnFail then

								self:debug("Trying to requeue...")
								if tmpcallback then
									self:debug("About to insert: " .. tmpCallingPlugin .. " | " .. tmpurl .. " | " .. tmpdata .. " | no callback set")
								else
									self:debug("About to insert: " .. tmpCallingPlugin .. " | " .. tmpurl .. " | " .. tmpdata .. " | add callback here!")
									-- need to fix and add callback saving in the line above
								end

								local callRerequest = {tmpCallingPlugin, tmpurl, tmpdata, 'false'}
								
	 							table.insert( self.queue, callRerequest)
	 							self:debug("Send failed, requeued 1 entry")
							end
							
						end
					end )
					
					
				end
			end
		end
	
	else
		self:debug("post-check nothing in queue")
	end

end


api.Bind( PLUGIN, "BZQueueBind" )

