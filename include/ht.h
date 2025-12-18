#ifndef HAShTABLE_H
#define HAShTABLE_H

#include <assert.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define HT_CAPACITY 16

typedef struct {
  char *key;
  void *value;
} ht_entry;

typedef struct {
  ht_entry *entries;
  size_t capacity;
  size_t length;
} ht;

typedef struct {
  const char *key;
  void *value;

  ht *table;
  size_t index;
} ht_i;

// Create a new Hash table
ht *ht_create(void) {
  ht *table = (ht *)malloc(sizeof(ht));
  if (table == NULL) {
    return NULL;
  }

  table->length = 0;
  table->capacity = HT_CAPACITY;
  table->entries = (ht_entry *)calloc(table->capacity, sizeof(ht_entry));
  if (table->entries == NULL) {
    free(table);
    return NULL;
  }

  return table;
}

// Destroy Hash table
void ht_destroy(ht *table) {
  for (size_t i = 0; i < table->capacity; ++i) {
    free(table->entries[i].key);
  }

  free(table->entries);
  free(table);
}

#define FNV_OFFSET 14695981039346656037UL
#define FNV_PRIME 1099511628211UL

// Hashing function
// Take a string and return the hash (size_t)
size_t ht_hash(const char *key) {
  size_t hash = FNV_OFFSET;
  for (const char *p = key; *p; p++) {
    hash ^= (size_t)(unsigned char)(*p);
    hash *= FNV_PRIME;
  }
  return hash;
}

// Get item with given key (NUL-terminated) from hash table.
// Return value (which was set with ht_set), or NULL if key not found.
void *ht_get(ht *table, const char *key) {
  size_t hash = ht_hash(key);
  size_t index = (hash & (table->capacity - 1));
  while (table->entries[index].key != NULL) {
    if (strcmp(key, table->entries[index].key) == 0) {
      // Found key, return value.
      return table->entries[index].value;
    }
    // Key wasn't in this slot, move to next (linear probing).
    index = (index + 1) % table->capacity;
  }
  return NULL;
}

static const char *ht_set_entry(ht_entry *entries, size_t capacity,
                                const char *key, void *value, size_t *plength) {
  size_t hash = ht_hash(key);
  size_t index = (hash & (size_t)(capacity - 1));

  // Loop till we find an empty entry.
  while (entries[index].key != NULL) {
    if (strcmp(key, entries[index].key) == 0) {
      // Found key (it already exists), update value.
      entries[index].value = value;
      return entries[index].key;
    }
    index = (index + 1) % capacity;
  }

  // Didn't find key, allocate+copy if needed, then insert it.
  if (plength != NULL) {
    key = strdup(key);
    if (key == NULL) {
      return NULL;
    }
    (*plength)++;
  }
  entries[index].key = (char *)key;
  entries[index].value = value;
  return key;
}

// Expand capacity of hash table to 2 times its capacity
// Return true on success
static bool ht_expand(ht *table) {
  // Allocate new entries array.
  size_t new_capacity = table->capacity * 2;
  if (new_capacity < table->capacity) {
    return false; // overflow
  }
  ht_entry *new_entries = (ht_entry *)calloc(new_capacity, sizeof(ht_entry));
  if (new_entries == NULL) {
    return false;
  }

  // Iterate entries, move all non-empty ones to new table's entries.
  for (size_t i = 0; i < table->capacity; i++) {
    ht_entry entry = table->entries[i];
    if (entry.key != NULL) {
      ht_set_entry(new_entries, new_capacity, entry.key, entry.value, NULL);
    }
  }

  // Free old entries array and update this table's details.
  free(table->entries);
  table->entries = new_entries;
  table->capacity = new_capacity;
  return true;
}

// Set item with given key (NUL-terminated) to value (which must not be NULL).
// If not already present in table, key is copied to newly allocated memory
// (keys are freed automatically when ht_destroy is called). Return address of
// copied key, or NULL if out of memory.
const char *ht_set(ht *table, const char *key, void *value) {
  assert(value != NULL);
  if (value == NULL) {
    return NULL;
  }

  // If length will exceed half of current capacity, expand it.
  if (table->length >= table->capacity / 2) {
    if (!ht_expand(table)) {
      return NULL;
    }
  }

  // Set entry and update length.
  return ht_set_entry(table->entries, table->capacity, key, value,
                      &table->length);
}

// Return number of items in hash table.
size_t ht_length(ht *table) { return table->length; }

// Return an iterator on Hash table
ht_i ht_iterator(ht *table) {
  ht_i it;
  it.table = table;
  it.index = 0;
  return it;
}

// Return next element inside the hash table
bool ht_next(ht_i *it) {
  ht *table = it->table;
  while (it->index < table->capacity) {
    size_t i = it->index;
    it->index++;
    if (table->entries[i].key != NULL) {
      // Found next non-empty item, update iterator key and value.
      ht_entry entry = table->entries[i];
      it->key = entry.key;
      it->value = entry.value;
      return true;
    }
  }
  return false;
}

#endif
