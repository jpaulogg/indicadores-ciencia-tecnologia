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

# OBS_STATUS == "M" significa valores que não podem existir
dados_ocde$OBS_VALUE[dados_ocde$OBS_STATUS == "M"] <- 0

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
	"42620"                   # Enrolment in all programmes, male 
)

dados_unesco <- read.csv(arquivo_unesco)
dados_unesco$MAGNITUDE <- NULL
dados_unesco <- dados_unesco[
	dados_unesco$INDICATOR_ID %in% id_unesco &
	dados_unesco$COUNTRY_ID %in% mapa_paises$ISO3 &
	dados_unesco$YEAR %in% periodo,
]

# -------------------------------------------
# FUNÇÕES

# Função para agregar a base da OCDE. Ao usá-la, é necessário filtrar
# colunas que possuem categorias de "Totais" e que não serão agrupadas.
agregar <- function(dados, .ref_var = NULL, .estrito = TRUE) {
	agrupadores <- c("REF_AREA", "TIME_PERIOD", .ref_var)
	form <- reformulate(termlabels = agrupadores, response = "OBS_VALUE")
	
	# se .estrito = TRUE, qualquer NA invalida a soma
	# se .estrito = FALSE, soma o que estiver disponível
	soma_estrita <- function(x) {
		if (all(is.na(x))) return(NA_real_)
		sum(x, na.rm = !.estrito)
	}
	aggregate(
		form,
		data = dados,
		FUN = soma_estrita,
		na.action = na.pass
	)
}

# Função para gerar blocos de agregações de campo de estudo, sexo,
# tipo de instituição e total de concluintes/titulados.
agregar.bloco <- function(dados, .nivel = NULL, .stem = FALSE) {

	# filtros iniciais
	df <- dados[dados$MEASURE == "GRAD", ]
	if (!is.null(.nivel)) {
		df <- df[df$EDUCATION_LEV == .nivel, ]
	}

	# áreas STEM (não é possível desagregar por tipo de instituição)
	# ver table(dados_ocde$EDUCATION_FIELD, dados_ocde$INST_TYPE_EDU)
	if (.stem) {
		df_stem <- df[
			df$EDUCATION_FIELD %in% c("F05", "F06", "F07") &
			df$INST_TYPE_EDU == "INST_EDU",
		]
		df_stem$EDUCATION_FIELD <- droplevels(df_stem$EDUCATION_FIELD)

		return(list(
			campo = agregar(df_stem, "EDUCATION_FIELD"),
			sexo  = agregar(df_stem, "SEX"),
			total = agregar(df_stem)
		))
	}

	# todas as áreas
	df_tot <- df[
		df$EDUCATION_FIELD != "_T" &
		df$INST_TYPE_EDU == "INST_EDU",
	]
	df_tot$EDUCATION_FIELD <- droplevels(df_tot$EDUCATION_FIELD)

	df_inst <- df[
		df$EDUCATION_FIELD == "_T" &
		df$INST_TYPE_EDU != "INST_EDU",
	]
	df_inst$INST_TYPE_EDU <- droplevels(df_inst$INST_TYPE_EDU)

	list(
		campo = agregar(df_tot, "EDUCATION_FIELD"),
		sexo  = agregar(df_tot, "SEX"),
		total = agregar(df_tot),
		inst  = agregar(df_inst, "INST_TYPE_EDU")
	)
}

# -------------------------------------------
# 1. CONCLUINTES/TITULADOS

# concluintes em programas de bacharelado, mestrado ou doutorado
ct_conctot <- agregar.bloco(dados_ocde)
ct_concstem <- agregar.bloco(dados_ocde, .stem = TRUE)

# concluintes em programas de bacharelado
ct_bachareis <- agregar.bloco(dados_ocde, "ISCED11_6")
ct_bachareistem <- agregar.bloco(
	dados_ocde,
	"ISCED11_6",
	.stem = TRUE
)

# titulados em programas de mestrado
ct_mestres <- agregar.bloco(dados_ocde, "ISCED11_7")
ct_mestrestem <- agregar.bloco(
	dados_ocde,
	"ISCED11_7",
	.stem = TRUE
)

# titulados em programas de doutorado
ct_doutores <- agregar.bloco(dados_ocde, "ISCED11_8")
ct_doutorestem <- agregar.bloco(
	dados_ocde,
	"ISCED11_8",
	.stem = TRUE
)

# -------------------------------------------
# 2. MATRICULADOS

# 2.1 Matriculados em todas as áreas (CT_MATOT)

# dados da UNESCO abrangem período mais longo e maior número de países
matot_total <- dados_unesco[dados_unesco$INDICATOR_ID == "25053", ]

id_mat_sexo <- c("25057", "42620")
matot_sexo <- dados_unesco[dados_unesco$INDICATOR_ID %in% id_mat_sexo, ]

id_mat_inst <- c("ETOIP.5T8.PR", "ETOIP.5T8.PU")
matot_inst <- dados_unesco[dados_unesco$INDICATOR_ID %in% id_mat_inst, ]

# dados da OCDE permitem desagregar por campo de estudo e instituições
matot_campo <- agregar(
	dados = dados_ocde[
		dados_ocde$MEASURE == "ENRL" &
		dados_ocde$EDUCATION_FIELD != "_T" &
		dados_ocde$INST_TYPE_EDU == "INST_EDU",
	],
	.ref_var = "EDUCATION_FIELD"
)
matot_ocde$EDUCATION_FIELD <- droplevels(matot_ocde$EDUCATION_FIELD)

rm(matot_ocde)

# 2.2 Matriculados em cursos STEM (CT_MATSTEM)

matstem_ocde <- dados_ocde[
	dados_ocde$MEASURE == "ENRL" &
	dados_ocde$EDUCATION_FIELD %in% c("F05", "F06", "F07") &
	dados_ocde$INST_TYPE_EDU == "INST_EDU",
]
matstem_ocde$MEASURE <- NULL
matstem_ocde$INST_TYPE_EDU <- NULL
matstem_ocde$EDUCATION_FIELD <- droplevels(matstem_ocde$EDUCATION_FIELD)

matstem_campo <- agregar(matstem_ocde, "EDUCATION_FIELD" )
matstem_sexo  <- agregar(matstem_ocde, "SEX")
matstem_total <- agregar(matstem_ocde)

rm(matstem_ocde)
