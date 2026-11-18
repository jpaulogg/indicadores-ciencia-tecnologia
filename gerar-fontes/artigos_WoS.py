#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Automação de Coleta e Consolidação - Web of Science (2000 a 2025)
Estratégia: 26 Anos x 10 Macro-Tópicos (TMAC) = 260 downloads Saída
única: ../../fontes/wos_artigos.csv Reino Unido desagregado (Inglaterra,
Escócia, País de Gales e Irlanda do Norte). Pergunta ao usuário antes de
remover os arquivos brutos em temp_dl_wos.
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
	"""Evita que um clique acidental no PowerShell congele o script."""
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
		import websocket	# noqa: F401
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
		print("Criando ambiente virtual local (.venv_wos)...")
		import venv
		venv.create(str(pasta_venv), with_pip=True)

	print("Instalando pacote 'websocket-client' no ambiente local...")
	subprocess.check_call([
		str(python_venv), "-m", "pip", "install", "--quiet", "--upgrade",
			"websocket-client"
	])

	print("Reiniciando o script dentro do ambiente configurado...\n")
	res = subprocess.run([str(python_venv), str(Path(__file__).resolve())] + sys.argv[1:])
	sys.exit(res.returncode)


desativar_quickedit_windows()
garantir_ambiente_e_pacotes()
import websocket	# noqa: E402


# ==============================================================================
# 2. PARÂMETROS DA PESQUISA (26 ANOS x 10 MACRO-TÓPICOS x 52 PAÍSES/TERRITÓRIOS)
# ==============================================================================

ANOS = list(range(2000, 2026))	# 2000 a 2025 (26 anos)
APENAS_ARTIGOS = False
MAX_PASSADAS = 3

# Os 10 Macro-Tópicos (TMAC = Macro Level Citation Topic)
MACRO_TOPICOS_10 = {
	1: "Clinical & Life Sciences",
	2: "Chemistry",
	3: "Agriculture,
	4: "Electrical Engineering,
	5: "Physics",
	6: "Social Sciences",
	7: "Engineering & Materials Science",
	8: "Earth Sciences",
	9: "Mathematics",
	10: "Arts & Humanities",
}

# Dicionário dos 52 Países/Territórios (48 países + 4 nações do Reino Unido desagregadas):
# Código ISO -> (Nome em Português, Lista de nomes equivalentes na Web of Science)
PAISES_52 = {
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
	"GB-ENG": ("Inglaterra", ["ENGLAND"]),
	"GB-SCT": ("Escócia", ["SCOTLAND"]),
	"GB-WLS": ("País de Gales", ["WALES"]),
	"GB-NIR": ("Irlanda do Norte", ["NORTH IRELAND", "NORTHERN IRELAND"]),
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


def conectar_aba_wos(porta_debug, pasta_em_andamento):
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

	caminho_dl_abs = os.path.abspath(pasta_em_andamento)
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


def executar_passo_wos(cdp, url_avancada, query_wos, pasta_em_andamento):
	for f in glob.glob(os.path.join(pasta_em_andamento, "*")):
		try:
			os.remove(f)
		except OSError:
			pass

	# Tenta voltar para a Busca Avançada via clique interno (sem recarregar a página inteira)
	voltou_interno = cdp.executar_js("""
	(async () => {
		const esperar = (ms) => new Promise(r => setTimeout(r, ms));
		const visivel = (el) => el && el.getBoundingClientRect().width > 0 && el.getBoundingClientRect().height > 0;

		if (visivel(document.querySelector("#advancedSearchInputArea"))) return true;

		// Clica no link/botão de busca no menu lateral ou breadcrumb para voltar sem reload
		const btnMenuSearch = Array.from(document.querySelectorAll("a, button")).find(
		el => visivel(el) && (/^(Search|Pesquisar|Advanced Search|Pesquisa avan[çc]ada)$/i.test(el.textContent.trim()) || (el.getAttribute("href") || "").includes("advanced-search"))
		);
		if (btnMenuSearch) {
		btnMenuSearch.click();
		await esperar(1200);
		}
		return visivel(document.querySelector("#advancedSearchInputArea"));
	})()
	""")

	# Só usa Page.navigate (recarregamento completo) se o clique interno não tiver aberto a caixa
	if not voltou_interno:
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

		// 6. Marca "All data rows (up to 100,000)" para baixar todos os países
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
			f for f in glob.glob(os.path.join(pasta_em_andamento, "*.txt"))
			if not f.endswith(".crdownload") and os.path.getsize(f) > 0
		]
		if arquivos_txt:
			time.sleep(0.4)
			return arquivos_txt[0]

	raise RuntimeError("Tempo esgotado aguardando o download do arquivo .txt.")


