/********************************************************************************
 * MIT License
*
* Copyright (c) 2024 Anthony Bonkoski
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*******************************************************************************/

#include <assert.h>
#include <inttypes.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define FAIL(...) do { fprintf(stderr, "FAIL: "); fprintf(stderr, __VA_ARGS__); fprintf(stderr, "\n"); abort(); } while (0)

/*******************************************************************
 * Params
 ******************************************************************/

#define DEBUG 0
#define USE_LOWLEVEL 1
#define MAX_OBJECTS 65536

/*******************************************************************
 * Object
 ******************************************************************/

#define TAG_NIL  0
#define TAG_ATOM 1
#define TAG_NUM  2
#define TAG_PAIR 3
#define TAG_CLOS 4
#define TAG_PRIM 5
#define TAG_STR  6

#define IS_NIL(obj)  ((obj)->tag == TAG_NIL)
#define IS_ATOM(obj) ((obj)->tag == TAG_ATOM)
#define IS_NUM(obj)  ((obj)->tag == TAG_NUM)
#define IS_PAIR(obj) ((obj)->tag == TAG_PAIR)
#define IS_CLOS(obj) ((obj)->tag == TAG_CLOS)
#define IS_PRIM(obj) ((obj)->tag == TAG_PRIM)
#define IS_STR(obj)  ((obj)->tag == TAG_STR)

#define FLAG_GC         0x01
#define FLAG_FREEABLE   0x02

// Common object structure
typedef struct obj obj_t;
struct obj
{
  uint64_t tag;
  uint8_t flags;
  union {
    const char * atom;
    int64_t      num;
    struct {
      obj_t * car;
      obj_t * cdr;
    } pair;
    struct {
      obj_t * body;
      obj_t * env;
    } clos;
    struct {
      void (*func)(obj_t **env);
    } prim;
    struct {
      char * data;
      size_t length;
    } string;
  };
};

#define FLAG_PUSH 128
#define FLAG_POP  129

// Global State
typedef struct state state_t;
struct state
{
  char  * input_str;             // input data string used by read()
  size_t  input_len;             // input data length used by read()
  size_t  input_pos;             // input data position used by read()

  obj_t * nil;                   // nil: ()
  obj_t * read_stack;            // defered obj to emit from read

  obj_t * interned_atoms;        // interned atoms list
  obj_t * atom_true;             // atom: t
  obj_t * atom_quote;            // atom: quote
  obj_t * atom_push;             // atom: push
  obj_t * atom_pop;              // atom: pop

  obj_t * stack;                 // top-of-stack (implemented with pairs)
  obj_t * env;                   // top-level / initial environment
  obj_t * expr;                  // top-level / initial expression
  obj_t **allocated;             // buffer of allocated objects
  int     allocated_last;        // pointer to last entry
};
state_t state[1];

void gc();
obj_t *alloc(void)
{
  obj_t *obj = (obj_t*)malloc(sizeof(obj_t));
  memset(obj, 0, sizeof(obj_t));

  if (state->allocated) {
    int start = state->allocated_last;
    int has_gced = 0;
    while (state->allocated[state->allocated_last]) {
      state->allocated_last = (state->allocated_last + 1) % MAX_OBJECTS;

      if (state->allocated_last == start) {
        if (has_gced) {
          FAIL("unable to allocated new object");
        }

        gc();
        has_gced++;
      }
    }

    state->allocated[state->allocated_last] = obj;
  }

  return obj;
}

void print(obj_t *obj);
static void gc_free(obj_t *obj) {
  switch(obj->tag) {
    case TAG_ATOM:
      free((void *) obj->atom);
      break;
    case TAG_STR:
      if (obj->flags & ~FLAG_FREEABLE) {
        free(obj->string.data);
      }
      break;
  }

  free(obj);
}

