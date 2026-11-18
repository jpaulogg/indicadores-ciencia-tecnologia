# Rotina para automatizar o download de dados utilizados na
# construção de indicadores de Ciência, Tecnologia e Inovação
#
# Autor: João Paulo Garcia
# email: joao.garcia@fjp.mg.gov.br
#
# Obs: o objeto `input_dir` está definido no script "setup.R".
# -------------------------------------------
# 4. DISPÊNDIO EM ATIVIDADES DE C&T E P&D

# 4.1 - UNESCO

# os indicadores abaixo têm valores a preços constantes de 2017
id_unesco <- c(
	"EXPPPP.CONST",             # GERD IN '000 PPP$'
	"EXPPPP.CONST.SF.BUSENTFS", # GERD - FINANCED BY BUSINESS ENTERPRISE
	"EXPPPP.CONST.SF.FSNS",     # GERD - FINANCED BY NOT SPECIFIED SOURCE
	"EXPPPP.CONST.SF.FUNABFS",  # GERD - FINANCED BY REST OF THE WORLD
	"EXPPPP.CONST.SF.GOVFS",    # GERD - FINANCED BY GOVERNMENT
	"EXPPPP.CONST.SF.HIEDUFS",  # GERD - FINANCED BY HIGHER EDUCATION
	"EXPPPP.CONST.SF.PRNPFS",   # GERD - FINANCED BY PRIVATE NON-PROFIT
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
	exdir = file.path(input_dir, "UNESCO_SCN_OPRI_disp"),
	junkpaths = TRUE
)

rm(id_unesco, params, api_url, arquivo_zip)
