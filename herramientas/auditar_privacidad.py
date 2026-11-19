#!/usr/bin/env python3
"""auditar_privacidad.py — Revisa que lo que va a entrar al repositorio público no filtre nada privado.

Cómputo Paralelo · 6BM1 · ESCOM-IPN · 27/1 · herramientas/ · herramienta del profesor
Aplica docs/CONVENCIONES.md §5: docente/ no se publica; nombres, correos y calificaciones de estudiantes nunca
entran al repositorio. Es un guardarraíl mecánico: lo que requiere juicio lo revisa el subagente auditor-privacidad.

Uso:
    python3 herramientas/auditar_privacidad.py [modo] [--repo DIR] [--permitidos ARCHIVO] [--sin-color]

Modos (uno; por defecto --arbol):
    --arbol         todo lo que difiere de HEAD en el árbol de trabajo: cambios con y sin `git add` y archivos nuevos
                    no ignorados. Es lo que usa el hook de Claude Code antes de `git commit`.
    --staged        solo lo que está en el índice (`git diff --cached`). Es lo que usa .githooks/pre-commit.
    --rango A..B    lo que agregan los commits del rango (`git diff A..B`). Antes de `git push` o en un PR.
    --todo          el contenido completo de todos los archivos versionados. Es lo que usa CI.

Reglas (todas BLOQUEANTE salvo donde se indica):
    R1 ruta-docente       una ruta bajo docente/ entra al índice o al commit (alguien usó `git add -f`).
    R2 seguimiento-lleno  herramientas/seguimiento-grupo.csv con filas de datos: la hoja llena vive en docente/.
    R3 correo             una dirección de correo que no es de ejemplo.
    R4 boleta             un número de boleta del IPN (10 dígitos: año de ingreso, 63 de ESCOM, consecutivo).
    R5 curp               una CURP.
    R6 termino-privado    un término de docente/privacidad-terminos.txt (un nombre, apellido o usuario por línea;
                          el profesor lo llena una vez con la lista del grupo; la regla se omite si no existe).
    R7 copia-de-docente   líneas agregadas (>= 50 caracteres) que están tal cual en un archivo de docente/ y no
                          estaban ya publicadas en HEAD. 3 o más en un archivo: BLOQUEANTE; 1 o 2: AVISO.
                          No aplica con --todo ni si docente/ no existe en esta máquina.

Excepciones: herramientas/privacidad-permitidos.txt, una expresión regular por línea (# comenta). Un hallazgo se
descarta si la expresión coincide con "<ruta>:<texto que disparó la regla>". Agregar una excepción es un cambio
visible en el diff: se revisa como cualquier otro.

Salida: una línea por hallazgo, `SEVERIDAD REGLA ruta:línea detalle`, con el dato sensible enmascarado (el registro
de CI es público), y un resumen. Código de salida: 0 sin bloqueantes · 1 con bloqueantes · 2 uso o no es un
repositorio git.

Ejemplos (desde la raíz del repositorio):
    python3 herramientas/auditar_privacidad.py              # antes de un commit
    python3 herramientas/auditar_privacidad.py --rango origin/main..HEAD
    git config core.hooksPath .githooks                     # una vez: audita cada `git commit` hecho a mano
"""
import argparse
import re
import subprocess
import sys
from pathlib import Path

RE_CORREO = re.compile(r"[A-Za-z0-9][A-Za-z0-9._%+-]*@[A-Za-z0-9](?:[A-Za-z0-9-]*\.)+[A-Za-z]{2,}")
RE_BOLETA = re.compile(r"(?<![\d.])(?:19|20)\d{2}63\d{4}(?![\d.]\d|\d)")
RE_CURP = re.compile(r"(?<![A-Z0-9])[A-Z][AEIOUX][A-Z]{2}\d{6}[HM][A-Z]{5}[A-Z0-9]\d(?![A-Z0-9])")
DOMINIOS_DE_EJEMPLO = ("ejemplo.mx", "ejemplo.com", "example.com", "example.org", "example.net", "anthropic.com",
                       "users.noreply.github.com", "localhost.localdomain")
