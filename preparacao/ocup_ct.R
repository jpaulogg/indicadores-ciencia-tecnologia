# Rotina para automatizar a construção de indicadores internacionais
# de pesquisadores e pessoal ocupado em atividades de P&D.
#
# autor: João Paulo Garcia
# email: joao.garcia@fjp.gov.br
#
# Os seguintes objetos estão definidos em "setup.R":
# ... dl_dir (diretório de rotinas para baixar fontes)
# ... input_dir (diretório de fonte de dados)
# ... periodo (por padrão, 2000:2025)
# ... mapa_paises (siglas ISO3 e ISO2 de grupos de países selecionados)
# -------------------------------------------

# LEITURA DOS DADOS

# 1. UNESCO - Science, Technology and Innovation (R&D personnel)

arquivo_unesco <- file.path(input_dir, "UNESCO_SCN_OPRI_ocup.csv")
dl_script <- file.path(dl_dir, "ocup_UNESCO.R")

if (!file.exists(arquivo_unesco)) {
	resposta <- readline(paste0(
		"O arquivo 'UNESCO_SCN_OPRI_ocup.csv' não foi encontrado.",
		" Deseja baixá-lo agora? (s/n): "
	))
	if (grepl(pattern = "^[SsYy]", resposta)) {
		source(dl_script, chdir = TRUE)
	} else {
		stop("Download cancelado")
	}
}

colunas_unesco <- c(
	"INDICATOR_ID" = "factor",
	"COUNTRY_ID"   = "character",
	"YEAR"         = "integer",
	"VALUE"        = "numeric",
	"QUALIFIER"    = "factor"
)

dados_unesco <- read.csv(arquivo_unesco, colClasses = colunas_unesco)
dados_unesco <- dados_unesco[, names(colunas_unesco)]

# -------------------------------------------
# FUNÇÕES

# 1. Função para organizar os dados em três blocos: total, sexo e setor
# .. de execução (sem cruzar sexo e setor).

organizar.bloco <- function(dados, .id_total, .id_fem, .id_setor) {

	# selecionar séries e identificar as desagregações
	total <- dados[dados$INDICATOR_ID == .id_total, ]
	fem   <- dados[dados$INDICATOR_ID == .id_fem, ]
	setor <- dados[dados$INDICATOR_ID %in% .id_setor, ]

	setores <- c("EMPRESAS", "GOVERNO", "ENSINO_SUPERIOR", "PRIVADO_SFL")

	total$SETOR <- rep("TOTAL", nrow(total))
	total$SEXO <- rep("T", nrow(total))
	total$ORIGEM <- rep("UNESCO", nrow(total))

	fem$SETOR <- rep("TOTAL", nrow(fem))
	fem$SEXO <- rep("F", nrow(fem))
	fem$ORIGEM <- rep("UNESCO", nrow(fem))

	setor$SETOR <- setores[match(setor$INDICATOR_ID, .id_setor)]
	setor$SEXO <- rep("T", nrow(setor))
	setor$ORIGEM <- rep("UNESCO", nrow(setor))

	# impedir que registros duplicados multipliquem as linhas do merge
	chaves <- c("COUNTRY_ID", "YEAR")
	if (anyDuplicated(total[, chaves]) || anyDuplicated(fem[, chaves])) {
		stop("Há observações duplicadas por país e ano")
	}

	# número de homens: total - mulheres
	homens <- merge(
		total[, c(chaves, "VALUE")],
		fem[, c(chaves, "VALUE")],
		by = chaves,
		suffixes = c("_T", "_F")
	)

	inconsistentes <- !is.na(homens$VALUE_T) & !is.na(homens$VALUE_F) &
		homens$VALUE_F > homens$VALUE_T
	if (any(inconsistentes)) {
		warning(
			sum(inconsistentes),
			" observações com mulheres > total; homens não calculados"
		)
	}

	homens$VALUE <- homens$VALUE_T - homens$VALUE_F
	homens$VALUE[inconsistentes] <- NA_real_
	homens <- homens[!is.na(homens$VALUE), ]
	homens$INDICATOR_ID <- rep(NA_character_, nrow(homens))
	homens$QUALIFIER <- rep(NA_character_, nrow(homens))
	homens$SETOR <- rep("TOTAL", nrow(homens))
	homens$SEXO <- rep("M", nrow(homens))
	homens$ORIGEM <- rep("calculado", nrow(homens))
	homens <- homens[, names(total)]

	sexo <- rbind(fem, homens)

	total <- total[order(total$COUNTRY_ID, total$YEAR), ]
	sexo <- sexo[order(sexo$COUNTRY_ID, sexo$YEAR, sexo$SEXO), ]
	setor <- setor[order(setor$COUNTRY_ID, setor$YEAR, setor$SETOR), ]
	row.names(total) <- NULL
	row.names(sexo) <- NULL
	row.names(setor) <- NULL

	list(
		total = total,
		sexo  = sexo,
		setor = setor
	)
}

# -------------------------------------------
# INDICADORES

# 1. Pesquisadores em atividades de P&D (HC)
# 1.1 Total, por sexo e por setor de execução
ct_pesq <- organizar.bloco(
	dados_unesco,
	.id_total = "21001",
	.id_fem   = "21105",
	.id_setor = c("21205", "21209", "21213", "21217")
)

# 2. Pessoal ocupado em atividades de P&D (HC)
# 2.1 Total, por sexo e por setor de execução
ct_pessoal <- organizar.bloco(
	dados_unesco,
	.id_total = "21000",
	.id_fem   = "21104",
	.id_setor = c("21204", "21208", "21212", "21216")
)
