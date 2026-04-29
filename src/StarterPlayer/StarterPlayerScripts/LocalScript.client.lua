local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

-- Desativa a lista padrão do Roblox
pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
end)

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

-- Evita duplicatas ao reiniciar o personagem
if playerGui:FindFirstChild("PlacarPersonalizado") then
	playerGui.PlacarPersonalizado:Destroy()
end

-- Criação da Interface Principal
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PlacarPersonalizado"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Name = "mainFrame"
mainFrame.Size = UDim2.new(0, 200, 0.5, 0)
mainFrame.Position = UDim2.new(1, -210, 0, 10)
mainFrame.BackgroundTransparency = 1
mainFrame.Parent = screenGui

-- Título (Igual à foto: "Players: X" alinhado à direita)
local tituloTexto = Instance.new("TextLabel")
tituloTexto.Size = UDim2.new(1, -5, 0, 25)
tituloTexto.Position = UDim2.new(0, 0, 0, 0)
tituloTexto.BackgroundTransparency = 1
tituloTexto.TextColor3 = Color3.new(1, 1, 1)
tituloTexto.Text = "Players: 0"
tituloTexto.Font = Enum.Font.GothamBold
tituloTexto.TextSize = 15
tituloTexto.TextXAlignment = Enum.TextXAlignment.Right -- Alinha para a direita
tituloTexto.Parent = mainFrame

local scrollingFrame = Instance.new("ScrollingFrame")
scrollingFrame.Size = UDim2.new(1, 0, 1, -30) 
scrollingFrame.Position = UDim2.new(0, 0, 0, 30)
scrollingFrame.BackgroundTransparency = 1
scrollingFrame.BorderSizePixel = 0
scrollingFrame.ScrollBarThickness = 0
scrollingFrame.Parent = mainFrame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 5)
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = scrollingFrame

local uiPadding = Instance.new("UIPadding")
uiPadding.PaddingTop = UDim.new(0, 5)
uiPadding.Parent = scrollingFrame

-- Função para desenhar a caixa do jogador
local function adicionarJogador(player)
	local playerFrame = Instance.new("Frame")
	playerFrame.Name = player.Name
	playerFrame.Size = UDim2.new(0.95, 0, 0, 30)
	playerFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30) -- Cinza escuro
	playerFrame.BackgroundTransparency = 0.4
	playerFrame.BorderSizePixel = 0
	playerFrame.Parent = scrollingFrame

	-- NOVIDADE: Deixa as bordas levemente arredondadas como na sua foto
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = playerFrame

	-- Borda Branca
	local uiStroke = Instance.new("UIStroke")
	uiStroke.Color = Color3.new(1, 1, 1)
	uiStroke.Transparency = 0.5
	uiStroke.Thickness = 1
	uiStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	uiStroke.Parent = playerFrame

	-- Nome do Jogador
	local nomeTexto = Instance.new("TextLabel")
	nomeTexto.Size = UDim2.new(1, -10, 1, 0)
	nomeTexto.Position = UDim2.new(0, 10, 0, 0)
	nomeTexto.BackgroundTransparency = 1
	nomeTexto.TextColor3 = Color3.new(1, 1, 1)
	nomeTexto.TextYAlignment = Enum.TextYAlignment.Center
	nomeTexto.TextXAlignment = Enum.TextXAlignment.Left
	nomeTexto.Font = Enum.Font.GothamSemibold
	nomeTexto.TextSize = 14
	nomeTexto.Parent = playerFrame

	-- Sistema de Nome Falso
	local function atualizarNome()
		local tagNome = player:FindFirstChild("NomeFalso")
		nomeTexto.Text = tagNome and tagNome.Value or "Desconhecido"
	end

	atualizarNome()
	
	-- NOVIDADE: Se a etiqueta já existir, ensinamos o placar a escutar as MUDANÇAS nela!
	local tagExistente = player:FindFirstChild("NomeFalso")
	if tagExistente then
		tagExistente.Changed:Connect(atualizarNome)
	end

	-- E se ela for criada depois, também ensinamos a escutar as mudanças!
	player.ChildAdded:Connect(function(child)
		if child.Name == "NomeFalso" then
			atualizarNome()
			child.Changed:Connect(atualizarNome)
		end
	end)
	
	-- Efeitos do Mouse
	playerFrame.MouseEnter:Connect(function()
		nomeTexto.Text = "@" .. player.Name
		nomeTexto.TextColor3 = Color3.fromRGB(160, 160, 160)
	end)

	playerFrame.MouseLeave:Connect(function()
		atualizarNome()
		nomeTexto.TextColor3 = Color3.new(1, 1, 1)
	end)
	
end

for _, p in ipairs(Players:GetPlayers()) do
	adicionarJogador(p)
end

Players.PlayerAdded:Connect(function(player)
	task.wait(1)
	adicionarJogador(player)
end)

Players.PlayerRemoving:Connect(function(player)
	local playerFrame = scrollingFrame:FindFirstChild(player.Name)
	if playerFrame then
		playerFrame:Destroy()
	end
end)

-- Atualiza o texto "Players: X" no topo
local function atualizarContagem()
	tituloTexto.Text = "Players: " .. #Players:GetPlayers()
end
Players.PlayerAdded:Connect(atualizarContagem)
Players.PlayerRemoving:Connect(atualizarContagem)
atualizarContagem()

-- Retrátil com a tecla Tab (Esconde o mainFrame inteiro, incluindo o título)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.Tab then
		mainFrame.Visible = not mainFrame.Visible
	end
end)