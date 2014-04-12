PLUGIN.Title = "BZForce"
PLUGIN.Description = "force certain settings on load"
PLUGIN.Version = "1.0"
PLUGIN.Author = "BadZombi"

function PLUGIN:OnUserConnect( netuser )
	rust.RunClientCommand(netuser, "censor.nudity false ") -- Nudity On
	rust.RunClientCommand(netuser, "grass.on false") -- grass off
	rust.RunClientCommand(netuser, "gui.hide_branding") -- hide alpha banner
end