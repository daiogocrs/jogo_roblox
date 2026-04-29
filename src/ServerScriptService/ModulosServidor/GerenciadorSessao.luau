local GerenciadorSessao = {}
GerenciadorSessao.DadosAtuais = {}

function GerenciadorSessao.Obter(userId)
	local dados = GerenciadorSessao.DadosAtuais[userId]
	if dados then
		return table.clone(dados)
	end
	return nil
end

function GerenciadorSessao.Definir(userId, novosDados)
	GerenciadorSessao.DadosAtuais[userId] = novosDados
end

function GerenciadorSessao.Remover(userId)
	GerenciadorSessao.DadosAtuais[userId] = nil
end

return GerenciadorSessao