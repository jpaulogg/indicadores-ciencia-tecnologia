# Rotina para automatizar o download de dados utilizados na
# construção de indicadores de Ciência, Tecnologia e Inovação
#
# Autor: João Paulo Garcia
# email: joao.garcia@fjp.mg.gov.br
# -------------------------------------------
# 1. EDUCAÇÃO FORMAL DE NÍVEL SUPERIOR

# 1.1 OCDE - Number of enrolled students, graduates and new
# .......... entrants by field of education

url_api <- paste0(
	# host URL
	"https://sdmx.oecd.org/public/rest/data/",
	# identificador da agencia à qual pertence a base de dados
	"OECD.EDU.IMEP,",
	# identificador da base de dados
	"DSD_EAG_UOE_NON_FIN_STUD@DF_UOE_NF_STUD_DB,",
	# versao da base de dados
	"1.1/",
	# paises (lideres + desenvolvidos + em transição + intermediários)
	"ISR+JPN+KOR+USA",
	"+AUS+AUT+BEL+CAN+CHE+DEU+DNK+FIN+GBR+IRL+ISL+LUX+NLD+NOR+NZL+SWE",
	"+BGR+CZE+ESP+EST+FRA+GRC+HRV+HUN+ITA+LTU+LVA+POL+PRT+SVK+SVN",
	"+BRA+CHL+COL+CRI+MEX+PER+ROU+TUR.",
	# nivel educacional (bacharelado + mestrado + doutorado + total)
	"ISCED11_6+ISCED11_7+ISCED11_8.",
	# especificação de medida (matriculados + concluintes)
	"ENRL+GRAD.",
	# tipo de educação (educação formal) e intensidade do curso (total)
	"FE._T.",
	# campos (total + areas STEM + areas individuais + nao especificadas)
	"_T+F00+F01+F02+F03+F04+F05+F06+F07+F08+F09+F10+F99.",
	# ano curricular, frequência (A = anual), país de origem e destino
	".A...",
	# tipo de instituição (publica, privada e total)
	"INST_EDU_PUB+INST_EDU_PRIV+INST_EDU.",
	# mobilidade (total)
	"_T.",
	# unidade de medida (PS = contagem de pessoas)
	"PS.",
	# gênero (feminino, masculino e total) e faixa etária (total)
	"F+M._T?",
	# recorte temporal (anos disponíveis: 2005, 2010-2024)
	"startPeriod=2010",
	"&endPeriod=2024",
	# representação tabular direta em linhas e colunas
	"&dimensionAtObservation=AllDimensions",
	# formato csv (para adicionar rótulos, 'csvfilewithlabels')
	"&format=csvfile"
)

output_file <- file.path(
	input_dir,  # definido em setup.R
	"OCDE_estudantes_por_campo.csv"
)

status_download <- tryCatch({
	download.file(
		url = url_api,
		destfile = output_file,
		mode     = "wb",
		quiet    = TRUE
	)
}, error = function(e) {
	stop("Falha no download: ", e$message)
})
