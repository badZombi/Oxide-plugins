PLUGIN.Title = "Remote Commands"
PLUGIN.Description = "accept commands and execute from authorized server..."
PLUGIN.Version = "0.5"
print( "Loading " .. PLUGIN.Title .. " plugin... Version: " .. PLUGIN.Version .. " ..." )

PLUGIN.queue = {};

function PLUGIN:tablelength(stuff)
	self.count = 0
	for k in pairs(stuff) do 
		self.count = self.count + 1
	end
	return self.count
end

function PLUGIN:Init()
	self:AddChatCommands();
	print("Completed loading of " .. self.Title .. " plugin.")

end

function PLUGIN:AddChatCommands()
        self:AddChatCommand( "test", self.testCmd );
        self:AddChatCommand( "addrow", self.addRow );
        self:AddChatCommand( "read", self.testRead );
end

function PLUGIN:testCmd(netuser)
    self.count = self:tablelength(self.queue);
    rust.SendChatToUser( netuser, "Test results: " .. self.count );
end

function PLUGIN:testRead(netuser)
    local task = table.remove(self.queue)
    if task ~= nil then
		local url = task[2] .. task[3]
		rust.SendChatToUser( netuser, "Data: " .. url );
	else
		rust.SendChatToUser( netuser, "No data yet..." );
	end
end

function PLUGIN:addRow(netuser)
    local callRequest = {'CallingPlugin', 'url', 'data', 'callback'}
	table.insert( self.queue, callRequest) 
    rust.SendChatToUser( netuser, "New row added" );
end