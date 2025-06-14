# Compiler and flags
CC = cc
CFLAGS = -Wall -Wextra
FLEX = flex

# Directories
LEXER_DIR = lexer
BUILD_DIR = build
SRCS_DIR = srcs

# Files
LEX_FILE = $(LEXER_DIR)/lex.l
LEX_OUTPUT = $(BUILD_DIR)/lex.yy.c
LEX_HEADER = $(BUILD_DIR)/lex.yy.h
MAIN_SRC = $(SRCS_DIR)/main.c
NAME = B

all: $(NAME)

# Create build directory if it doesn't exist
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

# Generate lexer code from .l file
$(LEX_OUTPUT): $(LEX_FILE) | $(BUILD_DIR)
	$(FLEX) -o $(LEX_OUTPUT) $(LEX_FILE)

# Compile the program with generated lexer
$(NAME): $(LEX_OUTPUT) $(MAIN_SRC) | $(BUILD_DIR)
	$(CC) $(CFLAGS) -I$(BUILD_DIR) -o $(NAME) $(MAIN_SRC) $(LEX_OUTPUT)

# Clean generated files
clean:
	rm -rf $(BUILD_DIR)

fclean: clean
	rm -rf $(NAME)

# Force rebuild
re: fclean all

.PHONY: all clean fclean re
