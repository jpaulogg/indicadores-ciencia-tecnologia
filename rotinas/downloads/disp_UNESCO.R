# Rotina para automatizar o download de dados utilizados na
# construção de indicadores de Ciência, Tecnologia e Inovação
#
# Autor: João Paulo Garcia
# email: joao.garcia@fjp.mg.gov.br
#
# Obs: os objetos `mapa_paises`, `input_dir` e `periodo são
# definido em # "../setup.R".
# -------------------------------------------
# 3.. FINANCIAMENTO E DISPÊNDIO EM C&T E P&D
# 3.2 DISPÊNDIO
#
# Base de dados: UNESCO (UIS) - SCN, OPRI

# os indicadores abaixo têm valores a preços constantes de 2017
id_unesco <- c(
	# por setor de execução
	"EXPPPP.CONST",             # GERD IN '000 PPP$'
	"EXPPPP.CONST.SP.BUSENTSP", # PERFORMED BY BUSINESS ENTERPRISE
	"EXPPPP.CONST.SP.GOVSP",    # PERFORMED BY GOVERNMENT
	"EXPPPP.CONST.SP.HIEDUSP",  # PERFORMED BY HIGHER EDUCATION
	"EXPPPP.CONST.SP.PRNPSP",   # PERFORMED BY PRIVATE NON-PROFIT
	"EXPPPP.CONST.SP.SPNS",     # PERFORMED BY NOT SPECIFIED SECTORS
	# por fonte de financiamento
	"EXPPPP.CONST.SF.BUSENTFS", # FINANCED BY BUSINESS ENTERPRISE
	"EXPPPP.CONST.SF.FSNS",     # FINANCED BY NOT SPECIFIED SOURCE
	"EXPPPP.CONST.SF.FUNABFS",  # FINANCED BY REST OF THE WORLD
	"EXPPPP.CONST.SF.GOVFS",    # FINANCED BY GOVERNMENT
	"EXPPPP.CONST.SF.HIEDUFS",  # FINANCED BY HIGHER EDUCATION
	"EXPPPP.CONST.SF.PRNPFS",   # FINANCED BY PRIVATE NON-PROFIT
	# como percentual do PIB 
	"EXPGDP.TOT",               # GERD as a percentage of GDP
	"EXPGDP.SP.BUSENTSP",       # PERFORMED BY BUSINESS ENTERPRISE)
	"EXPGDP.SP.GOVSP",          # PERFORMED BY GOVERNMENT
	"EXPGDP.SP.HIEDUSP",        # PERFORMED BY HIGHER EDUCATION
	"EXPGDP.SP.PRNPSP",         # PERFORMED BY PRIVATE NON-PROFIT
	"EXPGDP.SP.SPNS"            # PERFORMED BY NOT SPECIFIED SECTORS
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
	exdir = file.path(input_dir, "UNESCO_disp"),
	junkpaths = TRUE
)