MAX_BYTES = 2_000_000
MIN_LARGO_COPIA = 50
UMBRAL_COPIA = 3


def git(repo, *args, check=True):
    r = subprocess.run(["git", "-C", str(repo), *args], capture_output=True)
    if check and r.returncode != 0:
        raise RuntimeError(f"git {' '.join(args)}: {r.stderr.decode('utf-8', 'replace').strip()}")
    return r.stdout.decode("utf-8", "replace")


def es_binario(datos):
    return b"\0" in datos[:8000]


def enmascarar(texto):
    """Deja ver lo justo para localizar el hallazgo sin repetir el dato en un registro público."""
    if "@" in texto:
        usuario, dominio = texto.split("@", 1)
        return f"{usuario[:1]}***@{dominio}"
    return texto[:4] + "*" * max(0, len(texto) - 4)


def lineas_agregadas(diff):
    """Convierte un `git diff -U0` en {ruta: [(número de línea, texto)]} con solo las líneas agregadas."""
    por_archivo, ruta, n = {}, None, 0
    for linea in diff.splitlines():
        if linea.startswith("+++ "):
            destino = linea[4:].strip()
            ruta = None if destino == "/dev/null" else destino[2:] if destino[:2] in ("b/", "w/", "i/") else destino
            continue
        if linea.startswith("@@"):
            m = re.match(r"@@ -\S+ \+(\d+)", linea)
            n = int(m.group(1)) if m else 0
            continue
        if ruta is None or linea.startswith(("diff ", "index ", "--- ", "\\ ")):
            continue
        if linea.startswith("+"):
            por_archivo.setdefault(ruta, []).append((n, linea[1:]))
            n += 1
    return por_archivo


def lineas_de_archivo(ruta_abs):
    try:
        if ruta_abs.is_symlink() or not ruta_abs.is_file() or ruta_abs.stat().st_size > MAX_BYTES:
            return []
        datos = ruta_abs.read_bytes()
    except OSError:
        return []
    if es_binario(datos):
        return []
    return list(enumerate(datos.decode("utf-8", "replace").splitlines(), 1))


def recolectar(repo, modo, rango):
    """Devuelve (rutas que entran, {ruta: [(línea, texto)]} a revisar)."""
    if modo == "todo":
        rutas = [r for r in git(repo, "ls-files", "-z").split("\0") if r]
        return rutas, {r: lineas_de_archivo(repo / r) for r in rutas}
    if modo == "staged":
        rutas = [r for r in git(repo, "diff", "--cached", "--name-only", "--diff-filter=ACMR", "-z").split("\0") if r]
        return rutas, lineas_agregadas(git(repo, "diff", "--cached", "-U0", "--no-color", "--no-ext-diff"))
    if modo == "rango":
        rutas = [r for r in git(repo, "diff", "--name-only", "--diff-filter=ACMR", "-z", rango).split("\0") if r]
        return rutas, lineas_agregadas(git(repo, "diff", "-U0", "--no-color", "--no-ext-diff", rango))
    # arbol: índice + cambios sin agregar + archivos nuevos no ignorados
    hay_head = subprocess.run(["git", "-C", str(repo), "rev-parse", "-q", "--verify", "HEAD"],
                              capture_output=True).returncode == 0
    base = "HEAD" if hay_head else "4b825dc642cb6eb9a060e54bf8d69288fbee4904"  # árbol vacío de git
    rutas = {r for r in git(repo, "diff", "--name-only", "--diff-filter=ACMR", "-z", base).split("\0") if r}
    rutas |= {r for r in git(repo, "diff", "--cached", "--name-only", "--diff-filter=ACMR", "-z").split("\0") if r}
    agregadas = lineas_agregadas(git(repo, "diff", "-U0", "--no-color", "--no-ext-diff", base))
    for r in git(repo, "ls-files", "--others", "--exclude-standard", "-z").split("\0"):
        if r:
            rutas.add(r)
            agregadas[r] = lineas_de_archivo(repo / r)
    return sorted(rutas), agregadas


