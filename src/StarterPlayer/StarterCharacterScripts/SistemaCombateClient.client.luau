local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local jogador = game.Players.LocalPlayer

local eventoCombate = ReplicatedStorage:WaitForChild("ControleCombate")

-- Variáveis de Estado
local emCombate = false
local bloqueando = false
local atacando = false
local comboAtual = 1
local tempoUltimoAtaque = 0
local TEMPO_RESET_COMBO = 1.2

-- IDs das Animações (Substitua pelos IDs das suas animações criadas/compradas depois)
local idAnimacoes = {
	Postura = "rbxassetid://103851672361232",
	Bloqueio = "rbxassetid://127483438138363", 
	Soco1 = "rbxassetid://81738125339804",
	Soco2 = "rbxassetid://134940334146442", 
	Soco3 = "rbxassetid://81738125339804", 
	Soco4 = "rbxassetid://134940334146442", 
	Soco5 = "rbxassetid://116840465625849"  
}

local tracksCarregadas = {}

-- Função para carregar uma animação no personagem
local function tocarAnimacao(id)
	local personagem = jogador.Character
	if not personagem then return nil end
	local humanoid = personagem:FindFirstChild("Humanoid")
	local animator = humanoid:FindFirstChild("Animator")
	if not animator then return nil end

	-- Se a animação já foi carregada antes, apenas dá o play!
	if tracksCarregadas[id] then
		tracksCarregadas[id]:Play()
		return tracksCarregadas[id]
	end

	-- Se não, cria, carrega, salva no cache e dá o play
	local anim = Instance.new("Animation")
	anim.AnimationId = id
	local track = animator:LoadAnimation(anim)
	
	tracksCarregadas[id] = track
	track:Play()
	
	return track
end

local trackPostura = nil
local trackBloqueio = nil

UserInputService.InputBegan:Connect(function(input, processando)
	if processando then return end
	local personagem = jogador.Character
	if not personagem then return end

	-- Entrar/Sair do Modo Combate (Tecla C)
	if input.KeyCode == Enum.KeyCode.C then
		emCombate = not emCombate
		if emCombate then
			trackPostura = tocarAnimacao(idAnimacoes.Postura)
		else
			if trackPostura then trackPostura:Stop() end
			if trackBloqueio then trackBloqueio:Stop() end
			bloqueando = false
			eventoCombate:FireServer("Bloquear", false)
		end
	end

	-- Iniciar Bloqueio (Tecla F)
	if input.KeyCode == Enum.KeyCode.F and emCombate and not atacando then
		bloqueando = true
		trackBloqueio = tocarAnimacao(idAnimacoes.Bloqueio)
		eventoCombate:FireServer("Bloquear", true)
	end

	-- Atacar (Botão Esquerdo do Mouse)
	if input.UserInputType == Enum.UserInputType.MouseButton1 and emCombate and not bloqueando and not atacando then
		atacando = true

		-- Verifica se demorou muito para dar o próximo soco e reseta o combo
		if tick() - tempoUltimoAtaque > TEMPO_RESET_COMBO then
			comboAtual = 1
		end

		-- Toca a animação do soco atual
		local idSoco = idAnimacoes["Soco" .. comboAtual]
		local trackAtaque = tocarAnimacao(idSoco)

		-- Avisa o servidor para causar dano!
		eventoCombate:FireServer("Ataque", comboAtual)
		tempoUltimoAtaque = tick()

		-- Espera a animação de soco terminar
		if trackAtaque then
			trackAtaque.Stopped:Wait()
		else
			task.wait(0.3) -- Tempo de segurança caso não tenha animação ainda
		end

		-- Prepara para o próximo soco (até o máximo de 5)
		comboAtual = comboAtual + 1
		if comboAtual > 5 then
			comboAtual = 1
		end

		atacando = false
	end
end)

-- Soltar o Bloqueio (Quando o jogador soltar a tecla F)
UserInputService.InputEnded:Connect(function(input, processando)
	if input.KeyCode == Enum.KeyCode.F and emCombate then
		bloqueando = false
		if trackBloqueio then trackBloqueio:Stop() end
		eventoCombate:FireServer("Bloquear", false)
	end
end)

jogador:GetAttributeChangedSignal("Bloqueando"):Connect(function()
	local bloqueandoNoServidor = jogador:GetAttribute("Bloqueando")

	if not bloqueandoNoServidor and bloqueando then
		bloqueando = false
		if trackBloqueio then 
			trackBloqueio:Stop() 
		end
	end
end)