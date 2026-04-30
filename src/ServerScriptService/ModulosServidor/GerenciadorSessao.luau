local GerenciadorSessao = {}
GerenciadorSessao.DadosAtuais = {}

function GerenciadorSessao.Obter(userId)
	local dados = GerenciadorSessao.DadosAtuais[userId]
	if dados then
		return dados
	end
	return nil
end

function GerenciadorSessao.Definir(userId, novosDados)
	local dadosAtuais = GerenciadorSessao.DadosAtuais[userId]

	if dadosAtuais then
		for chave, valor in pairs(novosDados) do
			dadosAtuais[chave] = valor
		end
	else
		GerenciadorSessao.DadosAtuais[userId] = novosDados
	end
end

function GerenciadorSessao.Remover(userId)
	GerenciadorSessao.DadosAtuais[userId] = nil
end

return GerenciadorSessao
