local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProfileService = require(ReplicatedStorage.Packages.ProfileService)
local Promise = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Promise"))

local ConfigGerais = require(ReplicatedStorage:WaitForChild("ModulosCompartilhados"):WaitForChild("ConfigGerais"))
local GerenciadorSessao = require(script.Parent:WaitForChild("ModulosServidor"):WaitForChild("GerenciadorSessao"))
local StatusMath = require(script.Parent:WaitForChild("ModulosServidor"):WaitForChild("StatusMath"))

local eventoMenu = ReplicatedStorage:WaitForChild("EventoMenu")
local eventoEscolha = ReplicatedStorage:WaitForChild("EscolhaGenero")
local eventoDeletar = ReplicatedStorage:WaitForChild("DeletarPersonagem")

local function atualizarStatus(player)
	local dados = player:FindFirstChild("dadosOcultos")
	local character = player.Character

	if dados and character and character:FindFirstChild("Humanoid") then
		local atributos = StatusMath.calcularAtributos(dados.Nivel.Value, dados.Raca.Value)

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

-- ==========================================
-- CARREGAMENTO DO BONECO
-- ==========================================
Players.PlayerAdded:Connect(function(player)
	local dadosOcultos = Instance.new("Folder")
	dadosOcultos.Name = "dadosOcultos"
	dadosOcultos.Parent = player

	local nivel = Instance.new("IntValue")
	nivel.Name = "Nivel"
	nivel.Value = 1
	nivel.Parent = dadosOcultos

	local xp = Instance.new("IntValue")
	xp.Name = "XP"
	xp.Value = 0
	xp.Parent = dadosOcultos

	local xpMaximo = Instance.new("IntValue")
	xpMaximo.Name = "XPMaximo"
	xpMaximo.Value = 100
	xpMaximo.Parent = dadosOcultos

	local vidaMaxima = Instance.new("IntValue")
	vidaMaxima.Name = "VidaMaxima"
	vidaMaxima.Value = 100
	vidaMaxima.Parent = dadosOcultos

	local danoBase = Instance.new("IntValue")
	danoBase.Name = "DanoBase"
	danoBase.Value = 5
	danoBase.Parent = dadosOcultos

	local energiaMaxima = Instance.new("IntValue")
	energiaMaxima.Name = "EnergiaMaxima"
	energiaMaxima.Value = 100
	energiaMaxima.Parent = dadosOcultos

	local energiaAtual = Instance.new("IntValue")
	energiaAtual.Name = "EnergiaAtual"
	energiaAtual.Value = 100
	energiaAtual.Parent = dadosOcultos

	local agilidade = Instance.new("IntValue")
	agilidade.Name = "Agilidade"
	agilidade.Value = 16
	agilidade.Parent = dadosOcultos

	local raca = Instance.new("StringValue")
	raca.Name = "Raca"
	raca.Value = "Humano"
	raca.Parent = dadosOcultos

	local function sincronizarSessao(nomeTag, valor)
		local dadosSessao = GerenciadorSessao.Obter(player.UserId)
		if dadosSessao then
			dadosSessao[nomeTag] = valor
			GerenciadorSessao.Definir(player.UserId, dadosSessao)
		end
	end

	for _, tag in ipairs(dadosOcultos:GetChildren()) do
		tag.Changed:Connect(function()
			sincronizarSessao(tag.Name, tag.Value)
		end)
	end

	player.CharacterAdded:Connect(function(character)
		local dadosLocais = GerenciadorSessao.Obter(player.UserId)

		if dadosLocais then
			local humanoid = character:WaitForChild("Humanoid")
			task.wait(0.3)

			humanoid.DisplayName = dadosLocais.Nome
			local tagNome = player:FindFirstChild("NomeFalso") or Instance.new("StringValue")
			tagNome.Name = "NomeFalso"
			tagNome.Value = dadosLocais.Nome
			tagNome.Parent = player

			local tagRaca = dadosOcultos:FindFirstChild("Raca")
			if tagRaca then
				tagRaca.Value = dadosLocais.Raca
			end

			if dadosLocais.Nivel then
				dadosOcultos.Nivel.Value = dadosLocais.Nivel
			end
			if dadosLocais.XP then
				dadosOcultos.XP.Value = dadosLocais.XP
			end
			if dadosLocais.XPMaximo then
				dadosOcultos.XPMaximo.Value = dadosLocais.XPMaximo
			end

			local description = Instance.new("HumanoidDescription")
			description.HairAccessory = tostring(dadosLocais.Cabelo)
			description.Shirt = dadosLocais.Camisa
			description.Pants = dadosLocais.Calca
			local corTransformada = Color3.fromHex(dadosLocais.CorPele or "#EEC196")

			description.HeadColor = corTransformada
			description.TorsoColor = corTransformada
			description.LeftArmColor = corTransformada
			description.RightArmColor = corTransformada
			description.LeftLegColor = corTransformada
			description.RightLegColor = corTransformada

			Promise.try(function()
				humanoid:ApplyDescription(description)
			end)
				:andThen(function()
					print("Aparência de", player.Name, "carregada com sucesso!")
					atualizarStatus(player)
				end)
				:catch(function(erro)
					warn("Falha ao carregar aparência, o Roblox pode estar com instabilidade:", erro)
					atualizarStatus(player)
				end)
		end
	end)
end)

