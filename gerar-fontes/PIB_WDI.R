# Rotina para automatizar o download de dados utilizados na
# construção de indicadores de Ciência, Tecnologia e Inovação
#
# Autor: João Paulo Garcia
# email: joao.garcia@fjp.mg.gov.br
#
# Obs: os objetos `input_dir`, `mapa_paises` e `periodo`
# estão definidos no script "setup.R".
# -------------------------------------------
# 6. INDICADORES SOCIOECONÔMICOS
# .. 6.1 PIB
#
# Base de dados: Banco Mundial (WDI)

id_bm <- c(
    "NY.GDP.MKTP.PP.CD", # GDP, PPP (current international $)
    "NY.GDP.MKTP.PP.KD"  # GDP, PPP (constant 2021 international $)
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
    exdir = file.path(input_dir, "WDI_PIB_mundial"),
    junkpaths = TRUE
)

unlink(arquivo_zip)
rm(id_bm, api_url, arquivo_zip)
