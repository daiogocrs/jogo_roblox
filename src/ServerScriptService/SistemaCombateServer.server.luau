local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local eventoCombate = ReplicatedStorage:WaitForChild("ControleCombate")

local ALCANCE_SOCO = 5
local REDUCAO_BLOQUEIO = 0.2
local GASTO_ENERGIA_BLOQUEIO = 15
local COOLDOWN_ATAQUE = 0.3

local tempoUltimoAtaque = {}

eventoCombate.OnServerEvent:Connect(function(player, acao, dados)
	local personagem = player.Character
	if not personagem then
		return
	end

	if acao == "Bloquear" then
		if type(dados) ~= "boolean" then
			return
		end
		player:SetAttribute("Bloqueando", dados)
		return
	end

	if acao == "Ataque" then
		local tempoAtual = os.clock()
		local ultimoAtaque = tempoUltimoAtaque[player.UserId] or 0

		if (tempoAtual - ultimoAtaque) < COOLDOWN_ATAQUE then
			return
		end
		tempoUltimoAtaque[player.UserId] = tempoAtual

		local raiz = personagem:FindFirstChild("HumanoidRootPart")
		if not raiz then
			return
		end

		local danoDoAtacante = player:GetAttribute("DanoBase") or 5

		local parametros = OverlapParams.new()
		parametros.FilterDescendantsInstances = { personagem }
		parametros.FilterType = Enum.RaycastFilterType.Exclude

		local posicaoHitbox = raiz.CFrame * CFrame.new(0, 0, -3)
		local partesAtingidas = workspace:GetPartBoundsInBox(posicaoHitbox, Vector3.new(4, 5, 4), parametros)

		local inimigosAtingidos = {}

		for _, parte in ipairs(partesAtingidas) do
			local modeloInimigo = parte.Parent
			local humanoidInimigo = modeloInimigo:FindFirstChild("Humanoid")
			local raizInimigo = modeloInimigo:FindFirstChild("HumanoidRootPart")

			if
				humanoidInimigo
				and raizInimigo
				and humanoidInimigo.Health > 0
				and not inimigosAtingidos[modeloInimigo]
			then
				local distancia = (raiz.Position - raizInimigo.Position).Magnitude
				if distancia > (ALCANCE_SOCO + 3) then
					continue
				end

				inimigosAtingidos[modeloInimigo] = true

				local danoCalculado = danoDoAtacante
				local jogadorInimigo = Players:GetPlayerFromCharacter(modeloInimigo)

				if jogadorInimigo and jogadorInimigo:GetAttribute("Bloqueando") == true then
					danoCalculado = danoDoAtacante * REDUCAO_BLOQUEIO

					local energiaAtual = jogadorInimigo:GetAttribute("EnergiaAtual")

					if energiaAtual then
						-- Reduz a energia baseada no gasto de bloqueio
						jogadorInimigo:SetAttribute("EnergiaAtual", math.max(0, energiaAtual - GASTO_ENERGIA_BLOQUEIO))

						-- Se a energia zerar, quebra o bloqueio
						if jogadorInimigo:GetAttribute("EnergiaAtual") == 0 then
							jogadorInimigo:SetAttribute("Bloqueando", false)
						end
					end
				end

				humanoidInimigo:TakeDamage(danoCalculado)

				local velocidadeOriginal = humanoidInimigo.WalkSpeed
				humanoidInimigo.WalkSpeed = 0
				task.delay(0.3, function()
					if humanoidInimigo and humanoidInimigo.WalkSpeed == 0 then
						humanoidInimigo.WalkSpeed = velocidadeOriginal
					end
				end)
			end
		end
	end
end)

-- Limpa a memória quando o jogador sai
Players.PlayerRemoving:Connect(function(player)
	tempoUltimoAtaque[player.UserId] = nil
end)
