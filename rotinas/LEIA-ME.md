# Guia Técnico das Rotinas de C&T: Estrutura, APIs e Preparação de Dados

Este guia documenta o funcionamento interno das rotinas contidas na pasta `rotinas/`, detalhando o arquivo de configuração central (`setup.R`), a estrutura de chamadas e códigos de API utilizados no download das fontes internacionais, a lógica das rotinas de preparação e notas metodológicas sobre as bases de dados.

---

## 1. Configuração do Ambiente e Parâmetros (`setup.R`)

O script `setup.R` define os parâmetros transversais a todas as rotinas. Ele deve ser carregado antes da execução individual de qualquer script do projeto.

### A. Estrutura de Diretórios e Escopo Temporal
* **`dl_dir`**: Caminho para as rotinas de download (`rotinas/downloads/`).
* **`input_dir`**: Diretório das bases de dados brutas (`fontes/`).
* **`output_dir`**: Diretório de exportação dos indicadores finais (`indicadores/`).
* **`periodo`**: Janela temporal definida para a análise, cobrindo de **2000 a 2025** (`2000:2025`).

### B. Dicionário Geopolítico (`mapa_paises`)
O data frame `mapa_paises` padroniza os **48 países** analisados pelo projeto, agrupados em 5 estratos do Sistema Nacional de Inovação segundo a classificação de **Ribeiro et al. (2026)**:
* **`ISO3`**: Código alfabético de 3 letras da norma ISO (ex.: `USA`, `ISR`, `DEU`, `BRA`).
* **`ISO2`**: Código alfabético de 2 letras da norma ISO (ex.: `US`, `IL`, `DE`, `BR`).
* **`ISO_NUM`**: Código numérico de 3 dígitos da ONU (ex.: `840`, `076`, `276`), utilizado para efetuar o *merge* das bases da UNIDO.
* **`Nome_Completo`**: Nome oficial do país em português.
* **`Grupo`**: Fator ordenado com as categorias do SNI (`Ib` - Líderes da fronteira; `I` - Consolidados; `O` - Outliers em grande ascensão/China; `IIb` - Em transição; `II` - Intermediários com capacidade de absorção).

---

## 2. Detalhes Técnicos das Rotinas de Download (`downloads/`)

### A. OCDE — Organização para a Cooperação e Desenvolvimento Econômico
As chamadas da OCDE utilizam a **SDMX REST API** (`https://sdmx.oecd.org/public/rest/data/`).

1. **Educação Superior (`educ_OCDE.R`)**:
   * **Fluxo SDMX**: `OECD.EDU.IMEP,DSD_EAG_UOE_NON_FIN_STUD@DF_UOE_NF_STUD_DB,1.1/`
   * **Códigos e Dimensões**:
     * Níveis ISCED-11: `ISCED11_6` (Bacharelado/Equivalente), `ISCED11_7` (Mestrado/Equivalente), `ISCED11_8` (Doutorado/Equivalente).
     * Medida (`MEASURE`): `ENRL` (Matriculados), `GRAD` (Concluintes/Titulados).
     * Campos ISCED-F 2013: `_T` (Total), `F00` a `F10`, `F99` e agregação STEM (`F05T07`).
     * Tipo de Instituição (`INST_TYPE_EDU`): `INST_EDU_PUB` (Pública), `INST_EDU_PRIV` (Privada), `INST_EDU` (Total).
     * Unidade de Medida (`UNIT_MEASURE`): `PS` (Contagem de Pessoas).
     * Gênero (`SEX`): `F` (Feminino), `M` (Masculino), `_T` (Total).

2. **Patentes por Campo Tecnológico (`patentes_OCDE.R`)**:
   * **Fluxo SDMX**: `OECD.STI.PIE,DSD_PATENTS@DF_PATENTS,1.0/`
   * **Códigos e Dimensões**:
     * Autoridade de Patentes (`PATENT_AUTHORITIES`): `US50` (USPTO - Estados Unidos), `9P50_1` (PCT / WIPO), `9P50_2` (Famílias Triádicas de Patentes).
     * Medida e Unidade: `AP` (Depósitos de Patentes), `PF` (Famílias de Patentes); `PATN` (Patentes), `PATN_FM` (Famílias).
     * Data de Referência: `PRIORITY` (Data do primeiro depósito de prioridade internacional).
     * Agente Residente: `INVENTOR` (Atribuição baseada no endereço de residência do inventor).
     * Domínios WIPO: 35 campos tecnológicos (`WIPO_01` a `WIPO_35`) e total (`_T`).

