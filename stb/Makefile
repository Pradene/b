COMPILER ?= ../B

SRCS_DIR := srcs
OBJS_DIR := objs
NAME := stb.a

SRCS := $(wildcard $(SRCS_DIR)/*.s)
OBJS := $(patsubst $(SRCS_DIR)/%.s,$(OBJS_DIR)/%.o,$(SRCS))

all: $(NAME)

$(NAME): $(OBJS)
	@ar rcs $@ $^

$(OBJS_DIR)/%.o: $(SRCS_DIR)/%.s | $(OBJS_DIR)
	@gcc -c -m32 -o $@ -x assembler $(SRCS_DIR)/$*.s

$(OBJS_DIR):
	@mkdir -p $@

clean:
	@rm -rf $(OBJS_DIR)

fclean: clean
	@rm -f $(NAME)

re: fclean all

.PHONY: all clean fclean re