def cargar_permitidos(ruta):
    patrones = []
    if ruta.is_file():
        for i, linea in enumerate(ruta.read_text(encoding="utf-8").splitlines(), 1):
            linea = linea.strip()
            if not linea or linea.startswith("#"):
                continue
            try:
                patrones.append(re.compile(linea))
            except re.error as e:
                print(f"auditar_privacidad.py: {ruta}:{i}: expresión no válida ({e})", file=sys.stderr)
                sys.exit(2)
    return patrones


def cargar_terminos(repo):
    ruta = repo / "docente" / "privacidad-terminos.txt"
    if not ruta.is_file():
        return None
    terminos = []
    for linea in ruta.read_text(encoding="utf-8", errors="replace").splitlines():
        linea = linea.strip()
        if len(linea) >= 4 and not linea.startswith("#"):
            terminos.append(linea)
    if not terminos:
        return None
    alternativas = "|".join(re.escape(t) for t in sorted(set(terminos), key=len, reverse=True))
    return re.compile(rf"(?<!\w)(?:{alternativas})(?!\w)", re.IGNORECASE)


def lineas_de_docente(repo):
    """{línea sin espacios en los extremos: ruta dentro de docente/} para las líneas largas de docente/."""
    base = repo / "docente"
    if not base.is_dir():
        return None
    indice = {}
    for ruta in sorted(base.rglob("*")):
        if ruta.name == "privacidad-terminos.txt":
            continue
        for _, texto in lineas_de_archivo(ruta):
            t = texto.strip()
            if len(t) >= MIN_LARGO_COPIA and re.search(r"[A-Za-zÁÉÍÓÚáéíóúñÑ]{4}", t):
                indice.setdefault(t, str(ruta.relative_to(repo)))
    return indice


def lineas_publicas(repo):
    """Conjunto de líneas (sin espacios en los extremos) ya publicadas en HEAD."""
    r = subprocess.run(["git", "-C", str(repo), "grep", "-I", "-h", "--no-color", "-e", "", "HEAD"],
                       capture_output=True)
    return {linea.strip() for linea in r.stdout.decode("utf-8", "replace").splitlines()}