3. **População Histórica (`pop_OCDE.R`)**:
   * **Fluxo SDMX**: `OECD.ELS.SAE,DSD_POPULATION@DF_POP_HIST,1.0/`
   * **Códigos**: Indicador `POP`, unidade `PS`, estratificado por gênero (`F`, `M`, `_T`).

---

### B. UNESCO — Instituto de Estatística da UNESCO (UIS)
As requisições da UNESCO consultam a API pública do UIS (`https://api.uis.unesco.org/api/public/data/indicators/export`).

1. **Educação Superior (`educ_UNESCO.R`)**:
   * `25053`: Total de matriculados na educação superior.
   * `25057`: Matriculados do sexo feminino.
   * `42620`: Matriculados do sexo masculino.
   * `ETOIP.5T8.PR` / `ETOIP.5T8.PU`: Participação percentual de matriculados em instituições privadas e públicas.
   * `FOSGP.5T8.F500600700` (com sufixos `.F` e `.M`): Percentual de graduados em áreas STEM.

2. **Recursos Humanos em P&D / Pesquisadores (`ocup_UNESCO.R`)**:
   * `21001`: Total de Pesquisadores em Contagem Física (Headcount - HC).
   * `21105`: Pesquisadores do sexo feminino (HC).
   * Setores de Execução: `21205` (Empresas), `21209` (Governo), `21213` (Ensino Superior), `21217` (Instituições Privadas Sem Fins Lucrativos).

3. **Dispêndio em P&D (`disp_UNESCO.R`)**:
   * `EXPPPP.CONST`: GERD Total em milhares de PPP$ a preços constantes de 2017.
   * Execução (`EXPPPP.CONST.SP.*`): `.BUSENTSP` (Empresas), `.GOVSP` (Governo), `.HIEDUSP` (Ensino Superior), `.PRNPSP` (Privada Sem Fins Lucrativos), `.SPNS` (Não Especificado).
   * Financiamento (`EXPPPP.CONST.SF.*`): `.BUSENTFS` (Empresas), `.GOVFS` (Governo), `.HIEDUFS` (Ensino Superior), `.PRNPFS` (Privada Sem Fins Lucrativos), `.FUNABFS` (Exterior), `.FSNS` (Não Especificado).
   * Intensidade de P&D: `EXPGDP.TOT` (GERD como % do PIB) e desagregações por setor `EXPGDP.SP.*`.

---

### C. OIT — Organização Internacional do Trabalho (ILOSTAT)
A rotina `ocup_OIT.R` conecta-se à API web do ILOSTAT (`https://rplumber.ilo.org/data/indicator/`).

* **`EMP_STEM_SEX_STE_NB_A`**: Emprego em ocupações STEM em milhares de pessoas, por sexo (`SEX_T`, `SEX_F`, `SEX_M`) e agregação ocupacional (`STE_AGGREGATE_TOTAL`).
* **`EMP_TEMP_AGE_STE_NB_A`**: Emprego total por faixa etária (usado como denominador no cálculo do percentual STEM).

---

### D. UNIDO — Organização das Nações Unidas para o Desenvolvimento Industrial
A rotina `comercio_UNIDO.R` consome a API da UNIDO enviando uma requisição JSON contendo as especificações do dataset.

* **Base de Dados**: *Manufacturing Trade Database* (MTD).
* **Variáveis Solicitadas**:
  * `X_MHT`: Exportações de produtos de média-alta e alta intensidade tecnológica.
  * `M_MHT`: Importações de produtos de média-alta e alta intensidade tecnológica.
  * `X_T`: Exportações totais de manufaturas/bens.
  * `M_T`: Importações totais de manufaturas/bens.

---

### E. Banco Mundial (World Bank WDI)
As rotinas `PIB_WDI.R` e `pop_WDI.R` consultam a API v2 do Banco Mundial.

