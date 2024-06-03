#include <assert.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define FAIL(...) do { fprintf(stderr, "FAIL: "); fprintf(stderr, __VA_ARGS__); fprintf(stderr, "\n"); abort(); } while (0)
#define ARRAY_SIZE(arr) (sizeof(arr)/sizeof((arr)[0]))

static bool parse_i64(const char *str, int64_t *_out)
{
  int64_t n = atoll(str);
  if (n == 0 && 0 != strcmp(str, "0")) {
    return false;
  }
  *_out = n;
  return true;
}

/*******************************************************************
 * Params
 ******************************************************************/

#define DEBUG 0

/*******************************************************************
 * Object
 ******************************************************************/

#define TAG_ATOM 0
#define TAG_NUM  1
#define TAG_PAIR 2
#define TAG_CLOS 3
#define TAG_PRIM 4

#define IS_ATOM(obj) ((obj)->tag == TAG_ATOM)
#define IS_NUM(obj)  ((obj)->tag == TAG_NUM)
#define IS_PAIR(obj) ((obj)->tag == TAG_PAIR)
#define IS_CLOS(obj) ((obj)->tag == TAG_CLOS)
#define IS_PRIM(obj) ((obj)->tag == TAG_PRIM)

// Common object structure
typedef struct obj obj_t;
struct obj
{
  uint8_t tag;
  union {
    const char * atom;
    int64_t      num;
    struct {
      obj_t * car;
      obj_t * cdr;
    } pair;
    struct {
      obj_t *body;
      obj_t *env;
    } clos;
    struct {
      void (*func)(void);
    } prim;
  };
};

// Global State
typedef struct state state_t;
struct state
{
  char  * input_str;             // input data string used by read()
  size_t  input_len;             // input data length used by read()
  size_t  input_pos;             // input data position used by read()

  obj_t * interned_atoms;        // interned atoms list
  obj_t * atom_true;             // atom: t
  obj_t * atom_quote;            // atom: '
  obj_t * atom_push;             // atom: ^
  obj_t * atom_pop;              // atom: $

  obj_t * stack;                 // top-of-stack (implemented with pairs)
  obj_t * env;                   // top-level / initial environment
};
state_t state[1];

