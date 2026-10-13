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
		# grupo Ib - países que lideram a fronteira
		'USA', 'ISR', 'JPN', 'KOR',
		# grupo I - países consolidados que acompanham a fronteira
		'AUS', 'AUT', 'BEL', 'CAN', 'CHE', 'DEU', 'DNK', 'FIN',
		'GBR', 'IRL', 'ISL', 'LUX', 'NLD', 'NOR', 'NZL', 'SGP', 'SWE',
		# Outliers II - em grande ascensão, mas não alcançaram o grupo I
		'CHN',
		# grupo IIb - países em transição descendente ou ascendente
		'BGR', 'CZE', 'ESP', 'EST', 'FRA', 'GRC', 'HRV', 'HUN',
		'ITA', 'LTU', 'LVA', 'POL', 'PRT', 'SVK', 'SVN',
		# grupo II - países intermediários com boa capacidade de absorção
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
