# Rotina para automatizar o download de dados utilizados na
# construção de indicadores de Ciência, Tecnologia e Inovação
#
# Autor: João Paulo Garcia
# email: joao.garcia@fjp.mg.gov.br
#
# Obs: o objeto `input_dir` está definido em "gerar_fontes.R"
# ------------------------------------------------------------
# 3. OCUPAÇÃO EM ATIVIDADES DE C&T E P&D

# 3.2 - Organização Internacional do Trabalho (ILOSTAT)

id_ilostat <- c(
	"EMP_STEM_SEX_STE_NB_A", # ocupação STEM
	"EMP_TEMP_AGE_STE_NB_A"  # ocupação total
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
