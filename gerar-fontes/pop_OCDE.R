# Rotina para automatizar o download de dados utilizados na
# construção de indicadores de Ciência, Tecnologia e Inovação
#
# Autor: João Paulo Garcia
# email: joao.garcia@fjp.mg.gov.br
#
# Obs: o objeto `input_dir` está definido no script "setup.R".
# -------------------------------------------
# 6. INDICADORES SOCIOECONÔMICOS
# .. 6.1 POPULAÇÃO
#
# Base de dados: OCDE - Historical population data

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
	paste(mapa_paises$ISO3, collapse = "+"), ".",
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

status_download <- tryCatch({
	download.file(
		url = url_api,
		destfile = file.path(input_dir, "OCDE_pop_mundial.csv"),
		mode     = "wb",
		quiet    = TRUE
	)
}, error = function(e) {
	stop("Falha no download: ", e$message)
})

rm(url_api, status_download)
