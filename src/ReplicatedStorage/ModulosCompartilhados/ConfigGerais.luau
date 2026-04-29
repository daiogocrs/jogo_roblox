local ConfigGerais = {}

ConfigGerais.nomesMasculinos = {"Arthur", "Liam", "Noah", "William", "Lucas", "Gabriel"}
ConfigGerais.nomesFemininos = {"Olivia", "Emma", "Ava", "Sophia", "Julia", "Alice"}
ConfigGerais.sobrenomes = {"Silva", "Santos", "Oliveira", "Souza", "Rodrigues", "Smith"}

ConfigGerais.idsCabeloMasc = {376527350, 16630147} 
ConfigGerais.idsCabeloFem = {185812297, 376527350} 
ConfigGerais.idsCamisa = {398633812, 144076358, 382538295}
ConfigGerais.idsCalca = {398635834, 144076506, 382538503}

ConfigGerais.coresPeleHex = {
	"#FDE4C8", "#EEC196", "#C68642", "#8D5524", "#3D2314" 
}

ConfigGerais.ID_ROLETAR_NOME = 3582506122
ConfigGerais.ID_ROLETAR_RACA = 3582506121

function ConfigGerais.sortearRaca()
	local chance = math.random(1, 100)
	if chance <= 60 then
		return "Humano"        
	elseif chance <= 85 then
		return "Skypiean"      
	elseif chance <= 93 then
		return "Mink"          
	else
		return "Homem-Peixe"   
	end
end

return ConfigGerais