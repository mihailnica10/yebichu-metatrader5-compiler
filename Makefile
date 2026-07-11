DEV         := Development
COMPILE_SH  := $(DEV)/compile.sh
MQL5_INCL   := $(CURDIR)/MQ5/Include
MQL5_LIBS   := $(CURDIR)/MQ5/Libraries
MQL5_OUT    := $(CURDIR)/MQ5/Experts
IMAGE       := yebichu-mql5-compiler:latest

.PHONY: all init build compile clean

all: build compile

init:
	@if [ -d MQ5/.git ]; then \
		echo "[init] MQ5/ already initialized"; \
	else \
		echo "[init] Cloning MQ5 template..."; \
		git submodule update --init MQ5; \
	fi
	@if [ ! -f MQ5/Experts/MyEA/MyEA.mq5 ]; then \
		echo "[init] Creating MyEA from template..."; \
		mkdir -p MQ5/Experts/MyEA MQ5/Include; \
		cp $(DEV)/template/MyEA.mq5 MQ5/Experts/MyEA/; \
		cp $(DEV)/template/MyLib.mqh MQ5/Include/; \
		echo "[init] Done. Edit MQ5/Experts/MyEA/MyEA.mq5 and run make compile"; \
	else \
		echo "[init] MyEA already exists, skipping"; \
	fi

build:
	docker build -t $(IMAGE) $(DEV)

compile:
	@if [ -n "$(SRC)" ]; then \
		$(COMPILE_SH) \
			--include $(MQL5_INCL) \
			--libraries $(MQL5_LIBS) \
			--output $(MQL5_OUT) \
			"$(SRC)"; \
	else \
		FILES=(); \
		while IFS= read -r -d '' f; do \
			FILES+=("$$f"); \
		done < <(find MQ5/Experts -name '*.mq5' -type f -print0 2>/dev/null | sort -z); \
		if [ $${#FILES[@]} -eq 0 ]; then \
			echo "ERROR: no .mq5 files found under MQ5/Experts/" >&2; \
			echo "Run 'make init' to create a starter EA." >&2; \
			exit 1; \
		elif [ $${#FILES[@]} -eq 1 ]; then \
			$(COMPILE_SH) \
				--include $(MQL5_INCL) \
				--libraries $(MQL5_LIBS) \
				--output $(MQL5_OUT) \
				"$${FILES[0]}"; \
		else \
			echo ""; \
			echo "  Multiple .mq5 files found. Pick one:"; \
			echo ""; \
			PS3="  Select file (number): "; \
			select SRC in "$${FILES[@]}"; do \
				if [ -n "$$SRC" ]; then \
					echo ""; \
					$(COMPILE_SH) \
						--include $(MQL5_INCL) \
						--libraries $(MQL5_LIBS) \
						--output $(MQL5_OUT) \
						"$$SRC"; \
					break; \
				fi; \
			done; \
		fi; \
	fi

clean:
	rm -f MQ5/Experts/**/*.ex5
	rm -f MQ5/Experts/**/*.log
	docker rmi $(IMAGE) 2>/dev/null || true
