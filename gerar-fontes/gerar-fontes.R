# Configurações e objetos de uso geral das rotinas
#
# Autor: João Paulo Garcia
# email: joao.garcia@fjp.mg.gov.br
# -------------------------------------------
# Preparar ambiente

# evitar problemas com downloads demorados
options(timeout = 180)

# -------------------------------------------
# Objetos de uso geral

# diretório com as bases de dados
input_dir  <- file.path(dirname(getwd()), "fontes")
dir.create(input_dir, showWarnings = FALSE)

periodo <- 2000:2025