def main():
    ap = argparse.ArgumentParser(description="Audita que no entre nada privado al repositorio público del curso.",
                                 epilog="Reglas, excepciones y códigos de salida: ver la cabecera del script.")
    g = ap.add_mutually_exclusive_group()
    g.add_argument("--arbol", action="store_const", dest="modo", const="arbol")
    g.add_argument("--staged", action="store_const", dest="modo", const="staged")
    g.add_argument("--rango", metavar="A..B")
    g.add_argument("--todo", action="store_const", dest="modo", const="todo")
    ap.add_argument("--repo", default=".")
    ap.add_argument("--permitidos")
    ap.add_argument("--sin-color", action="store_true")
    a = ap.parse_args()
    modo = "rango" if a.rango else (a.modo or "arbol")

    try:
        repo = Path(git(a.repo, "rev-parse", "--show-toplevel").strip())
    except (RuntimeError, FileNotFoundError) as e:
        print(f"auditar_privacidad.py: {a.repo} no es un repositorio git ({e})", file=sys.stderr)
        return 2
    try:
        rutas, contenido = recolectar(repo, modo, a.rango)
    except RuntimeError as e:
        print(f"auditar_privacidad.py: {e}", file=sys.stderr)
        return 2

    permitidos = cargar_permitidos(Path(a.permitidos) if a.permitidos else repo / "herramientas" /
                                   "privacidad-permitidos.txt")
    hallazgos = []  # (severidad, regla, ruta, línea, detalle)

    def reportar(sev, regla, ruta, n, crudo, detalle):
        if any(p.search(f"{ruta}:{crudo}") for p in permitidos):
            return
        hallazgos.append((sev, regla, ruta, n, detalle))

    for ruta in rutas:
        if ruta == "docente" or ruta.startswith("docente/") or "/docente/" in ruta:
            reportar("BLOQUEANTE", "R1 ruta-docente", ruta, 0, ruta,
                     "docente/ no se publica (CONVENCIONES §5): `git restore --staged` o `git rm --cached`")
    seg = repo / "herramientas" / "seguimiento-grupo.csv"
    if "herramientas/seguimiento-grupo.csv" in rutas and seg.is_file():
        filas = [x for x in seg.read_text(encoding="utf-8", errors="replace").splitlines() if x.strip()]
        if len(filas) > 1:
            reportar("BLOQUEANTE", "R2 seguimiento-lleno", "herramientas/seguimiento-grupo.csv", 2, "filas",
                     f"{len(filas) - 1} fila(s) de datos: la hoja llena vive en docente/seguimiento-grupo.csv")

    terminos = cargar_terminos(repo)
    contenido.pop("herramientas/privacidad-permitidos.txt", None)  # las excepciones nombran lo que permiten
    for ruta in sorted(contenido):
        for n, texto in contenido[ruta]:
            for m in RE_CORREO.finditer(texto):
                dominio = m.group(0).rsplit("@", 1)[1].lower()
                if any(dominio == d or dominio.endswith("." + d) for d in DOMINIOS_DE_EJEMPLO):
                    continue
                reportar("BLOQUEANTE", "R3 correo", ruta, n, m.group(0), enmascarar(m.group(0)))
            for m in RE_BOLETA.finditer(texto):
                reportar("BLOQUEANTE", "R4 boleta", ruta, n, m.group(0), enmascarar(m.group(0)))
            for m in RE_CURP.finditer(texto):
                reportar("BLOQUEANTE", "R5 curp", ruta, n, m.group(0), enmascarar(m.group(0)))
            if terminos:
                for m in terminos.finditer(texto):
                    reportar("BLOQUEANTE", "R6 termino-privado", ruta, n, m.group(0),
                             "coincide con docente/privacidad-terminos.txt: " + enmascarar(m.group(0)))

    if modo != "todo":
        docente = lineas_de_docente(repo)
        if docente:
            candidatas = {}
            for ruta, lineas in contenido.items():
                if ruta.startswith("docente/"):
                    continue
                for n, texto in lineas:
                    t = texto.strip()
                    if t in docente:
                        candidatas.setdefault(ruta, []).append((n, t))
            if candidatas:
                publicas = lineas_publicas(repo)
                for ruta, lineas in sorted(candidatas.items()):
                    nuevas = [(n, t) for n, t in lineas if t not in publicas]
                    nuevas = [(n, t) for n, t in nuevas if not any(p.search(f"{ruta}:{t}") for p in permitidos)]
                    if not nuevas:
                        continue
                    sev = "BLOQUEANTE" if len(nuevas) >= UMBRAL_COPIA else "AVISO"
                    origen = docente[nuevas[0][1]]
                    nums = ", ".join(str(n) for n, _ in nuevas[:8]) + (", …" if len(nuevas) > 8 else "")
                    hallazgos.append((sev, "R7 copia-de-docente", ruta, nuevas[0][0],
                                      f"{len(nuevas)} línea(s) idénticas a {origen} (líneas {nums})"))

    bloqueantes = sum(1 for h in hallazgos if h[0] == "BLOQUEANTE")
    for sev, regla, ruta, n, detalle in hallazgos:
        donde = f"{ruta}:{n}" if n else ruta
        print(f"{sev} {regla} {donde} {detalle}")
    avisos = len(hallazgos) - bloqueantes
    notas = []
    if modo != "todo" and not (repo / "docente").is_dir():
        notas.append("sin docente/ en esta máquina: R6 y R7 no se evaluaron")
    elif terminos is None and modo != "todo":
        notas.append("sin docente/privacidad-terminos.txt: R6 no se evaluó")
    print(f"Resumen ({modo}): {len(contenido)} archivo(s) revisados, {bloqueantes} BLOQUEANTE, {avisos} AVISO"
          + (f" · {'; '.join(notas)}" if notas else ""))
    if bloqueantes:
        print("Corrige el archivo o, si es un falso positivo, agrega una excepción a "
              "herramientas/privacidad-permitidos.txt (queda visible en el diff).")
    return 1 if bloqueantes else 0


if __name__ == "__main__":
    sys.exit(main())
