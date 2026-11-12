# Rotina para automatizar o download de dados utilizados na
# construção de indicadores de Ciência, Tecnologia e Inovação
#
# Autor: João Paulo Garcia
# email: joao.garcia@fjp.mg.gov.br
# -------------------------------------------
# 5. POPULAÇÃO

# 5.1 OCDE - Historical population data

url_api <- paste0(
	# host URL
	"https://sdmx.oecd.org/public/rest/data/",
	# identificador da agencia à qual pertence a base de dados
	"OECD.ELS.SAE,",
	# identificador da base de dados
	"DSD_POPULATION@DF_POP_HIST,",
	# versao da base de dados
	"1.0/",
	# paises (disponível: 38 da OCDE + 17)
	"ISR+JPN+KOR+USA",
	"+AUS+AUT+BEL+CAN+CHE+DEU+DNK+FIN+GBR+IRL+ISL+LUX+NLD+NOR+NZL+SGP+SWE",
	"+CHN",
	"+BGR+CZE+ESP+EST+FRA+GRC+HRV+HUN+ITA+LTU+LVA+POL+PRT+SVK+SVN",
	"+ARG+BRA+CHL+COL+CRI+IND+MEX+PER+ROU+RUS+TUR+ZAF.",
	# especificação de medida (matriculados + concluintes)
	"POP.",
	# unidade de medida (PS = contagem de pessoas)
	"PS.",
	# gênero (feminino, masculino e total) e faixa etária (total)
	"F+M+_T._T.?",
	# recorte temporal (anos disponíveis: 1950-2025)
	"startPeriod=2000",
	"&endPeriod=2025",
	# representação tabular direta em linhas e colunas
	"&dimensionAtObservation=AllDimensions",
	# formato csv (para adicionar rótulos, 'csvfilewithlabels')
	"&format=csvfile"
)

output_file <- file.path(input_dir, "OCDE_pop_mundial.csv")

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
