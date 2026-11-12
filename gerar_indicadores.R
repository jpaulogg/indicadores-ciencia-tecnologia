source("setup.R")
output_dir <- file.path(getwd(), "indicadores")
dir.create(output_dir, showWarnings = FALSE)

deletar_fontes <- FALSE # TRUE para deletar fontes após gerar indicadores
