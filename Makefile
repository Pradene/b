# Compiler and flags
CC = cc
CFLAGS = -Wall -Wextra

FLEX = flex
BISON = bison

# Directories
BUILD_DIR = build
INCS_DIR = includes

# Files
LEX_INPUT = b.l
LEX_OUTPUT = $(BUILD_DIR)/lex.yy.c

PARSER_INPUT = b.y
PARSER_OUTPUT = $(BUILD_DIR)/y.tab.c
PARSER_HEADER = $(INCS_DIR)/y.tab.h

NAME = B

all: $(NAME)

# Create build directory if it doesn't exist
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

# Generate parser code from .y file
$(PARSER_OUTPUT) $(PARSER_HEADER): $(PARSER_INPUT) | $(BUILD_DIR)
	$(BISON) -d -o $(PARSER_OUTPUT) $(PARSER_INPUT)

# Generate lexer code from .l file
$(LEX_OUTPUT): $(LEX_INPUT) $(PARSER_HEADER) | $(BUILD_DIR)
	$(FLEX) -o $(LEX_OUTPUT) $(LEX_INPUT)

# Compile the program with generated lexer and parser
$(NAME): $(LEX_OUTPUT) $(PARSER_OUTPUT) | $(BUILD_DIR)
	$(CC) $(CFLAGS) -I$(INCS_DIR) -o $(NAME) $(LEX_OUTPUT) $(PARSER_OUTPUT)

# Clean generated files
clean:
	rm -rf $(BUILD_DIR)

fclean: clean
	rm -rf $(NAME)

# Force rebuild
re: fclean all

.PHONY: all clean fclean re
