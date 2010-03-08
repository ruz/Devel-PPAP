#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

typedef OP * (CPERLscope(*orig_ppaddr_t))(pTHX);
orig_ppaddr_t *PL_ppaddr_orig;
#define run_original_op(type) CALL_FPTR(PL_ppaddr_orig[type])(aTHX)

static OP *
pp_stmt_handle_shift(pTHX)
{
    OP *op = run_original_op(PL_op->op_type);
    /* here we can do something */
    return op;
}

static int
init_handler(pTHX)
{
    Newxc(PL_ppaddr_orig, OP_max, void *, orig_ppaddr_t);
    Copy(PL_ppaddr, PL_ppaddr_orig, OP_max, void *);
    PL_ppaddr[OP_SHIFT] = pp_stmt_handle_shift;
}

MODULE = Devel::PPAP   PACKAGE = Devel::PPAP

PROTOTYPES: DISABLE

int
init_handler()
    C_ARGS:
    aTHX


