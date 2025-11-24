# Makefile — gera SVGs de todos os .puml na pasta, toggla DEFS.puml e restaura no final.
# Tudo feito aqui: pre-edit, geração, move para diagramas_svg, pós-restore.
SHELL := /bin/bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c

DEFS := DEFS.puml
OUT_DIR := diagramas_svg

# Arquivos a ignorar
EXCLUDE_PUML := DEFS.puml DS-TEMPLATE.puml

# Lista de fontes .puml (avaliada no momento da execução)
SRC_PUML := $(filter-out $(EXCLUDE_PUML), $(wildcard *.puml))

.PHONY: all clean
.DEFAULT_GOAL := all

all:
	@# Segurança: se não há arquivos .puml além dos excluídos, aborta com mensagem.
	if [ -z "$(SRC_PUML)" ]; then
	  echo "Erro: nenhum arquivo .puml encontrado para processar."
	  echo "Arquivos .puml nesta pasta (antes de excluir):"
	  ls -1 *.puml 2>/dev/null || true
	  echo "OBS: excluindo: $(EXCLUDE_PUML)"
	  exit 1
	fi

	# Função de restauração (usada no trap e ao final)
	restore_defs() {
	  if [ -f "$(DEFS)" ]; then
	    echo "[REFACTOR-SCRIPT] Restaurando linhas em $(DEFS)..."
	    perl -0777 -pe "s/^[\t ]*!option[\t ]+handwritten[\t ]+true/'!option handwritten true/gm; s/^[\t ]*'skinparam[\t ]+Handwritten[\t ]+true/skinparam Handwritten true/gm;" "$(DEFS)" > "$(DEFS).tmp" && mv "$(DEFS).tmp" "$(DEFS)" || echo "[REFACTOR-SCRIPT] erro ao tentar restaurar, verifique $(DEFS).tmp"
	    echo "[REFACTOR-SCRIPT] Pronto."
	  else
	    echo "[REFACTOR-SCRIPT] Aviso: $(DEFS) não encontrado — nada a restaurar."
	  fi
	}

	# Trap para garantir restauração caso haja interrupção (INT/TERM/EXIT)
	trap 'echo "[trap] sinal recebido — executando restauração..."; restore_defs; exit 130' INT TERM
	trap 'echo "[PUML_WORKBENCH] processo finalizando — garantindo restauração..."; restore_defs' EXIT

	# PRE: aplicar alterações em DEFS.puml (sem backup permanente)
	if [ -f "$(DEFS)" ]; then
	  echo "[INITIAL-SCRIPT] aplicando alterações em $(DEFS)..."
	  perl -0777 -pe "s/^[\t ]*'!option[\t ]+handwritten[\t ]+true/!option handwritten true/gm; s/^[\t ]*skinparam[\t ]+Handwritten[\t ]+true/'skinparam Handwritten true/gm;" "$(DEFS)" > "$(DEFS).tmp" && mv "$(DEFS).tmp" "$(DEFS)" || (echo "[INITIAL-SCRIPT] erro ao editar $(DEFS)"; exit 2)
	  echo "[INITIAL-SCRIPT] Pronto."
	else
	  echo "[INITIAL-SCRIPT] Aviso: $(DEFS) não encontrado — prosseguindo sem alterações."
	fi

	# Geração: para cada .puml, gerar SVG e mover para OUT_DIR
	echo "Arquivos a processar:"
	for f in $(SRC_PUML); do
	  echo "  - $$f"
	done

	mkdir -p "$(OUT_DIR)"

	for f in $(SRC_PUML); do
	  echo "[PUML_WORKBENCH] Processando $$f ..."
	  plantuml -tsvg "$$f" || (echo "[PUML_WORKBENCH] plantuml falhou para $$f"; exit 3)
	  svgfile="$${f%.puml}.svg"
	  if [ -f "$$svgfile" ]; then
	    mv -f "$$svgfile" "$(OUT_DIR)/" || (echo "[PUML_WORKBENCH] erro movendo $$svgfile para $(OUT_DIR)"; exit 4)
	    echo "[PUML_WORKBENCH] $$svgfile -> $(OUT_DIR)/"
	  else
	    echo "[PUML_WORKBENCH] Aviso: esperado $$svgfile mas não encontrado"
	    exit 5
	  fi
	done

	# Gerar lista dos SVGs gerados (apenas nomes, sem caminho, ordenados)
	echo "[PUML_WORKBENCH] registrando arquivos SVG em script_readme/FILES_LIST.txt..."
	ls -1 "$(OUT_DIR)"/*.svg | xargs -n1 basename | sort > script_readme/FILES_LIST.txt
	echo "[PUML_WORKBENCH] script_readme/FILES_LIST.txt atualizado."

	# Gerar script_readme/FILES_AUTOMATION.txt com formato específico (ordenado conforme script_readme/FILES_LIST.txt)
	echo "[PUML_WORKBENCH] gerando script_readme/FILES_AUTOMATION.txt..."
	printf "" > script_readme/FILES_AUTOMATION.txt
	while IFS= read -r svgname || [ -n "$$svgname" ]; do
	  project="$${svgname%.svg}"
	  printf "### %s:\n" "$$project" >> script_readme/FILES_AUTOMATION.txt
	  printf "![%s](https://github.com/Embrapac/diagramas/blob/main/diagramas_svg/%s.svg)\n\n" "$$project" "$$project" >> script_readme/FILES_AUTOMATION.txt
	done < script_readme/FILES_LIST.txt
	echo "[PUML_WORKBENCH] script_readme/FILES_AUTOMATION.txt atualizado."

	# --- NOVO: garantir permissão e executar script script_readme/ADD_IMAGE.sh (se existir)
	if [ -f "./script_readme/ADD_IMAGE.sh" ]; then
	  echo "[PUML_WORKBENCH] encontrado script_readme/ADD_IMAGE.sh — definindo permissão e executando..."
	  chmod +x ./script_readme/ADD_IMAGE.sh || true
	  ./script_readme/ADD_IMAGE.sh || (echo "[PUML_WORKBENCH] script_readme/ADD_IMAGE.sh executado com erro" ; exit 6)
	  echo "[PUML_WORKBENCH] script_readme/ADD_IMAGE.sh executado com sucesso."
	else
	  echo "[PUML_WORKBENCH] Aviso: script_readme/ADD_IMAGE.sh não encontrado — pulando atualização do README.md."
	fi

	# (post_defs será chamado automaticamente pelo trap EXIT)
	echo "[PUML_WORKBENCH] Geração concluída — saída em $(OUT_DIR)."

clean:
	@echo ">>> Limpando $(OUT_DIR) ..."
	@rm -f $(OUT_DIR)/*.svg || true
	clear
	@echo ">>> Limpeza concluída."
	@sleep 1
	clear