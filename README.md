# Indicadores de Ciência, Tecnologia e Inovação (C&T)

Este repositório contém as rotinas para automação de download,
preparação e consolidação dos indicadores internacionais de Ciência,
Tecnologia e Inovação.

## Execução das Rotinas

Os scripts estão organizados dentro da pasta `rotinas/` e seguem a
seguinte estrutura de funcionamento:

**Execução Independente de Scripts**:

Os scripts individuais presentes no diretório `rotinas/` podem ser
executados separadamente, desde que o script `setup.R` seja carregado
antes (ex.: `source("setup.R")`). O `setup.R` configura o ambiente, os
diretórios de saída e os dicionários globais do projeto.

* **Tipos de Rotinas**:
  * **Downloads Automáticos**: Rotinas dedicadas a automatizar o
    download das bases de dados brutas de fontes internacionais (OCDE,
    UNESCO, OIT, UNIDO, Banco Mundial).
  * **Preparação de Indicadores**: Scripts que filtram, tratam e
    estruturam os dados das fontes para gerar uma versão provisória dos
    indicadores por tema (educação superior, ocupação/pesquisadores,
    produção científica/tecnológica, dispêndio em P&D e comércio
    tecnológico).

**Geração em Lote de Fontes de Dados**:

Existem scripts projetados para gerar e baixar **todas as fontes de
dados necessárias de uma só vez**, **com exceção da base de dados
da Web of Science** (que exige a execução de uma rotina própria de
extração incremental em Python).

**Consolidação e Exportação Final dos Indicadores**:
O script mestre `gerar_indicadores.R` é responsável por executar a
preparação, padronização e exportação de **todos os indicadores de uma
só vez**, salvando os arquivos finais em CSV organizados no diretório
de saída.
