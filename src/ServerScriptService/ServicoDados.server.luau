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

local ProfileStore = ProfileService.GetProfileStore("DadosJogadores_V2", TemplateDados)

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
			profile.Data = dadosAtuais
		end
		profile:Release()
	end
	GerenciadorSessao.Remover(player.UserId)
end)

local function WipeAccount(player)
	local profile = Profiles[player]
	if profile then
		profile:Release()
		Profiles[player] = nil
		ProfileStore:WipeProfileAsync("Player_" .. player.UserId)
	end
end
_G.WipeAccount = WipeAccount
