# Rotina para automatizar a construção de indicadores internacionais
# de comércio de produtos de média e alta tecnologia (MHT) e comércio total.
#
# autor: João Paulo Garcia
# email: joao.garcia@fjp.mg.gov.br
#
# Obs.: os objetos `input_dir` e `dl_dir` estão definidos em "setup.R".
# -------------------------------------------

# LEITURA DOS DADOS

# 1. UNIDO - Comércio Internacional de Manufaturas (MTD)
arq_comercio <- file.path(input_dir, "UNIDO_comercio", "data.csv")
dl_comercio <- file.path(dl_dir, "comercio_UNIDO.R")

if (!file.exists(arq_comercio)) {
	resposta <- readline(paste0(
		"O arquivo de dados de comércio ('UNIDO_comercio/data.csv') não foi encontrado.",
		" Deseja baixá-lo agora? (s/n): "
	))
	if (grepl(pattern = "^[SsYy]", resposta)) {
		source(dl_comercio, chdir = TRUE)
	} else {
		stop("Download cancelado")
	}
}

colunas_unido <- c(
	"CountryCode"  = "character",
	"Country"      = "character",
	"VariableCode" = "character",
	"Year"         = "integer",
	"Value"        = "numeric"
)

dados_comercio <- read.csv(arq_comercio, colClasses = colunas_unido)
dados_comercio <- dados_comercio[, names(colunas_unido)]

# Filtrar e incorporar as siglas ISO3 do mapa_paises
dados_comercio <- merge(
	dados_comercio,
	mapa_paises[, c("ISO_NUM", "ISO3")],
	by.x = "CountryCode",
	by.y = "ISO_NUM"
)

# -------------------------------------------
# INDICADORES

# 1. EXPORTAÇÕES DE MÉDIA-ALTA TECNOLOGIA (CT_EXPTEC)
ct_exptec <- list()

# 1.1 Total (em USD)
ct_exptec$total <- dados_comercio[
	dados_comercio$VariableCode == "X_MHT",
]

# 1.2 Percentual (% das exportações totais de bens)
exp_mht <- dados_comercio[dados_comercio$VariableCode == "X_MHT", ]
exp_tot <- dados_comercio[dados_comercio$VariableCode == "X_T", ]

ct_exptec$percentual <- merge(
	exp_mht[, c("ISO3", "Country", "Year", "Value")],
	exp_tot[, c("ISO3", "Year", "Value")],
	by = c("ISO3", "Year"),
	suffixes = c(".mht", ".total")
)

ct_exptec$percentual$percentual <- with(
	ct_exptec$percentual,
	100 * Value.mht / Value.total
)
ct_exptec$percentual$percentual[
	ct_exptec$percentual$Value.total == 0
] <- NA_real_


# 2. IMPORTAÇÕES DE MÉDIA-ALTA TECNOLOGIA (CT_IMPTEC)
ct_imptec <- list()

# 2.1 Total (em USD)
ct_imptec$total <- dados_comercio[
	dados_comercio$VariableCode == "M_MHT",
]

# 2.2 Percentual (% das importações totais de bens)
imp_mht <- dados_comercio[dados_comercio$VariableCode == "M_MHT", ]
imp_tot <- dados_comercio[dados_comercio$VariableCode == "M_T", ]

ct_imptec$percentual <- merge(
	imp_mht[, c("ISO3", "Country", "Year", "Value")],
	imp_tot[, c("ISO3", "Year", "Value")],
	by = c("ISO3", "Year"),
	suffixes = c(".mht", ".total")
)

ct_imptec$percentual$percentual <- with(
	ct_imptec$percentual,
	100 * Value.mht / Value.total
)
ct_imptec$percentual$percentual[
	ct_imptec$percentual$Value.total == 0
] <- NA_real_
