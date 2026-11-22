#!/usr/bin/env python3
"""
Static checks for the generated GSC (there is no GSC compiler for these
engines outside the games themselves, so this catches what it can):

  - balanced (), [], {} outside strings and comments
  - every ::func reference and every plain call resolves to a function in the
    same file, a known engine builtin for that engine, or an allowed cross-file
    call
  - no syntax these engines don't have (ternary ?:, foreach, &&= etc.)
  - simple statements end with ;
  - no duplicate function definitions
"""
import re
import sys
from pathlib import Path

# Builtins used by the menus, by engine. Only names believed to exist in that
# engine are listed; anything else is reported.
COMMON_FUNCS = {
    "isdefined", "isalive", "isplayer", "newclienthudelem", "precacheshader", "setdvar", "getdvar",
    "getentarray", "spawn", "anglestoforward", "bullettrace", "radiusdamage", "earthquake",
    "iprintln", "iprintlnbold", "visionsetnaked", "issubstr", "assert", "registerclientsys",
    "setclientsysstate", "newteamhudelem", "waittillslowprocessallowed",
}
MP_FUNCS = {"map_restart", "kick"}
SP_FUNCS = {"getarraykeys", "getaiarray"}
COMMON_METHODS = {
    "adsbuttonpressed", "meleebuttonpressed", "attackbuttonpressed", "usebuttonpressed",
    "fragbuttonpressed", "freezecontrols", "settext", "setshader", "destroy", "getentitynumber",
    "getcurrentweapon", "givemaxammo", "setweaponammoclip", "giveweapon", "switchtoweapon",
    "takeweapon", "setmovespeedscale", "setorigin", "setplayerangles", "getplayerangles", "linkto",
    "unlink", "moveto", "delete", "setperk", "fadeovertime", "setwaypoint",
}
MP_METHODS = {"setclientdvar", "hide", "show", "suicide", "dropitem"}
SP_METHODS = {"dodamage"}
ISHOST = {"ishost"}

ALLOWED_CROSS = {
    "maps\\mp\\gametypes\\_shmees::init",
    "maps\\_shmees_zm::init",
    "maps\\mp\\killstreaks\\_killstreaks::givekillstreak",
}

KEYWORDS = {"if", "for", "while", "switch", "return", "wait", "case", "default", "break",
            "continue", "thread", "endon", "waittill", "notify", "else", "self", "level",
            "true", "false", "undefined", "game", "waittillframeend", "__xref"}


def strip(text):
    """Blank out comments and string contents, keeping line structure."""
    out, i, n = [], 0, len(text)
    while i < n:
        c = text[i]
        if text.startswith("//", i):
            j = text.find("\n", i)
            j = n if j < 0 else j
            out.append(" " * (j - i)); i = j
        elif text.startswith("/*", i):
            j = text.find("*/", i + 2)
            j = n if j < 0 else j + 2
            out.append(re.sub(r"[^\n]", " ", text[i:j])); i = j
        elif c == '"':
            j = i + 1
            while j < n and text[j] != '"':
                j += 2 if text[j] == "\\" else 1
            out.append('"' + " " * (j - i - 1) + '"'); i = j + 1
        else:
            out.append(c); i += 1
    return "".join(out)


