# Rotina para automatizar a construção de indicadores internacionais
# de matriculados e concluintes/titulados em cursos de bacharelado,
# mestrado e doutorado.
#
# Autor: João Paulo Garcia
# email: joao.garcia@fjp.mg.gov.br
# -------------------------------------------
# Preparação do ambiente

source("utilitarios.R")

# Leitura de dados

# OCDE

arquivo_ocde <- file.path(data_dir, "OECD_enrl_by_field.csv")

colunas_ocde <- c(
	"TIME_PERIOD"     = "integer",
	"REF_AREA"        = "character",
	"EDUCATION_LEV"   = "factor",
	"EDUCATION_FIELD" = "factor",
	"MEASURE"         = "factor",
	"SEX"             = "factor",
	"OBS_STATUS"      = "factor",    # "A", "K", "O", "M" e "W"
	"OBS_VALUE"       = "numeric"    # Número de pessoas
)

dados_ocde <- read.csv(arquivo_ocde, colClasses = colunas_ocde)
dados_ocde <- dados_ocde[, names(colunas_ocde)]
dados_ocde <- subset(
	dados_ocde,
	OBS_STATUS %in% c("A", "W") &    # valores normais e complementados
		SEX == "_T" &                # todos os gêneros
		REF_AREA %in% mapa_paises$ISO3 &
		MOBILITY == "_T"             # não diferenciar intercâmbio
)

# UNESCO

dados_unesco <- read.csv(
	"../fontes/OPRI_DATA_NATIONAL.csv"
)

cod_areas <- c(
	"F500600700" = "STEM",    # sempre manter na primeira posição
	"F100" = "Educação",
	"F200" = "Humanas",
	"F300" = "Sociais",
	"F400" = "Negócios",
	"F500" = "Exatas e Naturais",
	"F600" = "TIC",
	"F700" = "Engenharia",
	"F800" = "Agrárias",
	"F900" = "Saúde"
)

id_enrolment <- "25053"

dados_unesco <- subset(
	dados_unesco,
	COUNTRY_ID %in% mapa_paises &
		INDICATOR_ID %in% c("25053", "FOSGP.5T8.F500600700")
)