void gc_walk(obj_t *obj, int val) {
  if (obj == NULL) return;
  if ((obj->flags & FLAG_GC) == val) return;

  switch(obj->tag) {
    case TAG_PAIR:
      gc_walk(obj->pair.car, val);
      gc_walk(obj->pair.cdr, val);
      break;
    case TAG_CLOS:
      gc_walk(obj->clos.body, val);
      gc_walk(obj->clos.env, val);
      break;
  }

  if (val) {
    obj->flags |= FLAG_GC;
  } else {
    obj->flags &= ~FLAG_GC;
  }
}

static void gc_do_walks(int val) {
  gc_walk(state->nil, val);
  gc_walk(state->read_stack, val);
  gc_walk(state->interned_atoms, val);
  gc_walk(state->atom_true, val);
  gc_walk(state->atom_quote, val);
  gc_walk(state->atom_push, val);
  gc_walk(state->atom_pop, val);
  gc_walk(state->stack, val);
  gc_walk(state->env, val);
  gc_walk(state->expr, val);
}

void gc() {
  if (!state->allocated) return;

  gc_do_walks(1);

  for (int i = 0; i < MAX_OBJECTS; i++) {
    if (state->allocated[i]) {
      if (!(state->allocated[i]->flags & FLAG_GC)) {
        gc_free(state->allocated[i]);
        state->allocated[i] = NULL;
      }
    }
  }

  gc_do_walks(0);
}

obj_t *make_nil(void)
{
  obj_t *obj = alloc();
  obj->tag = TAG_NIL;
  return obj;
}

obj_t *make_atom(const char *str, size_t len)
{
  char *atom_str = malloc(len+1);
  memcpy(atom_str, str, len);
  atom_str[len] = '\0';

  obj_t *atom = alloc();
  atom->tag   = TAG_ATOM;
  atom->atom  = atom_str;

  return atom;
}

obj_t *make_num(int64_t num)
{
  obj_t *obj = alloc();
  obj->tag = TAG_NUM;
  obj->num = num;
  return obj;
}

obj_t *make_pair(obj_t *car, obj_t *cdr)
{
  obj_t *obj = alloc();
  obj->tag = TAG_PAIR;
  obj->pair.car = car;
  obj->pair.cdr = cdr;
  return obj;
}

obj_t *make_clos(obj_t *body, obj_t *env)
{
  obj_t *obj = alloc();
  obj->tag = TAG_CLOS;
  obj->clos.body = body;
  obj->clos.env = env;
  return obj;
}

obj_t *make_prim(void (*func)(obj_t**))
{
  obj_t *obj = alloc();
  obj->tag = TAG_PRIM;
  obj->prim.func = func;
  return obj;
}

obj_t *make_str(char *data, size_t length, int freeable)
{
  obj_t *obj = alloc();
  obj->tag = TAG_STR;
  obj->string.data = data;
  obj->string.length = length;
  obj->flags |= FLAG_FREEABLE;
  return obj;
}

obj_t *intern(const char *atom_buf, size_t atom_len)
{
  // Search for an existing matching atom
  for (obj_t *list = state->interned_atoms; list != state->nil; list = list->pair.cdr) {
    assert(IS_PAIR(list));
    obj_t * elem = list->pair.car;
    assert(IS_ATOM(elem));
    if (atom_len == strlen(elem->atom) &&
        0 == memcmp(atom_buf, elem->atom, atom_len)) {
      return elem;
    }
  }

  // Not found: create a new one and push the front of the list

  obj_t *atom = make_atom(atom_buf, atom_len);
  state->interned_atoms = make_pair(atom, state->interned_atoms);
  return atom;
}

obj_t *car(obj_t *obj)
{
  if (!IS_PAIR(obj)) FAIL("Expected pair to apply car() function");
  return obj->pair.car;
}

obj_t *cdr(obj_t *obj)
{
  if (!IS_PAIR(obj)) FAIL("Expected pair to apply cdr() function");
  return obj->pair.cdr;
}

