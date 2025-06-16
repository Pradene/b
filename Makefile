# Compiler and flags
CC = cc
CFLAGS = -Wall -Wextra

FLEX = flex
BISON = bison

# Directories
SRCS_DIR = srcs
INCS_DIR = includes

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
	rm -rf $(SRCS_DIR) $(PARSER_HEADER)

fclean: clean
	rm -rf $(NAME)

# Force rebuild
re: fclean all

.PHONY: all clean fclean re
