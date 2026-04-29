local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Busca o MenuPrincipal na nuvem e cria uma cópia para o jogador
local menuClone = ReplicatedStorage:WaitForChild("MenuPrincipal"):Clone()

-- Envia o menu clonado diretamente para a tela do jogador!
menuClone.Parent = playerGui