# Gerar fontes de dados a partir das rotinas de download.
#
# Autor: João Paulo Garcia
# email: joao.garcia@fjp.mg.gov.br
# -------------------------------------------
# Preparar ambiente

setwd("rotinas/downloads")
source("../setup.R", chdir = TRUE)

# evitar problemas com downloads demorados
options(timeout = 180)

# -------------------------------------------
# 1.. FORMAÇÃO E CAPACITAÇÃO PROFISSIONAL
# 1.1 ENSINO SUPERIOR
source("educ_OCDE.R", local = new.env())
source("educ_UNESCO.R", local = new.env())

# 1.2 NÚMERO DE PESQUISADORES
source("ocup_UNESCO.R", local = new.env())

# 1.3 EMPREGOS EM ÁREAS STEM
source("ocup_OIT.R", local = new.env())

# 2.. PRODUÇÃO CIENTÍFICA E TECNOLÓGICA
# 2.1 PATENTES
source("patentes_OCDE.R", local = new.env())

# 2.2 ARTIGOS
# A base de dados de artigos é construída a partir do script de Python
# "artigos_WoS.py", que é uma rotina demorada e que exige interação com
# o navegador. Sugiro rodá-la separadamente.

# 3.. FINANCIAMENTO E DISPÊNDIO EM C&T E P&D
source("disp_UNESCO.R", local = new.env())

# 4.. INFRAESTRUTURA CIENTÍFICA
# A base com o número de instituições de ensino superior será construída
# a partir de um script de Python que automatiza downloads no site da
# WHED.

# 5.. TRANSFERÊNCIA TECNOLÓGICA
source("comercio_UNIDO.R", local = new.env())