obj_t *alloc(void)
{
  return (obj_t*)malloc(sizeof(obj_t));
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

obj_t *make_prim(void (*func)(void))
{
  obj_t *obj = alloc();
  obj->tag = TAG_PRIM;
  obj->prim.func = func;
  return obj;
}

obj_t *intern(const char *atom_buf, size_t atom_len)
{
  // Search for an existing matching atom
  for (obj_t *list = state->interned_atoms; list; list = list->pair.cdr) {
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
  if (a == b) return true;
  if (!a || !b) return false;
  return (IS_NUM(a) && IS_NUM(b) && a->num == b->num);
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
  skip_white_and_comments();
  char c = peek();
  if (c == ')') {
    advance();
    return NULL;
  }
  return make_pair(read(), read_list());
}

obj_t *read(void)
{
  skip_white_and_comments();

  char c = peek();
  if (!c) FAIL("End of input: could not read()"); // FIXME: BETTER SOLUTION??

  // A directive char is it's own atom
  if (is_directive(c)) {
    advance();
    return intern(&c, 1);
  }

  // Read a list?
  if (c == '(') {
    advance();
    return read_list();
  }

  // Otherwise, assume atom and read it
  size_t start = state->input_pos;
  while (!is_punctuation(peek())) advance();

  char * str = &state->input_str[start];
  size_t n = state->input_pos - start;
  return intern(str, n);
}

/*******************************************************************
 * Print
 ******************************************************************/

void print_recurse(obj_t *obj);

void print_list_tail(obj_t *obj)
{
  if (obj == NULL) {
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
    printf("()");
    return;
  }
  switch (obj->tag) {
    case TAG_ATOM: printf("%s", obj->atom); break;
    case TAG_NUM:  printf("%lld", obj->num);  break;
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

  for (; env; env = cdr(env)) {
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

obj_t *env_define_prim(obj_t *env, const char *name, void (*func)(void))
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

void eval(obj_t *expr, obj_t *env);

void compute(obj_t *comp, obj_t *env)
{
  if (DEBUG) {
    printf("compute: ");
    print(comp);
  }

  if (!comp) return; // all-done

  // unpack
  obj_t *cmd  = car(comp);
  obj_t *rest = cdr(comp);

  if (cmd == state->atom_quote) {
    if (!rest) FAIL("Expected data followng a quote directive (')");
    push(car(rest));
    rest = cdr(rest);
  } else if (cmd == state->atom_push) {
    if (!rest || !IS_ATOM(car(rest))) FAIL("Expected an atom followng a push directive (^)");
    push(env_find(env, car(rest)));
    rest = cdr(rest);
  } else if (cmd == state->atom_pop) {
    if (!rest || !IS_ATOM(car(rest))) FAIL("Expected an atom followng a pop directive ($)");
    env = env_define(env, car(rest), pop());
    rest = cdr(rest);
  } else {
    // atoms and (...) get ordinary eval
    eval(cmd, env);
  }

  compute(rest, env); // tail-call loop
}

void apply(obj_t *expr)
{
  if (DEBUG) {
    printf("apply: ");
    print(expr);
  }

  if (expr) {
    if (IS_CLOS(expr)) { // closure
      return compute(expr->clos.body, expr->clos.env);
    } else if (IS_PRIM(expr)) { // primitive
      return expr->prim.func();
    }
  }

  // everything else applies and reproduces itself
  push(expr);
}

void eval(obj_t *expr, obj_t *env)
{
  if (DEBUG) {
    printf("eval: ");
    print(expr);
  }

  if (expr && IS_ATOM(expr)) {
    int64_t num;
    if (parse_i64(expr->atom, &num)) { // numbers
      push(make_num(num));
    } else { // normal names
      apply(env_find(env, expr));
    }
  } else {
    push(make_clos(expr, env));
  }
}

/*******************************************************************
 * Primitives
 ******************************************************************/

void prim_force(void) { apply(pop()); }
void prim_eq(void)    { push(obj_equal(pop(), pop()) ? state->atom_true : NULL); }
void prim_cons(void)  { obj_t *a, *b; a = pop(); b = pop(); push(make_pair(a, b)); }
void prim_car(void)   { push(car(pop())); }
void prim_cdr(void)   { push(cdr(pop())); }
void prim_cswap(void) { if (pop() == state->atom_true) { obj_t *a, *b; a = pop(); b = pop(); push(a); push(b); } }
void prim_print(void) { print(pop()); }
void prim_stack(void) { push(state->stack); }
void prim_sub(void)   { obj_t *a, *b; b = pop(); a = pop(); push(make_num(obj_i64(a) - obj_i64(b))); }
void prim_mul(void)   { obj_t *a, *b; b = pop(); a = pop(); push(make_num(obj_i64(a) * obj_i64(b))); }

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
  ssize_t n = fread(mem, 1, file_size, fp);
  if ((size_t)n != file_size) FAIL("Failed to read file");

  mem[file_size] = 0;
  return mem;
}

/*******************************************************************
 * Interpretor
 ******************************************************************/

void setup(const char *input_path)
{
  state->input_str = load_file(input_path);
  state->input_len = strlen(state->input_str);
  state->input_pos = 0;

  state->interned_atoms = NULL;
  state->atom_true      = intern("t", 1);
  state->atom_quote     = intern("'", 1);
  state->atom_push      = intern("^", 1);
  state->atom_pop       = intern("$", 1);

  state->stack = NULL;

  obj_t *env = NULL;
  env = env_define_prim(env, "force", &prim_force);
  env = env_define_prim(env, "cons",  &prim_cons);
  env = env_define_prim(env, "car",   &prim_car);
  env = env_define_prim(env, "cdr",   &prim_cdr);
  env = env_define_prim(env, "eq",    &prim_eq);
  env = env_define_prim(env, "cswap", &prim_cswap);
  env = env_define_prim(env, "print", &prim_print);
  env = env_define_prim(env, "stack", &prim_stack);
  env = env_define_prim(env, "-",     &prim_sub);
  env = env_define_prim(env, "*",     &prim_mul);
  state->env = env;
}

int main(int argc, char *argv[])
{
  if (argc != 2) {
    fprintf(stderr, "usage: %s <path>\n", argv[0]);
    return 1;
  }
  setup(argv[1]);

  obj_t *obj = read();
  eval(obj, state->env);
  prim_force();

  return 1;
}
