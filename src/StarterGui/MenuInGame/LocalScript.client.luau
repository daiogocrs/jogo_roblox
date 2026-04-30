local player = game.Players.LocalPlayer
local MarketplaceService = game:GetService("MarketplaceService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ConfigGerais = require(ReplicatedStorage:WaitForChild("ModulosCompartilhados"):WaitForChild("ConfigGerais"))

local ID_ROLETAR_NOME = ConfigGerais.ID_ROLETAR_NOME
local ID_ROLETAR_RACA = ConfigGerais.ID_ROLETAR_RACA

-- Paineis
local painelOpcoes = script.Parent:WaitForChild("PainelOpcoes")
local painelGamepasses = script.Parent:WaitForChild("PainelGamepasses")
local painelStatus = script.Parent:WaitForChild("PainelStatus")

-- Botões do Painel de Opções
local btnGamepasses = painelOpcoes:WaitForChild("BtnGamepasses")
local btnStatus = painelOpcoes:WaitForChild("BtnStatus")

-- Botões da Loja
local btnRoletarNome = painelGamepasses:WaitForChild("BtnRoletarNome")
local btnRoletarRaca = painelGamepasses:WaitForChild("BtnRoletarRaca")

-- Textos de Status
local txtNivel = painelStatus:WaitForChild("TxtNivel")
local txtVida = painelStatus:WaitForChild("TxtVida")
local txtEnergia = painelStatus:WaitForChild("TxtEnergia")
local txtDano = painelStatus:WaitForChild("TxtDano")
local txtAgilidade = painelStatus:WaitForChild("TxtAgilidade")
local txtRaca = painelStatus:WaitForChild("TxtRaca")

local menuAberto = false

-- ==========================================
-- 🎨 SISTEMA DE TEMA AUTOMÁTICO
-- ==========================================
local corFundoBotao = Color3.fromRGB(20, 30, 40)
local corTexto = Color3.fromRGB(255, 255, 255)
local fontePadrao = Enum.Font.PermanentMarker

local function aplicarEstilo(item)
	if item:IsA("Frame") then
		item.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		item.BackgroundTransparency = 0.45
		item.AnchorPoint = Vector2.new(0.5, 0.5)
		item.Position = UDim2.new(0.5, 0, 0.5, 0)
		item.Size = UDim2.new(0, 300, 0, 0)
		item.AutomaticSize = Enum.AutomaticSize.Y

		if not item:FindFirstChild("UICorner") then
			local canto = Instance.new("UICorner")
			canto.CornerRadius = UDim.new(0, 12)
			canto.Parent = item
		end

		if not item:FindFirstChild("UIPadding") then
			local padding = Instance.new("UIPadding")
			padding.PaddingTop = UDim.new(0, 20)
			padding.PaddingBottom = UDim.new(0, 20)
			padding.PaddingLeft = UDim.new(0, 20)
			padding.PaddingRight = UDim.new(0, 20)
			padding.Parent = item
		end
	end

	if item:IsA("TextButton") or item:IsA("TextLabel") then
		item.Size = UDim2.new(1, 0, 0, 45)

		if item:IsA("TextButton") then
			item.BackgroundColor3 = corFundoBotao
			if not item:FindFirstChild("UICorner") then
				local canto = Instance.new("UICorner")
				canto.CornerRadius = UDim.new(0, 8)
				canto.Parent = item
			end
		else
			item.BackgroundTransparency = 1
		end

		item.TextColor3 = corTexto
		item.Font = fontePadrao
		item.TextScaled = false
		item.TextSize = 22

		if not item:FindFirstChild("UIStroke") then
			local borda = Instance.new("UIStroke")
			borda.Color = Color3.fromRGB(0, 0, 0)
			borda.Thickness = 2
			borda.Parent = item
		end
	end
end

for _, item in pairs(script.Parent:GetDescendants()) do
	aplicarEstilo(item)
end

-- ==========================================
-- LÓGICA DO MENU E STATUS DINÂMICO
-- ==========================================

local function atualizarTextosDeStatus()
	txtNivel.Text = "Nível: " .. (player:GetAttribute("Nivel") or 1)
	txtVida.Text = "Vida: " .. (player:GetAttribute("VidaMaxima") or 100)

	local energiaAtual = player:GetAttribute("EnergiaAtual") or 100
	local energiaMax = player:GetAttribute("EnergiaMaxima") or 100
	txtEnergia.Text = "Energia: " .. math.floor(energiaAtual) .. "/" .. energiaMax

	txtDano.Text = "Dano: " .. (player:GetAttribute("DanoBase") or 5)
	txtAgilidade.Text = "Agilidade: " .. (player:GetAttribute("Agilidade") or 16)
	txtRaca.Text = "Raça: " .. (player:GetAttribute("Raca") or "Humano")
end

player.AttributeChanged:Connect(atualizarTextosDeStatus)

atualizarTextosDeStatus()

UserInputService.InputBegan:Connect(function(input, processou)
	if not processou and input.KeyCode == Enum.KeyCode.M then
		menuAberto = not menuAberto
		if menuAberto then
			painelOpcoes.Visible = true
			painelGamepasses.Visible = false
			painelStatus.Visible = false
		else
			painelOpcoes.Visible = false
			painelGamepasses.Visible = false
			painelStatus.Visible = false
		end
	end
end)

btnGamepasses.MouseButton1Click:Connect(function()
	painelOpcoes.Visible = false
	painelGamepasses.Visible = true
end)

btnStatus.MouseButton1Click:Connect(function()
	painelOpcoes.Visible = false
	painelStatus.Visible = true
	atualizarTextosDeStatus()
end)

-- Compras
btnRoletarNome.MouseButton1Click:Connect(function()
	MarketplaceService:PromptProductPurchase(player, ID_ROLETAR_NOME)
end)

btnRoletarRaca.MouseButton1Click:Connect(function()
	MarketplaceService:PromptProductPurchase(player, ID_ROLETAR_RACA)
end)
