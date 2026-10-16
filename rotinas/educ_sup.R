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
source("setup.R")

arquivo_ocde <- file.path(input_dir, "OCDE_estudantes_por_campo.csv")

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
	"SEX"             = "factor",
	"OBS_STATUS"      = "factor",
	"OBS_VALUE"       = "numeric"
)

dados_ocde <- read.csv(arquivo_ocde, colClasses = colunas_ocde)
dados_ocde <- dados_ocde[, names(colunas_ocde)]

# UNESCO - Percentage of graduates from STEM programmes in tertiary
# ........ education

arquivo_unesco <- file.path(input_dir, "OPRI_DATA_NATIONAL.csv")

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
	"42620",                  # Enrolment in all programmes, male 
	"42654",                  # Enrolment in ISCED 6 programmes
	"42635",                  # Enrolment in ISCED 6 programmes, female
	"42615",                  # Enrolment in ISCED 6 programmes, male
	"42656",                  # Enrolment in ISCED 7 programmes
	"42637",                  # Enrolment in ISCED 7 programmes, female
	"42617",                  # Enrolment in ISCED 7 programmes, male
	"25052",                  # Enrolment in ISCED 8 programmes
	"25056",                  # Enrolment in ISCED 8 programmes, female
	"42619"                   # Enrolment in ISCED 8 programmes, male
)

dados_unesco <- read.csv(arquivo_unesco)
dados_unesco$MAGNITUDE <- NULL
dados_unesco <- dados_unesco[
	dados_unesco$INDICATOR_ID %in% id_unesco &
	dados_unesco$COUNTRY_ID %in% mapa_paises$ISO3 &   # ver global.R
	dados_unesco$YEAR %in% 2000:2024,
]

# -------------------------------------------
# CT_CONC_TOT - Concluintes em todas as áreas

# filtros iniciais
grad_total_ocde <- dados_ocde[
	dados_ocde$MEASURE == "GRAD" &
	dados_ocde$EDUCATION_FIELD == "_T",
]
grad_total_ocde$MEASURE <- NULL
grad_total_ocde$EDUCATION_FIELD <- droplevels(
	grad_total_ocde$EDUCATION_FIELD
)

# agregar tudo menos tipo de instituição
conctot_inst <- aggregate(
	OBS_VALUE ~ REF_AREA + TIME_PERIOD + INST_TYPE_EDU,
	data = grad_total_ocde,
	FUN = sum,
	na.action = na.pass,
	na.rm = TRUE
)
conctot_inst$INST_TYPE_EDU <- droplevels(conctot_inst$INST_TYPE_EDU)

# adicionar filtro institucional aos filtros iniciais
grad_total_ocde <- grad_total_ocde[
	grad_total_ocde$INST_TYPE_EDU == "INST_EDU", 
]

# agregar tudo menos sexo
conctot_sexo <- aggregate(
	OBS_VALUE ~ REF_AREA + TIME_PERIOD + SEX,
	data = grad_total_ocde,
	FUN = sum,
	na.action = na.pass,
	na.rm = TRUE
)
conctot_sexo$SEX <- droplevels(conctot_sexo$SEX)

# agregar tudo
conctot_total <- aggregate(
	OBS_VALUE ~ REF_AREA + TIME_PERIOD,
	data = grad_total_ocde,
	FUN = sum,
	na.action = na.pass,
	na.rm = TRUE
)

# CT_CONCSTEM - Concluintes em áreas STEM

# filtros iniciais
grad_stem_ocde <- dados_ocde[
	dados_ocde$MEASURE == "GRAD" &
	dados_ocde$INST_TYPE_EDU == "INST_EDU" &
	dados_ocde$EDUCATION_FIELD %in% c("F05", "F06", "F07"),
]
grad_stem_ocde$MEASURE <- NULL
grad_stem_ocde$INST_TYPE_EDU <- NULL
grad_stem_ocde$EDUCATION_FIELD <- droplevels(
	grad_stem_ocde$EDUCATION_FIELD
)

# agregar tudo menos sexo
concstem_sexo <- aggregate(
	OBS_VALUE ~ REF_AREA + TIME_PERIOD + SEX,
	data = grad_stem_ocde,
	FUN = sum,
	na.action = na.pass,
	na.rm = TRUE
)

# agregar tudo menos campo de estudo
concstem_campo <- aggregate(
	OBS_VALUE ~ REF_AREA + TIME_PERIOD + EDUCATION_FIELD,
	data = grad_stem_ocde,
	FUN = sum,
	na.action = na.pass,
	na.rm = TRUE
)

# agregar tudo
concstem_campo <- aggregate(
	OBS_VALUE ~ REF_AREA + TIME_PERIOD,
	data = grad_stem_ocde,
	FUN = sum,
	na.action = na.pass,
	na.rm = TRUE
)

# CT_CONCSTEM_PERCENT

id_stem_sexo <- c("FOSGP.5T8.F500600700.F", "FOSGP.5T8.F500600700.M")

concstem_prcnt_sexo <- dados_unesco[
	dados_unesco$INDICATOR_ID %in% id_stem_sexo,
]


# -------------------------------------------
# MATRICULADOS

matot <- dados_unesco[matot$INDICATOR_ID == "]

matot_campo <- dados_ocde[
	dados_ocde$MEASURE == "ENRL" &
	dados_ocde$MOBILITY == "_T" &
	dados_ocde$SEX == "_T",
]
matot_campo$MEASURE <- NULL
matot_campo$MOBILITY <- NULL
matot_campo$SEX <- NULL

# -------------------------------------------
# BACHAREIS (GRADUADOS)
bachareis <- dados_ocde[
	dados_ocde$MEASURE == "GRAD" &
	dados_ocde$EDUCATION_LEV == "ISCED11_6",
]
bachareis$MEASURE <- NULL
bachareis$EDUCATION_LEV <- NULL

bachareis_campo <- bachareis[
	bachareis$MOBILITY == "_T" &
	bachareis$SEX == "_T",
]
