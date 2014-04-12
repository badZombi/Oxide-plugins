PLUGIN.Title = "BZKill"
PLUGIN.Description = "Log death data in chat and/or on external server."
PLUGIN.Version = "0.5"
PLUGIN.ConfigVersion = "0.2"
PLUGIN.Author = "BadZombi"
print( "Loading " .. PLUGIN.Title .. " V: " .. PLUGIN.Version .. " ..." )


-- TODO:
-- Remove Oxmin stuff... not needed and can conflict
-- Remove log to file... no point in it for now
-- Remove olf body part data and see if it still works ;)
-- Remove all traces old code for object destruction (currently commented out) and move it to a new plugin
-- Update config loader so it will import variables from old config versions before overwriting

--Gets the function to call date time
local dateTime = util.GetStaticPropertyGetter( System.DateTime, 'Now' )
if not fileLog then fileLog = {} end

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

--Thanks to user973713
local function split(str, delimiter)
    result = {};
	if delimiter == nil then
                delimiter = "%s"
    end
    for match in (str..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end
--True for date false for date + time
local function getTimeOrDate(dtB)
	local dt = split(tostring(dateTime()))
	local date = dt[1]
	local time = dt[2]
	local ap = dt[3]
	
	local dateSplit = split(date,"/")
	if (string.len(dateSplit[1]) == 1) then dateSplit[1] = "0"..dateSplit[1] end 
	date = table.concat( {dateSplit[1], dateSplit[2], dateSplit[3] }, "-" )
	
	local timeSplit = split(time,":")
	if ap == "PM:" then timeSplit[1] = tonumber( timeSplit[1] ) + 12 end
	time = table.concat( timeSplit, ":" )
	
	if dtB then return "(" .. date .. ")"end
	return "(" .. date .. " " .. time .. ")"
end

local function findNetUserByID(userID)
    allnetusers = rust.GetAllNetUsers()
    if (not allnetusers) then 
    	print('fail1')
    	return 
    end
    local tmp = {}

    for i=1, #allnetusers do
    	local netuser = allnetusers[i]
    	if (rust.GetUserID(netuser) == userID) then
    		return netuser
    	end
    end

    print('fail2')
end

function PLUGIN:Init()


	local b, res = config.Read( self.Title )
	self.Config = res or {}
	if (not b) then
		print("Loading Default " .. self.Title .. " Config...")
		self:LoadDefaultConfig()
		if (res) then config.Save( self.Title ) end
	end
	if ( self.Config.configVersion ~= self.ConfigVersion) then
		print("Out of date " .. self.Title .." Config, Updating!")
		--Note old values will be replaced until update 1.5
		self:LoadDefaultConfig()
		config.Save( "BZ Kill Log" )
	end
	if self.Config.logToFile then
		fileLog.file = util.GetDatafile(self.Title .. getTimeOrDate(true))
		local logText = fileLog.file:GetText()
		if (logText ~= "") then
			fileLog.text = split(logText,"\r\n")
		else
			fileLog.text = {}
		end
	end

	self:AddChatCommand( "death", self.setConfigValue)
	oxmin_Plugin = plugins.Find("oxmin")

	if not oxmin_Plugin or not oxmin then
		print("Flag Deathconfig not added! Requires Oxmin")
		self.oxminInstalled = false
		return
	else
		self.FLAG_DEATHCONFIG = oxmin.AddFlag("Deathconfig")
		self.oxminInstalled = true
		print("Flag Deathconfig added!")
	end

	-- temp way to set up random messages
	self.AIdeathVerbs = {'just got jacked by a', 'just got fucked up by a', 'was just raped by a', 'was just slaughtered by a'}
	self.animalKilledVerbs = {'jacked a', 'just murdered a poor innocent', 'ganked', 'slaughtered a', 'just murdered a'}
	self.playerKilledVerbs = {'murdered', 'jacked', 'ganked', 'slaughtered', 'killed', 'blasted', 'popped', 'offed'}
	self.suicideMessages = {"murdered himself to death", "couldn't handle life...", 'chose the easy way out...', 'took the black pill...', 'just offed himself...', 'gave up too soon...'}
	self.wordsForPenis = {"penis", "wang", "junk", "crotch", "pink bits", "special purpose", "naughty parts", "shlong", "twig n' berries", "cock", "dick", "weiner", "prick", "johnson", "pecker", "baby maker", "bratwurst", "taint", "chode", "dong", "wenis", "love muscle", "main vein", "middle leg", "pud", "pudding", "yam bag", "D"}

end

function fileLog.save()
	fileLog.file:SetText( table.concat( fileLog.text, "\r\n" ) )
	fileLog.file:Save()
end

function PLUGIN:LoadDefaultConfig()
	self.Config.configVersion = self.ConfigVersion
	self.Config.logToAdminConsole = false
	self.Config.logToConsole = false
	self.Config.logToFile = false
	self.Config.broadCastChat = true
	self.Config.deathByEntity = "both"
	self.Config.player = "site"
	self.Config.bear = "both"
	self.Config.wolf = "site"
	self.Config.stag = "site"
	self.Config.chicken = "site"
	self.Config.rabbit = "both"
	self.Config.boar = "site"
	self.Config.suicide = "chat"
	self.Config.suicideMessage = "couldn't handle life..."
	self.Config.chatName = "RusTard"
	self.Config.weapon = true
	self.Config.bodyPart = true
	self.Config.left = ""
	self.Config.right = ""
	self.Config.logToWebsite = true
	self.Config.useQueue = false -- currently bugged so leave it false
	self.Config.serverAddress = "http://rustard.com/" -- address requires trailing slash
	self.Config.serverScript = "logger"
	self.Config.serverID = "123456"
	self.Config.serverPassword = "notsetyet"
	self.Config.showServerResponse = false
	self.Config.mutantbear = "both"
	self.Config.mutantwolf = "both"

end

--Gets user data from datastore
function PLUGIN:GetUserData( netuser )
	local userID = rust.GetUserID( netuser );
	return self:GetUserDataFromID(netuser, userID, netuser.displayName );
end

function PLUGIN:GetUserDataFromID(netuser, userID, name )
	local userentry = self.JsonData[ userID ];
	--Create user if user is not present in datastore
	if (not userentry) then
		userentry = {};
		userentry.LoggedOn=1;
		userentry.ID = userID;
		userentry.Name = name;
		userentry.X = self.X;
		userentry.Y = self.Y;
		userentry.Z = self.Z;
		self.JsonData[ userID ] = userentry;
        self:Save();
	end
	return userentry;
end

function PLUGIN:getUserX(netuser)
	self:GetUserData( netuser );
	local coords = netuser.playerClient.lastKnownPosition;
	local playerID = rust.GetUserID( netuser );
	local X = 0;
	if (coords ~= nil) then
		if (coords.x ~= nil) then
			if(type(coords.x)=='number') then	
				X = math.floor(coords.x);
			end
		end
	end
	if(playerID) then
		self.JsonData[playerID].X = X;
		self:Save();
	end
	return X;
end

function PLUGIN:getUserY(netuser)
	self:GetUserData( netuser );
	local coords = netuser.playerClient.lastKnownPosition;
	local Y = 0;
	if (coords ~= nil) then
		if (coords.y ~= nil) then
			if(type(coords.y)=='number') then	
				Y = math.floor(coords.y);
			end
		end
	end
	if(playerID) then
		self.JsonData[playerID].Y = Y;
		self:Save();
	end
	return Y;
end

function PLUGIN:getUserZ(netuser)
	self:GetUserData( netuser );
	local coords = netuser.playerClient.lastKnownPosition;
	local playerID = rust.GetUserID( netuser ) ; 
	local Z = 0;
	if (coords ~= nil) then
		if (coords.z ~= nil) then	
			if(type(coords.z)=='number') then	
				Z = math.floor(coords.z);
			end
		end
	end
	if(playerID) then
		self.JsonData[playerID].Z = Z;
		self:Save();
	end
	return Z;
end

function PLUGIN:notifyDeath(message)
	if self.Config.logToAdminConsole then
		for _, netuser in pairs( rust.GetAllNetUsers() ) do
			if netuser:CanAdmin() then rust.RunClientCommand( netuser, "echo " .. message ) end
		end
	end
	if self.Config.broadCastChat then
		rust.BroadcastChat(self.Config.chatName, message)
	end
	if self.Config.logToConsole then print(message) end
	
	if self.Config.logToFile then
		table.insert( fileLog.text, getTimeOrDate() .. " " .. message)
		fileLog.save()
		
	end
end

function PLUGIN:handleResponse(code, response)
	--rust.BroadcastChat("Blah", response)
end

function PLUGIN:updatesite(killData, noQueue)

	if self.Config.logToWebsite then
		local CALLBACK = false
		local BASEURL = self.Config.serverAddress .. self.Config.serverScript
		local URLSTRING = "?serverID=" .. self.Config.serverID .. "&pass=" .. self.Config.serverPassword .. touri(killData);
		if killData['callback'] ~= nil then
			CALLBACK = killData['callback']
		end
		if self.Config.useQueue and noQueue == nil then
			-- print("x " .. CALLBACK .. 'x')
			api.Call("BZQueueBind", "QueueMsg", self.Title, BASEURL, URLSTRING, CALLBACK)
		else
			local b = webrequest.Send(( BASEURL .. URLSTRING), function( code, response )
				if self.Config.showServerResponse then
					rust.BroadcastChat(self.Config.chatName, response)
				end
			end )
		end
	end	

end

function PLUGIN:reward( response )
	local rewardData = json.decode(response)

	if (not rewardData) then
		error( "json decode error during reward response" )
		return
	end

	if rewardData['reward'] and rewardData['player'] then
		targUser = findNetUserByID(rewardData['player'])
		rust.InventoryNotice(targUser, rewardData['reward'])
		print(rewardData['player'] .. ": " .. rewardData['reward'])
	end
	
end

function PLUGIN:setConfigValue(netuser, cmd, args)
	if (netuser:CanAdmin() or (self.oxminInstalled and oxmin_Plugin:HasFlag(netuser, self.FLAG_DEATHCONFIG, false))) then
		local targetConfig = args[1]
		for k, v in pairs(self.Config) do 
			if (k == targetConfig) then 
				if (tostring(self.Config[targetConfig]) == "true") then 
					self.Config[targetConfig] = false 
					rust.Notice( netuser, targetConfig .. " Set to: false") 
				else
					if (tostring(self.Config[targetConfig]) == "false") then 
						self.Config[targetConfig] = true 
						rust.Notice( netuser, targetConfig .. " Set to: true") 
					else
						self.Config[targetConfig] = args[2]
						rust.Notice( netuser, targetConfig .. " Set to: " .. tostring(args[2])) 
					end
				end
				print("Saving Config")
				config.Save( PLUGIN.Title )
				self:Init()
				return
			end
		end
		rust.Notice( netuser, "No Config found!") 
	end
end
local BodyParts = {}

BodyParts["Undefined"] = "spleen"
--In tribute to Offensive Combat <3
BodyParts["Hip"] = "wang"
BodyParts["Spine0"] = "chest"
BodyParts["Spine1"] = "chest"
BodyParts["Spine2"] = "chest"
BodyParts["Spine3"] = "chest"
BodyParts["Spine4"] = "chest"
BodyParts["Spine5"] = "chest"
BodyParts["Neck"] = "neck"
BodyParts["Head"] = "head"
BodyParts["Scalp"] = "dome"
BodyParts["Nostrils"] = "nose"
BodyParts["Jaw"] = "face"
BodyParts["TongueRear"] = "mouth"
BodyParts["TongueFront"] = "mouth"
BodyParts["Heart"] = "heart"
BodyParts["Brain"] = "brain"
BodyParts["Stomache"] = "gut"
BodyParts["L_Lung"] = "lung"
BodyParts["R_Lung"] = "lung"
BodyParts["L_Eye"] = "eye"
BodyParts["R_Eye"] = "eye"
BodyParts["L_Clavical"] = "chest"
BodyParts["R_Clavical"] = "chest"
BodyParts["L_UpperArm0"] = "left arm"
BodyParts["R_UpperArm0"] = "right arm"
BodyParts["L_UpperArm1"] = "left arm"
BodyParts["R_UpperArm1"] = "right arm"
BodyParts["L_ForeArm0"] = "left arm"
BodyParts["R_ForeArm0"] = "right arm"
BodyParts["L_ForeArm1"] = "left arm"
BodyParts["R_ForeArm1"] = "right arm"
BodyParts["L_Hand"] = "left hand"
BodyParts["R_Hand"] = "right hand"
BodyParts["L_Finger_Index0"] = "left  hand"
BodyParts["R_Finger_Index0"] = "right  hand"
BodyParts["L_Finger_Index1"] = "left  hand"
BodyParts["R_Finger_Index1"] = "right hand"
BodyParts["L_Finger_Index2"] = "left hand"
BodyParts["R_Finger_Index2"] = "right hand"
BodyParts["L_Finger_Index3"] = "left hand"
BodyParts["R_Finger_Index3"] = "right hand"
BodyParts["L_Finger_Index4"] = "left hand"
BodyParts["R_Finger_Index4"] = "right hand"
BodyParts["L_Finger_Middle0"] = "left hand"
BodyParts["R_Finger_Middle0"] = "right hand"
BodyParts["L_Finger_Middle1"] = "left hand"
BodyParts["R_Finger_Middle1"] = "right hand"
BodyParts["L_Finger_Middle2"] = "left hand"
BodyParts["R_Finger_Middle2"] = "right hand"
BodyParts["L_Finger_Middle3"] = "left hand"
BodyParts["R_Finger_Middle3"] = "right hand"
BodyParts["L_Finger_Middle4"] = "left hand"
BodyParts["R_Finger_Middle4"] = "right hand"
BodyParts["L_Finger_Ring0"] = "left hand"
BodyParts["R_Finger_Ring0"] = "right hand"
BodyParts["L_Finger_Ring1"] = "left hand"
BodyParts["R_Finger_Ring1"] = "right hand"
BodyParts["L_Finger_Ring2"] = "left hand"
BodyParts["R_Finger_Ring2"] = "right hand"
BodyParts["L_Finger_Ring3"] = "left hand"
BodyParts["R_Finger_Ring3"] = "right hand"
BodyParts["L_Finger_Ring4"] = "left hand"
BodyParts["R_Finger_Ring4"] = "right hand"
BodyParts["L_Finger_Pinky0"] = "left hand"
BodyParts["R_Finger_Pinky0"] = "right hand"
BodyParts["L_Finger_Pinky1"] = "left hand"
BodyParts["R_Finger_Pinky1"] = "right hand"
BodyParts["L_Finger_Pinky2"] = "left hand"
BodyParts["R_Finger_Pinky2"] = "right hand"
BodyParts["L_Finger_Pinky3"] = "left hand"
BodyParts["R_Finger_Pinky3"] = "right hand"
BodyParts["L_Finger_Pinky4"] = "left hand"
BodyParts["R_Finger_Pinky4"] = "right hand"
BodyParts["L_Finger_Thumb0"] = "left hand"
BodyParts["R_Finger_Thumb0"] = "right hand"
BodyParts["L_Finger_Thumb1"] = "left hand"
BodyParts["R_Finger_Thumb1"] = "right hand"
BodyParts["L_Finger_Thumb2"] = "left hand"
BodyParts["R_Finger_Thumb2"] = "right hand"
BodyParts["L_Finger_Thumb3"] = "left hand"
BodyParts["R_Finger_Thumb3"] = "right hand"
BodyParts["L_Finger_Thumb4"] = "left hand"
BodyParts["R_Finger_Thumb4"] = "right hand"
BodyParts["L_Fingers"] = "left hand"
BodyParts["R_Fingers"] = "right hand"
BodyParts["L_Thigh0"] = "left leg"
BodyParts["R_Thigh0"] = "right leg"
BodyParts["L_Thigh1"] = "left leg"
BodyParts["R_Thigh1"] = "right leg"
BodyParts["L_Shin0"] = "left leg"
BodyParts["R_Shin0"] = "right leg"
BodyParts["L_Shin1"] = "left leg"
BodyParts["R_Shin1"] = "right leg"
BodyParts["L_Foot"] = "left foot"
BodyParts["R_Foot"] = "right foot"
BodyParts["L_Heel0"] = "left foot"
BodyParts["R_Heel0"] = "right foot"
BodyParts["L_Heel1"] = "left foot"
BodyParts["R_Heel1"] = "right foot"
BodyParts["L_Toe0"] = "left foot"
BodyParts["R_Toe0"] = "right foot"
BodyParts["L_Toe1"] = "left foot"
BodyParts["R_Toe1"] = "right foot"
BodyParts["L_EyeLidLower"] = "eye"
BodyParts["R_EyeLidLower"] = "eye"
BodyParts["L_EyeLidUpper"] = "eye"
BodyParts["R_EyeLidUpper"] = "eye"
BodyParts["L_BrowInner"] = "head"
BodyParts["R_BrowInner"] = "head"
BodyParts["L_BrowOuter"] = "head"
BodyParts["R_BrowOuter"] = "head"
BodyParts["L_Cheek"] = "face"
BodyParts["R_Cheek"] = "face"
BodyParts["L_LipUpper"] = "mouth"
BodyParts["R_LipUpper"] = "mouth"
BodyParts["L_LipLower"] = "mouth"
BodyParts["R_LipLower"] = "mouth"
BodyParts["L_LipCorner"] = "mouth"
BodyParts["R_LipCorner"] = "mouth"

local _BodyParts = cs.gettype( "BodyParts, Facepunch.HitBox" )
local _GetNiceName = util.GetStaticMethod( _BodyParts, "GetNiceName" )
local _NetworkView = cs.gettype( "Facepunch.NetworkView, Facepunch.ID" )
local _Find = util.GetStaticMethod( _NetworkView, "Find" )

function PLUGIN:getUserLocation(netuser)
        local coords = netuser.playerClient.lastKnownPosition
        return math.floor(coords.x) .. "|" .. math.floor(coords.y) .. "|" .. math.floor(coords.z)
end

function PLUGIN:getAILocation(gameObject)
        local coords = gameObject.transform.localPosition
        return math.floor(coords.x) .. "|" .. math.floor(coords.y) .. "|" .. math.floor(coords.z)
end

function PLUGIN:DistanceFromPlayers(p1, p2)
    local fulldist = math.sqrt(math.pow(p1.x - p2.x,2) + math.pow(p1.y - p2.y,2) + math.pow(p1.z - p2.z,2)) 
    return tostring(math.floor(fulldist))
end

function PLUGIN:tosteamid(somedata)
	return rust.CommunityIDToSteamID( tonumber( rust.GetUserID( somedata ) ) )
end

function PLUGIN:datetime()

	local nowtime = util.GetStaticPropertyGetter( System.DateTime, 'Now' )
	return nowtime().Year .. "|" .. nowtime().Month .. "|" .. nowtime().Day .. "|" .. nowtime().Hour .. "|" .. nowtime().Minute .. "|" .. nowtime().Second
end

function PLUGIN:OnKilled(takedamage, damage)

	local killData = {}

	local KillerAnimals ={}
 
	KillerAnimals["MutantBear(Clone)"] = "Mutant Bear"
	KillerAnimals["MutantWolf(Clone)"] = "Mutant Wolf"
	KillerAnimals["Bear(Clone)"] = "Bear"
	KillerAnimals["Wolf(Clone)"] = "Wolf"

	-- save time for web
	self.Ktimestamp = self:datetime()
	killData['time'] = self.Ktimestamp

	killData['action'] = 'kill'

	self.logWhere = nil;

	--determine and save weapon name
	local weapon
	if(damage.extraData) then
		weapon = damage.extraData.dataBlock.name
	end
	local weaponMsg
	local weaponLog
	if( weapon and	self.Config.weapon ) then 
		if ((weapon == "M4") or (weapon == "MP5A4")) then
			weaponMsg = " with an " .. self.Config.left .." ".. weapon .. " ".. self.Config.right
		else
			weaponMsg = " with a " .. self.Config.left .." ".. weapon .. " ".. self.Config.right
		end
		--Dont need to deal with proper english:
		weaponLog = weapon
	else 
		weaponMsg = " "
		weaponLog = "something"
	end

	killData['weapon'] = weaponLog
    
    -- player gets killed:
    if (takedamage:GetComponent( "HumanController" ) and self.Config.player) then
    	if(damage.victim.client) then
    		
    		-- killed by AI
			if(self.Config.deathByEntity) then
				self.animal = nil;
				self.logWhere = self.Config.deathByEntity;
				
				-- need to figure out where object killer name is stored.
				if (damage.attacker.networkView == nil) then 
					self.animal = "unknown object"
					killData['vsid'] = self:tosteamid(damage.victim.client.netUser)
			    	killData['victim'] = damage.victim.client.netUser.displayName
			    	killData['vpos'] = self:getUserLocation(damage.victim.client.netUser)

					if self.logWhere == "both" or self.logWhere == "chat" then
				    	self:notifyDeath(killData['victim'] .. " ".. self.AIdeathVerbs[ math.random( #self.AIdeathVerbs ) ] .." " .. self.animal .. "!")
				    end

				    if self.logWhere == "both" or self.logWhere == "site" then
				    	self:updatesite(killData)
				    end	

				    return
				end

				if KillerAnimals[damage.attacker.networkView.gameObject.Name] then
					self.animal = KillerAnimals[damage.attacker.networkView.gameObject.Name];
				else
					if (damage.attacker.networkView.gameObject:GetComponent("BearAI") and self.Config.deathByEntity) then
				    	self.animal = "bear";
				    elseif (damage.attacker.networkView.gameObject:GetComponent( "WolfAI" ) and self.Config.deathByEntity) then
				    	self.animal = "wolf";
				    end
				end

			    if self.animal ~= nil then 
			    	
			    	killData['weapon'] = nil
			    	killData['type'] = "aikill"
			    	killData['killer'] = self.animal
			    	killData['kpos'] = self:getAILocation(damage.attacker.networkView.gameObject)
			    	killData['vsid'] = self:tosteamid(damage.victim.client.netUser)
			    	killData['victim'] = damage.victim.client.netUser.displayName
			    	killData['vpos'] = self:getUserLocation(damage.victim.client.netUser)

			    	if self.logWhere == "both" or self.logWhere == "chat" then
				    	self:notifyDeath(killData['victim'] .. " ".. self.AIdeathVerbs[ math.random( #self.AIdeathVerbs ) ] .." " .. self.animal .. "!")
				    end

				    if self.logWhere == "both" or self.logWhere == "site" then
				    	self:updatesite(killData)
				    end	

			    end

			end
		end     

		-- killed by player
        if(damage.victim.client and damage.attacker.client) then
        	self.logWhere = self.Config.player;
			local isSamePlayer = (damage.victim.client == damage.attacker.client)
			local partName = ''

			if (damage.victim.client.netUser.displayName and not isSamePlayer) then

				-- distance stuff
				aAv = damage.attacker.client.netUser:LoadAvatar()
				vAv = damage.victim.client.netUser:LoadAvatar()
				local dist = self:DistanceFromPlayers(vAv.pos,aAv.pos) 
				rust.InventoryNotice(damage.attacker.client.netUser, "Distance: " .. tostring(math.floor(dist)))
				--rust.InventoryNotice(damage.attacker.client.netUser, "Killed: " .. victimName)
				-- end distance stuff
				killData['type'] = 'playerkill'
				killData['distance'] = dist
				killData['killer'] = damage.attacker.client.netUser.displayName
				killData['ksid'] = self:tosteamid(damage.attacker.client.netUser)
				killData['kpos'] = self:getUserLocation(damage.attacker.client.netUser)
				killData['victim'] = damage.victim.client.netUser.displayName
				killData['vsid'] = self:tosteamid(damage.victim.client.netUser)
				killData['vpos'] = self:getUserLocation(damage.victim.client.netUser)
				killData['weapon'] = weaponLog;
				if (self.Config.weapon == true and self.Config.bodyPart == true) then

					if (damage.bodyPart ~= nil) then
						if(damage.bodyPart:GetType().Name == "BodyPart" and _GetNiceName(damage.bodyPart) ~= nil) then

							if _GetNiceName(damage.bodyPart) == "Hip" then 
								killData['part'] = self.wordsForPenis[ math.random( #self.wordsForPenis ) ];
							else 
								killData['part'] = _GetNiceName(damage.bodyPart);
							end
							
							if self.logWhere == "both" or self.logWhere == "chat" then
								self:notifyDeath(damage.attacker.client.netUser.displayName .. " ".. self.playerKilledVerbs[ math.random( #self.playerKilledVerbs ) ] .." " .. damage.victim.client.netUser.displayName .. weaponMsg .. " right in the " .. killData['part'] .."! {" .. dist .. "m}")
							end

							if self.logWhere == "both" or self.logWhere == "chat" then
								self:updatesite(killData)
							end

						else
							if self.logWhere == "both" or self.logWhere == "chat" then
								self:notifyDeath(damage.attacker.client.netUser.displayName .. " ".. self.playerKilledVerbs[ math.random( #self.playerKilledVerbs ) ] .." " .. damage.victim.client.netUser.displayName .. weaponMsg .. " right in the spleen! {" .. dist .. "m}")
							end

							if self.logWhere == "both" or self.logWhere == "site" then
								self:updatesite(killData)
							end


						end
						return
					end


					
				end

				if self.logWhere == "both" or self.logWhere == "chat" then
					self:notifyDeath(damage.attacker.client.netUser.displayName .. " ".. self.playerKilledVerbs[ math.random( #self.playerKilledVerbs ) ] .." " .. damage.victim.client.netUser.displayName ..  weaponMsg)
				end

				killData['weapon'] = 'something'
				killData['part'] = 'spleen'
				if self.logWhere == "both" or self.logWhere == "site" then
					self:updatesite(killData)
				end
				return
			end

			if(isSamePlayer and self.Config.suicide) then
				self.logWhere = self.Config.suicide;
				--Suicides
				local suicideMsg = self.suicideMessages[ math.random( #self.suicideMessages ) ] 

				killData['type'] = "suicide"
		    	killData['victim'] = damage.attacker.client.netUser.displayName
		    	killData['vpos'] = self:getUserLocation(damage.attacker.client.netUser)
		    	killData['vsid'] = self:tosteamid(damage.attacker.client.netUser)
		    	--print(self.logwhere);
		    	if self.logWhere == "both" or self.logWhere == "chat" then
		    		--print('sending chat');
					self:notifyDeath(damage.attacker.client.netUser.displayName .. " " .. suicideMsg)
				end

				if self.logWhere == "both" or self.logWhere == "site" then
					--print('sending to site');
					self:updatesite(killData)
				end
				
				return
			end
		end   
        return
    end

    -- object is destroyed -- this will be moved to a different plugin -- need ID to name for offline players
	    --if (takedamage:GetComponent( "DeployableObject" )) then
		--	if(damage.attacker.client) then
		--		local getDeployableOwnerId = util.GetFieldGetter(Rust.DeployableObject, "ownerID", true)
		--		local deployable = takedamage:GetComponent( "DeployableObject" )
		--		local deployableOwnerId = getDeployableOwnerId(deployable)
		--		local owner = deployable.creatorID
		--		local item = takedamage.gameObject.Name
		--		local destroyer = damage.attacker.client.netUser.displayName
		--		local tmpmsg = destroyer .. " destroyed an item (".. item ..") created by " .. owner .." ("..deployableOwnerId..") using a " ..killData['weapon']
		--		print(tmpmsg)
		--		self:notifyDeath(tmpmsg)
		--		
		--		return
		--	end
	    --end
		--	
		--if (takedamage:GetComponent ( "StructureComponent" )) then
		--	
		--	if(damage.attacker.client) then
		--		local getStructureMasterOwnerId = util.GetFieldGetter(Rust.StructureMaster, "ownerID", true)
		--		local entity = takedamage:GetComponent("StructureComponent")
		--		local master = entity._master
		--		local structureOwnerId = getStructureMasterOwnerId(master)
		--		local owner = master.creatorID
		--		local item = takedamage.gameObject.Name
		--		local destroyer = damage.attacker.client.netUser.displayName
		--		local tmpmsg = destroyer .. " destroyed an item (".. item ..") created by " .. owner .." ("..structureOwnerId..")"
		--		print(tmpmsg)
		--		self:notifyDeath(tmpmsg)
		--		return
		--	end
		--end

    -- player kills animal :
    self.animal = nil;


    if KillerAnimals[takedamage.gameObject.Name] then

		self.animal = KillerAnimals[takedamage.gameObject.Name];

		if (self.animal == "Bear" and self.Config.bear) then 
			self.logWhere = self.Config.bear;
		elseif (self.animal == "Mutant Bear" and self.Config.mutantbear) then
			self.logWhere = self.Config.mutantbear;
			killData['callback'] = 'reward';
		elseif (self.animal == "Wolf" and self.Config.wolf) then
			self.logWhere = self.Config.wolf;
		elseif (self.animal == "Mutant Wolf" and self.Config.mutantwolf) then
			self.logWhere = self.Config.mutantwolf;
			killData['callback'] = 'reward';
		end

	else

		if (takedamage:GetComponent( "BearAI" ) and self.Config.bear) then
	    	self.animal = "bear";
	    	self.logWhere = self.Config.bear;
	    elseif (takedamage:GetComponent( "WolfAI" ) and self.Config.wolf) then
	    	self.animal = "wolf";
	    	self.logWhere = self.Config.wolf;
	    elseif (takedamage:GetComponent( "StagAI" ) and self.Config.stag) then
	    	self.animal = "deer";
	    	self.logWhere = self.Config.stag;
	    elseif (takedamage:GetComponent( "ChickenAI" ) and self.Config.chicken) then
	    	self.animal = "chicken";
	    	self.logWhere = self.Config.chicken;
	    elseif (takedamage:GetComponent( "RabbitAI" ) and self.Config.rabbit) then
	    	self.animal = "bunny";
	    	self.logWhere = self.Config.rabbit;
	    elseif (takedamage:GetComponent( "BoarAI" ) and self.Config.boar) then
	    	self.animal = "pig";
	    	self.logWhere = self.Config.boar;
	    end
	end
    

    if (self.animal ~= nil) then
    	killData['type'] = "animalkill"
    	killData['victim'] = self.animal
    	killData['vpos'] = self:getAILocation(takedamage.gameObject)
    	killData['ksid'] = self:tosteamid(damage.attacker.client.netUser)
    	killData['killer'] = damage.attacker.client.netUser.displayName
    	killData['kpos'] = self:getUserLocation(damage.attacker.client.netUser)
    	killData['distance'] = self:DistanceFromPlayers(damage.attacker.client.netUser.playerClient.lastKnownPosition, takedamage.gameObject.transform.localPosition) 
    	rust.InventoryNotice(damage.attacker.client.netUser, "Distance: " .. killData['distance'] .. "m")

    	if self.logWhere == "both" or self.logWhere == "chat" then
        	self:notifyDeath(killData['killer'] .. " ".. self.animalKilledVerbs[ math.random( #self.animalKilledVerbs ) ] .. " " .. killData['victim']  ..  weaponMsg)
        end

        if self.logWhere == "both" or self.logWhere == "site" then
        	self:updatesite(killData)
        end
        
        return
    end
	
end

api.Bind( PLUGIN, "BZKillBind" )

