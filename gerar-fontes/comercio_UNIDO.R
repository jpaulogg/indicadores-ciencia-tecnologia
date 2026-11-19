# Rotina para automatizar o download de dados utilizados na
# construção de indicadores de Ciência, Tecnologia e Inovação

# Autor: João Paulo Garcia
# email: joao.garcia@fjp.mg.gov.br
#
# Obs.: `input_dir` e `periodo` são definidos em "../setup.R".
# -----------------------------------------------------------------
# 5.. TRANSFERÊNCIA DE TECNOLOGIA
# 5.1 COMÉRCIO INTERNACIONAL DE PRODUTOS DE MÉDIA-ALTA TECNOLOGIA
#
# Base de dados: UNIDO (Manufacturing Trade Database)

# Preparar ambiente
if (!requireNamespace("jsonlite", quietly = TRUE)) {
	stop("Instale o pacote jsonlite: install.packages('jsonlite')")
}
if (!requireNamespace("curl", quietly = TRUE)) {
	stop("Instale o pacote curl: install.packages('curl')")
}

# 1. Metadados: identificador da base, países e anos disponíveis.
url_meta <- "https://stat.unido.org/portal/dataset/getDataset/MTD"
res_meta <- curl::curl_fetch_memory(url_meta)
if (res_meta$status_code != 200L) {
	stop("Erro HTTP ",res_meta$status_code," ao consultar os metadados")
}
meta <- jsonlite::fromJSON(
	rawToChar(res_meta$content),
	simplifyVector = FALSE
)

# 2. Solicitar um ZIP com os quatro indicadores, para todos os países.
requisicao <- list(
	datasetId = jsonlite::unbox(meta$id),
	countryCodes = character(0),
	countryGroupsCodes = character(0),
	variableCodes = c("X_MHT", "M_MHT", "X_T", "M_T"),
	activityCodes = character(0),
	periods = periodo,
	valueCurrency = jsonlite::unbox("NA"),
	includeMetadata = jsonlite::unbox(TRUE),
	selectedImportFiles = c("R")
)
corpo <- as.character(jsonlite::toJSON(requisicao, auto_unbox = FALSE))

url_prepare <- "https://stat.unido.org/portal/dataset/download/csv/prepare"
handle <- curl::new_handle()
curl::handle_setopt(
	handle,
	post = TRUE,
	postfields = corpo,
	timeout = 120L
)
curl::handle_setheaders(
	handle,
	"Content-Type" = "application/json",
	"Accept" = "application/json",
	"Origin" = "https://stat.unido.org",
	"Referer" = "https://stat.unido.org/data/download?dataset=mtd"
)
res <- curl::curl_fetch_memory(url_prepare, handle = handle)
resposta <- rawToChar(res$content)
if (res$status_code < 200L || res$status_code >= 300L) {
	stop("Erro HTTP ao preparar o ZIP: ", substr(resposta, 1L, 400L))
}

# 3. Identificar o arquivo preparado pela UNIDO.
nome_zip <- regmatches(
	resposta,
	regexpr("[A-Za-z0-9_-]{16,}\\.zip", resposta, perl = TRUE)
)
id_zip <- character(0)
if (!length(nome_zip)) {
	id_zip <- regmatches(
		resposta,
		regexpr("[A-Fa-f0-9]{32,}", resposta, perl = TRUE)
	)
	if (length(id_zip)) nome_zip <- paste0(id_zip, ".zip")
}
if (!length(nome_zip)) {
	stop("ZIP não identificado: ", substr(resposta, 1L, 600L))
}

# 4. Verificar a disponibilidade e baixar o ZIP.
url_check <- paste0(
	"https://stat.unido.org/portal/dataset/download/check/",
	nome_zip
)
url_zip <- paste0(
	"https://stat.unido.org/portal/dataset/download/",
	nome_zip
)
arquivo_zip <- tempfile(fileext = ".zip")
concluido <- FALSE

for (tentativa in seq_len(40L)) {
	try(curl::curl_fetch_memory(url_check), silent = TRUE)
	res_zip <- tryCatch(
		curl::curl_fetch_disk(url_zip, arquivo_zip),
		error = function(e) NULL
	)

	if (!is.null(res_zip) && res_zip$status_code == 200L &&
		file.exists(arquivo_zip) && file.info(arquivo_zip)$size > 4L) {
		con <- file(arquivo_zip, "rb")
		assinatura <- readBin(con, "raw", n = 2L)
		close(con)
		if (identical(assinatura, as.raw(c(0x50, 0x4b)))) {
			concluido <- TRUE
			break
		}
	}
	if (tentativa < 40L) Sys.sleep(3)
}

if (!concluido) {
	unlink(arquivo_zip)
	stop("Não foi possível baixar um ZIP válido da UNIDO.")
}

# 5. Extrair os arquivos originais, sem manipular os dados.
unzip(
	arquivo_zip,
	exdir = file.path(input_dir, "UNIDO_comercio"),
	junkpaths = TRUE
)
unlink(arquivo_zip)
message("Download concluído: ", pasta)
