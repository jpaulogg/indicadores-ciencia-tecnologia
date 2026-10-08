# Script para automatizar o download de dados sobre CT&I
# Autor: João Paulo Garcia
# email: joao.garcia@fjp.mg.gov.br

# Preparar o ambiente

options(timeout = 1800)

data_dir <- "fontes"

if (!dir.exists(data_dir)) {
	dir.create(data_dir)
}

# 1. EDUCAÇÃO FORMAL DE NÍVEL SUPERIOR

# 1.1 OCDE - Number of enrolled students, graduates and new
# .......... entrants by field of education
#
# Campos de estudo:
# .... F05T07: Science, technology, engineering and mathematics (STEM)
# .... F01: Education
# .... F02: Arts and humanities
# .... F03: Social sciences, journalism and information
# .... F04: Business, administration and law
# .... F05: Natural sciences, mathematics and statistics
# .... F06: Information and Communication Technologies... (ICT ou TIC)
# .... F07: Engineering, manufacturing and construction
# .... F08: Agriculture, forestry, fisheries and veterinary
# .... F09: Health and welfare broad field level
# .... _T : Total

oecd_educ_api <- c(
	"https://sdmx.oecd.org",
	"public",
  	"rest",
  	"data",
  	"OECD.EDU.IMEP,DSD_EAG_UOE_NON_FIN_STUD@DF_UOE_NF_RAW_FIELD,1.1",
	paste0(
		# países (todos os 44)
		"AUS+AUT+BEL+CAN+CHL+COL+CRI+CZE+DNK+EST+FIN+FRA+DEU+GRC+HUN",
		"+ISL+IRL+ISR+ITA+JPN+KOR+LVA+LTU+LUX+MEX+NLD+NZL+NOR+POL+PRT",
		"+SVK+SVN+ESP+SWE+CHE+TUR+GBR+USA+BRA+BGR+HRV+PER+ROU.",
		# níveis educacionais (bacharelado, mestrado, doutorado)
		"ISCED11_6+ISCED11_7+ISCED11_8.",
		# categorias (matriculado, ingressante e concluinte)
		"ENRL+NENT+GRAD...",
		# campos de estudo
		"F05T07+F02+F03+F04+F05+F06+F07+F08+F09+F10+_T",
		# estudantes em mobilidade (incluindo nativos)
		"..A....MOB+_T..",
		# gênero
		"F+M+_T.?",
		# período (não disponibiliza dados para antes de 2013)
		"startPeriod=2013",
		"&endPeriod=2024",
		"&dimensionAtObservation=AllDimensions",
		"&format=csvfilewithlabels"
	)
)

oecd_educ_file <- file.path(data_dir, "OCDE_matriculados_por_campo.csv")
download.file(paste(collapse = '/', oecd_educ_api), oecd_educ_file)

# 1.2  UNESCO - Percentage of graduates from Science, Technology,
# ............. Engineering and Mathematics programmes in tertiary
# ............. education

unesco_educ_url <- "https://download.uis.unesco.org/bdds/202602/OPRI.zip"
unesco_educ_zip <- file.path(tempdir(), "OPRI.zip")
download.file(unesco_educ_url, destfile = unesco_educ_zip)

unzip(
	unesco_educ_zip,
	files = c("OPRI_DATA_NATIONAL.csv", "OPRI_LABEL.csv"),
	exdir = data_dir
)

# 2. PRODUÇÃO CIENTÍFICA E TECNOLÓGICA


