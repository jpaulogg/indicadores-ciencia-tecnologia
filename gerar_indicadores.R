# Gerar indicadores a partir das rotinas de preparação.
#
# Autor: João Paulo Garcia
# email: joao.garcia@fjp.mg.gov.br
# -------------------------------------------
# PREPARAR AMBIENTE

# carregar objetos de uso geral (output_dir, mapa_paises, etc)
source("../setup.R", chdir = TRUE)

colunas_padrao <- c(
	"ano",
	"pais",                 # nome completo
	"cod_pais",             # código ISO3 ou ISO2
	"cod_indicador",        # ex: CT_DISPPD
	"tipo_categoria",       # ex: "sexo",     "setor",      "total"
	"nome_especificacao",   # ex: "Feminino", "Government", "total"
	"valor"
)

deletar_fontes <- FALSE # TRUE para deletar fontes após gerar indicadores

# Função para padronizar o nome das colunas de "ano", "cod_pais" e "valor"
padronizar.nomes <- function(.col_names) {
	
	nomes_ano <- c("TIME_PERIOD", "year", "Year", "time")
	nomes_iso <- c("REF_AREA", "ref_area", "geoUnit", "ISO3", "ISO2")
	nomes_espec <- c(
		"campo_nome", "inst_nome", "SEX", "sex", "sexo_nome", "setor_nome"
	)
	nomes_valor <- c(
		"OBS_VALUE", "obs_value", "Value", "value", "percentual"
	)

	.col_names[.col_names %in% nomes_ano]   <- "ano"
	.col_names[.col_names %in% nomes_iso]   <- "cod_pais"
	.col_names[.col_names %in% nomes_espec] <- "nome_especificacao"
	.col_names[.col_names %in% nomes_valor] <- "valor"

	.col_names
}

# Função para traduzir código ISO para o nome completo dos países
traduzir.ISO3 <- function(.cod_paises, .padrao = "ISO3") {
	idx <- match(.cod_paises, mapa_paises[[.padrao]])
	mapa_paises[idx, "Nome_Completo"]
}

# Função formatar os indicadores.
fmt.indicador <- function(df, .cod_ind, .nome_df) {

	# renomear colunas
	colnames(df) <- padronizar.nomes(colnames(df))

	# adicionar nome completo dos países
	if (!"pais" %in% colnames(df)) {
		df$pais    <- traduzir.ISO3(df$cod_pais)
	}

	# adicionar código do indicador e tipo de categoria de desagregação
	df$cod_indicador  <- .cod_ind
	df$tipo_categoria <- .nome_df

	# adicionar especificação se ainda não existir
	if (!"nome_especificacao" %in% colnames(df)) {
		df$nome_especificacao <- df$tipo_categoria
	}

	return(df)
}

# Funções para salvar indicadores
salvar.csv <- function(df, .cod_ind, .nome_df) {
	df <- df[, colunas_padrao]
	pasta <- file.path(output_dir, .cod_ind)
	dir.create(pasta)
	arquivo <- file.path(pasta, paste0(.cod_ind, "_", .nome_df, ".csv"))
	write.csv(df, arquivo, row.names = FALSE, fileEncoding = "UTF-8")
}

# Função para processar listas de indicadores, formatando e salvando o CSV
processar.lista <- function(l) {
	nome_lista <- deparse(substitute(l))
	cod_ind <- toupper(nome_lista)
	lapply(names(l), function(nome_df) {
		df <- fmt.indicador(l[[nome_df]], cod_ind, nome_df)
		salvar(df, cod_ind, nome_df)
	})
}

# -------------------------------------------
# CARREGAR ROTINAS DE PREPARAÇÃO

# 1. Formação e Capacitação Profissional
source("educ_sup.R")

# liberar memória
rm(
	dados_ocde, dados_unesco, campos_educ_ocdem, sexo_unesco, inst_unesco,
	arq_ocde, arq_unesco, dl_ocde, dl_unesco, agregar, agregar.bloco
)

source("ocupacao_ct.R")

# -------------------------------------------
# 2. Produção Científica e Tecnológica

source("producao_ct.R")

# -------------------------------------------
# 3. Financiamento e Dispêndio Em C&t e P&d

source("dispendio_ct.R")

# -------------------------------------------
# 4. Infraestrutura Científica

# Ainda não temos uma rotina de download ou de preparação para dados
# de infraestrutura científica.

# -------------------------------------------
# 5. Transferência Tecnológica

source("comercio_tec.R")
