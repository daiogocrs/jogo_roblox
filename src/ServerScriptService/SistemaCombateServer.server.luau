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

		if dados == true then
			if player:GetAttribute("Stunned") == true then
				return
			end

			local dadosAtacante = player:FindFirstChild("dadosOcultos")
			if dadosAtacante and dadosAtacante:FindFirstChild("EnergiaAtual") then
				if dadosAtacante.EnergiaAtual.Value < GASTO_ENERGIA_BLOQUEIO then
					return
				end
			end
		end

		player:SetAttribute("Bloqueando", dados)
		return
	end

	if acao == "Ataque" then
		local comboHit = type(dados) == "number" and dados or 1

		local tempoAtual = os.clock()
		local ultimoAtaque = tempoUltimoAtaque[player.UserId] or 0

		local cooldownNecessario = (player:GetAttribute("UltimoCombo") == 5) and 1.5 or COOLDOWN_ATAQUE

		if (tempoAtual - ultimoAtaque) < cooldownNecessario then
			return
		end

		tempoUltimoAtaque[player.UserId] = tempoAtual
		player:SetAttribute("UltimoCombo", comboHit)

		local raiz = personagem:FindFirstChild("HumanoidRootPart")
		if not raiz then
			return
		end

		local dadosAtacante = player:FindFirstChild("dadosOcultos")
		local danoDoAtacante = 5
		if dadosAtacante and dadosAtacante:FindFirstChild("DanoBase") then
			danoDoAtacante = dadosAtacante.DanoBase.Value
		end

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

				if comboHit == 5 then
					danoCalculado = danoCalculado * 1.5
				end

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

				if comboHit == 5 and raizInimigo then
					local direcaoEmpurrao = (raizInimigo.Position - raiz.Position).Unit
					local forcaEsmagadora = direcaoEmpurrao * 50 + Vector3.new(0, 20, 0)

					raizInimigo.AssemblyLinearVelocity = forcaEsmagadora
				end

				humanoidInimigo.WalkSpeed = 0
				if jogadorInimigo then
					jogadorInimigo:SetAttribute("Stunned", true)
				end

				task.delay(0.3, function()
					if humanoidInimigo then
						if jogadorInimigo then
							jogadorInimigo:SetAttribute("Stunned", false)

							local dadosOcultos = jogadorInimigo:FindFirstChild("dadosOcultos")
							if dadosOcultos and dadosOcultos:FindFirstChild("Agilidade") then
								humanoidInimigo.WalkSpeed = dadosOcultos.Agilidade.Value
							else
								humanoidInimigo.WalkSpeed = 16
							end
						else
							humanoidInimigo.WalkSpeed = 16
						end
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
