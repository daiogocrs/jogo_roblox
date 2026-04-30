local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ProfileService = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("ProfileService"))
local GerenciadorSessao = require(script.Parent:WaitForChild("ModulosServidor"):WaitForChild("GerenciadorSessao"))

local TemplateDados = {
	Nome = "Desconhecido",
	Genero = "Masculino",
	Cabelo = 0,
	Camisa = 0,
	Calca = 0,
	Raca = "Humano",
	CorPele = "#EEC196",
	Nivel = 1,
	XP = 0,
	XPMaximo = 100,
}

local ProfileStore = ProfileService.GetProfileStore("DadosJogadores", TemplateDados)

local Profiles = {}

local function PlayerAdded(player)
	local profile = ProfileStore:LoadProfileAsync("Player_" .. player.UserId)

	if profile ~= nil then
		profile:AddUserId(player.UserId)
		profile:Reconcile()

		profile:ListenToRelease(function()
			Profiles[player] = nil
			player:Kick("Seus dados foram carregados em outro servidor. Por favor, reconecte.")
		end)

		if player:IsDescendantOf(Players) then
			Profiles[player] = profile
			GerenciadorSessao.Definir(player.UserId, profile.Data)
		else
			profile:Release()
		end
	else
		player:Kick("Não foi possível carregar seus dados. Tente novamente.")
	end
end

Players.PlayerAdded:Connect(PlayerAdded)

Players.PlayerRemoving:Connect(function(player)
	local profile = Profiles[player]
	if profile then
		local dadosAtuais = GerenciadorSessao.Obter(player.UserId)
		if dadosAtuais then
			for chave, valor in pairs(dadosAtuais) do
				profile.Data[chave] = valor
			end
		end
		profile:Release()
	end
	GerenciadorSessao.Remover(player.UserId)
end)

local eventoApagar = Instance.new("BindableEvent")
eventoApagar.Name = "ApagarDadosConta"
eventoApagar.Parent = ReplicatedStorage

eventoApagar.Event:Connect(function(player)
	local profile = Profiles[player]
	if profile then
		profile:Release()
		Profiles[player] = nil
		ProfileStore:WipeProfileAsync("Player_" .. player.UserId)
		print("Dados de " .. player.Name .. " apagados com sucesso!")
	end
end)

game:BindToClose(function()
	for _, profile in pairs(Profiles) do
		if profile ~= nil then
			profile:Release()
		end
	end
end)
