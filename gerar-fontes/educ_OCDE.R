# Rotina para automatizar o download de dados utilizados na
# construção de indicadores de Ciência, Tecnologia e Inovação
#
# Autor: João Paulo Garcia
# email: joao.garcia@fjp.mg.gov.br
#
# Obs: o objeto `input_dir` está definido no script "setup.R".
# -------------------------------------------
# 1.. FORMAÇÃO E CAPACITAÇÃO PROFISSIONAL
# 1.1 EDUCAÇÃO SUPERIOR
#
# Base de dados: OCDE - Student (full database)

url_api <- paste0(
	# host URL
	"https://sdmx.oecd.org/public/rest/data/",
	# identificador da agencia à qual pertence a base de dados
	"OECD.EDU.IMEP,",
	# identificador da base de dados
	"DSD_EAG_UOE_NON_FIN_STUD@DF_UOE_NF_STUD_DB,",
	# versao da base de dados
	"1.1/",
	# paises (disponível: 38 da OCDE + 5)
	paste(mapa_paises$ISO3, collapse = "+"), ".",
	# nivel educacional (bacharelado + mestrado + doutorado)
	"ISCED11_6+ISCED11_7+ISCED11_8.",
	# especificação de medida (matriculados + concluintes)
	"ENRL+GRAD.",
	# tipo de educação (educação formal) e intensidade do curso (total)
	"FE._T.",
	# campos (total + areas STEM + areas individuais + nao especificadas)
	"_T+F00+F01+F02+F03+F04+F05+F06+F07+F08+F09+F10+F99.",
	# ano curricular, frequência (A = anual), país de origem e destino
	"_T.A._Z._Z.",
	# tipo de instituição (publica, privada e total)
	"INST_EDU_PUB+INST_EDU_PRIV+INST_EDU.",
	# mobilidade (total)
	"_T.",
	# unidade de medida (PS = contagem de pessoas)
	"PS.",
	# gênero (feminino e masculino) e faixa etária (total)
	"F+M._T?",
	# recorte temporal (anos disponíveis: 2005, 2010-2024)
	"startPeriod=2010",
	# representação tabular direta em linhas e colunas
	"&dimensionAtObservation=AllDimensions",
	# formato csv (para adicionar rótulos, 'csvfilewithlabels')
	"&format=csvfile"
)

status_download <- tryCatch({
	download.file(
		url = url_api,
		destfile = file.path(input_dir, "OCDE_estudantes_por_campo.csv"),
		mode     = "wb",
		quiet    = TRUE
	)
}, error = function(e) {
	stop("Falha no download: ", e$message)
})
