local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local eventoEnergia = ReplicatedStorage:WaitForChild("ControleEnergia")

local jogadoresCorrendo = {}

local cooldownDash = {}
local TEMPO_RECARGA_DASH = 1.5

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

eventoEnergia.OnServerEvent:Connect(function(player, acao)
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
		local tempoAtual = os.clock()
		local ultimoDash = cooldownDash[player.UserId] or 0

		if (tempoAtual - ultimoDash) >= TEMPO_RECARGA_DASH then
			if energia.Value >= 20 then
				energia.Value = math.max(0, energia.Value - 20)
				cooldownDash[player.UserId] = tempoAtual
			end
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	jogadoresCorrendo[player.UserId] = nil
	cacheEnergia[player.UserId] = nil
	cooldownDash[player.UserId] = nil
end)

while task.wait(0.1) do
	for userId, cache in pairs(cacheEnergia) do
		local energia = cache.Atual
		local maxEnergia = cache.Maxima

		if jogadoresCorrendo[userId] then
			energia.Value = math.max(0, energia.Value - 1)

			if energia.Value == 0 then
				jogadoresCorrendo[userId] = false

				local player = Players:GetPlayerByUserId(userId)
				if player then
					eventoEnergia:FireClient(player, "SemEnergia")
				end
			end
		else
			if energia.Value < maxEnergia.Value then
				energia.Value = math.min(maxEnergia.Value, energia.Value + 1)
			end
		end
	end
end
