# Rotina para automatizar a construção de indicadores internacionais
# de matriculados e concluintes/titulados em cursos de bacharelado,
# mestrado e doutorado.
#
# Autor: João Paulo Garcia
# email: joao.garcia@fjp.mg.gov.br
# -------------------------------------------
# Os seguintes objetos estão definidos em "setup.R":
# ... dl_dir (diretório de rotinas para baixar fontes)
# ... input_dir (diretório de fonte de dados)
# ... periodo (por padrão, 2000:2025)
# ... mapa_paises (siglas ISO3 e ISO2 de grupos de países selecionados)

# LEITURA DOS DADOS

# 1. OCDE - Number of enrolled students, graduates
# .......... and new entrants by field of education

arquivo_ocde <- file.path(input_dir, "OCDE_estudantes_por_campo.csv")
dl_script <- file.path(dl_dir, "educ_OCDE.R")

if (!file.exists(arquivo_ocde)) {
	resposta <- readline(paste0(
		"O arquivo 'OCDE_estudantes_por_campo.csv' não foi encontrado.",
		" Deseja baixá-lo agora? (s/n): "
	))
	if (grepl(pattern = "^[SsYy]", resposta)) {
		source(dl_file, chdir = TRUE)
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

# 2. UNESCO - Other Policy Relevant Indicators (Education – OPRI)

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

# 1. Função para agregar a base da OCDE. Ao usá-la, é necessário excluir
# .. linhas que possuem "Totais" agregados e que não serão agrupadas.
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

# 2. Função para gerar blocos de agregações de campo de estudo, sexo,
# .. tipo de instituição e total de concluintes/titulados e matriculados
agregar.bloco <- function(dados, .medida = "GRAD", .nivel = NULL, .stem = FALSE) {

	# filtros iniciais
	df <- dados[dados$MEASURE == .medida, ]
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
# INDICADORES

# 1. Concluintes/Titulados

# 1.1 Concluintes e titulados em todas as áreas
ct_conctot   <- agregar.bloco(dados_ocde)
ct_bachareis <- agregar.bloco(dados_ocde, .nivel = "ISCED11_6")
ct_mestres   <- agregar.bloco(dados_ocde, .nivel = "ISCED11_7")
ct_doutores  <- agregar.bloco(dados_ocde, .nivel = "ISCED11_8")

# 1.2 Concluintes e titulados em áreas STEM
ct_concstem <- agregar.bloco(dados_ocde, .stem = TRUE)

ct_bachareistem <- agregar.bloco(
	dados_ocde,
	.nivel = "ISCED11_6",
	.stem = TRUE
)

ct_mestrestem <- agregar.bloco(
	dados_ocde,
	.nivel = "ISCED11_7",
	.stem = TRUE
)

ct_doutorestem <- agregar.bloco(
	dados_ocde,
	.nivel = "ISCED11_8",
	.stem = TRUE
)

# 2. Matriculados

# 2.1 Matriculados em todas as áreas (CT_MATOT)
ct_matot <- vector(mode = "list", length = 4)

# dados da UNESCO abrangem período mais longo e maior número de países
ct_matot$total <- dados_unesco[dados_unesco$INDICATOR_ID == "25053",]

id_mat_sexo <- c("25057", "42620")
ct_matot$sexo <- dados_unesco[dados_unesco$INDICATOR_ID %in% id_mat_sexo,]

id_mat_inst <- c("ETOIP.5T8.PR", "ETOIP.5T8.PU")
ct_matot$inst <- dados_unesco[dados_unesco$INDICATOR_ID %in% id_mat_inst,]

# dados da OCDE permitem desagregar por campo de estudo
ct_matot$campo <- agregar(
	dados = dados_ocde[
		dados_ocde$MEASURE == "ENRL" &
		dados_ocde$EDUCATION_FIELD != "_T" &
		dados_ocde$INST_TYPE_EDU == "INST_EDU",
	],
	.ref_var = "EDUCATION_FIELD"
)
ct_matot$campo$EDUCATION_FIELD <- droplevels(
	ct_matot$campo$EDUCATION_FIELD
)

# 2.2 Matriculados em cursos STEM (CT_MATSTEM)
ct_matstem <- agregar.bloco(
	dados_ocde,
	.medida = "ENRL",
	.stem = TRUE
)
