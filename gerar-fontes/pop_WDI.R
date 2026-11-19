# Rotina para automatizar o download de dados utilizados na
# construção de indicadores de Ciência, Tecnologia e Inovação
#
# Autor: João Paulo Garcia
# email: joao.garcia@fjp.mg.gov.br
#
# Obs: os objetos `mapa_paises`, `input_dir` e `periodo são
# definido em # "../setup.R".
# -------------------------------------------
# 6.. INDICADORES SOCIOECONÔMICOS
# 6.2 POPULAÇÃO
#
# Base de dados: Banco Mundial (WDI)

id_bm <- c(
    "SP.POP.TOTL",       # Population, total
    "SP.POP.TOTL.FE.IN", # Population, female
    "SP.POP.TOTL.MA.IN"  # Population, male
)

api_url <- paste0(
    "https://api.worldbank.org/v2/country/",
    paste(mapa_paises$ISO3, collapse = ";"),
    "/indicator/",
    paste(id_bm, collapse = ";"),
    "?source=2",
    "&date=", min(periodo), ":", max(periodo),
    "&downloadformat=csv",
    "&dataformat=list"
)

arquivo_zip <- tempfile(fileext = ".zip")

download.file(
    url = api_url,
    destfile = arquivo_zip,
    mode = "wb"
)

unzip(
    arquivo_zip,
    exdir = file.path(input_dir, "WDI_pop_mundial"),
    junkpaths = TRUE
)

unlink(arquivo_zip)
