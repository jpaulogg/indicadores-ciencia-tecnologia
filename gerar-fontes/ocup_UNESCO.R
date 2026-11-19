# Rotina para automatizar o download de dados utilizados na
# construção de indicadores de Ciência, Tecnologia e Inovação
#
# Autor: João Paulo Garcia
# email: joao.garcia@fjp.mg.gov.br
#
# Obs: os objetos `mapa_paises`, `input_dir` e `periodo são
# definido em # "../setup.R".
# ------------------------------------------------------------
# 1.. FORMAÇÃO E CAPACITAÇÃO PROFISSIONAL
# 1.2 NÚMERO DE PESQUISADORES
#
# Base de dados: UNESCO - Science and Technology OPRI

id_unesco <- c(
	# ambos os sexos
    "21001",   # Researchers (HC) - Total
    "21205",   # Researchers (HC) - Business enterprise
    "21209",   # Researchers (HC) - Government
    "21213",   # Researchers (HC) - Higher education
    "21217",   # Researchers (HC) - Private non-profit

    # sexo feminino
    "21105",   # Researchers (HC) - Female
    "21726",   # Researchers (HC) - Female - Business enterprise
    "21727",   # Researchers (HC) - Female - Government
    "21728",   # Researchers (HC) - Female - Higher education
    "21729"    # Researchers (HC) - Female - Private non-profit
)

params <- c(
	paste0("indicator=", id_unesco),
	paste0("geoUnit=", mapa_paises$ISO3),
	paste0("start=", min(periodo)),
	paste0("end=", max(periodo)),
	"indicatorMetadata=false"
)

api_url <- paste0(
	"https://api.uis.unesco.org/api/public/data/indicators/export?",
	paste(c(params, "format=csv"), collapse = "&")
)

arquivo_zip <- tempfile()

download.file(
	url = api_url,
	destfile = arquivo_zip,
	mode = "wb"
)

unzip(
	arquivo_zip,
	exdir = file.path(input_dir, "UNESCO_SCN_OPRI_ocup"),
	junkpaths = TRUE
)
