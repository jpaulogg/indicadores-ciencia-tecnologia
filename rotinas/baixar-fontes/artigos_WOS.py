#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Automação de Coleta e Consolidação - Web of Science (2000 a 2025)
Estratégia Otimizada: 26 Anos x 10 Macro-Tópicos (TMAC) = 260 downloads
Analisando por: Countries/Regions (captura todos os países + recorte de 49 países)
"""

import os
import sys
import time
import json
import glob
import random
import shutil
import subprocess
import urllib.request
from pathlib import Path


# ==============================================================================
# 1. AUTO-INSTALAÇÃO DE PACOTES E AJUSTE DO TERMINAL WINDOWS
# ==============================================================================
def desativar_quickedit_windows():
    """Impede que um clique acidental na janela do PowerShell congele o script."""
    if os.name == "nt":
        try:
            import ctypes
            kernel32 = ctypes.windll.kernel32
            handle = kernel32.GetStdHandle(-10)
            modo = ctypes.c_uint32()
            if kernel32.GetConsoleMode(handle, ctypes.byref(modo)):
                novo_modo = (modo.value & ~0x0040) | 0x0080
                kernel32.SetConsoleMode(handle, novo_modo)
        except Exception:
            pass


def garantir_ambiente_e_pacotes():
    try:
        import websocket  # noqa: F401
        return
    except ImportError:
        pass

    pasta_script = Path(__file__).resolve().parent
    pasta_venv = pasta_script / ".venv_wos"

    if os.name == "nt":
        python_venv = pasta_venv / "Scripts" / "python.exe"
    else:
        python_venv = pasta_venv / "bin" / "python"

    if not python_venv.exists():
        print("[Setup] Criando ambiente virtual local (.venv_wos)...")
        import venv
        venv.create(str(pasta_venv), with_pip=True)

    print("[Setup] Instalando pacote 'websocket-client' no ambiente local...")
    subprocess.check_call([
        str(python_venv), "-m", "pip", "install", "--quiet", "--upgrade", "websocket-client"
    ])

    print("[Setup] Reiniciando o script dentro do ambiente configurado...\n")
    res = subprocess.run([str(python_venv), str(Path(__file__).resolve())] + sys.argv[1:])
    sys.exit(res.returncode)


desativar_quickedit_windows()
garantir_ambiente_e_pacotes()
import websocket  # noqa: E402

# ==============================================================================
# 2. PARÂMETROS DA PESQUISA (26 ANOS x 10 MACRO-TÓPICOS TMAC = 260 BUSCAS)
# ==============================================================================

ANOS = list(range(2000, 2026))  # 2000 a 2025
APENAS_ARTIGOS = False
MAX_PASSADAS = 3

# Os 10 Macro-Tópicos (TMAC = Macro Level Citation Topic)
# Formato: id -> (Nome Oficial, Cláusula para o campo TMAC=)
MACRO_TOPICOS_10 = {
    1: ("Clinical & Life Sciences", '"1 Clinical & Life Sciences" OR "Clinical & Life Sciences"'),
    2: ("Chemistry", '"2 Chemistry" OR "Chemistry"'),
    3: ("Agriculture, Environment & Ecology", '"3 Agriculture, Environment & Ecology" OR "Agriculture, Environment & Ecology"'),
    4: ("Electrical Engineering, Electronics & Computer Science", '"4 Electrical Engineering, Electronics & Computer Science" OR "Electrical Engineering, Electronics & Computer Science"'),
    5: ("Physics", '"5 Physics" OR "Physics"'),
    6: ("Social Sciences", '"6 Social Sciences" OR "Social Sciences"'),
    7: ("Engineering & Materials Science", '"7 Engineering & Materials Science" OR "Engineering & Materials Science"'),
    8: ("Earth Sciences", '"8 Earth Sciences" OR "Earth Sciences"'),
    9: ("Mathematics", '"9 Mathematics" OR "Mathematics"'),
    10: ("Arts & Humanities", '"10 Arts & Humanities" OR "Arts & Humanities"'),
}

# Os 49 Países selecionados para o painel filtrado
PAISES_49 = {
    "US": ("Estados Unidos", ["USA"]),
    "IL": ("Israel", ["ISRAEL"]),
    "JP": ("Japão", ["JAPAN"]),
    "KR": ("Coreia do Sul", ["SOUTH KOREA"]),
    "AU": ("Austrália", ["AUSTRALIA"]),
    "AT": ("Áustria", ["AUSTRIA"]),
    "BE": ("Bélgica", ["BELGIUM"]),
    "CA": ("Canadá", ["CANADA"]),
    "CH": ("Suíça", ["SWITZERLAND"]),
    "DE": ("Alemanha", ["GERMANY"]),
    "DK": ("Dinamarca", ["DENMARK"]),
    "FI": ("Finlândia", ["FINLAND"]),
    "GB": ("Reino Unido", ["ENGLAND", "SCOTLAND", "WALES", "NORTH IRELAND", "UNITED KINGDOM"]),
    "IE": ("Irlanda", ["IRELAND"]),
    "IS": ("Islândia", ["ICELAND"]),
    "LU": ("Luxemburgo", ["LUXEMBOURG"]),
    "NL": ("Países Baixos", ["NETHERLANDS"]),
    "NO": ("Noruega", ["NORWAY"]),
    "NZ": ("Nova Zelândia", ["NEW ZEALAND"]),
    "SG": ("Cingapura", ["SINGAPORE"]),
    "SE": ("Suécia", ["SWEDEN"]),
    "CN": ("China", ["PEOPLES R CHINA", "CHINA MAINLAND"]),
    "BG": ("Bulgária", ["BULGARIA"]),
    "CZ": ("República Tcheca", ["CZECH REPUBLIC", "CZECHIA"]),
    "ES": ("Espanha", ["SPAIN"]),
    "EE": ("Estônia", ["ESTONIA"]),
    "FR": ("França", ["FRANCE"]),
    "GR": ("Grécia", ["GREECE"]),
    "HR": ("Croácia", ["CROATIA"]),
    "HU": ("Hungria", ["HUNGARY"]),
    "IT": ("Itália", ["ITALY"]),
    "LT": ("Lituânia", ["LITHUANIA"]),
    "LV": ("Letônia", ["LATVIA"]),
    "PL": ("Polônia", ["POLAND"]),
    "PT": ("Portugal", ["PORTUGAL"]),
    "SK": ("Eslováquia", ["SLOVAKIA"]),
    "SI": ("Eslovênia", ["SLOVENIA"]),
    "AR": ("Argentina", ["ARGENTINA"]),
    "BR": ("Brasil", ["BRAZIL"]),
    "CL": ("Chile", ["CHILE"]),
    "CO": ("Colômbia", ["COLOMBIA"]),
    "CR": ("Costa Rica", ["COSTA RICA"]),
    "IN": ("Índia", ["INDIA"]),
    "MX": ("México", ["MEXICO"]),
    "PE": ("Peru", ["PERU"]),
    "RO": ("Romênia", ["ROMANIA"]),
    "RU": ("Rússia", ["RUSSIA"]),
    "TR": ("Turquia", ["TURKEY", "TURKIYE"]),
    "ZA": ("África do Sul", ["SOUTH AFRICA"]),
}


# ==============================================================================
# 3. CONTROLE DO NAVEGADOR VIA CHROME DEVTOOLS PROTOCOL
# ==============================================================================
def localizar_navegador():
    candidatos = []
    if os.name == "nt":
        for env_var in ("PROGRAMFILES", "PROGRAMFILES(X86)", "LOCALAPPDATA"):
            base = os.environ.get(env_var, "")
            if base:
                candidatos.extend([
                    os.path.join(base, "Google", "Chrome", "Application", "chrome.exe"),
                    os.path.join(base, "Microsoft", "Edge", "Application", "msedge.exe"),
                    os.path.join(base, "BraveSoftware", "Brave-Browser", "Application", "brave.exe"),
                ])
    else:
        for cmd in ("chromium", "chromium-browser", "google-chrome", "google-chrome-stable", "brave-browser", "microsoft-edge"):
            caminho = shutil.which(cmd)
            if caminho:
                candidatos.append(caminho)

    for c in candidatos:
        if c and os.path.isfile(c):
            return c
    raise RuntimeError("Nenhum navegador baseado em Chromium (Chrome, Edge, Chromium ou Brave) foi encontrado.")


class ControladorCDP:
    def __init__(self, ws_url):
        self.ws = websocket.create_connection(ws_url, timeout=90, suppress_origin=True)
        self.msg_id = 0

    def enviar(self, metodo, params=None):
        self.msg_id += 1
        alvo_id = self.msg_id
        pacote = {"id": alvo_id, "method": metodo, "params": params or {}}
        self.ws.send(json.dumps(pacote))
        while True:
            resposta = json.loads(self.ws.recv())
            if resposta.get("id") == alvo_id:
                if "error" in resposta:
                    raise RuntimeError(f"Erro CDP ({metodo}): {resposta['error']}")
                return resposta.get("result", {})

    def executar_js(self, codigo_js):
        res = self.enviar("Runtime.evaluate", {
            "expression": codigo_js,
            "awaitPromise": True,
            "returnByValue": True,
        })
        if "exceptionDetails" in res:
            detalhe = res["exceptionDetails"]
            texto = detalhe.get("exception", {}).get("description", detalhe.get("text", "Erro JS"))
            raise RuntimeError(texto)
        return res.get("result", {}).get("value")

    def fechar(self):
        try:
            self.ws.close()
        except Exception:
            pass


def conectar_aba_wos(porta_debug, pasta_temp_dl):
    with urllib.request.urlopen(f"http://127.0.0.1:{porta_debug}/json") as resp:
        abas = json.loads(resp.read().decode("utf-8"))

    aba_wos = next(
        (a for a in abas if a.get("type") == "page" and ("/wos/" in a.get("url", "").lower() or "webofscience" in a.get("url", "").lower())),
        None
    )
    if not aba_wos:
        raise RuntimeError("Aba da Web of Science não encontrada. Certifique-se de que ela está aberta.")

    cdp = ControladorCDP(aba_wos["webSocketDebuggerUrl"])
    cdp.enviar("Page.enable")
    cdp.enviar("Runtime.enable")

    caminho_dl_abs = os.path.abspath(pasta_temp_dl)
    try:
        cdp.enviar("Browser.setDownloadBehavior", {
            "behavior": "allow",
            "downloadPath": caminho_dl_abs,
        })
    except Exception:
        cdp.enviar("Page.setDownloadBehavior", {
            "behavior": "allow",
            "downloadPath": caminho_dl_abs,
        })

    return cdp, aba_wos["url"]


def executar_passo_wos(cdp, url_avancada, query_wos, pasta_temp_dl):
    for f in glob.glob(os.path.join(pasta_temp_dl, "*")):
        try:
            os.remove(f)
        except OSError:
            pass

    cdp.enviar("Page.navigate", {"url": url_avancada})
    time.sleep(2.0)

    js_script = f"""
    (async () => {{
      const esperar = (ms) => new Promise(r => setTimeout(r, ms));
      const regexCat = /Countries\\/Regions|Pa[íi]ses\\/Regi[õo]es|Pa[íi]ses\\/Territ[óo]rios/i;
      const queryStr = {json.dumps(query_wos)};
      const visivel = (el) => {{
        if (!el) return false;
        const rect = el.getBoundingClientRect();
        return rect.width > 0 && rect.height > 0;
      }};
      const foraDoMenu = (el) => !el.closest("header, app-header, nav, aside, footer, [role='navigation']");

      // 1. Aguarda a caixa #advancedSearchInputArea (ou clica em Advanced Search se cair na home)
      let caixa = null;
      const t0 = Date.now();
      while (Date.now() - t0 < 25000) {{
        caixa = document.querySelector("#advancedSearchInputArea");
        if (visivel(caixa)) break;

        const linksAdv = Array.from(document.querySelectorAll(
          "a[href*='advanced-search'], a[data-ta*='advanced'], button[data-ta*='advanced'], a, button"
        )).filter(el => visivel(el) && foraDoMenu(el));

        const btnAdv = linksAdv.find(el => {{
          const txt = el.textContent.trim();
          const href = (el.getAttribute("href") || "").toLowerCase();
          return /^(Advanced Search|Pesquisa avan[çc]ada)$/i.test(txt) || href.includes("advanced-search");
        }});

        if (btnAdv) {{
          btnAdv.click();
          await esperar(1500);
        }} else {{
          await esperar(400);
        }}
      }}

      if (!visivel(caixa)) {{
        throw new Error("Caixa #advancedSearchInputArea não encontrada.");
      }}

      // Limpa e preenche a query
      caixa.focus();
      const setter = Object.getOwnPropertyDescriptor(window.HTMLTextAreaElement.prototype, "value").set;
      setter.call(caixa, "");
      caixa.dispatchEvent(new Event("input", {{ bubbles: true }}));
      await esperar(150);
      setter.call(caixa, queryStr);
      caixa.dispatchEvent(new Event("input", {{ bubbles: true }}));
      caixa.dispatchEvent(new Event("change", {{ bubbles: true }}));
      await esperar(600);

      // 2. Clica no botão Search EXCLUSIVO da Busca Avançada
      let btnSearch = document.querySelector('button[data-ta="run-search-button"]');
      if (!visivel(btnSearch)) {{
        const candidatosSearch = Array.from(
          document.querySelectorAll(".search-button-container button, app-advanced-search button, main button, form button")
        ).filter(b => visivel(b) && foraDoMenu(b));

        btnSearch = candidatosSearch.find(b => /^(Search|Pesquisar)$/i.test(b.textContent.trim()));
      }}

      if (!visivel(btnSearch)) {{
        throw new Error("Botão Search da Busca Avançada não encontrado.");
      }}
      btnSearch.click();

      // 3. Aguarda o botão "Analyze results" OU mensagem de "0 registros encontrados"
      let btnAnalyze = null;
      const t1 = Date.now();
      while (Date.now() - t1 < 35000) {{
        const textoPag = document.body.innerText || "";
        if (/No records match your query|Nenhum registro corresponde|Your search found no records/i.test(textoPag)) {{
          return "SEM_REGISTROS";
        }}
        const candidatos = Array.from(document.querySelectorAll("a, button")).filter(el => visivel(el) && foraDoMenu(el));
        btnAnalyze = candidatos.find(el => /Analyze results|Analisar resultados/i.test(el.textContent));
        if (btnAnalyze) break;
        await esperar(500);
      }}
      if (!btnAnalyze) throw new Error("Botão 'Analyze results' não apareceu.");
      await esperar(800);
      btnAnalyze.click();

      // 4. Aguarda a tela Analyze Results carregar
      let btnDownload = null;
      const t2 = Date.now();
      while (Date.now() - t2 < 35000) {{
        if (/analyze-results/i.test(window.location.href)) {{
          const btns = Array.from(document.querySelectorAll("button")).filter(el => visivel(el) && foraDoMenu(el));
          btnDownload = btns.find(el => /Download data table|Baixar tabela/i.test(el.textContent));
          if (btnDownload) break;
        }}
        await esperar(500);
      }}
      if (!btnDownload) throw new Error("Tela Analyze Results não carregou a tempo.");
      await esperar(1200);

      // 5. Seleciona "Countries/Regions" (Países/Regiões) no menu da página Analyze Results
      const seletores = Array.from(document.querySelectorAll(
        "app-analyze-results wos-select button, app-analyze-results mat-select, main wos-select button, main mat-select, wos-select button, mat-select, [aria-haspopup='listbox']"
      )).filter(el => visivel(el) && foraDoMenu(el));

      let dropdownCat = seletores.find(el => /Web of Science Categories|Categorias da Web of Science|Citation Topics|T[óo]picos de cita[çc][ãa]o|Countries|Pa[íi]ses|Research Areas|Áreas de pesquisa/i.test(el.textContent)) || seletores[0];

      if (!dropdownCat) throw new Error("Seletor de categoria da página Analyze Results não encontrado.");

      if (!regexCat.test(dropdownCat.textContent.trim())) {{
        dropdownCat.scrollIntoView({{ block: "center" }});
        await esperar(300);
        dropdownCat.click();
        await esperar(800);

        let opcaoCat = null;
        const t3 = Date.now();
        while (Date.now() - t3 < 15000) {{
          const candidatosOpcao = Array.from(document.querySelectorAll(
            '[role="option"], mat-option, .mat-option-text, .options-list li, .wos-select-options button, .wos-select-options li, wos-select li, wos-select button, .cdk-overlay-container [role="option"], .cdk-overlay-container button, .cdk-overlay-container li, .cdk-overlay-container span'
          )).filter(el => visivel(el) && el !== dropdownCat);

          opcaoCat = candidatosOpcao.find(el => {{
            const txt = el.textContent.trim();
            return txt.length < 60 && regexCat.test(txt);
          }});

          if (opcaoCat) break;
          await esperar(400);
        }}

        if (!opcaoCat) {{
          throw new Error("Opção 'Countries/Regions' não encontrada no menu aberto.");
        }}

        opcaoCat.scrollIntoView({{ block: "nearest" }});
        opcaoCat.click();
        await esperar(2500);
      }}

      // 6. Marca "All data rows (up to 100,000)" para baixar todos os países do mundo
      const radios = Array.from(document.querySelectorAll("mat-radio-button, label, input[type='radio']"));
      const radioAll = radios.find(el => visivel(el) && /All data rows|Todas as linhas/i.test(el.textContent || (el.parentElement && el.parentElement.textContent) || ""));
      if (radioAll) {{
        const inputInterno = radioAll.querySelector("input[type='radio']") || radioAll;
        inputInterno.click();
        await esperar(500);
      }}

      // 7. Aguarda o botão "Download data table" ficar pronto (até 20s) e clica nele
      let btnDownloadFinal = null;
      const t4 = Date.now();
      while (Date.now() - t4 < 20000) {{
        const btnsDl = Array.from(document.querySelectorAll("button")).filter(el => visivel(el) && foraDoMenu(el));
        btnDownloadFinal = btnsDl.find(el => /Download data table|Baixar tabela/i.test(el.textContent));
        if (btnDownloadFinal) break;
        await esperar(500);
      }}
      if (!btnDownloadFinal) throw new Error("Botão 'Download data table' não encontrado após selecionar Countries/Regions.");
      btnDownloadFinal.scrollIntoView({{ block: "center" }});
      await esperar(300);
      btnDownloadFinal.click();
      return "OK";
    }})()
    """

    status = cdp.executar_js(js_script)
    if status == "SEM_REGISTROS":
        return "SEM_REGISTROS"

    t_espera = 0.0
    while t_espera < 25.0:
        time.sleep(0.5)
        t_espera += 0.5
        arquivos_txt = [
            f for f in glob.glob(os.path.join(pasta_temp_dl, "*.txt"))
            if not f.endswith(".crdownload") and os.path.getsize(f) > 0
        ]
        if arquivos_txt:
            time.sleep(0.4)
            return arquivos_txt[0]

    raise RuntimeError("Tempo esgotado aguardando o download do arquivo .txt.")


# ==============================================================================
# 4. CONSOLIDAÇÃO DOS ARQUIVOS BAIXADOS EM CSV
# ==============================================================================
def consolidar_dados(pasta_saida):
    arquivos = sorted(glob.glob(os.path.join(pasta_saida, "wos_*.txt")))
    if not arquivos:
        print("\n[Consolidação] Nenhum arquivo .txt encontrado para consolidar.")
        return

    print(f"\n[Consolidação] Processando {len(arquivos)} arquivos baixados e gerando CSVs...")

    # Mapa reverso de Nome WoS -> Código ISO-2 dos 49 países
    mapa_pais_iso = {}
    for iso, (_, nomes_wos) in PAISES_49.items():
        for n in nomes_wos:
            mapa_pais_iso[n.upper()] = iso

    linhas_todos_paises = []
    agregado_49_paises = {}  # (ano, cod_topico, iso) -> artigos

    for arq in arquivos:
        nome_base = Path(arq).stem  # Ex: wos_2000_topico_01
        partes = nome_base.split("_")
        if len(partes) < 4:
            continue
        try:
            ano = int(partes[1])
            cod_topico = int(partes[3])
        except ValueError:
            continue

        if cod_topico not in MACRO_TOPICOS_10:
            continue
        nome_topico = MACRO_TOPICOS_10[cod_topico][0]

        # Inicializa os 49 países com 0 para este (ano, cod_topico)
        for iso in PAISES_49.keys():
            agregado_49_paises[(ano, cod_topico, iso)] = 0

        with open(arq, "r", encoding="utf-8", errors="replace") as f:
            linhas = [ln.rstrip("\r\n") for ln in f if ln.strip()]

        if len(linhas) > 1:
            for ln in linhas[1:]:
                cols = ln.split("\t")
                if len(cols) < 2:
                    continue
                pais_wos = cols[0].strip().upper()
                try:
                    contagem = int(cols[1].strip())
                except ValueError:
                    continue

                iso_code = mapa_pais_iso.get(pais_wos, "")
                linhas_todos_paises.append((ano, cod_topico, nome_topico, pais_wos, iso_code, contagem))

                if iso_code:
                    ch = (ano, cod_topico, iso_code)
                    agregado_49_paises[ch] = agregado_49_paises.get(ch, 0) + contagem

    # CSV 1: Painel dos 49 Países x 10 Macro-tópicos x Anos
    csv_49 = "wos_painel_49paises_10macrotopicos.csv"
    with open(csv_49, "w", encoding="utf-8") as f:
        f.write("ano,iso_pais,pais_nome,id_macro_topico,macro_topico,artigos\n")
        for (ano, cod_top, iso), cont in sorted(agregado_49_paises.items()):
            pais_pt = PAISES_49[iso][0]
            nome_top = MACRO_TOPICOS_10[cod_top][0]
            pais_esc = f'"{pais_pt}"' if "," in pais_pt else pais_pt
            top_esc = f'"{nome_top}"' if "," in nome_top else nome_top
            f.write(f"{ano},{iso},{pais_esc},{cod_top},{top_esc},{cont}\n")

    # CSV 2: Painel Completo com todos os ~200 países do mundo
    csv_completo = "wos_painel_todos_paises_10macrotopicos.csv"
    with open(csv_completo, "w", encoding="utf-8") as f:
        f.write("ano,id_macro_topico,macro_topico,pais_wos,iso_pais,artigos\n")
        for ano, cod_top, nome_top, pais_wos, iso, cont in linhas_todos_paises:
            top_esc = f'"{nome_top}"' if "," in nome_top else nome_top
            pais_esc = f'"{pais_wos}"' if "," in pais_wos else pais_wos
            f.write(f"{ano},{cod_top},{top_esc},{pais_esc},{iso},{cont}\n")

    print(f"[Sucesso] Painel 49 países salvo em: {csv_49}")
    print(f"[Sucesso] Painel completo (todos os países) salvo em: {csv_completo}")


# ==============================================================================
# 5. EXECUÇÃO PRINCIPAL
# ==============================================================================
def main():
    pasta_raiz = Path(__file__).resolve().parent
    pasta_saida = os.path.join(pasta_raiz, "dados_wos", "por_tmac_paises")
    pasta_temp_dl = os.path.join(pasta_raiz, "temp_dl_wos")
    os.makedirs(pasta_saida, exist_ok=True)
    os.makedirs(pasta_temp_dl, exist_ok=True)

    porta_debug = 9222
    perfil_nav = os.path.join(pasta_raiz, ".perfil_navegador_wos")
    os.makedirs(perfil_nav, exist_ok=True)

    navegador_bin = localizar_navegador()
    print(f"[Navegador] Abrindo: {navegador_bin}")

    proc_nav = subprocess.Popen([
        navegador_bin,
        f"--remote-debugging-port={porta_debug}",
        "--remote-allow-origins=*",
        f"--user-data-dir={perfil_nav}",
        "--no-first-run",
        "--no-default-browser-check",
        "https://www.periodicos.capes.gov.br/",
    ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    print("\n" + "=" * 70)
    print("INSTRUÇÕES PARA O USUÁRIO:")
    print("1. Na janela do navegador que abriu, acesse a Web of Science.")
    print("2. Aguarde a tela inicial da Web of Science (Core Collection) abrir")
    print("   e feche eventuais avisos de cookies ou pop-ups.")
    print("=" * 70 + "\n")

    input(">>> Pressione ENTER aqui quando estiver na tela da Web of Science... ")

    cdp, url_atual = conectar_aba_wos(porta_debug, pasta_temp_dl)
    base_wos = url_atual.split("/wos/")[0]
    url_avancada = f"{base_wos}/wos/woscc/advanced-search"
    print(f"[Conectado] Proxy/Domínio detectado: {base_wos}")

    filtro_doc = " AND DT=(Article)" if APENAS_ARTIGOS else ""

    # Lista de 260 buscas (26 anos x 10 Macro-Tópicos TMAC)
    itens_busca = []
    for ano in ANOS:
        for cod_topico, (nome_topico, clausula_tmac) in sorted(MACRO_TOPICOS_10.items()):
            query_wos = f"PY={ano} AND TMAC=({clausula_tmac}){filtro_doc}"
            itens_busca.append((cod_topico, nome_topico, query_wos, ano))

    total = len(itens_busca)

    try:
        for passada in range(1, MAX_PASSADAS + 1):
            pendentes = [
                item for item in itens_busca
                if not (
                    os.path.exists(os.path.join(pasta_saida, f"wos_{item[3]}_topico_{item[0]:02d}.txt"))
                    and os.path.getsize(os.path.join(pasta_saida, f"wos_{item[3]}_topico_{item[0]:02d}.txt")) > 0
                )
            ]

            if not pendentes:
                print("\n[Concluído] Todos os 260 arquivos (26 anos x 10 Macro-Tópicos) foram baixados!")
                break

            if passada > 1:
                print(f"\n=== INICIANDO REPESCAGEM AUTOMÁTICA (Passada {passada}/{MAX_PASSADAS}) ===")
                print(f"Restam {len(pendentes)} arquivos pendentes. Aguardando 15s antes de retomar...")
                time.sleep(15.0)

            for idx, (cod_topico, nome_topico, query_wos, ano) in enumerate(itens_busca, 1):
                arq_destino = os.path.join(pasta_saida, f"wos_{ano}_topico_{cod_topico:02d}.txt")
                if os.path.exists(arq_destino) and os.path.getsize(arq_destino) > 0:
                    if passada == 1:
                        print(f"[{idx}/{total}] Já salvo: wos_{ano}_topico_{cod_topico:02d}.txt (pulando)")
                    continue

                print(f"[{idx}/{total}] Baixando: Ano {ano} | TMAC {cod_topico} ({nome_topico}) ... ", end="", flush=True)
                try:
                    resultado = executar_passo_wos(cdp, url_avancada, query_wos, pasta_temp_dl)
                    if resultado == "SEM_REGISTROS":
                        with open(arq_destino, "w", encoding="utf-8") as f:
                            f.write("Countries/Regions\tRecord Count\t%\n")
                        print("0 registros (vazio registrado).")
                    else:
                        shutil.move(resultado, arq_destino)
                        print("OK!")

                    time.sleep(random.uniform(3.0, 5.5))

                except Exception as e:
                    print(f"ERRO: {e}")
                    try:
                        cdp.fechar()
                        cdp, _ = conectar_aba_wos(porta_debug, pasta_temp_dl)
                    except Exception:
                        pass
                    time.sleep(random.uniform(8.0, 12.0))

    finally:
        cdp.fechar()
        shutil.rmtree(pasta_temp_dl, ignore_errors=True)
        consolidar_dados(pasta_saida)
        proc_nav.terminate()


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n[Interrompido] Execução pausada pelo usuário. Os arquivos baixados até aqui foram consolidados.")
    except Exception as erro_fatal:
        print(f"\n[Erro Fatal] {erro_fatal}")
        if os.name == "nt":
            input("\nPressione ENTER para fechar...")