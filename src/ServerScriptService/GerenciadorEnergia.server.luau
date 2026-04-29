local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local eventoEnergia = ReplicatedStorage:WaitForChild("ControleEnergia")

-- Tabela para gravar quem está com o botão de corrida pressionado
local jogadoresCorrendo = {}

-- CACHE DE ENERGIA: Evita usar FindFirstChild a cada 0.1 segundos!
local cacheEnergia = {}

-- Função que guarda os status de energia do jogador na memória assim que ele entra
local function registrarCache(player)
	-- Espera até que a pasta e os valores sejam criados pelo GeradorPersonagem
	local dados = player:WaitForChild("dadosOcultos", 10)
	if dados then
		local energiaAtual = dados:WaitForChild("EnergiaAtual", 10)
		local energiaMaxima = dados:WaitForChild("EnergiaMaxima", 10)

		if energiaAtual and energiaMaxima then
			cacheEnergia[player.UserId] = {
				Atual = energiaAtual,
				Maxima = energiaMaxima
			}
		end
	end
end

-- Registra quem já está no servidor e quem entrar depois
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(registrarCache, player)
end
Players.PlayerAdded:Connect(registrarCache)

eventoEnergia.OnServerEvent:Connect(function(player, acao)
	local cache = cacheEnergia[player.UserId]
	if not cache then return end -- Segurança caso os dados ainda não tenham carregado

	local energia = cache.Atual

	if acao == "IniciarSprint" then
		jogadoresCorrendo[player.UserId] = true
	elseif acao == "PararSprint" then
		jogadoresCorrendo[player.UserId] = false
	elseif acao == "Dash" then
		-- O Dash gasta 20 de energia em um único golpe
		if energia.Value >= 20 then
			energia.Value = math.max(0, energia.Value - 20)
		end
	end
end)

-- Limpa a memória se o jogador sair (Evita vazamento de memória/lag)
Players.PlayerRemoving:Connect(function(player)
	jogadoresCorrendo[player.UserId] = nil
	cacheEnergia[player.UserId] = nil
end)

-- Loop Mestre de Energia Otimizado (Roda a cada 0.1 segundos)
while task.wait(0.1) do
	-- Agora iteramos diretamente sobre o nosso cache na memória!
	for userId, cache in pairs(cacheEnergia) do
		local energia = cache.Atual
		local maxEnergia = cache.Maxima

		if jogadoresCorrendo[userId] then
			-- GASTO DA CORRIDA: Drena 10 de energia por segundo (1 por tick)
			energia.Value = math.max(0, energia.Value - 1)

			-- Se a energia zerar, força o jogador a parar de correr
			if energia.Value == 0 then
				jogadoresCorrendo[userId] = false

				-- Puxa o jogador pelo ID para avisar o cliente
				local player = Players:GetPlayerByUserId(userId)
				if player then
					eventoEnergia:FireClient(player, "SemEnergia")
				end
			end
		else
			-- REGENERAÇÃO: Recupera 10 de energia por segundo se não estiver correndo
			if energia.Value < maxEnergia.Value then
				energia.Value = math.min(maxEnergia.Value, energia.Value + 1)
			end
		end
	end
end