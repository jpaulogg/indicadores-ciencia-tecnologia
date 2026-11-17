# Rotina para automatizar o download de dados utilizados na
# construção de indicadores de Ciência, Tecnologia e Inovação
#
# Autor: João Paulo Garcia
# email: joao.garcia@fjp.mg.gov.br
#
# Obs: mapa_paises, periodo e input_dir são definidos em `setup.R`.
# -------------------------------------------

# preparar ambiente
if (!requireNamespace("jsonlite", quietly = TRUE)) {
    install.packages("jsonlite")
}

# 1. EDUCAÇÃO FORMAL DE NÍVEL SUPERIOR

# 1.2  UNESCO - Education OPRI

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

base_url <- "https://api.uis.unesco.org/api/public/data/indicators"

params <- c(
	paste0("indicator=", id_unesco),
	paste0("geoUnit=", mapa_paises$ISO3),
	paste0("start=", min(periodo)),
	paste0("end=", max(periodo)),
	"indicatorMetadata=false"
)

api_url <- paste0(base_url, "?", paste(params, collapse = "&"))

dados <- jsonlite::fromJSON(api_url, flatten = TRUE)
dados_unesco <- dados$records

# tornar nomes de colunas compatíveis com os downloads diretos do site
colnames(dados_unesco) <- c(
	"INDICATOR_ID",    # indicatorId
	"COUNTRY_ID",      # geoUnit
	"YEAR",            # year
	"VALUE",           # value
	"MAGNITUDE",       # magnitude
	"QUALIFIER"        # qualifier
)

if (!is.data.frame(dados_unesco) || nrow(dados_unesco) == 0) {
	stop("A consulta não retornou registros. Verifique dados$hints.")
}

write.csv(
	dados_unesco,
	file.path(input_dir, "UNESCO_EDUC_OPRI.csv"),
	row.names = FALSE
)

rm(id_unesco, params, base_url, api_url, dados, dados_unesco)
