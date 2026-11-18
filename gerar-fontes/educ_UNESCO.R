# Rotina para automatizar o download de dados utilizados na
# construção de indicadores de Ciência, Tecnologia e Inovação
#
# Autor: João Paulo Garcia
# email: joao.garcia@fjp.mg.gov.br
#
# Obs: mapa_paises, periodo e input_dir são definidos em `setup.R`.
# -------------------------------------------
# 1. FORMAÇÃO E CAPACITAÇÃO PROFISSIONAL
# .. 1.1 EDUCAÇÃO SUPERIOR
#
# Base de dados: UNESCO - Education OPRI

id_unesco <- c(
	"FOSGP.5T8.F500600700",   # % of graduates from STEM
	"FOSGP.5T8.F500600700.F", # % of graduates from STEM, female
	"FOSGP.5T8.F500600700.M", # % of graduates from STEM, male
	"FOSGP.5T8.F500",         # % of graduates from science and math
	"FOSGP.5T8.F600",         # % of graduates from TIC
	"FOSGP.5T8.F700",         # % of graduates from engineere
	"ETOIP.5T8.PR",           # % of enrolment in private institutions
	"ETOIP.5T8.PU",           # % of enrolment in public institutions
	"25053",                  # Enrolment in all programmes
	"25057",                  # Enrolment in all programmes, female 
	"42620"                   # Enrolment in all programmes, male 
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
	exdir = file.path(input_dir, "UNESCO_SCN_OPRI_educ"),
	junkpaths = TRUE
)

rm(id_unesco, params, api_url, arquivo_zip)
