local Filter = {}
Filter.__index = Filter

function Filter.new(discordWebhookUrl, apiKey)
	local self = setmetatable({}, Filter)
	self.discordWebhookUrl = discordWebhookUrl
	self.apiKey = apiKey
	return self
end

function Filter:sendDiscordNotification(playerName, text, results)
	local fields = {}
	for category, flagged in pairs(results.categories) do
		local name = category:gsub("/", " - "):gsub("^%l", string.upper)
		local score = math.floor(results.category_scores[category] * 10 + 0.5) / 10 -- Inline rounding
		local value = flagged and "Yes" or "No"
		table.insert(fields, {
			name = "**" .. name .. ":**",
			value = "*" .. value .. " | Score: " .. tostring(score) .. "*",
			inline = true
		})
	end

	local discordPayload = {
		["embeds"] = {{
			["title"] = "Moderation Result: " .. playerName,
			["description"] = "**Message:** " .. text,
			["color"] = 0xFF5733,
			["fields"] = fields
		}}
	}

	local discordBody = game:GetService("HttpService"):JSONEncode(discordPayload)
	local headers = {
		["Content-Type"] = "application/json"
	}

	local success, response = pcall(function()
		return game:GetService("HttpService"):RequestAsync({
			Url = self.discordWebhookUrl,
			Method = "POST",
			Headers = headers,
			Body = discordBody
		})
	end)

	if not success then
		warn("Discord failed: "..response)
	end
end

function Filter:moderateText(playerName, text)
	local url = "https://api.openai.com/v1/moderations"
	local headers = {
		["Content-Type"] = "application/json",
		["Authorization"] = "Bearer " .. self.apiKey
	}
	local payload = {
		input = text
	}
	local body = game:GetService("HttpService"):JSONEncode(payload)

	local success, response = pcall(function()
		return game:GetService("HttpService"):RequestAsync({
			Url = url,
			Method = "POST",
			Headers = headers,
			Body = body
		})
	end)

	if success then
		local responseData = game:GetService("HttpService"):JSONDecode(response.Body)
		if responseData and responseData.results and responseData.results[1].flagged then
			self:sendDiscordNotification(playerName, text, responseData.results[1])
		end
	else
		warn("OpenAI failed: " .. response)
	end
end

return Filter
