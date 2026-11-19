# Rotina para automatizar a construção de indicadores internacionais
# de artigos científicos, por total e área do conhecimento.
#
# autor: João Paulo Garcia
# email: joao.garcia@fjp.mg.gov.br
#
# O objeto `input_dir` está definido em "setup.R".
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

dados_wos <- read.csv(arquivo_wos)

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

dados_ocde <- read.csv(arquivo_ocde)

# Patentes depositadas (CT_PATOT)
# AP = pedidos de patente; PATN = contagem de patentes.
# Exclui as categorias tecnológicas específicas da OCDE (_Z).
# Mantém cada autoridade de patentes separada.
dados_pat <- dados_ocde[
	dados_ocde$MEASURE == "AP" &
	dados_ocde$UNIT_MEASURE == "PATN" &
	dados_ocde$OECD_TECHNOLOGY_PATENT == "_Z",
]

# vetor que será utilizado depois para traduzir os campos tecnológicos
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
# INDICADORES

# 1. Artigos

ct_artigos <- list()
ct_artigos$area <- dados_wos

ct_artigos$total <- aggregate(
	artigos ~ ano + iso_pais + pais_nome,
	data = dados_wos,
	FUN = sum
)

# 2. Patentes

ct_patot <- list()
ct_patot$total <- dados_pat[
	dados_pat$WIPO == "_T",
]
ct_patot$campo <- dados_pat[
	dados_pat$WIPO %in% names(campos_wipo),
]
ct_patot$campo$campo_wipo <- unname(
	campos_wipo[ct_patot$campo$WIPO]
)