def lint(path, engine, mode):
    raw = Path(path).read_text().replace("\r\n", "\n")
    code = strip(raw)
    errs = []

    # balance
    stack = []
    pairs = {")": "(", "]": "[", "}": "{"}
    for ln, line in enumerate(code.split("\n"), 1):
        for ch in line:
            if ch in "([{":
                stack.append((ch, ln))
            elif ch in ")]}":
                if not stack or stack[-1][0] != pairs[ch]:
                    errs.append(f"line {ln}: unbalanced '{ch}'")
                    return errs
                stack.pop()
    if stack:
        errs.append(f"line {stack[-1][1]}: '{stack[-1][0]}' never closed")
        return errs

    # function definitions: name(args) at column 0 followed by {
    defs = {}
    for m in re.finditer(r"(?m)^([A-Za-z_][A-Za-z0-9_]*)\s*\(([^)]*)\)\s*\n\{", code):
        name = m.group(1).lower()
        if name in defs:
            errs.append(f"duplicate function {m.group(1)}")
        defs[name] = m.group(2)

    funcs = COMMON_FUNCS | (MP_FUNCS if mode == "mp" else SP_FUNCS)
    methods = COMMON_METHODS | (MP_METHODS if mode == "mp" else SP_METHODS)
    if engine in ("iw4", "t5") and mode == "mp":
        methods |= ISHOST

    # function pointer references
    for m in re.finditer(r"(?<![\\\w])::([A-Za-z_]\w*)", code):
        if m.group(1).lower() not in defs:
            errs.append(f"::{m.group(1)} is not defined in this file")

    # cross-file calls
    for m in re.finditer(r"((?:maps|common_scripts)\\[\w\\]+)::(\w+)", code):
        full = (m.group(1) + "::" + m.group(2)).lower()
        if full not in ALLOWED_CROSS:
            errs.append(f"cross-file call not allowed: {m.group(0)}")

    # plain and method calls
    body = re.sub(r"(?:maps|common_scripts)\\[\w\\]+::\w+", "__xref", code)
    for ln, line in enumerate(body.split("\n"), 1):
        if re.match(r"^[A-Za-z_]\w*\s*\(", line):      # a definition line
            continue
        for m in re.finditer(r"([A-Za-z_]\w*)\s*\(", line):
            name = m.group(1)
            low = name.lower()
            if low in KEYWORDS:
                continue
            before = line[:m.start()].rstrip()
            if before.endswith("::"):
                continue
            is_method = bool(re.search(r"[\w\]\)]\s*$", before)) and not re.search(r"\b(thread|return|if|while|else|wait)\s*$", before)
            if low in defs:
                continue
            if is_method and low in methods:
                continue
            if not is_method and low in funcs:
                continue
            if low in funcs or low in methods:
                continue
            errs.append(f"line {ln}: unknown {'method' if is_method else 'function'} {name}()")

    # syntax these engines don't support
    for ln, line in enumerate(code.split("\n"), 1):
        s = line.strip()
        if re.search(r"\?[^?]*:", s) and "::" not in s:
            errs.append(f"line {ln}: ternary operator")
        if re.match(r"foreach\b", s):
            errs.append(f"line {ln}: foreach")
        if re.search(r"&&=|\|\|=", s):
            errs.append(f"line {ln}: compound logical assignment")

    # statements end with ;
    lines = code.split("\n")
    for ln, line in enumerate(lines, 1):
        s = line.strip()
        if not s or s in ("{", "}") or s.endswith(("{", "}", ";", ":")):
            continue
        if s.startswith("#"):
            if not s.endswith(";"):
                errs.append(f"line {ln}: #include without ;")
            continue
        if re.match(r"^(if|else|for|while|switch)\b", s) or s == "else":
            continue
        if re.match(r"^[A-Za-z_]\w*\s*\([^)]*\)$", s):   # function header
            continue
        if re.match(r"^(case\b.*|default)\s*:?$", s):
            continue
        errs.append(f"line {ln}: missing ; -> {s[:60]}")

    return errs


def main(root):
    total = 0
    bad = 0
    for path in sorted(Path(root).rglob("*.gsc")):
        game = path.relative_to(root).parts[0]
        engine = {"COD4": "iw3", "WAW": "t4", "MW2": "iw4", "BO1": "t5"}[game]
        mode = "mp" if "/mp/" in str(path).replace("\\", "/") else "sp"
        errs = lint(path, engine, mode)
        total += 1
        rel = path.relative_to(root)
        if errs:
            bad += 1
            print(f"FAIL {rel}")
            for e in errs[:30]:
                print("     " + e)
        else:
            print(f"ok   {rel}")
    print(f"\n{total - bad}/{total} files clean")
    return 0 if bad == 0 else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1] if len(sys.argv) > 1 else str(Path(__file__).resolve().parent.parent / "ShmeesMenu")))
