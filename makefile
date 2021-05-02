# change wiht your path of your editor
godot-path =
godot-name-executable-main = Godot_v3.2.3-stable

ifeq ($(OS),Windows_NT)
    console = powershell --comand
    godot-sufix = _win64.exe
    copy = copy
    copy-flag = /Y
    rm = rmdir
    rm-flag = /Q /S
    default-target = compile/windows/kalaxia.exe
    make = mingw32-make
else
    console = sh
    godot-sufix = _x11.64
    copy = cp
    copy-flag = -f
    rm = rm
    rm-flag = -rf
    default-target = compile/linux/kalaxia.x86_64s
    make = make
endif
mkdir = mkdir

file-config-dev = config\development.tres
file-config-prod = config\production.tres
file-config-default = $(file-config-dev)
file-config-used = config\environment_config.tres

git = git
describe = describe
git-decribe-flag-long = --tags --long
git-decribe-flag-short = --tags

echo = echo

pybabel = pybabel
pybabel-flags = extract -F babelrc -k text -k LineEdit/placeholder_text -k tr -k hint_tooltip -k translate -o
msgmerge = msgmerge
msgmerge-flags = --update --backup=simple --suffix=.back

godot ?= $(addprefix $(godot-path), $(addsuffix $(godot-sufix), $(godot-name-executable-main)) )
godot-flag = --export
godot-flag-debug = --export-debug

butler ?= butler

source-sufix = gd tscn tres
source-files = $(foreach sufix, $(source-sufix), $(wildcard *.$(sufix) */*.$(sufix) */*/*.$(sufix) */*/*/*.$(sufix) */*/*/*/*.$(sufix) */*/*/*/*/*.$(sufix)))
translation-string-files = $(wildcard locales/*.txt)
cached-data = cache.tres

version-file = version.tres

.PHONY: all
all: $(default-target)


.PHONY: setup
setup: $(version-file)
	$(copy) $(copy-flag) "$(file-config-dev)" "$(file-config-used)"


.PHONY: production
production: $(source-files) $(version-file) .FORCE
	$(copy) $(copy-flag) "$(file-config-prod)" "$(file-config-used)"
	$(godot) $(godot-flag) "Windows" compile/windows/kalaxia.exe
	$(godot) $(godot-flag) "Linux" compile/linux/kalaxia.x86_64
	$(copy) $(copy-flag) "$(file-config-dev)" "$(file-config-used)"


.PHONY: debug
debug: $(source-files) $(version-file) .FORCE
	$(copy) $(copy-flag) "$(file-config-prod)" "$(file-config-used)"
	$(godot) $(godot-flag-debug) "Windows" compile/windows/kalaxia.exe
	$(godot) $(godot-flag-debug) "Linux" compile/linux/kalaxia.x86_64
	$(copy) $(copy-flag) "$(file-config-dev)" "$(file-config-used)"


.PHONY: debug-local
debug-local: compile/windows/kalaxia.exe compile/linux/kalaxia.x86_64



.PHONY: update-translation
update-translation: locales/fr.po locales/en.po


.PHONY: clean-cache
clean-cache:
	$(rm) $(rm-flag) $(cached-data)


%.po: locales/translation.pot
	$(msgmerge) $(msgmerge-flags) $@ $<


%.pot: $(source-files) $(translation-string-files)
	$(pybabel) $(pybabel-flags) $@ .


var := $(shell $(git) $(describe) $(git-decribe-flag-long))
$(version-file): version_model.txt .FORCE
	$(copy) $(copy-flag) $< $@
	echo version = "$(var)" >> $@


compile/windows/kalaxia.exe: $(source-files) $(version-file)
	$(godot) $(godot-flag) "Windows" $@


compile/linux/kalaxia.x86_64: $(source-files) $(version-file)
	$(godot) $(godot-flag) "Linux" $@

version-short := $(shell $(git) $(describe) $(git-decribe-flag-short))
.PHONY: itch-push-windows
itch-push-windows:
	$(butler) push compile/tmp/. kalaxia-contributors/kalaxia:windows-universal --userversion $(version-short)


.PHONY: itch-push-linux
itch-push-linux:
	$(butler) push compile/tmp/. kalaxia-contributors/kalaxia:linux-universal --userversion $(version-short)

itch-push: .FORCE
	$(make) production
	$(mkdir) "compile/tmp"
	$(copy) $(copy-flag) "compile\windows\kalaxia.exe" "compile\tmp\kalaxia.exe"
	$(copy) $(copy-flag) "compile\windows\kalaxia.pck" "compile\tmp\kalaxia.pck"
	$(make) itch-push-windows
	$(rm) $(rm-flag) "compile/tmp"
	$(mkdir) "compile/tmp"
	$(copy) $(copy-flag) "compile\linux\kalaxia.x86_64" "compile\tmp\kalaxia.x86_64"
	$(copy) $(copy-flag) "compile\linux\kalaxia.pck" "compile\tmp\kalaxia.pck"
	$(make) itch-push-linux
	$(rm) $(rm-flag) "compile/tmp"

.PHONY: .FORCE
.FORCE: # force the revaluation of the rule even if other prerequesit files are not changed
