# Gerar indicadores a partir das rotinas de preparação.
#
# Autor: João Paulo Garcia
# email: joao.garcia@fjp.mg.gov.br
# -------------------------------------------
# PREPARAR AMBIENTE

# carregar objetos de uso geral (output_dir, mapa_paises, etc)
source("rotinas/setup.R", chdir = TRUE)

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
		"campo_nome", "inst_nome", "SEX", "sex", "sexo_nome",
		"setor_nome", "macro_topico"
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
		df$pais <- traduzir.ISO3(df$cod_pais)
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
	if (!dir.exists(pasta)) dir.create(pasta)
	arquivo <- file.path(pasta, paste0(.cod_ind, "_", .nome_df, ".csv"))
	write.csv(df, arquivo, row.names = FALSE, fileEncoding = "UTF-8")
}

# Função para processar listas de indicadores, formatando e salvando o CSV
processar.lista <- function(l, .nome_lista) {
	cod_ind <- toupper(.nome_lista)
	lapply(names(l), function(nome_df) {
		df <- fmt.indicador(l[[nome_df]], cod_ind, nome_df)
		salvar.csv(df, cod_ind, nome_df)
	})
}

# -------------------------------------------
# CARREGAR ROTINAS DE PREPARAÇÃO

# 1. Formação e Capacitação Profissional
source("rotinas/preparacao/educ_sup.R")

# liberar memória e limpar lista de objetos da sessão
rm(
	dados_ocde, dados_unesco, campos_educ_ocde, sexo_unesco, inst_unesco,
	arq_ocde, arq_unesco, dl_ocde, dl_unesco, agregar, agregar.bloco
)

source("rotinas/preparacao/ocupacao_ct.R")
rm(
	arq_oit, arq_unesco, colunas_unesco, dados_oit_stem, dados_oit_t,
	dados_unesco, dl_oit, dl_unesco, emprego_total, pesq_masc,
	rotulos_sexo, setores_pesq
)

# 2. Produção Científica e Tecnológica
source("rotinas/preparacao/producao_ct.R")
rm(
	arquivo_ocde, arquivo_wos, colunas_ocde, dados_fam,
	dados_ocde, dados_pct, dados_uspto, dados_wos, dl_ocde,
	macro_topicos_wos
)

# 3. Financiamento e Dispêndio Em C&t e P&d
source("rotinas/preparacao/dispendio_ct.R")
rm(
	arq_disp, colunas_unesco, dados_disp, dl_disp,
	setores_exec, setores_exec_pib, setores_financ
)

# 4. Infraestrutura Científica

# Ainda não temos uma rotina de download ou de preparação para dados
# de infraestrutura científica.

# 5. Transferência Tecnológica

source("rotinas/preparacao/comercio_tec.R")
rm(
	arq_comercio, colunas_unido, dados_comercio, dl_comercio,
	exp_mht, exp_tot, imp_mht, imp_tot
)

# -------------------------------------------
# PROCESSAR LISTAS

for (cod in ls(pattern="^ct_[a-z]*$")) {
	processar.lista(get(cod), cod)
}

teste_output <- length(list.files(output_dir)) >= 20

if (!teste_output) stop("Menos de 20 indicadores foram gerados")

if (deletar_fontes) {
	unlink(input_dir, recursive = TRUE)
} else {
	resposta <- readline(paste(
		"Indicadores salvos sucesso.",
		"Deseja deletar as bases de dados?"
	))
	if (grepl(pattern = "^[SsYy]", resposta)) {
		unlink(input_dir, recursive = TRUE)
	}
}
