# Rotina para automatizar o download de dados utilizados na
# construção de indicadores de Ciência, Tecnologia e Inovação
#
# Autor: João Paulo Garcia
# email: joao.garcia@fjp.mg.gov.br
# -------------------------------------------
# 2. PRODUÇÃO CIENTÍFICA E TECNOLÓGICA

# 2.1 WIPO - IP Statiscs Data Center
# Indicador: Total patent applications (direct and PCT)

# carregar objetos e opções padrão
source("../setup.R", chdir = TRUE)

wipo_url <- paste0(
	"https://api.ipstatsdc.deda.prd.web1.wipo.int/api/v1/public/ips-search/downloadCsv?",
	"selectedTab=patent&indicator=10&reportType=15&",
	# periodo (o primeiro ano disponível é 1980)
	"fromYear=2000&toYear=2024",
	"&ipsOffSelValues=US&ipsOriSelValues=",
	# paises
	"IL,JP,KR,US,",
	"AU,AT,BE,CA,CH,CN,DE,DK,FI,GB,IE,IS,LU,NL,NO,NZ,SG,SE,",
	"BG,CZ,ES,EE,FR,GR,HR,HU,IT,LT,LV,PL,PT,SK,SI,",
	"AR,BR,CL,CO,CR,IN,MX,PE,RO,RU,TR,ZA"
)

cabecalhos <- c(
	"Accept"          = "application/json, text/plain, */*",
	"Accept-Language" = "en",
	"Origin"          = "https://www3.wipo.int",
	"Referer"         = "https://www3.wipo.int/",
	"Sec-Fetch-Dest"  = "empty",
	"Sec-Fetch-Mode"  = "cors",
	"Sec-Fetch-Site"  = "same-site"
)

output_file <- file.path(dirs$input, "WIPO_patentes_USPTO_2000_2008.csv")

status_download <- tryCatch({
	download.file(
		url      = wipo_url,
		destfile = output_file,
		method   = "libcurl",
		headers  = cabecalhos,
		mode     = "wb",
		quiet    = TRUE
  	)
}, error = function(e) {
	stop("Falha na conexão HTTP com o servidor da WIPO: ", e$message)
})
