#ifndef SYMBOL_H
#define SYMBOL_H

#include "ht.h"
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>

typedef struct Scope Scope;

typedef struct {
  size_t line;
  size_t offset;
} Positon;

typedef struct {
  char *name;
  Positon pos;
  Scope *scope;
} Symbol;

// Scope struct to store all variables defined inside of it
// So we can check if a variable is defined when accessing value
struct Scope {
  size_t depth;
  ht *symbols;
  Scope *parent;
};

Scope *current_scope = NULL;

// Create a new scope
void scope_create() {
  printf("Scope created\n");
  Scope *scope = (Scope *)malloc(sizeof(Scope));
  if (scope == NULL) {
    return;
  }
  scope->depth = current_scope ? current_scope->depth + 1 : 0;
  scope->symbols = ht_create();
  scope->parent = current_scope;
  current_scope = scope;
}

// Destroy the current scope
void scope_destroy() {
  printf("Scope destroyed\n");
  if (current_scope != NULL) {
    Scope *scope = current_scope;

    for (size_t i = 0; i < scope->symbols->capacity; ++i) {
      if (scope->symbols->entries[i].key) {
        Symbol *symbol = (Symbol *)scope->symbols->entries[i].value;
        free(symbol->name);
        free(symbol);
      }
    }

    ht_destroy(scope->symbols);
    current_scope = current_scope->parent;
    free(scope);
  }
}

// Add a variable inside the scope
Symbol *symbol_add(char *name, Positon pos) {
  if (ht_get(current_scope->symbols, name) != NULL) {
    return NULL;
  }

  Symbol *symbol = (Symbol *)malloc(sizeof(Symbol));
  if (symbol == NULL) {
    return NULL;
  }
  symbol->name = strdup(name);
  symbol->scope = current_scope;
  symbol->pos = pos;

  ht_set(current_scope->symbols, name, symbol);
  return symbol;
}

// Find a variable inside the current scope
Symbol *symbol_find(const char *name) {
  return (Symbol *)ht_get(current_scope->symbols, name);
}

// Find a variable inside all parents scope
Symbol *symbol_find_global(const char *name) {
  Scope *scope = current_scope;

  while (scope != NULL) {
    Symbol *symbol = (Symbol *)ht_get(scope->symbols, name);
    if (symbol != NULL) {
      return symbol;
    }
    scope = scope->parent;
  }
  return NULL;
}

#endif
