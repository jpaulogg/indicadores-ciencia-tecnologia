# Rotina para automatizar a construção de indicadores internacionais
# de número de pesquisadores, por setor de atuação e sexo.
#
# autor: João Paulo Garcia
# email: joao.garcia@fjp.mg.gov.br
#
# Obs.: os objetos `input_dir` e `dl_dir` está definido em "setup.R".
# -------------------------------------------------------------------

# LEITURA DOS DADOS

# 1. UNESCO - Science, Technology and Innovation (R&D personnel)

arq_unesco <- file.path(input_dir, "UNESCO_SCN_OPRI_ocup", "data.csv")
dl_unesco <- file.path(dl_dir, "ocup_UNESCO.R")

if (!file.exists(arq_unesco)) {
	resposta <- readline(paste0(
		"O arquivo de dados não foi encontrado.",
		" Deseja baixá-lo agora? (s/n): "
	))
	if (grepl(pattern = "^[SsYy]", resposta)) {
		source(dl_unesco, chdir = TRUE)
	} else {
		stop("Download cancelado")
	}
}

dados_unesco <- read.csv(arq_unesco)

# 2. OIT - Employment in STEM occupations by sex and status

arq_oit <- c(
	total = file.path(input_dir, "OIT_EMP_TEMP_AGE_STE_NB_A.csv"),
	stem  = file.path(input_dir, "OIT_EMP_STEM_SEX_STE_NB_A.csv")
)

dl_oit <- file.path(dl_dir, "ocup_OIT")

if (!all(file.exists(arq_oit))) {
	resposta <- readline(paste0(
		"Pelo menos um arquivo de dados não foi encontrado.",
		" Deseja baixá-lo(s) agora? (s/n): "
	))
	if (grepl(pattern = "^[SsYy]", resposta)) {
		source(dl_oit, chdir = TRUE)
	} else {
		stop("Download cancelado")
	}
}

dados_oit_t <- read.csv(arq_oit["total"])
dados_oit_stem <- read.csv(arq_oit["stem"])

# -------------------------------------------
# INDICADORES

# 1. Número de pesquisadores (HC)
ct_pesq <- list()

# 1.1 Total
ct_pesq$total <- dados_unesco[
	dados_unesco$indicatorId == 21001,
]

# 1.2 Por setor de atuação
id_setor <- c(21205, 21209, 21213, 21217)
ct_pesq$setor <- dados_unesco[
	dados_unesco$indicatorId %in% id_setor,
]

# 1.3 Por sexo
# UNESCO disponibiliza o total (21001) e o feminino (21105).
# O masculino é calculado pela diferença entre os dois.
ct_pesq$sexo <- dados_unesco[
	dados_unesco$indicatorId == 21105,
]
ct_pesq$sexo$sexo <- "F"

pesq_masc <- merge(
	ct_pesq$total[, c("geoUnit", "year", "value")],
	ct_pesq$sexo[, c("geoUnit", "year", "value")],
	by = c("geoUnit", "year"),
	suffixes = c(".total", ".fem")
)

pesq_masc$value <- pesq_masc$value.total - pesq_masc$value.fem
pesq_masc$indicatorId <- NA_integer_
pesq_masc$qualifier <- "CALCULADO"
pesq_masc$magnitude <- ""
pesq_masc$sexo <- "M"

pesq_masc <- pesq_masc[, names(ct_pesq$sexo)]
ct_pesq$sexo <- rbind(ct_pesq$sexo, pesq_masc)

# 2. Emprego em ocupações STEM (CT_TRABSTEM)
ct_trabstem <- list()

# 2.1 Total (todas as posições na ocupação)
ct_trabstem$total <- dados_oit_stem[
	dados_oit_stem$sex == "SEX_T" &
	dados_oit_stem$classif1 == "STE_AGGREGATE_TOTAL",
]

# 2.2 Por sexo
ct_trabstem$sexo <- dados_oit_stem[
	dados_oit_stem$sex %in% c("SEX_M", "SEX_F") &
	dados_oit_stem$classif1 == "STE_AGGREGATE_TOTAL",
]

# 2.3 Percentual em relação ao total de pessoas ocupadas (15 anos ou mais)
# Os dois arquivos apresentam os valores em milhares.
# O campo `source` é mantido no pareamento para não combinar pesquisas distintas.
emprego_total <- dados_oit_t[
	dados_oit_t$classif1 == "AGE_YTHADULT_YGE15" &
	dados_oit_t$classif2 == "STE_AGGREGATE_TOTAL",
]

ct_trabstem$percentual <- merge(
	ct_trabstem$total,
	emprego_total[, c("ref_area", "source", "time", "obs_value")],
	by = c("ref_area", "source", "time"),
	suffixes = c(".stem", ".total")
)

ct_trabstem$percentual$percentual <- with(
	ct_trabstem$percentual,
	100 * obs_value.stem / obs_value.total
)
ct_trabstem$percentual$percentual[
	ct_trabstem$percentual$obs_value.total == 0
] <- NA_real_