bool obj_equal(obj_t *a, obj_t *b)
{
  return (a == b) || (IS_NUM(a) && IS_NUM(b) && a->num == b->num);
}

int64_t obj_i64(obj_t *a)
{
  return IS_NUM(a) ? a->num : 0;
}

/*******************************************************************
 * Read
 ******************************************************************/

char peek(void)
{
  if (state->input_pos == state->input_len) return 0;
  return state->input_str[state->input_pos];
}

void advance(void)
{
  assert(peek()); // invalid to advance beyond the end
  state->input_pos++;
}

bool is_white(char c)
{
  return c == ' ' || c == '\t' || c == '\n';
}

bool is_directive(char c)
{
  return c == '\'' || c == '^' || c == '$';
}

bool is_punctuation(char c) {
  return c == 0 || is_white(c) || is_directive(c) || c == '(' || c == ')' || c == ';';
}

void skip_white_and_comments(void)
{
  char c = peek();
  if (c == 0) return; // end-of-data

  // skip white
  if (is_white(c)) {
    advance();
    return skip_white_and_comments(); // tail-call loop
  }

  // skip comment
  if (c == ';') {
    advance();
    while (1) {
      char c = peek();
      if (c == 0) return; // end-of-data
      advance();
      if (c == '\n') break;
    }
    return skip_white_and_comments(); // tail-call loop
  }
}

obj_t *read(void);

obj_t *read_list(void)
{
  if (!state->read_stack) {
    skip_white_and_comments();
    char c = peek();
    if (c == ')') {
      advance();
      return state->nil;
    }
  }
  obj_t *first = read();
  obj_t *second = read_list();
  return make_pair(first, second);
}

static bool parse_i64(const char *str, size_t len, int64_t *_out)
{
  // Copy to ensure null-termination
  static char buf[20];
  memcpy(buf, str, len);
  buf[len] = '\0';

  int64_t n = atoll(buf);
  if (n == 0 && 0 != strcmp(buf, "0")) {
    return false;
  }
  *_out = n;
  return true;
}

obj_t *read_scalar(void)
{
  if (peek() == '"') {
    advance();
    char *string = malloc(1);
    int length = 1;
    while (true) {
      char c = peek();
      advance();

      if (c == '"') {
        return make_str(string, length - 1, 1);
      }

      if (c == '\\') {
        if (peek() == 'n') {
          advance();
          c = 0x0a;
        } else if (peek() == 'x') {
          advance();

          char bytes[3];
          bytes[0] = peek();
          advance();
          bytes[1] = peek();
          advance();
          bytes[2] = 0;

          c = (char) strtol((char *) &bytes, NULL, 16);
        }
      }
      string = realloc(string, length + 1);
      string[length - 1] = c;
      string[length] = 0;
      length++;
    }
  }

  // Otherwise, assume atom or num and read it
  size_t start = state->input_pos;
  while (!is_punctuation(peek())) advance();

  char * str = &state->input_str[start];
  size_t n = state->input_pos - start;

  // Is it a number?
  int64_t num;
  if (parse_i64(str, n, &num)) { // num
    return make_num(num);
  } else { // atom
    return intern(str, n);
  }
}

obj_t *read(void)
{
  obj_t *read_stack = state->read_stack;
  if (read_stack) {
    state->read_stack = cdr(read_stack);
    return car(read_stack);
  }

  skip_white_and_comments();

  char c = peek();
  if (!c) FAIL("End of input: could not read()"); // FIXME: BETTER SOLUTION??

  // A quote?
  if (c == '\'') {
    advance();
    return state->atom_quote;
  }

  // A push?
  if (c == '^') {
    advance();
    obj_t *s = NULL;
    s = make_pair(state->atom_push, s);
    s = make_pair(read_scalar(), s);
    s = make_pair(state->atom_quote, s);
    state->read_stack = s;
    return read(); // tail-call to dump the read stack
  }

  // A pop?
  if (c == '$') {
    advance();
    obj_t *s = NULL;
    s = make_pair(state->atom_pop, s);
    s = make_pair(read_scalar(), s);
    s = make_pair(state->atom_quote, s);
    state->read_stack = s;
    return read(); // tail-call to dump the read stack
  }

  // Read a list?
  if (c == '(') {
    advance();
    return read_list();
  } else {
    return read_scalar();
  }
}

