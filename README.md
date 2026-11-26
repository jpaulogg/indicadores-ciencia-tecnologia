# Indicadores de Ciência, Tecnologia e Inovação (C&T)

Este repositório contém o conjunto de rotinas em R e Python para automação do download, tratamento, padronização e exportação dos indicadores internacionais de Ciência, Tecnologia e Inovação (C&T).

---

## 1. Requisitos e Instruções de Instalação

### Pré-requisitos
* **R (versão 4.0 ou superior)**:
  * Pacotes R recomendados/necessários: "jsonlite", "curl".
  * Instalação via R:
    
```R
install.packages(c("jsonlite", "curl"))
```

* **Python (versão 3.8 ou superior)**:
  * Utilizado na extração incremental de dados de artigos científicos da Web of Science.
  * O script cria/gerencia seu próprio ambiente virtual (".venv_wos") e instala automaticamente o pacote "websocket-client". Se optar por instalar manualmente:
    
```bash
pip install websocket-client
```

* **Navegador Baseado em Chromium**:
  * É necessário ter instalado um navegador baseado em Chromium (**Google Chrome, Microsoft Edge, Chromium ou Brave**) para suporte à automação da Web of Science via Chrome DevTools Protocol (CDP).

---

## 2. Destaque: Extração da Web of Science e Interação com o Navegador

A rotina de coleta de artigos científicos ("artigos_WoS.py") utiliza controle de navegador via **Chrome DevTools Protocol (CDP)**.

> **Atenção**: Esta rotina **pressupõe a interação do usuário com o navegador**. O script inicia uma instância do navegador Chromium e exige que o usuário esteja conectado à rede institucional com acesso liberado à plataforma **Web of Science** (ou que efetue a autenticação/login no portal durante a sessão aberta), permitindo que a automação consulte e colete incrementalmente os dados dos 10 macro-tópicos de citação e dos 52 territórios mapeados.

---

## 3. Grupos Temáticos de Indicadores e Categorias de Desagregação

Os indicadores estão divididos em 4 grandes grupos temáticos, padronizados no formato de 7 colunas ("ano", "pais", "cod_pais", "cod_indicador", "tipo_categoria", "nome_especificacao", "valor"):

### 1. Capacitação e Ocupação em Atividades de C&T e P&D
* **Indicadores**:
  * Concluintes/Titulados no ensino superior (geral e STEM — Bacharelado, Mestrado e Doutorado).
  * Matriculados no ensino superior (geral e STEM).
  * Número de Pesquisadores em Contagem Física / Headcount (HC).
  * Emprego em ocupações STEM e participação percentual no emprego total.
* **Categorias de Desagregação**:
  * "sexo": Feminino e Masculino ("sexo_nome", "SEX", "sex").
  * "inst": Dependência administrativa da instituição ("Pública" e "Privada").
  * "campo": Campos de estudo/formação segundo a classificação ISCED-F.
  * "setor": Setores de atuação dos pesquisadores ("Empresas", "Governo", "Ensino Superior", "Inst. Privadas Sem Fins Lucrativos").
  * "percentual": Proporção do emprego STEM em relação ao emprego total.

### 2. Produção Científica e Patentes de Inovação
* **Indicadores**:
  * Artigos científicos publicados e indexados na Web of Science.
  * Patentes depositadas no escritório americano (USPTO).
  * Patentes depositadas via Tratado de Cooperação em Matéria de Patentes (PCT / WIPO).
  * Famílias Triádicas de Patentes (OCDE).
* **Categorias de Desagregação**:
  * "area": 10 Macro-tópicos de citação da Web of Science (ex.: *Clinical & Life Sciences*, *Chemistry*, *Physics*, *Engineering & Materials Science*, etc.).
  * "campo": 35 Campos tecnológicos da WIPO (ex.: *Biotechnology*, *Pharmaceuticals*, *Computer technology*, *Telecommunications*, etc.).

### 3. Dispêndio e Financiamento de Gastos em C&T
* **Indicadores**:
  * Dispêndio Bruto em Pesquisa e Desenvolvimento (GERD) em valores absolutos (milhares de PPP$ a preços constantes de 2017).
  * Dispêndio Bruto em P&D como proporção percentual do Produto Interno Bruto (% do PIB).
* **Categorias de Desagregação**:
  * "executor": Setor de execução do gasto ("Business Enterprise", "Government", "Higher Education", "Private Non-Profit").
  * "financiador": Fonte de financiamento do gasto ("Business Enterprise", "Government", "Higher Education", "Private Non-Profit", "Rest of the World").

### 4. Importação e Exportação de Produtos de Média-Alta e Alta Intensidade Tecnológica
* **Indicadores**:
  * Exportações e Importações de manufaturas de média-alta e alta intensidade tecnológica (MHT).
* **Categorias de Desagregação**:
  * "total": Valores absolutos em dólares americanos (USD).
  * "percentual": Participação percentual das manufaturas MHT em relação às exportações ou importações totais de bens.

---

## 4. Instruções e Exemplos de Execução do Código

Os scripts podem ser executados separadamente por módulo ou em lote através do pipeline principal.

### A. Execução Individual de Scripts
Cada script dentro da pasta "rotinas/" pode ser rodado de forma autônoma, desde que o script de configuração inicial ("setup.R") seja carregado previamente no ambiente R:

```R
# 1. Carregar o ambiente de configuração inicial
source("rotinas/setup.R", chdir = TRUE)

# 2. Executar um script específico de preparação (ex.: Dispêndio em P&D)
source("rotinas/preparacao/dispendio_ct.R")
```

### B. Download em Lote das Fontes de Dados
Para baixar automaticamente todas as bases de dados brutas de fontes internacionais (OCDE, UNESCO, OIT, UNIDO e Banco Mundial) de uma só vez:

```R
# Executar a rotina integrada de geração de fontes
source("rotinas/gerar_fontes.R")
```

Observação: O script "gerar_fontes.R" baixa todas as bases necessárias, com exceção da Web of Science.

### C. Coleta Incremental da Web of Science (Python)
Para realizar a coleta e atualização da base da Web of Science via automação de navegador:

```bash
python rotinas/fontes/WoS_artigos/artigos_WoS.py
```

### D. Processamento e Exportação Final dos Indicadores
Para executar todo o fluxo de preparação, padronização em 7 colunas e exportação final dos arquivos CSV para o diretório de indicadores:

```R
# Executar o script mestre de consolidação
source("gerar_indicadores.R")
```

Ao final da execução do "gerar_indicadores.R", todos os arquivos estarão organizados em subpastas correspondentes ao código de cada indicador (ex.: "indicadores/CT_DISPPD/CT_DISPPD_total.csv").
