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

STB = stb.a
STB_DIR = stb

LEX_OUTPUT = $(SRCS_DIR)/lex.yy.c
PARSER_OUTPUT = $(SRCS_DIR)/y.tab.c
PARSER_HEADER = $(INCS_DIR)/y.tab.h

NAME = B

# Collect example .b files and corresponding .s, .o, executable names
EXAMPLES = $(wildcard $(EXAMPLES_DIR)/*.b)
SOURCES = $(patsubst $(EXAMPLES_DIR)/%.b,$(TEST_DIR)/%.s,$(EXAMPLES))
OBJECTS = $(patsubst $(EXAMPLES_DIR)/%.b,$(TEST_DIR)/%.o,$(EXAMPLES))
BINARIES = $(patsubst $(EXAMPLES_DIR)/%.b,$(TEST_DIR)/%,$(EXAMPLES))

all: $(NAME) $(STB)

# Create necessary directories
$(SRCS_DIR):
	@mkdir -p $(SRCS_DIR)

$(TEST_DIR):
	@mkdir -p $(TEST_DIR)

# Parser generation
$(PARSER_OUTPUT) $(PARSER_HEADER): $(PARSER_INPUT) | $(SRCS_DIR)
	$(BISON) -d -o $(PARSER_OUTPUT) $(PARSER_INPUT)
	mv $(SRCS_DIR)/y.tab.h $(PARSER_HEADER)

# Lexer generation
$(LEX_OUTPUT): $(LEX_INPUT) $(PARSER_HEADER) | $(SRCS_DIR)
	$(FLEX) -o $@ $(LEX_INPUT)

# Compiler binary
$(NAME): $(LEX_OUTPUT) $(PARSER_OUTPUT)
	$(CC) $(CFLAGS) -I$(INCS_DIR) -o $@ $(LEX_OUTPUT) $(PARSER_OUTPUT)

# Pattern rule to compile .b → .s using ./B
$(TEST_DIR)/%.s: $(EXAMPLES_DIR)/%.b $(NAME) | $(TEST_DIR)
	@./$(NAME) < $< > $@

# Pattern rule to compile .s → .o
$(TEST_DIR)/%.o: $(TEST_DIR)/%.s
	@gcc -c -m32 -o $@ -x assembler $<

# Pattern rule to link .o → executable
$(TEST_DIR)/%: $(TEST_DIR)/%.o $(STB)
	@ld -m elf_i386 -o $@ $< brt0.o $(STB_DIR)/$(STB)

# Run tests
tests: $(BINARIES)
	@echo "Running tests..."
	@for bin in $(BINARIES); do \
		echo -n "Testing $$bin... "; \
		$$bin > /dev/null; \
		code=$$?; \
		if [ $$code -eq 0 ]; then \
			echo "\033[32mOK\033[0m"; \
		else \
			echo "\033[31mKO (returned $$code)\033[0m"; \
		fi; \
	done

$(STB): $(NAME)
	@$(MAKE) -C $(STB_DIR)

# Clean generated files
clean:
	@rm -rf $(SRCS_DIR) $(TEST_DIR) $(PARSER_HEADER)

fclean: clean
	@rm -f $(NAME)

re: fclean all

.PHONY: all clean fclean re tests stb.a

