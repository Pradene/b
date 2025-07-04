# Compiler and flags
CC = cc
CFLAGS = -Wall -Wextra

FLEX = flex
BISON = bison

# Directories
SRCS_DIR = srcs
INCS_DIR = includes
EXAMPLES_DIR = examples
TEST_DIR = test

# Files
LEX_INPUT = b.l
PARSER_INPUT = b.y

LEX_OUTPUT = $(SRCS_DIR)/lex.yy.c

PARSER_OUTPUT = $(SRCS_DIR)/y.tab.c
PARSER_HEADER = $(INCS_DIR)/y.tab.h

NAME = B

all: $(NAME)

# Create build directory if it doesn't exist
$(SRCS_DIR):
	mkdir -p $(SRCS_DIR)

# Generate parser code from .y file
$(PARSER_OUTPUT) $(PARSER_HEADER): $(PARSER_INPUT) | $(SRCS_DIR)
	$(BISON) -d -o $(PARSER_OUTPUT) $(PARSER_INPUT)
	mv $(SRCS_DIR)/y.tab.h $(PARSER_HEADER)

# Generate lexer code from .l file
$(LEX_OUTPUT): $(LEX_INPUT) $(PARSER_HEADER) | $(SRCS_DIR)
	$(FLEX) -o $(LEX_OUTPUT) $(LEX_INPUT)

# Compile the program with generated lexer and parser
$(NAME): $(LEX_OUTPUT) $(PARSER_OUTPUT) | $(SRCS_DIR)
	$(CC) $(CFLAGS) -I$(INCS_DIR) -o $(NAME) $(LEX_OUTPUT) $(PARSER_OUTPUT)

# Clean generated files
clean:
	rm -rf $(SRCS_DIR) $(PARSER_HEADER) $(TEST_DIR)

fclean: clean
	rm -rf $(NAME)

# Force rebuild
re: fclean all

# Test rule: compile examples and verify return values
test: $(NAME)
	@mkdir -p $(TEST_DIR)
	@echo "Running tests..."
	@for file in $(EXAMPLES_DIR)/*.b; do \
		base=$$(basename "$$file" .b); \
		echo -n "Testing $$file... "; \
		./$(NAME) < "$$file" > $(TEST_DIR)/$$base.s || continue; \
		gcc -c -m32 -o $(TEST_DIR)/$$base.o -x assembler $(TEST_DIR)/$$base.s; \
		ld -m elf_i386 -o $(TEST_DIR)/$$base $(TEST_DIR)/$$base.o brt0.o; \
		$(TEST_DIR)/$$base 1>/dev/null ; \
		retval=$$?; \
		if [ $$retval -eq 0 ]; then \
			echo "\033[32mOK\033[0m"; \
		else \
			echo "\033[31mKO (returned $$retval)\033[0m"; \
		fi; \
	done
	@rm -rf $(TEST_DIR)

.PHONY: all clean fclean re test
