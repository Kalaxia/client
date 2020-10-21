# change wiht your path of your editor
godot-path =
godot-name-executable-main = Godot_v3.2.3-stable

ifeq ($(OS),Windows_NT)
    console = powershell --comand
    godot-sufix = _win64.exe
    copy = copy
    copy-flag = /Y
    rm = del
    rm-flag =
    default-target = compile/windows/kalaxia.exe
else
    console = sh
    godot-sufix = _x11.64
    copy = cp
    copy-flag = -f
    rm = rm
    rm-flag = -f
    default-target = compile/linux/kalaxia.x86_64
endif

file-config-dev = config\development.tres
file-config-prod = config\production.tres
file-config-default = $(file-config-dev)
file-config-used = config\environement_config.tres

git = git 
describe = describe
git-decribe-flag = --tags --long

echo = echo

pybabel = pybabel
pybabel-flags = extract -F babelrc -k text -k LineEdit/placeholder_text -k tr -k hint_tooltip -k translate -o
msgmerge = msgmerge
msgmerge-flags = --update --backup=simple --suffix=.back

godot ?= $(addprefix $(godot-path), $(addsuffix $(godot-sufix), $(godot-name-executable-main)) )
godot-flag = --export

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
debug: compile/windows/kalaxia.exe compile/linux/kalaxia.x86_64


.PHONY: update-translation
update-translation: locales/fr.po locales/en.po


.PHONY: clean-cache
clean-cache:
	$(rm) $(rm-flag) $(cached-data)


%.po: locales/translation.pot
	$(msgmerge) $(msgmerge-flags) $@ $<


%.pot: $(source-files) $(translation-string-files)
	$(pybabel) $(pybabel-flags) $@ .


var := $(shell $(git) $(describe) $(git-decribe-flag))
$(version-file): version_model.txt .FORCE
	$(copy) $(copy-flag) $< $@
	echo version = "$(var)" >> $@


compile/windows/kalaxia.exe: $(source-files) $(version-file)
	$(godot) $(godot-flag) "Windows" $@


compile/linux/kalaxia.x86_64: $(source-files) $(version-file)
	$(godot) $(godot-flag) "Linux" $@


.PHONY: .FORCE
.FORCE: # force the revaluation of the rule even if other prerequesit files are not changed
