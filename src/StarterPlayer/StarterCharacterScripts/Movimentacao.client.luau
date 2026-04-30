local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")
local player = game.Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local eventoEnergia = ReplicatedStorage:WaitForChild("ControleEnergia")

local dadosOcultos = player:WaitForChild("dadosOcultos")
local energiaAtual = dadosOcultos:WaitForChild("EnergiaAtual")
local energiaMaxima = dadosOcultos:WaitForChild("EnergiaMaxima")
local agilidade = dadosOcultos:WaitForChild("Agilidade")

-- ==========================================
-- CRIANDO A BARRA DE ENERGIA FLUTUANTE (VERTICAL)
-- ==========================================
local billboard = Instance.new("BillboardGui")
billboard.Name = "BarraEnergia"
billboard.Size = UDim2.new(0.25, 0, 3.5, 0)
billboard.StudsOffset = Vector3.new(2.3, 0, 0)
billboard.AlwaysOnTop = true
billboard.Adornee = rootPart
billboard.Parent = character

local fundoBarra = Instance.new("Frame")
fundoBarra.Size = UDim2.new(1, 0, 1, 0)
fundoBarra.BackgroundColor3 = Color3.fromRGB(20, 30, 40)
fundoBarra.BackgroundTransparency = 0.5
fundoBarra.BorderSizePixel = 1
fundoBarra.BorderColor3 = Color3.fromRGB(0, 0, 0)
fundoBarra.Parent = billboard

local barraAzul = Instance.new("Frame")
barraAzul.AnchorPoint = Vector2.new(0, 1)
barraAzul.Position = UDim2.new(0, 0, 1, 0)
barraAzul.Size = UDim2.new(1, 0, 1, 0)
barraAzul.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
barraAzul.BorderSizePixel = 0
barraAzul.Parent = fundoBarra

-- ==========================================
-- LÓGICA DE CONTROLES
-- ==========================================
local isSprinting = false
local lastWPress = 0
local tempoDuploClique = 0.3
local podeDarDash = true

local function atualizarBarraVisual()
	local atual = energiaAtual.Value
	local maxima = energiaMaxima.Value

	local proporcao = math.clamp(atual / maxima, 0, 1)

	barraAzul.Size = UDim2.new(1, 0, proporcao, 0)

	if atual >= maxima then
		billboard.Enabled = false
	else
		billboard.Enabled = true
	end
end

energiaAtual.Changed:Connect(atualizarBarraVisual)
atualizarBarraVisual()

eventoEnergia.OnClientEvent:Connect(function(msg)
	if msg == "SemEnergia" then
		isSprinting = false
		humanoid.WalkSpeed = agilidade.Value
	end
end)

UserInputService.InputBegan:Connect(function(input, processou)
	if processou then
		return
	end

	if input.KeyCode == Enum.KeyCode.W then
		local tempoAtual = tick()

		if tempoAtual - lastWPress <= tempoDuploClique then
			if energiaAtual.Value > 0 and not player:GetAttribute("Bloqueando") then
				isSprinting = true
				humanoid.WalkSpeed = agilidade.Value * 1.8
				eventoEnergia:FireServer("IniciarSprint")
			end
		end
		lastWPress = tempoAtual
	elseif input.KeyCode == Enum.KeyCode.Q then
		if podeDarDash and energiaAtual.Value >= 20 and not player:GetAttribute("Bloqueando") then
			podeDarDash = false

			local direcao = humanoid.MoveDirection
			if direcao.Magnitude == 0 then
				direcao = rootPart.CFrame.LookVector
			end

			eventoEnergia:FireServer("Dash", direcao)

			task.wait(1)
			podeDarDash = true
		end
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.W then
		if isSprinting then
			isSprinting = false
			humanoid.WalkSpeed = agilidade.Value
			eventoEnergia:FireServer("PararSprint")
		end
	end
end)

-- ==========================================
-- EFEITO DO BLOQUEIO NA MOVIMENTAÇÃO
-- ==========================================
player:GetAttributeChangedSignal("Bloqueando"):Connect(function()
	local bloqueando = player:GetAttribute("Bloqueando")

	if bloqueando then
		if isSprinting then
			isSprinting = false
			eventoEnergia:FireServer("PararSprint")
		end

		humanoid.WalkSpeed = agilidade.Value * 0.4
	else
		if not player:GetAttribute("Stunned") then
			humanoid.WalkSpeed = agilidade.Value
		end
	end
end)