* **PIB**: `NY.GDP.MKTP.PP.CD` (PPP corrente internacional $) e `NY.GDP.MKTP.PP.KD` (PPP constante internacional $ de 2021).
* **População**: `SP.POP.TOTL` (Total), `SP.POP.TOTL.FE.IN` (Feminina), `SP.POP.TOTL.MA.IN` (Masculina).

---

### F. Web of Science (`artigos_WoS.py`)
Rotina em Python controlada via Chrome DevTools Protocol (CDP) usando WebSocket para raspagem e consolidação incremental.

* **10 Macro-Tópicos de Citação (TMAC)**:
  1. *Clinical & Life Sciences* (Código 1)
  2. *Chemistry* (Código 2)
  3. *Agriculture, Environment & Ecology* (Código 3)
  4. *Electrical Engineering, Electronics & Computer Science* (Código 4)
  5. *Physics* (Código 5)
  6. *Social Sciences* (Código 6)
  7. *Engineering & Materials Science* (Código 7)
  8. *Earth Sciences* (Código 8)
  9. *Mathematics* (Código 9)
  10. *Arts & Humanities* (Código 10)
* **Tratamento Territorial**: O Reino Unido é mantido desagregado em 4 territórios (`GB-ENG` - Inglaterra, `GB-SCT` - Escócia, `GB-WLS` - País de Gales, `GB-NIR` - Irlanda do Norte) para refletir a contagem institucional original da Web of Science.
* **Atualização**: para atualizar essa base de dados basta editar a
  variável `ANOS` da rotina de download e então executá-la.

---

## 3. Estrutura e Lógica das Rotinas de Preparação (`preparacao/`)

As rotinas na pasta `preparacao/` leem os dados brutos e estruturam os objetos de saída no formato de listas do R (`ct_indicador`), prontas para consumo do script `gerar_indicadores.R`.

* **`educ_sup.R`**: Utiliza as funções customizadas `agregar()` e `agregar.bloco()` para filtrar níveis ISCED (6, 7 ou 8) e áreas STEM, gerando sub-tabelas nomeadas (`$campo`, `$inst`, `$sexo`, `$total`).
* **`ocupacao_ct.R`**: Calcula dinamicamente o número de pesquisadores masculinos por diferença (`pesq_masc = total - feminino`) e combina a base STEM da OIT com o emprego total para estimar a taxa percentual.
* **`producao_ct.R`**: Ingere o arquivo `WoS_artigos/consolidado.csv` e aplica a rotulagem dos 35 campos tecnológicos da WIPO (`campos_nome`) sobre as patentes da OCDE (`US50`, `9P50_1` e `9P50_2`).
* **`dispendio_ct.R`**: Agrupa os gastos de P&D em valores absolutos constantes (PPP$ de 2017) e em percentual do PIB por setor executor e financiador.
* **`comercio_tec.R`**: Realiza o *merge* das importações e exportações da UNIDO via código numérico de país (`ISO_NUM`) e calcula a proporção MHT sobre o total de bens.

---

## 4. Notas Metodológicas sobre as Bases de Dados

1. **Diferenças de Escopo UNESCO vs. OCDE**:
   * A UNESCO prioriza ampla cobertura geográfica global (países em desenvolvimento), porém com dados educacionais e de P&D agrupados em macro-categorias.
   * A OCDE fornece elevado detalhamento disciplinar (ISCED-F de 3 dígitos e 35 campos WIPO), porém restrito aos seus membros e economias parceiras.
2. **Unidade Monetária em P&D**:
   * Os valores do indicador `EXPPPP.CONST` estão expressos em **milhares de dólares em Paridade de Poder de Compra (PPP$) a preços constantes de 2017**, corrigindo distorções inflacionárias e diferenças de custo de vida entre os países.
3. **Classificação Tecnológica WIPO (35 Campos)**:
   * As patentes são categorizadas conforme a tabela padrão da WIPO em 35 setores de tecnologia (ex.: *Biotechnology*, *Pharmaceuticals*, *Telecommunications*, *Semiconductors*, *Civil engineering*).
