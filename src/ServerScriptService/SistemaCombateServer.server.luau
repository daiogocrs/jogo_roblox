local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local eventoCombate = ReplicatedStorage:WaitForChild("ControleCombate")

local ALCANCE_SOCO = 5
local REDUCAO_BLOQUEIO = 0.2
local GASTO_ENERGIA_BLOQUEIO = 15
local COOLDOWN_ATAQUE = 0.3

local tempoUltimoAtaque = {}

-- MELHORIA DE PERFORMANCE: Criado apenas uma vez fora do evento!
local parametrosCombate = OverlapParams.new()
parametrosCombate.FilterType = Enum.RaycastFilterType.Exclude

eventoCombate.OnServerEvent:Connect(function(player, acao, dados)
	local personagem = player.Character
	if not personagem then
		return
	end

	if acao == "Bloquear" then
		if type(dados) ~= "boolean" then
			return
		end

		if dados == true then
			local pastaOculta = player:FindFirstChild("dadosOcultos")
			if pastaOculta and pastaOculta:FindFirstChild("EnergiaAtual") then
				if pastaOculta.EnergiaAtual.Value >= GASTO_ENERGIA_BLOQUEIO then
					player:SetAttribute("Bloqueando", true)
				else
					player:SetAttribute("Bloqueando", false)
				end
			end
		else
			player:SetAttribute("Bloqueando", false)
		end
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

		local dadosAtacante = player:FindFirstChild("dadosOcultos")
		local danoDoAtacante = 5

		if dadosAtacante and dadosAtacante:FindFirstChild("DanoBase") then
			danoDoAtacante = dadosAtacante.DanoBase.Value
		end

		parametrosCombate.FilterDescendantsInstances = { personagem }

		local posicaoHitbox = raiz.CFrame * CFrame.new(0, 0, -3)
		local partesAtingidas = workspace:GetPartBoundsInBox(posicaoHitbox, Vector3.new(4, 5, 4), parametrosCombate)

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

				-- MELHORIA DE GAMEPLAY (Hitstun perfeito):
				local velocidadeOriginal = humanoidInimigo.WalkSpeed
				humanoidInimigo.WalkSpeed = 0
				raizInimigo.AssemblyLinearVelocity = Vector3.zero

				task.delay(0.3, function()
					if humanoidInimigo and humanoidInimigo.WalkSpeed == 0 then
						humanoidInimigo.WalkSpeed = velocidadeOriginal
					end
				end)
			end
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	tempoUltimoAtaque[player.UserId] = nil
end)
