local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local PersonagensDS = DataStoreService:GetDataStore("DadosJogadores_V1")

local GerenciadorSessao = require(script.Parent:WaitForChild("ModulosServidor"):WaitForChild("GerenciadorSessao"))

Players.PlayerAdded:Connect(function(player)
	local chaveDS = tostring(player.UserId)
	local sucesso, dados = pcall(function() return PersonagensDS:GetAsync(chaveDS) end)

	if sucesso and dados then
		GerenciadorSessao.Definir(player.UserId, dados)
	else
		GerenciadorSessao.Definir(player.UserId, nil) 
	end
end)

Players.PlayerRemoving:Connect(function(player)
	local dadosLocais = GerenciadorSessao.Obter(player.UserId)
	if dadosLocais then
		pcall(function() PersonagensDS:SetAsync(tostring(player.UserId), dadosLocais) end)
	end
	GerenciadorSessao.Remover(player.UserId)
end)

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		local dadosLocais = GerenciadorSessao.Obter(player.UserId)
		if dadosLocais then
			pcall(function() PersonagensDS:SetAsync(tostring(player.UserId), dadosLocais) end)
		end
	end
	task.wait(2) 
end)