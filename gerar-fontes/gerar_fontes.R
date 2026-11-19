# Configurações e objetos de uso geral das rotinas
#
# Autor: João Paulo Garcia
# email: joao.garcia@fjp.mg.gov.br
# -------------------------------------------
# Preparar ambiente

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
# o navegador.

# 3.. FINANCIAMENTO E DISPÊNDIO EM C&T E P&D
# 3.1 FINANCIAMENTO
source("disp_UNESCO.R", local = new.env())

# 3.2 DISPÊNDIO
source("financ_UNESCO.R", local = new.env())

# 4.. INFRAESTRUTURA CIENTÍFICA
# 4.1 INSTITUIÇÕES DE ENSINO SUPERIOR
# A base com o número de instituições de ensino superior será construída
# a partir de um script de Python que automatiza downloads no site da
# WHED.

# 5.. TRANSFERÊNCIA TECNOLÓGICA
# 5.1 COMÉRCIO INTERNACIONAL DE PRODUTOS DE MÉDIA-ALTA TECNOLOGIA
source("comercio_UNIDO.R", local = new.env())

# 6.. INDICADORES SOCIOECONÔMICOS
# 6.1 PIB
source("PIB_WDI.R", local = new.env())

# 6.2 POPULAÇÃO
source("pop_WDI.R", local = new.env())
