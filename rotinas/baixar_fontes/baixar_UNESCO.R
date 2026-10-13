# Rotina para automatizar o download de dados utilizados na
# construção de indicadores de Ciência, Tecnologia e Inovação
#
# Autor: João Paulo Garcia
# email: joao.garcia@fjp.mg.gov.br
# -------------------------------------------

# Preparar o ambiente
source("../utilitarios.R")

# -------------------------------------------
# 1. EDUCAÇÃO FORMAL DE NÍVEL SUPERIOR

# 1.2  UNESCO - Percentage of graduates from Science, Technology,
# ............. Engineering and Mathematics programmes in tertiary
# ............. education

unesco_educ_url <- "https://download.uis.unesco.org/bdds/202602/OPRI.zip"
unesco_educ_zip <- file.path(tempdir(), "OPRI.zip")

status_download <- tryCatch({
	download.file(unesco_educ_url, destfile = unesco_educ_zip)
	cat("Extraindo arquivos")
	unzip(
		unesco_educ_zip,
		files = c("OPRI_DATA_NATIONAL.csv", "OPRI_LABEL.csv"),
		exdir = data_dir
	)
}, error = function(e) {
	stop("Algo deu errado", e$message)
})

cat("Arquivos extraídos com sucesso")