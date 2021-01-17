#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "hashTable.h"

#define CAPACITY 50000 // Size of the Hash Table

unsigned long hash_function(char* str) {
    unsigned long i = 0;
    for (int j=0; str[j]; j++)
        i += str[j];
    return i % CAPACITY;
}
 
static LinkedList* allocate_list () {
    // Allocates memory for a Linkedlist pointer
    LinkedList* list = (LinkedList*) malloc (sizeof(LinkedList));
    return list;
}
 
static LinkedList* linkedlist_insert(LinkedList* list, Ht_item* item) {
    // Inserts the item onto the Linked List
    if (!list) {
        LinkedList* head = allocate_list();
        head->item = item;
        head->next = NULL;
        list = head;
        return list;
    } 
     
    else if (list->next == NULL) {
        LinkedList* node = allocate_list();
        node->item = item;
        node->next = NULL;
        list->next = node;
        return list;
    }
 
    LinkedList* temp = list;
    while (temp->next->next) {
        temp = temp->next;
    }
     
    LinkedList* node = allocate_list();
    node->item = item;
    node->next = NULL;
    temp->next = node;
     
    return list;
}
 
static Ht_item* linkedlist_remove(LinkedList* list) {
    // Removes the head from the linked list
    // and returns the item of the popped element
    if (!list)
        return NULL;
    if (!list->next)
        return NULL;
    LinkedList* node = list->next;
    LinkedList* temp = list;
    temp->next = NULL;
    list = node;
    Ht_item* it = NULL;
    memcpy(temp->item, it, sizeof(Ht_item));
    free(temp->item->identifier);
    free(temp->item->varInfo);
    free(temp->item);
    free(temp);
    return it;
}
 
static void free_linkedlist(LinkedList* list) {
    LinkedList* temp = list;
    while (list) {
        temp = list;
        list = list->next;
        free(temp->item->identifier);
        free(temp->item->varInfo);
        free(temp->item);
        free(temp);
    }
}
 
static LinkedList** create_overflow_buckets(HashTable* table) {
    // Create the overflow buckets; an array of linkedlists
    LinkedList** buckets = (LinkedList**) calloc (table->size, sizeof(LinkedList*));
    for (int i=0; i<table->size; i++)
        buckets[i] = NULL;
    return buckets;
}
 
static void free_overflow_buckets(HashTable* table) {
    // Free all the overflow bucket lists
    LinkedList** buckets = table->overflow_buckets;
    for (int i=0; i<table->size; i++)
        free_linkedlist(buckets[i]);
    free(buckets);
}
 
 
Ht_item* create_item(char* identifier, varInfo* varInfo) {
    // Creates a pointer to a new hash table item
    Ht_item* item = (Ht_item*) malloc (sizeof(Ht_item));
    item->identifier = (char*) malloc (strlen(identifier) + 1);
    item->varInfo = (struct varInfo*) malloc (sizeof(varInfo));
    item->identifier = strdup(identifier);
    item->varInfo->type = strdup(varInfo->type);
    item->varInfo->varPos = varInfo->varPos;
 
    return item;
}
 
HashTable* create_table(int size) {
    // Creates a new HashTable
    HashTable* table = (HashTable*) malloc (sizeof(HashTable));
    table->size = size;
    table->count = 0;
    table->items = (Ht_item**) calloc (table->size, sizeof(Ht_item*));
    for (int i=0; i<table->size; i++)
        table->items[i] = NULL;
    table->overflow_buckets = create_overflow_buckets(table);
 
    return table;
}
 
void free_item(Ht_item* item) {
    // Frees an item
    free(item->identifier);
    free(item->varInfo);
    free(item);
}
 
void free_table(HashTable* table) {
    // Frees the table
    for (int i=0; i<table->size; i++) {
        Ht_item* item = table->items[i];
        if (item != NULL)
            free_item(item);
    }
 
    free_overflow_buckets(table);
    free(table->items);
    free(table);
}
 
void handle_collision(HashTable* table, unsigned long index, Ht_item* item) {
    LinkedList* head = table->overflow_buckets[index];
 
    if (head == NULL) {
        // We need to create the list
        head = allocate_list();
        head->item = item;
        table->overflow_buckets[index] = head;
        return;
    }
    else {
        // Insert to the list
        table->overflow_buckets[index] = linkedlist_insert(head, item);
        return;
    }
 }
 
