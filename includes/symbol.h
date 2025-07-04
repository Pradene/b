#ifndef SYMBOL_H
#define SYMBOL_H

#include "ht.h"
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>

typedef struct Scope Scope;

typedef enum { EXTERNAL, AUTOMATIC, INTERNAL, LABEL } Storage;
typedef enum { VARIABLE, POINTER } SymbolType;

typedef struct {
  char *name;
  SymbolType type;
  Scope *scope;
  size_t offset;
  Storage storage;
} Symbol;

// Scope struct to store all variables defined inside of it
// So we can check if a variable is defined when accessing value
struct Scope {
  Scope *parent;
  size_t local_offset;
  size_t param_offset;
  size_t depth;
  ht *symbols;
};

Scope *current_scope = NULL;

// Create a new scope
void scope_create() {
  Scope *scope = (Scope *)malloc(sizeof(Scope));
  if (scope == NULL) {
    return;
  }
  scope->local_offset = 0;
  scope->param_offset = 4;
  scope->depth = current_scope ? current_scope->depth + 1 : 0;
  scope->symbols = ht_create();
  scope->parent = current_scope;
  current_scope = scope;
}

// Destroy the current scope
void scope_destroy() {
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
Symbol *symbol_add(char *name, SymbolType type, Storage storage) {
  if (ht_get(current_scope->symbols, name) != NULL) {
    return NULL;
  }

  Symbol *symbol = (Symbol *)malloc(sizeof(Symbol));
  if (symbol == NULL) {
    return NULL;
  }

  if (storage == AUTOMATIC) {
    current_scope->local_offset += 4;
    symbol->offset = current_scope->local_offset;
  } else if (storage == INTERNAL) {
    current_scope->param_offset += 4;
    symbol->offset = current_scope->param_offset;
  } else {
    symbol->offset = 0;
  }

  symbol->name = strdup(name);
  symbol->scope = current_scope;
  symbol->storage = storage;
  symbol->type = type;

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
