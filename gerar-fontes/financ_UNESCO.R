# Rotina para automatizar o download de dados utilizados na
# construção de indicadores de Ciência, Tecnologia e Inovação
#
# Autor: João Paulo Garcia
# email: joao.garcia@fjp.mg.gov.br
#
# Obs: o objeto `input_dir` está definido no script "setup.R".
# -------------------------------------------
# 3.. FINANCIAMENTO E DISPÊNDIO EM C&T E P&D
# 3.2 DISPÊNDIO
#
# Base de dados: UNESCO (UIS) - SCN, OPRI

# os indicadores abaixo têm valores a preços constantes de 2017
id_unesco <- c(
	"EXPPPP.CONST",             # GERD IN '000 PPP$'
	"EXPPPP.CONST.SP.BUSENTSP", # GERD - PERFORMED BY BUSINESS ENTERPRISE
	"EXPPPP.CONST.SP.GOVSP",    # GERD - PERFORMED BY GOVERNMENT
	"EXPPPP.CONST.SP.HIEDUSP",  # GERD - PERFORMED BY HIGHER EDUCATION
	"EXPPPP.CONST.SP.PRNPSP",   # GERD - PERFORMED BY PRIVATE NON-PROFIT
	"EXPPPP.CONST.SP.SPNS"      # GERD - PERFORMED BY NOT SPECIFIED SECTORS
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
	exdir = file.path(input_dir, "UNESCO_SCN_OPRI_financ"),
	junkpaths = TRUE
)
