# Makefile — gera SVGs de todos os .puml na pasta.
# Tudo feito aqui: verificação, geração, move para diagramas_svg, update README.
SHELL := /bin/bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c

DEFS := DEFS.puml
OUT_DIR := diagramas_svg

# Arquivos a ignorar (nome base, sem caminho)
EXCLUDE_PUML := DEFS.puml DS-TEMPLATE.puml

# Função para wildcard recursivo
rwildcard = $(wildcard $1$2) $(foreach d,$(wildcard $1*),$(call rwildcard,$d/,$2))

# Lista de fontes .puml (recursivo a partir do diretório atual)
ALL_PUML := $(call rwildcard,./,*.puml)

# Filtra os arquivos a excluir comparando só o nome base
SRC_PUML := $(filter-out $(EXCLUDE_PUML), \
             $(notdir $(ALL_PUML)))

# Lista com caminhos completos dos arquivos fonte (para usar no for)
SRC_PUML_FULL := $(filter-out $(addprefix ./,$(EXCLUDE_PUML)), \
                  $(ALL_PUML))

.PHONY: all clean
.DEFAULT_GOAL := all

all:
	@# Verificação de segurança: aborta se não houver arquivos
	if [ -z "$(SRC_PUML_FULL)" ]; then \
		echo "Erro: nenhum arquivo .puml encontrado para processar."; \
		echo "Arquivos .puml encontrados (antes de excluir):"; \
		find . -name '*.puml' -maxdepth 5 2>/dev/null || true; \
		echo "OBS: excluindo: $(EXCLUDE_PUML)"; \
		exit 1; \
	fi

ifneq ($(SRC_PUML_FULL),)
	# Exibe a lista de arquivos a serem processados (um por linha)
	echo "Arquivos a processar:";
	for f in $(SRC_PUML_FULL); do \
		echo "  - $$f"; \
	done

	# Cria diretório de saída
	mkdir -p "$(OUT_DIR)"

	# Loop de processamento
	for f in $(SRC_PUML_FULL); do \
		base="$${f##*/}"; \
		name="$${base%.puml}"; \
		dir="$$(dirname "$$f")"; \
		echo "[PUML_WORKBENCH] Processando $$f ..."; \
		plantuml -tsvg -o "$$PWD" "$$f" || (echo "[PUML_WORKBENCH] plantuml falhou para $$f"; exit 3); \
		svgfile="$$name.svg"; \
		if [ -f "$$svgfile" ]; then \
			mv -f "$$svgfile" "$(OUT_DIR)/" || (echo "[PUML_WORKBENCH] erro movendo $$svgfile para $(OUT_DIR)"; exit 4); \
			echo "[PUML_WORKBENCH] $$svgfile -> $(OUT_DIR)/"; \
		else \
			echo "[PUML_WORKBENCH] Aviso: esperado $$svgfile mas não encontrado"; \
			exit 5; \
		fi; \
	done

endif

	# Gerar lista dos SVGs gerados (apenas nomes, sem caminho, ordenados)
	echo "[PUML_WORKBENCH] registrando arquivos SVG em script_readme/FILES_LIST.txt..."
	ls -1 "$(OUT_DIR)"/*.svg | xargs -n1 basename | sort > script_readme/FILES_LIST.txt
	echo "[PUML_WORKBENCH] script_readme/FILES_LIST.txt atualizado."

	# Gerar script_readme/FILES_AUTOMATION.txt
	echo "[PUML_WORKBENCH] gerando script_readme/FILES_AUTOMATION.txt..."
	printf "" > script_readme/FILES_AUTOMATION.txt; \
	while IFS= read -r svgname || [ -n "$$svgname" ]; do \
		project="$${svgname%.svg}"; \
		printf "### %s:\n" "$$project" >> script_readme/FILES_AUTOMATION.txt; \
		printf "![%s](https://github.com/Embrapac/diagramas/blob/main/diagramas_svg/%s.svg)\n\n" "$$project" "$$project" >> script_readme/FILES_AUTOMATION.txt; \
	done < script_readme/FILES_LIST.txt
	echo "[PUML_WORKBENCH] script_readme/FILES_AUTOMATION.txt atualizado."

	# Executar script script_readme/ADD_IMAGE.sh (se existir)
	if [ -f "./script_readme/ADD_IMAGE.sh" ]; then \
		echo "[PUML_WORKBENCH] encontrado script_readme/ADD_IMAGE.sh — definindo permissão e executando..."; \
		chmod +x ./script_readme/ADD_IMAGE.sh || true; \
		./script_readme/ADD_IMAGE.sh || (echo "[PUML_WORKBENCH] script_readme/ADD_IMAGE.sh executado com erro" ; exit 6); \
		echo "[PUML_WORKBENCH] script_readme/ADD_IMAGE.sh executado com sucesso."; \
	else \
		echo "[PUML_WORKBENCH] Aviso: script_readme/ADD_IMAGE.sh não encontrado — pulando atualização do README.md."; \
	fi

	# Exportar esquemático KiCad
	echo "[KICAD_EXPORT] Iniciando exportação do KiCad..."
	cd esquematicos/embrapac-mcu
	kicad-cli sch export svg --exclude-drawing-sheet --output ../../ embrapac-mcu.kicad_sch && mv ../../embrapac-mcu.svg ../../MCU-SCHEMATIC.svg
	cd ../..
	mv MCU-SCHEMATIC.svg diagramas_svg/

	clear
	@echo "   _____________________________________________________ "
	@echo "  /                                                     \\"
	@echo " |  >>> Pasta diagramas_svg atualizada com sucesso !     |"
	@echo " |  >>> O README já foi atualizado com as novas imagens! |"
	@echo " |  >>> KiCad SVG exportado com sucesso!                 |"
	@echo "  \___________      ____________________________________/"
	@echo "              \\   /"
	@echo "               \\ /"
	@echo "                  .--. "
	@echo "                 |o_o | "
	@echo "                 |:_/ | "
	@echo "                //   \\ \\ "
	@echo "               (|     | ) "
	@echo "              /'\\_   _/\`\\ "
	@echo "              \\___)=(___/ "
	@echo " "
	@echo " "

clean:
	@echo ">>> Limpando $(OUT_DIR) ..."
	@rm -f $(OUT_DIR)/*.svg || true
	clear
	@echo "   _____________________________________ "
	@echo "  /                                     \\"
	@echo " |  >>> Limpeza na pasta svg concluída  |"
	@echo "  \___________      ____________________/"
	@echo "              \\   /"
	@echo "               \\ /"
	@echo "                  .--. "
	@echo "                 |o_o | "
	@echo "                 |:_/ | "
	@echo "                //   \\ \\ "
	@echo "               (|     | ) "
	@echo "              /'\\_   _/\`\\ "
	@echo "              \\___)=(___/ "
	@echo " "
	@sleep 0.8
	clear