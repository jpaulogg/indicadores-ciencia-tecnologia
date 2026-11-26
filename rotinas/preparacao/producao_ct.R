# Rotina para automatizar a construção de indicadores internacionais
# de artigos científicos, por total e área do conhecimento.
#
# autor: João Paulo Garcia
# email: joao.garcia@fjp.mg.gov.br
#
# O objeto `input_dir` está definido em "setup.R".
# -------------------------------------------
# DICIONÁRIOS

macro_topicos_wos <- c(
	"Clinical & Life Sciences",
	"Chemistry",
	"Agriculture, Environment & Ecology",
	"Electrical Engineering, Electronics & Computer Science",
	"Physics",
	"Social Sciences",
	"Engineering & Materials Science",
	"Earth Sciences",
	"Mathematics",
	"Arts & Humanities"
)

campos_wipo <- c(
	"WIPO_01" = "Electrical machinery, apparatus, energy",
	"WIPO_02" = "Audio-visual technology",
	"WIPO_03" = "Telecommunications",
	"WIPO_04" = "Digital communication",
	"WIPO_05" = "Basic communication processes",
	"WIPO_06" = "Computer technology",
	"WIPO_07" = "IT methods for management",
	"WIPO_08" = "Semiconductors",
	"WIPO_09" = "Optics",
	"WIPO_10" = "Measurement",
	"WIPO_11" = "Analysis of biological materials",
	"WIPO_12" = "Control",
	"WIPO_13" = "Medical technology",
	"WIPO_14" = "Organic fine chemistry",
	"WIPO_15" = "Biotechnology",
	"WIPO_16" = "Pharmaceuticals",
	"WIPO_17" = "Macromolecular chemistry, polymers",
	"WIPO_18" = "Food chemistry",
	"WIPO_19" = "Basic materials chemistry",
	"WIPO_20" = "Materials, metallurgy",
	"WIPO_21" = "Surface technology, coating",
	"WIPO_22" = "Micro-structural and nano-technology",
	"WIPO_23" = "Chemical engineering",
	"WIPO_24" = "Environmental technology",
	"WIPO_25" = "Handling",
	"WIPO_26" = "Machine tools",
	"WIPO_27" = "Engines, pumps, turbines",
	"WIPO_28" = "Textile and paper machines",
	"WIPO_29" = "Other special machines",
	"WIPO_30" = "Thermal processes and apparatus",
	"WIPO_31" = "Mechanical elements",
	"WIPO_32" = "Transport",
	"WIPO_33" = "Furniture, games",
	"WIPO_34" = "Other consumer goods",
	"WIPO_35" = "Civil engineering"
)

# -------------------------------------------
# LEITURA DOS DADOS

# 1. Web of Science - Citation Topics (macro)
arquivo_wos <- file.path(input_dir, "WoS_artigos", "consolidado.csv")

if (!file.exists(arquivo_wos)) {
	stop(
		"Arquivo 'WoS_artigos/consolidado.csv' não encontrado.",
		" Execute o script em 'gerar-fontes/arquivo_WoS.R'."
	)
}

colunas_wos <- c(
	"ano"             = "integer",
	"cod_pais"        = "character",
	"pais"            = "character",
	"id_macro_topico" = "integer",
	"macro_topico"    = "character",
	"artigos"         = "numeric"
)

dados_wos <- read.csv(arquivo_wos, colClasses = colunas_wos)
dados_wos <- dados_wos[, names(colunas_wos)]

# 2. OCDE - Patents by technology
arquivo_ocde <- file.path(input_dir, "OCDE_patentes_por_campo.csv")
dl_ocde <- file.path(dl_dir, "patentes_OCDE.R")

if (!file.exists(arquivo_ocde)) {
	resposta <- readline(paste0(
		"O arquivo 'OCDE_patentes_por_campo.csv' não foi encontrado.",
		" Deseja baixá-lo agora? (s/n): "
	))
	if (grepl(pattern = "^[SsYy]", resposta)) {
		source(dl_ocde, chdir = TRUE)
	} else {
		stop("Download cancelado")
	}
}

colunas_ocde <- c(
	"TIME_PERIOD"             = "integer",
	"REF_AREA"                = "character",
	"PATENT_AUTHORITIES"      = "character",
	"MEASURE"                 = "character",
	"UNIT_MEASURE"            = "character",
	"WIPO"                    = "character",
	"OECD_TECHNOLOGY_PATENT"  = "character",
	"OBS_VALUE"               = "numeric"
)

dados_ocde <- read.csv(arquivo_ocde, colClasses = colunas_ocde)
dados_ocde <- dados_ocde[, names(colunas_ocde)]

# -------------------------------------------
# INDICADORES

# 1. Artigos

ct_artigos <- list()
ct_artigos$area <- dados_wos
ct_artigos$area$macro_topico <- factor(
	ct_artigos$area$macro_topico,
	levels = macro_topicos_wos
)

ct_artigos$total <- aggregate(
	artigos ~ ano + cod_pais + pais,
	data = dados_wos,
	FUN = sum
)

# 2. Patentes

# 2.1 Patentes no USPTO
dados_uspto <- dados_ocde[
	dados_ocde$PATENT_AUTHORITIES == "US50" &
	dados_ocde$MEASURE == "AP" &
	dados_ocde$UNIT_MEASURE == "PATN" &
	dados_ocde$OECD_TECHNOLOGY_PATENT == "_Z",
]

ct_patuspto <- list()

ct_patuspto$total <- dados_uspto[
	dados_uspto$WIPO == "_T",
]

ct_patuspto$campo <- dados_uspto[
	dados_uspto$WIPO %in% names(campos_wipo),
]
ct_patuspto$campo$campo_nome <- factor(
	unname(campos_wipo[ct_patuspto$campo$WIPO]),
	levels = unname(campos_wipo)
)

# 2.2 Patentes via PCT / WIPO
dados_pct <- dados_ocde[
	dados_ocde$PATENT_AUTHORITIES == "9P50_1" &
	dados_ocde$MEASURE == "AP" &
	dados_ocde$UNIT_MEASURE == "PATN" &
	dados_ocde$OECD_TECHNOLOGY_PATENT == "_Z",
]

ct_patpct <- list()

ct_patpct$total <- dados_pct[
	dados_pct$WIPO == "_T",
]

ct_patpct$campo <- dados_pct[
	dados_pct$WIPO %in% names(campos_wipo),
]
ct_patpct$campo$campo_nome <- factor(
	unname(campos_wipo[ct_patpct$campo$WIPO]),
	levels = unname(campos_wipo)
)

# 2.3 Famílias Triádicas de Patentes
dados_fam <- dados_ocde[
	dados_ocde$PATENT_AUTHORITIES == "9P50_2" &
	dados_ocde$MEASURE == "PF" &
	dados_ocde$UNIT_MEASURE == "PATN_FM" &
	dados_ocde$OECD_TECHNOLOGY_PATENT == "_Z",
]

ct_patfam <- list()

ct_patfam$total <- dados_fam[
	dados_fam$WIPO == "_T",
]

ct_patfam$campo <- dados_fam[
	dados_fam$WIPO %in% names(campos_wipo),
]
ct_patfam$campo$campo_nome <- factor(
	unname(campos_wipo[ct_patfam$campo$WIPO]),
	levels = unname(campos_wipo)
)
