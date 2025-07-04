COMPILER ?= ../B

SRCS_DIR := srcs
OBJS_DIR := objs
NAME := stb.a

SRCS := $(wildcard $(SRCS_DIR)/*.b)
OBJS := $(patsubst $(SRCS_DIR)/%.b,$(OBJS_DIR)/%.o,$(SRCS))

all: $(NAME)

$(NAME): $(OBJS)
	@ar rcs $@ $^

$(OBJS_DIR)/%.o: $(SRCS_DIR)/%.b | $(OBJS_DIR)
	@$(COMPILER) < $< > $(OBJS_DIR)/$*.s
	@gcc -c -m32 -o $@ -x assembler $(OBJS_DIR)/$*.s

$(OBJS_DIR):
	@mkdir -p $@

clean:
	@rm -rf $(OBJS_DIR)

fclean: clean
	@rm -f $(NAME)

re: fclean all

.PHONY: all clean fclean re

