# Objetos de uso geral das rotinas de download e preparação dos dados.
#
# Autor: João Paulo Garcia
# email: joao.garcia@fjp.mg.gov.br
# -------------------------------------------

# diretórios de uso geral
dl_dir    <- file.path(getwd() , "downloads")
input_dir <- file.path(dirname(getwd()) , "fontes")
output_dir <- file.path(dirname(getwd()) , "indicadores")

for (d in c(dl_dir, input_dir, output_dir)) {
	if (!dir.exists(d)) dir.create(d, recursive = TRUE)
}

# algumas bases começam em 2013, muitas vão apenas até 2024.
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
		# outliers II - em grande ascensão, mas ainda fora do grupo I [22]
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
		'GB', 'IE', 'IS', 'LU', 'NL', 'NO', 'NZ', 'SG', 'SE',
		'CN',
		'BG', 'CZ', 'ES', 'EE', 'FR', 'GR', 'HR', 'HU',
		'IT', 'LT', 'LV', 'PL', 'PT', 'SK', 'SI',
		'AR', 'BR', 'CL', 'CO', 'CR', 'IN', 'MX', 'PE', 'RO',
		'RU', 'TR', 'ZA'
	),
	ISO_NUM = c(
		'840', '376', '392', '410',
		'036', '040', '056', '124', '756', '276', '208', '246',
		'826', '372', '352', '442', '528', '578', '554', '702', '752',
		'156',
		'100', '203', '724', '233', '250', '300', '191', '348',
		'380', '440', '428', '616', '620', '703', '705',
		'032', '076', '152', '170', '188', '356', '484', '604', '642',
		'643', '792', '710'
	),
	Nome_Completo = c(
		'Estados Unidos', 'Israel', 'Japão', 'Coreia do Sul', 'Austrália',
		'Áustria', 'Bélgica', 'Canadá', 'Suíça', 'Alemanha', 'Dinamarca',
		'Finlândia', 'Reino Unido', 'Irlanda', 'Islândia', 'Luxemburgo',
		'Países Baixos', 'Noruega', 'Nova Zelândia', 'Cingapura', 'Suécia',
		'China', 'Bulgária', 'Tchéquia', 'Espanha', 'Estônia', 'França',
		'Grécia', 'Croácia', 'Hungria', 'Itália', 'Lituânia', 'Letônia',
		'Polônia', 'Portugal', 'Eslováquia', 'Eslovênia', 'Argentina',
		'Brasil', 'Chile', 'Colômbia', 'Costa Rica', 'Índia', 'México',
		'Peru', 'Romênia', 'Rússia', 'Turquia', 'África do Sul'
	),
	Grupo = factor(
		c(
			rep('Ib', 4),
			rep('I', 17),
			'O',
			rep('IIb', 15),
			rep('II', 12)
		),
		levels = c("Ib", "I", "O", "IIb", "II")
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
