# Rotina para automatizar a construção de indicadores internacionais
# de dispêndio em C&T e P&D (valores absolutos em PPP$ e % do PIB).
#
# autor: João Paulo Garcia
# email: joao.garcia@fjp.mg.gov.br
#
# Obs.: os objetos `input_dir` e `dl_dir` estão definidos em "setup.R".
# -------------------------------------------------------------------
# DICIONÁRIOS

setores_exec <- c(
	"EXPPPP.CONST.SP.BUSENTSP" = "Business Enterprise",
	"EXPPPP.CONST.SP.GOVSP"    = "Government",
	"EXPPPP.CONST.SP.HIEDUSP"  = "Higher Education",
	"EXPPPP.CONST.SP.PRNPSP"   = "Private Non-Profit",
	"EXPPPP.CONST.SP.SPNS"     = "Not Specified Sectors"
)

setores_exec_pib <- c(
	"EXPGDP.SP.BUSENTSP" = "Business Enterprise",
	"EXPGDP.SP.GOVSP"    = "Government",
	"EXPGDP.SP.HIEDUSP"  = "Higher Education",
	"EXPGDP.SP.PRNPSP"   = "Private Non-Profit",
	"EXPGDP.SP.SPNS"     = "Not Specified Sectors"
)

setores_financ <- c(
	"EXPPPP.CONST.SF.BUSENTFS" = "Business Enterprise",
	"EXPPPP.CONST.SF.GOVFS"    = "Government",
	"EXPPPP.CONST.SF.HIEDUFS"  = "Higher Education",
	"EXPPPP.CONST.SF.PRNPFS"   = "Private Non-Profit",
	"EXPPPP.CONST.SF.FUNABFS"  = "Rest of the World",
	"EXPPPP.CONST.SF.FSNS"     = "Not Specified Source"
)

# -------------------------------------------
# LEITURA DOS DADOS

# UNESCO - Science, Technology and Innovation (OPRI)
arq_disp <- file.path(input_dir, "UNESCO_disp", "data.csv")
dl_disp <- file.path(dl_dir, "disp_UNESCO.R")

if (!file.exists(arq_disp)) {
	resposta <- readline(paste0(
		"O arquivo de dados de dispêndio (UNESCO) não foi encontrado.",
		" Deseja baixá-lo agora? (s/n): "
	))
	if (grepl(pattern = "^[SsYy]", resposta)) {
		source(dl_disp, chdir = TRUE)
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

dados_disp <- read.csv(arq_disp, colClasses = colunas_unesco)

# -------------------------------------------
# INDICADORES

# 1. Dispêndio em p&d em valores absolutos
# unidade: '000 PPP$ a preços constantes de 2017
ct_disppd <- list()

ct_disppd$total <- dados_disp[
	dados_disp$indicatorId == "EXPPPP.CONST",
]

ct_disppd$executor <- dados_disp[
	dados_disp$indicatorId %in% names(setores_exec),
]
ct_disppd$executor$setor_nome <- factor(
	unname(setores_exec[ct_disppd$executor$indicatorId]),
	levels = unname(setores_exec)
)

ct_disppd$financiador <- dados_disp[
	dados_disp$indicatorId %in% names(setores_financ),
]
ct_disppd$financiador$setor_nome <- factor(
	unname(setores_financ[ct_disppd$financiador$indicatorId]),
	levels = unname(setores_financ)
)

# 2. Dispêndio em P&D como percentual do PIB
ct_disppdpib <- list()

ct_disppdpib$total <- dados_disp[
	dados_disp$indicatorId == "EXPGDP.TOT",
]

ct_disppdpib$executor <- dados_disp[
	dados_disp$indicatorId %in% names(setores_exec_pib),
]
ct_disppdpib$executor$setor_nome <- factor(
	unname(setores_exec_pib[ct_disppdpib$executor$indicatorId]),
	levels = unname(setores_exec_pib)
)
