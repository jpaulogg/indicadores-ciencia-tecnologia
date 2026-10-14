# Opções e objetos de uso geral das rotinas
#
# Autor: João Paulo Garcia
# email: joao.garcia@fjp.mg.gov.br
# -------------------------------------------
# Preparar ambiente

# evitar que "utilitarios.R" seja carregado mais de uma vez
if (exists(".UTILITARIOS", envir = .GlobalEnv)) {
	return(invisible())
}
assign(".UTILITARIOS", TRUE, envir = .GlobalEnv)

# evitar problemas com downloads demorados
options(timeout = 180)

if (!dir.exists("../fontes")) {
	dir.create("../fontes")
}
if (!dir.exists("../indicadores")) {
	dir.create("../indicadores")
}

# -------------------------------------------
# Objetos de uso geral

periodo <- 2000:2025

# Agrupamento de países segundo a classificação proposta pelo trabalho
# "National innovation systems represented as a moving and expanding
# universe" (Ribeiro et al., 2026). O período mais recente analisado pelo
# trabalho é o ano de 2022.

mapa_paises <- data.frame(
	ISO3 = c(
		# grupo Ib - países que lideram a fronteira [1-4]
		'USA', 'ISR', 'JPN', 'KOR',
		# grupo I - países consolidados que acompanham a fronteira [5-21]
		'AUS', 'AUT', 'BEL', 'CAN', 'CHE', 'DEU', 'DNK', 'FIN',
		'GBR', 'IRL', 'ISL', 'LUX', 'NLD', 'NOR', 'NZL', 'SGP', 'SWE',
		# Outliers II - em grande ascensão, mas ainda fora do grupo I [22]
		'CHN',
		# grupo IIb - em transição descendente ou ascendente [23-37]
		'BGR', 'CZE', 'ESP', 'EST', 'FRA', 'GRC', 'HRV', 'HUN',
		'ITA', 'LTU', 'LVA', 'POL', 'PRT', 'SVK', 'SVN',
		# grupo II - intermediários com boa capacidade de absorção [37-48]
		'ARG', 'BRA', 'CHL', 'COL', 'CRI', 'IND', 'MEX', 'PER', 'ROU',
		'RUS', 'TUR', 'ZAF'
	),
	ISO2 = c(
		'US', 'IL', 'JP', 'KR',
		'AU', 'AT', 'BE', 'CA', 'CH', 'DE', 'DK', 'FI',
		'GB', 'IE', 'IS', 'LU', 'NL', 'NO', 'NZ', 'SE', 'SG',
		'CN',
		'BG', 'CZ', 'ES', 'EE', 'FR', 'GR', 'HR', 'HU',
		'IT', 'LT', 'LV', 'PL', 'PT', 'SK', 'SI',
		'AR', 'BR', 'CL', 'CO', 'CR', 'IN', 'MX', 'PE', 'RO', 'RU', 'TR',
		'ZA'
	),
	Grupo = c(
		rep('Ib', 4),
		rep('I', 17),
		'Outlier_II',
		rep('IIb', 15),
		rep('II', 12)
	)
)

paises_ib <- mapa_paises[mapa_paises$Grupo == "Ib", ]
paises_ib$Grupo <- NULL
paises_i <- mapa_paises[mapa_paises$Grupo == "I", ]
paises_i$Grupo <- NULL

paises_iib <- mapa_paises[mapa_paises$Grupo == "IIb", ]
paises_iib$Grupo <- NULL
paises_ii <- mapa_paises[mapa_paises$Grupo == "II", ]
paises_ii$Grupo <- NULL
