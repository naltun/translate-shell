#!/usr/bin/gawk -f
BEGIN {
Name        = "Translate Shell"
Description = "Command-line translator using Google Translate, Bing Translator, Yandex.Translate, etc."
Version     = "0.9.7.1"
ReleaseDate = "2023-02-08"
Command     = "trans"
EntryPoint  = "translate.awk"
EntryScript = "translate"
}
function initConst() {
NULLSTR = ""
NONE = "\0"
TRUE = 1
STDIN  = "/dev/stdin"
STDOUT = "/dev/stdout"
STDERR = "/dev/stderr"
SUPOUT = " > /dev/null "
SUPERR = " 2> /dev/null "
PIPE = " | "
}
function anything(array,
i) {
for (i in array)
if (array[i]) return 1
return 0
}
function exists(value) {
if (isarray(value))
return anything(value)
else
return value ? 1 : 0
}
function belongsTo(element, array,
i) {
for (i in array)
if (element == array[i]) return element
return NULLSTR
}
function identical(x, y,
i) {
if (!isarray(x) && !isarray(y))
return x == y
else if (isarray(x) && isarray(y)) {
if (length(x) != length(y)) return 0
for (i in x)
if (!identical(x[i], y[i])) return 0
return 1
} else
return 0
}
function append(array, element) {
array[anything(array) ? length(array) : 0] = element
}
function compareByIndexFields(i1, v1, i2, v2,
t1, t2, tl, j) {
split(i1, t1, SUBSEP)
split(i2, t2, SUBSEP)
tl = length(t1) < length(t2) ? length(t1) : length(t2)
for (j = 1; j <= tl; j++) {
if (t1[j] < t2[j])
return -1
else if (t1[j] > t2[j])
return 1
}
return 0
}
function isnum(string) {
return string == string + 0
}
function startsWithAny(string, substrings,
i) {
for (i in substrings)
if (index(string, substrings[i]) == 1) return substrings[i]
return NULLSTR
}
function matchesAny(string, patterns,
i) {
for (i in patterns)
if (string ~ "^" patterns[i]) return patterns[i]
return NULLSTR
}
function ucfirst(string) {
if (length(string) >= 2)
return toupper(substr(string, 1, 1)) substr(string, 2)
else if (length(string) == 1)
return toupper(string)
return NULLSTR
}
function replicate(string, len,
i, temp) {
temp = NULLSTR
for (i = 0; i < len; i++)
temp = temp string
return temp
}
function reverse(string,
i, temp) {
temp = NULLSTR
for (i = length(string); i > 0; i--)
temp = temp substr(string, i, 1);
return temp
}
function join(array, separator, sortedIn, preserveNull,
i, j, saveSortedIn, temp) {
if (!sortedIn)
sortedIn = "compareByIndexFields"
temp = NULLSTR
j = 0
if (isarray(array)) {
saveSortedIn = PROCINFO["sorted_in"]
PROCINFO["sorted_in"] = sortedIn
for (i in array)
if (preserveNull || array[i] != NULLSTR)
temp = j++ ? temp separator array[i] : array[i]
PROCINFO["sorted_in"] = saveSortedIn
} else
temp = array
return temp
}
function explode(string, array) {
split(string, array, NULLSTR)
}
function escapeChar(char) {
switch (char) {
case "b":
return "\b"
case "f":
return "\f"
case "n":
return "\n"
case "r":
return "\r"
case "t":
return "\t"
case "v":
return "\v"
case "u0026":
return "&"
case "u003c":
return "<"
case "u003d":
return "="
case "u003e":
return ">"
case "u200b":
return ""
default:
return char
}
}
function literal(string,
c, cc, escaping, i, s) {
if (string !~ /^".*"$/)
return string
explode(string, s)
string = NULLSTR
escaping = 0
for (i = 2; i < length(s); i++) {
c = s[i]
if (escaping) {
if (cc) {
cc = cc c
if (length(cc) == 5) {
string = string escapeChar(cc)
escaping = 0
cc = NULLSTR
}
} else if (c == "u") {
cc = c
} else {
string = string escapeChar(c)
escaping = 0
}
} else {
if (c == "\\")
escaping = 1
else
string = string c
}
}
return string
}
function escape(string) {
gsub(/\\/, "\\\\", string)
gsub(/"/, "\\\"", string)
return string
}
function unescape(string) {
gsub(/\\"/, "\"", string)
gsub(/\\\\/, "\\", string)
return string
}
function parameterize(string, quotationMark) {
if (!quotationMark)
quotationMark = "'"
if (quotationMark == "'") {
gsub(/'/, "'\\''", string)
return "'" string "'"
} else {
return "\"" escape(string) "\""
}
}
function unparameterize(string,    temp) {
match(string, /^'(.*)'$/, temp)
if (temp[0]) {
string = temp[1]
gsub(/'\\''/, "'", string)
return string
}
match(string, /^"(.*)"$/, temp)
if (temp[0]) {
string = temp[1]
return unescape(string)
}
return string
}
function toString(value, inline, heredoc, valOnly, numSub, level, sortedIn,
i, items, j, k, p, saveSortedIn, temp, v) {
if (!level) level = 0
if (!sortedIn)
sortedIn = "compareByIndexFields"
if (isarray(value)) {
saveSortedIn = PROCINFO["sorted_in"]
PROCINFO["sorted_in"] = sortedIn
p = 0
for (i in value) {
split(i, j, SUBSEP); k = join(j, ",")
if (!numSub || !isnum(k)) k = parameterize(k, "\"")
v = toString(value[i], inline, heredoc, valOnly, numSub, level + 1, sortedIn)
if (!isarray(value[i])) v = parameterize(v, "\"")
if (valOnly)
items[p++] = inline ? v : (replicate("\t", level) v)
else
items[p++] = inline ? (k ": " v) :
(replicate("\t", level) k "\t" v)
}
PROCINFO["sorted_in"] = saveSortedIn
temp = inline ? join(items, ", ") :
("\n" join(items, "\n") "\n" replicate("\t", level))
temp = valOnly ? ("[" temp "]") : ("{" temp "}")
return temp
} else {
if (heredoc)
return "'''\n" value "\n'''"
else
return value
}
}
function squeeze(line, preserveIndent) {
if (!preserveIndent)
gsub(/^[[:space:]]+/, NULLSTR, line)
gsub(/^[[:space:]]*#.*$/, NULLSTR, line)
gsub(/#[^"/]*$/, NULLSTR, line)
gsub(/[[:space:]]+$/, NULLSTR, line)
gsub(/[[:space:]]+\\$/, "\\", line)
return line
}
function yn(string) {
return (tolower(string) ~ /^([0fn]|off)/) ? 0 : 1
}
function initAnsiCode() {
if (ENVIRON["TERM"] == "dumb") return
AnsiCode["reset"]         = AnsiCode[0] = "\33[0m"
AnsiCode["bold"]          = "\33[1m"
AnsiCode["underline"]     = "\33[4m"
AnsiCode["negative"]      = "\33[7m"
AnsiCode["no bold"]       = "\33[22m"
AnsiCode["no underline"]  = "\33[24m"
AnsiCode["positive"]      = "\33[27m"
AnsiCode["black"]         = "\33[30m"
AnsiCode["red"]           = "\33[31m"
AnsiCode["green"]         = "\33[32m"
AnsiCode["yellow"]        = "\33[33m"
AnsiCode["blue"]          = "\33[34m"
AnsiCode["magenta"]       = "\33[35m"
AnsiCode["cyan"]          = "\33[36m"
AnsiCode["gray"]          = "\33[37m"
AnsiCode["default"]       = "\33[39m"
AnsiCode["dark gray"]     = "\33[90m"
AnsiCode["light red"]     = "\33[91m"
AnsiCode["light green"]   = "\33[92m"
AnsiCode["light yellow"]  = "\33[93m"
AnsiCode["light blue"]    = "\33[94m"
AnsiCode["light magenta"] = "\33[95m"
AnsiCode["light cyan"]    = "\33[96m"
AnsiCode["white"]         = "\33[97m"
}
function ansi(code, text) {
switch (code) {
case "bold":
return AnsiCode[code] text AnsiCode["no bold"]
case "underline":
return AnsiCode[code] text AnsiCode["no underline"]
case "negative":
return AnsiCode[code] text AnsiCode["positive"]
default:
return AnsiCode[code] text AnsiCode[0]
}
}
function w(text) {
print ansi("yellow", text) > STDERR
}
function e(text) {
print ansi("bold", ansi("yellow", text)) > STDERR
}
function wtf(text) {
print ansi("bold", ansi("red", text)) > STDERR
}
function d(text) {
print ansi("gray", text) > STDERR
}
function da(value, name, inline, heredoc, valOnly, numSub, sortedIn,
i, j, saveSortedIn) {
if (!name)
name = "_"
if (!sortedIn)
sortedIn = "compareByIndexFields"
d(name " = " toString(value, inline, heredoc, valOnly, numSub, 0, sortedIn))
}
function assert(x, message) {
if (!message)
message = "[ERROR] Assertion failed."
if (x)
return x
else
e(message)
}
function initUrlEncoding() {
UrlEncoding["\t"] = "%09"
UrlEncoding["\n"] = "%0A"
UrlEncoding[" "]  = "%20"
UrlEncoding["!"]  = "%21"
UrlEncoding["\""] = "%22"
UrlEncoding["#"]  = "%23"
UrlEncoding["$"]  = "%24"
UrlEncoding["%"]  = "%25"
UrlEncoding["&"]  = "%26"
UrlEncoding["'"]  = "%27"
UrlEncoding["("]  = "%28"
UrlEncoding[")"]  = "%29"
UrlEncoding["*"]  = "%2A"
UrlEncoding["+"]  = "%2B"
UrlEncoding[","]  = "%2C"
UrlEncoding["-"]  = "%2D"
UrlEncoding["."]  = "%2E"
UrlEncoding["/"]  = "%2F"
UrlEncoding[":"]  = "%3A"
UrlEncoding[";"]  = "%3B"
UrlEncoding["<"]  = "%3C"
UrlEncoding["="]  = "%3D"
UrlEncoding[">"]  = "%3E"
UrlEncoding["?"]  = "%3F"
UrlEncoding["@"]  = "%40"
UrlEncoding["["]  = "%5B"
UrlEncoding["\\"] = "%5C"
UrlEncoding["]"]  = "%5D"
UrlEncoding["^"]  = "%5E"
UrlEncoding["_"]  = "%5F"
UrlEncoding["`"]  = "%60"
UrlEncoding["{"]  = "%7B"
UrlEncoding["|"]  = "%7C"
UrlEncoding["}"]  = "%7D"
UrlEncoding["~"]  = "%7E"
}
function quote(string,    i, r, s) {
r = NULLSTR
explode(string, s)
for (i = 1; i <= length(s); i++)
r = r (s[i] in UrlEncoding ? UrlEncoding[s[i]] : s[i])
return r
}
function unquote(string,    i, k, r, s, temp) {
r = NULLSTR
explode(string, s)
temp = NULLSTR
for (i = 1; i <= length(s); i++)
if (temp) {
temp = temp s[i]
if (length(temp) > 2) {
for (k in UrlEncoding)
if (temp == UrlEncoding[k]) {
r = r k
temp = NULLSTR
break
}
if (temp) {
r = r temp
temp = NULLSTR
}
}
} else {
if (s[i] != "%")
r = r s[i]
else
temp = s[i]
}
if (temp)
r = r temp
return r
}
function initUriSchemes() {
UriSchemes[0] = "file://"
UriSchemes[1] = "http://"
UriSchemes[2] = "https://"
}
function readFrom(file,    line, text) {
if (!file) file = "/dev/stdin"
text = NULLSTR
while (getline line < file)
text = (text ? text "\n" : NULLSTR) line
return text
}
function writeTo(text, file) {
if (!file) file = "/dev/stdout"
print text > file
}
function getOutput(command,    content, line) {
content = NULLSTR
while ((command |& getline line) > 0)
content = (content ? content "\n" : NULLSTR) line
close(command)
return content
}
function fileExists(file) {
return !system("test -f " parameterize(file))
}
function dirExists(file) {
return !system("test -d " parameterize(file))
}
function detectProgram(prog, arg, returnOutput,    command, temp) {
command = prog " " arg SUPERR
command | getline temp
close(command)
if (returnOutput)
return temp
if (temp)
return prog
return NULLSTR
}
function getGitHead(    line, group) {
if (fileExists(".git/HEAD")) {
getline line < ".git/HEAD"
match(line, /^ref: (.*)$/, group)
if (fileExists(".git/" group[1])) {
getline line < (".git/" group[1])
return substr(line, 1, 7)
} else
return NULLSTR
} else
return NULLSTR
}
BEGIN {
initConst()
initAnsiCode()
initUrlEncoding()
initUriSchemes()
}
function initGawk(    group) {
Gawk = "gawk"
GawkVersion = PROCINFO["version"]
split(PROCINFO["version"], group, ".")
if (group[1] < 4) {
e("[ERROR] Oops! Your gawk (version " GawkVersion ") "\
"appears to be too old.\n"\
"        You need at least gawk 4.0.0 to run this program.")
exit 1
}
}
function initBiDiTerm() {
if (ENVIRON["MLTERM"])
BiDiTerm = "mlterm"
else if (ENVIRON["KONSOLE_VERSION"])
BiDiTerm = "konsole"
}
function initBiDi() {
FriBidi = detectProgram("fribidi", "--version", 1)
BiDiNoPad = FriBidi ? "fribidi --nopad" : "rev" SUPERR
BiDi = FriBidi ? "fribidi --width %s" :
"rev" SUPERR "| sed \"s/'/\\\\\\'/\" | xargs -0 printf '%%%ss'"
}
function initRlwrap() {
Rlwrap = detectProgram("rlwrap", "--version")
}
function initEmacs() {
Emacs = detectProgram("emacs", "--version")
}
function initCurl() {
Curl = detectProgram("curl", "--version")
}
function l(value, name, inline, heredoc, valOnly, numSub, sortedIn) {
if (Option["debug"]) {
if (name)
da(value, name, inline, heredoc, valOnly, numSub, sortedIn)
else
d(value)
}
}
function m(string) {
if (Option["debug"])
return ansi("cyan", string) RS
}
function newerVersion(ver1, ver2,    i, group1, group2) {
split(ver1, group1, ".")
split(ver2, group2, ".")
for (i = 1; i <= 4; i++) {
if (group1[i] + 0 > group2[i] + 0)
return 1
else if (group1[i] + 0 < group2[i] + 0)
return 0
}
return 0
}
function rlwrapMe(    i, command) {
initRlwrap()
if (!Rlwrap) {
l(">> not found: rlwrap")
return 1
}
if (ENVIRON["TRANS_ENTRY"]) {
command = Rlwrap " " ENVIRON["TRANS_ENTRY"] " "\
parameterize("-no-rlwrap")
} else if (fileExists(ENVIRON["TRANS_DIR"] "/" EntryScript)) {
command = Rlwrap " sh "\
parameterize(ENVIRON["TRANS_DIR"] "/" EntryScript)\
" - " parameterize("-no-rlwrap")
} else {
l(">> not found: $TRANS_ENTRY or EntryPoint")
return 1
}
for (i = 1; i < length(ARGV); i++)
if (ARGV[i])
command = command " " parameterize(ARGV[i])
l(">> forking: " command)
if (!system(command)) {
l(">> process exited with code 0")
exit ExitCode
} else {
l(">> process exited with non-zero return code")
return 1
}
}
function emacsMe(    i, params, el, command) {
initEmacs()
if (!Emacs) {
l(">> not found: emacs")
return 1
}
params = ""
for (i = 1; i < length(ARGV); i++)
if (ARGV[i])
params = params " " parameterize(ARGV[i], "\"")
if (ENVIRON["TRANS_ENTRY"]) {
el = "(progn (setq explicit-shell-file-name \"" ENVIRON["TRANS_ENTRY"] "\") "\
"(setq explicit-" Command "-args '(\"-I\" \"-no-rlwrap\"" params ")) "\
"(command-execute 'shell) (rename-buffer \"" Name "\"))"
} else if (fileExists(ENVIRON["TRANS_DIR"] "/" EntryScript)) {
el = "(progn (setq explicit-shell-file-name \"" "sh" "\") "\
"(setq explicit-" "sh" "-args '(\"" ENVIRON["TRANS_DIR"] "/" EntryScript "\" \"-I\" \"-no-rlwrap\"" params ")) "\
"(command-execute 'shell) (rename-buffer \"" Name "\"))"
} else {
l(">> not found: $TRANS_ENTRY or EntryPoint")
return 1
}
command = Emacs " --eval " parameterize(el)
l(">> forking: " command)
if (!system(command)) {
l(">> process exited with code 0")
exit ExitCode
} else {
l(">> process exited with non-zero return code")
return 1
}
}
function curl(url, output,    command, content, line) {
initCurl()
if (!Curl) {
l(">> not found: curl")
w("[WARNING] curl is not found.")
return NULLSTR
}
command = Curl " --location --silent"
if (Option["proxy"])
command = command " --proxy " parameterize(Option["proxy"])
if (Option["user-agent"])
command = command " --user-agent " parameterize(Option["user-agent"])
command = command " " parameterize(url)
if (output) {
command = command " --output " parameterize(output)
system(command)
return NULLSTR
}
content = NULLSTR
while ((command |& getline line) > 0)
content = (content ? content "\n" : NULLSTR) line
close(command)
return content
}
function curlPost(url, data, output,    command, content, line) {
initCurl()
if (!Curl) {
l(">> not found: curl")
w("[WARNING] curl is not found.")
return NULLSTR
}
command = Curl " --location --silent"
if (Option["proxy"])
command = command " --proxy " parameterize(Option["proxy"])
if (Option["user-agent"])
command = command " --user-agent " parameterize(Option["user-agent"])
command = command " --request POST --data " parameterize(data)
command = command " " parameterize(url)
if (output) {
command = command " --output " parameterize(output)
system(command)
return NULLSTR
}
content = NULLSTR
while ((command |& getline line) > 0)
content = (content ? content "\n" : NULLSTR) line
close(command)
return content
}
function dump(text, group,    command, temp) {
command = "hexdump" " -v -e'1/1 \"%03u\" \" \"'"
command = "echo " parameterize(text) PIPE command
command | getline temp
split(temp, group, " ")
close(command)
return length(group) - 1
}
function dumpX(text, group,    command, temp) {
command = "hexdump" " -v -e'1/1 \"%02X\" \" \"'"
command = "echo " parameterize(text) PIPE command
command | getline temp
split(temp, group, " ")
close(command)
return length(group) - 1
}
function base64(text,    command, temp) {
if (detectProgram("uname", "-s", 1) == "Linux")
command = "echo -n " parameterize(text) PIPE "base64 -w0"
else
command = "echo -n " parameterize(text) PIPE "base64"
command = "bash -c " parameterize(command, "\"")
command | getline temp
close(command)
return temp
}
function uprintf(text,    command, temp) {
command = "echo -en " parameterize(text)
command = "bash -c " parameterize(command, "\"")
command | getline temp
close(command)
return temp
}
function initLocale() {
Locale["af"]["name"]               = "Afrikaans"
Locale["af"]["endonym"]            = "Afrikaans"
Locale["af"]["translations-of"]    = "Vertalings van %s"
Locale["af"]["definitions-of"]     = "Definisies van %s"
Locale["af"]["synonyms"]           = "Sinonieme"
Locale["af"]["examples"]           = "Voorbeelde"
Locale["af"]["see-also"]           = "Sien ook"
Locale["af"]["family"]             = "Indo-European"
Locale["af"]["branch"]             = "West Germanic"
Locale["af"]["iso"]                = "afr"
Locale["af"]["glotto"]             = "afri1274"
Locale["af"]["script"]             = "Latn"
Locale["af"]["spoken-in"]          = "South Africa; Namibia"
Locale["af"]["supported-by"]       = "google; bing; yandex"
Locale["sq"]["name"]               = "Albanian"
Locale["sq"]["endonym"]            = "Shqip"
Locale["sq"]["endonym2"]           = "Gjuha shqipe"
Locale["sq"]["translations-of"]    = "Përkthimet e %s"
Locale["sq"]["definitions-of"]     = "Përkufizime të %s"
Locale["sq"]["synonyms"]           = "Sinonime"
Locale["sq"]["examples"]           = "Shembuj"
Locale["sq"]["see-also"]           = "Shihni gjithashtu"
Locale["sq"]["family"]             = "Indo-European"
Locale["sq"]["branch"]             = "Paleo-Balkan"
Locale["sq"]["iso"]                = "sqi"
Locale["sq"]["glotto"]             = "alba1267"
Locale["sq"]["script"]             = "Latn"
Locale["sq"]["spoken-in"]          = "Albania; Kosovo; Montenegro; North Macedonia"
Locale["sq"]["supported-by"]       = "google; bing; yandex"
Locale["am"]["name"]               = "Amharic"
Locale["am"]["endonym"]            = "አማርኛ"
Locale["am"]["translations-of"]    = "የ %s ትርጉሞች"
Locale["am"]["definitions-of"]     = "የ %s ቃላት ፍችዎች"
Locale["am"]["synonyms"]           = "ተመሳሳይ ቃላት"
Locale["am"]["examples"]           = "ምሳሌዎች"
Locale["am"]["see-also"]           = "የሚከተለውንም ይመልከቱ"
Locale["am"]["family"]             = "Afro-Asiatic"
Locale["am"]["branch"]             = "Semitic"
Locale["am"]["iso"]                = "amh"
Locale["am"]["glotto"]             = "amha1245"
Locale["am"]["script"]             = "Ethi"
Locale["am"]["spoken-in"]          = "Ethiopia"
Locale["am"]["supported-by"]       = "google; bing; yandex"
Locale["ar"]["name"]               = "Arabic"
Locale["ar"]["endonym"]            = "العربية"
Locale["ar"]["translations-of"]    = "ترجمات %s"
Locale["ar"]["definitions-of"]     = "تعريفات %s"
Locale["ar"]["synonyms"]           = "مرادفات"
Locale["ar"]["examples"]           = "أمثلة"
Locale["ar"]["see-also"]           = "انظر أيضًا"
Locale["ar"]["family"]             = "Afro-Asiatic"
Locale["ar"]["branch"]             = "Semitic"
Locale["ar"]["iso"]                = "ara"
Locale["ar"]["glotto"]             = "stan1318"
Locale["ar"]["script"]             = "Arab"
Locale["ar"]["rtl"]                = "true"
Locale["ar"]["spoken-in"]          = "the Arab world"
Locale["ar"]["supported-by"]       = "google; bing; yandex"
Locale["hy"]["name"]               = "Armenian"
Locale["hy"]["endonym"]            = "Հայերեն"
Locale["hy"]["translations-of"]    = "%s-ի թարգմանությունները"
Locale["hy"]["definitions-of"]     = "%s-ի սահմանումները"
Locale["hy"]["synonyms"]           = "Հոմանիշներ"
Locale["hy"]["examples"]           = "Օրինակներ"
Locale["hy"]["see-also"]           = "Տես նաև"
Locale["hy"]["family"]             = "Indo-European"
Locale["hy"]["iso"]                = "hye"
Locale["hy"]["glotto"]             = "nucl1235"
Locale["hy"]["script"]             = "Armn"
Locale["hy"]["spoken-in"]          = "Armenia"
Locale["hy"]["supported-by"]       = "google; bing; yandex"
Locale["as"]["name"]               = "Assamese"
Locale["as"]["endonym"]            = "অসমীয়া"
Locale["as"]["family"]             = "Indo-European"
Locale["as"]["branch"]             = "Indo-Aryan"
Locale["as"]["iso"]                = "asm"
Locale["as"]["glotto"]             = "assa1263"
Locale["as"]["script"]             = "Beng"
Locale["as"]["spoken-in"]          = "the northeastern Indian state of Assam"
Locale["as"]["supported-by"]       = "google; bing"
Locale["ay"]["name"]               = "Aymara"
Locale["ay"]["endonym"]            = "Aymar aru"
Locale["ay"]["family"]             = "Aymaran"
Locale["ay"]["iso"]                = "aym"
Locale["ay"]["glotto"]             = "nucl1667"
Locale["ay"]["script"]             = "Latn"
Locale["ay"]["spoken-in"]          = "Bolivia; Peru"
Locale["ay"]["supported-by"]       = "google"
Locale["az"]["name"]               = "Azerbaijani"
Locale["az"]["name2"]              = "Azeri"
Locale["az"]["endonym"]            = "Azərbaycanca"
Locale["az"]["translations-of"]    = "%s sözünün tərcüməsi"
Locale["az"]["definitions-of"]     = "%s sözünün tərifləri"
Locale["az"]["synonyms"]           = "Sinonimlər"
Locale["az"]["examples"]           = "Nümunələr"
Locale["az"]["see-also"]           = "Həmçinin, baxın:"
Locale["az"]["family"]             = "Turkic"
Locale["az"]["branch"]             = "Oghuz"
Locale["az"]["iso"]                = "aze"
Locale["az"]["glotto"]             = "nort2697"
Locale["az"]["script"]             = "Latn"
Locale["az"]["spoken-in"]          = "Azerbaijan"
Locale["az"]["supported-by"]       = "google; bing; yandex"
Locale["bm"]["name"]               = "Bambara"
Locale["bm"]["endonym"]            = "Bamanankan"
Locale["bm"]["endonym2"]           = "Bamana"
Locale["bm"]["family"]             = "Mande"
Locale["bm"]["branch"]             = "Manding"
Locale["bm"]["iso"]                = "bam"
Locale["bm"]["glotto"]             = "bamb1269"
Locale["bm"]["script"]             = "Latn"
Locale["bm"]["spoken-in"]          = "Mali"
Locale["bm"]["supported-by"]       = "google"
Locale["ba"]["name"]               = "Bashkir"
Locale["ba"]["endonym"]            = "Башҡортса"
Locale["ba"]["endonym2"]           = "башҡорт теле"
Locale["ba"]["family"]             = "Turkic"
Locale["ba"]["branch"]             = "Kipchak"
Locale["ba"]["iso"]                = "bak"
Locale["ba"]["glotto"]             = "bash1264"
Locale["ba"]["script"]             = "Cyrl"
Locale["ba"]["spoken-in"]          = "the Republic of Bashkortostan in Russia"
Locale["ba"]["supported-by"]       = "bing; yandex"
Locale["eu"]["name"]               = "Basque"
Locale["eu"]["endonym"]            = "Euskara"
Locale["eu"]["translations-of"]    = "%s esapidearen itzulpena"
Locale["eu"]["definitions-of"]     = "Honen definizioak: %s"
Locale["eu"]["synonyms"]           = "Sinonimoak"
Locale["eu"]["examples"]           = "Adibideak"
Locale["eu"]["see-also"]           = "Ikusi hauek ere"
Locale["eu"]["family"]             = "Language isolate"
Locale["eu"]["iso"]                = "eus"
Locale["eu"]["glotto"]             = "basq1248"
Locale["eu"]["script"]             = "Latn"
Locale["eu"]["spoken-in"]          = "Euskal Herria in Spain and France"
Locale["eu"]["supported-by"]       = "google; bing; yandex"
Locale["be"]["name"]               = "Belarusian"
Locale["be"]["endonym"]            = "беларуская"
Locale["be"]["translations-of"]    = "Пераклады %s"
Locale["be"]["definitions-of"]     = "Вызначэннi %s"
Locale["be"]["synonyms"]           = "Сінонімы"
Locale["be"]["examples"]           = "Прыклады"
Locale["be"]["see-also"]           = "Гл. таксама"
Locale["be"]["family"]             = "Indo-European"
Locale["be"]["branch"]             = "East Slavic"
Locale["be"]["iso"]                = "bel"
Locale["be"]["glotto"]             = "bela1254"
Locale["be"]["script"]             = "Cyrl"
Locale["be"]["spoken-in"]          = "Belarus"
Locale["be"]["supported-by"]       = "google; yandex"
Locale["bn"]["name"]               = "Bengali"
Locale["bn"]["name2"]              = "Bangla"
Locale["bn"]["endonym"]            = "বাংলা"
Locale["bn"]["translations-of"]    = "%s এর অনুবাদ"
Locale["bn"]["definitions-of"]     = "%s এর সংজ্ঞা"
Locale["bn"]["synonyms"]           = "প্রতিশব্দ"
Locale["bn"]["examples"]           = "উদাহরণ"
Locale["bn"]["see-also"]           = "আরো দেখুন"
Locale["bn"]["family"]             = "Indo-European"
Locale["bn"]["branch"]             = "Indo-Aryan"
Locale["bn"]["iso"]                = "ben"
Locale["bn"]["glotto"]             = "beng1280"
Locale["bn"]["script"]             = "Beng"
Locale["bn"]["spoken-in"]          = "Bangladesh; India"
Locale["bn"]["supported-by"]       = "google; bing; yandex"
Locale["bho"]["name"]              = "Bhojpuri"
Locale["bho"]["endonym"]           = "भोजपुरी"
Locale["bho"]["family"]            = "Indo-European"
Locale["bho"]["branch"]            = "Indo-Aryan"
Locale["bho"]["iso"]               = "bho"
Locale["bho"]["glotto"]            = "bhoj1246"
Locale["bho"]["script"]            = "Deva"
Locale["bho"]["spoken-in"]         = "India; Nepal; Fiji"
Locale["bho"]["supported-by"]      = "google"
Locale["bs"]["name"]               = "Bosnian"
Locale["bs"]["endonym"]            = "Bosanski"
Locale["bs"]["translations-of"]    = "Prijevod za: %s"
Locale["bs"]["definitions-of"]     = "Definicije za %s"
Locale["bs"]["synonyms"]           = "Sinonimi"
Locale["bs"]["examples"]           = "Primjeri"
Locale["bs"]["see-also"]           = "Pogledajte i"
Locale["bs"]["family"]             = "Indo-European"
Locale["bs"]["branch"]             = "South Slavic"
Locale["bs"]["iso"]                = "bos"
Locale["bs"]["glotto"]             = "bosn1245"
Locale["bs"]["script"]             = "Latn"
Locale["bs"]["spoken-in"]          = "Bosnia and Herzegovina"
Locale["bs"]["supported-by"]       = "google; bing; yandex"
Locale["br"]["name"]               = "Breton"
Locale["br"]["endonym"]            = "Brezhoneg"
Locale["br"]["family"]             = "Indo-European"
Locale["br"]["branch"]             = "Celtic"
Locale["br"]["iso"]                = "bre"
Locale["br"]["glotto"]             = "bret1244"
Locale["br"]["script"]             = "Latn"
Locale["br"]["spoken-in"]          = "Brittany in France"
Locale["br"]["supported-by"]       = ""
Locale["bg"]["name"]               = "Bulgarian"
Locale["bg"]["endonym"]            = "български"
Locale["bg"]["translations-of"]    = "Преводи на %s"
Locale["bg"]["definitions-of"]     = "Дефиниции за %s"
Locale["bg"]["synonyms"]           = "Синоними"
Locale["bg"]["examples"]           = "Примери"
Locale["bg"]["see-also"]           = "Вижте също"
Locale["bg"]["family"]             = "Indo-European"
Locale["bg"]["branch"]             = "South Slavic"
Locale["bg"]["iso"]                = "bul"
Locale["bg"]["glotto"]             = "bulg1262"
Locale["bg"]["script"]             = "Cyrl"
Locale["bg"]["spoken-in"]          = "Bulgaria"
Locale["bg"]["supported-by"]       = "google; bing; yandex"
Locale["yue"]["name"]              = "Cantonese"
Locale["yue"]["endonym"]           = "粵語"
Locale["yue"]["endonym2"]          = "廣東話"
Locale["yue"]["family"]            = "Sino-Tibetan"
Locale["yue"]["branch"]            = "Sinitic"
Locale["yue"]["iso"]               = "yue"
Locale["yue"]["glotto"]            = "cant1236"
Locale["yue"]["script"]            = "Hant"
Locale["yue"]["spoken-in"]         = "southeastern China; Hong Kong; Macau"
Locale["yue"]["supported-by"]      = "bing"
Locale["ca"]["name"]               = "Catalan"
Locale["ca"]["endonym"]            = "Català"
Locale["ca"]["translations-of"]    = "Traduccions per a %s"
Locale["ca"]["definitions-of"]     = "Definicions de: %s"
Locale["ca"]["synonyms"]           = "Sinònims"
Locale["ca"]["examples"]           = "Exemples"
Locale["ca"]["see-also"]           = "Vegeu també"
Locale["ca"]["family"]             = "Indo-European"
Locale["ca"]["branch"]             = "Western Romance"
Locale["ca"]["iso"]                = "cat"
Locale["ca"]["glotto"]             = "stan1289"
Locale["ca"]["script"]             = "Latn"
Locale["ca"]["spoken-in"]          = "Països Catalans in Andorra, Spain, France and Italy"
Locale["ca"]["supported-by"]       = "google; bing; yandex"
Locale["ceb"]["name"]              = "Cebuano"
Locale["ceb"]["endonym"]           = "Cebuano"
Locale["ceb"]["translations-of"]   = "%s Mga Paghubad sa PULONG_O_HUGPONG SA PAMULONG"
Locale["ceb"]["definitions-of"]    = "Mga kahulugan sa %s"
Locale["ceb"]["synonyms"]          = "Mga Kapulong"
Locale["ceb"]["examples"]          = "Mga pananglitan:"
Locale["ceb"]["see-also"]          = "Kitaa pag-usab"
Locale["ceb"]["family"]            = "Austronesian"
Locale["ceb"]["branch"]            = "Malayo-Polynesian"
Locale["ceb"]["iso"]               = "ceb"
Locale["ceb"]["glotto"]            = "cebu1242"
Locale["ceb"]["script"]            = "Latn"
Locale["ceb"]["spoken-in"]         = "the southern Philippines"
Locale["ceb"]["supported-by"]      = "google; yandex"
Locale["chr"]["name"]              = "Cherokee"
Locale["chr"]["endonym"]           = "ᏣᎳᎩ"
Locale["chr"]["family"]            = "Iroquoian"
Locale["chr"]["iso"]               = "chr"
Locale["chr"]["glotto"]            = "cher1273"
Locale["chr"]["script"]            = "Cher"
Locale["chr"]["spoken-in"]         = "North America"
Locale["chr"]["supported-by"]      = ""
Locale["ny"]["name"]               = "Chichewa"
Locale["ny"]["name2"]              = "Chinyanja"
Locale["ny"]["endonym"]            = "Nyanja"
Locale["ny"]["translations-of"]    = "Matanthauzidwe a %s"
Locale["ny"]["definitions-of"]     = "Mamasulidwe a %s"
Locale["ny"]["synonyms"]           = "Mau ofanana"
Locale["ny"]["examples"]           = "Zitsanzo"
Locale["ny"]["see-also"]           = "Onaninso"
Locale["ny"]["family"]             = "Atlantic-Congo"
Locale["ny"]["branch"]             = "Bantu"
Locale["ny"]["iso"]                = "nya"
Locale["ny"]["glotto"]             = "nyan1308"
Locale["ny"]["script"]             = "Latn"
Locale["ny"]["spoken-in"]          = "Malawi; Zambia"
Locale["ny"]["supported-by"]       = "google"
Locale["lzh"]["name"]              = "Chinese (Literary)"
Locale["lzh"]["endonym"]           = "文言"
Locale["lzh"]["endonym2"]          = "古漢語"
Locale["lzh"]["family"]            = "Sino-Tibetan"
Locale["lzh"]["branch"]            = "Sinitic"
Locale["lzh"]["iso"]               = "lzh"
Locale["lzh"]["glotto"]            = "lite1248"
Locale["lzh"]["script"]            = "Hans"
Locale["lzh"]["spoken-in"]         = "ancient China"
Locale["lzh"]["supported-by"]      = "bing"
Locale["zh-CN"]["name"]            = "Chinese (Simplified)"
Locale["zh-CN"]["endonym"]         = "简体中文"
Locale["zh-CN"]["translations-of"] = "%s 的翻译"
Locale["zh-CN"]["definitions-of"]  = "%s的定义"
Locale["zh-CN"]["synonyms"]        = "同义词"
Locale["zh-CN"]["examples"]        = "示例"
Locale["zh-CN"]["see-also"]        = "另请参阅"
Locale["zh-CN"]["family"]          = "Sino-Tibetan"
Locale["zh-CN"]["branch"]          = "Sinitic"
Locale["zh-CN"]["iso"]             = "zho-CN"
Locale["zh-CN"]["glotto"]          = "mand1415"
Locale["zh-CN"]["script"]          = "Hans"
Locale["zh-CN"]["dictionary"]      = "true"
Locale["zh-CN"]["spoken-in"]       = "the Greater China regions"
Locale["zh-CN"]["written-in"]      = "mainland China; Singapore"
Locale["zh-CN"]["supported-by"]    = "google; bing; yandex"
Locale["zh-TW"]["name"]            = "Chinese (Traditional)"
Locale["zh-TW"]["endonym"]         = "繁體中文"
Locale["zh-TW"]["endonym2"]        = "正體中文"
Locale["zh-TW"]["translations-of"] = "「%s」的翻譯"
Locale["zh-TW"]["definitions-of"]  = "「%s」的定義"
Locale["zh-TW"]["synonyms"]        = "同義詞"
Locale["zh-TW"]["examples"]        = "例句"
Locale["zh-TW"]["see-also"]        = "另請參閱"
Locale["zh-TW"]["family"]          = "Sino-Tibetan"
Locale["zh-TW"]["branch"]          = "Sinitic"
Locale["zh-TW"]["iso"]             = "zho-TW"
Locale["zh-TW"]["glotto"]          = "mand1415"
Locale["zh-TW"]["script"]          = "Hant"
Locale["zh-TW"]["dictionary"]      = "true"
Locale["zh-TW"]["spoken-in"]       = "the Greater China regions"
Locale["zh-TW"]["written-in"]      = "Taiwan (Republic of China); Hong Kong; Macau"
Locale["zh-TW"]["supported-by"]    = "google; bing"
Locale["cv"]["name"]               = "Chuvash"
Locale["cv"]["endonym"]            = "Чӑвашла"
Locale["cv"]["family"]             = "Turkic"
Locale["cv"]["branch"]             = "Oghur"
Locale["cv"]["iso"]                = "chv"
Locale["cv"]["glotto"]             = "chuv1255"
Locale["cv"]["script"]             = "Cyrl"
Locale["cv"]["spoken-in"]          = "the Chuvash Republic in Russia"
Locale["cv"]["supported-by"]       = "yandex"
Locale["co"]["name"]               = "Corsican"
Locale["co"]["endonym"]            = "Corsu"
Locale["co"]["translations-of"]    = "Traductions de %s"
Locale["co"]["definitions-of"]     = "Définitions de %s"
Locale["co"]["synonyms"]           = "Synonymes"
Locale["co"]["examples"]           = "Exemples"
Locale["co"]["see-also"]           = "Voir aussi"
Locale["co"]["family"]             = "Indo-European"
Locale["co"]["branch"]             = "Italo-Dalmatian"
Locale["co"]["iso"]                = "cos"
Locale["co"]["glotto"]             = "cors1241"
Locale["co"]["script"]             = "Latn"
Locale["co"]["spoken-in"]          = "Corsica in France; the northern end of the island of Sardinia in Italy"
Locale["co"]["supported-by"]       = "google"
Locale["hr"]["name"]               = "Croatian"
Locale["hr"]["endonym"]            = "Hrvatski"
Locale["hr"]["translations-of"]    = "Prijevodi riječi ili izraza %s"
Locale["hr"]["definitions-of"]     = "Definicije riječi ili izraza %s"
Locale["hr"]["synonyms"]           = "Sinonimi"
Locale["hr"]["examples"]           = "Primjeri"
Locale["hr"]["see-also"]           = "Također pogledajte"
Locale["hr"]["family"]             = "Indo-European"
Locale["hr"]["branch"]             = "South Slavic"
Locale["hr"]["iso"]                = "hrv"
Locale["hr"]["glotto"]             = "croa1245"
Locale["hr"]["script"]             = "Latn"
Locale["hr"]["spoken-in"]          = "Croatia; Bosnia and Herzegovina"
Locale["hr"]["supported-by"]       = "google; bing; yandex"
Locale["cs"]["name"]               = "Czech"
Locale["cs"]["endonym"]            = "Čeština"
Locale["cs"]["translations-of"]    = "Překlad výrazu %s"
Locale["cs"]["definitions-of"]     = "Definice výrazu %s"
Locale["cs"]["synonyms"]           = "Synonyma"
Locale["cs"]["examples"]           = "Příklady"
Locale["cs"]["see-also"]           = "Viz také"
Locale["cs"]["family"]             = "Indo-European"
Locale["cs"]["branch"]             = "West Slavic"
Locale["cs"]["iso"]                = "ces"
Locale["cs"]["glotto"]             = "czec1258"
Locale["cs"]["script"]             = "Latn"
Locale["cs"]["spoken-in"]          = "Czechia"
Locale["cs"]["supported-by"]       = "google; bing; yandex"
Locale["da"]["name"]               = "Danish"
Locale["da"]["endonym"]            = "Dansk"
Locale["da"]["translations-of"]    = "Oversættelser af %s"
Locale["da"]["definitions-of"]     = "Definitioner af %s"
Locale["da"]["synonyms"]           = "Synonymer"
Locale["da"]["examples"]           = "Eksempler"
Locale["da"]["see-also"]           = "Se også"
Locale["da"]["family"]             = "Indo-European"
Locale["da"]["branch"]             = "North Germanic"
Locale["da"]["iso"]                = "dan"
Locale["da"]["glotto"]             = "dani1285"
Locale["da"]["script"]             = "Latn"
Locale["da"]["spoken-in"]          = "Denmark; Greenland; the Faroe Islands; the northern German region of Southern Schleswig"
Locale["da"]["supported-by"]       = "google; bing; yandex"
Locale["prs"]["name"]              = "Dari"
Locale["prs"]["endonym"]           = "دری"
Locale["prs"]["family"]            = "Indo-European"
Locale["prs"]["branch"]            = "Iranian"
Locale["prs"]["iso"]               = "prs"
Locale["prs"]["glotto"]            = "dari1249"
Locale["prs"]["script"]            = "Arab"
Locale["prs"]["rtl"]               = "true"
Locale["prs"]["spoken-in"]         = "Afghanistan; Iran"
Locale["prs"]["supported-by"]      = "bing"
Locale["dv"]["name"]               = "Dhivehi"
Locale["dv"]["name2"]              = "Divehi"
Locale["dv"]["name3"]              = "Maldivian"
Locale["dv"]["endonym"]            = "ދިވެހި"
Locale["dv"]["family"]             = "Indo-European"
Locale["dv"]["branch"]             = "Indo-Aryan"
Locale["dv"]["iso"]                = "div"
Locale["dv"]["glotto"]             = "dhiv1236"
Locale["dv"]["script"]             = "Thaa"
Locale["dv"]["rtl"]                = "true"
Locale["dv"]["spoken-in"]          = "the Maldives"
Locale["dv"]["supported-by"]       = "google; bing"
Locale["doi"]["name"]              = "Dogri"
Locale["doi"]["endonym"]           = "डोगरी"
Locale["doi"]["family"]            = "Indo-European"
Locale["doi"]["branch"]            = "Indo-Aryan"
Locale["doi"]["iso"]               = "doi"
Locale["doi"]["glotto"]            = "indo1311"
Locale["doi"]["script"]            = "Deva"
Locale["doi"]["spoken-in"]         = "the Jammu region in northern India"
Locale["doi"]["supported-by"]      = "google"
Locale["nl"]["name"]               = "Dutch"
Locale["nl"]["endonym"]            = "Nederlands"
Locale["nl"]["translations-of"]    = "Vertalingen van %s"
Locale["nl"]["definitions-of"]     = "Definities van %s"
Locale["nl"]["synonyms"]           = "Synoniemen"
Locale["nl"]["examples"]           = "Voorbeelden"
Locale["nl"]["see-also"]           = "Zie ook"
Locale["nl"]["family"]             = "Indo-European"
Locale["nl"]["branch"]             = "West Germanic"
Locale["nl"]["iso"]                = "nld"
Locale["nl"]["glotto"]             = "dutc1256"
Locale["nl"]["script"]             = "Latn"
Locale["nl"]["dictionary"]         = "true"
Locale["nl"]["spoken-in"]          = "the Netherlands; Belgium; Suriname; Aruba; Curaçao; Sint Maarten; the Caribbean Netherlands"
Locale["nl"]["supported-by"]       = "google; bing; yandex"
Locale["dz"]["name"]               = "Dzongkha"
Locale["dz"]["endonym"]            = "རྫོང་ཁ"
Locale["dz"]["family"]             = "Sino-Tibetan"
Locale["dz"]["branch"]             = "Tibetic"
Locale["dz"]["iso"]                = "dzo"
Locale["dz"]["glotto"]             = "nucl1307"
Locale["dz"]["script"]             = "Tibt"
Locale["dz"]["spoken-in"]          = "Bhutan"
Locale["dz"]["supported-by"]       = ""
Locale["en"]["name"]               = "English"
Locale["en"]["endonym"]            = "English"
Locale["en"]["translations-of"]    = "Translations of %s"
Locale["en"]["definitions-of"]     = "Definitions of %s"
Locale["en"]["synonyms"]           = "Synonyms"
Locale["en"]["examples"]           = "Examples"
Locale["en"]["see-also"]           = "See also"
Locale["en"]["family"]             = "Indo-European"
Locale["en"]["branch"]             = "West Germanic"
Locale["en"]["iso"]                = "eng"
Locale["en"]["glotto"]             = "stan1293"
Locale["en"]["script"]             = "Latn"
Locale["en"]["dictionary"]         = "true"
Locale["en"]["spoken-in"]          = "worldwide"
Locale["en"]["supported-by"]       = "google; bing; yandex"
Locale["eo"]["name"]               = "Esperanto"
Locale["eo"]["endonym"]            = "Esperanto"
Locale["eo"]["translations-of"]    = "Tradukoj de %s"
Locale["eo"]["definitions-of"]     = "Difinoj de %s"
Locale["eo"]["synonyms"]           = "Sinonimoj"
Locale["eo"]["examples"]           = "Ekzemploj"
Locale["eo"]["see-also"]           = "Vidu ankaŭ"
Locale["eo"]["family"]             = "Constructed language"
Locale["eo"]["iso"]                = "epo"
Locale["eo"]["glotto"]             = "espe1235"
Locale["eo"]["script"]             = "Latn"
Locale["eo"]["spoken-in"]          = "worldwide"
Locale["eo"]["description"]        = "the world's most widely spoken constructed international auxiliary language, designed to be a universal second language for international communication"
Locale["eo"]["supported-by"]       = "google; yandex"
Locale["et"]["name"]               = "Estonian"
Locale["et"]["endonym"]            = "Eesti"
Locale["et"]["translations-of"]    = "Sõna(de) %s tõlked"
Locale["et"]["definitions-of"]     = "Sõna(de) %s definitsioonid"
Locale["et"]["synonyms"]           = "Sünonüümid"
Locale["et"]["examples"]           = "Näited"
Locale["et"]["see-also"]           = "Vt ka"
Locale["et"]["family"]             = "Uralic"
Locale["et"]["branch"]             = "Finnic"
Locale["et"]["iso"]                = "est"
Locale["et"]["glotto"]             = "esto1258"
Locale["et"]["script"]             = "Latn"
Locale["et"]["spoken-in"]          = "Estonia"
Locale["et"]["supported-by"]       = "google; bing; yandex"
Locale["ee"]["name"]               = "Ewe"
Locale["ee"]["endonym"]            = "Eʋegbe"
Locale["ee"]["family"]             = "Atlantic-Congo"
Locale["ee"]["branch"]             = "Gbe"
Locale["ee"]["iso"]                = "ewe"
Locale["ee"]["glotto"]             = "ewee1241"
Locale["ee"]["script"]             = "Latn"
Locale["ee"]["spoken-in"]          = "Ghana; Togo; Benin"
Locale["ee"]["supported-by"]       = "google"
Locale["fo"]["name"]               = "Faroese"
Locale["fo"]["endonym"]            = "Føroyskt"
Locale["fo"]["family"]             = "Indo-European"
Locale["fo"]["branch"]             = "North Germanic"
Locale["fo"]["iso"]                = "fao"
Locale["fo"]["glotto"]             = "faro1244"
Locale["fo"]["script"]             = "Latn"
Locale["fo"]["spoken-in"]          = "the Faroe Islands"
Locale["fo"]["supported-by"]       = "bing"
Locale["fj"]["name"]               = "Fijian"
Locale["fj"]["endonym"]            = "Vosa Vakaviti"
Locale["fj"]["family"]             = "Austronesian"
Locale["fj"]["branch"]             = "Malayo-Polynesian"
Locale["fj"]["iso"]                = "fij"
Locale["fj"]["glotto"]             = "fiji1243"
Locale["fj"]["script"]             = "Latn"
Locale["fj"]["spoken-in"]          = "Fiji"
Locale["fj"]["supported-by"]       = "bing"
Locale["tl"]["name"]               = "Filipino"
Locale["tl"]["name2"]              = "Tagalog"
Locale["tl"]["endonym"]            = "Filipino"
Locale["tl"]["endonym2"]           = "Tagalog"
Locale["tl"]["translations-of"]    = "Mga pagsasalin ng %s"
Locale["tl"]["definitions-of"]     = "Mga kahulugan ng %s"
Locale["tl"]["synonyms"]           = "Mga Kasingkahulugan"
Locale["tl"]["examples"]           = "Mga Halimbawa"
Locale["tl"]["see-also"]           = "Tingnan rin ang"
Locale["tl"]["family"]             = "Austronesian"
Locale["tl"]["branch"]             = "Malayo-Polynesian"
Locale["tl"]["iso"]                = "fil"
Locale["tl"]["glotto"]             = "fili1244"
Locale["tl"]["script"]             = "Latn"
Locale["tl"]["spoken-in"]          = "the Philippines"
Locale["tl"]["supported-by"]       = "google; bing; yandex"
Locale["fi"]["name"]               = "Finnish"
Locale["fi"]["endonym"]            = "Suomi"
Locale["fi"]["translations-of"]    = "Käännökset tekstille %s"
Locale["fi"]["definitions-of"]     = "Määritelmät kohteelle %s"
Locale["fi"]["synonyms"]           = "Synonyymit"
Locale["fi"]["examples"]           = "Esimerkkejä"
Locale["fi"]["see-also"]           = "Katso myös"
Locale["fi"]["family"]             = "Uralic"
Locale["fi"]["branch"]             = "Finnic"
Locale["fi"]["iso"]                = "fin"
Locale["fi"]["glotto"]             = "finn1318"
Locale["fi"]["script"]             = "Latn"
Locale["fi"]["spoken-in"]          = "Finland"
Locale["fi"]["supported-by"]       = "google; bing; yandex"
Locale["fr"]["name"]               = "French"
Locale["fr"]["endonym"]            = "Français"
Locale["fr"]["translations-of"]    = "Traductions de %s"
Locale["fr"]["definitions-of"]     = "Définitions de %s"
Locale["fr"]["synonyms"]           = "Synonymes"
Locale["fr"]["examples"]           = "Exemples"
Locale["fr"]["see-also"]           = "Voir aussi"
Locale["fr"]["family"]             = "Indo-European"
Locale["fr"]["branch"]             = "Western Romance"
Locale["fr"]["iso"]                = "fra"
Locale["fr"]["glotto"]             = "stan1290"
Locale["fr"]["script"]             = "Latn"
Locale["fr"]["dictionary"]         = "true"
Locale["fr"]["spoken-in"]          = "France; Switzerland; Belgium; Luxembourg"
Locale["fr"]["supported-by"]       = "google; bing; yandex"
Locale["fr-CA"]["name"]            = "French (Canadian)"
Locale["fr-CA"]["endonym"]         = "Français canadien"
Locale["fr-CA"]["translations-of"] = "Traductions de %s"
Locale["fr-CA"]["definitions-of"]  = "Définitions de %s"
Locale["fr-CA"]["synonyms"]        = "Synonymes"
Locale["fr-CA"]["examples"]        = "Exemples"
Locale["fr-CA"]["see-also"]        = "Voir aussi"
Locale["fr-CA"]["family"]          = "Indo-European"
Locale["fr-CA"]["branch"]          = "Western Romance"
Locale["fr-CA"]["iso"]             = "fra-CA"
Locale["fr-CA"]["glotto"]          = "queb1247"
Locale["fr-CA"]["script"]          = "Latn"
Locale["fr-CA"]["spoken-in"]       = "Canada"
Locale["fr-CA"]["supported-by"]    = "bing"
Locale["gl"]["name"]               = "Galician"
Locale["gl"]["endonym"]            = "Galego"
Locale["gl"]["translations-of"]    = "Traducións de %s"
Locale["gl"]["definitions-of"]     = "Definicións de %s"
Locale["gl"]["synonyms"]           = "Sinónimos"
Locale["gl"]["examples"]           = "Exemplos"
Locale["gl"]["see-also"]           = "Ver tamén"
Locale["gl"]["family"]             = "Indo-European"
Locale["gl"]["branch"]             = "Western Romance"
Locale["gl"]["iso"]                = "glg"
Locale["gl"]["glotto"]             = "gali1258"
Locale["gl"]["script"]             = "Latn"
Locale["gl"]["spoken-in"]          = "Galicia in northwestern Spain"
Locale["gl"]["supported-by"]       = "google; bing; yandex"
Locale["ka"]["name"]               = "Georgian"
Locale["ka"]["endonym"]            = "ქართული"
Locale["ka"]["translations-of"]    = "%s-ის თარგმანები"
Locale["ka"]["definitions-of"]     = "%s-ის განსაზღვრებები"
Locale["ka"]["synonyms"]           = "სინონიმები"
Locale["ka"]["examples"]           = "მაგალითები"
Locale["ka"]["see-also"]           = "ასევე იხილეთ"
Locale["ka"]["family"]             = "Kartvelian"
Locale["ka"]["branch"]             = "Karto-Zan"
Locale["ka"]["iso"]                = "kat"
Locale["ka"]["glotto"]             = "nucl1302"
Locale["ka"]["script"]             = "Geor"
Locale["ka"]["spoken-in"]          = "Georgia"
Locale["ka"]["supported-by"]       = "google; bing; yandex"
Locale["de"]["name"]               = "German"
Locale["de"]["endonym"]            = "Deutsch"
Locale["de"]["translations-of"]    = "Übersetzungen für %s"
Locale["de"]["definitions-of"]     = "Definitionen von %s"
Locale["de"]["synonyms"]           = "Synonyme"
Locale["de"]["examples"]           = "Beispiele"
Locale["de"]["see-also"]           = "Siehe auch"
Locale["de"]["family"]             = "Indo-European"
Locale["de"]["branch"]             = "West Germanic"
Locale["de"]["iso"]                = "deu"
Locale["de"]["glotto"]             = "stan1295"
Locale["de"]["script"]             = "Latn"
Locale["de"]["dictionary"]         = "true"
Locale["de"]["spoken-in"]          = "Central Europe"
Locale["de"]["supported-by"]       = "google; bing; yandex"
Locale["el"]["name"]               = "Greek"
Locale["el"]["endonym"]            = "Ελληνικά"
Locale["el"]["translations-of"]    = "Μεταφράσεις του %s"
Locale["el"]["definitions-of"]     = "Όρισμοί %s"
Locale["el"]["synonyms"]           = "Συνώνυμα"
Locale["el"]["examples"]           = "Παραδείγματα"
Locale["el"]["see-also"]           = "Δείτε επίσης"
Locale["el"]["family"]             = "Indo-European"
Locale["el"]["branch"]             = "Paleo-Balkan"
Locale["el"]["iso"]                = "ell"
Locale["el"]["glotto"]             = "mode1248"
Locale["el"]["script"]             = "Grek"
Locale["el"]["spoken-in"]          = "Greece; Cyprus; southern Albania"
Locale["el"]["supported-by"]       = "google; bing; yandex"
Locale["kl"]["name"]               = "Greenlandic"
Locale["kl"]["endonym"]            = "Kalaallisut"
Locale["kl"]["family"]             = "Eskimo-Aleut"
Locale["kl"]["branch"]             = "Inuit"
Locale["kl"]["iso"]                = "kal"
Locale["kl"]["glotto"]             = "kala1399"
Locale["kl"]["script"]             = "Latn"
Locale["kl"]["spoken-in"]          = "Greenland"
Locale["kl"]["supported-by"]       = ""
Locale["gn"]["name"]               = "Guarani"
Locale["gn"]["endonym"]            = "Avañe'ẽ"
Locale["gn"]["family"]             = "Tupian"
Locale["gn"]["iso"]                = "gug"
Locale["gn"]["glotto"]             = "para1311"
Locale["gn"]["script"]             = "Latn"
Locale["gn"]["spoken-in"]          = "Paraguay; Bolivia; Argentina; Brazil"
Locale["gn"]["supported-by"]       = "google"
Locale["gu"]["name"]               = "Gujarati"
Locale["gu"]["endonym"]            = "ગુજરાતી"
Locale["gu"]["translations-of"]    = "%s ના અનુવાદ"
Locale["gu"]["definitions-of"]     = "%s ની વ્યાખ્યાઓ"
Locale["gu"]["synonyms"]           = "સમાનાર્થી"
Locale["gu"]["examples"]           = "ઉદાહરણો"
Locale["gu"]["see-also"]           = "આ પણ જુઓ"
Locale["gu"]["family"]             = "Indo-European"
Locale["gu"]["branch"]             = "Indo-Aryan"
Locale["gu"]["iso"]                = "guj"
Locale["gu"]["glotto"]             = "guja1252"
Locale["gu"]["script"]             = "Gujr"
Locale["gu"]["spoken-in"]          = "the Indian state of Gujarat"
Locale["gu"]["supported-by"]       = "google; bing; yandex"
Locale["ht"]["name"]               = "Haitian Creole"
Locale["ht"]["endonym"]            = "Kreyòl Ayisyen"
Locale["ht"]["translations-of"]    = "Tradiksyon %s"
Locale["ht"]["definitions-of"]     = "Definisyon nan %s"
Locale["ht"]["synonyms"]           = "Sinonim"
Locale["ht"]["examples"]           = "Egzanp:"
Locale["ht"]["see-also"]           = "Wè tou"
Locale["ht"]["family"]             = "Indo-European"
Locale["ht"]["branch"]             = "French Creole"
Locale["ht"]["iso"]                = "hat"
Locale["ht"]["glotto"]             = "hait1244"
Locale["ht"]["script"]             = "Latn"
Locale["ht"]["spoken-in"]          = "Haiti"
Locale["ht"]["supported-by"]       = "google; bing; yandex"
Locale["haw"]["name"]              = "Hawaiian"
Locale["haw"]["endonym"]           = "ʻŌlelo Hawaiʻi"
Locale["haw"]["family"]            = "Austronesian"
Locale["haw"]["branch"]            = "Malayo-Polynesian"
Locale["haw"]["iso"]               = "haw"
Locale["haw"]["glotto"]            = "hawa1245"
Locale["haw"]["script"]            = "Latn"
Locale["haw"]["spoken-in"]         = "the US state of Hawaii"
Locale["haw"]["supported-by"]      = "google"
Locale["ha"]["name"]               = "Hausa"
Locale["ha"]["endonym"]            = "Hausa"
Locale["ha"]["translations-of"]    = "Fassarar %s"
Locale["ha"]["definitions-of"]     = "Ma'anoni na %s"
Locale["ha"]["synonyms"]           = "Masu kamancin ma'ana"
Locale["ha"]["examples"]           = "Misalai"
Locale["ha"]["see-also"]           = "Duba kuma"
Locale["ha"]["family"]             = "Afro-Asiatic"
Locale["ha"]["branch"]             = "Chadic"
Locale["ha"]["iso"]                = "hau"
Locale["ha"]["glotto"]             = "haus1257"
Locale["ha"]["script"]             = "Latn"
Locale["ha"]["spoken-in"]          = "Chad; Nigeria; Niger; Ghana; Cameroon; Benin"
Locale["ha"]["supported-by"]       = "google"
Locale["he"]["name"]               = "Hebrew"
Locale["he"]["endonym"]            = "עִבְרִית"
Locale["he"]["translations-of"]    = "תרגומים של %s"
Locale["he"]["definitions-of"]     = "הגדרות של %s"
Locale["he"]["synonyms"]           = "מילים נרדפות"
Locale["he"]["examples"]           = "דוגמאות"
Locale["he"]["see-also"]           = "ראה גם"
Locale["he"]["family"]             = "Afro-Asiatic"
Locale["he"]["branch"]             = "Semitic"
Locale["he"]["iso"]                = "heb"
Locale["he"]["glotto"]             = "hebr1245"
Locale["he"]["script"]             = "Hebr"
Locale["he"]["rtl"]                = "true"
Locale["he"]["spoken-in"]          = "Israel"
Locale["he"]["supported-by"]       = "google; bing; yandex"
Locale["mrj"]["name"]              = "Hill Mari"
Locale["mrj"]["endonym"]           = "Кырык мары"
Locale["mrj"]["family"]            = "Uralic"
Locale["mrj"]["branch"]            = "Mari"
Locale["mrj"]["iso"]               = "mrj"
Locale["mrj"]["glotto"]            = "west2392"
Locale["mrj"]["script"]            = "Cyrl"
Locale["mrj"]["spoken-in"]         = "the Gornomariysky, Yurinsky and Kilemarsky districts of Mari El, Russia"
Locale["mrj"]["supported-by"]      = "yandex"
Locale["hi"]["name"]               = "Hindi"
Locale["hi"]["endonym"]            = "हिन्दी"
Locale["hi"]["translations-of"]    = "%s के अनुवाद"
Locale["hi"]["definitions-of"]     = "%s की परिभाषाएं"
Locale["hi"]["synonyms"]           = "समानार्थी"
Locale["hi"]["examples"]           = "उदाहरण"
Locale["hi"]["see-also"]           = "यह भी देखें"
Locale["hi"]["family"]             = "Indo-European"
Locale["hi"]["branch"]             = "Indo-Aryan"
Locale["hi"]["iso"]                = "hin"
Locale["hi"]["glotto"]             = "hind1269"
Locale["hi"]["script"]             = "Deva"
Locale["hi"]["spoken-in"]          = "India"
Locale["hi"]["supported-by"]       = "google; bing; yandex"
Locale["hmn"]["name"]              = "Hmong"
Locale["hmn"]["endonym"]           = "Hmoob"
Locale["hmn"]["translations-of"]   = "Lus txhais: %s"
Locale["hmn"]["family"]            = "Hmong-Mien"
Locale["hmn"]["branch"]            = "Hmongic"
Locale["hmn"]["iso"]               = "hmn"
Locale["hmn"]["glotto"]            = "firs1234"
Locale["hmn"]["script"]            = "Latn"
Locale["hmn"]["spoken-in"]         = "China; Vietnam; Laos; Myanmar; Thailand"
Locale["hmn"]["supported-by"]      = "google; bing"
Locale["hu"]["name"]               = "Hungarian"
Locale["hu"]["endonym"]            = "Magyar"
Locale["hu"]["translations-of"]    = "%s fordításai"
Locale["hu"]["definitions-of"]     = "%s jelentései"
Locale["hu"]["synonyms"]           = "Szinonimák"
Locale["hu"]["examples"]           = "Példák"
Locale["hu"]["see-also"]           = "Lásd még"
Locale["hu"]["family"]             = "Uralic"
Locale["hu"]["branch"]             = "Ugric"
Locale["hu"]["iso"]                = "hun"
Locale["hu"]["glotto"]             = "hung1274"
Locale["hu"]["script"]             = "Latn"
Locale["hu"]["spoken-in"]          = "Hungary"
Locale["hu"]["supported-by"]       = "google; bing; yandex"
Locale["is"]["name"]               = "Icelandic"
Locale["is"]["endonym"]            = "Íslenska"
Locale["is"]["translations-of"]    = "Þýðingar á %s"
Locale["is"]["definitions-of"]     = "Skilgreiningar á"
Locale["is"]["synonyms"]           = "Samheiti"
Locale["is"]["examples"]           = "Dæmi"
Locale["is"]["see-also"]           = "Sjá einnig"
Locale["is"]["family"]             = "Indo-European"
Locale["is"]["branch"]             = "North Germanic"
Locale["is"]["iso"]                = "isl"
Locale["is"]["glotto"]             = "icel1247"
Locale["is"]["script"]             = "Latn"
Locale["is"]["spoken-in"]          = "Iceland"
Locale["is"]["supported-by"]       = "google; bing; yandex"
Locale["ig"]["name"]               = "Igbo"
Locale["ig"]["endonym"]            = "Igbo"
Locale["ig"]["translations-of"]    = "Ntụgharị asụsụ nke %s"
Locale["ig"]["definitions-of"]     = "Nkọwapụta nke %s"
Locale["ig"]["synonyms"]           = "Okwu oyiri"
Locale["ig"]["examples"]           = "Ọmụmaatụ"
Locale["ig"]["see-also"]           = "Hụkwuo"
Locale["ig"]["family"]             = "Atlantic-Congo"
Locale["ig"]["branch"]             = "Igboid"
Locale["ig"]["iso"]                = "ibo"
Locale["ig"]["glotto"]             = "nucl1417"
Locale["ig"]["script"]             = "Latn"
Locale["ig"]["spoken-in"]          = "southeastern Nigeria"
Locale["ig"]["supported-by"]       = "google"
Locale["ilo"]["name"]              = "Ilocano"
Locale["ilo"]["endonym"]           = "Ilokano"
Locale["ilo"]["family"]            = "Austronesian"
Locale["ilo"]["branch"]            = "Malayo-Polynesian"
Locale["ilo"]["iso"]               = "ilo"
Locale["ilo"]["glotto"]            = "ilok1237"
Locale["ilo"]["script"]            = "Latn"
Locale["ilo"]["spoken-in"]         = "the northern Philippines"
Locale["ilo"]["supported-by"]      = "google"
Locale["id"]["name"]               = "Indonesian"
Locale["id"]["endonym"]            = "Bahasa Indonesia"
Locale["id"]["translations-of"]    = "Terjemahan dari %s"
Locale["id"]["definitions-of"]     = "Definisi %s"
Locale["id"]["synonyms"]           = "Sinonim"
Locale["id"]["examples"]           = "Contoh"
Locale["id"]["see-also"]           = "Lihat juga"
Locale["id"]["family"]             = "Austronesian"
Locale["id"]["branch"]             = "Malayo-Polynesian"
Locale["id"]["iso"]                = "ind"
Locale["id"]["glotto"]             = "indo1316"
Locale["id"]["script"]             = "Latn"
Locale["id"]["spoken-in"]          = "Indonesia"
Locale["id"]["supported-by"]       = "google; bing; yandex"
Locale["ie"]["name"]               = "Interlingue"
Locale["ie"]["name2"]              = "Occidental"
Locale["ie"]["endonym"]            = "Interlingue"
Locale["ie"]["family"]             = "Constructed language"
Locale["ie"]["iso"]                = "ile"
Locale["ie"]["glotto"]             = "occi1241"
Locale["ie"]["script"]             = "Latn"
Locale["ie"]["spoken-in"]          = "worldwide"
Locale["ie"]["description"]        = "an international auxiliary language"
Locale["ie"]["supported-by"]       = ""
Locale["ikt"]["name"]              = "Inuinnaqtun"
Locale["ikt"]["endonym"]           = "Inuinnaqtun"
Locale["ikt"]["family"]            = "Eskimo-Aleut"
Locale["ikt"]["branch"]            = "Inuit"
Locale["ikt"]["iso"]               = "ikt"
Locale["ikt"]["glotto"]            = "copp1244"
Locale["ikt"]["script"]            = "Latn"
Locale["ikt"]["spoken-in"]         = "the Canadian Arctic"
Locale["ikt"]["supported-by"]      = "bing"
Locale["iu"]["name"]               = "Inuktitut"
Locale["iu"]["endonym"]            = "ᐃᓄᒃᑎᑐᑦ"
Locale["iu"]["family"]             = "Eskimo-Aleut"
Locale["iu"]["branch"]             = "Inuit"
Locale["iu"]["iso"]                = "iku"
Locale["iu"]["glotto"]             = "east2534"
Locale["iu"]["script"]             = "Cans"
Locale["iu"]["spoken-in"]          = "the Canadian Arctic"
Locale["iu"]["supported-by"]       = "bing"
Locale["iu-Latn"]["name"]          = "Inuktitut (Latin)"
Locale["iu-Latn"]["endonym"]       = "Inuktitut"
Locale["iu-Latn"]["family"]        = "Eskimo-Aleut"
Locale["iu-Latn"]["branch"]        = "Inuit"
Locale["iu-Latn"]["iso"]           = "iku"
Locale["iu-Latn"]["glotto"]        = "east2534"
Locale["iu-Latn"]["script"]        = "Latn"
Locale["iu-Latn"]["spoken-in"]     = "the Canadian Arctic"
Locale["iu-Latn"]["supported-by"]  = "bing"
Locale["ga"]["name"]               = "Irish"
Locale["ga"]["name2"]              = "Gaelic"
Locale["ga"]["endonym"]            = "Gaeilge"
Locale["ga"]["translations-of"]    = "Aistriúcháin ar %s"
Locale["ga"]["definitions-of"]     = "Sainmhínithe ar %s"
Locale["ga"]["synonyms"]           = "Comhchiallaigh"
Locale["ga"]["examples"]           = "Samplaí"
Locale["ga"]["see-also"]           = "féach freisin"
Locale["ga"]["family"]             = "Indo-European"
Locale["ga"]["branch"]             = "Celtic"
Locale["ga"]["iso"]                = "gle"
Locale["ga"]["glotto"]             = "iris1253"
Locale["ga"]["script"]             = "Latn"
Locale["ga"]["spoken-in"]          = "Ireland"
Locale["ga"]["supported-by"]       = "google; bing; yandex"
Locale["it"]["name"]               = "Italian"
Locale["it"]["endonym"]            = "Italiano"
Locale["it"]["translations-of"]    = "Traduzioni di %s"
Locale["it"]["definitions-of"]     = "Definizioni di %s"
Locale["it"]["synonyms"]           = "Sinonimi"
Locale["it"]["examples"]           = "Esempi"
Locale["it"]["see-also"]           = "Vedi anche"
Locale["it"]["family"]             = "Indo-European"
Locale["it"]["branch"]             = "Italo-Dalmatian"
Locale["it"]["iso"]                = "ita"
Locale["it"]["glotto"]             = "ital1282"
Locale["it"]["script"]             = "Latn"
Locale["it"]["dictionary"]         = "true"
Locale["it"]["spoken-in"]          = "Italy; Switzerland; San Marino; Vatican City"
Locale["it"]["supported-by"]       = "google; bing; yandex"
Locale["ja"]["name"]               = "Japanese"
Locale["ja"]["endonym"]            = "日本語"
Locale["ja"]["translations-of"]    = "「%s」の翻訳"
Locale["ja"]["definitions-of"]     = "%s の定義"
Locale["ja"]["synonyms"]           = "同義語"
Locale["ja"]["examples"]           = "例"
Locale["ja"]["see-also"]           = "関連項目"
Locale["ja"]["family"]             = "Japonic"
Locale["ja"]["iso"]                = "jpn"
Locale["ja"]["glotto"]             = "nucl1643"
Locale["ja"]["script"]             = "Jpan"
Locale["ja"]["dictionary"]         = "true"
Locale["ja"]["spoken-in"]          = "Japan"
Locale["ja"]["supported-by"]       = "google; bing; yandex"
Locale["jv"]["name"]               = "Javanese"
Locale["jv"]["endonym"]            = "Basa Jawa"
Locale["jv"]["translations-of"]    = "Terjemahan %s"
Locale["jv"]["definitions-of"]     = "Arti %s"
Locale["jv"]["synonyms"]           = "Sinonim"
Locale["jv"]["examples"]           = "Conto"
Locale["jv"]["see-also"]           = "Deleng uga"
Locale["jv"]["family"]             = "Austronesian"
Locale["jv"]["branch"]             = "Malayo-Polynesian"
Locale["jv"]["iso"]                = "jav"
Locale["jv"]["glotto"]             = "java1254"
Locale["jv"]["script"]             = "Latn"
Locale["jv"]["spoken-in"]          = "Java, Indonesia"
Locale["jv"]["supported-by"]       = "google; yandex"
Locale["kn"]["name"]               = "Kannada"
Locale["kn"]["endonym"]            = "ಕನ್ನಡ"
Locale["kn"]["translations-of"]    = "%s ನ ಅನುವಾದಗಳು"
Locale["kn"]["definitions-of"]     = "%s ನ ವ್ಯಾಖ್ಯಾನಗಳು"
Locale["kn"]["synonyms"]           = "ಸಮಾನಾರ್ಥಕಗಳು"
Locale["kn"]["examples"]           = "ಉದಾಹರಣೆಗಳು"
Locale["kn"]["see-also"]           = "ಇದನ್ನೂ ಗಮನಿಸಿ"
Locale["kn"]["family"]             = "Dravidian"
Locale["kn"]["branch"]             = "South Dravidian"
Locale["kn"]["iso"]                = "kan"
Locale["kn"]["glotto"]             = "nucl1305"
Locale["kn"]["script"]             = "Knda"
Locale["kn"]["spoken-in"]          = "the southwestern India"
Locale["kn"]["supported-by"]       = "google; bing; yandex"
Locale["kk"]["name"]               = "Kazakh"
Locale["kk"]["endonym"]            = "Қазақ тілі"
Locale["kk"]["translations-of"]    = "%s аудармалары"
Locale["kk"]["definitions-of"]     = "%s анықтамалары"
Locale["kk"]["synonyms"]           = "Синонимдер"
Locale["kk"]["examples"]           = "Мысалдар"
Locale["kk"]["see-also"]           = "Келесі тізімді де көріңіз:"
Locale["kk"]["family"]             = "Turkic"
Locale["kk"]["branch"]             = "Kipchak"
Locale["kk"]["iso"]                = "kaz"
Locale["kk"]["glotto"]             = "kaza1248"
Locale["kk"]["script"]             = "Cyrl"
Locale["kk"]["spoken-in"]          = "Kazakhstan; China; Mongolia; Russia; Kyrgyzstan; Uzbekistan"
Locale["kk"]["supported-by"]       = "google; bing; yandex"
Locale["km"]["name"]               = "Khmer"
Locale["km"]["endonym"]            = "ភាសាខ្មែរ"
Locale["km"]["translations-of"]    = "ការ​បក​ប្រែ​នៃ %s"
Locale["km"]["definitions-of"]     = "និយមន័យ​នៃ​ %s"
Locale["km"]["synonyms"]           = "សទិសន័យ"
Locale["km"]["examples"]           = "ឧទាហរណ៍"
Locale["km"]["see-also"]           = "មើល​ផង​ដែរ"
Locale["km"]["family"]             = "Austroasiatic"
Locale["km"]["branch"]             = "Khmeric"
Locale["km"]["iso"]                = "khm"
Locale["km"]["glotto"]             = "cent1989"
Locale["km"]["script"]             = "Khmr"
Locale["km"]["spoken-in"]          = "Cambodia; Thailand; Vietnam"
Locale["km"]["supported-by"]       = "google; bing; yandex"
Locale["rw"]["name"]               = "Kinyarwanda"
Locale["rw"]["endonym"]            = "Ikinyarwanda"
Locale["rw"]["family"]             = "Atlantic-Congo"
Locale["rw"]["branch"]             = "Bantu"
Locale["rw"]["iso"]                = "kin"
Locale["rw"]["glotto"]             = "kiny1244"
Locale["rw"]["script"]             = "Latn"
Locale["rw"]["spoken-in"]          = "Rwanda; Uganda; DR Congo; Tanzania"
Locale["rw"]["supported-by"]       = "google"
Locale["tlh-Latn"]["name"]         = "Klingon"
Locale["tlh-Latn"]["endonym"]      = "tlhIngan Hol"
Locale["tlh-Latn"]["family"]       = "Constructed language"
Locale["tlh-Latn"]["iso"]          = "tlh-Latn"
Locale["tlh-Latn"]["glotto"]       = "klin1234"
Locale["tlh-Latn"]["script"]       = "Latn"
Locale["tlh-Latn"]["spoken-in"]    = "the Star Trek universe"
Locale["tlh-Latn"]["description"]  = "a fictional language spoken by the Klingons in the Star Trek universe"
Locale["tlh-Latn"]["supported-by"] = "bing"
Locale["gom"]["name"]              = "Konkani"
Locale["gom"]["endonym"]           = "कोंकणी"
Locale["gom"]["family"]            = "Indo-European"
Locale["gom"]["branch"]            = "Indo-Aryan"
Locale["gom"]["iso"]               = "gom"
Locale["gom"]["glotto"]            = "goan1235"
Locale["gom"]["script"]            = "Deva"
Locale["gom"]["spoken-in"]         = "the western coastal region of India"
Locale["gom"]["supported-by"]      = "google"
Locale["ko"]["name"]               = "Korean"
Locale["ko"]["endonym"]            = "한국어"
Locale["ko"]["translations-of"]    = "%s의 번역"
Locale["ko"]["definitions-of"]     = "%s의 정의"
Locale["ko"]["synonyms"]           = "동의어"
Locale["ko"]["examples"]           = "예문"
Locale["ko"]["see-also"]           = "참조"
Locale["ko"]["family"]             = "Koreanic"
Locale["ko"]["iso"]                = "kor"
Locale["ko"]["glotto"]             = "kore1280"
Locale["ko"]["script"]             = "Kore"
Locale["ko"]["dictionary"]         = "true"
Locale["ko"]["spoken-in"]          = "South Korea; North Korea; China"
Locale["ko"]["supported-by"]       = "google; bing; yandex"
Locale["kri"]["name"]              = "Krio"
Locale["kri"]["endonym"]           = "Krio"
Locale["kri"]["family"]            = "Indo-European"
Locale["kri"]["branch"]            = "English Creole"
Locale["kri"]["iso"]               = "kri"
Locale["kri"]["glotto"]            = "krio1253"
Locale["kri"]["script"]            = "Latn"
Locale["kri"]["spoken-in"]         = "Sierra Leone"
Locale["kri"]["supported-by"]      = "google"
Locale["ku"]["name"]               = "Kurdish (Northern)"
Locale["ku"]["name2"]              = "Kurmanji"
Locale["ku"]["endonym"]            = "Kurmancî"
Locale["ku"]["endonym2"]           = "Kurdî"
Locale["ku"]["family"]             = "Indo-European"
Locale["ku"]["branch"]             = "Iranian"
Locale["ku"]["iso"]                = "kmr"
Locale["ku"]["glotto"]             = "nort2641"
Locale["ku"]["script"]             = "Latn"
Locale["ku"]["spoken-in"]          = "southeast Turkey; northwest and northeast Iran; northern Iraq; northern Syria; the Caucasus and Khorasan regions"
Locale["ku"]["supported-by"]       = "google"
Locale["ckb"]["name"]              = "Kurdish (Central)"
Locale["ckb"]["name2"]             = "Sorani"
Locale["ckb"]["endonym"]           = "سۆرانی"
Locale["ckb"]["endonym2"]          = "کوردیی ناوەندی"
Locale["ckb"]["family"]            = "Indo-European"
Locale["ckb"]["branch"]            = "Iranian"
Locale["ckb"]["iso"]               = "ckb"
Locale["ckb"]["glotto"]            = "cent1972"
Locale["ckb"]["script"]            = "Arab"
Locale["ckb"]["rtl"]               = "true"
Locale["ckb"]["spoken-in"]         = "Iraqi Kurdistan; western Iran"
Locale["ckb"]["supported-by"]      = "google"
Locale["ky"]["name"]               = "Kyrgyz"
Locale["ky"]["endonym"]            = "Кыргызча"
Locale["ky"]["translations-of"]    = "%s котормосу"
Locale["ky"]["definitions-of"]     = "%s аныктамасы"
Locale["ky"]["synonyms"]           = "Синонимдер"
Locale["ky"]["examples"]           = "Мисалдар"
Locale["ky"]["see-also"]           = "Дагы караңыз"
Locale["ky"]["family"]             = "Turkic"
Locale["ky"]["branch"]             = "Kipchak"
Locale["ky"]["iso"]                = "kir"
Locale["ky"]["glotto"]             = "kirg1245"
Locale["ky"]["script"]             = "Cyrl"
Locale["ky"]["spoken-in"]          = "Kyrgyzstan; China; Tajikistan; Afghanistan; Pakistan"
Locale["ky"]["supported-by"]       = "google; bing; yandex"
Locale["lo"]["name"]               = "Lao"
Locale["lo"]["endonym"]            = "ລາວ"
Locale["lo"]["translations-of"]    = "ຄຳ​ແປ​ສຳລັບ %s"
Locale["lo"]["definitions-of"]     = "ຄວາມໝາຍຂອງ %s"
Locale["lo"]["synonyms"]           = "ຄຳທີ່ຄ້າຍກັນ %s"
Locale["lo"]["examples"]           = "ຕົວຢ່າງ"
Locale["lo"]["see-also"]           = "ເບິ່ງ​ເພີ່ມ​ເຕີມ"
Locale["lo"]["family"]             = "Kra-Dai"
Locale["lo"]["branch"]             = "Tai"
Locale["lo"]["iso"]                = "lao"
Locale["lo"]["glotto"]             = "laoo1244"
Locale["lo"]["script"]             = "Laoo"
Locale["lo"]["spoken-in"]          = "Laos; Thailand; Cambodia"
Locale["lo"]["supported-by"]       = "google; bing; yandex"
Locale["la"]["name"]               = "Latin"
Locale["la"]["endonym"]            = "Latina"
Locale["la"]["translations-of"]    = "Versio de %s"
Locale["la"]["family"]             = "Indo-European"
Locale["la"]["branch"]             = "Latino-Faliscan"
Locale["la"]["iso"]                = "lat"
Locale["la"]["glotto"]             = "lati1261"
Locale["la"]["script"]             = "Latn"
Locale["la"]["spoken-in"]          = "ancient Rome"
Locale["la"]["supported-by"]       = "google; yandex"
Locale["lv"]["name"]               = "Latvian"
Locale["lv"]["endonym"]            = "Latviešu"
Locale["lv"]["translations-of"]    = "%s tulkojumi"
Locale["lv"]["definitions-of"]     = "%s definīcijas"
Locale["lv"]["synonyms"]           = "Sinonīmi"
Locale["lv"]["examples"]           = "Piemēri"
Locale["lv"]["see-also"]           = "Skatiet arī"
Locale["lv"]["family"]             = "Indo-European"
Locale["lv"]["branch"]             = "Eastern Baltic"
Locale["lv"]["iso"]                = "lav"
Locale["lv"]["glotto"]             = "latv1249"
Locale["lv"]["script"]             = "Latn"
Locale["lv"]["spoken-in"]          = "Latvia"
Locale["lv"]["supported-by"]       = "google; bing; yandex"
Locale["ln"]["name"]               = "Lingala"
Locale["ln"]["endonym"]            = "Lingála"
Locale["ln"]["family"]             = "Atlantic-Congo"
Locale["ln"]["branch"]             = "Bantu"
Locale["ln"]["iso"]                = "lin"
Locale["ln"]["glotto"]             = "ling1269"
Locale["ln"]["script"]             = "Latn"
Locale["ln"]["spoken-in"]          = "DR Congo; Republic of the Congo; Angola; Central African Republic; southern South Sudan"
Locale["ln"]["supported-by"]       = "google"
Locale["lt"]["name"]               = "Lithuanian"
Locale["lt"]["endonym"]            = "Lietuvių"
Locale["lt"]["translations-of"]    = "„%s“ vertimai"
Locale["lt"]["definitions-of"]     = "„%s“ apibrėžimai"
Locale["lt"]["synonyms"]           = "Sinonimai"
Locale["lt"]["examples"]           = "Pavyzdžiai"
Locale["lt"]["see-also"]           = "Taip pat žiūrėkite"
Locale["lt"]["family"]             = "Indo-European"
Locale["lt"]["branch"]             = "Eastern Baltic"
Locale["lt"]["iso"]                = "lit"
Locale["lt"]["glotto"]             = "lith1251"
Locale["lt"]["script"]             = "Latn"
Locale["lt"]["spoken-in"]          = "Lithuania"
Locale["lt"]["supported-by"]       = "google; bing; yandex"
Locale["lg"]["name"]               = "Luganda"
Locale["lg"]["endonym"]            = "Luganda"
Locale["lg"]["endonym2"]           = "Oluganda"
Locale["lg"]["family"]             = "Atlantic-Congo"
Locale["lg"]["branch"]             = "Bantu"
Locale["lg"]["iso"]                = "lug"
Locale["lg"]["glotto"]             = "gand1255"
Locale["lg"]["script"]             = "Latn"
Locale["lg"]["spoken-in"]          = "Uganda; Rwanda"
Locale["lg"]["supported-by"]       = "google"
Locale["lb"]["name"]               = "Luxembourgish"
Locale["lb"]["endonym"]            = "Lëtzebuergesch"
Locale["lb"]["family"]             = "Indo-European"
Locale["lb"]["branch"]             = "West Germanic"
Locale["lb"]["iso"]                = "ltz"
Locale["lb"]["glotto"]             = "luxe1241"
Locale["lb"]["script"]             = "Latn"
Locale["lb"]["spoken-in"]          = "Luxembourg"
Locale["lb"]["supported-by"]       = "google; yandex"
Locale["mk"]["name"]               = "Macedonian"
Locale["mk"]["endonym"]            = "Македонски"
Locale["mk"]["translations-of"]    = "Преводи на %s"
Locale["mk"]["definitions-of"]     = "Дефиниции на %s"
Locale["mk"]["synonyms"]           = "Синоними"
Locale["mk"]["examples"]           = "Примери"
Locale["mk"]["see-also"]           = "Види и"
Locale["mk"]["family"]             = "Indo-European"
Locale["mk"]["branch"]             = "South Slavic"
Locale["mk"]["iso"]                = "mkd"
Locale["mk"]["glotto"]             = "mace1250"
Locale["mk"]["script"]             = "Cyrl"
Locale["mk"]["spoken-in"]          = "North Macedonia; Albania; Bosnia and Herzegovina; Romania; Serbia"
Locale["mk"]["supported-by"]       = "google; bing; yandex"
Locale["mai"]["name"]              = "Maithili"
Locale["mai"]["endonym"]           = "मैथिली"
Locale["mai"]["family"]            = "Indo-European"
Locale["mai"]["branch"]            = "Indo-Aryan"
Locale["mai"]["iso"]               = "mai"
Locale["mai"]["glotto"]            = "mait1250"
Locale["mai"]["script"]            = "Deva"
Locale["mai"]["spoken-in"]         = "the Mithila region in India and Nepal"
Locale["mai"]["supported-by"]      = "google"
Locale["mg"]["name"]               = "Malagasy"
Locale["mg"]["endonym"]            = "Malagasy"
Locale["mg"]["translations-of"]    = "Dikan'ny %s"
Locale["mg"]["definitions-of"]     = "Famaritana ny %s"
Locale["mg"]["synonyms"]           = "Mitovy hevitra"
Locale["mg"]["examples"]           = "Ohatra"
Locale["mg"]["see-also"]           = "Jereo ihany koa"
Locale["mg"]["family"]             = "Austronesian"
Locale["mg"]["branch"]             = "Malayo-Polynesian"
Locale["mg"]["iso"]                = "mlg"
Locale["mg"]["glotto"]             = "plat1254"
Locale["mg"]["script"]             = "Latn"
Locale["mg"]["spoken-in"]          = "Madagascar; the Comoros; Mayotte"
Locale["mg"]["supported-by"]       = "google; bing; yandex"
Locale["ms"]["name"]               = "Malay"
Locale["ms"]["endonym"]            = "Bahasa Melayu"
Locale["ms"]["translations-of"]    = "Terjemahan %s"
Locale["ms"]["definitions-of"]     = "Takrif %s"
Locale["ms"]["synonyms"]           = "Sinonim"
Locale["ms"]["examples"]           = "Contoh"
Locale["ms"]["see-also"]           = "Lihat juga"
Locale["ms"]["family"]             = "Austronesian"
Locale["ms"]["branch"]             = "Malayo-Polynesian"
Locale["ms"]["iso"]                = "msa"
Locale["ms"]["glotto"]             = "stan1306"
Locale["ms"]["script"]             = "Latn"
Locale["ms"]["spoken-in"]          = "Malaysia; Singapore; Indonesia; Brunei; East Timor"
Locale["ms"]["supported-by"]       = "google; bing; yandex"
Locale["ml"]["name"]               = "Malayalam"
Locale["ml"]["endonym"]            = "മലയാളം"
Locale["ml"]["translations-of"]    = "%s എന്നതിന്റെ വിവർത്തനങ്ങൾ"
Locale["ml"]["definitions-of"]     = "%s എന്നതിന്റെ നിർവ്വചനങ്ങൾ"
Locale["ml"]["synonyms"]           = "പര്യായങ്ങള്‍"
Locale["ml"]["examples"]           = "ഉദാഹരണങ്ങള്‍"
Locale["ml"]["see-also"]           = "ഇതും കാണുക"
Locale["ml"]["family"]             = "Dravidian"
Locale["ml"]["branch"]             = "South Dravidian"
Locale["ml"]["iso"]                = "mal"
Locale["ml"]["glotto"]             = "mala1464"
Locale["ml"]["script"]             = "Mlym"
Locale["ml"]["spoken-in"]          = "Kerala, Lakshadweep and Puducherry in India"
Locale["ml"]["supported-by"]       = "google; bing; yandex"
Locale["mt"]["name"]               = "Maltese"
Locale["mt"]["endonym"]            = "Malti"
Locale["mt"]["translations-of"]    = "Traduzzjonijiet ta' %s"
Locale["mt"]["definitions-of"]     = "Definizzjonijiet ta' %s"
Locale["mt"]["synonyms"]           = "Sinonimi"
Locale["mt"]["examples"]           = "Eżempji"
Locale["mt"]["see-also"]           = "Ara wkoll"
Locale["mt"]["family"]             = "Afro-Asiatic"
Locale["mt"]["branch"]             = "Semitic"
Locale["mt"]["iso"]                = "mlt"
Locale["mt"]["glotto"]             = "malt1254"
Locale["mt"]["script"]             = "Latn"
Locale["mt"]["spoken-in"]          = "Malta"
Locale["mt"]["supported-by"]       = "google; bing; yandex"
Locale["mi"]["name"]               = "Maori"
Locale["mi"]["endonym"]            = "Māori"
Locale["mi"]["translations-of"]    = "Ngā whakamāoritanga o %s"
Locale["mi"]["definitions-of"]     = "Ngā whakamārama o %s"
Locale["mi"]["synonyms"]           = "Ngā Kupu Taurite"
Locale["mi"]["examples"]           = "Ngā Tauira:"
Locale["mi"]["see-also"]           = "Tiro hoki:"
Locale["mi"]["family"]             = "Austronesian"
Locale["mi"]["branch"]             = "Malayo-Polynesian"
Locale["mi"]["iso"]                = "mri"
Locale["mi"]["glotto"]             = "maor1246"
Locale["mi"]["script"]             = "Latn"
Locale["mi"]["spoken-in"]          = "New Zealand"
Locale["mi"]["supported-by"]       = "google; bing; yandex"
Locale["mr"]["name"]               = "Marathi"
Locale["mr"]["endonym"]            = "मराठी"
Locale["mr"]["translations-of"]    = "%s ची भाषांतरे"
Locale["mr"]["definitions-of"]     = "%s च्या व्याख्या"
Locale["mr"]["synonyms"]           = "समानार्थी शब्द"
Locale["mr"]["examples"]           = "उदाहरणे"
Locale["mr"]["see-also"]           = "हे देखील पहा"
Locale["mr"]["family"]             = "Indo-European"
Locale["mr"]["branch"]             = "Indo-Aryan"
Locale["mr"]["iso"]                = "mar"
Locale["mr"]["glotto"]             = "mara1378"
Locale["mr"]["script"]             = "Deva"
Locale["mr"]["spoken-in"]          = "the Indian state of Maharashtra"
Locale["mr"]["supported-by"]       = "google; bing; yandex"
Locale["mhr"]["name"]              = "Eastern Mari"
Locale["mhr"]["name2"]             = "Meadow Mari"
Locale["mhr"]["endonym"]           = "Олык марий"
Locale["mhr"]["family"]            = "Uralic"
Locale["mhr"]["branch"]            = "Mari"
Locale["mhr"]["iso"]               = "mhr"
Locale["mhr"]["glotto"]            = "east2328"
Locale["mhr"]["script"]            = "Cyrl"
Locale["mhr"]["spoken-in"]         = "Mari El, Russia"
Locale["mhr"]["supported-by"]      = "yandex"
Locale["mni-Mtei"]["name"]         = "Meiteilon"
Locale["mni-Mtei"]["name2"]        = "Manipuri"
Locale["mni-Mtei"]["name3"]        = "Meitei"
Locale["mni-Mtei"]["name4"]        = "Meetei"
Locale["mni-Mtei"]["endonym"]      = "ꯃꯤꯇꯩꯂꯣꯟ"
Locale["mni-Mtei"]["family"]       = "Sino-Tibetan"
Locale["mni-Mtei"]["branch"]       = "Tibeto-Burman"
Locale["mni-Mtei"]["iso"]          = "mni"
Locale["mni-Mtei"]["glotto"]       = "mani1292"
Locale["mni-Mtei"]["script"]       = "Mtei"
Locale["mni-Mtei"]["spoken-in"]    = "the northeastern India; Bangladesh; Myanmar"
Locale["mni-Mtei"]["supported-by"] = "google"
Locale["lus"]["name"]              = "Mizo"
Locale["lus"]["endonym"]           = "Mizo ṭawng"
Locale["lus"]["family"]            = "Sino-Tibetan"
Locale["lus"]["branch"]            = "Tibeto-Burman"
Locale["lus"]["iso"]               = "lus"
Locale["lus"]["glotto"]            = "lush1249"
Locale["lus"]["script"]            = "Latn"
Locale["lus"]["spoken-in"]         = "the Indian state of Mizoram"
Locale["lus"]["supported-by"]      = "google"
Locale["mn"]["name"]               = "Mongolian"
Locale["mn"]["endonym"]            = "Монгол"
Locale["mn"]["translations-of"]    = "%s-н орчуулга"
Locale["mn"]["definitions-of"]     = "%s үгийн тодорхойлолт"
Locale["mn"]["synonyms"]           = "Ойролцоо утгатай"
Locale["mn"]["examples"]           = "Жишээнүүд"
Locale["mn"]["see-also"]           = "Мөн харах"
Locale["mn"]["family"]             = "Mongolic"
Locale["mn"]["iso"]                = "mon"
Locale["mn"]["glotto"]             = "mong1331"
Locale["mn"]["script"]             = "Cyrl"
Locale["mn"]["spoken-in"]          = "Mongolia; Inner Mongolia in China"
Locale["mn"]["supported-by"]       = "google; bing; yandex"
Locale["mn-Mong"]["name"]          = "Mongolian (Traditional)"
Locale["mn-Mong"]["endonym"]       = "ᠮᠣᠩᠭᠣᠯ"
Locale["mn-Mong"]["family"]        = "Mongolic"
Locale["mn-Mong"]["iso"]           = "mon-Mong"
Locale["mn-Mong"]["glotto"]        = "mong1331"
Locale["mn-Mong"]["script"]        = "Mong"
Locale["mn-Mong"]["spoken-in"]     = "Mongolia; Inner Mongolia in China"
Locale["mn-Mong"]["supported-by"]  = "bing"
Locale["my"]["name"]               = "Myanmar"
Locale["my"]["name2"]              = "Burmese"
Locale["my"]["endonym"]            = "မြန်မာစာ"
Locale["my"]["translations-of"]    = "%s၏ ဘာသာပြန်ဆိုချက်များ"
Locale["my"]["definitions-of"]     = "%s၏ အနက်ဖွင့်ဆိုချက်များ"
Locale["my"]["synonyms"]           = "ကြောင်းတူသံကွဲများ"
Locale["my"]["examples"]           = "ဥပမာ"
Locale["my"]["see-also"]           = "ဖော်ပြပါများကိုလဲ ကြည့်ပါ"
Locale["my"]["family"]             = "Sino-Tibetan"
Locale["my"]["branch"]             = "Tibeto-Burman"
Locale["my"]["iso"]                = "mya"
Locale["my"]["glotto"]             = "nucl1310"
Locale["my"]["script"]             = "Mymr"
Locale["my"]["spoken-in"]          = "Myanmar"
Locale["my"]["supported-by"]       = "google; bing; yandex"
Locale["ne"]["name"]               = "Nepali"
Locale["ne"]["endonym"]            = "नेपाली"
Locale["ne"]["translations-of"]    = "%sका अनुवाद"
Locale["ne"]["definitions-of"]     = "%sको परिभाषा"
Locale["ne"]["synonyms"]           = "समानार्थीहरू"
Locale["ne"]["examples"]           = "उदाहरणहरु"
Locale["ne"]["see-also"]           = "यो पनि हेर्नुहोस्"
Locale["ne"]["family"]             = "Indo-European"
Locale["ne"]["branch"]             = "Indo-Aryan"
Locale["ne"]["iso"]                = "nep"
Locale["ne"]["glotto"]             = "nepa1254"
Locale["ne"]["script"]             = "Deva"
Locale["ne"]["spoken-in"]          = "Nepal; India"
Locale["ne"]["supported-by"]       = "google; bing; yandex"
Locale["no"]["name"]               = "Norwegian"
Locale["no"]["endonym"]            = "Norsk"
Locale["no"]["translations-of"]    = "Oversettelser av %s"
Locale["no"]["definitions-of"]     = "Definisjoner av %s"
Locale["no"]["synonyms"]           = "Synonymer"
Locale["no"]["examples"]           = "Eksempler"
Locale["no"]["see-also"]           = "Se også"
Locale["no"]["family"]             = "Indo-European"
Locale["no"]["branch"]             = "North Germanic"
Locale["no"]["iso"]                = "nor"
Locale["no"]["glotto"]             = "norw1258"
Locale["no"]["script"]             = "Latn"
Locale["no"]["spoken-in"]          = "Norway"
Locale["no"]["supported-by"]       = "google; bing; yandex"
Locale["oc"]["name"]               = "Occitan"
Locale["oc"]["endonym"]            = "Occitan"
Locale["oc"]["family"]             = "Indo-European"
Locale["oc"]["branch"]             = "Western Romance"
Locale["oc"]["iso"]                = "oci"
Locale["oc"]["glotto"]             = "occi1239"
Locale["oc"]["script"]             = "Latn"
Locale["oc"]["spoken-in"]          = "Occitania in France, Monaco, Italy and Spain"
Locale["oc"]["supported-by"]       = ""
Locale["or"]["name"]               = "Odia"
Locale["or"]["name2"]              = "Oriya"
Locale["or"]["endonym"]            = "ଓଡ଼ିଆ"
Locale["or"]["family"]             = "Indo-European"
Locale["or"]["branch"]             = "Indo-Aryan"
Locale["or"]["iso"]                = "ori"
Locale["or"]["glotto"]             = "macr1269"
Locale["or"]["script"]             = "Orya"
Locale["or"]["spoken-in"]          = "the Indian state of Odisha"
Locale["or"]["supported-by"]       = "google; bing"
Locale["om"]["name"]               = "Oromo"
Locale["om"]["endonym"]            = "Afaan Oromoo"
Locale["om"]["family"]             = "Afro-Asiatic"
Locale["om"]["branch"]             = "Cushitic"
Locale["om"]["iso"]                = "orm"
Locale["om"]["glotto"]             = "nucl1736"
Locale["om"]["script"]             = "Latn"
Locale["om"]["spoken-in"]          = "the Ethiopian state of Oromia; northeastern Kenya"
Locale["om"]["supported-by"]       = "google"
Locale["pap"]["name"]              = "Papiamento"
Locale["pap"]["endonym"]           = "Papiamentu"
Locale["pap"]["family"]            = "Indo-European"
Locale["pap"]["branch"]            = "Portuguese Creole"
Locale["pap"]["iso"]               = "pap"
Locale["pap"]["glotto"]            = "papi1253"
Locale["pap"]["script"]            = "Latn"
Locale["pap"]["spoken-in"]         = "the Dutch Caribbean"
Locale["pap"]["supported-by"]      = "yandex"
Locale["ps"]["name"]               = "Pashto"
Locale["ps"]["name2"]              = "Pushto"
Locale["ps"]["endonym"]            = "پښتو"
Locale["ps"]["translations-of"]    = "د %sژباړې"
Locale["ps"]["definitions-of"]     = "د%s تعریفونه"
Locale["ps"]["synonyms"]           = "مترادف لغتونه"
Locale["ps"]["examples"]           = "بېلګې"
Locale["ps"]["see-also"]           = "دا هم ووینئ"
Locale["ps"]["family"]             = "Indo-European"
Locale["ps"]["branch"]             = "Iranian"
Locale["ps"]["iso"]                = "pus"
Locale["ps"]["glotto"]             = "pash1269"
Locale["ps"]["script"]             = "Arab"
Locale["ps"]["rtl"]                = "true"
Locale["ps"]["spoken-in"]          = "Afghanistan; Pakistan"
Locale["ps"]["supported-by"]       = "google; bing"
Locale["fa"]["name"]               = "Persian"
Locale["fa"]["name2"]              = "Farsi"
Locale["fa"]["endonym"]            = "فارسی"
Locale["fa"]["translations-of"]    = "ترجمه‌های %s"
Locale["fa"]["definitions-of"]     = "تعریف‌های %s"
Locale["fa"]["synonyms"]           = "مترادف‌ها"
Locale["fa"]["examples"]           = "مثال‌ها"
Locale["fa"]["see-also"]           = "همچنین مراجعه کنید به"
Locale["fa"]["family"]             = "Indo-European"
Locale["fa"]["branch"]             = "Iranian"
Locale["fa"]["iso"]                = "fas"
Locale["fa"]["glotto"]             = "west2369"
Locale["fa"]["script"]             = "Arab"
Locale["fa"]["rtl"]                = "true"
Locale["fa"]["spoken-in"]          = "Iran"
Locale["fa"]["supported-by"]       = "google; bing; yandex"
Locale["pl"]["name"]               = "Polish"
Locale["pl"]["endonym"]            = "Polski"
Locale["pl"]["translations-of"]    = "Tłumaczenia %s"
Locale["pl"]["definitions-of"]     = "%s – definicje"
Locale["pl"]["synonyms"]           = "Synonimy"
Locale["pl"]["examples"]           = "Przykłady"
Locale["pl"]["see-also"]           = "Zobacz też"
Locale["pl"]["family"]             = "Indo-European"
Locale["pl"]["branch"]             = "West Slavic"
Locale["pl"]["iso"]                = "pol"
Locale["pl"]["glotto"]             = "poli1260"
Locale["pl"]["script"]             = "Latn"
Locale["pl"]["spoken-in"]          = "Poland"
Locale["pl"]["supported-by"]       = "google; bing; yandex"
Locale["pt-BR"]["name"]            = "Portuguese (Brazilian)"
Locale["pt-BR"]["endonym"]         = "Português Brasileiro"
Locale["pt-BR"]["translations-of"] = "Traduções de %s"
Locale["pt-BR"]["definitions-of"]  = "Definições de %s"
Locale["pt-BR"]["synonyms"]        = "Sinônimos"
Locale["pt-BR"]["examples"]        = "Exemplos"
Locale["pt-BR"]["see-also"]        = "Veja também"
Locale["pt-BR"]["family"]          = "Indo-European"
Locale["pt-BR"]["branch"]          = "Western Romance"
Locale["pt-BR"]["iso"]             = "por"
Locale["pt-BR"]["glotto"]          = "braz1246"
Locale["pt-BR"]["script"]          = "Latn"
Locale["pt-BR"]["dictionary"]      = "true"
Locale["pt-BR"]["spoken-in"]       = "Portugal; Brazil; Cape Verde; Angola; Mozambique; Guinea-Bissau; Equatorial Guinea; São Tomé and Príncipe; East Timor; Macau"
Locale["pt-BR"]["supported-by"]    = "google; bing; yandex"
Locale["pt-PT"]["name"]            = "Portuguese (European)"
Locale["pt-PT"]["endonym"]         = "Português Europeu"
Locale["pt-PT"]["translations-of"] = "Traduções de %s"
Locale["pt-PT"]["definitions-of"]  = "Definições de %s"
Locale["pt-PT"]["synonyms"]        = "Sinônimos"
Locale["pt-PT"]["examples"]        = "Exemplos"
Locale["pt-PT"]["see-also"]        = "Veja também"
Locale["pt-PT"]["family"]          = "Indo-European"
Locale["pt-PT"]["branch"]          = "Western Romance"
Locale["pt-PT"]["iso"]             = "por"
Locale["pt-PT"]["glotto"]          = "port1283"
Locale["pt-PT"]["script"]          = "Latn"
Locale["pt-PT"]["spoken-in"]       = "Portugal; Brazil; Cape Verde; Angola; Mozambique; Guinea-Bissau; Equatorial Guinea; São Tomé and Príncipe; East Timor; Macau"
Locale["pt-PT"]["supported-by"]    = "bing"
Locale["pa"]["name"]               = "Punjabi"
Locale["pa"]["endonym"]            = "ਪੰਜਾਬੀ"
Locale["pa"]["translations-of"]    = "ਦੇ ਅਨੁਵਾਦ%s"
Locale["pa"]["definitions-of"]     = "ਦੀਆਂ ਪਰਿਭਾਸ਼ਾ %s"
Locale["pa"]["synonyms"]           = "ਸਮਾਨਾਰਥਕ ਸ਼ਬਦ"
Locale["pa"]["examples"]           = "ਉਦਾਹਰਣਾਂ"
Locale["pa"]["see-also"]           = "ਇਹ ਵੀ ਵੇਖੋ"
Locale["pa"]["family"]             = "Indo-European"
Locale["pa"]["branch"]             = "Indo-Aryan"
Locale["pa"]["iso"]                = "pan"
Locale["pa"]["glotto"]             = "panj1256"
Locale["pa"]["script"]             = "Guru"
Locale["pa"]["spoken-in"]          = "the Punjab region of India and Pakistan"
Locale["pa"]["supported-by"]       = "google; bing; yandex"
Locale["qu"]["name"]               = "Quechua"
Locale["qu"]["endonym"]            = "Runasimi"
Locale["qu"]["family"]             = "Quechuan"
Locale["qu"]["iso"]                = "que"
Locale["qu"]["glotto"]             = "quec1387"
Locale["qu"]["script"]             = "Latn"
Locale["qu"]["spoken-in"]          = "Peru; Bolivia; Ecuador; surrounding countries"
Locale["qu"]["supported-by"]       = "google"
Locale["otq"]["name"]              = "Querétaro Otomi"
Locale["otq"]["endonym"]           = "Hñąñho"
Locale["otq"]["family"]            = "Oto-Manguean"
Locale["otq"]["iso"]               = "otq"
Locale["otq"]["glotto"]            = "quer1236"
Locale["otq"]["script"]            = "Latn"
Locale["otq"]["spoken-in"]         = "Querétaro in Mexico"
Locale["otq"]["supported-by"]      = "bing"
Locale["ro"]["name"]               = "Romanian"
Locale["ro"]["endonym"]            = "Română"
Locale["ro"]["translations-of"]    = "Traduceri pentru %s"
Locale["ro"]["definitions-of"]     = "Definiții pentru %s"
Locale["ro"]["synonyms"]           = "Sinonime"
Locale["ro"]["examples"]           = "Exemple"
Locale["ro"]["see-also"]           = "Vedeți și"
Locale["ro"]["family"]             = "Indo-European"
Locale["ro"]["branch"]             = "Eastern Romance"
Locale["ro"]["iso"]                = "ron"
Locale["ro"]["glotto"]             = "roma1327"
Locale["ro"]["script"]             = "Latn"
Locale["ro"]["spoken-in"]          = "Romania; Moldova"
Locale["ro"]["supported-by"]       = "google; bing; yandex"
Locale["rm"]["name"]               = "Romansh"
Locale["rm"]["endonym"]            = "Rumantsch"
Locale["rm"]["family"]             = "Indo-European"
Locale["rm"]["branch"]             = "Western Romance"
Locale["rm"]["iso"]                = "roh"
Locale["rm"]["glotto"]             = "roma1326"
Locale["rm"]["script"]             = "Latn"
Locale["rm"]["spoken-in"]          = "the Swiss canton of the Grisons"
Locale["rm"]["supported-by"]       = ""
Locale["ru"]["name"]               = "Russian"
Locale["ru"]["endonym"]            = "Русский"
Locale["ru"]["translations-of"]    = "%s: варианты перевода"
Locale["ru"]["definitions-of"]     = "%s – определения"
Locale["ru"]["synonyms"]           = "Синонимы"
Locale["ru"]["examples"]           = "Примеры"
Locale["ru"]["see-also"]           = "Похожие слова"
Locale["ru"]["family"]             = "Indo-European"
Locale["ru"]["branch"]             = "East Slavic"
Locale["ru"]["iso"]                = "rus"
Locale["ru"]["glotto"]             = "russ1263"
Locale["ru"]["script"]             = "Cyrl"
Locale["ru"]["dictionary"]         = "true"
Locale["ru"]["spoken-in"]          = "the Russian-speaking world"
Locale["ru"]["supported-by"]       = "google; bing; yandex"
Locale["sm"]["name"]               = "Samoan"
Locale["sm"]["endonym"]            = "Gagana Sāmoa"
Locale["sm"]["family"]             = "Austronesian"
Locale["sm"]["branch"]             = "Malayo-Polynesian"
Locale["sm"]["iso"]                = "smo"
Locale["sm"]["glotto"]             = "samo1305"
Locale["sm"]["script"]             = "Latn"
Locale["sm"]["spoken-in"]          = "the Samoan Islands"
Locale["sm"]["supported-by"]       = "google; bing"
Locale["sa"]["name"]               = "Sanskrit"
Locale["sa"]["endonym"]            = "संस्कृतम्"
Locale["sa"]["family"]             = "Indo-European"
Locale["sa"]["branch"]             = "Indo-Aryan"
Locale["sa"]["iso"]                = "san"
Locale["sa"]["glotto"]             = "sans1269"
Locale["sa"]["script"]             = "Deva"
Locale["sa"]["spoken-in"]          = "ancient India"
Locale["sa"]["supported-by"]       = "google"
Locale["gd"]["name"]               = "Scots Gaelic"
Locale["gd"]["endonym"]            = "Gàidhlig"
Locale["gd"]["translations-of"]    = "Eadar-theangachadh airson %s"
Locale["gd"]["definitions-of"]     = "Deifiniseanan airson %s"
Locale["gd"]["synonyms"]           = "Co-fhaclan"
Locale["gd"]["examples"]           = "Buill-eisimpleir"
Locale["gd"]["see-also"]           = "Faic na leanas cuideachd"
Locale["gd"]["family"]             = "Indo-European"
Locale["gd"]["branch"]             = "Celtic"
Locale["gd"]["iso"]                = "gla"
Locale["gd"]["glotto"]             = "scot1245"
Locale["gd"]["script"]             = "Latn"
Locale["gd"]["spoken-in"]          = "Scotland"
Locale["gd"]["supported-by"]       = "google; yandex"
Locale["nso"]["name"]              = "Sepedi"
Locale["nso"]["name2"]             = "Pedi"
Locale["nso"]["name3"]             = "Northern Sotho"
Locale["nso"]["endonym"]           = "Sepedi"
Locale["nso"]["family"]            = "Atlantic-Congo"
Locale["nso"]["branch"]            = "Bantu"
Locale["nso"]["iso"]               = "nso"
Locale["nso"]["glotto"]            = "nort3233"
Locale["nso"]["script"]            = "Latn"
Locale["nso"]["spoken-in"]         = "the northeastern provinces of South Africa"
Locale["nso"]["supported-by"]      = "google"
Locale["sr-Cyrl"]["name"]          = "Serbian (Cyrillic)"
Locale["sr-Cyrl"]["endonym"]       = "Српски"
Locale["sr-Cyrl"]["translations-of"] = "Преводи за „%s“"
Locale["sr-Cyrl"]["definitions-of"]  = "Дефиниције за %s"
Locale["sr-Cyrl"]["synonyms"]      = "Синоними"
Locale["sr-Cyrl"]["examples"]      = "Примери"
Locale["sr-Cyrl"]["see-also"]      = "Погледајте такође"
Locale["sr-Cyrl"]["family"]        = "Indo-European"
Locale["sr-Cyrl"]["branch"]        = "South Slavic"
Locale["sr-Cyrl"]["iso"]           = "srp-Cyrl"
Locale["sr-Cyrl"]["glotto"]        = "serb1264"
Locale["sr-Cyrl"]["script"]        = "Cyrl"
Locale["sr-Cyrl"]["spoken-in"]     = "Serbia; Bosnia and Herzegovina; Montenegro; Kosovo"
Locale["sr-Cyrl"]["supported-by"]  = "google; bing; yandex"
Locale["sr-Latn"]["name"]          = "Serbian (Latin)"
Locale["sr-Latn"]["endonym"]       = "Srpski"
Locale["sr-Latn"]["translations-of"] = "Prevodi za „%s“"
Locale["sr-Latn"]["definitions-of"]  = "Definicije za %s"
Locale["sr-Latn"]["synonyms"]      = "Sinonimi"
Locale["sr-Latn"]["examples"]      = "Primeri"
Locale["sr-Latn"]["see-also"]      = "Pogledajte takođe"
Locale["sr-Latn"]["family"]        = "Indo-European"
Locale["sr-Latn"]["branch"]        = "South Slavic"
Locale["sr-Latn"]["iso"]           = "srp-Latn"
Locale["sr-Latn"]["glotto"]        = "serb1264"
Locale["sr-Latn"]["script"]        = "Latn"
Locale["sr-Latn"]["spoken-in"]     = "Serbia; Bosnia and Herzegovina; Montenegro; Kosovo"
Locale["sr-Latn"]["supported-by"]  = "bing"
Locale["st"]["name"]               = "Sesotho"
Locale["st"]["name2"]              = "Sotho"
Locale["st"]["name3"]              = "Southern Sotho"
Locale["st"]["endonym"]            = "Sesotho"
Locale["st"]["translations-of"]    = "Liphetolelo tsa %s"
Locale["st"]["definitions-of"]     = "Meelelo ea %s"
Locale["st"]["synonyms"]           = "Mantsoe a tšoanang ka moelelo"
Locale["st"]["examples"]           = "Mehlala"
Locale["st"]["see-also"]           = "Bona hape"
Locale["st"]["family"]             = "Atlantic-Congo"
Locale["st"]["branch"]             = "Bantu"
Locale["st"]["iso"]                = "sot"
Locale["st"]["glotto"]             = "sout2807"
Locale["st"]["script"]             = "Latn"
Locale["st"]["spoken-in"]          = "Lesotho; South Africa; Zimbabwe"
Locale["st"]["supported-by"]       = "google"
Locale["tn"]["name"]               = "Setswana"
Locale["tn"]["name2"]              = "Tswana"
Locale["tn"]["endonym"]            = "Setswana"
Locale["tn"]["family"]             = "Atlantic-Congo"
Locale["tn"]["branch"]             = "Bantu"
Locale["tn"]["iso"]                = "tsn"
Locale["tn"]["glotto"]             = "tswa1253"
Locale["tn"]["script"]             = "Latn"
Locale["tn"]["spoken-in"]          = "Botswana; South Africa"
Locale["tn"]["supported-by"]       = ""
Locale["sn"]["name"]               = "Shona"
Locale["sn"]["endonym"]            = "chiShona"
Locale["sn"]["translations-of"]    = "Shanduro dze %s"
Locale["sn"]["definitions-of"]     = "Zvinoreva %s"
Locale["sn"]["synonyms"]           = "Mashoko anoreva zvakafana nemamwe"
Locale["sn"]["examples"]           = "Mienzaniso"
Locale["sn"]["see-also"]           = "Onawo"
Locale["sn"]["family"]             = "Atlantic-Congo"
Locale["sn"]["branch"]             = "Bantu"
Locale["sn"]["iso"]                = "sna"
Locale["sn"]["glotto"]             = "core1255"
Locale["sn"]["script"]             = "Latn"
Locale["sn"]["spoken-in"]          = "Zimbabwe"
Locale["sn"]["supported-by"]       = "google"
Locale["sd"]["name"]               = "Sindhi"
Locale["sd"]["endonym"]            = "سنڌي"
Locale["sd"]["translations-of"]    = "%s جو ترجمو"
Locale["sd"]["definitions-of"]     = "%s جون وصفون"
Locale["sd"]["synonyms"]           = "هم معني"
Locale["sd"]["examples"]           = "مثالون"
Locale["sd"]["see-also"]           = "به ڏسو"
Locale["sd"]["family"]             = "Indo-European"
Locale["sd"]["branch"]             = "Indo-Aryan"
Locale["sd"]["iso"]                = "snd"
Locale["sd"]["glotto"]             = "sind1272"
Locale["sd"]["script"]             = "Arab"
Locale["sd"]["rtl"]                = "true"
Locale["sd"]["spoken-in"]          = "the region of Sindh in Pakistan; India"
Locale["sd"]["supported-by"]       = "google"
Locale["si"]["name"]               = "Sinhala"
Locale["si"]["name2"]              = "Sinhalese"
Locale["si"]["endonym"]            = "සිංහල"
Locale["si"]["translations-of"]    = "%s හි පරිවර්තන"
Locale["si"]["definitions-of"]     = "%s හි නිර්වචන"
Locale["si"]["synonyms"]           = "සමානාර්ථ පද"
Locale["si"]["examples"]           = "උදාහරණ"
Locale["si"]["see-also"]           = "මෙයත් බලන්න"
Locale["si"]["family"]             = "Indo-European"
Locale["si"]["branch"]             = "Indo-Aryan"
Locale["si"]["iso"]                = "sin"
Locale["si"]["glotto"]             = "sinh1246"
Locale["si"]["script"]             = "Sinh"
Locale["si"]["spoken-in"]          = "Sri Lanka"
Locale["si"]["supported-by"]       = "google; yandex"
Locale["sk"]["name"]               = "Slovak"
Locale["sk"]["endonym"]            = "Slovenčina"
Locale["sk"]["translations-of"]    = "Preklady výrazu: %s"
Locale["sk"]["definitions-of"]     = "Definície výrazu %s"
Locale["sk"]["synonyms"]           = "Synonymá"
Locale["sk"]["examples"]           = "Príklady"
Locale["sk"]["see-also"]           = "Pozrite tiež"
Locale["sk"]["family"]             = "Indo-European"
Locale["sk"]["branch"]             = "West Slavic"
Locale["sk"]["iso"]                = "slk"
Locale["sk"]["glotto"]             = "slov1269"
Locale["sk"]["script"]             = "Latn"
Locale["sk"]["spoken-in"]          = "Slovakia"
Locale["sk"]["supported-by"]       = "google; bing; yandex"
Locale["sl"]["name"]               = "Slovenian"
Locale["sl"]["name2"]              = "Slovene"
Locale["sl"]["endonym"]            = "Slovenščina"
Locale["sl"]["translations-of"]    = "Prevodi za %s"
Locale["sl"]["definitions-of"]     = "Razlage za %s"
Locale["sl"]["synonyms"]           = "Sopomenke"
Locale["sl"]["examples"]           = "Primeri"
Locale["sl"]["see-also"]           = "Glejte tudi"
Locale["sl"]["family"]             = "Indo-European"
Locale["sl"]["branch"]             = "South Slavic"
Locale["sl"]["iso"]                = "slv"
Locale["sl"]["glotto"]             = "slov1268"
Locale["sl"]["script"]             = "Latn"
Locale["sl"]["spoken-in"]          = "Slovenia"
Locale["sl"]["supported-by"]       = "google; bing; yandex"
Locale["so"]["name"]               = "Somali"
Locale["so"]["endonym"]            = "Soomaali"
Locale["so"]["translations-of"]    = "Turjumaada %s"
Locale["so"]["definitions-of"]     = "Qeexitaannada %s"
Locale["so"]["synonyms"]           = "La micne ah"
Locale["so"]["examples"]           = "Tusaalooyin"
Locale["so"]["see-also"]           = "Sidoo kale eeg"
Locale["so"]["family"]             = "Afro-Asiatic"
Locale["so"]["branch"]             = "Cushitic"
Locale["so"]["iso"]                = "som"
Locale["so"]["glotto"]             = "soma1255"
Locale["so"]["script"]             = "Latn"
Locale["so"]["spoken-in"]          = "Somalia; Somaliland; Ethiopia; Djibouti"
Locale["so"]["supported-by"]       = "google; bing"
Locale["es"]["name"]               = "Spanish"
Locale["es"]["endonym"]            = "Español"
Locale["es"]["translations-of"]    = "Traducciones de %s"
Locale["es"]["definitions-of"]     = "Definiciones de %s"
Locale["es"]["synonyms"]           = "Sinónimos"
Locale["es"]["examples"]           = "Ejemplos"
Locale["es"]["see-also"]           = "Ver también"
Locale["es"]["family"]             = "Indo-European"
Locale["es"]["branch"]             = "Western Romance"
Locale["es"]["iso"]                = "spa"
Locale["es"]["glotto"]             = "stan1288"
Locale["es"]["script"]             = "Latn"
Locale["es"]["dictionary"]         = "true"
Locale["es"]["spoken-in"]          = "Spain; the Americas"
Locale["es"]["supported-by"]       = "google; bing; yandex"
Locale["su"]["name"]               = "Sundanese"
Locale["su"]["endonym"]            = "Basa Sunda"
Locale["su"]["translations-of"]    = "Tarjamahan tina %s"
Locale["su"]["definitions-of"]     = "Panjelasan tina %s"
Locale["su"]["synonyms"]           = "Sinonim"
Locale["su"]["examples"]           = "Conto"
Locale["su"]["see-also"]           = "Tingali ogé"
Locale["su"]["family"]             = "Austronesian"
Locale["su"]["branch"]             = "Malayo-Polynesian"
Locale["su"]["iso"]                = "sun"
Locale["su"]["glotto"]             = "sund1252"
Locale["su"]["script"]             = "Latn"
Locale["su"]["spoken-in"]          = "Java, Indonesia"
Locale["su"]["supported-by"]       = "google; yandex"
Locale["sw"]["name"]               = "Swahili"
Locale["sw"]["name2"]              = "Kiswahili"
Locale["sw"]["endonym"]            = "Kiswahili"
Locale["sw"]["translations-of"]    = "Tafsiri ya %s"
Locale["sw"]["definitions-of"]     = "Ufafanuzi wa %s"
Locale["sw"]["synonyms"]           = "Visawe"
Locale["sw"]["examples"]           = "Mifano"
Locale["sw"]["see-also"]           = "Angalia pia"
Locale["sw"]["family"]             = "Atlantic-Congo"
Locale["sw"]["branch"]             = "Bantu"
Locale["sw"]["iso"]                = "swa"
Locale["sw"]["glotto"]             = "swah1253"
Locale["sw"]["script"]             = "Latn"
Locale["sw"]["spoken-in"]          = "the East African coast and litoral islands"
Locale["sw"]["supported-by"]       = "google; bing; yandex"
Locale["sv"]["name"]               = "Swedish"
Locale["sv"]["endonym"]            = "Svenska"
Locale["sv"]["translations-of"]    = "Översättningar av %s"
Locale["sv"]["definitions-of"]     = "Definitioner av %s"
Locale["sv"]["synonyms"]           = "Synonymer"
Locale["sv"]["examples"]           = "Exempel"
Locale["sv"]["see-also"]           = "Se även"
Locale["sv"]["family"]             = "Indo-European"
Locale["sv"]["branch"]             = "North Germanic"
Locale["sv"]["iso"]                = "swe"
Locale["sv"]["glotto"]             = "swed1254"
Locale["sv"]["script"]             = "Latn"
Locale["sv"]["spoken-in"]          = "Sweden; Finland; Estonia"
Locale["sv"]["supported-by"]       = "google; bing; yandex"
Locale["ty"]["name"]               = "Tahitian"
Locale["ty"]["endonym"]            = "Reo Tahiti"
Locale["ty"]["family"]             = "Austronesian"
Locale["ty"]["branch"]             = "Malayo-Polynesian"
Locale["ty"]["iso"]                = "tah"
Locale["ty"]["glotto"]             = "tahi1242"
Locale["ty"]["script"]             = "Latn"
Locale["ty"]["spoken-in"]          = "French Polynesia"
Locale["ty"]["supported-by"]       = "bing"
Locale["tg"]["name"]               = "Tajik"
Locale["tg"]["name2"]              = "Tajiki"
Locale["tg"]["endonym"]            = "Тоҷикӣ"
Locale["tg"]["translations-of"]    = "Тарҷумаҳои %s"
Locale["tg"]["definitions-of"]     = "Таърифҳои %s"
Locale["tg"]["synonyms"]           = "Муродифҳо"
Locale["tg"]["examples"]           = "Намунаҳо:"
Locale["tg"]["see-also"]           = "Ҳамчунин Бинед"
Locale["tg"]["family"]             = "Indo-European"
Locale["tg"]["branch"]             = "Iranian"
Locale["tg"]["iso"]                = "tgk"
Locale["tg"]["glotto"]             = "taji1245"
Locale["tg"]["script"]             = "Cyrl"
Locale["tg"]["spoken-in"]          = "Tajikistan; Uzbekistan"
Locale["tg"]["supported-by"]       = "google; yandex"
Locale["ta"]["name"]               = "Tamil"
Locale["ta"]["endonym"]            = "தமிழ்"
Locale["ta"]["translations-of"]    = "%s இன் மொழிபெயர்ப்புகள்"
Locale["ta"]["definitions-of"]     = "%s இன் வரையறைகள்"
Locale["ta"]["synonyms"]           = "இணைச்சொற்கள்"
Locale["ta"]["examples"]           = "எடுத்துக்காட்டுகள்"
Locale["ta"]["see-also"]           = "இதையும் காண்க"
Locale["ta"]["family"]             = "Dravidian"
Locale["ta"]["branch"]             = "South Dravidian"
Locale["ta"]["iso"]                = "tam"
Locale["ta"]["glotto"]             = "tami1289"
Locale["ta"]["script"]             = "Taml"
Locale["ta"]["spoken-in"]          = "the Indian state of Tamil Nadu; Sri Lanka; Singapore"
Locale["ta"]["supported-by"]       = "google; bing; yandex"
Locale["tt"]["name"]               = "Tatar"
Locale["tt"]["endonym"]            = "татарча"
Locale["tt"]["family"]             = "Turkic"
Locale["tt"]["branch"]             = "Kipchak"
Locale["tt"]["iso"]                = "tat"
Locale["tt"]["glotto"]             = "tata1255"
Locale["tt"]["script"]             = "Cyrl"
Locale["tt"]["spoken-in"]          = "the Republic of Tatarstan in Russia"
Locale["tt"]["supported-by"]       = "google; bing; yandex"
Locale["te"]["name"]               = "Telugu"
Locale["te"]["endonym"]            = "తెలుగు"
Locale["te"]["translations-of"]    = "%s యొక్క అనువాదాలు"
Locale["te"]["definitions-of"]     = "%s యొక్క నిర్వచనాలు"
Locale["te"]["synonyms"]           = "పర్యాయపదాలు"
Locale["te"]["examples"]           = "ఉదాహరణలు"
Locale["te"]["see-also"]           = "వీటిని కూడా చూడండి"
Locale["te"]["family"]             = "Dravidian"
Locale["te"]["branch"]             = "South-Central Dravidian"
Locale["te"]["iso"]                = "tel"
Locale["te"]["glotto"]             = "telu1262"
Locale["te"]["script"]             = "Telu"
Locale["te"]["spoken-in"]          = "the Indian states of Andhra Pradesh and Telangana"
Locale["te"]["supported-by"]       = "google; bing; yandex"
Locale["th"]["name"]               = "Thai"
Locale["th"]["endonym"]            = "ไทย"
Locale["th"]["translations-of"]    = "คำแปลของ %s"
Locale["th"]["definitions-of"]     = "คำจำกัดความของ %s"
Locale["th"]["synonyms"]           = "คำพ้องความหมาย"
Locale["th"]["examples"]           = "ตัวอย่าง"
Locale["th"]["see-also"]           = "ดูเพิ่มเติม"
Locale["th"]["family"]             = "Kra-Dai"
Locale["th"]["branch"]             = "Tai"
Locale["th"]["iso"]                = "tha"
Locale["th"]["glotto"]             = "thai1261"
Locale["th"]["script"]             = "Thai"
Locale["th"]["spoken-in"]          = "Thailand"
Locale["th"]["supported-by"]       = "google; bing; yandex"
Locale["bo"]["name"]               = "Tibetan"
Locale["bo"]["endonym"]            = "བོད་ཡིག"
Locale["bo"]["family"]             = "Sino-Tibetan"
Locale["bo"]["branch"]             = "Tibetic"
Locale["bo"]["iso"]                = "bod"
Locale["bo"]["glotto"]             = "tibe1272"
Locale["bo"]["script"]             = "Tibt"
Locale["bo"]["spoken-in"]          = "the Tibet Autonomous Region of China"
Locale["bo"]["supported-by"]       = "bing"
Locale["ti"]["name"]               = "Tigrinya"
Locale["ti"]["endonym"]            = "ትግርኛ"
Locale["ti"]["family"]             = "Afro-Asiatic"
Locale["ti"]["branch"]             = "Semitic"
Locale["ti"]["iso"]                = "tir"
Locale["ti"]["glotto"]             = "tigr1271"
Locale["ti"]["script"]             = "Ethi"
Locale["ti"]["spoken-in"]          = "Eritrea; the Tigray region of northern Ethiopia"
Locale["ti"]["supported-by"]       = "google; bing"
Locale["to"]["name"]               = "Tongan"
Locale["to"]["endonym"]            = "Lea faka-Tonga"
Locale["to"]["family"]             = "Austronesian"
Locale["to"]["branch"]             = "Malayo-Polynesian"
Locale["to"]["iso"]                = "ton"
Locale["to"]["glotto"]             = "tong1325"
Locale["to"]["script"]             = "Latn"
Locale["to"]["spoken-in"]          = "Tonga"
Locale["to"]["supported-by"]       = "bing"
Locale["ts"]["name"]               = "Tsonga"
Locale["ts"]["endonym"]            = "Xitsonga"
Locale["ts"]["family"]             = "Atlantic-Congo"
Locale["ts"]["branch"]             = "Bantu"
Locale["ts"]["iso"]                = "tso"
Locale["ts"]["glotto"]             = "tson1249"
Locale["ts"]["script"]             = "Latn"
Locale["ts"]["spoken-in"]          = "Eswatini; Mozambique; South Africa; Zimbabwe"
Locale["ts"]["supported-by"]       = "google"
Locale["tr"]["name"]               = "Turkish"
Locale["tr"]["endonym"]            = "Türkçe"
Locale["tr"]["translations-of"]    = "%s çevirileri"
Locale["tr"]["definitions-of"]     = "%s için tanımlar"
Locale["tr"]["synonyms"]           = "Eş anlamlılar"
Locale["tr"]["examples"]           = "Örnekler"
Locale["tr"]["see-also"]           = "Ayrıca bkz."
Locale["tr"]["family"]             = "Turkic"
Locale["tr"]["branch"]             = "Oghuz"
Locale["tr"]["iso"]                = "tur"
Locale["tr"]["glotto"]             = "nucl1301"
Locale["tr"]["script"]             = "Latn"
Locale["tr"]["spoken-in"]          = "Türkiye; Cyprus"
Locale["tr"]["supported-by"]       = "google; bing; yandex"
Locale["tk"]["name"]               = "Turkmen"
Locale["tk"]["endonym"]            = "Türkmen"
Locale["tk"]["family"]             = "Turkic"
Locale["tk"]["branch"]             = "Oghuz"
Locale["tk"]["iso"]                = "tuk"
Locale["tk"]["glotto"]             = "turk1304"
Locale["tk"]["script"]             = "Latn"
Locale["tk"]["spoken-in"]          = "Turkmenistan; Iran; Afghanistan; Pakistan"
Locale["tk"]["supported-by"]       = "google; bing"
Locale["tw"]["name"]               = "Twi"
Locale["tw"]["name2"]              = "Akan Kasa"
Locale["tw"]["endonym"]            = "Twi"
Locale["tw"]["family"]             = "Atlantic-Congo"
Locale["tw"]["branch"]             = "Kwa"
Locale["tw"]["iso"]                = "twi"
Locale["tw"]["glotto"]             = "akua1239"
Locale["tw"]["script"]             = "Latn"
Locale["tw"]["spoken-in"]          = "Ghana"
Locale["tw"]["supported-by"]       = "google"
Locale["udm"]["name"]              = "Udmurt"
Locale["udm"]["endonym"]           = "Удмурт"
Locale["udm"]["family"]            = "Uralic"
Locale["udm"]["branch"]            = "Permic"
Locale["udm"]["iso"]               = "udm"
Locale["udm"]["glotto"]            = "udmu1245"
Locale["udm"]["script"]            = "Cyrl"
Locale["udm"]["spoken-in"]         = "the Republic of Udmurt in Russia"
Locale["udm"]["supported-by"]      = "yandex"
Locale["uk"]["name"]               = "Ukrainian"
Locale["uk"]["endonym"]            = "Українська"
Locale["uk"]["translations-of"]    = "Переклади слова або виразу \"%s\""
Locale["uk"]["definitions-of"]     = "\"%s\" – визначення"
Locale["uk"]["synonyms"]           = "Синоніми"
Locale["uk"]["examples"]           = "Приклади"
Locale["uk"]["see-also"]           = "Дивіться також"
Locale["uk"]["family"]             = "Indo-European"
Locale["uk"]["branch"]             = "East Slavic"
Locale["uk"]["iso"]                = "ukr"
Locale["uk"]["glotto"]             = "ukra1253"
Locale["uk"]["script"]             = "Cyrl"
Locale["uk"]["spoken-in"]          = "Ukraine"
Locale["uk"]["supported-by"]       = "google; bing; yandex"
Locale["hsb"]["name"]              = "Upper Sorbian"
Locale["hsb"]["endonym"]           = "Hornjoserbšćina"
Locale["hsb"]["family"]            = "Indo-European"
Locale["hsb"]["branch"]            = "West Slavic"
Locale["hsb"]["iso"]               = "hsb"
Locale["hsb"]["glotto"]            = "uppe1395"
Locale["hsb"]["script"]            = "Latn"
Locale["hsb"]["spoken-in"]         = "Saxony, Germany"
Locale["hsb"]["supported-by"]      = "bing"
Locale["ur"]["name"]               = "Urdu"
Locale["ur"]["endonym"]            = "اُردُو"
Locale["ur"]["translations-of"]    = "کے ترجمے %s"
Locale["ur"]["definitions-of"]     = "کی تعریفات %s"
Locale["ur"]["synonyms"]           = "مترادفات"
Locale["ur"]["examples"]           = "مثالیں"
Locale["ur"]["see-also"]           = "نیز دیکھیں"
Locale["ur"]["family"]             = "Indo-European"
Locale["ur"]["branch"]             = "Indo-Aryan"
Locale["ur"]["iso"]                = "urd"
Locale["ur"]["glotto"]             = "urdu1245"
Locale["ur"]["script"]             = "Arab"
Locale["ur"]["rtl"]                = "true"
Locale["ur"]["spoken-in"]          = "Pakistan; India"
Locale["ur"]["supported-by"]       = "google; bing; yandex"
Locale["ug"]["name"]               = "Uyghur"
Locale["ug"]["endonym"]            = "ئۇيغۇر تىلى"
Locale["ug"]["family"]             = "Turkic"
Locale["ug"]["branch"]             = "Karluk"
Locale["ug"]["iso"]                = "uig"
Locale["ug"]["glotto"]             = "uigh1240"
Locale["ug"]["script"]             = "Arab"
Locale["ug"]["rtl"]                = "true"
Locale["ug"]["spoken-in"]          = "the Xinjiang Uyghur Autonomous Region of China"
Locale["ug"]["supported-by"]       = "google; bing"
Locale["uz"]["name"]               = "Uzbek"
Locale["uz"]["endonym"]            = "Oʻzbek tili"
Locale["uz"]["translations-of"]    = "%s: tarjima variantlari"
Locale["uz"]["definitions-of"]     = "%s – ta’riflar"
Locale["uz"]["synonyms"]           = "Sinonimlar"
Locale["uz"]["examples"]           = "Namunalar"
Locale["uz"]["see-also"]           = "O‘xshash so‘zlar"
Locale["uz"]["family"]             = "Turkic"
Locale["uz"]["branch"]             = "Karluk"
Locale["uz"]["iso"]                = "uzb"
Locale["uz"]["glotto"]             = "uzbe1247"
Locale["uz"]["script"]             = "Latn"
Locale["uz"]["spoken-in"]          = "Uzbekistan; Afghanistan; Pakistan"
Locale["uz"]["supported-by"]       = "google; bing; yandex"
Locale["vi"]["name"]               = "Vietnamese"
Locale["vi"]["endonym"]            = "Tiếng Việt"
Locale["vi"]["translations-of"]    = "Bản dịch của %s"
Locale["vi"]["definitions-of"]     = "Nghĩa của %s"
Locale["vi"]["synonyms"]           = "Từ đồng nghĩa"
Locale["vi"]["examples"]           = "Ví dụ"
Locale["vi"]["see-also"]           = "Xem thêm"
Locale["vi"]["family"]             = "Austroasiatic"
Locale["vi"]["branch"]             = "Vietic"
Locale["vi"]["iso"]                = "vie"
Locale["vi"]["glotto"]             = "viet1252"
Locale["vi"]["script"]             = "Latn"
Locale["vi"]["spoken-in"]          = "Vietnam"
Locale["vi"]["supported-by"]       = "google; bing; yandex"
Locale["vo"]["name"]               = "Volapük"
Locale["vo"]["endonym"]            = "Volapük"
Locale["vo"]["family"]             = "Constructed language"
Locale["vo"]["iso"]                = "vol"
Locale["vo"]["glotto"]             = "vola1234"
Locale["vo"]["script"]             = "Latn"
Locale["vo"]["spoken-in"]          = "worldwide"
Locale["vo"]["description"]        = "an international auxiliary language"
Locale["vo"]["supported-by"]       = ""
Locale["cy"]["name"]               = "Welsh"
Locale["cy"]["endonym"]            = "Cymraeg"
Locale["cy"]["translations-of"]    = "Cyfieithiadau %s"
Locale["cy"]["definitions-of"]     = "Diffiniadau %s"
Locale["cy"]["synonyms"]           = "Cyfystyron"
Locale["cy"]["examples"]           = "Enghreifftiau"
Locale["cy"]["see-also"]           = "Gweler hefyd"
Locale["cy"]["family"]             = "Indo-European"
Locale["cy"]["branch"]             = "Celtic"
Locale["cy"]["iso"]                = "cym"
Locale["cy"]["glotto"]             = "wels1247"
Locale["cy"]["script"]             = "Latn"
Locale["cy"]["spoken-in"]          = "Wales in the UK"
Locale["cy"]["supported-by"]       = "google; bing; yandex"
Locale["fy"]["name"]               = "Frisian"
Locale["fy"]["endonym"]            = "Frysk"
Locale["fy"]["translations-of"]    = "Oersettings fan %s"
Locale["fy"]["definitions-of"]     = "Definysjes fan %s"
Locale["fy"]["synonyms"]           = "Synonimen"
Locale["fy"]["examples"]           = "Foarbylden"
Locale["fy"]["see-also"]           = "Sjoch ek"
Locale["fy"]["family"]             = "Indo-European"
Locale["fy"]["branch"]             = "West Germanic"
Locale["fy"]["iso"]                = "fry"
Locale["fy"]["glotto"]             = "west2354"
Locale["fy"]["script"]             = "Latn"
Locale["fy"]["spoken-in"]          = "Friesland in the Netherlands"
Locale["fy"]["supported-by"]       = "google"
Locale["wo"]["name"]               = "Wolof"
Locale["wo"]["endonym"]            = "Wollof"
Locale["wo"]["family"]             = "Atlantic-Congo"
Locale["wo"]["branch"]             = "Atlantic"
Locale["wo"]["iso"]                = "wol"
Locale["wo"]["glotto"]             = "wolo1247"
Locale["wo"]["script"]             = "Latn"
Locale["wo"]["spoken-in"]          = "Senegal; Mauritania; the Gambia"
Locale["wo"]["supported-by"]       = ""
Locale["xh"]["name"]               = "Xhosa"
Locale["xh"]["endonym"]            = "isiXhosa"
Locale["xh"]["translations-of"]    = "Iinguqulelo zika-%s"
Locale["xh"]["definitions-of"]     = "Iingcaciso zika-%s"
Locale["xh"]["synonyms"]           = "Izithethantonye"
Locale["xh"]["examples"]           = "Imizekelo"
Locale["xh"]["see-also"]           = "Kwakhona bona"
Locale["xh"]["family"]             = "Atlantic-Congo"
Locale["xh"]["branch"]             = "Bantu"
Locale["xh"]["iso"]                = "xho"
Locale["xh"]["glotto"]             = "xhos1239"
Locale["xh"]["script"]             = "Latn"
Locale["xh"]["spoken-in"]          = "South Africa; Zimbabwe"
Locale["xh"]["supported-by"]       = "google; yandex"
Locale["sah"]["name"]              = "Yakut"
Locale["sah"]["name2"]             = "Sakha"
Locale["sah"]["endonym"]           = "Sakha"
Locale["sah"]["family"]            = "Turkic"
Locale["sah"]["branch"]            = "Siberian Turkic"
Locale["sah"]["iso"]               = "sah"
Locale["sah"]["glotto"]            = "yaku1245"
Locale["sah"]["script"]            = "Latn"
Locale["sah"]["spoken-in"]         = "the Republic of Sakha (Yakutia) in Russia"
Locale["sah"]["supported-by"]      = "yandex"
Locale["yi"]["name"]               = "Yiddish"
Locale["yi"]["endonym"]            = "ייִדיש"
Locale["yi"]["translations-of"]    = "איבערזעצונגען פון %s"
Locale["yi"]["definitions-of"]     = "דפיניציונען %s"
Locale["yi"]["synonyms"]           = "סינאָנימען"
Locale["yi"]["examples"]           = "ביישפילע"
Locale["yi"]["see-also"]           = "זייען אויך"
Locale["yi"]["family"]             = "Indo-European"
Locale["yi"]["branch"]             = "West Germanic"
Locale["yi"]["iso"]                = "yid"
Locale["yi"]["glotto"]             = "yidd1255"
Locale["yi"]["script"]             = "Hebr"
Locale["yi"]["rtl"]                = "true"
Locale["yi"]["spoken-in"]          = "worldwide"
Locale["yi"]["description"]        = "a West Germanic language historically spoken by Ashkenazi Jews"
Locale["yi"]["supported-by"]       = "google; yandex"
Locale["yo"]["name"]               = "Yoruba"
Locale["yo"]["endonym"]            = "Yorùbá"
Locale["yo"]["translations-of"]    = "Awọn itumọ ti %s"
Locale["yo"]["definitions-of"]     = "Awọn itumọ ti %s"
Locale["yo"]["synonyms"]           = "Awọn ọrọ onitumọ"
Locale["yo"]["examples"]           = "Awọn apẹrẹ"
Locale["yo"]["see-also"]           = "Tun wo"
Locale["yo"]["family"]             = "Atlantic-Congo"
Locale["yo"]["iso"]                = "yor"
Locale["yo"]["glotto"]             = "yoru1245"
Locale["yo"]["script"]             = "Latn"
Locale["yo"]["spoken-in"]          = "Nigeria; Benin"
Locale["yo"]["supported-by"]       = "google"
Locale["yua"]["name"]              = "Yucatec Maya"
Locale["yua"]["endonym"]           = "Màaya T'àan"
Locale["yua"]["family"]            = "Mayan"
Locale["yua"]["iso"]               = "yua"
Locale["yua"]["glotto"]            = "yuca1254"
Locale["yua"]["script"]            = "Latn"
Locale["yua"]["spoken-in"]         = "Mexico; Belize"
Locale["yua"]["supported-by"]      = "bing"
Locale["zu"]["name"]               = "Zulu"
Locale["zu"]["endonym"]            = "isiZulu"
Locale["zu"]["translations-of"]    = "Ukuhumusha i-%s"
Locale["zu"]["definitions-of"]     = "Izincazelo ze-%s"
Locale["zu"]["synonyms"]           = "Amagama afanayo"
Locale["zu"]["examples"]           = "Izibonelo"
Locale["zu"]["see-also"]           = "Bheka futhi"
Locale["zu"]["family"]             = "Atlantic-Congo"
Locale["zu"]["branch"]             = "Bantu"
Locale["zu"]["iso"]                = "zul"
Locale["zu"]["glotto"]             = "zulu1248"
Locale["zu"]["script"]             = "Latn"
Locale["zu"]["spoken-in"]          = "South Africa; Lesotho; Eswatini"
Locale["zu"]["supported-by"]       = "google; bing; yandex"
}
function initLocaleAlias(    i) {
for (i in Locale) {
if ("iso" in Locale[i])
LocaleAlias[Locale[i]["iso"]] = i
if ("name" in Locale[i])
LocaleAlias[tolower(Locale[i]["name"])] = i
if ("name2" in Locale[i])
LocaleAlias[tolower(Locale[i]["name2"])] = i
if ("endonym" in Locale[i])
LocaleAlias[tolower(Locale[i]["endonym"])] = i
if ("endonym2" in Locale[i])
LocaleAlias[tolower(Locale[i]["endonym2"])] = i
}
LocaleAlias["in"] = "id"
LocaleAlias["iw"] = "he"
LocaleAlias["ji"] = "yi"
LocaleAlias["jw"] = "jv"
LocaleAlias["kurdish"] = "ku" # Kurdish: default to "ku" (N.B. Google uses this code for Kurmanji)
LocaleAlias["mari"] = "mhr" # Mari: default to "mhr" (Eastern Mari)
LocaleAlias["mo"] = "ro"
LocaleAlias["moldavian"] = "ro"
LocaleAlias["moldovan"] = "ro"
LocaleAlias["mww"] = "hmn"
LocaleAlias["nb"] = "no"
LocaleAlias["nn"] = "no"
LocaleAlias["pt"] = "pt-BR"
LocaleAlias["portuguese"] = "pt-BR"
LocaleAlias["sh"]      = "sr-Cyrl"
LocaleAlias["sr"]      = "sr-Cyrl"
LocaleAlias["srp"]     = "sr-Cyrl"
LocaleAlias["serbian"] = "sr-Cyrl"
LocaleAlias["zh"]      = "zh-CN"
LocaleAlias["zh-CHS"]  = "zh-CN"
LocaleAlias["zh-CHT"]  = "zh-TW"
LocaleAlias["zh-Hans"] = "zh-CN"
LocaleAlias["zh-Hant"] = "zh-TW"
LocaleAlias["zho"]     = "zh-CN"
LocaleAlias["chinese"] = "zh-CN"
LocaleAlias["tlh"] = "tlh-Latn"
LocaleAlias["mni"] = "mni-Mtei"
}
function initLocaleDisplay(    i) {
for (i in Locale) {
Locale[i]["display"] = show(Locale[i]["endonym"], i)
}
}
function getCode(code,    group) {
if (code == "auto" || code in Locale)
return code
else if (code in LocaleAlias)
return LocaleAlias[code]
else if (tolower(code) in LocaleAlias)
return LocaleAlias[tolower(code)]
match(code, /^([[:alpha:]][[:alpha:]][[:alpha:]]?)-(.*)$/, group)
if (group[1])
return group[1]
return
}
function getName(code) {
return Locale[getCode(code)]["name"]
}
function getNames(code) {
if ("name2" in Locale[getCode(code)])
return Locale[getCode(code)]["name"] " / " Locale[getCode(code)]["name2"]
else
return Locale[getCode(code)]["name"]
}
function getEndonym(code) {
return Locale[getCode(code)]["endonym"]
}
function getDisplay(code) {
return Locale[getCode(code)]["display"]
}
function showTranslationsOf(code, text,    fmt) {
fmt = Locale[getCode(code)]["translations-of"]
if (!fmt) fmt = Locale["en"]["translations-of"]
return sprintf(fmt, text)
}
function showDefinitionsOf(code, text,    fmt) {
fmt = Locale[getCode(code)]["definitions-of"]
if (!fmt) fmt = Locale["en"]["definitions-of"]
return sprintf(fmt, text)
}
function showSynonyms(code,    tmp) {
tmp = Locale[getCode(code)]["synonyms"]
if (!tmp) tmp = Locale["en"]["synonyms"]
return tmp
}
function showExamples(code,    tmp) {
tmp = Locale[getCode(code)]["examples"]
if (!tmp) tmp = Locale["en"]["examples"]
return tmp
}
function showSeeAlso(code,    tmp) {
tmp = Locale[getCode(code)]["see-also"]
if (!tmp) tmp = Locale["en"]["see-also"]
return tmp
}
function getFamily(code) {
return Locale[getCode(code)]["family"]
}
function getBranch(code) {
return Locale[getCode(code)]["branch"]
}
function getISO(code) {
return Locale[getCode(code)]["iso"]
}
function getGlotto(code) {
return Locale[getCode(code)]["glotto"]
}
function getScript(code) {
return Locale[getCode(code)]["script"]
}
function isRTL(code) {
return Locale[getCode(code)]["rtl"] ? 1 : 0
}
function hasDictionary(code) {
return Locale[getCode(code)]["dictionary"] ? 1 : 0
}
function compName(i1, v1, i2, v2) {
if (getName(i1) < getName(i2))
return -1
else
return (getName(i1) != getName(i2))
}
function scriptName(code) {
switch (code) {
case "Arab": return "Arabic"
case "Armn": return "Armenian"
case "Beng": return "Bengali"
case "Cans": return "Canadian Aboriginal Syllabics"
case "Cher": return "Cherokee"
case "Cyrl": return "Cyrillic"
case "Deva": return "Devanagari"
case "Ethi": return "Ethiopic (Geʻez)"
case "Geor": return "Georgian (Mkhedruli)"
case "Grek": return "Greek"
case "Gujr": return "Gujarati"
case "Guru": return "Gurmukhi"
case "Hani": return "Han"
case "Hans": return "Han (Simplified)"
case "Hant": return "Han (Traditional)"
case "Hebr": return "Hebrew"
case "Jpan": return "Japanese (Han + Hiragana + Katakana)"
case "Khmr": return "Khmer"
case "Knda": return "Kannada"
case "Kore": return "Korean (Hangul + Han)"
case "Laoo": return "Lao"
case "Latn": return "Latin"
case "Mlym": return "Malayalam"
case "Mong": return "Mongolian"
case "Mtei": return "Meitei Mayek"
case "Mymr": return "Myanmar"
case "Orya": return "Oriya"
case "Sinh": return "Sinhala"
case "Taml": return "Tamil"
case "Telu": return "Telugu"
case "Thaa": return "Thaana"
case "Thai": return "Thai"
case "Tibt": return "Tibetan"
default: return "Unknown"
}
}
function getSpokenIn(code,    i, j, r, regions, str) {
r = NULLSTR
str = Locale[getCode(code)]["spoken-in"]
if (str) {
split(str, regions, /\s?;\s?/)
j = 0
for (i in regions) {
r = r regions[i]
j++
if (j < length(regions) - 1)
r = r ", "
else if (j == length(regions) - 1)
r = r " and "
}
}
return r
}
function getWrittenIn(code,    i, j, r, regions, str) {
r = NULLSTR
str = Locale[getCode(code)]["written-in"]
if (str) {
split(str, regions, /\s?;\s?/)
j = 0
for (i in regions) {
r = r regions[i]
j++
if (j < length(regions) - 1)
r = r ", "
else if (j == length(regions) - 1)
r = r " and "
}
}
return r
}
function getDescription(code) {
return Locale[getCode(code)]["description"]
}
function isSupportedByGoogle(code,    engines, i, str) {
str = Locale[getCode(code)]["supported-by"]
if (str) {
split(str, engines, /\s?;\s?/)
for (i in engines)
if (engines[i] == "google") return 1
}
return 0
}
function isSupportedByBing(code,    engines, i, str) {
str = Locale[getCode(code)]["supported-by"]
if (str) {
split(str, engines, /\s?;\s?/)
for (i in engines)
if (engines[i] == "bing") return 1
}
return 0
}
function getDetails(code,    article, desc, group, iso, name, names, script, writing) {
if (code == "auto" || !getCode(code)) {
e("[ERROR] Language not found: " code "\n"\
"        Run '-reference / -R' to see a list of available languages.")
exit 1
}
script = scriptName(getScript(code))
if (isRTL(code)) script = script " (R-to-L)"
split(getISO(code), group, "-")
iso = group[1]
name = getName(code)
names = getNames(code)
if (match(name, /\(.*\)/)) {
writing = substr(name, match(name, /\(.*\)/) + 1)
writing = substr(writing, 1, length(writing) - 1)
name = substr(name, 1, match(name, /\(.*\)/) - 2)
}
if (getDescription(code))
desc = sprintf("%s is %s.", names, getDescription(code))
else if (getBranch(code)) {
article = match(tolower(getBranch(code)), /^[aeiou]/) ? "an" : "a"
if (iso == "eng")
desc = sprintf("%s is %s %s language spoken %s.",
names, article, getBranch(code), getSpokenIn(code))
else
desc = sprintf("%s is %s %s language spoken mainly in %s.",
names, article, getBranch(code), getSpokenIn(code))
}
else if (getFamily(code) == NULLSTR || tolower(getFamily(code)) == "language isolate")
desc = sprintf("%s is a language spoken mainly in %s.", names, getSpokenIn(code))
else
desc = sprintf("%s is a language of the %s family, spoken mainly in %s.",
names, getFamily(code), getSpokenIn(code))
if (writing && getWrittenIn(code))
desc = desc sprintf(" The %s writing system is officially used in %s.",
tolower(writing), getWrittenIn(code))
return ansi("bold", sprintf("%s\n", getDisplay(code)))\
sprintf("%-22s%s\n", "Name", ansi("bold", names))\
sprintf("%-22s%s\n", "Family", ansi("bold", getFamily(code)))\
sprintf("%-22s%s\n", "Writing system", ansi("bold", script))\
sprintf("%-22s%s\n", "Code", ansi("bold", getCode(code)))\
sprintf("%-22s%s\n", "ISO 639-3", ansi("bold", iso))\
sprintf("%-22s%s\n", "SIL", ansi("bold", "https://iso639-3.sil.org/code/" iso))\
sprintf("%-22s%s\n", "Glottolog", getGlotto(code) ?
ansi("bold", "https://glottolog.org/resource/languoid/id/" getGlotto(code)) : "")\
sprintf("%-22s%s\n", "Wikipedia", ansi("bold", "https://en.wikipedia.org/wiki/ISO_639:" iso))\
(Locale[getCode(code)]["supported-by"] ?
sprintf("%-22s%s\n", "Translator support", sprintf("Google [%s]    Bing [%s]",
isSupportedByGoogle(code) ? "✔" : "✘", isSupportedByBing(code) ? "✔" : "✘")) : "")\
(Locale[getCode(code)]["spoken-in"] ?
ansi("bold", sprintf("\n%s", desc)) : "")
}
function showPhonetics(phonetics, code) {
if (code && getCode(code) == "en")
return "/" phonetics "/"
else
return "(" phonetics ")"
}
function show(text, code,    command, temp) {
if (!code || isRTL(code)) {
if (Cache[text][0])
return Cache[text][0]
else {
if ((FriBidi || (code && isRTL(code))) && BiDiNoPad) {
command = "echo " parameterize(text) PIPE BiDiNoPad
command | getline temp
close(command)
} else
temp = text
return Cache[text][0] = temp
}
} else
return text
}
function s(text, code, width,    command, temp) {
if (!code || isRTL(code)) {
if (!width) width = Option["width"]
if (Cache[text][width])
return Cache[text][width]
else {
if ((FriBidi || (code && isRTL(code))) && BiDi) {
command = "echo " parameterize(text) PIPE sprintf(BiDi, width)
command | getline temp
close(command)
} else
temp = text
return Cache[text][width] = temp
}
} else
return text
}
function ins(level, text, code, width,    i, temp) {
if (code && isRTL(code)) {
if (!width) width = Option["width"]
return s(text, code, width - Option["indent"] * level)
} else
return replicate(" ", Option["indent"] * level) text
}
function parseLang(lang,    code, group) {
match(lang, /^([a-z][a-z][a-z]?)(_|$)/, group)
code = getCode(group[1])
if (lang ~ /^zh_(CN|SG)/) code = "zh-CN"
else if (lang ~ /^zh_(TW|HK)/) code = "zh-TW"
if (!code) code = "en"
return code
}
function initUserLang(    lang, utf) {
if (lang = ENVIRON["LC_ALL"]) {
if (!UserLocale) UserLocale = lang
utf = utf || tolower(lang) ~ /utf-?8$/
}
if (lang = ENVIRON["LANG"]) {
if (!UserLocale) UserLocale = lang
utf = utf || tolower(lang) ~ /utf-?8$/
}
if (!UserLocale) {
UserLocale = "en_US.UTF-8"
utf = 1
}
if (!utf)
w("[WARNING] Your locale codeset (" UserLocale ") is not UTF-8.")
UserLang = parseLang(UserLocale)
}
function getVersion(    build, gitHead) {
initAudioPlayer()
initPager()
Platform = Platform ? Platform : detectProgram("uname", "-s", 1)
if (ENVIRON["TRANS_BUILD"])
build = "-" ENVIRON["TRANS_BUILD"]
else {
gitHead = getGitHead()
build = gitHead ? "-git:" gitHead : ""
}
return ansi("bold", sprintf("%-22s%s%s\n\n", Name, Version, build))\
sprintf("%-22s%s\n", "platform", Platform)\
sprintf("%-22s%s\n", "terminal type", ENVIRON["TERM"])\
sprintf("%-22s%s\n", "bi-di emulator", BiDiTerm ? BiDiTerm :
"[N/A]")\
sprintf("%-22s%s\n", "gawk (GNU Awk)", PROCINFO["version"])\
sprintf("%s\n", FriBidi ? FriBidi :
"fribidi (GNU FriBidi) [NOT INSTALLED]")\
sprintf("%-22s%s\n", "audio player", AudioPlayer ? AudioPlayer :
"[NOT INSTALLED]")\
sprintf("%-22s%s\n", "terminal pager", Pager ? Pager :
"[NOT INSTALLED]")\
sprintf("%-22s%s\n", "web browser", Option["browser"] != NONE ?
Option["browser"] :"[NONE]")\
sprintf("%-22s%s (%s)\n", "user locale", UserLocale, getName(UserLang))\
sprintf("%-22s%s\n", "host language", Option["hl"])\
sprintf("%-22s%s\n", "source language", join(Option["sls"], "+"))\
sprintf("%-22s%s\n", "target language", join(Option["tl"], "+"))\
sprintf("%-22s%s\n", "translation engine", Option["engine"])\
sprintf("%-22s%s\n", "proxy", Option["proxy"] ? Option["proxy"] :
"[NONE]")\
sprintf("%-22s%s\n", "user-agent", Option["user-agent"] ? Option["user-agent"] :
"[NONE]")\
sprintf("%-22s%s\n", "ip version", Option["ip-version"] ? Option["ip-version"] :
"[DEFAULT]")\
sprintf("%-22s%s\n", "theme", Option["theme"])\
sprintf("%-22s%s\n", "init file", InitScript ? InitScript : "[NONE]")\
sprintf("\n%-22s%s", "Report bugs to:", "https://github.com/soimort/translate-shell/issues")
}
function getHelp() {
return "Usage:  " ansi("bold", Command)\
" [" ansi("underline", "OPTIONS") "]"\
" [" ansi("underline", "SOURCES") "]"\
":[" ansi("underline", "TARGETS") "]"\
" [" ansi("underline", "TEXT") "]..." RS\
RS "Information options:" RS\
ins(1, ansi("bold", "-V") ", " ansi("bold", "-version")) RS\
ins(2, "Print version and exit.") RS\
ins(1, ansi("bold", "-H") ", " ansi("bold", "-help")) RS\
ins(2, "Print help message and exit.") RS\
ins(1, ansi("bold", "-M") ", " ansi("bold", "-man")) RS\
ins(2, "Show man page and exit.") RS\
ins(1, ansi("bold", "-T") ", " ansi("bold", "-reference")) RS\
ins(2, "Print reference table of languages (in endonyms) and codes, and exit.") RS\
ins(1, ansi("bold", "-R") ", " ansi("bold", "-reference-english")) RS\
ins(2, "Print reference table of languages (in English names) and codes, and exit.") RS\
ins(1, ansi("bold", "-S") ", " ansi("bold", "-list-engines")) RS\
ins(2, "List available translation engines and exit.") RS\
ins(1, ansi("bold", "-list-languages")) RS\
ins(2, "List all languages (in endonyms) and exit.") RS\
ins(1, ansi("bold", "-list-languages-english")) RS\
ins(2, "List all languages (in English names) and exit.") RS\
ins(1, ansi("bold", "-list-codes")) RS\
ins(2, "List all codes and exit.") RS\
ins(1, ansi("bold", "-list-all")) RS\
ins(2, "List all languages (endonyms and English names) and codes, and exit.") RS\
ins(1, ansi("bold", "-L ") ansi("underline", "CODES")\
", " ansi("bold", "-linguist ") ansi("underline", "CODES")) RS\
ins(2, "Print details of languages and exit.") RS\
ins(1, ansi("bold", "-U") ", " ansi("bold", "-upgrade")) RS\
ins(2, "Check for upgrade of this program.") RS\
RS "Translator options:" RS\
ins(1, ansi("bold", "-e ") ansi("underline", "ENGINE")\
", " ansi("bold", "-engine ") ansi("underline", "ENGINE")) RS\
ins(2, "Specify the translation engine to use.") RS\
RS "Display options:" RS\
ins(1, ansi("bold", "-verbose")) RS\
ins(2, "Verbose mode. (default)") RS\
ins(1, ansi("bold", "-b") ", " ansi("bold", "-brief")) RS\
ins(2, "Brief mode.") RS\
ins(1, ansi("bold", "-d") ", " ansi("bold", "-dictionary")) RS\
ins(2, "Dictionary mode.") RS\
ins(1, ansi("bold", "-identify")) RS\
ins(2, "Language identification.") RS\
ins(1, ansi("bold", "-show-original ") ansi("underline", "Y/n")) RS\
ins(2, "Show original text or not.") RS\
ins(1, ansi("bold", "-show-original-phonetics ") ansi("underline", "Y/n")) RS\
ins(2, "Show phonetic notation of original text or not.") RS\
ins(1, ansi("bold", "-show-translation ") ansi("underline", "Y/n")) RS\
ins(2, "Show translation or not.") RS\
ins(1, ansi("bold", "-show-translation-phonetics ") ansi("underline", "Y/n")) RS\
ins(2, "Show phonetic notation of translation or not.") RS\
ins(1, ansi("bold", "-show-prompt-message ") ansi("underline", "Y/n")) RS\
ins(2, "Show prompt message or not.") RS\
ins(1, ansi("bold", "-show-languages ") ansi("underline", "Y/n")) RS\
ins(2, "Show source and target languages or not.") RS\
ins(1, ansi("bold", "-show-original-dictionary ") ansi("underline", "y/N")) RS\
ins(2, "Show dictionary entry of original text or not.") RS\
ins(1, ansi("bold", "-show-dictionary ") ansi("underline", "Y/n")) RS\
ins(2, "Show dictionary entry of translation or not.") RS\
ins(1, ansi("bold", "-show-alternatives ") ansi("underline", "Y/n")) RS\
ins(2, "Show alternative translations or not.") RS\
ins(1, ansi("bold", "-w ") ansi("underline", "NUM")\
", " ansi("bold", "-width ") ansi("underline", "NUM")) RS\
ins(2, "Specify the screen width for padding.") RS\
ins(1, ansi("bold", "-indent ") ansi("underline", "NUM")) RS\
ins(2, "Specify the size of indent (number of spaces).") RS\
ins(1, ansi("bold", "-theme ") ansi("underline", "FILENAME")) RS\
ins(2, "Specify the theme to use.") RS\
ins(1, ansi("bold", "-no-theme")) RS\
ins(2, "Do not use any other theme than default.") RS\
ins(1, ansi("bold", "-no-ansi")) RS\
ins(2, "Do not use ANSI escape codes.") RS\
ins(1, ansi("bold", "-no-autocorrect")) RS\
ins(2, "Do not autocorrect. (if defaulted by the translation engine)") RS\
ins(1, ansi("bold", "-no-bidi")) RS\
ins(2, "Do not convert bidirectional texts.") RS\
ins(1, ansi("bold", "-bidi")) RS\
ins(2, "Always convert bidirectional texts.") RS\
ins(1, ansi("bold", "-no-warn")) RS\
ins(2, "Do not write warning messages to stderr.") RS\
ins(1, ansi("bold", "-dump")) RS\
ins(2, "Print raw API response instead.") RS\
RS "Audio options:" RS\
ins(1, ansi("bold", "-p, -play")) RS\
ins(2, "Listen to the translation.") RS\
ins(1, ansi("bold", "-speak")) RS\
ins(2, "Listen to the original text.") RS\
ins(1, ansi("bold", "-n ") ansi("underline", "VOICE")\
", " ansi("bold", "-narrator ") ansi("underline", "VOICE")) RS\
ins(2, "Specify the narrator, and listen to the translation.") RS\
ins(1, ansi("bold", "-player ") ansi("underline", "PROGRAM")) RS\
ins(2, "Specify the audio player to use, and listen to the translation.") RS\
ins(1, ansi("bold", "-no-play")) RS\
ins(2, "Do not listen to the translation.") RS\
ins(1, ansi("bold", "-no-translate")) RS\
ins(2, "Do not translate anything when using -speak.") RS\
ins(1, ansi("bold", "-download-audio")) RS\
ins(2, "Download the audio to the current directory.") RS\
ins(1, ansi("bold", "-download-audio-as ") ansi("underline", "FILENAME")) RS\
ins(2, "Download the audio to the specified file.") RS\
RS "Terminal paging and browsing options:" RS\
ins(1, ansi("bold", "-v") ", " ansi("bold", "-view")) RS\
ins(2, "View the translation in a terminal pager.") RS\
ins(1, ansi("bold", "-pager ") ansi("underline", "PROGRAM")) RS\
ins(2, "Specify the terminal pager to use, and view the translation.") RS\
ins(1, ansi("bold", "-no-view") ", " ansi("bold", "-no-pager")) RS\
ins(2, "Do not view the translation in a terminal pager.") RS\
ins(1, ansi("bold", "-browser ") ansi("underline", "PROGRAM")) RS\
ins(2, "Specify the web browser to use.") RS\
ins(1, ansi("bold", "-no-browser")) RS\
ins(2, "Do not open the web browser.") RS\
RS "Networking options:" RS\
ins(1, ansi("bold", "-x ") ansi("underline", "HOST:PORT")\
", " ansi("bold", "-proxy ") ansi("underline", "HOST:PORT")) RS\
ins(2, "Use HTTP proxy on given port.") RS\
ins(1, ansi("bold", "-u ") ansi("underline", "STRING")\
", " ansi("bold", "-user-agent ") ansi("underline", "STRING")) RS\
ins(2, "Specify the User-Agent to identify as.") RS\
ins(1, ansi("bold", "-4") ", " ansi("bold", "-ipv4")\
", " ansi("bold", "-inet4-only")) RS\
ins(2, "Connect only to IPv4 addresses.") RS\
ins(1, ansi("bold", "-6") ", " ansi("bold", "-ipv6")\
", " ansi("bold", "-inet6-only")) RS\
ins(2, "Connect only to IPv6 addresses.") RS\
RS "Interactive shell options:" RS\
ins(1, ansi("bold", "-I") ", " ansi("bold", "-interactive") ", " ansi("bold", "-shell")) RS\
ins(2, "Start an interactive shell.") RS\
ins(1, ansi("bold", "-E") ", " ansi("bold", "-emacs")) RS\
ins(2, "Start the GNU Emacs front-end for an interactive shell.") RS\
ins(1, ansi("bold", "-no-rlwrap")) RS\
ins(2, "Do not invoke rlwrap when starting an interactive shell.") RS\
RS "I/O options:" RS\
ins(1, ansi("bold", "-i ") ansi("underline", "FILENAME")\
", " ansi("bold", "-input ") ansi("underline", "FILENAME")) RS\
ins(2, "Specify the input file.") RS\
ins(1, ansi("bold", "-o ") ansi("underline", "FILENAME")\
", " ansi("bold", "-output ") ansi("underline", "FILENAME")) RS\
ins(2, "Specify the output file.") RS\
RS "Language preference options:" RS\
ins(1, ansi("bold", "-hl ") ansi("underline", "CODE")\
", " ansi("bold", "-host ") ansi("underline", "CODE")) RS\
ins(2, "Specify the host (interface) language.") RS\
ins(1, ansi("bold", "-s ") ansi("underline", "CODES")\
", " ansi("bold", "-sl ") ansi("underline", "CODES")\
", " ansi("bold", "-source ") ansi("underline", "CODES")\
", " ansi("bold", "-from ") ansi("underline", "CODES")) RS\
ins(2, "Specify the source language(s), joined by '+'.") RS\
ins(1, ansi("bold", "-t ") ansi("underline", "CODES")\
", " ansi("bold", "-tl ") ansi("underline", "CODES")\
", " ansi("bold", "-target ") ansi("underline", "CODES")\
", " ansi("bold", "-to ") ansi("underline", "CODES")) RS\
ins(2, "Specify the target language(s), joined by '+'.") RS\
RS "Text preprocessing options:" RS\
ins(1, ansi("bold", "-j") ", " ansi("bold", "-join-sentence")) RS\
ins(2, "Treat all arguments as one single sentence.") RS\
RS "Other options:" RS\
ins(1, ansi("bold", "-no-init")) RS\
ins(2, "Do not load any initialization script.") RS\
RS "See the man page " Command "(1) for more information."
}
function showMan(    temp) {
if (ENVIRON["TRANS_MANPAGE"]) {
initPager()
Groff = detectProgram("groff", "--version")
if (Pager && Groff) {
temp = "echo -E \"${TRANS_MANPAGE}\""
temp = temp PIPE\
Groff " -Wall -mtty-char -mandoc -Tutf8 "\
"-rLL=" Option["width"] "n -rLT=" Option["width"] "n"
switch (Pager) {
case "less":
temp = temp PIPE\
Pager " -s -P\"\\ \\Manual page " Command "(1) line %lt (press h for help or q to quit)\""
break
case "most":
temp = temp PIPE Pager " -Cs"
break
default:
temp = temp PIPE Pager
}
system(temp)
return
}
}
if (fileExists(ENVIRON["TRANS_DIR"] "/man/" Command ".1"))
system("man " parameterize(ENVIRON["TRANS_DIR"] "/man/" Command ".1") SUPERR)
else if (system("man " Command SUPERR))
print getHelp()
}
function getReference(displayName,
code, col, cols, colNum, i, j, name, num, offset, r, rows, saveSortedIn,
t1, t2) {
num = 0
for (code in Locale) {
if (Locale[code]["supported-by"])
num++
}
colNum = (Option["width"] >= 104) ? 4 : 3
if (colNum == 4) {
rows = int(num / 4) + (num % 4 ? 1 : 0)
cols[0][0] = cols[1][0] = cols[2][0] = cols[3][0] = NULLSTR
} else {
rows = int(num / 3) + (num % 3 ? 1 : 0)
cols[0][0] = cols[1][0] = cols[2][0] = NULLSTR
}
i = 0
saveSortedIn = PROCINFO["sorted_in"]
PROCINFO["sorted_in"] = displayName == "endonym" ? "@ind_num_asc" :
"compName"
for (code in Locale) {
if (Locale[code]["supported-by"]) {
col = int(i / rows)
append(cols[col], code)
i++
}
}
PROCINFO["sorted_in"] = saveSortedIn
if (displayName == "endonym") {
if (colNum == 4) {
offset = int((Option["width"] - 104) / 4)
r = "┌" replicate("─", 25 + offset) "┬" replicate("─", 25 + offset)\
"┬" replicate("─", 25 + offset) "┬" replicate("─", 25 + offset) "┐" RS
for (i = 0; i < rows; i++) {
r = r "│"
for (j = 0; j < 4; j++) {
if (cols[j][i]) {
t1 = getDisplay(cols[j][i])
if (length(t1) > 17 + offset)
t1 = substr(t1, 1, 14 + offset) "..."
switch (cols[j][i]) {
case "sa":
t1 = sprintf(" %-"21+offset"s", t1)
break
case "he": case "dv":
t1 = sprintf(" %-"20+offset"s", t1)
break
case "bo": case "or": case "ur":
t1 = sprintf(" %-"19+offset"s", t1)
break
case "as": case "gom": case "mai":
case "gu": case "hi": case "bho":
case "ta": case "te": case "my":
case "ne": case "pa": case "km":
case "kn": case "yi": case "si":
t1 = sprintf(" %-"18+offset"s", t1)
break
case "lzh": case "yue":
t1 = sprintf(" %-"15+offset"s", t1)
break
case "ja": case "ko":
t1 = sprintf(" %-"14+offset"s", t1)
break
case "zh-CN": case "zh-TW":
t1 = sprintf(" %-"13+offset"s", t1)
break
default:
if (length(t1) <= 17+offset)
t1 = sprintf(" %-"17+offset"s", t1)
}
switch (length(cols[j][i])) {
case 1: case 2: case 3: case 4:
t2 = sprintf("- %s │", ansi("bold", sprintf("%4s", cols[j][i])))
break
case 5:
t2 = sprintf("- %s│", ansi("bold", cols[j][i]))
break
case 6:
t2 = sprintf("-%s│", ansi("bold", cols[j][i]))
break
case 7:
t2 = sprintf("-%s", ansi("bold", cols[j][i]))
break
default:
t2 = ansi("bold", cols[j][i])
}
r = r t1 t2
} else
r = r sprintf("%"25+offset"s│", NULLSTR)
}
r = r RS
}
r = r "└" replicate("─", 25 + offset) "┴" replicate("─", 25 + offset)\
"┴" replicate("─", 25 + offset) "┴" replicate("─", 25 + offset) "┘"
} else {
r = "┌" replicate("─", 25) "┬" replicate("─", 25) "┬" replicate("─", 25) "┐" RS
for (i = 0; i < rows; i++) {
r = r "│"
for (j = 0; j < 3; j++) {
if (cols[j][i]) {
t1 = getDisplay(cols[j][i])
if (length(t1) > 17)
t1 = substr(t1, 1, 14) "..."
switch (cols[j][i]) {
case "sa":
t1 = sprintf(" %-21s", t1)
break
case "he": case "dv":
t1 = sprintf(" %-20s", t1)
break
case "bo": case "or": case "ur":
t1 = sprintf(" %-19s", t1)
break
case "as": case "gom": case "mai":
case "gu": case "hi": case "bho":
case "ta": case "te": case "my":
case "ne": case "pa": case "km":
case "kn": case "yi": case "si":
t1 = sprintf(" %-18s", t1)
break
case "lzh": case "yue":
t1 = sprintf(" %-15s", t1)
break
case "ja": case "ko":
t1 = sprintf(" %-14s", t1)
break
case "zh-CN": case "zh-TW":
t1 = sprintf(" %-13s", t1)
break
default:
if (length(t1) <= 17)
t1 = sprintf(" %-17s", t1)
}
switch (length(cols[j][i])) {
case 1: case 2: case 3: case 4:
t2 = sprintf("- %s │", ansi("bold", sprintf("%4s", cols[j][i])))
break
case 5:
t2 = sprintf("- %s│", ansi("bold", cols[j][i]))
break
case 6:
t2 = sprintf("-%s│", ansi("bold", cols[j][i]))
break
case 7:
t2 = sprintf("-%s", ansi("bold", cols[j][i]))
break
default:
t2 = ansi("bold", cols[j][i])
}
r = r t1 t2
} else
r = r sprintf("%25s│", NULLSTR)
}
r = r RS
}
r = r "└" replicate("─", 25) "┴" replicate("─", 25) "┴" replicate("─", 25) "┘"
}
} else {
if (colNum == 4) {
offset = int((Option["width"] - 104) / 4)
r = "┌" replicate("─", 25 + offset) "┬" replicate("─", 25 + offset)\
"┬" replicate("─", 25 + offset) "┬" replicate("─", 25 + offset) "┐" RS
for (i = 0; i < rows; i++) {
r = r "│"
for (j = 0; j < 4; j++) {
if (cols[j][i]) {
t1 = getName(cols[j][i])
if (length(t1) > 17 + offset)
t1 = substr(t1, 1, 14 + offset) "..."
t1 = sprintf(" %-"17+offset"s", t1)
switch (length(cols[j][i])) {
case 1: case 2: case 3: case 4:
t2 = sprintf("- %s │", ansi("bold", sprintf("%4s", cols[j][i])))
break
case 5:
t2 = sprintf("- %s│", ansi("bold", cols[j][i]))
break
case 6:
t2 = sprintf("-%s│", ansi("bold", cols[j][i]))
break
case 7:
t2 = sprintf("-%s", ansi("bold", cols[j][i]))
break
default:
t2 = ansi("bold", cols[j][i])
}
r = r t1 t2
} else
r = r sprintf("%"25+offset"s│", NULLSTR)
}
r = r RS
}
r = r "└" replicate("─", 25 + offset) "┴" replicate("─", 25 + offset)\
"┴" replicate("─", 25 + offset) "┴" replicate("─", 25 + offset) "┘"
} else {
r = "┌" replicate("─", 25) "┬" replicate("─", 25) "┬" replicate("─", 25) "┐" RS
for (i = 0; i < rows; i++) {
r = r "│"
for (j = 0; j < 3; j++) {
if (cols[j][i]) {
t1 = getName(cols[j][i])
if (length(t1) > 17)
t1 = substr(t1, 1, 14) "..."
t1 = sprintf(" %-17s", t1)
switch (length(cols[j][i])) {
case 1: case 2: case 3: case 4:
t2 = sprintf("- %s │", ansi("bold", sprintf("%4s", cols[j][i])))
break
case 5:
t2 = sprintf("- %s│", ansi("bold", cols[j][i]))
break
case 6:
t2 = sprintf("-%s│", ansi("bold", cols[j][i]))
break
case 7:
t2 = sprintf("-%s", ansi("bold", cols[j][i]))
break
default:
t2 = ansi("bold", cols[j][i])
}
r = r t1 t2
} else
r = r sprintf("%25s│", NULLSTR)
}
r = r RS
}
r = r "└" replicate("─", 25) "┴" replicate("─", 25) "┴" replicate("─", 25) "┘"
}
}
return r
}
function getLanguage(codes,    code, i, r, saveSortedIn) {
r = NULLSTR
if (!isarray(codes))
r = getDetails(codes)
else if (anything(codes)) {
saveSortedIn = PROCINFO["sorted_in"]
PROCINFO["sorted_in"] = "@ind_num_asc"
for (i in codes)
r = (r ? r RS prettify("target-seperator", replicate(Option["chr-target-seperator"], Option["width"])) RS\
: r) getDetails(codes[i])
PROCINFO["sorted_in"] = saveSortedIn
} else
r = getDetails(Option["hl"])
return r
}
function tokenize(returnTokens, string,
delimiters,
newlines,
quotes,
escapeChars,
leftBlockComments,
rightBlockComments,
lineComments,
reservedOperators,
reservedPatterns,
blockCommenting,
c,
currentToken,
escaping,
i,
lineCommenting,
p,
quoting,
r,
s,
tempGroup,
tempPattern,
tempString) {
if (!delimiters[0]) {
delimiters[0] = " "
delimiters[1] = "\t"
delimiters[2] = "\v"
}
if (!newlines[0]) {
newlines[0] = "\n"
newlines[1] = "\r"
}
if (!quotes[0]) {
quotes[0] = "\""
}
if (!escapeChars[0]) {
escapeChars[0] = "\\"
}
if (!leftBlockComments[0]) {
leftBlockComments[0] = "#|"
leftBlockComments[1] = "/*"
leftBlockComments[2] = "(*"
}
if (!rightBlockComments[0]) {
rightBlockComments[0] = "|#"
rightBlockComments[1] = "*/"
rightBlockComments[2] = "*)"
}
if (!lineComments[0]) {
lineComments[0] = ";"
lineComments[1] = "//"
lineComments[2] = "#"
}
if (!reservedOperators[0]) {
reservedOperators[0] = "("
reservedOperators[1] = ")"
reservedOperators[2] = "["
reservedOperators[3] = "]"
reservedOperators[4] = "{"
reservedOperators[5] = "}"
reservedOperators[6] = ","
}
if (!reservedPatterns[0]) {
reservedPatterns[0] = "[+-]?((0|[1-9][0-9]*)|[.][0-9]*|(0|[1-9][0-9]*)[.][0-9]*)([Ee][+-]?[0-9]+)?"
reservedPatterns[1] = "[+-]?0[0-7]+([.][0-7]*)?"
reservedPatterns[2] = "[+-]?0[Xx][0-9A-Fa-f]+([.][0-9A-Fa-f]*)?"
}
split(string, s, "")
currentToken = ""
quoting = escaping = blockCommenting = lineCommenting = 0
p = 0
i = 1
while (i <= length(s)) {
c = s[i]
r = substr(string, i)
if (blockCommenting) {
if (tempString = startsWithAny(r, rightBlockComments))
blockCommenting = 0
i++
} else if (lineCommenting) {
if (belongsTo(c, newlines))
lineCommenting = 0
i++
} else if (quoting) {
currentToken = currentToken c
if (escaping) {
escaping = 0
} else {
if (belongsTo(c, quotes)) {
if (currentToken) {
returnTokens[p++] = currentToken
currentToken = ""
}
quoting = 0
} else if (belongsTo(c, escapeChars)) {
escaping = 1
} else {
}
}
i++
} else {
if (belongsTo(c, delimiters) || belongsTo(c, newlines)) {
if (currentToken) {
returnTokens[p++] = currentToken
currentToken = ""
}
i++
} else if (belongsTo(c, quotes)) {
if (currentToken) {
returnTokens[p++] = currentToken
}
currentToken = c
quoting = 1
i++
} else if (tempString = startsWithAny(r, leftBlockComments)) {
if (currentToken) {
returnTokens[p++] = currentToken
currentToken = ""
}
blockCommenting = 1
i += length(tempString)
} else if (tempString = startsWithAny(r, lineComments)) {
if (currentToken) {
returnTokens[p++] = currentToken
currentToken = ""
}
lineCommenting = 1
i += length(tempString)
} else if (tempString = startsWithAny(r, reservedOperators)) {
if (currentToken) {
returnTokens[p++] = currentToken
currentToken = ""
}
returnTokens[p++] = tempString
i += length(tempString)
} else if (tempPattern = matchesAny(r, reservedPatterns)) {
if (currentToken) {
returnTokens[p++] = currentToken
currentToken = ""
}
match(r, "^" tempPattern, tempGroup)
returnTokens[p++] = tempGroup[0]
i += length(tempGroup[0])
} else {
currentToken = currentToken c
i++
}
}
}
if (currentToken)
returnTokens[p++] = currentToken
}
function parseJsonArray(returnAST, tokens,
leftBrackets,
rightBrackets,
separators,
i, j, key, p, stack, token) {
if (!leftBrackets[0]) {
leftBrackets[0] = "("
leftBrackets[1] = "["
leftBrackets[2] = "{"
}
if (!rightBrackets[0]) {
rightBrackets[0] = ")"
rightBrackets[1] = "]"
rightBrackets[2] = "}"
}
if (!separators[0]) {
separators[0] = ","
}
stack[p = 0] = 0
for (i = 0; i < length(tokens); i++) {
token = tokens[i]
if (belongsTo(token, leftBrackets))
stack[++p] = 0
else if (belongsTo(token, rightBrackets))
--p
else if (belongsTo(token, separators))
stack[p]++
else {
key = stack[0]
for (j = 1; j <= p; j++)
key = key SUBSEP stack[j]
returnAST[key] = token
}
}
}
function parseJson(returnAST, tokens,
arrayStartTokens, arrayEndTokens,
objectStartTokens, objectEndTokens,
commas, colons,
flag, i, j, key, name, p, stack, token) {
if (!arrayStartTokens[0])  arrayStartTokens[0]  = "["
if (!arrayEndTokens[0])    arrayEndTokens[0]    = "]"
if (!objectStartTokens[0]) objectStartTokens[0] = "{"
if (!objectEndTokens[0])   objectEndTokens[0]   = "}"
if (!commas[0])            commas[0]            = ","
if (!colons[0])            colons[0]            = ":"
stack[p = 0] = 0
flag = 0
for (i = 0; i < length(tokens); i++) {
token = tokens[i]
if (belongsTo(token, arrayStartTokens)) {
stack[++p] = 0
} else if (belongsTo(token, objectStartTokens)) {
stack[++p] = NULLSTR
flag = 0
} else if (belongsTo(token, objectEndTokens) ||
belongsTo(token, arrayEndTokens)) {
--p
} else if (belongsTo(token, commas)) {
if (isnum(stack[p]))
stack[p]++
else
flag = 0
} else if (belongsTo(token, colons)) {
flag = 1
} else if (isnum(stack[p]) || flag) {
key = stack[0]
for (j = 1; j <= p; j++)
key = key SUBSEP stack[j]
returnAST[key] = token
flag = 0
} else {
stack[p] = unparameterize(token)
}
}
}
function parseList(returnAST, tokens,
leftBrackets,
rightBrackets,
separators,
i, j, key, p, stack, token) {
if (!leftBrackets[0]) {
leftBrackets[0] = "("
leftBrackets[1] = "["
leftBrackets[2] = "{"
}
if (!rightBrackets[0]) {
rightBrackets[0] = ")"
rightBrackets[1] = "]"
rightBrackets[2] = "}"
}
if (!separators[0]) {
separators[0] = ","
}
stack[p = 0] = 0
for (i = 0; i < length(tokens); i++) {
token = tokens[i]
if (belongsTo(token, leftBrackets)) {
stack[++p] = 0
} else if (belongsTo(token, rightBrackets)) {
stack[--p]++
} else if (belongsTo(token, separators)) {
} else {
key = NULLSTR
if (p > 0) {
for (j = 0; j < p - 1; j++)
key = key SUBSEP stack[j]
returnAST[key][stack[p - 1]] = NULLSTR
key = key SUBSEP stack[p - 1]
}
returnAST[key][stack[p]] = token
stack[p]++
}
}
}
function prettify(name, string,    i, temp) {
temp = string
if ("sgr-" name in Option)
if (isarray(Option["sgr-" name]))
for (i in Option["sgr-" name])
temp = ansi(Option["sgr-" name][i], temp)
else
temp = ansi(Option["sgr-" name], temp)
return temp
}
function randomColor(    i) {
i = int(5 * rand())
switch (i) {
case 0: return "green"
case 1: return "yellow"
case 2: return "blue"
case 3: return "magenta"
case 4: return "cyan"
default: return "default"
}
}
function setRandomTheme(    i, n, temp) {
srand(systime())
for (i = 0; i < 3; i++) {
do temp = randomColor(); while (belongsTo(temp, n))
n[i] = temp
}
Option["sgr-prompt-message"] = Option["sgr-languages"] = n[0]
Option["sgr-original-dictionary-detailed-word-class"][1] = n[0]
Option["sgr-original-dictionary-detailed-word-class"][2] = "bold"
Option["sgr-original-dictionary-synonyms"] = n[0]
Option["sgr-original-dictionary-synonyms-word-class"][1] = n[0]
Option["sgr-original-dictionary-synonyms-word-class"][2] = "bold"
Option["sgr-original-dictionary-examples"] = n[0]
Option["sgr-original-dictionary-see-also"] = n[0]
Option["sgr-dictionary-word-class"][1] = n[0]
Option["sgr-dictionary-word-class"][2] = "bold"
Option["sgr-original"][1] = Option["sgr-original-phonetics"][1] = n[1]
Option["sgr-original"][2] = Option["sgr-original-phonetics"][2] = "bold"
Option["sgr-prompt-message-original"][1] = n[1]
Option["sgr-prompt-message-original"][2] = "bold"
Option["sgr-languages-sl"] = n[1]
Option["sgr-original-dictionary-detailed-explanation"][1] = n[1]
Option["sgr-original-dictionary-detailed-explanation"][2] = "bold"
Option["sgr-original-dictionary-detailed-example"] = n[1]
Option["sgr-original-dictionary-detailed-synonyms"] = n[1]
Option["sgr-original-dictionary-detailed-synonyms-item"][1] = n[1]
Option["sgr-original-dictionary-detailed-synonyms-item"][2] = "bold"
Option["sgr-original-dictionary-synonyms-synonyms"] = n[1]
Option["sgr-original-dictionary-synonyms-synonyms-item"][1] = n[1]
Option["sgr-original-dictionary-synonyms-synonyms-item"][2] = "bold"
Option["sgr-original-dictionary-examples-example"] = n[1]
Option["sgr-original-dictionary-examples-original"][1] = n[1]
Option["sgr-original-dictionary-examples-original"][2] = "bold"
Option["sgr-original-dictionary-examples-original"][3] = "underline"
Option["sgr-original-dictionary-see-also-phrases"] = n[1]
Option["sgr-original-dictionary-see-also-phrases-item"][1] = n[1]
Option["sgr-original-dictionary-see-also-phrases-item"][2] = "bold"
Option["sgr-dictionary-explanation"] = n[1]
Option["sgr-dictionary-explanation-item"][1] = n[1]
Option["sgr-dictionary-explanation-item"][2] = "bold"
Option["sgr-alternatives-original"][1] = n[1]
Option["sgr-alternatives-original"][2] = "bold"
Option["sgr-translation"][1] = Option["sgr-translation-phonetics"][1] = n[2]
Option["sgr-translation"][2] = Option["sgr-translation-phonetics"][2] = "bold"
Option["sgr-languages-tl"] = n[2]
Option["sgr-dictionary-word"][1] = n[2]
Option["sgr-dictionary-word"][2] = "bold"
Option["sgr-alternatives-translations"] = n[2]
Option["sgr-alternatives-translations-item"][1] = n[2]
Option["sgr-alternatives-translations-item"][2] = "bold"
Option["sgr-brief-translation"][1] = Option["sgr-brief-translation-phonetics"][1] = n[2]
Option["sgr-brief-translation"][2] = Option["sgr-brief-translation-phonetics"][2] = "bold"
Option["fmt-welcome-message"] = Name
Option["sgr-welcome-message"][1] = n[0]
Option["sgr-welcome-message"][2] = "bold"
Option["fmt-welcome-submessage"] = "(:q to quit)"
Option["sgr-welcome-submessage"] = n[0]
Option["fmt-prompt"] = "%s> "
Option["sgr-prompt"][1] = n[1]
Option["sgr-prompt"][2] = "bold"
}
function setDefaultTheme() {
Option["sgr-translation"] = Option["sgr-translation-phonetics"] = "bold"
Option["sgr-prompt-message-original"] = "underline"
Option["sgr-languages-sl"] = "underline"
Option["sgr-languages-tl"] = "bold"
Option["sgr-original-dictionary-detailed-explanation"] = "bold"
Option["sgr-original-dictionary-detailed-synonyms-item"] = "bold"
Option["sgr-original-dictionary-synonyms-synonyms-item"] = "bold"
Option["sgr-original-dictionary-examples-original"][1] = "bold"
Option["sgr-original-dictionary-examples-original"][2] = "underline"
Option["sgr-original-dictionary-see-also-phrases-item"] = "bold"
Option["sgr-dictionary-word"] = "bold"
Option["sgr-alternatives-original"] = "underline"
Option["sgr-alternatives-translations-item"] = "bold"
Option["fmt-welcome-message"] = Name
Option["sgr-welcome-message"] = "bold"
Option["fmt-welcome-submessage"] = "(:q to quit)"
Option["fmt-prompt"] = "%s> "
Option["sgr-prompt"] = "bold"
}
function setTheme(    file, line, script) {
if (Option["theme"] && Option["theme"] != "default"\
&& Option["theme"] != "none" && Option["theme"] != "random") {
file = Option["theme"]
if (!fileExists(file)) {
file = ENVIRON["HOME"] "/.translate-shell/" Option["theme"]
if (!fileExists(file)) {
file = ENVIRON["HOME"] "/.config/translate-shell/" Option["theme"]
if (!fileExists(file)) return
}
}
}
if (file && fileExists(file)) {
script = NULLSTR
while (getline line < file)
script = script "\n" line
loadOptions(script)
} else if (Option["theme"] == "none")
;
else if (Option["theme"] == "random")
setRandomTheme()
else
setDefaultTheme()
}
function provides(engineName) {
Translator[tolower(engineName)] = TRUE
}
function engineMethod(methodName,    engine, translator) {
if (!Translator[Option["engine"]]) {
engine = tolower(Option["engine"])
if (!Translator[engine])
for (translator in Translator)
if (Translator[translator] &&
translator ~ "^"engine) {
engine = translator
break
}
if (!Translator[engine]) {
e("[ERROR] Translator not found: " Option["engine"] "\n"\
"        Run '-list-engines / -S' to see a list of available engines.")
exit 1
}
Option["engine"] = engine
}
return Option["engine"] methodName
}
function initAudioPlayer() {
AudioPlayer = !system("mpv" SUPOUT SUPERR) ?
"mpv --no-config" :
(!system("mplayer" SUPOUT SUPERR) ?
"mplayer" :
(!system("mpg123 --version" SUPOUT SUPERR) ?
"mpg123" :
""))
}
function initSpeechSynthesizer() {
SpeechSynthesizer = !system("say ''" SUPOUT SUPERR) ?
"say" :
(!system("espeak ''" SUPOUT SUPERR) ?
"espeak" :
"")
}
function initPager() {
Pager = !system("less -V" SUPOUT SUPERR) ?
"less" :
(!system("more -V" SUPOUT SUPERR) ?
"more" :
(!system("most" SUPOUT SUPERR) ?
"most" :
""))
}
function initHttpService(    inet) {
_Init()
inet = "inet"
if (Option["ip-version"])
inet = inet Option["ip-version"]
if (Option["proxy"]) {
match(Option["proxy"], /^(http:\/*)?(([^:]+):([^@]+)@)?([^\/]*):([^\/:]*)/, HttpProxySpec)
HttpAuthUser = HttpProxySpec[3]
HttpAuthPass = HttpProxySpec[4]
HttpAuthCredentials = base64(unquote(HttpAuthUser) ":" HttpAuthPass)
HttpService = "/" inet "/tcp/0/" HttpProxySpec[5] "/" HttpProxySpec[6]
HttpPathPrefix = HttpProtocol HttpHost
} else {
HttpService = "/" inet "/tcp/0/" HttpHost "/" HttpPort
HttpPathPrefix = ""
}
PROCINFO[HttpService, "READ_TIMEOUT"] = 2000
}
function preprocess(text) {
return quote(text)
}
function preprocessByDump(text,    arr, i, len, temp) {
len = dumpX(text, arr)
temp = ""
for (i = 1; i <= len; i++)
temp = temp "%" arr[i]
return temp
}
function postprocess(text) {
text = gensub(/ ([.,;:?!"])/, "\\1", "g", text)
text = gensub(/(["]) /, "\\1", "g", text)
return text
}
function getResponse(text, sl, tl, hl,
content, header, isBody, url, group, status, location) {
url = _RequestUrl(text, sl, tl, hl)
header = "GET " url " HTTP/1.1\r\n"\
"Host: " HttpHost "\r\n"\
"Connection: close\r\n"
if (Option["user-agent"])
header = header "User-Agent: " Option["user-agent"] "\r\n"
if (Cookie)
header = header "Cookie: " Cookie "\r\n"
if (HttpAuthUser && HttpAuthPass)
header = header "Proxy-Authorization: Basic " HttpAuthCredentials "\r\n"
l(header)
content = NULLSTR; isBody = 0
while (1) {
print (header "\r\n") |& HttpService
while ((HttpService |& getline) > 0) {
if (isBody)
content = content ? content "\n" $0 : $0
else if (length($0) <= 1)
isBody = 1
else {
match($0, /^HTTP[^ ]* ([^ ]*)/, group)
if (RSTART) status = group[1]
match($0, /^Location: (.*)/, group)
if (RSTART) location = squeeze(group[1])
}
l(sprintf("%4s bytes > %s", length($0), $0))
}
close(HttpService)
if (ERRNO == "Connection timed out") {
w("[WARNING] " ERRNO ". Retrying IPv4 connection.")
Option["ip-version"] = 4
initHttpService()
PROCINFO[HttpService, "READ_TIMEOUT"] = 0
ERRNO = ""
} else
break
}
if ((status == "301" || status == "302") && location) {
content = curl(location)
} else if (status == "429") {
e("[ERROR] " ucfirst(Option["engine"]) " did not return results because rate limiting is in effect")
assert(false, "[ERROR] Rate limiting")
} else if (status >= "400") {
e("[ERROR] " ucfirst(Option["engine"]) " returned an error response. HTTP status code: " status)
assert(false, "[ERROR] Other HTTP error")
}
return assert(content, "[ERROR] Null response.")
}
function postResponse(text, sl, tl, hl, type,
content, contentLength, contentType, group,
header, isBody, reqBody, url, status, location, userAgent) {
url = _PostRequestUrl(text, sl, tl, hl, type)
contentType = _PostRequestContentType(text, sl, tl, hl, type)
userAgent = _PostRequestUserAgent(text, sl, tl, hl, type)
reqBody = _PostRequestBody(text, sl, tl, hl, type)
if (DumpContentengths[reqBody])
contentLength = DumpContentengths[reqBody]
else
contentLength = DumpContentengths[reqBody] = dump(reqBody, group)
header = "POST " url " HTTP/1.1\r\n"\
"Host: " HttpHost "\r\n"\
"Connection: close\r\n"\
"Content-Length: " contentLength "\r\n"\
"Content-Type: " contentType "\r\n"
if (Option["user-agent"] && !userAgent)
header = header "User-Agent: " Option["user-agent"] "\r\n"
if (userAgent)
header = header "User-Agent: " userAgent "\r\n"
if (Cookie)
header = header "Cookie: " Cookie "\r\n"
if (HttpAuthUser && HttpAuthPass)
header = header "Proxy-Authorization: Basic " HttpAuthCredentials "\r\n"
l(header)
content = NULLSTR; isBody = 0
while (1) {
print (header "\r\n" reqBody) |& HttpService
while ((HttpService |& getline) > 0) {
if (isBody)
content = content ? content "\n" $0 : $0
else if (length($0) <= 1)
isBody = 1
else {
match($0, /^HTTP[^ ]* ([^ ]*)/, group)
if (RSTART) status = group[1]
match($0, /^Location: (.*)/, group)
if (RSTART) location = squeeze(group[1])
}
l(sprintf("%4s bytes > %s", length($0), $0))
}
close(HttpService)
if (ERRNO == "Connection timed out") {
w("[WARNING] " ERRNO ". Retrying IPv4 connection.")
Option["ip-version"] = 4
initHttpService()
PROCINFO[HttpService, "READ_TIMEOUT"] = 0
ERRNO = ""
} else
break
}
if (status == "404") {
e("[ERROR] 404 Not Found")
exit 1
}
if ((status == "301" || status == "302") && location) {
url = "https" substr(url, 5)
content = curlPost(url, reqBody)
} else if (status == "429") {
e("[ERROR] " ucfirst(Option["engine"]) " did not return results because rate limiting is in effect")
assert(false, "[ERROR] Rate limiting")
} else if (status >= "400") {
e("[ERROR] " ucfirst(Option["engine"]) " returned an error response. HTTP status code: " status)
assert(false, "[ERROR] Other HTTP error")
}
return content
}
function p(string) {
if (Option["view"]) {
print string | Option["pager"] (Option["pager"] == "less" ? " -R" : "")
close(Option["pager"] (Option["pager"] == "less" ? " -R" : ""))
} else
print string > Option["output"]
}
function play(text, tl,    url, status) {
url = _TTSUrl(text, tl)
status = system(Option["player"] " " parameterize(url) SUPOUT SUPERR)
if (status)
w("Voice output isn't available for " getName(tl))
return status
}
function download_audio(text, tl,    url, output) {
url = _TTSUrl(text, tl)
if (Option["download-audio-as"])
output = Option["download-audio-as"]
else
output = text " [" Option["engine"] "] (" Option["narrator"] ").ts"
if (url ~ /^\//)
system("mv -- " parameterize(url) " " parameterize(output))
else
curl(url, output)
}
function getTranslation(text, sl, tl, hl,
isVerbose, toSpeech, returnPlaylist, returnIl) {
return _Translate(text, sl, tl, hl,
isVerbose, toSpeech, returnPlaylist, returnIl)
}
function fileTranslation(uri,    group, temp1, temp2) {
temp1 = Option["input"]
temp2 = Option["verbose"]
match(uri, /^file:\/\/(.*)/, group)
Option["input"] = group[1]
Option["verbose"] = 0
translateMain()
Option["input"] = temp1
Option["verbose"] = temp2
}
function webTranslation(uri, sl, tl, hl,    temp) {
temp = _WebTranslateUrl(uri, sl, tl, hl)
if (temp) {
p(temp)
if (Option["browser"] != NONE)
system(Option["browser"] " " parameterize(temp) SUPOUT SUPERR)
}
}
function translate(text, inline,
i, j, playlist, il, saveSortedIn) {
if (!getCode(Option["hl"])) {
w("[WARNING] Unknown language code: " Option["hl"] ", fallback to English: en")
Option["hl"] = "en"
} else if (isRTL(Option["hl"])) {
if (!FriBidi)
w("[WARNING] " getName(Option["hl"]) " is a right-to-left language, but FriBidi is not found.")
}
if (!getCode(Option["sl"])) {
w("[WARNING] Unknown source language code: " Option["sl"])
} else if (isRTL(Option["sl"])) {
if (!FriBidi)
w("[WARNING] " getName(Option["sl"]) " is a right-to-left language, but FriBidi is not found.")
}
saveSortedIn = PROCINFO["sorted_in"]
PROCINFO["sorted_in"] = "@ind_num_asc"
for (i in Option["tl"]) {
if (!Option["interactive"])
if (Option["verbose"] && i > 1)
p(prettify("target-seperator", replicate(Option["chr-target-seperator"], Option["width"])))
if (inline &&
startsWithAny(text, UriSchemes) == "file://") {
fileTranslation(text)
} else if (inline &&
startsWithAny(text, UriSchemes) == "http://" ||
startsWithAny(text, UriSchemes) == "https://") {
webTranslation(text, Option["sl"], Option["tl"][i], Option["hl"])
} else {
if (!Option["no-translate"])
p(getTranslation(text, Option["sl"], Option["tl"][i], Option["hl"], Option["verbose"], Option["play"] || Option["download-audio"], playlist, il))
else
il[0] = Option["sl"] == "auto" ? "en" : Option["sl"]
if (Option["play"] == 1) {
if (Option["player"])
for (j in playlist)
play(playlist[j]["text"], playlist[j]["tl"])
else if (SpeechSynthesizer)
for (j in playlist)
print playlist[j]["text"] | SpeechSynthesizer
} else if (Option["play"] == 2) {
if (Option["player"])
play(text, il[0])
else if (SpeechSynthesizer)
print text | SpeechSynthesizer
}
if (Option["download-audio"] == 1) {
if (Option["play"] != 2 && !Option["no-translate"])
download_audio(playlist[length(playlist) - 1]["text"],\
playlist[length(playlist) - 1]["tl"])
else
download_audio(text, il[0])
}
}
}
PROCINFO["sorted_in"] = saveSortedIn
}
function translates(text, inline,
i) {
saveSortedIn = PROCINFO["sorted_in"]
PROCINFO["sorted_in"] = "@ind_num_asc"
for (i in Option["sls"]) {
if (!Option["interactive"])
if (Option["verbose"] && i > 1)
p(prettify("target-seperator", replicate(Option["chr-target-seperator"], Option["width"])))
Option["sl"] = Option["sls"][i]
translate(text, inline)
}
PROCINFO["sorted_in"] = saveSortedIn
}
function translateMain(    i, line) {
if (Option["interactive"])
prompt()
if (Option["input"] == STDIN || fileExists(Option["input"])) {
i = 0
while (getline line < Option["input"])
if (line) {
if (!Option["interactive"])
if (Option["verbose"] && i++ > 0)
p(prettify("source-seperator",
replicate(Option["chr-source-seperator"],
Option["width"])))
if (Option["interactive"])
repl(line)
else
translates(line)
} else {
if (!Option["interactive"])
if (!Option["verbose"])
p(line)
}
} else
e("[ERROR] File not found: " Option["input"])
}
function _Init(    vm) {
vm = engineMethod("Init")
return @vm()
}
function _RequestUrl(text, sl, tl, hl,    vm) {
vm = engineMethod("RequestUrl")
return @vm(text, sl, tl, hl)
}
function _PostRequestUrl(text, sl, tl, hl, type,    vm) {
vm = engineMethod("PostRequestUrl")
return @vm(text, sl, tl, hl, type)
}
function _PostRequestContentType(text, sl, tl, hl, type,    vm) {
vm = engineMethod("PostRequestContentType")
return @vm(text, sl, tl, hl, type)
}
function _PostRequestUserAgent(text, sl, tl, hl, type,    vm) {
vm = engineMethod("PostRequestUserAgent")
return @vm(text, sl, tl, hl, type)
}
function _PostRequestBody(text, sl, tl, hl, type,    vm) {
vm = engineMethod("PostRequestBody")
return @vm(text, sl, tl, hl, type)
}
function _TTSUrl(text, tl,    vm) {
vm = engineMethod("TTSUrl")
return @vm(text, tl)
}
function _WebTranslateUrl(uri, sl, tl, hl,    vm) {
vm = engineMethod("WebTranslateUrl")
return @vm(uri, sl, tl, hl)
}
function _Translate(text, sl, tl, hl,
isVerbose, toSpeech, returnPlaylist, returnIl,
vm) {
vm = engineMethod("Translate")
return @vm(text, sl, tl, hl,
isVerbose, toSpeech, returnPlaylist, returnIl)
}
BEGIN { provides("google") }
function genRL(a, x,
b, c, d, i, y) {
tokenize(y, x)
parseList(b, y)
i = SUBSEP 0
for (c = 0; c < length(b[i]) - 2; c += 3) {
d = b[i][c + 2]
d = d >= 97 ? d - 87 :
d - 48
d = b[i][c + 1] == 43 ? rshift(a, d) : lshift(a, d)
a = b[i][c] == 43 ? and(a + d, 4294967295) : xor(a, d)
}
return a
}
function genTK(text,
a, d, dLen, e, tkk, ub, vb) {
if (TK[text]) return TK[text]
tkk = systime() / 3600
ub = "[43,45,51,94,43,98,43,45,102]"
vb = "[43,45,97,94,43,54]"
dLen = dump(text, d)
a = tkk
for (e = 1; e <= dLen; e++)
a = genRL(a + d[e], vb)
a = genRL(a, ub)
0 > a && (a = and(a, 2147483647) + 2147483648)
a %= 1e6
TK[text] = a "." xor(a, tkk)
l(text, "text")
l(tkk, "tkk")
l(TK[text], "tk")
return TK[text]
}
function googleInit() {
HttpProtocol = "http://"
HttpHost = "translate.googleapis.com"
HttpPort = 80
}
function googleRequestUrl(text, sl, tl, hl,    qc) {
qc = Option["no-autocorrect"] ? "qc" : "qca";
return HttpPathPrefix "/translate_a/single?client=gtx"\
"&ie=UTF-8&oe=UTF-8"\
"&dt=bd&dt=ex&dt=ld&dt=md&dt=rw&dt=rm&dt=ss&dt=t&dt=at&dt=gt"\
"&dt=" qc "&sl=" sl "&tl=" tl "&hl=" hl\
"&q=" preprocessByDump(text)
}
function googleTTSUrl(text, tl) {
return HttpProtocol HttpHost "/translate_tts?ie=UTF-8&client=gtx"\
"&tl=" tl "&q=" preprocessByDump(text)
}
function googleWebTranslateUrl(uri, sl, tl, hl) {
return "https://translate.google.com/translate?"\
"hl=" hl "&sl=" sl "&tl=" tl "&u=" uri
}
function googleTranslate(text, sl, tl, hl,
isVerbose, toSpeech, returnPlaylist, returnIl,
r,
content, tokens, ast,
_sl, _tl, _hl, il, ils, isPhonetic,
article, example, explanation, ref, word,
translation, translations, phonetics,
wordClasses, words, segments, altTranslations,
original, oPhonetics, oWordClasses, oWords,
oRefs, oSynonymClasses, oSynonyms,
oExamples, oSeeAlso,
wShowOriginal, wShowOriginalPhonetics,
wShowTranslation, wShowTranslationPhonetics,
wShowPromptMessage, wShowLanguages,
wShowOriginalDictionary, wShowDictionary,
wShowAlternatives,
genderedTrans, hasWordClasses, hasAltTranslations,
i, j, k, group, temp, saveSortedIn) {
isPhonetic = match(tl, /^@/)
tl = substr(tl, 1 + isPhonetic)
if (!getCode(tl)) {
w("[WARNING] Unknown target language code: " tl)
} else if (isRTL(tl)) {
if (!FriBidi)
w("[WARNING] " getName(tl) " is a right-to-left language, but FriBidi is not found.")
}
_sl = getCode(sl); if (!_sl) _sl = sl
_tl = getCode(tl); if (!_tl) _tl = tl
_hl = getCode(hl); if (!_hl) _hl = hl
content = getResponse(text, _sl, _tl, _hl)
if (Option["dump"])
return content
tokenize(tokens, content)
parseJsonArray(ast, tokens)
l(content, "content", 1, 1)
l(tokens, "tokens", 1, 0, 1)
l(ast, "ast")
if (!isarray(ast) || !anything(ast)) {
e("[ERROR] Oops! Something went wrong and I can't translate it for you :(")
ExitCode = 1
return
}
saveSortedIn = PROCINFO["sorted_in"]
PROCINFO["sorted_in"] = "compareByIndexFields"
for (i in ast) {
if (ast[i] == "null") continue
if (i ~ "^0" SUBSEP "0" SUBSEP "[[:digit:]]+" SUBSEP "0$")
append(translations, literal(ast[i]))
if (i ~ "^0" SUBSEP "0" SUBSEP "[[:digit:]]+" SUBSEP "1$")
append(original, literal(ast[i]))
if (i ~ "^0" SUBSEP "0" SUBSEP "[[:digit:]]+" SUBSEP "2$")
append(phonetics, literal(ast[i]))
if (i ~ "^0" SUBSEP "0" SUBSEP "[[:digit:]]+" SUBSEP "3$")
append(oPhonetics, literal(ast[i]))
if (match(i, "^0" SUBSEP "1" SUBSEP "([[:digit:]]+)" SUBSEP "0$", group))
wordClasses[group[1]] = literal(ast[i])
if (match(i, "^0" SUBSEP "1" SUBSEP "([[:digit:]]+)" SUBSEP "2" SUBSEP "([[:digit:]]+)" SUBSEP "([[:digit:]]+)$", group))
words[group[1]][group[2]][group[3]] = literal(ast[i])
if (match(i, "^0" SUBSEP "1" SUBSEP "([[:digit:]]+)" SUBSEP "2" SUBSEP "([[:digit:]]+)" SUBSEP "1" SUBSEP "([[:digit:]]+)$", group))
words[group[1]][group[2]]["1"][group[3]] = literal(ast[i])
if (match(i, "^0" SUBSEP "5" SUBSEP "([[:digit:]]+)" SUBSEP "0$", group)) {
segments[group[1]] = literal(ast[i])
altTranslations[group[1]][0] = ""
}
if (match(i, "^0" SUBSEP "5" SUBSEP "([[:digit:]]+)" SUBSEP "2" SUBSEP "([[:digit:]]+)" SUBSEP "0$", group))
altTranslations[group[1]][group[2]] = literal(ast[i])
if (i ~ "^0" SUBSEP "7" SUBSEP "5$") {
if (ast[i] == "true")
w("Showing translation for:  (use -no-auto to disable autocorrect)")
else
w("Did you mean: "\
ansi("bold", unparameterize(ast["0" SUBSEP "7" SUBSEP "1"])))
}
if (i ~ "^0" SUBSEP "8" SUBSEP "0" SUBSEP "[[:digit:]]+$" ||
i ~ "^0" SUBSEP "2$")
append(ils, literal(ast[i]))
if (match(i, "^0" SUBSEP "11" SUBSEP "([[:digit:]]+)" SUBSEP "0$", group))
oSynonymClasses[group[1]] = literal(ast[i])
if (match(i, "^0" SUBSEP "11" SUBSEP "([[:digit:]]+)" SUBSEP "1" SUBSEP "([[:digit:]]+)" SUBSEP "1$", group))
if (ast[i]) {
oRefs[literal(ast[i])][1] = group[1]
oRefs[literal(ast[i])][2] = group[2]
}
if (match(i, "^0" SUBSEP "11" SUBSEP "([[:digit:]]+)" SUBSEP "1" SUBSEP "([[:digit:]]+)" SUBSEP "0" SUBSEP "([[:digit:]]+)$", group))
oSynonyms[group[1]][group[2]][group[3]] = literal(ast[i])
if (match(i, "^0" SUBSEP "12" SUBSEP "([[:digit:]]+)" SUBSEP "0$", group))
oWordClasses[group[1]] = literal(ast[i])
if (match(i, "^0" SUBSEP "12" SUBSEP "([[:digit:]]+)" SUBSEP "1" SUBSEP "([[:digit:]]+)" SUBSEP "0$", group))
oWords[group[1]][group[2]][0] = literal(ast[i])
if (match(i, "^0" SUBSEP "12" SUBSEP "([[:digit:]]+)" SUBSEP "1" SUBSEP "([[:digit:]]+)" SUBSEP "1$", group))
oWords[group[1]][group[2]][1] = literal(ast[i])
if (match(i, "^0" SUBSEP "12" SUBSEP "([[:digit:]]+)" SUBSEP "1" SUBSEP "([[:digit:]]+)" SUBSEP "2$", group))
oWords[group[1]][group[2]][2] = literal(ast[i])
if (match(i, "^0" SUBSEP "13" SUBSEP "0" SUBSEP "([[:digit:]]+)" SUBSEP "0$", group))
oExamples[group[1]] = literal(ast[i])
if (match(i, "^0" SUBSEP "14" SUBSEP "0" SUBSEP "([[:digit:]]+)$", group))
oSeeAlso[group[1]] = literal(ast[i])
if (match(i, "^0" SUBSEP "18" SUBSEP "0" SUBSEP "([[:digit:]]+)" SUBSEP "1$", group))
genderedTrans[group[1]] = literal(ast[i])
}
PROCINFO["sorted_in"] = saveSortedIn
translation = join(translations)
returnIl[0] = il = !anything(ils) || belongsTo(sl, ils) ? sl : ils[0]
if (Option["verbose"] < -1)
return il
else if (Option["verbose"] < 0)
return getLanguage(il)
if (!isVerbose) {
r = isPhonetic && anything(phonetics) ?
prettify("brief-translation-phonetics", join(phonetics, " ")) :
prettify("brief-translation", s(translation, tl))
if (toSpeech) {
returnPlaylist[0]["text"] = translation
returnPlaylist[0]["tl"] = _tl
}
} else {
wShowOriginal = Option["show-original"]
wShowOriginalPhonetics = Option["show-original-phonetics"]
wShowTranslation = Option["show-translation"]
wShowTranslationPhonetics = Option["show-translation-phonetics"]
wShowPromptMessage = Option["show-prompt-message"]
wShowLanguages = Option["show-languages"]
wShowOriginalDictionary = Option["show-original-dictionary"]
wShowDictionary = Option["show-dictionary"]
wShowAlternatives = Option["show-alternatives"]
if (!anything(oPhonetics)) wShowOriginalPhonetics = 0
if (!anything(phonetics)) wShowTranslationPhonetics = 0
if (getCode(il) == getCode(tl) &&\
(isarray(oWordClasses) || isarray(oSynonymClasses) ||\
isarray(oExamples) || isarray(oSeeAlso))) {
wShowOriginalDictionary = 1
wShowTranslation = 0
}
hasWordClasses = exists(wordClasses)
hasAltTranslations = exists(altTranslations[0])
if (!hasWordClasses && !hasAltTranslations)
wShowPromptMessage = wShowLanguages = 0
if (!hasWordClasses) wShowDictionary = 0
if (!hasAltTranslations) wShowAlternatives = 0
if (wShowOriginal) {
if (r) r = r RS RS
r = r m("-- display original text & phonetics")
r = r prettify("original", s(join(original, " "), il))
if (wShowOriginalPhonetics)
r = r RS prettify("original-phonetics", showPhonetics(join(oPhonetics, " "), il))
}
if (wShowTranslation) {
if (r) r = r RS RS
r = r m("-- display major translation & phonetics")
if (!exists(genderedTrans))
r = r prettify("translation", s(translation, tl))
else {
r = r prettify("prompt-message", s("(♂) ", hl))
r = r prettify("translation", s(genderedTrans[0], tl)) RS
r = r prettify("prompt-message", s("(♀) ", hl))
r = r prettify("translation", s(genderedTrans[1], tl))
}
if (wShowTranslationPhonetics)
r = r RS prettify("translation-phonetics", showPhonetics(join(phonetics, " "), tl))
}
if (wShowPromptMessage || wShowLanguages)
if (r) r = r RS
if (wShowPromptMessage) {
if (hasWordClasses) {
if (r) r = r RS
r = r m("-- display prompt message (Definitions of ...)")
if (isRTL(hl))
r = r prettify("prompt-message", s(showDefinitionsOf(hl, join(original, " "))))
else {
split(showDefinitionsOf(hl, "\0%s\0"), group, "\0")
for (i = 1; i <= length(group); i++) {
if (group[i] == "%s")
r = r prettify("prompt-message-original", show(join(original, " "), il))
else
r = r prettify("prompt-message", group[i])
}
}
} else if (hasAltTranslations) {
if (r) r = r RS
r = r m("-- display prompt message (Translations of ...)")
if (isRTL(hl))
r = r prettify("prompt-message", s(showTranslationsOf(hl, join(original, " "))))
else {
split(showTranslationsOf(hl, "\0%s\0"), group, "\0")
for (i = 1; i <= length(group); i++) {
if (group[i] == "%s")
r = r prettify("prompt-message-original", show(join(original, " "), il))
else
r = r prettify("prompt-message", group[i])
}
}
}
}
if (wShowLanguages) {
if (r) r = r RS
r = r m("-- display source language -> target language")
temp = Option["fmt-languages"]
if (!temp) temp = "[ %s -> %t ]"
split(temp, group, /(%s|%S|%t|%T)/)
r = r prettify("languages", group[1])
if (temp ~ /%s/)
r = r prettify("languages-sl", getDisplay(il))
if (temp ~ /%S/)
r = r prettify("languages-sl", getName(il))
r = r prettify("languages", group[2])
if (temp ~ /%t/)
r = r prettify("languages-tl", getDisplay(tl))
if (temp ~ /%T/)
r = r prettify("languages-tl", getName(tl))
r = r prettify("languages", group[3])
}
if (wShowOriginalDictionary) {
if (exists(oWordClasses)) {
if (r) r = r RS
r = r m("-- display original dictionary (detailed explanations)")
for (i = 0; i < length(oWordClasses); i++) {
r = (i > 0 ? r RS : r) RS prettify("original-dictionary-detailed-word-class", s(oWordClasses[i], hl))
for (j = 0; j < length(oWords[i]); j++) {
explanation = oWords[i][j][0]
ref = oWords[i][j][1]
example = oWords[i][j][2]
r = (j > 0 ? r RS : r) RS prettify("original-dictionary-detailed-explanation", ins(1, explanation, il))
if (example)
r = r RS prettify("original-dictionary-detailed-example", ins(2, "- \"" example "\"", il))
if (ref && isarray(oRefs[ref])) {
temp = prettify("original-dictionary-detailed-synonyms", ins(1, show(showSynonyms(hl), hl) ": "))
temp = temp prettify("original-dictionary-detailed-synonyms-item", show(oSynonyms[oRefs[ref][1]][oRefs[ref][2]][0], il))
for (k = 1; k < length(oSynonyms[oRefs[ref][1]][oRefs[ref][2]]); k++)
temp = temp prettify("original-dictionary-detailed-synonyms", ", ")\
prettify("original-dictionary-detailed-synonyms-item", show(oSynonyms[oRefs[ref][1]][oRefs[ref][2]][k], il))
r = r RS temp
}
}
}
}
if (exists(oSynonymClasses)) {
r = r RS RS
r = r m("-- display original dictionary (synonyms)")
r = r prettify("original-dictionary-synonyms", s(showSynonyms(hl), hl))
for (i = 0; i < length(oSynonymClasses); i++) {
r = (i > 0 ? r RS : r) RS prettify("original-dictionary-synonyms-word-class", ins(1, oSynonymClasses[i], hl))
for (j = 0; j < length(oSynonyms[i]); j++) {
temp = prettify("original-dictionary-synonyms-synonyms", ins(2, "- "))
temp = temp prettify("original-dictionary-synonyms-synonyms-item", show(oSynonyms[i][j][0], il))
for (k = 1; k < length(oSynonyms[i][j]); k++)
temp = temp prettify("original-dictionary-synonyms-synonyms", ", ")\
prettify("original-dictionary-synonyms-synonyms-item", show(oSynonyms[i][j][k], il))
r = r RS temp
}
}
}
if (exists(oExamples)) {
r = r RS RS
r = r m("-- display original dictionary (examples)")
r = r prettify("original-dictionary-examples", s(showExamples(hl), hl))
for (i = 0; i < length(oExamples); i++) {
example = oExamples[i]
temp = prettify("original-dictionary-examples-example", ins(1, "- "))
split(example, group, /(<b>|<\/b>)/)
if (group[3] ~ / [[:punct:].]/)
group[3] = substr(group[3], 2)
if (isRTL(il))
temp = temp show(group[1] group[2] group[3], il)
else
temp = temp prettify("original-dictionary-examples-example", group[1])\
prettify("original-dictionary-examples-original", group[2])\
prettify("original-dictionary-examples-example", group[3])
r = (i > 0 ? r RS : r) RS temp
}
}
if (exists(oSeeAlso)) {
r = r RS RS
r = r m("-- display original dictionary (see also)")
r = r prettify("original-dictionary-see-also", s(showSeeAlso(hl), hl))
temp = ins(1, prettify("original-dictionary-see-also-phrases-item", show(oSeeAlso[0], il)))
for (k = 1; k < length(oSeeAlso); k++)
temp = temp prettify("original-dictionary-see-also-phrases", ", ")\
prettify("original-dictionary-see-also-phrases-item", show(oSeeAlso[k], il))
r = r RS temp
}
}
if (wShowDictionary) {
if (r) r = r RS
r = r m("-- display dictionary entries")
for (i = 0; i < length(wordClasses); i++) {
r = (i > 0 ? r RS : r) RS prettify("dictionary-word-class", s(wordClasses[i], hl))
for (j = 0; j < length(words[i]); j++) {
word = words[i][j][0]
article = words[i][j][4]
if (isRTL(il))
explanation = join(words[i][j][1], ", ")
else {
explanation = prettify("dictionary-explanation-item", words[i][j][1][0])
for (k = 1; k < length(words[i][j][1]); k++)
explanation = explanation prettify("dictionary-explanation", ", ")\
prettify("dictionary-explanation-item", words[i][j][1][k])
}
r = r RS prettify("dictionary-word", ins(1, (article ? "(" article ") " : "") word, tl))
if (isRTL(il))
r = r RS prettify("dictionary-explanation-item", ins(2, explanation, il))
else
r = r RS ins(2, explanation)
}
}
}
if (wShowAlternatives) {
if (r) r = r RS RS
r = r m("-- display alternative translations")
for (i = 0; i < length(altTranslations); i++) {
r = (i > 0 ? r RS : r) prettify("alternatives-original", show(segments[i], il))
if (isRTL(tl)) {
temp = join(altTranslations[i], ", ")
r = r RS prettify("alternatives-translations-item", ins(1, temp, tl))
} else {
temp = prettify("alternatives-translations-item", altTranslations[i][0])
for (j = 1; j < length(altTranslations[i]); j++)
temp = temp prettify("alternatives-translations", ", ")\
prettify("alternatives-translations-item", altTranslations[i][j])
r = r RS ins(1, temp)
}
}
}
if (toSpeech) {
if (index(showTranslationsOf(hl, "%s"), "%s") > 2) {
returnPlaylist[0]["text"] = showTranslationsOf(hl)
returnPlaylist[0]["tl"] = _hl
returnPlaylist[1]["text"] = join(original)
returnPlaylist[1]["tl"] = il
} else {
returnPlaylist[0]["text"] = join(original)
returnPlaylist[0]["tl"] = il
returnPlaylist[1]["text"] = showTranslationsOf(hl)
returnPlaylist[1]["tl"] = _hl
}
returnPlaylist[2]["text"] = translation
returnPlaylist[2]["tl"] = _tl
}
}
return r
}
BEGIN { provides("bing") }
function bingInit() {
HttpProtocol = "http://"
HttpHost = "www.bing.com"
HttpPort = 80
}
function bingSetup(    ast, content, cookie, group, header, isBody, key,
location, status, token, tokens, url) {
url = HttpPathPrefix "/translator"
header = "GET " url " HTTP/1.1\r\n"\
"Host: " HttpHost "\r\n"\
"Connection: close\r\n"
if (Option["user-agent"])
header = header "User-Agent: " Option["user-agent"] "\r\n"
cookie = NULLSTR
print header |& HttpService
while ((HttpService |& getline) > 0) {
match($0, /Set-Cookie: ([^;]*);/, group)
if (group[1]) {
cookie = cookie (cookie ?  "; " : NULLSTR) group[1]
}
if (isBody)
content = content ? content "\n" $0 : $0
else if (length($0) <= 1)
isBody = 1
else {
match($0, /^HTTP[^ ]* ([^ ]*)/, group)
if (RSTART) status = group[1]
match($0, /^Location: (.*)/, group)
if (RSTART) location = squeeze(group[1])
}
l(sprintf("%4s bytes > %s", length($0), length($0) < 1024 ? $0 : "..."))
}
close(HttpService)
if ((status == "301" || status == "302") && location)
content = curl(location)
Cookie = cookie
match(content, /IG:"([^"]+)"/, group)
if (group[1]) {
IG = group[1]
l(IG, "IG")
} else {
e("[ERROR] Failed to extract IG.")
exit 1
}
match(content, /data-iid="([^"]+)"/, group)
if (group[1]) {
IID = group[1]
l(IID, "IID")
} else {
e("[ERROR] Failed to extract IID.")
exit 1
}
match(content, /params_AbusePreventionHelper = ([^;]+);/, group)
if (group[1]) {
tokenize(tokens, group[1])
parseJson(ast, tokens)
key = ast[0 SUBSEP 0]
token = unparameterize(ast[0 SUBSEP 1])
BingTokenKey = sprintf("&token=%s&key=%s", quote(token), quote(key))
l(BingTokenKey, "BingTokenKey")
} else {
e("[ERROR] Failed to extract token & key.")
exit 1
}
}
function bingTTSUrl(text, tl,
country, gender, i, group,
header, content, isBody) {
gender = "female"
country = NULLSTR
split(Option["narrator"], group, ",")
for (i in group) {
if (group[i] ~ /^(f(emale)?|w(oman)?)$/)
gender = "female"
else if (group[i] ~ /^m(ale|an)?$/)
gender = "male"
else
country = group[i]
}
if (country) tl = tl "-" country
else if (tl == "ar") tl = tl "-EG"
else if (tl == "da") tl = tl "-DK"
else if (tl == "de") tl = tl "-DE"
else if (tl == "en") tl = tl "-US"
else if (tl == "es") tl = tl "-ES"
else if (tl == "fi") tl = tl "-FI"
else if (tl == "fr") tl = tl "-FR"
else if (tl == "it") tl = tl "-IT"
else if (tl == "ja") tl = tl "-JP"
else if (tl == "ko") tl = tl "-KR"
else if (tl == "nl") tl = tl "-NL"
else if (tl == "nb") tl = tl "-NO"
else if (tl == "pl") tl = tl "-PL"
else if (tl == "pt") tl = tl "-PT"
else if (tl == "ru") tl = tl "-RU"
else if (tl == "sv") tl = tl "-SE"
else if (tl == "yue") ;
else if (tl == "zh") tl = tl "-CN"
header = "GET " "/tspeak?"\
"&language=" tl "&text=" preprocess(text)\
"&options=" gender "&format=audio%2Fmp3" " HTTP/1.1\r\n"\
"Host: " HttpHost "\r\n"\
"Connection: close\r\n"
if (Option["user-agent"])
header = header "User-Agent: " Option["user-agent"] "\r\n"
if (Cookie)
header = header "Cookie: " Cookie "\r\n"
content = NULLSTR; isBody = 0
print header |& HttpService
while ((HttpService |& getline) > 0) {
if (isBody)
content = content ? content "\n" $0 : $0
else if (length($0) <= 1)
isBody = 1
}
close(HttpService)
if (!TempFile)
TempFile = getOutput("mktemp")
printf("%s", content) > TempFile
close(TempFile)
return TempFile
}
function bingWebTranslateUrl(uri, sl, tl, hl,    _sl, _tl) {
_sl = sl; _tl = tl
if (_sl == "zh")    _sl = "zh-CHS"
if (_sl == "zh-CN") _sl = "zh-CHS"
if (_sl == "zh-TW") _sl = "zh-CHT"
if (_tl == "zh")    _tl = "zh-CHS"
if (_tl == "zh-CN") _tl = "zh-CHS"
if (_tl == "zh-TW") _tl = "zh-CHT"
return "https://www.translatetheweb.com/?" "from=" _sl "&to=" _tl "&a=" uri
}
function bingRequestUrl(text, sl, tl, hl) {
return HttpPathPrefix "/translator/api/Dictionary/Lookup?"\
"from=" sl "&to=" tl "&text=" preprocess(text)
}
function bingPostRequestUrl(text, sl, tl, hl, type) {
if (type == "lookup")
return HttpPathPrefix "/tlookupv3"
else # type == "translate"
return HttpPathPrefix "/ttranslatev3" sprintf("?IG=%s&IID=%s", IG, IID)
}
function bingPostRequestContentType(text, sl, tl, hl, type) {
return "application/x-www-form-urlencoded"
}
function bingPostRequestUserAgent(text, sl, tl, hl, type) {
return ""
}
function bingPostRequestBody(text, sl, tl, hl, type) {
if (type == "lookup")
return "&text=" quote(text) "&from=" sl "&to=" tl
else # type == "translate"
return "&text=" quote(text) "&fromLang=" sl "&to=" tl BingTokenKey
}
function bingTranslate(text, sl, tl, hl,
isVerbose, toSpeech, returnPlaylist, returnIl,
r,
content, tokens, ast, dicContent, dicTokens, dicAst,
_sl, _tl, _hl, il, isPhonetic,
translation, phonetics, oPhonetics,
wordClasses, words, wordBackTranslations,
wShowOriginal, wShowOriginalPhonetics,
wShowTranslation, wShowTranslationPhonetics,
wShowLanguages, wShowDictionary,
i, j, k, group, temp, saveSortedIn) {
isPhonetic = match(tl, /^@/)
tl = substr(tl, 1 + isPhonetic)
if (!getCode(tl)) {
w("[WARNING] Unknown target language code: " tl)
} else if (isRTL(tl)) {
if (!FriBidi)
w("[WARNING] " getName(tl) " is a right-to-left language, but FriBidi is not found.")
}
_sl = getCode(sl); if (!_sl) _sl = sl
_tl = getCode(tl); if (!_tl) _tl = tl
_hl = getCode(hl); if (!_hl) _hl = hl
bingSetup()
if (_sl == "auto")  _sl = "auto-detect"
if (_sl == "tl")    _sl = "fil"
if (_sl == "hmn")   _sl = "mww"
if (_sl == "ku")    _sl = "kmr"
else if (_sl == "ckb") _sl = "ku"
if (_sl == "mn")    _sl = "mn-Cyrl"
if (_sl == "no")    _sl = "nb"
if (_sl == "pt-BR") _sl = "pt"
else if (_sl == "pt-PT") _sl = "pt"
if (_sl == "zh-CN") _sl = "zh-Hans"
if (_sl == "zh-TW") _sl = "zh-Hant"
if (_tl == "tl")    _tl = "fil"
if (_tl == "hmn")   _tl = "mww"
if (_tl == "ku")    _tl = "kmr"
else if (_tl == "ckb") _tl = "ku"
if (_tl == "mn")    _tl = "mn-Cyrl"
if (_tl == "no")    _tl = "nb"
if (_tl == "pt-BR") _tl = "pt"
else if (_tl == "pt-PT") _tl = "pt-pt"
if (_tl == "zh-CN") _tl = "zh-Hans"
if (_tl == "zh-TW") _tl = "zh-Hant"
content = postResponse(text, _sl, _tl, _hl, "translate")
if (content == "") {
HttpHost = "cn.bing.com"
if (Option["proxy"]) {
HttpPathPrefix = HttpProtocol HttpHost
} else {
HttpService = "/" "inet" "/tcp/0/" HttpHost "/" HttpPort
}
content = postResponse(text, _sl, _tl, _hl, "translate")
}
if (Option["dump"])
return content
tokenize(tokens, content)
parseJson(ast, tokens)
l(content, "content", 1, 1)
l(tokens, "tokens", 1, 0, 1)
l(ast, "ast")
if (!isarray(ast) || !anything(ast)) {
e("[ERROR] Oops! Something went wrong and I can't translate it for you :(")
ExitCode = 1
return
}
if (ast[0 SUBSEP "statusCode"] == "400") {
e("[ERROR] " ucfirst(Option["engine"]) " does not support the specified language(s)")
ExitCode = 1
return
}
translation = unparameterize(ast[0 SUBSEP 0 SUBSEP "translations" SUBSEP 0 SUBSEP "text"])
returnIl[0] = il = _sl == "auto-detect" ?
unparameterize(ast[0 SUBSEP 0 SUBSEP "detectedLanguage" SUBSEP "language"]) : _sl
if (Option["verbose"] < -1)
return il
if (Option["verbose"] < 0)
return getLanguage(il)
wShowTranslationPhonetics = Option["show-translation-phonetics"]
if (wShowTranslationPhonetics) {
split(_tl, group, "-")
phonetics = unparameterize(ast[0 SUBSEP 0 SUBSEP "translations" SUBSEP 0 SUBSEP "transliteration"\
SUBSEP "text"])
if (phonetics == translation) phonetics = ""
}
if (!isVerbose) {
r = isPhonetic && phonetics ?
prettify("brief-translation-phonetics", join(phonetics, " ")) :
prettify("brief-translation", s(translation, tl))
} else {
wShowOriginal = Option["show-original"]
wShowTranslation = Option["show-translation"]
wShowLanguages = Option["show-languages"]
wShowDictionary = Option["show-dictionary"]
wShowOriginalPhonetics = Option["show-original-phonetics"]
if (wShowOriginalPhonetics) {
split(_sl, group, "-")
delete ast
content = postResponse(text, il, il, _hl, "translate")
tokenize(tokens, content)
parseJson(ast, tokens)
oPhonetics = unparameterize(ast[0 SUBSEP 0 SUBSEP "translations" SUBSEP 0\
SUBSEP "transliteration" SUBSEP "text"])
if (oPhonetics == text) oPhonetics = ""
}
if (!oPhonetics) wShowOriginalPhonetics = 0
if (!phonetics) wShowTranslationPhonetics = 0
if (wShowOriginal) {
if (r) r = r RS RS
r = r m("-- display original text")
r = r prettify("original", s(text, _sl))
if (wShowOriginalPhonetics)
r = r RS prettify("original-phonetics", showPhonetics(join(oPhonetics, " "), _sl))
}
if (wShowTranslation) {
if (r) r = r RS RS
r = r m("-- display major translation")
r = r prettify("translation", s(translation, tl))
if (wShowTranslationPhonetics)
r = r RS prettify("translation-phonetics", showPhonetics(join(phonetics, " "), tl))
}
if (wShowLanguages) {
if (r) r = r RS RS
r = r m("-- display source language -> target language")
temp = Option["fmt-languages"]
if (!temp) temp = "[ %s -> %t ]"
split(temp, group, /(%s|%S|%t|%T)/)
r = r prettify("languages", group[1])
if (temp ~ /%s/)
r = r prettify("languages-sl", getDisplay(il))
if (temp ~ /%S/)
r = r prettify("languages-sl", getName(il))
r = r prettify("languages", group[2])
if (temp ~ /%t/)
r = r prettify("languages-tl", getDisplay(tl))
if (temp ~ /%T/)
r = r prettify("languages-tl", getName(tl))
r = r prettify("languages", group[3])
}
if (wShowDictionary) {
dicContent = postResponse(text, il, _tl, _hl, "lookup")
if (dicContent != "") {
tokenize(dicTokens, dicContent)
parseJson(dicAst, dicTokens)
l(dicContent, "dicContent", 1, 1)
l(dicTokens, "dicTokens", 1, 0, 1)
l(dicAst, "dicAst")
saveSortedIn = PROCINFO["sorted_in"]
PROCINFO["sorted_in"] = "compareByIndexFields"
for (i in dicAst) {
if (match(i, "^0" SUBSEP "0" SUBSEP "translations" SUBSEP "([[:digit:]]+)" SUBSEP\
"posTag$", group))
wordClasses[group[1]] = tolower(literal(dicAst[i]))
}
for (i in dicAst) {
if (match(i, "^0" SUBSEP "0" SUBSEP "translations" SUBSEP "([[:digit:]]+)" SUBSEP\
"displayTarget$", group))
words[wordClasses[group[1]]][group[1]] = literal(dicAst[i])
if (match(i, "^0" SUBSEP "0" SUBSEP "translations" SUBSEP "([[:digit:]]+)" SUBSEP\
"backTranslations" SUBSEP "([[:digit:]]+)" SUBSEP "displayText$", group))
wordBackTranslations[wordClasses[group[1]]][group[1]][group[2]] = literal(dicAst[i])
}
PROCINFO["sorted_in"] = saveSortedIn
if (r) r = r RS
r = r m("-- display dictionary entries")
for (i = 0; i < length(words); i++) {
r = (i > 0 ? r RS : r) RS prettify("dictionary-word-class", s(wordClasses[i], hl))
for (j in words[wordClasses[i]]) {
r = r RS prettify("dictionary-word", ins(1, words[wordClasses[i]][j], tl))
if (isRTL(il))
explanation = join(wordBackTranslations[wordClasses[i]][j], ", ")
else {
explanation = prettify("dictionary-explanation-item",
wordBackTranslations[wordClasses[i]][j][0])
for (k = 1; k < length(wordBackTranslations[wordClasses[i]][j]); k++)
explanation = explanation prettify("dictionary-explanation", ", ")\
prettify("dictionary-explanation-item",
wordBackTranslations[wordClasses[i]][j][k])
}
if (isRTL(il))
r = r RS prettify("dictionary-explanation-item", ins(2, explanation, il))
else
r = r RS ins(2, explanation)
}
}
}
}
}
if (toSpeech) {
returnPlaylist[0]["text"] = translation
returnPlaylist[0]["tl"] = _tl
}
return r
}
BEGIN { provides("yandex") }
function genSID(    content, group, temp) {
content = curl("http://translate.yandex.com")
match(content, /SID:[[:space:]]*'([^']+)'/, group)
if (group[1]) {
split(group[1], temp, ".")
SID = reverse(temp[1]) "." reverse(temp[2]) "." reverse(temp[3])
} else {
e("[ERROR] Oops! Something went wrong and I can't translate it for you :(")
exit 1
}
}
function yandexInit() {
genSID()
YandexWebTranslate = "z5h64q92x9.net"
HttpProtocol = "http://"
HttpHost = "translate.yandex.net"
HttpPort = 80
}
function yandexRequestUrl(text, sl, tl, hl,    group) {
split(sl, group, "-"); sl = group[1]
split(tl, group, "-"); tl = group[1]
return HttpPathPrefix "/api/v1/tr.json/translate?"\
"id=" SID "-0-0&srv=tr-text"\
"&text=" preprocess(text) "&lang=" (sl == "auto" ? tl : sl "-" tl)
}
function yandexPostRequestBody(text, sl, tl, hl, type) {
return "text=" quote(text) "&lang=" sl
}
function yandexGetDictionaryResponse(text, sl, tl, hl,    content, header, isBody, url) {
split(sl, group, "-"); sl = group[1]
split(tl, group, "-"); tl = group[1]
url = "http://dictionary.yandex.net/dicservice.json/lookupMultiple?"\
"&text=" preprocess(text) "&dict=" sl "-" tl
content = curl(url)
return assert(content, "[ERROR] Null response.")
}
function yandexTTSUrl(text, tl,
speaker, emotion, i, group) {
speaker = NULLSTR
emotion = NULLSTR
split(Option["narrator"], group, ",")
for (i in group) {
if (group[i] ~ /^(g(ood)?|n(eutral)?|e(vil)?)$/)
emotion = group[i]
else if (group[i] ~ /^(f(emale)?|w(oman)?)$/)
speaker = "alyss"
else if (group[i] ~ /^m(ale|an)?$/)
speaker = "zahar"
else
speaker = group[i]
}
switch (tl) {
case "ar": tl = "ar_AE"; break
case "cs": tl = "cs_CZ"; break
case "da": tl = "da_DK"; break
case "de": tl = "de_DE"; break
case "el": tl = "el_GR"; break
case "en": tl = "en_GB"; break
case "es": tl = "es_ES"; break
case "fi": tl = "fi_FI"; break
case "fr": tl = "fr_FR"; break
case "it": tl = "it_IT"; break
case "nl": tl = "nl_NL"; break
case "no": tl = "no_NO"; break
case "pl": tl = "pl_PL"; break
case "pt": tl = "pt_PT"; break
case "ru": tl = "ru_RU"; break
case "sv": tl = "sv_SE"; break
case "tr": tl = "tr_TR"; break
default: tl = NULLSTR
}
return HttpProtocol "tts.voicetech.yandex.net" "/tts?"\
"text=" preprocess(text) (tl ? "&lang=" tl : tl)\
(speaker ? "&speaker=" speaker : speaker)\
(emotion ? "&emotion=" emotion : emotion)\
"&format=mp3" "&quality=hi"
}
function yandexWebTranslateUrl(uri, sl, tl, hl) {
gsub(/:\/\//, "/", uri)
return HttpProtocol YandexWebTranslate "/proxy_u/"\
(sl == "auto" ? tl : sl "-" tl)"/" uri
}
function yandexTranslate(text, sl, tl, hl,
isVerbose, toSpeech, returnPlaylist, returnIl,
r,
content, tokens, ast,
_sl, _tl, _hl, il, isPhonetic,
translation,
wShowOriginal, wShowTranslation, wShowLanguages,
wShowDictionary, dicContent, dicTokens, dicAst,
i, syn, mean,
group, temp) {
isPhonetic = match(tl, /^@/)
tl = substr(tl, 1 + isPhonetic)
if (!getCode(tl)) {
w("[WARNING] Unknown target language code: " tl)
} else if (isRTL(tl)) {
if (!FriBidi)
w("[WARNING] " getName(tl) " is a right-to-left language, but FriBidi is not found.")
}
_sl = getCode(sl); if (!_sl) _sl = sl
_tl = getCode(tl); if (!_tl) _tl = tl
_hl = getCode(hl); if (!_hl) _hl = hl
content = getResponse(text, _sl, _tl, _hl)
if (Option["dump"])
return content
tokenize(tokens, content)
parseJson(ast, tokens)
l(content, "content", 1, 1)
l(tokens, "tokens", 1, 0, 1)
l(ast, "ast")
if (!isarray(ast) || !anything(ast)) {
e("[ERROR] Oops! Something went wrong and I can't translate it for you :(")
ExitCode = 1
return
}
if (ast[0 SUBSEP "code"] != "200") {
e("[ERROR] " unparameterize(ast[0 SUBSEP "message"]))
ExitCode = 1
return
}
translation = unparameterize(ast[0 SUBSEP "text" SUBSEP 0])
wShowTranslationPhonetics = Option["show-translation-phonetics"]
if (wShowTranslationPhonetics && _tl != "emj") {
split(_tl, group, "-")
data = yandexPostRequestBody(translation, group[1], group[1], _hl, "translit")
content = curlPost("https://translate.yandex.net/translit/translit", data)
phonetics = (content ~ /not supported$/) ? "" : unparameterize(content)
}
split(unparameterize(ast[0 SUBSEP "lang"]), group, "-")
returnIl[0] = il = group[1]
if (Option["verbose"] < -1)
return il
else if (Option["verbose"] < 0)
return getLanguage(il)
if (!isVerbose) {
r = isPhonetic && phonetics ?
prettify("brief-translation-phonetics", join(phonetics, " ")) :
prettify("brief-translation", s(translation, tl))
} else {
wShowOriginal = Option["show-original"]
wShowTranslation = Option["show-translation"]
wShowLanguages = Option["show-languages"]
wShowDictionary = Option["show-dictionary"]
wShowOriginalPhonetics = Option["show-original-phonetics"]
if (wShowTranslationPhonetics && il != "emj") {
split(il, group, "-")
data = yandexPostRequestBody(text, group[1], group[1], _hl, "translit")
content = curlPost("https://translate.yandex.net/translit/translit", data)
oPhonetics = (content ~ /not supported$/) ? "" : unparameterize(content)
}
if (!oPhonetics) wShowOriginalPhonetics = 0
if (!phonetics) wShowTranslationPhonetics = 0
if (wShowOriginal) {
if (r) r = r RS RS
r = r m("-- display original text & phonetics")
r = r prettify("original", s(text, il))
if (wShowOriginalPhonetics)
r = r RS prettify("original-phonetics", showPhonetics(join(oPhonetics, " "), il))
}
if (wShowTranslation) {
if (r) r = r RS RS
r = r m("-- display major translation")
r = r prettify("translation", s(translation, tl))
if (wShowTranslationPhonetics)
r = r RS prettify("translation-phonetics", showPhonetics(join(phonetics, " "), tl))
}
if (wShowLanguages) {
if (r) r = r RS RS
r = r m("-- display source language -> target language")
temp = Option["fmt-languages"]
if (!temp) temp = "[ %s -> %t ]"
split(temp, group, /(%s|%S|%t|%T)/)
r = r prettify("languages", group[1])
if (temp ~ /%s/)
r = r prettify("languages-sl", getDisplay(il))
if (temp ~ /%S/)
r = r prettify("languages-sl", getName(il))
r = r prettify("languages", group[2])
if (temp ~ /%t/)
r = r prettify("languages-tl", getDisplay(tl))
if (temp ~ /%T/)
r = r prettify("languages-tl", getName(tl))
r = r prettify("languages", group[3])
}
if (wShowDictionary && false) {
dicContent = yandexGetDictionaryResponse(text, il, _tl, _hl)
tokenize(dicTokens, dicContent)
parseJson(dicAst, dicTokens)
if (anything(dicAst)) {
if (r) r = r RS
r = r m("-- display dictionary entries")
saveSortedIn = PROCINFO["sorted_in"]
PROCINFO["sorted_in"] = "@ind_num_asc"
for (i in dicAst) {
if (i ~ "^0" SUBSEP "def" SUBSEP "[[:digit:]]+" SUBSEP\
"pos$") {
r = r RS prettify("dictionary-word-class", s((literal(dicAst[i])), hl))
syn = mean = ""
}
if (i ~ "^0" SUBSEP "def" SUBSEP "[[:digit:]]+" SUBSEP\
"tr" SUBSEP "[[:digit:]]+" SUBSEP\
"mean" SUBSEP "[[:digit:]]+" SUBSEP "text") {
if (mean) {
mean = mean prettify("dictionary-explanation", ", ")\
prettify("dictionary-explanation-item", s((literal(dicAst[i])), sl))
} else {
mean = prettify("dictionary-explanation-item", s((literal(dicAst[i])), sl))
}
}
if (i ~ "^0" SUBSEP "def" SUBSEP "[[:digit:]]+" SUBSEP\
"tr" SUBSEP "[[:digit:]]+" SUBSEP\
"syn" SUBSEP "[[:digit:]]+" SUBSEP "text") {
if (syn) {
syn = syn prettify("dictionary-explanation", ", ")\
prettify("dictionary-word", s((literal(dicAst[i])), il))
} else {
syn = prettify("dictionary-word", s((literal(dicAst[i])), il))
}
}
if (i ~ "^0" SUBSEP "def" SUBSEP "[[:digit:]]+" SUBSEP\
"tr" SUBSEP "[[:digit:]]+" SUBSEP "text$") {
text = prettify("dictionary-word", s((literal(dicAst[i])), il))
if (syn) {
r = r RS ins(1, text prettify("dictionary-explanation", ", ") syn)
} else {
r = r RS ins(1, text)
}
r = r RS ins(2, mean)
syn = mean = ""
}
}
PROCINFO["sorted_in"] = saveSortedIn
}
}
}
if (toSpeech) {
returnPlaylist[0]["text"] = translation
returnPlaylist[0]["tl"] = _tl
}
return r
}
BEGIN { provides("apertium") }
function apertiumInit() {
HttpProtocol = "http://"
HttpHost = "www.apertium.org"
HttpPort = 80
}
function apertiumRequestUrl(text, sl, tl, hl) {
return HttpPathPrefix "/apy/translate?"\
"langpair=" preprocess(sl) "|" preprocess(tl)\
"&q=" preprocess(text)
}
function apertiumTTSUrl(text, tl,    narrator) {
}
function apertiumWebTranslateUrl(uri, sl, tl, hl) {
}
function apertiumTranslate(text, sl, tl, hl,
isVerbose, toSpeech, returnPlaylist, returnIl,
r,
content, tokens, ast,
_sl, _tl, _hl, il,
translation,
wShowOriginal, wShowTranslation, wShowLanguages,
group, temp) {
if (!getCode(tl)) {
w("[WARNING] Unknown target language code: " tl)
} else if (isRTL(tl)) {
if (!FriBidi)
w("[WARNING] " getName(tl) " is a right-to-left language, but FriBidi is not found.")
}
_sl = getCode(sl); if (!_sl) _sl = sl
_tl = getCode(tl); if (!_tl) _tl = tl
_hl = getCode(hl); if (!_hl) _hl = hl
_sl = "auto" == _sl ? "en" : _sl
content = getResponse(text, _sl, _tl, _hl)
if (Option["dump"])
return content
tokenize(tokens, content)
parseJson(ast, tokens)
l(content, "content", 1, 1)
l(tokens, "tokens", 1, 0, 1)
l(ast, "ast")
if (!isarray(ast) || !anything(ast)) {
e("[ERROR] Oops! Something went wrong and I can't translate it for you :(")
ExitCode = 1
return
}
translation = uprintf(unquote(unparameterize(ast[0 SUBSEP "responseData" SUBSEP "translatedText"])))
returnIl[0] = il = _sl
if (Option["verbose"] < -1)
return il
else if (Option["verbose"] < 0)
return getLanguage(il)
if (!isVerbose) {
r = translation
} else {
wShowOriginal = Option["show-original"]
wShowTranslation = Option["show-translation"]
wShowLanguages = Option["show-languages"]
if (wShowOriginal) {
if (r) r = r RS RS
r = r m("-- display original text")
r = r prettify("original", s(text, il))
}
if (wShowTranslation) {
if (r) r = r RS RS
r = r m("-- display major translation")
r = r prettify("translation", s(translation, tl))
}
if (wShowLanguages) {
if (r) r = r RS RS
r = r m("-- display source language -> target language")
temp = Option["fmt-languages"]
if (!temp) temp = "[ %s -> %t ]"
split(temp, group, /(%s|%S|%t|%T)/)
r = r prettify("languages", group[1])
if (temp ~ /%s/)
r = r prettify("languages-sl", getDisplay(il))
if (temp ~ /%S/)
r = r prettify("languages-sl", getName(il))
r = r prettify("languages", group[2])
if (temp ~ /%t/)
r = r prettify("languages-tl", getDisplay(tl))
if (temp ~ /%T/)
r = r prettify("languages-tl", getName(tl))
r = r prettify("languages", group[3])
}
}
if (toSpeech) {
returnPlaylist[0]["text"] = translation
returnPlaylist[0]["tl"] = _tl
}
return r
}
BEGIN {
provides("spell")
provides("aspell")
provides("hunspell")
}
function spellInit() {
Ispell = detectProgram("aspell", "--version") ? "aspell" :
(detectProgram("hunspell", "--version") ? "hunspell" : "")
if (!Ispell) {
e("[ERROR] Spell checker (aspell or hunspell) not found.")
exit 1
}
}
function aspellInit() {
if (!(Ispell = detectProgram("aspell", "--version") ? "aspell" : "")) {
e("[ERROR] Spell checker (aspell) not found.")
exit 1
}
}
function hunspellInit() {
if (!(Ispell = detectProgram("hunspell", "--version") ? "hunspell" : "")) {
e("[ERROR] Spell checker (hunspell) not found.")
exit 1
}
}
function spellTranslate(text, sl, tl, hl,
isVerbose, toSpeech, returnPlaylist, returnIl,
args, i, j, r, line, group, word, sug) {
args = " -a" (sl != "auto" ? " -d " sl : "")
if (system("echo" PIPE Ispell args SUPOUT SUPERR)) {
e("[ERROR] No dictionary for language: " sl)
exit 1
}
i = 1
r = ""
while ((("echo " parameterize(text) PIPE Ispell args SUPERR) |& getline line) > 0) {
match(line,
/^& (.*) [[:digit:]]+ [[:digit:]]+: ([^,]+)(, ([^,]+))?(, ([^,]+))?/,
group)
if (RSTART) {
ExitCode = 1
word = group[1]
sug = "[" group[2]
if (group[4]) sug = sug "|" group[4]
if (group[6]) sug = sug "|" group[6]
sug = sug "]"
j = i + index(substr(text, i), word) - 1
r = r substr(text, i, j - i)
r = r ansi("bold", ansi("red", word)) ansi("yellow", sug)
i = j + length(word)
}
}
r = r substr(text, i)
return r
}
function aspellTranslate(text, sl, tl, hl,
isVerbose, toSpeech, returnPlaylist, returnIl) {
return spellTranslate(text, sl, tl, hl)
}
function hunspellTranslate(text, sl, tl, hl,
isVerbose, toSpeech, returnPlaylist, returnIl) {
return spellTranslate(text, sl, tl, hl)
}
function spellTTSUrl(text, tl,    narrator) {
e("[ERROR] Spell checker does not support TTS.")
ExitCode = 1
return
}
function aspellTTSUrl(text, tl,    narrator) {
return spellTTSUrl(text, tl)
}
function hunspellTTSUrl(text, tl,    narrator) {
return spellTTSUrl(text, tl)
}
function spellWebTranslateUrl(uri, sl, tl, hl) {
e("[ERROR] Spell checker does not support web translation.")
ExitCode = 1
return
}
function aspellWebTranslateUrl(uri, sl, tl, hl) {
return spellWebTranslateUrl(uri, sl, tl, hl)
}
function hunspellWebTranslateUrl(uri, sl, tl, hl) {
return spellWebTranslateUrl(uri, sl, tl, hl)
}
BEGIN { provides("auto") }
function autoInit() {
}
function autoTTSUrl(text, tl) {
Option["engine"] = "google"
initHttpService()
return googleTTSUrl(text, tl)
}
function autoWebTranslateUrl(uri, sl, tl, hl) {
Option["engine"] = "google"
initHttpService()
return googleWebTranslateUrl(uri, sl, tl, hl)
}
function autoTranslate(text, sl, tl, hl,
isVerbose, toSpeech, returnPlaylist, returnIl,
engine, temp) {
if ((sl == "auto" || isSupportedByGoogle(sl)) && (tl == "auto" || isSupportedByGoogle(tl))) {
engine = Option["engine"]
Option["engine"] = "google"
initHttpService()
temp = googleTranslate(text, sl, tl, hl, isVerbose, toSpeech, returnPlaylist, returnIl)
Option["engine"] = engine
} else if ((sl == "auto" || isSupportedByBing(sl)) && (tl == "auto" || isSupportedByBing(tl))) {
engine = Option["engine"]
Option["engine"] = "bing"
initHttpService()
temp = bingTranslate(text, sl, tl, hl, isVerbose, toSpeech, returnPlaylist, returnIl)
Option["engine"] = engine
} else {
engine = Option["engine"]
Option["engine"] = "google"
initHttpService()
temp = googleTranslate(text, sl, tl, hl, isVerbose, toSpeech, returnPlaylist, returnIl)
Option["engine"] = engine
}
return temp
}
function loadOptions(script,    i, j, tokens, name, value) {
tokenize(tokens, script)
for (i in tokens) {
if (tokens[i] ~ /^:/) {
name = substr(tokens[i], 2)
value = tokens[i + 1]
if (value ~ /^[+-]?((0|[1-9][0-9]*)|[.][0-9]*|(0|[1-9][0-9]*)[.][0-9]*)([Ee][+-]?[0-9]+)?$/) {
delete Option[name]
Option[name] = value
} else if (value == "false" || value == "true") {
delete Option[name]
Option[name] = yn(value)
} else if (value ~ /^".*"$/) {
delete Option[name]
Option[name] = literal(value)
} else if (value == "[") {
delete Option[name]
for (j = 1; tokens[i + j + 1] && tokens[i + j + 1] != "]"; j++) {
if (tokens[i + j + 1] ~ /^".*"$/)
Option[name][j] = literal(tokens[i + j + 1])
else {
e("[ERROR] Malformed configuration.")
return
}
}
} else {
e("[ERROR] Malformed configuration.")
return
}
}
}
}
function upgrade(    i, newVersion, registry, tokens) {
RegistryIndex = "https://raw.githubusercontent.com/soimort/translate-shell/registry/index.trans"
registry = curl(RegistryIndex)
if (!registry) {
e("[ERROR] Failed to check for upgrade.")
ExitCode = 1
return
}
tokenize(tokens, registry)
for (i in tokens)
if (tokens[i] == ":translate-shell")
newVersion = literal(tokens[i + 1])
if (newerVersion(newVersion, Version)) {
w("Current version: \t" Version)
w("New version available: \t" newVersion)
w("Download from: \t" "https://www.soimort.org/translate-shell/trans")
} else {
w("Current version: \t" Version)
w("Already up-to-date.")
}
}
function welcome() {
if (Option["fmt-welcome-message"])
print prettify("welcome-message", Option["fmt-welcome-message"]) > STDERR
if (Option["fmt-welcome-submessage"])
print prettify("welcome-submessage", Option["fmt-welcome-submessage"]) > STDERR
}
function prompt(    i, p, temp) {
p = Option["fmt-prompt"]
if (p ~ /%a/) gsub(/%a/, strftime("%a"), p)
if (p ~ /%A/) gsub(/%A/, strftime("%A"), p)
if (p ~ /%b/) gsub(/%b/, strftime("%b"), p)
if (p ~ /%B/) gsub(/%B/, strftime("%B"), p)
if (p ~ /%c/) gsub(/%c/, strftime("%c"), p)
if (p ~ /%C/) gsub(/%C/, strftime("%C"), p)
if (p ~ /%d/) gsub(/%d/, strftime("%d"), p)
if (p ~ /%D/) gsub(/%D/, strftime("%D"), p)
if (p ~ /%e/) gsub(/%e/, strftime("%e"), p)
if (p ~ /%F/) gsub(/%F/, strftime("%F"), p)
if (p ~ /%g/) gsub(/%g/, strftime("%g"), p)
if (p ~ /%G/) gsub(/%G/, strftime("%G"), p)
if (p ~ /%h/) gsub(/%h/, strftime("%h"), p)
if (p ~ /%H/) gsub(/%H/, strftime("%H"), p)
if (p ~ /%I/) gsub(/%I/, strftime("%I"), p)
if (p ~ /%j/) gsub(/%j/, strftime("%j"), p)
if (p ~ /%m/) gsub(/%m/, strftime("%m"), p)
if (p ~ /%M/) gsub(/%M/, strftime("%M"), p)
if (p ~ /%n/) gsub(/%n/, strftime("%n"), p)
if (p ~ /%p/) gsub(/%p/, strftime("%p"), p)
if (p ~ /%r/) gsub(/%r/, strftime("%r"), p)
if (p ~ /%R/) gsub(/%R/, strftime("%R"), p)
if (p ~ /%u/) gsub(/%u/, strftime("%u"), p)
if (p ~ /%U/) gsub(/%U/, strftime("%U"), p)
if (p ~ /%V/) gsub(/%V/, strftime("%V"), p)
if (p ~ /%w/) gsub(/%w/, strftime("%w"), p)
if (p ~ /%W/) gsub(/%W/, strftime("%W"), p)
if (p ~ /%x/) gsub(/%x/, strftime("%x"), p)
if (p ~ /%X/) gsub(/%X/, strftime("%X"), p)
if (p ~ /%y/) gsub(/%y/, strftime("%y"), p)
if (p ~ /%Y/) gsub(/%Y/, strftime("%Y"), p)
if (p ~ /%z/) gsub(/%z/, strftime("%z"), p)
if (p ~ /%Z/) gsub(/%Z/, strftime("%Z"), p)
if (p ~ /%_/)
gsub(/%_/, showTranslationsOf(Option["hl"]), p)
if (p ~ /%l/)
gsub(/%l/, getDisplay(Option["hl"]), p)
if (p ~ /%L/)
gsub(/%L/, getName(Option["hl"]), p)
if (p ~ /%S/) {
temp = getName(Option["sls"][1])
for (i = 2; i <= length(Option["sls"]); i++)
temp = temp "+" getName(Option["sls"][i])
gsub(/%S/, temp, p)
}
if (p ~ /%t/) {
temp = getDisplay(Option["tl"][1])
for (i = 2; i <= length(Option["tl"]); i++)
temp = temp "+" getDisplay(Option["tl"][i])
gsub(/%t/, temp, p)
}
if (p ~ /%T/) {
temp = getName(Option["tl"][1])
for (i = 2; i <= length(Option["tl"]); i++)
temp = temp "+" getName(Option["tl"][i])
gsub(/%T/, temp, p)
}
if (p ~ /%,/) {
temp = getDisplay(Option["tl"][1])
for (i = 2; i <= length(Option["tl"]); i++)
temp = temp "," getDisplay(Option["tl"][i])
gsub(/%,/, temp, p)
}
if (p ~ /%</) {
temp = getName(Option["tl"][1])
for (i = 2; i <= length(Option["tl"]); i++)
temp = temp "," getName(Option["tl"][i])
gsub(/%</, temp, p)
}
if (p ~ /%\//) {
temp = getDisplay(Option["tl"][1])
for (i = 2; i <= length(Option["tl"]); i++)
temp = temp "/" getDisplay(Option["tl"][i])
gsub(/%\//, temp, p)
}
if (p ~ /%\?/) {
temp = getName(Option["tl"][1])
for (i = 2; i <= length(Option["tl"]); i++)
temp = temp "/" getName(Option["tl"][i])
gsub(/%\?/, temp, p)
}
temp = getDisplay(Option["sls"][1])
for (i = 2; i <= length(Option["sls"]); i++)
temp = temp "+" getDisplay(Option["sls"][i])
printf(prettify("prompt", p), temp) > STDERR
}
function repl(line,    command, group, name, i, value, words) {
split(line, words, " ")
command = words[1]
if (command ~ /^:(q|quit)$/) {
exit
} else if (command ~ /^:set$/) {
name = words[2]
value = words[3]
if (name == "sl") {
delete Option["sls"]
Option["sls"][1] = value
} else if (name == "tl") {
delete Option["tl"]
Option["tl"][1] = value
} else {
Option[name] = value
}
} else if (command ~ /^:show$/) {
name = words[2]
print prettify("welcome-submessage", toString(Option[name], 1, 0, 1))
} else if (command ~ /^:swap$/) {
tl = Option["tl"][1]
Option["tl"][1] = Option["sls"][1]
Option["sls"][1] = tl
} else if (command ~ /^:engine$/) {
value = words[2]
Option["engine"] = value
initHttpService()
} else if (command ~ /^:reset$/) {
} else {
match(command, /^[{(\[]?((@?[[:alpha:]][[:alpha:]][[:alpha:]]?(-[[:alpha:]][[:alpha:]][[:alpha:]]?[[:alpha:]]?)?\+)*(@?[[:alpha:]][[:alpha:]][[:alpha:]]?(-[[:alpha:]][[:alpha:]][[:alpha:]]?[[:alpha:]]?)?)?)?(:|=)((@?[[:alpha:]][[:alpha:]][[:alpha:]]?(-[[:alpha:]][[:alpha:]][[:alpha:]]?[[:alpha:]]?)?\+)*(@?[[:alpha:]][[:alpha:]][[:alpha:]]?(-[[:alpha:]][[:alpha:]][[:alpha:]]?[[:alpha:]]?)?)?)[})\]]?$/, group)
if (RSTART) {
if (group[1]) {
split(group[1], Option["sls"], "+")
Option["sl"] = Option["sls"][1]
}
if (group[7]) split(group[7], Option["tl"], "+")
line = words[2]
for (i = 3; i <= length(words); i++)
line = line " " words[i]
}
if (line) {
translates(line)
if (Option["verbose"]) printf RS
}
}
prompt()
}
function init() {
initGawk()
initBiDiTerm()
initBiDi()
initLocale()
initLocaleAlias()
initUserLang()
RS = "\n"
ExitCode = 0
Option["debug"] = 0
Option["engine"] = "auto"
Option["verbose"] = 1
Option["show-original"] = 1
Option["show-original-phonetics"] = 1
Option["show-translation"] = 1
Option["show-translation-phonetics"] = 1
Option["show-prompt-message"] = 1
Option["show-languages"] = 1
Option["show-original-dictionary"] = 0
Option["show-dictionary"] = 1
Option["show-alternatives"] = 1
Option["width"] = ENVIRON["COLUMNS"] ? ENVIRON["COLUMNS"] - 2 : 0
Option["indent"] = 4
Option["no-ansi"] = 0
Option["no-autocorrect"] = 0
Option["no-bidi"] = 0
Option["force-bidi"] = 0
Option["no-warn"] = 0
Option["theme"] = "default"
Option["dump"] = 0
Option["play"] = 0
Option["narrator"] = "female"
Option["player"] = ENVIRON["PLAYER"]
Option["no-translate"] = 0
Option["download-audio"] = 0
Option["download-audio-as"] = NULLSTR
Option["view"] = 0
Option["pager"] = ENVIRON["PAGER"]
Option["browser"] = ENVIRON["BROWSER"]
Option["proxy"] = ENVIRON["HTTP_PROXY"] ? ENVIRON["HTTP_PROXY"] : ENVIRON["http_proxy"]
Option["user-agent"] = ENVIRON["USER_AGENT"] ? ENVIRON["USER_AGENT"] :
"Mozilla/5.0 (Windows NT 10.0; Win64; x64) "\
"AppleWebKit/537.36 (KHTML, like Gecko) "\
"Chrome/104.0.0.0 "\
"Safari/537.36 "\
"Edg/104.0.1293.54"
Option["ip-version"] = 0
Option["no-rlwrap"] = 0
Option["interactive"] = 0
Option["emacs"] = 0
Option["input"] = NULLSTR
Option["output"] = STDOUT
Option["hl"] = ENVIRON["HOST_LANG"] ? ENVIRON["HOST_LANG"] :
ENVIRON["HOME_LANG"] ? ENVIRON["HOME_LANG"] : UserLang
Option["sl"] = ENVIRON["SOURCE_LANG"] ? ENVIRON["SOURCE_LANG"] : "auto"
Option["sls"][1] = Option["sl"]
Option["tl"][1] = ENVIRON["TARGET_LANG"] ? ENVIRON["TARGET_LANG"] : UserLang
Option["join-sentence"] = 0
}
function initScript(    file, line, script, temp) {
file = ".trans"
if (!fileExists(file)) {
file = ENVIRON["HOME"] "/.translate-shell/init.trans"
if (!fileExists(file)) {
file = ENVIRON["XDG_CONFIG_HOME"] "/translate-shell/init.trans"
if (!fileExists(file)) {
file = ENVIRON["HOME"] "/.config/translate-shell/init.trans"
if (!fileExists(file)) {
file = "/etc/translate-shell"
if (!fileExists(file)) return
}
}
}
}
InitScript = file
script = NULLSTR
while (getline line < InitScript)
script = script "\n" line
loadOptions(script)
if (!isarray(Option["tl"])) {
temp = Option["tl"]
delete Option["tl"]
Option["tl"][1] = temp
}
}
function initMisc(    command, group, temp) {
initHttpService()
if (!Option["width"] && detectProgram("tput", "-V")) {
command = "tput cols" SUPERR
command | getline temp
close(command)
Option["width"] = temp > 5 ? temp - 2 : 64
}
if (Option["no-ansi"])
delete AnsiCode
if (Option["no-bidi"] || BiDiTerm == "mlterm")
BiDi = BiDiNoPad = NULLSTR
else if (!Option["force-bidi"] && BiDiTerm == "konsole") {
BiDiNoPad = NULLSTR
BiDi = "sed \"s/'/\\\\\\'/\" | xargs -0 printf '%%%ss'"
}
initLocaleDisplay()
if (Option["no-warn"])
STDERR = "/dev/null"
if (Option["play"]) {
if (!Option["player"]) {
initAudioPlayer()
Option["player"] = AudioPlayer ? AudioPlayer : Option["player"]
if (!Option["player"])
initSpeechSynthesizer()
}
if (!Option["player"] && !SpeechSynthesizer) {
w("[WARNING] No available audio player or speech synthesizer.")
Option["play"] = 0
}
}
if (Option["view"]) {
if (!Option["pager"]) {
initPager()
Option["pager"] = Pager
}
if (!Option["pager"]) {
w("[WARNING] No available terminal pager.")
Option["view"] = 0
}
}
if (!Option["browser"]) {
Platform = detectProgram("uname", "-s", 1)
Option["browser"] = Platform == "Darwin" ? "open" : "xdg-open"
}
}
BEGIN {
init()
if (!(belongsTo("-no-init", ARGV) || belongsTo("--no-init", ARGV)))
initScript()
pos = 0
noargc = 0
while (ARGV[++pos]) {
match(ARGV[pos], /^--?(V|vers(i(on?)?)?)$/)
if (RSTART) {
InfoOnly = "version"
continue
}
match(ARGV[pos], /^--?(H|h(e(lp?)?)?)$/)
if (RSTART) {
InfoOnly = "help"
continue
}
match(ARGV[pos], /^--?(M|m(a(n(u(al?)?)?)?)?)$/)
if (RSTART) {
InfoOnly = "manual"
continue
}
match(ARGV[pos], /^--?(T|ref(e(r(e(n(ce?)?)?)?)?)?)$/)
if (RSTART) {
InfoOnly = "reference"
continue
}
match(ARGV[pos], /^--?r$/)
if (RSTART) {
w("[ERROR] Option '-r' has been deprecated since version 0.9.\n"\
"        Use option '-T' or '-reference' instead.")
exit 1
}
match(ARGV[pos], /^--?(R|reference-e(n(g(l(i(sh?)?)?)?)?)?)$/)
if (RSTART) {
InfoOnly = "reference-english"
continue
}
match(ARGV[pos], /^--?(S|list-e(n(g(i(n(es?)?)?)?)?)?)$/)
if (RSTART) {
InfoOnly = "list-engines"
continue
}
match(ARGV[pos], /^--?(list-languages)$/)
if (RSTART) {
InfoOnly = "list-languages"
continue
}
match(ARGV[pos], /^--?(list-languages-english)$/)
if (RSTART) {
InfoOnly = "list-languages-english"
continue
}
match(ARGV[pos], /^--?(list-codes)$/)
if (RSTART) {
InfoOnly = "list-codes"
continue
}
match(ARGV[pos], /^--?(list-all)$/)
if (RSTART) {
InfoOnly = "list-all"
continue
}
match(ARGV[pos], /^--?(L|linguist)(=(.*)?)?$/, group)
if (RSTART) {
InfoOnly = "language"
if (group[2]) {
if (group[3]) split(group[3], Option["tl"], "+")
} else
split(ARGV[++pos], Option["tl"], "+")
continue
}
match(ARGV[pos], /^--?(list)(=(.*)?)?$/, group)
if (RSTART) {
w("[WARNING] Option '-list' will be deprecated in the next version.\n"\
"          Use '-L' / '-linguist' instead.")
InfoOnly = "language"
if (group[2]) {
if (group[3]) split(group[3], Option["tl"], "+")
} else
split(ARGV[++pos], Option["tl"], "+")
continue
}
match(ARGV[pos], /^--?(U|upgrade)$/)
if (RSTART) {
InfoOnly = "upgrade"
continue
}
match(ARGV[pos], /^--?(N|nothing)$/)
if (RSTART) {
InfoOnly = "nothing"
continue
}
match(ARGV[pos], /^--?(e|engine)(=(.*)?)?$/, group)
if (RSTART) {
Option["engine"] = group[2] ?
(group[3] ? group[3] : Option["engine"]) :
ARGV[++pos]
continue
}
match(ARGV[pos], /^\/(.*)$/, group)
if (RSTART) {
Option["engine"] = group[1]
continue
}
match(ARGV[pos], /^--?verbose$/)
if (RSTART) {
Option["verbose"] = 1
continue
}
match(ARGV[pos], /^--?b(r(i(ef?)?)?)?$/)
if (RSTART) {
Option["verbose"] = 0
continue
}
match(ARGV[pos], /^--?d(i(c(t(i(o(n(a(ry?)?)?)?)?)?)?)?)?$/)
if (RSTART) {
Option["show-original-dictionary"] = 1
Option["show-dictionary"] = 0
Option["show-alternatives"] = 0
continue
}
match(ARGV[pos], /^--?id(e(n(t(i(fy?)?)?)?)?)?$/)
if (RSTART) {
Option["verbose"] = Option["verbose"] - 2
continue
}
match(ARGV[pos], /^--?show-original(=(.*)?)?$/, group)
if (RSTART) {
Option["show-original"] = yn(group[1] ? group[2] : ARGV[++pos])
continue
}
match(ARGV[pos], /^--?show-original-phonetics(=(.*)?)?$/, group)
if (RSTART) {
Option["show-original-phonetics"] = yn(group[1] ? group[2] : ARGV[++pos])
continue
}
match(ARGV[pos], /^--?show-translation(=(.*)?)?$/, group)
if (RSTART) {
Option["show-translation"] = yn(group[1] ? group[2] : ARGV[++pos])
continue
}
match(ARGV[pos], /^--?show-translation-phonetics(=(.*)?)?$/, group)
if (RSTART) {
Option["show-translation-phonetics"] = yn(group[1] ? group[2] : ARGV[++pos])
continue
}
match(ARGV[pos], /^--?show-prompt-message(=(.*)?)?$/, group)
if (RSTART) {
Option["show-prompt-message"] = yn(group[1] ? group[2] : ARGV[++pos])
continue
}
match(ARGV[pos], /^--?show-languages(=(.*)?)?$/, group)
if (RSTART) {
Option["show-languages"] = yn(group[1] ? group[2] : ARGV[++pos])
continue
}
match(ARGV[pos], /^--?show-original-dictionary(=(.*)?)?$/, group)
if (RSTART) {
Option["show-original-dictionary"] = yn(group[1] ? group[2] : ARGV[++pos])
continue
}
match(ARGV[pos], /^--?show-dictionary(=(.*)?)?$/, group)
if (RSTART) {
Option["show-dictionary"] = yn(group[1] ? group[2] : ARGV[++pos])
continue
}
match(ARGV[pos], /^--?show-alternatives(=(.*)?)?$/, group)
if (RSTART) {
Option["show-alternatives"] = yn(group[1] ? group[2] : ARGV[++pos])
continue
}
match(ARGV[pos], /^--?w(i(d(th?)?)?)?(=(.*)?)?$/, group)
if (RSTART) {
Option["width"] = group[4] ?
(group[5] ? group[5] : Option["width"]) :
ARGV[++pos]
continue
}
match(ARGV[pos], /^--?indent(=(.*)?)?$/, group)
if (RSTART) {
Option["indent"] = group[1] ?
(group[2] ? group[2] : Option["indent"]) :
ARGV[++pos]
continue
}
match(ARGV[pos], /^--?theme(=(.*)?)?$/, group)
if (RSTART) {
Option["theme"] = group[1] ?
(group[2] ? group[2] : Option["theme"]) :
ARGV[++pos]
continue
}
match(ARGV[pos], /^--?no-theme$/)
if (RSTART) {
Option["theme"] = NULLSTR
continue
}
match(ARGV[pos], /^--?no-ansi$/)
if (RSTART) {
Option["no-ansi"] = 1
continue
}
match(ARGV[pos], /^--?no-auto(correct)?$/)
if (RSTART) {
Option["no-autocorrect"] = 1
continue
}
match(ARGV[pos], /^--?no-bidi/)
if (RSTART) {
Option["no-bidi"] = 1
continue
}
match(ARGV[pos], /^--?bidi/)
if (RSTART) {
Option["force-bidi"] = 1
continue
}
match(ARGV[pos], /^--?no-warn/)
if (RSTART) {
Option["no-warn"] = 1
continue
}
match(ARGV[pos], /^--?dump/)
if (RSTART) {
Option["dump"] = 1
continue
}
match(ARGV[pos], /^--?p(l(ay?)?)?$/)
if (RSTART) {
Option["play"] = 1
continue
}
match(ARGV[pos], /^--?sp(e(ak?)?)?$/)
if (RSTART) {
Option["play"] = 2
continue
}
match(ARGV[pos], /^--?(n|narrator)(=(.*)?)?$/, group)
if (RSTART) {
if (!Option["play"]) Option["play"] = 1
Option["narrator"] = group[2] ?
(group[3] ? group[3] : Option["narrator"]) :
ARGV[++pos]
continue
}
match(ARGV[pos], /^--?player(=(.*)?)?$/, group)
if (RSTART) {
if (!Option["play"]) Option["play"] = 1
Option["player"] = group[1] ?
(group[2] ? group[2] : Option["player"]) :
ARGV[++pos]
continue
}
match(ARGV[pos], /^--?no-play$/)
if (RSTART) {
Option["play"] = 0
continue
}
match(ARGV[pos], /^--?no-tran(s(l(a(te?)?)?)?)?$/)
if (RSTART) {
Option["no-translate"] = 1
continue
}
match(ARGV[pos], /^--?download-a(u(d(io?)?)?)?$/)
if (RSTART) {
Option["download-audio"] = 1
continue
}
match(ARGV[pos], /^--?download-audio-as(=(.*)?)?$/, group)
if (RSTART) {
if (!Option["download-audio"]) Option["download-audio"] = 1
Option["download-audio-as"] = group[1] ?
(group[2] ? group[2] : Option["download-audio-as"]) :
ARGV[++pos]
continue
}
match(ARGV[pos], /^--?v(i(ew?)?)?$/)
if (RSTART) {
Option["view"] = 1
continue
}
match(ARGV[pos], /^--?pager(=(.*)?)?$/, group)
if (RSTART) {
Option["view"] = 1
Option["pager"] = group[1] ?
(group[2] ? group[2] : Option["pager"]) :
ARGV[++pos]
continue
}
match(ARGV[pos], /^--?no-(view|pager)$/)
if (RSTART) {
Option["view"] = 0
continue
}
match(ARGV[pos], /^--?browser(=(.*)?)?$/, group)
if (RSTART) {
Option["browser"] = group[1] ?
(group[2] ? group[2] : Option["browser"]) :
ARGV[++pos]
continue
}
match(ARGV[pos], /^--?no-browser$/)
if (RSTART) {
Option["browser"] = NONE
continue
}
match(ARGV[pos], /^--?(x|proxy)(=(.*)?)?$/, group)
if (RSTART) {
Option["proxy"] = group[2] ?
(group[3] ? group[3] : Option["proxy"]) :
ARGV[++pos]
continue
}
match(ARGV[pos], /^--?(u|user-agent)(=(.*)?)?$/, group)
if (RSTART) {
Option["user-agent"] = group[2] ?
(group[3] ? group[3] : Option["user-agent"]) :
ARGV[++pos]
continue
}
match(ARGV[pos], /^--?(4|ipv4|inet4-only)$/)
if (RSTART) {
Option["ip-version"] = 4
continue
}
match(ARGV[pos], /^--?(6|ipv6|inet6-only)$/)
if (RSTART) {
Option["ip-version"] = 6
continue
}
match(ARGV[pos], /^--?(I|int(e(r(a(c(t(i(ve?)?)?)?)?)?)?)?|shell)$/)
if (RSTART) {
Option["interactive"] = 1
continue
}
match(ARGV[pos], /^--?(E|emacs)$/)
if (RSTART) {
Option["emacs"] = 1
continue
}
match(ARGV[pos], /^--?no-rlwrap$/)
if (RSTART) {
Option["no-rlwrap"] = 1
continue
}
match(ARGV[pos], /^--?prompt(=(.*)?)?$/, group)
if (RSTART) {
w("[ERROR] Option '-prompt' has been deprecated since version 0.9.\n"\
"        Use configuration variable 'fmt-prompt' instead.")
exit 1
}
match(ARGV[pos], /^--?prompt-color(=(.*)?)?$/, group)
if (RSTART) {
w("[ERROR] Option '-prompt-color' has been deprecated since version 0.9.\n"\
"        Use configuration variable 'sgr-prompt' instead.")
exit 1
}
match(ARGV[pos], /^--?i(n(p(ut?)?)?)?(=(.*)?)?$/, group)
if (RSTART) {
Option["input"] = group[4] ?
(group[5] ? group[5] : Option["input"]) :
ARGV[++pos]
continue
}
match(ARGV[pos], /^--?o(u(t(p(ut?)?)?)?)?(=(.*)?)?$/, group)
if (RSTART) {
Option["output"] = group[5] ?
(group[6] ? group[6] : Option["output"]) :
ARGV[++pos]
continue
}
match(ARGV[pos], /^--?(host|hl)(=(.*)?)?$/, group)
if (RSTART) {
Option["hl"] = group[2] ?
(group[3] ? group[3] : Option["hl"]) :
ARGV[++pos]
continue
}
match(ARGV[pos], /^--?(l(a(ng?)?)?)(=(.*)?)?$/, group)
if (RSTART) {
w("[WARNING] Option '-l' / '-lang' will be deprecated in the next version.\n"\
"          Use '-hl' / '-host' instead.")
Option["hl"] = group[4] ?
(group[5] ? group[5] : Option["hl"]) :
ARGV[++pos]
continue
}
match(ARGV[pos], /^--?(s(o(u(r(ce?)?)?)?|l)?|f|from)(=(.*)?)?$/, group)
if (RSTART) {
if (group[6]) {
if (group[7]) split(group[7], Option["sls"], "+")
} else
split(ARGV[++pos], Option["sls"], "+")
Option["sl"] = Option["sls"][1]
continue
}
match(ARGV[pos], /^--?t(a(r(g(et?)?)?)?|l|o)?(=(.*)?)?$/, group)
if (RSTART) {
if (group[5]) {
if (group[6]) split(group[6], Option["tl"], "+")
} else
split(ARGV[++pos], Option["tl"], "+")
continue
}
match(ARGV[pos], /^[{(\[]?((@?[[:alpha:]][[:alpha:]][[:alpha:]]?(-[[:alpha:]][[:alpha:]][[:alpha:]]?[[:alpha:]]?)?\+)*(@?[[:alpha:]][[:alpha:]][[:alpha:]]?(-[[:alpha:]][[:alpha:]][[:alpha:]]?[[:alpha:]]?)?)?)?(:|=)((@?[[:alpha:]][[:alpha:]][[:alpha:]]?(-[[:alpha:]][[:alpha:]][[:alpha:]]?[[:alpha:]]?)?\+)*(@?[[:alpha:]][[:alpha:]][[:alpha:]]?(-[[:alpha:]][[:alpha:]][[:alpha:]]?[[:alpha:]]?)?)?)[})\]]?$/, group)
if (RSTART) {
if (group[1]) {
split(group[1], Option["sls"], "+")
Option["sl"] = Option["sls"][1]
}
if (group[7]) split(group[7], Option["tl"], "+")
continue
}
match(ARGV[pos], /^--?j(o(i(n(-(s(e(n(t(e(n(ce?)?)?)?)?)?)?)?)?)?)?)?$/)
if (RSTART) {
Option["join-sentence"] = 1
continue
}
match(ARGV[pos], /^--?(D|debug)$/)
if (RSTART) {
Option["debug"] = 1
continue
}
match(ARGV[pos], /^--?no-init/)
if (RSTART) continue
match(ARGV[pos], /^-(-?no-op)?$/)
if (RSTART) continue
match(ARGV[pos], /^--$/)
if (RSTART) {
++pos
break
}
noargv[noargc++] = ARGV[pos]
}
if (Option["interactive"] && !Option["no-rlwrap"])
rlwrapMe()
else if (Option["emacs"] && !Option["interactive"] && !Option["no-rlwrap"])
if (emacsMe())
Option["interactive"] = 1
initMisc()
switch (InfoOnly) {
case "version":
print getVersion()
exit ExitCode
case "help":
print getHelp()
exit ExitCode
case "manual":
showMan()
exit ExitCode
case "reference":
print getReference("endonym")
exit ExitCode
case "reference-english":
print getReference("name")
exit ExitCode
case "list-engines":
saveSortedIn = PROCINFO["sorted_in"]
PROCINFO["sorted_in"] = "@ind_num_asc"
for (translator in Translator)
print (Option["engine"] == translator ? "* " : "  ") translator
PROCINFO["sorted_in"] = saveSortedIn
exit ExitCode
case "list-languages":
saveSortedIn = PROCINFO["sorted_in"]
PROCINFO["sorted_in"] = "@ind_num_asc"
for (code in Locale)
if (Locale[code]["supported-by"])
print getDisplay(Locale[code]["endonym"])
PROCINFO["sorted_in"] = saveSortedIn
exit ExitCode
case "list-languages-english":
saveSortedIn = PROCINFO["sorted_in"]
PROCINFO["sorted_in"] = "compName"
for (code in Locale)
if (Locale[code]["supported-by"])
print Locale[code]["name"] #(Locale[code]["name2"] ? " / " Locale[code]["name2"] : "")
PROCINFO["sorted_in"] = saveSortedIn
exit ExitCode
case "list-codes":
saveSortedIn = PROCINFO["sorted_in"]
PROCINFO["sorted_in"] = "@ind_num_asc"
for (code in Locale)
if (Locale[code]["supported-by"])
print code
PROCINFO["sorted_in"] = saveSortedIn
exit ExitCode
case "list-all":
saveSortedIn = PROCINFO["sorted_in"]
PROCINFO["sorted_in"] = "compName"
for (code in Locale)
if (Locale[code]["supported-by"])
printf("%-10s %-30s %s\n", code, Locale[code]["name"], getDisplay(Locale[code]["endonym"]))
PROCINFO["sorted_in"] = saveSortedIn
exit ExitCode
case "language":
print getLanguage(Option["tl"])
exit ExitCode
case "upgrade":
upgrade()
exit ExitCode
case "nothing":
exit ExitCode
}
setTheme()
if (Option["interactive"])
welcome()
if (pos < ARGC)
for (i = pos; i < ARGC; i++)
noargv[noargc++] = ARGV[i]
if (noargc > 1 && Option["join-sentence"]) {
noargv[0] = join(noargv, " ")
noargc = 1
}
if (noargc) {
for (i = 0; i < noargc; i++) {
if (Option["verbose"] && i > pos)
p(prettify("source-seperator", replicate(Option["chr-source-seperator"], Option["width"])))
translates(noargv[i], 1)
}
} else {
if (!Option["input"]) Option["input"] = STDIN
}
if (Option["input"])
translateMain()
exit ExitCode
}
