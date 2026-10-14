# Rotina para automatizar o download de dados utilizados na
# construção de indicadores de Ciência, Tecnologia e Inovação
#
# Autor: João Paulo Garcia
# email: joao.garcia@fjp.mg.gov.br
# -------------------------------------------
# 1. EDUCAÇÃO FORMAL DE NÍVEL SUPERIOR

# 1.1 OCDE - Number of enrolled students, graduates and new
# .......... entrants by field of education
#
# Campos de estudo:
# .... F00: Generic programmes and qualifications
# .... F01: Education
# .... F02: Arts and humanities
# .... F03: Social sciences, journalism and information
# .... F04: Business, administration and law
# .... F05: Natural sciences, mathematics and statistics
# .... F06: Information and Communication Technologies... (ICT ou TIC)
# .... F07: Engineering, manufacturing and construction
# .... F08: Agriculture, forestry, fisheries and veterinary
# .... F09: Health and welfare broad field level
# .... F10: Services
# .... F99: Field unspecified (broad field level)
# .... F05T07: Science, technology, engineering and mathematics (STEM)

campos_api <- c(
	"https://sdmx.oecd.org",
	"public",
  	"rest",
  	"data",
  	"OECD.EDU.IMEP,DSD_EAG_UOE_NON_FIN_STUD@DF_UOE_NF_RAW_FIELD,1.1",
	paste0(
		# países (todos os 43 disponíveis)
		"ISR+JPN+KOR+USA",
		"+AUS+AUT+BEL+CAN+CHE+DEU+DNK+FIN+GBR+IRL+ISL+LUX+NLD+NOR+NZL+SWE",
		"+BGR+CZE+ESP+EST+FRA+GRC+HRV+HUN+ITA+LTU+LVA+POL+PRT+SVK+SVN",
		"+BRA+CHL+COL+CRI+MEX+PER+ROU+TUR.",
		# níveis educacionais (bacharelado, mestrado, doutorado)
		"ISCED11_5+ISCED11_6+ISCED11_7+ISCED11_8.",
		# categorias (matriculado, ingressante e concluinte)
		"ENRL+NENT+GRAD...",
		# campos de estudo
		"F05T07+F00+F01+F02+F03+F04+F05+F06+F07+F08+F09+F10+F99..",
		# estudantes em mobilidade (incluindo nativos)
		"A....MOB+_T..",
		# gênero
		"F+M+_T.?",
		# período (não disponibiliza dados para antes de 2013)
		"startPeriod=2013",
		"&endPeriod=2024",
		"&dimensionAtObservation=AllDimensions",
		"&format=csvfilewithlabels"
	)
)

url_api <- paste(collapse = '/', campos_api)
output_file <- "../../fontes/OCDE_estudantes_por_campo.csv"

status_download <- tryCatch({
	download.file(
		url = url_api,
		destfile = output_file,
		mode     = "wb",
		quiet    = TRUE
	)
}, error = function(e) {
	stop("Falha no download: ", e$message)
})
