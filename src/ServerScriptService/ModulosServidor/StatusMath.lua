local StatusMath = {}

function StatusMath.calcularAtributos(nivel, raca)
	local atributos = {}
	local bonusNivel = nivel - 1

	local novaVida = 100 + bonusNivel
	local novoDano = 5 + math.floor(bonusNivel / 5)
	local novaEnergia = 100 + (bonusNivel * 2)
	local novaAgilidade = 16 + math.floor(bonusNivel / 5)

	if raca == "Skypiean" then
		novaEnergia = novaEnergia + 15
		novaAgilidade = novaAgilidade + 2
	elseif raca == "Mink" then
		novaAgilidade = novaAgilidade + 4
		novoDano = novoDano + 1
		novaEnergia = novaEnergia + 10
	elseif raca == "Homem-Peixe" then
		novaVida = novaVida + 20
		novoDano = novoDano + 3
	end

	atributos.vidaMaxima = novaVida
	atributos.danoBase = novoDano
	atributos.energiaMaxima = novaEnergia
	atributos.agilidade = novaAgilidade

	return atributos
end

function StatusMath.adicionarXP(xpAtual, xpMaximo, nivelAtual, quantidadeGanha)
	xpAtual = xpAtual + quantidadeGanha
	local subiuDeNivel = false

	while xpAtual >= xpMaximo do
		xpAtual = xpAtual - xpMaximo 
		nivelAtual = nivelAtual + 1
		xpMaximo = math.floor(xpMaximo * 1.5) 
		subiuDeNivel = true
	end

	return xpAtual, xpMaximo, nivelAtual, subiuDeNivel
end

return StatusMath