# ==============================================================================
# 4. CONSOLIDAÇÃO DOS ARQUIVOS EM TABELA ÚNICA E VERIFICAÇÃO DE INTEGRIDADE
# ==============================================================================
def consolidar_dados(pasta_concluidos, arquivo_csv_saida, total_esperado_arquivos):
	"""
	Consolida os arquivos .txt na tabela final de 52 países/territórios x 26 anos x 10 macro-tópicos.
	Retorna True se todos os 260 arquivos esperados foram processados e a tabela
	final foi gravada integralmente com sucesso.
	"""
	arquivos = sorted(
		f for f in glob.glob(os.path.join(pasta_concluidos, "wos_*.txt"))
		if os.path.getsize(f) > 0
	)
	if not arquivos:
		print("\n[Consolidação] Nenhum arquivo .txt encontrado para consolidar.")
		return False

	print(f"\n[Consolidação] Processando {len(arquivos)}/{total_esperado_arquivos} arquivos baixados...")

	# Mapa reverso: Nome WoS -> Código ISO dos 52 países/territórios
	mapa_pais_iso = {}
	for iso, (_, nomes_wos) in PAISES_52.items():
		for n in nomes_wos:
			mapa_pais_iso[n.upper()] = iso

	agregado_52_paises = {}	# (ano, cod_topico, iso) -> artigos
	pares_processados = set()

	for arq in arquivos:
		nome_base = Path(arq).stem	# Ex: wos_2000_topico_01
		partes = nome_base.split("_")
		if len(partes) < 4:
			continue
		try:
			ano = int(partes[1])
			cod_topico = int(partes[3])
		except ValueError:
			continue

		if cod_topico not in MACRO_TOPICOS_10 or ano not in ANOS:
			continue

		pares_processados.add((ano, cod_topico))

		# Inicializa os 52 países/territórios com 0 para este (ano, cod_topico)
		for iso in PAISES_52.keys():
			agregado_52_paises[(ano, cod_topico, iso)] = 0

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
				if iso_code:
					ch = (ano, cod_topico, iso_code)
					agregado_52_paises[ch] = agregado_52_paises.get(ch, 0) + contagem

	os.makedirs(os.path.dirname(arquivo_csv_saida), exist_ok=True)

	linhas_gravadas = 0
	with open(arquivo_csv_saida, "w", encoding="utf-8") as f:
		f.write("ano,iso_pais,pais_nome,id_macro_topico,macro_topico,artigos\n")
		for (ano, cod_top, iso), cont in sorted(agregado_52_paises.items()):
			pais_pt = PAISES_52[iso][0]
			nome_top = MACRO_TOPICOS_10[cod_top]
			pais_esc = f'"{pais_pt}"' if "," in pais_pt else pais_pt
			top_esc = f'"{nome_top}"' if "," in nome_top else nome_top
			f.write(f"{ano},{iso},{pais_esc},{cod_top},{top_esc},{cont}\n")
			linhas_gravadas += 1

	print(f"[Sucesso] Tabela salva em: {arquivo_csv_saida} ({linhas_gravadas} linhas)")

	linhas_esperadas = total_esperado_arquivos * len(PAISES_52)
	coleta_completa = (
		len(pares_processados) == total_esperado_arquivos
		and linhas_gravadas == linhas_esperadas
		and os.path.exists(arquivo_csv_saida)
		and os.path.getsize(arquivo_csv_saida) > 0
	)
	return coleta_completa


