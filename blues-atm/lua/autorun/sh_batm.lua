--Id's used via net message to identify the message type
BATM_NET_COMMANDS = {
	--Client to server
	selectAccount = 1,
	deposit       = 2,
	withdraw      = 3,
	transfer      = 4,
	kickUser      = 5,
	addUser       = 6,

	--Server to client
	receiveAccountInfo = 50,
}

timer.Simple(0.01, function()
	DarkRP.createEntity("Chip 'n' Pin", {
		ent = "atm_reader",
		model = "models/bluesatm/atm_reader.mdl",
		price = 500,
		max = 8,
		cmd = "buychpnpin",
	})
end)
 