local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local eventoEnergia = ReplicatedStorage:WaitForChild("ControleEnergia")

local jogadoresCorrendo = {}

local cacheEnergia = {}

local function registrarCache(player)
	local dados = player:WaitForChild("dadosOcultos", 10)
	if dados then
		local energiaAtual = dados:WaitForChild("EnergiaAtual", 10)
		local energiaMaxima = dados:WaitForChild("EnergiaMaxima", 10)

		if energiaAtual and energiaMaxima then
			cacheEnergia[player.UserId] = {
				Atual = energiaAtual,
				Maxima = energiaMaxima,
			}
		end
	end
end

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(registrarCache, player)
end
Players.PlayerAdded:Connect(registrarCache)

eventoEnergia.OnServerEvent:Connect(function(player, acao, parametroExtra)
	local cache = cacheEnergia[player.UserId]
	if not cache then
		return
	end

	local energia = cache.Atual

	if acao == "IniciarSprint" then
		jogadoresCorrendo[player.UserId] = true
	elseif acao == "PararSprint" then
		jogadoresCorrendo[player.UserId] = false
	elseif acao == "Dash" then
		if typeof(parametroExtra) ~= "Vector3" then
			return
		end

		if energia.Value >= 20 then
			energia.Value = math.max(0, energia.Value - 20)

			local personagem = player.Character
			if personagem and personagem:FindFirstChild("HumanoidRootPart") then
				local rootPart = personagem.HumanoidRootPart

				local forca = Instance.new("LinearVelocity")
				forca.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector

				local direcaoSegura = parametroExtra.Unit
				if direcaoSegura.Magnitude ~= direcaoSegura.Magnitude then
					direcaoSegura = rootPart.CFrame.LookVector
				end

				forca.VectorVelocity = direcaoSegura * 60
				forca.MaxForce = 100000

				local attachment = rootPart:FindFirstChild("RootAttachment") or Instance.new("Attachment", rootPart)
				attachment.Name = "RootAttachment"

				forca.Attachment0 = attachment
				forca.Parent = rootPart

				task.delay(0.15, function()
					if forca then
						forca:Destroy()
					end
				end)
			end
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	jogadoresCorrendo[player.UserId] = nil
	cacheEnergia[player.UserId] = nil
end)

while task.wait(0.1) do
	for userId, cache in pairs(cacheEnergia) do
		local energia = cache.Atual
		local maxEnergia = cache.Maxima
		local player = Players:GetPlayerByUserId(userId)

		if jogadoresCorrendo[userId] then
			energia.Value = math.max(0, energia.Value - 1)

			if energia.Value == 0 and player then
				jogadoresCorrendo[userId] = false
				eventoEnergia:FireClient(player, "SemEnergia")
			end
		elseif player and player:GetAttribute("Bloqueando") == true then
			energia.Value = math.max(0, energia.Value - 1)

			if energia.Value == 0 then
				player:SetAttribute("Bloqueando", false)
			end
		else
			if energia.Value < maxEnergia.Value then
				energia.Value = math.min(maxEnergia.Value, energia.Value + 1)
			end
		end
	end
end