-- ==========================================
-- EVENTOS DO CLIENTE
-- ==========================================
eventoMenu.OnServerEvent:Connect(function(player, acao)
	if acao == "VerificarConta" then
		local dadosSessao = GerenciadorSessao.Obter(player.UserId)
		local tentativas = 0

		while dadosSessao == nil and tentativas < 50 do
			task.wait(0.1)
			dadosSessao = GerenciadorSessao.Obter(player.UserId)
			tentativas += 1
		end

		if dadosSessao and dadosSessao.Nome ~= "Desconhecido" then
			eventoMenu:FireClient(player, true)
		else
			eventoMenu:FireClient(player, false)
		end
	elseif acao == "Iniciar" then
		player:LoadCharacter()
	end
end)

eventoDeletar.OnServerEvent:Connect(function(player)
	if _G.WipeAccount then
		_G.WipeAccount(player)
	end

	GerenciadorSessao.Remover(player.UserId)

	local tagNome = player:FindFirstChild("NomeFalso")
	if tagNome then
		tagNome:Destroy()
	end

	local dadosOcultos = player:FindFirstChild("dadosOcultos")
	if dadosOcultos then
		if dadosOcultos:FindFirstChild("Nivel") then
			dadosOcultos.Nivel.Value = 1
		end
		if dadosOcultos:FindFirstChild("XP") then
			dadosOcultos.XP.Value = 0
		end
		if dadosOcultos:FindFirstChild("XPMaximo") then
			dadosOcultos.XPMaximo.Value = 100
		end
		if dadosOcultos:FindFirstChild("VidaMaxima") then
			dadosOcultos.VidaMaxima.Value = 100
		end
		if dadosOcultos:FindFirstChild("DanoBase") then
			dadosOcultos.DanoBase.Value = 5
		end
		if dadosOcultos:FindFirstChild("EnergiaMaxima") then
			dadosOcultos.EnergiaMaxima.Value = 100
		end
		if dadosOcultos:FindFirstChild("EnergiaAtual") then
			dadosOcultos.EnergiaAtual.Value = 100
		end
		if dadosOcultos:FindFirstChild("Agilidade") then
			dadosOcultos.Agilidade.Value = 16
		end
		if dadosOcultos:FindFirstChild("Raca") then
			dadosOcultos.Raca.Value = "Humano"
		end
	end
	eventoMenu:FireClient(player, false)
end)

eventoEscolha.OnServerEvent:Connect(function(player, genero)
	local nomeSorteado = ""
	local cabeloSorteado = 0

	if genero == "Masculino" then
		nomeSorteado = ConfigGerais.nomesMasculinos[math.random(1, #ConfigGerais.nomesMasculinos)]
			.. " "
			.. ConfigGerais.sobrenomes[math.random(1, #ConfigGerais.sobrenomes)]
		cabeloSorteado = ConfigGerais.idsCabeloMasc[math.random(1, #ConfigGerais.idsCabeloMasc)]
	else
		nomeSorteado = ConfigGerais.nomesFemininos[math.random(1, #ConfigGerais.nomesFemininos)]
			.. " "
			.. ConfigGerais.sobrenomes[math.random(1, #ConfigGerais.sobrenomes)]
		cabeloSorteado = ConfigGerais.idsCabeloFem[math.random(1, #ConfigGerais.idsCabeloFem)]
	end

	local dadosPersonagem = {
		Nome = nomeSorteado,
		Genero = genero,
		Cabelo = cabeloSorteado,
		Camisa = ConfigGerais.idsCamisa[math.random(1, #ConfigGerais.idsCamisa)],
		Calca = ConfigGerais.idsCalca[math.random(1, #ConfigGerais.idsCalca)],
		Raca = ConfigGerais.sortearRaca(),
		CorPele = ConfigGerais.coresPeleHex[math.random(1, #ConfigGerais.coresPeleHex)],
		Nivel = 1,
		XP = 0,
		XPMaximo = 100,
	}

	GerenciadorSessao.Definir(player.UserId, dadosPersonagem)

	player:LoadCharacter()
end)