/*******************************************************************
 * Print
 ******************************************************************/

void print_recurse(obj_t *obj);

void print_list_tail(obj_t *obj)
{
  if (obj == NULL) {
    printf(" NULL");
    return;
  }

  if (obj == state->nil) {
    printf(")");
    return;
  }
  if (IS_PAIR(obj)) {
    printf(" ");
    print_recurse(obj->pair.car);
    print_list_tail(obj->pair.cdr);
  } else {
    printf(" . ");
    print_recurse(obj);
    printf(")");
  }
}

void print_recurse(obj_t *obj)
{
  if (obj == NULL) {
    printf("NULL");
    return;
  }

  if (obj == state->nil) {
    printf("()");
    return;
  }
  switch (obj->tag) {
    case TAG_ATOM: printf("%s", obj->atom); break;
    case TAG_NUM:  printf("%" PRId64, obj->num);  break;
    case TAG_PAIR: {
      printf("(");
      print_recurse(obj->pair.car);
      print_list_tail(obj->pair.cdr);
    } break;
    case TAG_CLOS: {
      printf("CLOSURE<");
      print_recurse(obj->clos.body);
      printf(", %p>", obj->clos.env);
    } break;
    case TAG_PRIM: {
      printf("PRIM<%p>", obj->prim.func);
    } break;
    case TAG_STR: {
      for (int i = 0; i < obj->string.length; i++) {
        printf("%c", obj->string.data[i]);
      }
    }
  }
}

void print(obj_t *obj)
{
  print_recurse(obj);
  printf("\n");
}

/*******************************************************************
 * Environment
 ******************************************************************/

/* Environment is jsut a simple list of key-val (dotted) pairs */

obj_t *env_find(obj_t *env, obj_t *key)
{
  if (!IS_ATOM(key)) FAIL("Expected 'key' to be an atom in env_find()");

  for (; env != state->nil; env = cdr(env)) {
    obj_t *kv = car(env);
    if (key == car(kv)) {
      return cdr(kv);
    }
  }

  FAIL("Failed to find in key='%s' in environment", key->atom);
}

obj_t *env_define(obj_t *env, obj_t *key, obj_t *val)
{
  return make_pair(make_pair(key, val), env);
}

obj_t *env_define_prim(obj_t *env, const char *name, void (*func)(obj_t **env))
{
  return env_define(env, intern(name, strlen(name)), make_prim(func));
}

/*******************************************************************
 * Value Stack Operations
 ******************************************************************/

void push(obj_t *obj)
{
  state->stack = make_pair(obj, state->stack);
}

bool try_pop(obj_t **_out)
{
  if (!state->stack) {
    return false;
  }

  *_out = car(state->stack);
  state->stack = cdr(state->stack);
  return true;
}

obj_t *pop()
{
  obj_t *ret = NULL;
  if (!try_pop(&ret)) FAIL("Value Stack Underflow");
  return ret;
}

/*******************************************************************
 * Eval
 ******************************************************************/

void eval(obj_t *expr, obj_t **env);

void compute(obj_t *comp, obj_t *env)
{
  if (DEBUG) {
    printf("compute: ");
    print(comp);
  }

  while (comp != state->nil) {
    // unpack
    obj_t *cmd  = car(comp);
    comp = cdr(comp);

    if (cmd == state->atom_quote) {
      if (comp == state->nil) FAIL("Expected data following a quote form");
      push(car(comp));
      comp = cdr(comp);
      continue;
    }

    // atoms and (...) get ordinary eval
    eval(cmd, &env);
  }
}

