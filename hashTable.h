typedef struct varInfo {
    int varPos;
    char *type;
} varInfo;

typedef struct Ht_item {
    char* identifier;
    varInfo* varInfo;
} Ht_item;
 
typedef struct LinkedList {
    Ht_item* item; 
    struct LinkedList* next;
} LinkedList;

typedef struct HashTable {
    Ht_item** items;
    LinkedList** overflow_buckets;
    int size;
    int count;
} HashTable;

unsigned long hash_function(char*);
static LinkedList* allocate_list ();
static LinkedList* linkedlist_insert(LinkedList*, Ht_item*);
static Ht_item* linkedlist_remove(LinkedList*);
static void free_linkedlist(LinkedList*);
static LinkedList** create_overflow_buckets(HashTable*);
static void free_overflow_buckets(HashTable*);
Ht_item* create_item(char*, varInfo*);
HashTable* create_table(int);
void free_item(Ht_item*);
void free_table(HashTable*);
void handle_collision(HashTable*, unsigned long, Ht_item*);
void ht_insert(HashTable*, char*, int, char *);
varInfo* ht_search(HashTable*, char*);
void print_search(HashTable*, char*);
void print_table(HashTable*);
void free_linkedlist(LinkedList*);
void ht_delete(HashTable*, char*);
int hasDuplicates(HashTable*, char*);
