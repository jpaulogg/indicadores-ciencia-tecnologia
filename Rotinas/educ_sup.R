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

arquivo_ocde <- "../Fontes/OCDE_matriculados_por_campo.csv"

if (!file.exists(arquivo_ocde)) {
	resposta <- readline(paste0(
		"O arquivo 'OECD_enrl_by_field.csv' não foi encontrado.",
		" Deseja baixá-lo agora? (s/n): "
	))
	if (tolower(trimws(resposta)) %in% c("s", "sim", "y")) {
		source("../Baixar-Fontes/baixar_OCDE.R", chdir = TRUE)
	} else {
		stop("Download cancelado")
	}
}

colunas_ocde <- c(
	"TIME_PERIOD"     = "integer",
	"REF_AREA"        = "character",
	"EDUCATION_LEV"   = "factor",
	"EDUCATION_FIELD" = "factor",
	"MEASURE"         = "factor",
	"MOBILITY"        = "factor",
	"SEX"             = "factor",
	"OBS_STATUS"      = "factor",
	"OBS_VALUE"       = "numeric"
)

dados_ocde <- read.csv(arquivo_ocde, colClasses = colunas_ocde)
dados_ocde <- dados_ocde[, names(colunas_ocde)]

# -------------------------------------------
# CONCLUINTES

ct_conctot <- dados_ocde[dados_ocde$MEASURE == "GRAD", ]
ct_conctot$MEASURE <- NULL

# -------------------------------------------
# MATRICULADOS
ct_matot <- dados_ocde[dados_ocde$MEASURE == "ENRL", ]
ct_matot$MEASURE <- NULL

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
