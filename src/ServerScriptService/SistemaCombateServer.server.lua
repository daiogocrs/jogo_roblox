local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local eventoCombate = ReplicatedStorage:WaitForChild("ControleCombate")

-- Configurações de Dano e Defesa
local ALCANCE_SOCO = 5 
local REDUCAO_BLOQUEIO = 0.2 
local GASTO_ENERGIA_BLOQUEIO = 15 
local COOLDOWN_ATAQUE = 0.3 -- Tempo mínimo entre os socos aceito pelo servidor

-- Dicionário para proteger contra spammers de ataque
local tempoUltimoAtaque = {}

eventoCombate.OnServerEvent:Connect(function(player, acao, dados)
	local personagem = player.Character
	if not personagem then return end

	if acao == "Bloquear" then
		player:SetAttribute("Bloqueando", dados) 
		return
	end

	if acao == "Ataque" then
		-- SISTEMA DE SEGURANÇA (Anti-Spam)
		local tempoAtual = os.clock()
		local ultimoAtaque = tempoUltimoAtaque[player.UserId] or 0

		if (tempoAtual - ultimoAtaque) < COOLDOWN_ATAQUE then
			return -- Ignora o ataque: o jogador atacou rápido demais (Exploit ou Lag)
		end
		tempoUltimoAtaque[player.UserId] = tempoAtual

		local raiz = personagem:FindFirstChild("HumanoidRootPart")
		if not raiz then return end

		local dadosAtacante = player:FindFirstChild("dadosOcultos")
		local danoDoAtacante = 5 

		if dadosAtacante and dadosAtacante:FindFirstChild("DanoBase") then
			danoDoAtacante = dadosAtacante.DanoBase.Value
		end

		local parametros = OverlapParams.new()
		parametros.FilterDescendantsInstances = {personagem} 
		parametros.FilterType = Enum.RaycastFilterType.Exclude

		local posicaoHitbox = raiz.CFrame * CFrame.new(0, 0, -3)
		local partesAtingidas = workspace:GetPartBoundsInBox(posicaoHitbox, Vector3.new(4, 5, 4), parametros)

		local inimigosAtingidos = {}

		for _, parte in ipairs(partesAtingidas) do
			local modeloInimigo = parte.Parent
			local humanoidInimigo = modeloInimigo:FindFirstChild("Humanoid")

			if humanoidInimigo and humanoidInimigo.Health > 0 and not inimigosAtingidos[modeloInimigo] then
				inimigosAtingidos[modeloInimigo] = true

				local danoCalculado = danoDoAtacante
				local jogadorInimigo = Players:GetPlayerFromCharacter(modeloInimigo)

				if jogadorInimigo and jogadorInimigo:GetAttribute("Bloqueando") == true then
					danoCalculado = danoDoAtacante * REDUCAO_BLOQUEIO 

					local pastaOculta = jogadorInimigo:FindFirstChild("dadosOcultos")
					if pastaOculta and pastaOculta:FindFirstChild("EnergiaAtual") then
						local energiaAtual = pastaOculta.EnergiaAtual.Value
						pastaOculta.EnergiaAtual.Value = math.max(0, energiaAtual - GASTO_ENERGIA_BLOQUEIO)

						if pastaOculta.EnergiaAtual.Value == 0 then
							jogadorInimigo:SetAttribute("Bloqueando", false)
						end
					end
				end

				humanoidInimigo:TakeDamage(danoCalculado)
			end
		end
	end
end)

-- Limpa a memória quando o jogador sai
Players.PlayerRemoving:Connect(function(player)
	tempoUltimoAtaque[player.UserId] = nil
end)