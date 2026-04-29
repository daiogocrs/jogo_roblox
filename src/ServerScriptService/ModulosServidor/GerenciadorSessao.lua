local GerenciadorSessao = {}
GerenciadorSessao.DadosAtuais = {}

function GerenciadorSessao.Obter(userId)
	return GerenciadorSessao.DadosAtuais[userId]
end

function GerenciadorSessao.Definir(userId, novosDados)
	GerenciadorSessao.DadosAtuais[userId] = novosDados
end

function GerenciadorSessao.Remover(userId)
	GerenciadorSessao.DadosAtuais[userId] = nil
end

return GerenciadorSessao