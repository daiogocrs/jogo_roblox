local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")
local player = game.Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local eventoEnergia = ReplicatedStorage:WaitForChild("ControleEnergia")

local energiaAtual = player:GetAttribute("EnergiaAtual") or 100

-- ==========================================
-- CRIANDO A BARRA DE ENERGIA FLUTUANTE (VERTICAL)
-- ==========================================
local billboard = Instance.new("BillboardGui")
billboard.Name = "BarraEnergia"
-- NOVIDADE: Barra mais fina no X (0.25) e alta no Y (3.5)
billboard.Size = UDim2.new(0.25, 0, 3.5, 0)
-- NOVIDADE: Move a barra para a direita (X = 1.5) e alinha ao centro (Y = 0)
billboard.StudsOffset = Vector3.new(2.3, 0, 0)
billboard.AlwaysOnTop = true
-- NOVIDADE: Grudando a barra no tronco (RootPart) em vez da cabeça
billboard.Adornee = rootPart
billboard.Parent = character

local fundoBarra = Instance.new("Frame")
fundoBarra.Size = UDim2.new(1, 0, 1, 0)
fundoBarra.BackgroundColor3 = Color3.fromRGB(20, 30, 40)
fundoBarra.BackgroundTransparency = 0.5
-- Borda preta fininha de 1 pixel para dar um contraste nas pontas quadradas
fundoBarra.BorderSizePixel = 1
fundoBarra.BorderColor3 = Color3.fromRGB(0, 0, 0)
fundoBarra.Parent = billboard

local barraAzul = Instance.new("Frame")
-- NOVIDADE: Truque matemático para a barra encher de baixo para cima
barraAzul.AnchorPoint = Vector2.new(0, 1) -- Fixa a âncora na parte de baixo
barraAzul.Position = UDim2.new(0, 0, 1, 0) -- Joga a posição inicial para baixo
barraAzul.Size = UDim2.new(1, 0, 1, 0)
barraAzul.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
barraAzul.BorderSizePixel = 0
barraAzul.Parent = fundoBarra

-- ==========================================
-- LÓGICA DE CONTROLES
-- ==========================================
local isSprinting = false
local lastWPress = 0
local tempoDuploClique = 0.3 -- Tempo máximo entre os dois cliques no "W"
local podeDarDash = true

-- Função que altera o tamanho VERTICAL da barra
local function atualizarBarraVisual()
	local atual = energiaAtual.Value
	local maxima = energiaMaxima.Value

	local proporcao = math.clamp(atual / maxima, 0, 1)

	-- NOVIDADE: A proporção (o tanto que a barra enche) agora é aplicada no eixo Y
	barraAzul.Size = UDim2.new(1, 0, proporcao, 0)

	-- Só mostra a barra se a energia estiver sendo gasta
	if atual >= maxima then
		billboard.Enabled = false
	else
		billboard.Enabled = true
	end
end

-- Escuta as mudanças de energia vindas do Servidor
energiaAtual.Changed:Connect(atualizarBarraVisual)
atualizarBarraVisual()

-- Se o servidor avisar que a energia acabou no meio da corrida
eventoEnergia.OnClientEvent:Connect(function(msg)
	if msg == "SemEnergia" then
		isSprinting = false
		humanoid.WalkSpeed = agilidade.Value
	end
end)

-- Detectando quando aperta as teclas
UserInputService.InputBegan:Connect(function(input, processou)
	if processou then
		return
	end

	-- Lógica da Corrida (Duplo W)
	if input.KeyCode == Enum.KeyCode.W then
		local tempoAtual = tick()

		if tempoAtual - lastWPress <= tempoDuploClique then
			if energiaAtual.Value > 0 then
				isSprinting = true
				humanoid.WalkSpeed = agilidade.Value * 1.8
				eventoEnergia:FireServer("IniciarSprint")
			end
		end
		lastWPress = tempoAtual

		-- Lógica do Dash/Esquiva (Q)
	elseif input.KeyCode == Enum.KeyCode.Q then
		if podeDarDash and energiaAtual.Value >= 20 then
			podeDarDash = false
			eventoEnergia:FireServer("Dash")

			local direcao = humanoid.MoveDirection
			if direcao.Magnitude == 0 then
				direcao = rootPart.CFrame.LookVector
			end

			local forca = Instance.new("LinearVelocity")
			forca.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
			forca.VectorVelocity = direcao * 60
			forca.MaxForce = 100000

			local attachment = rootPart:FindFirstChild("RootAttachment")
			if not attachment then
				attachment = Instance.new("Attachment", rootPart)
				attachment.Name = "RootAttachment"
			end

			forca.Attachment0 = attachment
			forca.Parent = rootPart

			task.wait(0.15)
			forca:Destroy()

			task.wait(1)
			podeDarDash = true
		end
	end
end)

-- Detectando quando solta o botão para parar de correr
UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.W then
		if isSprinting then
			isSprinting = false
			humanoid.WalkSpeed = agilidade.Value
			eventoEnergia:FireServer("PararSprint")
		end
	end
end)
