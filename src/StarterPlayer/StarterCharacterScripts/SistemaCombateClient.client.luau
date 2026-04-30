local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local jogador = game.Players.LocalPlayer

local eventoCombate = ReplicatedStorage:WaitForChild("ControleCombate")

local emCombate = false
local bloqueando = false
local atacando = false
local comboAtual = 1
local tempoUltimoAtaque = 0
local TEMPO_RESET_COMBO = 1.2

local idAnimacoes = {
	Postura = "rbxassetid://103851672361232",
	Bloqueio = "rbxassetid://127483438138363",
	Soco1 = "rbxassetid://81738125339804",
	Soco2 = "rbxassetid://134940334146442",
	Soco3 = "rbxassetid://81738125339804",
	Soco4 = "rbxassetid://134940334146442",
	Soco5 = "rbxassetid://116840465625849",
}

local tracksCarregadas = {}

local function tocarAnimacao(id)
	local personagem = jogador.Character
	if not personagem then
		return nil
	end

	local humanoid = personagem:FindFirstChild("Humanoid")
	if not humanoid then
		return nil
	end

	local animator = humanoid:FindFirstChild("Animator")
	if not animator then
		return nil
	end

	if tracksCarregadas[id] then
		tracksCarregadas[id]:Play()
		return tracksCarregadas[id]
	end

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
	if processando then
		return
	end
	local personagem = jogador.Character
	if not personagem then
		return
	end

	-- Entrar/Sair do Modo Combate (Tecla C)
	if input.KeyCode == Enum.KeyCode.C then
		emCombate = not emCombate
		if emCombate then
			trackPostura = tocarAnimacao(idAnimacoes.Postura)
		else
			if trackPostura then
				trackPostura:Stop()
			end
			if trackBloqueio then
				trackBloqueio:Stop()
			end
			bloqueando = false
			-- Aqui dizemos ao servidor que paramos de bloquear
			eventoCombate:FireServer("Bloquear", false)
		end
	end

	-- Bloquear (Tecla F)
	if input.KeyCode == Enum.KeyCode.F and emCombate and not atacando then
		bloqueando = true
		trackBloqueio = tocarAnimacao(idAnimacoes.Bloqueio)
		-- Avisa o servidor que estamos a bloquear
		eventoCombate:FireServer("Bloquear", true)
	end

	-- Atacar (Clique Esquerdo)
	if input.UserInputType == Enum.UserInputType.MouseButton1 and emCombate and not bloqueando and not atacando then
		atacando = true

		if os.clock() - tempoUltimoAtaque > TEMPO_RESET_COMBO then
			comboAtual = 1
		end

		local idSoco = idAnimacoes["Soco" .. comboAtual]
		local trackAtaque = tocarAnimacao(idSoco)

		-- Envia o ataque para o servidor processar o dano
		eventoCombate:FireServer("Ataque", comboAtual)
		tempoUltimoAtaque = os.clock()

		-- Espera o tempo da animação de forma segura (evita encravar o Input)
		if trackAtaque and trackAtaque.Length > 0 then
			task.wait(trackAtaque.Length * 0.9)
		else
			task.wait(0.3)
		end

		if comboAtual == 5 then
			task.wait(1.2) -- O quinto soco tem um tempo de espera maior
		end

		comboAtual = comboAtual + 1
		if comboAtual > 5 then
			comboAtual = 1
		end

		atacando = false
	end
end)

UserInputService.InputEnded:Connect(function(input, processando)
	-- Para de bloquear ao soltar o F
	if input.KeyCode == Enum.KeyCode.F and emCombate then
		bloqueando = false
		if trackBloqueio then
			trackBloqueio:Stop()
		end
		-- Avisa o servidor
		eventoCombate:FireServer("Bloquear", false)
	end
end)

-- Desliga o bloqueio localmente se a estamina acabar no servidor
jogador:GetAttributeChangedSignal("Bloqueando"):Connect(function()
	local bloqueandoNoServidor = jogador:GetAttribute("Bloqueando")

	if not bloqueandoNoServidor and bloqueando then
		bloqueando = false
		if trackBloqueio then
			trackBloqueio:Stop()
		end
	end
end)
