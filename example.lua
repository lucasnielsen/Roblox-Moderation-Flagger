local FilterModule = require(game.ServerScriptService.FilterModule)
local moderationSystem = FilterModule.new("YOUR_DISCORD_WEBHOOK_URL", "YOUR_OPENAI_API_KEY")

game.Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		local filteredMessage = game:GetService("Chat"):FilterStringForBroadcast(message, player)
		moderationSystem:moderateText(player.Name, filteredMessage)
	end)
end)
