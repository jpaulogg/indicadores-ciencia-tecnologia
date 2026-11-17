# Rotina para automatizar o download de dados utilizados na
# construção de indicadores de Ciência, Tecnologia e Inovação
#
# Autor: João Paulo Garcia
# email: joao.garcia@fjp.mg.gov.br
# -------------------------------------------

# preparar ambiente
if (!requireNamespace("jsonlite", quietly = TRUE)) {
    install.packages("jsonlite")
}

# 3. OCUPAÇÃO EM ATIVIDADES DE C&T E P&D

# 3.1 - UNESCO

id_unesco <- c(
	# ambos os sexos
    "21001",   # Researchers (HC) - Total
    "21205",   # Researchers (HC) - Business enterprise
    "21209",   # Researchers (HC) - Government
    "21213",   # Researchers (HC) - Higher education
    "21217",   # Researchers (HC) - Private non-profit
    "21000",   # Total R&D personnel (HC) - Total
    "21204",   # Total R&D personnel (HC) - Business enterprise
    "21208",   # Total R&D personnel (HC) - Government
    "21212",   # Total R&D personnel (HC) - Higher education
    "21216",   # Total R&D personnel (HC) - Private non-profit

    # sexo feminino
    "21105",   # Researchers (HC) - Female
    "21726",   # Researchers (HC) - Female - Business enterprise
    "21727",   # Researchers (HC) - Female - Government
    "21728",   # Researchers (HC) - Female - Higher education
    "21729",   # Researchers (HC) - Female - Private non-profit
	"21104",   # Total R&D personnel (HC) - Female
	"21706",   # Total R&D personnel (HC) - Female - Business enterprise
	"21707",   # Total R&D personnel (HC) - Female - Government
	"21708",   # Total R&D personnel (HC) - Female - Higher education
	"21709"    # Total R&D personnel (HC) - Female - Private non-profit
)

base_url <- "https://api.uis.unesco.org/api/public/data/indicators"

params <- c(
	paste0("indicator=", id_unesco),
	paste0("geoUnit=", mapa_paises$ISO3),
	paste0("start=", min(periodo)),
	paste0("end=", max(periodo)),
	"indicatorMetadata=false"
)

api_url <- paste0(base_url, "?", paste(params, collapse = "&"))

dados <- jsonlite::fromJSON(api_url, flatten = TRUE)
dados_unesco <- dados$records

# tornar nomes de colunas compatíveis com os downloads diretos do site
colnames(dados_unesco) <- c(
	"INDICATOR_ID",    # indicatorId
	"COUNTRY_ID",      # geoUnit
	"YEAR",            # year
	"VALUE",           # value
	"MAGNITUDE",       # magnitude
	"QUALIFIER"        # qualifier
)

if (!is.data.frame(dados_unesco) || nrow(dados_unesco) == 0) {
	stop("A consulta não retornou registros. Verifique dados$hints.")
}

write.csv(
	dados_unesco,
	file.path(input_dir, "UNESCO_SCN_OPRI_ocup.csv"),
	row.names = FALSE
)

rm(id_unesco, params, base_url, api_url, dados, dados_unesco)
