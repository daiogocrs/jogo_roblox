local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local menuClone = ReplicatedStorage:WaitForChild("MenuPrincipal"):Clone()

menuClone.Parent = playerGui
