# Rotina para automatizar o download de dados utilizados na
# construção de indicadores de Ciência, Tecnologia e Inovação
#
# Autor: João Paulo Garcia
# email: joao.garcia@fjp.mg.gov.br
#
# Obs: o objeto `input_dir` está definido no script "setup.R".
# -------------------------------------------
# 3. PRODUÇÃO CIENTÍFICA E TECNOLÓGICA

# 3.1 OCDE - Patents by technology

url_api <- paste0(
	# host URL
	"https://sdmx.oecd.org/public/rest/data/",
	# identificador da agência à qual pertence a base de dados
	"OECD.STI.PIE,",
	# identificador da base de dados
	"DSD_PATENTS@DF_PATENTS,",
	# versão da base de dados
	"1.0/",
	# autoridade de patentes (WIPO/PCT + USPTO)
	"9P50_1+US50+9P50_2.",
	# frequência (anual)
	"A.",
	# medida (depósito) e unidade de medida (patentes e famílias)
	"AP+PF.PATN_FM+PATN.",
	# data de referência (prioridade)
	"PRIORITY.",
	# paises (disponível: 38 da OCDE + 17)
	paste(mapa_paises$ISO3, collapse = "+"), ".",
	# país do parceiro (_Z = não se aplica)
	"_Z.",
	# papel do agente residente no país (iventor ou depositante)
	"INVENTOR.",
	# tipo de cooperação
	"_Z.",
	# domínios/campos tecnológicos da WIPO (todos disponíveis)
	"_T+WIPO_01+WIPO_02+WIPO_03+WIPO_04+WIPO_05+WIPO_06+WIPO_07+WIPO_08",
	"+WIPO_09+WIPO_10+WIPO_11+WIPO_12+WIPO_13+WIPO_14+WIPO_15+WIPO_16",
	"+WIPO_17+WIPO_18+WIPO_19+WIPO_20+WIPO_21+WIPO_22+WIPO_23+WIPO_24",
	"+WIPO_25+WIPO_26+WIPO_27+WIPO_28+WIPO_29+WIPO_30+WIPO_31+WIPO_32",
	"+WIPO_33+WIPO_34+WIPO_35+_Z.",
	# campo tecnológico OCDE (não incluir)
	"?",
	# período (2000 ao mais recente)
	"startPeriod=2000",
	# representação tabular direta em linhas e colunas
	"&dimensionAtObservation=AllDimensions",
	# formato CSV (para adicionar rótulos, 'csvfilewithlabels')
	"&format=csvfile"
)

status_download <- tryCatch({
	download.file(
		url = url_api,
		destfile = file.path(input_dir, "OCDE_patentes_por_campo.csv"),
		mode     = "wb",
		quiet    = TRUE
	)
}, error = function(e) {
	stop("Falha no download: ", e$message)
})

rm(url_api, status_download)
