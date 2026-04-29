local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local camera = workspace.CurrentCamera
local cameraMenu = workspace:WaitForChild("CameraMenu")

local menuGui = script.Parent
local painelPrincipal = menuGui:WaitForChild("PainelPrincipal")
local painelGenero = menuGui:WaitForChild("PainelGenero")
local painelConfirmacao = menuGui:WaitForChild("PainelConfirmacao")

local eventoMenu = ReplicatedStorage:WaitForChild("EventoMenu")
local eventoEscolha = ReplicatedStorage:WaitForChild("EscolhaGenero")
local eventoDeletar = ReplicatedStorage:WaitForChild("DeletarPersonagem")

local temPersonagem = false

-- Fundo transparente por código para a câmera aparecer
painelPrincipal.BackgroundTransparency = 1
painelGenero.BackgroundTransparency = 1
painelConfirmacao.BackgroundTransparency = 1

-- Trava a Câmera
local function travarCamera()
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = cameraMenu.CFrame
end
local conexaoCamera = RunService.RenderStepped:Connect(travarCamera)

local function esconderTudo()
	painelPrincipal.Visible = false
	painelGenero.Visible = false
	painelConfirmacao.Visible = false
end

-- Recebe a resposta do Servidor
eventoMenu.OnClientEvent:Connect(function(possuiConta)
	esconderTudo()
	painelPrincipal.Visible = true
	menuGui.Enabled = true
	temPersonagem = possuiConta

	if painelPrincipal:FindFirstChild("BtnWipe") then
		painelPrincipal.BtnWipe.Visible = possuiConta
	end
end)

-- Botão de Iniciar
painelPrincipal.BtnIniciar.MouseButton1Click:Connect(function()
	if temPersonagem then
		eventoMenu:FireServer("Iniciar") 
		conexaoCamera:Disconnect()
		camera.CameraType = Enum.CameraType.Custom
		menuGui.Enabled = false
	else
		esconderTudo()
		painelGenero.Visible = true
	end
end)

-- CORREÇÃO: O Evento de Clique do Botão Wipe!
if painelPrincipal:FindFirstChild("BtnWipe") then
	painelPrincipal.BtnWipe.MouseButton1Click:Connect(function()
		esconderTudo()
		painelConfirmacao.Visible = true
	end)
end

local function escolherGenero(genero)
	eventoEscolha:FireServer(genero)
	conexaoCamera:Disconnect()
	camera.CameraType = Enum.CameraType.Custom
	menuGui.Enabled = false
end

painelGenero.BtnMasculino.MouseButton1Click:Connect(function() escolherGenero("Masculino") end)
painelGenero.BtnFeminino.MouseButton1Click:Connect(function() escolherGenero("Feminino") end)

-- Confirmação do Wipe
painelConfirmacao.BtnSim.MouseButton1Click:Connect(function()
	painelConfirmacao.BtnSim.Text = "Deletando..."
	eventoDeletar:FireServer()

	task.wait(1)

	-- Reseta a interface para o estado de "nova conta"
	painelConfirmacao.BtnSim.Text = "SIM"
	temPersonagem = false
	if painelPrincipal:FindFirstChild("BtnWipe") then
		painelPrincipal.BtnWipe.Visible = false
	end

	esconderTudo()
	painelPrincipal.Visible = true
end)

painelConfirmacao.BtnNao.MouseButton1Click:Connect(function()
	esconderTudo()
	painelPrincipal.Visible = true
end)

eventoMenu:FireServer("VerificarConta")