void eval(obj_t *expr, obj_t **env)
{
  if (DEBUG) {
    printf("eval: ");
    print(expr);
  }

  if (IS_ATOM(expr)) {
    obj_t *val = env_find(*env, expr);
    if (IS_CLOS(val)) { // closure
      return compute(val->clos.body, val->clos.env);
    } else if (IS_PRIM(val)) { // primitive
      return val->prim.func(env);
    } else {
      return push(val);
    }
  } else if (IS_NIL(expr) || IS_PAIR(expr)) {
    return push(make_clos(expr, *env));
  } else {
    return push(expr);
  }
}

/*******************************************************************
 * Primitives
 ******************************************************************/

/* Core primitives */
void prim_push(obj_t **env) { push(env_find(*env, pop())); }
void prim_pop(obj_t **env)  { obj_t *k, *v; k = pop(); v = pop(); *env = env_define(*env, k, v); }
void prim_eq(obj_t **_)     { push(obj_equal(pop(), pop()) ? state->atom_true : state->nil); }
void prim_cons(obj_t **_)   { obj_t *a, *b; a = pop(); b = pop(); push(make_pair(a, b)); }
void prim_car(obj_t **_)    { push(car(pop())); }
void prim_cdr(obj_t **_)    { push(cdr(pop())); }
void prim_cswap(obj_t **_)  { if (pop() == state->atom_true) { obj_t *a, *b; a = pop(); b = pop(); push(a); push(b); } }
void prim_tag(obj_t **_)    { push(make_num(pop()->tag)); }
void prim_read(obj_t **_)   { push(read()); }
void prim_print(obj_t **_)  { print(pop()); }
void prim_mstr(obj_t **_)   { int64_t l = obj_i64(pop()); push(make_str(calloc(1, l), l, 1)); }
void prim_speek(obj_t **_)  { int64_t o = obj_i64(pop()); obj_t *s = pop(); if (IS_STR(s)) { push(make_num(o >= s->string.length ? 0 : s->string.data[o])); } }
void prim_spoke(obj_t **_)  { int64_t v, o; v = obj_i64(pop()); o = obj_i64(pop()); obj_t *s = pop(); if (IS_STR(s) && o < s->string.length) { s->string.data[o] = v; } }
void prim_memview(obj_t **_){ int64_t s, a; s = obj_i64(pop()); a = obj_i64(pop()); push(make_str((char *) a, s, 0)); }
void prim_gc(obj_t **_)     { gc(); }

/* Extra primitives */
void prim_stack(obj_t **_) { push(state->stack); }
void prim_env(obj_t **env) { push(*env); }
void prim_sub(obj_t **_)   { obj_t *a, *b; b = pop(); a = pop(); push(make_num(obj_i64(a) - obj_i64(b))); }
void prim_mul(obj_t **_)   { obj_t *a, *b; b = pop(); a = pop(); push(make_num(obj_i64(a) * obj_i64(b))); }
void prim_nand(obj_t **_)  { obj_t *a, *b; b = pop(); a = pop(); push(make_num(~(obj_i64(a) & obj_i64(b)))); }
void prim_lsh(obj_t **_)   { obj_t *a, *b; b = pop(); a = pop(); push(make_num(obj_i64(a) << obj_i64(b))); }
void prim_rsh(obj_t **_)   { obj_t *a, *b; b = pop(); a = pop(); push(make_num(obj_i64(a) >> obj_i64(b))); }

#if USE_LOWLEVEL
/* Low-level primitives */
void prim_ptr_state(obj_t **_)    { push(make_num((int64_t)state)); }
void prim_ptr_read(obj_t **_)     { push(make_num(*(int64_t*)obj_i64(pop()))); }
void prim_ptr_write(obj_t **_)    { obj_t *a, *b; b = pop(); a = pop(); *(int64_t*)obj_i64(a) = obj_i64(b); }
void prim_ptr_to_obj(obj_t **_)   { push((obj_t*)obj_i64(pop())); }
void prim_ptr_from_obj(obj_t **_) { push(make_num((int64_t)pop())); }
#endif

