yapl_s: y.tab.c lex.yy.c
	gcc -O3 lex.yy.c y.tab.c -o yapl_s
	@echo "Run the program as ./yapl_s [input_file]"

y.tab.c: yapl_s.y 
	yacc -d yapl_s.y

lex.yy.c: yapl_s.l y.tab.h
	lex yapl_s.l

clean:
	@rm -f lex.yy.c y.tab.h y.tab.c yapl_s

test: yapl_s
	@echo "Running all tests"
	@for dir in tests/positive tests/negative tests/misc; do \
		if [ -d $$dir ]; then \
			echo "Testing $$dir..."; \
			for test_file in $$dir/test*.c; do \
				if [ -f $$test_file ]; then \
					base=$$(basename $$test_file .c); \
					test_id=$${base#test}; \
					echo "  Running $$dir/test$$test_id.c"; \
					./yapl_s $$test_file > $$dir/output$$test_id.txt; \
				fi; \
			done; \
		fi; \
	done
	@echo "All tests completed"