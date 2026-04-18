CC := gcc
CFLAGS := -O3
YACC := yacc
LEX := lex

OLD_COMPILER := yapl_s
NEW_COMPILER := yapl_s_new

OLD_Y := yapl_s.y
OLD_L := yapl_s.l
NEW_Y := yapl_s_new.y
NEW_L := yapl_s_new.l

OLD_TAB_C := old_y.tab.c
OLD_TAB_H := old_y.tab.h
OLD_LEX_C := old_lex.yy.c

NEW_TAB_C := new_y.tab.c
NEW_TAB_H := new_y.tab.h
NEW_LEX_C := new_lex.yy.c

SYMTAB_SRC := symtab.c

.PHONY: all clean test test_old test_new

all: $(OLD_COMPILER) $(NEW_COMPILER)

$(OLD_COMPILER): $(OLD_TAB_C) $(OLD_LEX_C)
	@cp -f $(OLD_TAB_H) y.tab.h
	$(CC) $(CFLAGS) $(OLD_LEX_C) $(OLD_TAB_C) $(SYMTAB_SRC) -o $(OLD_COMPILER)
	@echo "Run the program as ./$(OLD_COMPILER) [input_file]"

$(NEW_COMPILER): $(NEW_TAB_C) $(NEW_LEX_C)
	@cp -f $(NEW_TAB_H) y.tab.h
	$(CC) $(CFLAGS) $(NEW_LEX_C) $(NEW_TAB_C) $(SYMTAB_SRC) -o $(NEW_COMPILER)
	@echo "Run the program as ./$(NEW_COMPILER) [input_file]"

$(OLD_TAB_C) $(OLD_TAB_H): $(OLD_Y)
	$(YACC) -d $(OLD_Y)
	@mv -f y.tab.c $(OLD_TAB_C)
	@mv -f y.tab.h $(OLD_TAB_H)

$(NEW_TAB_C) $(NEW_TAB_H): $(NEW_Y)
	$(YACC) -d $(NEW_Y)
	@mv -f y.tab.c $(NEW_TAB_C)
	@mv -f y.tab.h $(NEW_TAB_H)

$(OLD_LEX_C): $(OLD_L) $(OLD_TAB_H)
	@cp -f $(OLD_TAB_H) y.tab.h
	$(LEX) -o $(OLD_LEX_C) $(OLD_L)

$(NEW_LEX_C): $(NEW_L) $(NEW_TAB_H)
	@cp -f $(NEW_TAB_H) y.tab.h
	$(LEX) -o $(NEW_LEX_C) $(NEW_L)

clean:
	@rm -f \
		$(OLD_LEX_C) $(OLD_TAB_H) $(OLD_TAB_C) $(OLD_COMPILER) \
		$(NEW_LEX_C) $(NEW_TAB_H) $(NEW_TAB_C) $(NEW_COMPILER) \
		derivation_tree.dot y.output y.tab.h lex.yy.c

test: test_old test_new
	@echo "All tests completed"

test_old: $(OLD_COMPILER)
	@echo "Running tests with $(OLD_COMPILER)"
	@for dir in tests/positive tests/negative tests/misc; do \
		if [ -d $$dir ]; then \
			echo "Testing $$dir..."; \
			for test_file in $$dir/test*.c; do \
				if [ -f $$test_file ]; then \
					base=$$(basename $$test_file .c); \
					test_id=$${base#test}; \
					echo "  Running $$dir/test$$test_id.c"; \
					./$(OLD_COMPILER) $$test_file > $$dir/output_old_$$test_id.txt; \
				fi; \
			done; \
		fi; \
	done

test_new: $(NEW_COMPILER)
	@echo "Running tests with $(NEW_COMPILER)"
	@for dir in tests/positive tests/negative tests/misc; do \
		if [ -d $$dir ]; then \
			echo "Testing $$dir..."; \
			for test_file in $$dir/test*.c; do \
				if [ -f $$test_file ]; then \
					base=$$(basename $$test_file .c); \
					test_id=$${base#test}; \
					echo "  Running $$dir/test$$test_id.c"; \
					./$(NEW_COMPILER) $$test_file > $$dir/output_new_$$test_id.txt; \
					if [ -f derivation_tree.dot ]; then \
						dot -Tsvg derivation_tree.dot -o $$dir/tree_new_$$test_id.svg; \
						rm -f derivation_tree.dot; \
					fi; \
				fi; \
			done; \
		fi; \
	done