/*******************************************************************
 * Misc
 ******************************************************************/

static char *load_file(const char *filename)
{
  FILE *fp = fopen(filename, "r");
  if (!fp) FAIL("Failed to open file: '%s'\n", filename);

  fseek(fp, 0, SEEK_END);
  size_t file_size = ftell(fp);
  fseek(fp, 0, SEEK_SET);

  char *mem = malloc(file_size+1);
  size_t n = fread(mem, 1, file_size, fp);
  if (n != file_size) FAIL("Failed to read file");

  mem[file_size] = 0;
  return mem;
}

/*******************************************************************
 * Interpreter
 ******************************************************************/

void setup(const char *input_path)
{
  state->input_str = load_file(input_path);
  state->input_len = strlen(state->input_str);
  state->input_pos = 0;

  state->read_stack = NULL;
  state->nil        = make_nil();

  state->interned_atoms = state->nil;
  state->atom_true      = intern("t", 1);
  state->atom_quote     = intern("quote", 5);
  state->atom_push      = intern("push", 4);
  state->atom_pop       = intern("pop", 3);

  state->stack = state->nil;

  obj_t *env = state->nil;

  // Core primitives
  env = env_define_prim(env, "push",  &prim_push);
  env = env_define_prim(env, "pop",   &prim_pop);
  env = env_define_prim(env, "cons",  &prim_cons);
  env = env_define_prim(env, "car",   &prim_car);
  env = env_define_prim(env, "cdr",   &prim_cdr);
  env = env_define_prim(env, "eq",    &prim_eq);
  env = env_define_prim(env, "cswap", &prim_cswap);
  env = env_define_prim(env, "tag",   &prim_tag);
  env = env_define_prim(env, "read",  &prim_read);
  env = env_define_prim(env, "print", &prim_print);
  env = env_define_prim(env, "make-string", &prim_mstr);
  env = env_define_prim(env, "string-peek", &prim_speek);
  env = env_define_prim(env, "string-poke", &prim_spoke);
  env = env_define_prim(env, "string-memview", &prim_memview);
  env = env_define_prim(env, "gc", &prim_gc);

  // Extra primitives
  env = env_define_prim(env, "stack", &prim_stack);
  env = env_define_prim(env, "env",   &prim_env);
  env = env_define_prim(env, "-",     &prim_sub);
  env = env_define_prim(env, "*",     &prim_mul);
  env = env_define_prim(env, "nand",  &prim_nand);
  env = env_define_prim(env, "<<",    &prim_lsh);
  env = env_define_prim(env, ">>",    &prim_rsh);

  #if USE_LOWLEVEL
  // Low-level primitives
  env = env_define_prim(env, "ptr-state!",    &prim_ptr_state);
  env = env_define_prim(env, "ptr-read!",     &prim_ptr_read);
  env = env_define_prim(env, "ptr-write!",    &prim_ptr_write);
  env = env_define_prim(env, "ptr-to-obj!",   &prim_ptr_to_obj);
  env = env_define_prim(env, "ptr-from-obj!", &prim_ptr_from_obj);
  #endif

  state->env = env;
  state->allocated = NULL;
}

void setup_gc() {
  state->allocated = malloc(sizeof(obj_t *) * MAX_OBJECTS);
  memset(state->allocated, 0, sizeof(obj_t *) * MAX_OBJECTS);
}

int main(int argc, char *argv[])
{
  if (argc != 2) {
    fprintf(stderr, "usage: %s <path>\n", argv[0]);
    return 1;
  }
  setup(argv[1]);

  state->expr = read();
  setup_gc();

  compute(state->expr, state->env);

  return 0;
}
