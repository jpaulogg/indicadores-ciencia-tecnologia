# Rotina para automatizar o download de dados utilizados na
# construção de indicadores de Ciência, Tecnologia e Inovação
#
# Autor: João Paulo Garcia
# email: joao.garcia@fjp.mg.gov.br
# -------------------------------------------
# 1. EDUCAÇÃO FORMAL DE NÍVEL SUPERIOR

# 1.2  UNESCO - Percentage of graduates from Science, Technology,
# ............. Engineering and Mathematics programmes in tertiary
# ............. education

zip_url <- "https://download.uis.unesco.org/bdds/202602/OPRI.zip"
zip_file <- file.path(tempdir(), "OPRI.zip")

status_download <- tryCatch({
	download.file(zip_url, destfile = zip_file, mode = 'wb')
	unzip(
		zip_file,
		files = c("OPRI_DATA_NATIONAL.csv", "OPRI_LABEL.csv"),
		exdir = input_dir)
}, error = function(e) {
	stop("Algo deu errado", e$message)
})
