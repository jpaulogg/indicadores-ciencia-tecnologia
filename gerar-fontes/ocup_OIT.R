# Rotina para automatizar o download de dados utilizados na
# construção de indicadores de Ciência, Tecnologia e Inovação
#
# Autor: João Paulo Garcia
# email: joao.garcia@fjp.mg.gov.br
#
# Obs: os objetos `mapa_paises`, `input_dir` e `periodo são
# definido em # "../setup.R".
# ------------------------------------------------------------
# 1.. FORMAÇÃO E CAPACITAÇÃO PROFISSIONAL
# 1.3 EMPREGOS EM ÁREAS STEM
#
# Base de dados: ILOSTAT

id_ilostat <- c(
	"EMP_STEM_SEX_STE_NB_A", # empregos STEM
	"EMP_TEMP_AGE_STE_NB_A"  # empregos total
)

for (id in id_ilostat) {

	url_api <- paste0(
		"https://rplumber.ilo.org/data/indicator/?",
		"id=", id,
		"&ref_area=",
		paste(mapa_paises$ISO3, collapse = "+"),
		"&timefrom=", min(periodo),
		"&timeto=", max(periodo),
		"&type=code",
		"&format=.csv"
	)

	download.file(
		url_api,
		file.path(input_dir, paste0("OIT_", id, ".csv")),
		mode = "wb",
		quiet = TRUE
	)
}
