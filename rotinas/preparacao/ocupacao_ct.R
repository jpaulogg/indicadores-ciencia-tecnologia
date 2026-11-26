# Rotina para automatizar a construção de indicadores internacionais
# de número de pesquisadores (por setor de atuação e sexo) e
# emprego em ocupações STEM (total, por sexo e % do emprego total).
#
# autor: João Paulo Garcia
# email: joao.garcia@fjp.mg.gov.br
#
# Obs.: os objetos `input_dir` e `dl_dir` estão definidos em "setup.R".
# -------------------------------------------------------------------
# DICIONÁRIOS

setores_pesq <- c(
	"21205" = "Business Enterprise",
	"21209" = "Government",
	"21213" = "Higher Education",
	"21217" = "Private Non-Profit"
)

rotulos_sexo <- c(
	"SEX_F" = "F",
	"SEX_M" = "M"
)

# -------------------------------------------------------------------
# LEITURA DOS DADOS

# 1. UNESCO - Science, Technology and Innovation (R&D personnel)

arq_unesco <- file.path(input_dir, "UNESCO_ocup", "data.csv")
dl_unesco <- file.path(dl_dir, "ocup_UNESCO.R")

if (!file.exists(arq_unesco)) {
	resposta <- readline(paste0(
		"O arquivo de dados de R&D personnel (UNESCO) não foi encontrado.",
		" Deseja baixá-lo agora? (s/n): "
	))
	if (grepl(pattern = "^[SsYy]", resposta)) {
		source(dl_unesco, chdir = TRUE)
	} else {
		stop("Download cancelado")
	}
}

colunas_unesco <- c(
	"geoUnit"     = "character",
	"year"        = "integer",
	"indicatorId" = "character",
	"value"       = "numeric",
	"qualifier"   = "NULL",
	"magnitude"   = "NULL"
)

dados_unesco <- read.csv(arq_unesco, colClasses = colunas_unesco)

# 2. OIT - Employment in STEM occupations by sex and status

arq_oit <- c(
	total = file.path(input_dir, "OIT_EMP_TEMP_AGE_STE_NB_A.csv"),
	stem  = file.path(input_dir, "OIT_EMP_STEM_SEX_STE_NB_A.csv")
)

dl_oit <- file.path(dl_dir, "ocup_OIT.R")

if (!all(file.exists(arq_oit))) {
	resposta <- readline(paste0(
		"Pelo menos um arquivo de dados da OIT não foi encontrado.",
		" Deseja baixá-lo(s) agora? (s/n): "
	))
	if (grepl(pattern = "^[SsYy]", resposta)) {
		source(dl_oit, chdir = TRUE)
	} else {
		stop("Download cancelado")
	}
}

dados_oit_t <- read.csv(arq_oit["total"])
dados_oit_t <- dados_oit_t[,
	c("ref_area", "source", "classif1", "classif2", "time", "obs_value")
]
dados_oit_stem <- read.csv(arq_oit["stem"])
dados_oit_stem <- dados_oit_stem [
	c("ref_area", "source", "sex", "classif1", "time", "obs_value")
]

# -------------------------------------------
# INDICADORES

# 1. Número de pesquisadores (HC)
ct_pesq <- list()

ct_pesq$total <- dados_unesco[
	dados_unesco$indicatorId == "21001",
]

ct_pesq$setor <- dados_unesco[
	dados_unesco$indicatorId %in% names(setores_pesq),
]
ct_pesq$setor$setor_nome <- factor(
	unname(setores_pesq[ct_pesq$setor$indicatorId]),
	levels = unname(setores_pesq)
)

ct_pesq$sexo <- dados_unesco[
	dados_unesco$indicatorId == "21105",
]
ct_pesq$sexo$sexo_nome <- "F"

pesq_masc <- merge(
	ct_pesq$total[, c("geoUnit", "year", "value")],
	ct_pesq$sexo[, c("geoUnit", "year", "value")],
	by = c("geoUnit", "year"),
	suffixes = c(".total", ".fem")
)

pesq_masc$value <- pesq_masc$value.total - pesq_masc$value.fem
pesq_masc$indicatorId <- NA_character_
pesq_masc$sexo_nome <- "M"

pesq_masc <- pesq_masc[, names(ct_pesq$sexo)]
ct_pesq$sexo <- rbind(ct_pesq$sexo, pesq_masc)

ct_pesq$sexo$sexo_nome <- factor(
	ct_pesq$sexo$sexo_nome,
	levels = c("F", "M")
)

# 2. emprego em ocupações stem
ct_trabstem <- list()

ct_trabstem$total <- dados_oit_stem[
	dados_oit_stem$sex == "SEX_T" &
	dados_oit_stem$classif1 == "STE_AGGREGATE_TOTAL",
]

ct_trabstem$sexo <- dados_oit_stem[
	dados_oit_stem$sex %in% c("SEX_M", "SEX_F") &
	dados_oit_stem$classif1 == "STE_AGGREGATE_TOTAL",
]

ct_trabstem$sexo$sexo_nome <- factor(
	unname(rotulos_sexo[ct_trabstem$sexo$sex]),
	levels = c("F", "M")
)

# valores em milhares.
# O campo `source` é mantido para não combinar pesquisas distintas.
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