# ==============================================================================
# 5. EXECUÇÃO PRINCIPAL
# ==============================================================================
def main():
	# Diretório onde está este script (ex.: .../rotinas/baixar-fontes)
	pasta_raiz = Path(__file__).resolve().parent

	# Diretório de saída final: ../../fontes
	pasta_fontes = (pasta_raiz / ".." / "fontes").resolve()
	os.makedirs(pasta_fontes, exist_ok=True)
	arquivo_csv_saida = os.path.join(pasta_fontes, "wos_artigos.csv")

	# Diretório temporário de downloads subdividido em "em_andamento" e "concluidos"
	pasta_base_temp = os.path.join(pasta_raiz, "temp_dl_wos")
	pasta_em_andamento = os.path.join(pasta_base_temp, "em_andamento")
	pasta_concluidos = os.path.join(pasta_base_temp, "concluidos")
	os.makedirs(pasta_em_andamento, exist_ok=True)
	os.makedirs(pasta_concluidos, exist_ok=True)

	porta_debug = 9222
	perfil_nav = os.path.join(pasta_raiz, ".perfil_navegador_wos")
	os.makedirs(perfil_nav, exist_ok=True)

	navegador_bin = localizar_navegador()
	print(f"[Navegador] Abrindo: {navegador_bin}")
	print(f"[Destino Final] {arquivo_csv_saida}")

	proc_nav = subprocess.Popen([
		navegador_bin,
		f"--remote-debugging-port={porta_debug}",
		"--remote-allow-origins=*",
		f"--user-data-dir={perfil_nav}",
		"--disable-blink-features=AutomationControlled",
		"--no-first-run",
		"--no-default-browser-check",
		"https://www.periodicos.capes.gov.br/",
	], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

	print("\n" + "=" * 70)
	print("INSTRUÇÕES PARA O USUÁRIO:")
	print("1. Na janela do navegador que abriu, acesse a Web of Science.")
	print("2. Aguarde a tela inicial da Web of Science (Core Collection) abrir")
	print("	 e feche eventuais avisos de cookies ou pop-ups.")
	print("=" * 70 + "\n")

	input(">>> Pressione ENTER aqui quando estiver na tela da Web of Science... ")

	cdp, url_atual = conectar_aba_wos(porta_debug, pasta_em_andamento)
	base_wos = url_atual.split("/wos/")[0]
	url_avancada = f"{base_wos}/wos/woscc/advanced-search"
	print(f"[Conectado] Proxy/Domínio detectado: {base_wos}")

	filtro_doc = " AND DT=(Article)" if APENAS_ARTIGOS else ""

	# Lista de 260 buscas (26 anos x 10 Macro-Tópicos TMAC)
	itens_busca = []

	for ano in ANOS:
		for cod_topico, nome_topico in sorted(MACRO_TOPICOS_10.items()):
			query_wos = f'PY={ano} AND TMAC="{cod_topico} {nome_topico}"{filtro_doc}'
			itens_busca.append((cod_topico, nome_topico, query_wos, ano))

	total = len(itens_busca)

	try:
		for passada in range(1, MAX_PASSADAS + 1):
			pendentes = [
				item for item in itens_busca
				if not (
					os.path.exists(os.path.join(pasta_concluidos, f"wos_{item[3]}_topico_{item[0]:02d}.txt"))
					and os.path.getsize(os.path.join(pasta_concluidos, f"wos_{item[3]}_topico_{item[0]:02d}.txt")) > 0
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
				arq_destino = os.path.join(pasta_concluidos, f"wos_{ano}_topico_{cod_topico:02d}.txt")
				if os.path.exists(arq_destino) and os.path.getsize(arq_destino) > 0:
					if passada == 1:
						print(f"[{idx}/{total}] Já salvo: wos_{ano}_topico_{cod_topico:02d}.txt (pulando)")
					continue

				print(f"[{idx}/{total}] Baixando: Ano {ano} | TMAC {cod_topico} ({nome_topico}) ... ", end="", flush=True)
				try:
					resultado = executar_passo_wos(cdp, url_avancada, query_wos, pasta_em_andamento)
					if resultado == "SEM_REGISTROS":
						with open(arq_destino, "w", encoding="utf-8") as f:
							f.write("Countries/Regions\tRecord Count\t%\n")
						print("0 registros (vazio registrado).")
					else:
						shutil.move(resultado, arq_destino)
						print("OK!")

					time.sleep(random.uniform(3.5, 6.5))

				except Exception as e:
					print(f"ERRO: {e}")
					try:
						cdp.fechar()
						cdp, _ = conectar_aba_wos(porta_debug, pasta_em_andamento)
					except Exception:
						pass
					time.sleep(random.uniform(8.0, 12.0))

	finally:
		cdp.fechar()
		proc_nav.terminate()

		# Remove sempre a subpasta de downloads em andamento
		shutil.rmtree(pasta_em_andamento, ignore_errors=True)

		# Consolida os dados em ../../fontes e verifica se todos os 260 arquivos foram processados
		sucesso_total = consolidar_dados(pasta_concluidos, arquivo_csv_saida, total)

		if sucesso_total:
			try:
				resposta = input(
					"\n>>> Todos os 260 arquivos foram consolidados com sucesso.\n"
					">>> Deseja apagar a pasta 'temp_dl_wos' com os arquivos brutos (.txt)? [s/N]: "
				).strip().lower()
			except EOFError:
				resposta = "n"

			if resposta in ("s", "sim", "y", "yes"):
				shutil.rmtree(pasta_base_temp, ignore_errors=True)
				print("[Limpeza] Pasta 'temp_dl_wos' removida com sucesso.")
			else:
				print("[Mantido] Os arquivos brutos (.txt) foram preservados em 'temp_dl_wos/concluidos'.")
		else:
			print(
				"[Aviso] A coleta ainda está incompleta. Os arquivos já baixados foram preservados em "
				"'temp_dl_wos/concluidos' para que a próxima execução retome de onde parou."
			)


if __name__ == "__main__":
	try:
		main()
	except KeyboardInterrupt:
		print("\n[Interrompido] Execução pausada pelo usuário.")
	except Exception as erro_fatal:
		print(f"\n[Erro Fatal] {erro_fatal}")
		if os.name == "nt":
			input("\nPressione ENTER para fechar...")
