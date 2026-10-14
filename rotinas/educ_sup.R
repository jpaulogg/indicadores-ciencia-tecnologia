# Rotina para automatizar a construção de indicadores internacionais
# de matriculados e concluintes/titulados em cursos de bacharelado,
# mestrado e doutorado.
#
# Autor: João Paulo Garcia
# email: joao.garcia@fjp.mg.gov.br
# -------------------------------------------
# LEITURA DOS DADOS

# OCDE - Number of enrolled students, graduates and new entrants by
# ...... field of education

# carregar objetos de uso geral
source("utilitarios.R")

arquivo_ocde <- "../fontes/OCDE_estudantes_por_campo.csv"

if (!file.exists(arquivo_ocde)) {
	resposta <- readline(paste0(
		"O arquivo 'OCDE_estudantes_por_campo.csv' não foi encontrado.",
		" Deseja baixá-lo agora? (s/n): "
	))
	if (grepl(pattern = "[SsYy]", resposta)) {
		source("../baixar-fontes/baixar_OCDE.R", chdir = TRUE)
	} else {
		stop("Download cancelado")
	}
}

colunas_ocde <- c(
	"TIME_PERIOD"     = "integer",
	"REF_AREA"        = "character",
	"MEASURE"         = "factor",
	"INST_TYPE_EDU"   = "factor",
	"EDUCATION_LEV"   = "factor",
	"EDUCATION_FIELD" = "factor",
	"MOBILITY"        = "factor",
	"SEX"             = "factor",
	"OBS_STATUS"      = "factor",
	"OBS_VALUE"       = "numeric"
)

dados_ocde <- read.csv(arquivo_ocde, colClasses = colunas_ocde)
dados_ocde <- dados_ocde[, names(colunas_ocde)]

# UNESCO - Percentage of graduates from STEM programmes in tertiary
# ........ education

arquivo_unesco <- "../fontes/OPRI_DATA_NATIONAL.csv"

if (!file.exists(arquivo_unesco)) {
	resposta <- readline(paste0(
		"O arquivo 'OPRI_DATA_NATIONAL.csv' não foi encontrado.",
		" Deseja baixá-lo agora? (s/n): "
	))
	if (grepl(pattern = "[SsYy]", resposta)) {
		source("../baixar-fontes/baixar_UNESCO.R", chdir = TRUE)
	} else {
		stop("Download cancelado")
	}
}

id_filtro <- c(
	"25052",                # Enrolment in ISCED 8 programmes, both sexes 
	"25053",                # Enrolment in all programmes, both sexes 
	"25057",                # Enrolment in all programmes, female 
	"42620",                # Enrolment in all programmes, male 
	"42654",                # Enrolment in ISCED 6 programmes, both sexes 
	"42656",                # Enrolment in ISCED 7 programmes, both sexes 
	"ETOIP.5T8.PR",         # % of enrolment in private institutions
	"ETOIP.5T8.PU",         # % of enrolment in public institutions
	"FOSGP.5T8.F500600700"  # %  of graduates from STEM programmes
)

dados_unesco <- read.csv(arquivo_unesco, row.names = NULL)
dados_unesco$MAGNITUDE <- NULL
dados_unesco <- dados_unesco[
	dados_unesco$INDICATOR_ID %in% id_filtro &
	dados_unesco$COUNTRY_ID %in% mapa_paises$ISO3 &
	dados_unesco$YEAR %in% 2000:2024,
]

# -------------------------------------------
# CONCLUINTES

ct_conctot <- dados_ocde[dados_ocde$MEASURE == "GRAD", ]
ct_conctot$MEASURE <- NULL

# -------------------------------------------
# MATRICULADOS

ct_matot <- dados_unesco[ct_matot$INDICATOR_ID == "]

ct_matot_area <- dados_ocde[
	dados_ocde$MEASURE == "ENRL" &
	dados_ocde$MOBILITY == "_T" &
	dados_ocde$SEX == "_T",
]
ct_matot_area$MEASURE <- NULL
ct_matot_area$MOBILITY <- NULL
ct_matot_area$SEX <- NULL

# -------------------------------------------
# BACHAREIS (GRADUADOS)
ct_bachareis <- dados_ocde[
	dados_ocde$MEASURE == "GRAD" &
	dados_ocde$EDUCATION_LEV == "ISCED11_6",
]
ct_bachareis$MEASURE <- NULL
ct_bachareis$EDUCATION_LEV <- NULL

ct_bachareis_areas <- ct_bachareis[
	ct_bachareis$MOBILITY == "_T" &
	ct_bachareis$SEX == "_T",
]
