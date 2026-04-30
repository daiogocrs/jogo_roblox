local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

local PersonagensDS = DataStoreService:GetDataStore("DadosJogadores_V2")
local ConfigGerais = require(ReplicatedStorage:WaitForChild("ModulosCompartilhados"):WaitForChild("ConfigGerais"))
local GerenciadorSessao = require(script.Parent:WaitForChild("ModulosServidor"):WaitForChild("GerenciadorSessao"))
local StatusMath = require(script.Parent:WaitForChild("ModulosServidor"):WaitForChild("StatusMath"))

local function atualizarStatusVisual(player)
	local dados = player:FindFirstChild("dadosOcultos")
	local character = player.Character

	if dados and character and character:FindFirstChild("Humanoid") then
		local nivel = dados.Nivel.Value
		local raca = dados.Raca.Value
		local atributos = StatusMath.calcularAtributos(nivel, raca)

		dados.VidaMaxima.Value = atributos.vidaMaxima
		dados.DanoBase.Value = atributos.danoBase
		dados.EnergiaMaxima.Value = atributos.energiaMaxima
		dados.Agilidade.Value = atributos.agilidade
		if dados:FindFirstChild("EnergiaAtual") then
			dados.EnergiaAtual.Value = atributos.energiaMaxima
		end

		local humanoid = character.Humanoid
		humanoid.MaxHealth = atributos.vidaMaxima
		humanoid.Health = atributos.vidaMaxima
		humanoid.WalkSpeed = atributos.agilidade
	end
end

MarketplaceService.ProcessReceipt = function(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local dadosLocais = GerenciadorSessao.Obter(player.UserId)
	if not dadosLocais then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	if receiptInfo.ProductId == ConfigGerais.ID_ROLETAR_NOME then
		if dadosLocais.Genero == "Masculino" then
			dadosLocais.Nome = ConfigGerais.nomesMasculinos[math.random(1, #ConfigGerais.nomesMasculinos)]
				.. " "
				.. ConfigGerais.sobrenomes[math.random(1, #ConfigGerais.sobrenomes)]
		else
			dadosLocais.Nome = ConfigGerais.nomesFemininos[math.random(1, #ConfigGerais.nomesFemininos)]
				.. " "
				.. ConfigGerais.sobrenomes[math.random(1, #ConfigGerais.sobrenomes)]
		end

		local tagNome = player:FindFirstChild("NomeFalso") or Instance.new("StringValue")
		tagNome.Name = "NomeFalso"
		tagNome.Value = dadosLocais.Nome
		tagNome.Parent = player

		if player.Character and player.Character:FindFirstChild("Humanoid") then
			player.Character.Humanoid.DisplayName = dadosLocais.Nome
		end
	elseif receiptInfo.ProductId == ConfigGerais.ID_ROLETAR_RACA then
		dadosLocais.Raca = ConfigGerais.sortearRaca()
		local dadosOcultos = player:FindFirstChild("dadosOcultos")
		if dadosOcultos then
			local tagRaca = dadosOcultos:FindFirstChild("Raca") or Instance.new("StringValue")
			tagRaca.Name = "Raca"
			tagRaca.Value = dadosLocais.Raca
			tagRaca.Parent = dadosOcultos
		end
		atualizarStatusVisual(player)
	end

	GerenciadorSessao.Definir(player.UserId, dadosLocais)

	player:LoadCharacter()
	return Enum.ProductPurchaseDecision.PurchaseGranted
end