void ht_insert(HashTable* table, char* identifier, int varPos, char *type) {
    // Create the item
    varInfo *varInfo = (struct varInfo*) malloc(sizeof(varInfo));
    varInfo->varPos = varPos;
    varInfo->type = strdup(type);
    Ht_item* item = create_item(identifier, varInfo);
 
    // Compute the index
    unsigned long index = hash_function(identifier);
 
    Ht_item* current_item = table->items[index];
     
    if (current_item == NULL) {
        // identifier does not exist.
        if (table->count == table->size) {
            // Hash Table Full
            printf("Insert Error: Hash Table is full\n");
            // Remove the create item
            free_item(item);
            return;
        }
         
        // Insert directly
        table->items[index] = item; 
        table->count++;
    }
 
    else {
            // Scenario 1: We only need to update varInfo
            if (strcmp(current_item->identifier, identifier) == 0) {
                table->items[index]->varInfo->type = strdup(varInfo->type);
                table->items[index]->varInfo->varPos = varInfo->varPos;
                return;
            }
     
        else {
            // Scenario 2: Collision
            handle_collision(table, index, item);
            return;
        }
    }
}
 
varInfo* ht_search(HashTable* table, char* identifier) {
    // Searches the identifier in the hashtable
    // and returns NULL if it doesn't exist
    int index = hash_function(identifier);
    Ht_item* item = table->items[index];
    LinkedList* head = table->overflow_buckets[index];
 
    // Ensure that we move to items which are not NULL
    while (item != NULL) {
        if (strcmp(item->identifier, identifier) == 0)
            return item->varInfo;
        if (head == NULL)
            return NULL;
        item = head->item;
        head = head->next;
    }
    return NULL;
}
 
void print_search(HashTable* table, char* identifier) {
    varInfo* val;
    if ((val = ht_search(table, identifier)) == NULL) {
        printf("%s does not exist\n", identifier);
        return;
    }
    else {
        printf("identifier:%s, varPos:%d, type:%s\n", identifier, val->varPos, val->type);
    }
}
 
void print_table(HashTable* table) {
    printf("\n//-------------------\n");
    for (int i=0; i<table->size; i++) {
        if (table->items[i]) {
            printf("//Index:%d, identifier:%s, varPos:%d, type:%s", i, table->items[i]->identifier, table->items[i]->varInfo->varPos, table->items[i]->varInfo->type);
            if (table->overflow_buckets[i]) {
                printf(" => Overflow Bucket => ");
                LinkedList* head = table->overflow_buckets[i];
                while (head) {
                    printf("identifier:%s, varPos:%d, type:%s", head->item->identifier, head->item->varInfo->varPos, head->item->varInfo->type);
                    head = head->next;
                }
            }
            printf("\n");
        }
    }
    printf("//-------------------\n");
}

void ht_delete(HashTable* table, char* identifier) {
    // Deletes an item from the table
    int index = hash_function(identifier);
    Ht_item* item = table->items[index];
    LinkedList* head = table->overflow_buckets[index];
 
    if (item == NULL) {
        // Does not exist. Return
        return;
    }
    else {
        if (head == NULL && strcmp(item->identifier, identifier) == 0) {
            // No collision chain. Remove the item
            // and set table index to NULL
            table->items[index] = NULL;
            free_item(item);
            table->count--;
            return;
        }
        else if (head != NULL) {
            // Collision Chain exists
            if (strcmp(item->identifier, identifier) == 0) {
                // Remove this item and set the head of the list
                // as the new item
                 
                free_item(item);
                LinkedList* node = head;
                head = head->next;
                node->next = NULL;
                table->items[index] = create_item(node->item->identifier, node->item->varInfo);
                free_linkedlist(node);
                table->overflow_buckets[index] = head;
                return;
            }
 
            LinkedList* curr = head;
            LinkedList* prev = NULL;
             
            while (curr) {
                if (strcmp(curr->item->identifier, identifier) == 0) {
                    if (prev == NULL) {
                        // First element of the chain. Remove the chain
                        free_linkedlist(head);
                        table->overflow_buckets[index] = NULL;
                        return;
                    }
                    else {
                        // This is somewhere in the chain
                        prev->next = curr->next;
                        curr->next = NULL;
                        free_linkedlist(curr);
                        table->overflow_buckets[index] = head;
                        return;
                    }
                }
                curr = curr->next;
                prev = curr;
            }
 
        }
    }
}

int hasDuplicates(HashTable *table, char *identifier) {
    int index = hash_function(identifier);
    Ht_item* item = table->items[index];
    LinkedList* head = table->overflow_buckets[index];

    while (item != NULL) {
        if (strcmp(item->identifier, identifier) == 0)
            return 1;
        if (head == NULL)
            return 0;
        item = head->item;
        head = head->next;
    }
    return 0;
}