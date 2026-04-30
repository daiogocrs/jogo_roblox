local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local TAXA_RECUPERACAO = 5 -- Recupera 5 pontos de energia por segundo

RunService.Heartbeat:Connect(function(deltaTime)
	for _, player in ipairs(Players:GetPlayers()) do
		-- Pegamos os atributos direto da memória (super rápido!)
		local energiaAtual = player:GetAttribute("EnergiaAtual")
		local energiaMaxima = player:GetAttribute("EnergiaMaxima")

		if energiaAtual and energiaMaxima then
			if energiaAtual < energiaMaxima then
				-- A mágica do deltaTime: Recuperação 100% suave
				local novaEnergia = math.min(energiaMaxima, energiaAtual + (TAXA_RECUPERACAO * deltaTime))
				player:SetAttribute("EnergiaAtual", novaEnergia)
			end
		end
	end
end)
