local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local eventoCombate = ReplicatedStorage:WaitForChild("ControleCombate")

local ALCANCE_SOCO = 5
local REDUCAO_BLOQUEIO = 0.2
local GASTO_ENERGIA_BLOQUEIO = 15
local COOLDOWN_ATAQUE = 0.3
local TEMPO_RESET_COMBO = 1.2

local registroCombate = {}

local function iniciarRegistro(player)
	registroCombate[player.UserId] = {
		ultimoAtaque = 0,
		combo = 1,
		cooldown = 0,
	}
end

Players.PlayerAdded:Connect(iniciarRegistro)

Players.PlayerRemoving:Connect(function(player)
	registroCombate[player.UserId] = nil
end)

local parametrosAtaque = OverlapParams.new()
parametrosAtaque.FilterType = Enum.RaycastFilterType.Exclude

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
		local registro = registroCombate[player.UserId]
		if not registro then
			iniciarRegistro(player)
			registro = registroCombate[player.UserId]
		end

		local tempoAtual = os.clock()

		if tempoAtual < registro.ultimoAtaque + registro.cooldown then
			return
		end

		if tempoAtual - registro.ultimoAtaque > TEMPO_RESET_COMBO then
			registro.combo = 1
		end

		local hitAtual = registro.combo

		if hitAtual == 5 then
			registro.cooldown = 1.5
		else
			registro.cooldown = COOLDOWN_ATAQUE
		end

		registro.ultimoAtaque = tempoAtual

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

		parametrosAtaque.FilterDescendantsInstances = { personagem }

		local posicaoHitbox = raiz.CFrame * CFrame.new(0, 0, -3)
		local partesAtingidas = workspace:GetPartBoundsInBox(posicaoHitbox, Vector3.new(4, 5, 4), parametrosAtaque)

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

				if hitAtual == 5 then
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

				if hitAtual == 5 and raizInimigo then
					local direcaoEmpurrao = (raizInimigo.Position - raiz.Position).Unit
					local forcaEsmagadora = direcaoEmpurrao * 50 + Vector3.new(0, 20, 0)

					raizInimigo.AssemblyLinearVelocity = forcaEsmagadora
				end

				modeloInimigo:SetAttribute("UltimoStun", tempoAtual)
				humanoidInimigo.WalkSpeed = 0
				if jogadorInimigo then
					jogadorInimigo:SetAttribute("Stunned", true)
				end

				local velocidadeAnterior = humanoidInimigo.WalkSpeed
				humanoidInimigo.WalkSpeed = 0
				if jogadorInimigo then
					jogadorInimigo:SetAttribute("Stunned", true)
				end

				task.delay(0.3, function()
					if modeloInimigo:GetAttribute("UltimoStun") == tempoAtual then
						if humanoidInimigo then
							if jogadorInimigo then
								jogadorInimigo:SetAttribute("Stunned", false)
							end
							humanoidInimigo.WalkSpeed = velocidadeAnterior
						end
					end
				end)
			end
		end

		registro.combo = registro.combo + 1
		if registro.combo > 5 then
			registro.combo = 1
		end
	end
end)
