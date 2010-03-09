#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

typedef OP * (CPERLscope(*orig_ppaddr_t))(pTHX);
orig_ppaddr_t *PL_ppaddr_orig;
#define run_original_op(type) CALL_FPTR(PL_ppaddr_orig[type])(aTHX)

FILE* out;

FILE*
open_report_file()
{
    const char *name = "ppap.out";
    const char *mode = "wb";

    unlink(name);

    return fopen(name, mode);
}

static char*
cur_op_context()
{
    int context = OP_GIMME(PL_op, 0);
    if ( context == G_SCALAR ) {
        return "$";
    } else if ( context == G_ARRAY ) {
        return "@";
    } else if ( context == G_VOID ) {
        return "-";
    } else {
        return "?";
    }
}

void
describe_array(const AV* const av) {
    I32 prefix, size, sufix;

    if ( SvTIED_mg((const SV *)av, PERL_MAGIC_tied) ) {
        fprintf(out, "@T");
    }

    size = AvMAX(av);
    prefix = AvARRAY(av) - AvALLOC(av);
    sufix = AvFILLp(av) - size;

    fprintf(out, "@%"IVdf"-%"IVdf"-%"IVdf, (IV)prefix, (IV)size+1, (IV)sufix);
}

static OP *
pp_stmt_handle_push(pTHX)
{
    dSP; dMARK;

    fprintf(out, "%s push ", cur_op_context());
    describe_array( (AV *)(*(MARK+1)) );
    fprintf(out, ", ...%"IVdf"\n", SP-MARK-1);

    return run_original_op(PL_op->op_type);
}

static OP *
pp_stmt_handle_shift(pTHX)
{
    dSP; dMARK;

    if ( PL_op->op_type == OP_SHIFT ) {
        fprintf(out, "%s shift ", cur_op_context());
    } else {
        fprintf(out, "%s pop ", cur_op_context());
    }
    if ( SP-MARK > 1 ) { /* XXX: handle shift @_ */
        describe_array( (AV *)(*(MARK+1)) );
    }
    fprintf(out, "\n");

    return run_original_op(PL_op->op_type);
}

static OP *
pp_stmt_handle_unshift(pTHX)
{
    dSP; dMARK;

    fprintf(out, "%s unshift ", cur_op_context());
    describe_array( (AV *)(*(MARK+1)) );
    fprintf(out, ", ...%"IVdf"\n", SP-MARK-1);

    return run_original_op(PL_op->op_type);
}

static OP *
pp_stmt_handle_splice(pTHX)
{
    dSP; dMARK;
    I32 nargs = SP-MARK-1;

    fprintf(out, "%s splice ", cur_op_context());
    describe_array( (AV *)(*(MARK+1)) );

    if ( nargs-- > 0 ) {
        fprintf(out, ", %"IVdf, SvIV(*(SP-nargs)));
    }
    if ( nargs-- > 0 ) {
        fprintf(out, ", %"IVdf, SvIV(*(SP-nargs)));
    }
    if ( nargs > 0 ) {
        fprintf(out, ", ...%"IVdf, nargs);
    }
    fprintf(out, "\n");

    return run_original_op(PL_op->op_type);
}

static OP *
pp_stmt_handle_aelem(pTHX)
{
    dSP; dMARK;

    fprintf(out, "%s", cur_op_context());
    if ( PL_op->op_flags & OPf_MOD ) {
        fprintf(out, "=");
    }
    fprintf(out, " aelem ");

    describe_array( (AV *)(*(MARK+1)) );
    fprintf(out, ", %"IVdf"\n", SvIV((SV *)(*(MARK+1))));

    return run_original_op(PL_op->op_type);
}

static OP *
pp_stmt_handle_aelemfast(pTHX)
{
    dSP; dMARK;

    fprintf(out, "%s", cur_op_context());
    if ( PL_op->op_flags & OPf_MOD ) {
        fprintf(out, "=");
    }
    fprintf(out, " aelemfast ");

    if ( PL_op->op_flags & OPf_SPECIAL ) {
        describe_array( PAD_SV(PL_op->op_targ) );
    } else {
        // XXX: how safe to do this?
        describe_array( GvAV(cGVOP_gv) );
    }

    fprintf(out, ", %"IVdf"\n", (IV) PL_op->op_private);

    return run_original_op(PL_op->op_type);
}

static int
init_handler(pTHX)
{
    Newxc(PL_ppaddr_orig, OP_max, void *, orig_ppaddr_t);
    Copy(PL_ppaddr, PL_ppaddr_orig, OP_max, void *);

    PL_ppaddr[OP_AELEM]      = pp_stmt_handle_aelem;
    PL_ppaddr[OP_AELEMFAST]  = pp_stmt_handle_aelemfast;

    PL_ppaddr[OP_POP]        = pp_stmt_handle_shift;
    PL_ppaddr[OP_PUSH]       = pp_stmt_handle_push;
    PL_ppaddr[OP_SHIFT]      = pp_stmt_handle_shift;
    PL_ppaddr[OP_UNSHIFT]    = pp_stmt_handle_unshift;

    PL_ppaddr[OP_SPLICE]     = pp_stmt_handle_splice;

    out = open_report_file();
}

MODULE = Devel::PPAP   PACKAGE = Devel::PPAP

PROTOTYPES: DISABLE

int
init_handler()
    C_ARGS:
    aTHX


