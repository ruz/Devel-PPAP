#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "clock.h"

typedef OP * (CPERLscope(*orig_ppaddr_t))(pTHX);
orig_ppaddr_t *PL_ppaddr_orig;
orig_ppaddr_t *PL_ppaddr_mine;
#define run_original_op(type) STMT_START { \
    OP* rv; long elapsed, overflow; \
    get_time_of_day(start_time); \
    rv = CALL_FPTR(PL_ppaddr_orig[type])(aTHX); \
    get_time_of_day(end_time); \
    get_ticks_between(start_time, end_time, elapsed, overflow); \
    fprintf(out, " |%"IVdf"\n", elapsed); \
    return rv; \
} STMT_END

/* sMARK like dMARK, but doesn't change anything */
#define sMARK register SV **mark = PL_stack_base + TOPMARK


static const int const handle_ops[OP_max] = {
        OP_NULL         ,
        OP_STUB         ,
        OP_SCALAR       ,
        OP_PUSHMARK     ,
        OP_WANTARRAY    ,
        OP_CONST        ,
        OP_GVSV         ,
        OP_GV           ,
        OP_GELEM        ,
        OP_PADSV        ,
        OP_PADAV        ,
        OP_PADHV        ,
        OP_PADANY       ,
        OP_PUSHRE       ,
        OP_RV2GV        ,
        OP_RV2SV        ,
        OP_AV2ARYLEN    ,
        OP_RV2CV        ,
        OP_ANONCODE     ,
        OP_PROTOTYPE    ,
        OP_REFGEN       ,
        OP_SREFGEN      ,
        OP_REF          ,
        OP_BLESS        ,
        OP_BACKTICK     ,
        OP_GLOB         ,
        OP_READLINE     ,
        OP_RCATLINE     ,
        OP_REGCMAYBE    ,
        OP_REGCRESET    ,
        OP_REGCOMP      ,
        OP_MATCH        ,
        OP_QR           ,
        OP_SUBST        ,
        OP_SUBSTCONT    ,
        OP_TRANS        ,
        OP_TRANSR       ,
        OP_SASSIGN      ,
        OP_AASSIGN      ,
        OP_CHOP         ,
        OP_SCHOP        ,
        OP_CHOMP        ,
        OP_SCHOMP       ,
        OP_DEFINED      ,
        OP_UNDEF        ,
        OP_STUDY        ,
        OP_POS          ,
        OP_PREINC       ,
        OP_I_PREINC     ,
        OP_PREDEC       ,
        OP_I_PREDEC     ,
        OP_POSTINC      ,
        OP_I_POSTINC    ,
        OP_POSTDEC      ,
        OP_I_POSTDEC    ,
        OP_POW          ,
        OP_MULTIPLY     ,
        OP_I_MULTIPLY   ,
        OP_DIVIDE       ,
        OP_I_DIVIDE     ,
        OP_MODULO       ,
        OP_I_MODULO     ,
        OP_REPEAT       ,
        OP_ADD          ,
        OP_I_ADD        ,
        OP_SUBTRACT     ,
        OP_I_SUBTRACT   ,
        OP_CONCAT       ,
        OP_STRINGIFY    ,
        OP_LEFT_SHIFT   ,
        OP_RIGHT_SHIFT  ,
        OP_LT           ,
        OP_I_LT         ,
        OP_GT           ,
        OP_I_GT         ,
        OP_LE           ,
        OP_I_LE         ,
        OP_GE           ,
        OP_I_GE         ,
        OP_EQ           ,
        OP_I_EQ         ,
        OP_NE           ,
        OP_I_NE         ,
        OP_NCMP         ,
        OP_I_NCMP       ,
        OP_SLT          ,
        OP_SGT          ,
        OP_SLE          ,
        OP_SGE          ,
        OP_SEQ          ,
        OP_SNE          ,
        OP_SCMP         ,
        OP_BIT_AND      ,
        OP_BIT_XOR      ,
        OP_BIT_OR       ,
        OP_NEGATE       ,
        OP_I_NEGATE     ,
        OP_NOT          ,
        OP_COMPLEMENT   ,
        OP_SMARTMATCH   ,
        OP_ATAN2        ,
        OP_SIN          ,
        OP_COS          ,
        OP_RAND         ,
        OP_SRAND        ,
        OP_EXP          ,
        OP_LOG          ,
        OP_SQRT         ,
        OP_INT          ,
        OP_HEX          ,
        OP_OCT          ,
        OP_ABS          ,
        OP_LENGTH       ,
        OP_SUBSTR       ,
        OP_VEC          ,
        OP_INDEX        ,
        OP_RINDEX       ,
        OP_SPRINTF      ,
        OP_FORMLINE     ,
        OP_ORD          ,
        OP_CHR          ,
        OP_CRYPT        ,
        OP_UCFIRST      ,
        OP_LCFIRST      ,
        OP_UC           ,
        OP_LC           ,
        OP_QUOTEMETA    ,
        OP_RV2AV        ,
        OP_AELEMFAST    ,
        OP_AELEMFAST_LEX,
        OP_AELEM        ,
        OP_ASLICE       ,
        OP_AEACH        ,
        OP_AKEYS        ,
        OP_AVALUES      ,
        OP_EACH         ,
        OP_VALUES       ,
        OP_KEYS         ,
        OP_DELETE       ,
        OP_EXISTS       ,
        OP_RV2HV        ,
        OP_HELEM        ,
        OP_HSLICE       ,
        OP_BOOLKEYS     ,
        OP_UNPACK       ,
        OP_PACK         ,
        OP_SPLIT        ,
        OP_JOIN         ,
        OP_LIST         ,
        OP_LSLICE       ,
        OP_ANONLIST     ,
        OP_ANONHASH     ,
        OP_SPLICE       ,
        OP_PUSH         ,
        OP_POP          ,
        OP_SHIFT        ,
        OP_UNSHIFT      ,
        OP_SORT         ,
        OP_REVERSE      ,
//        OP_GREPSTART    ,
//        OP_GREPWHILE    ,
//        OP_MAPSTART     ,
//        OP_MAPWHILE     ,
        OP_RANGE        ,
        OP_FLIP         ,
        OP_FLOP         ,
        OP_AND          ,
        OP_OR           ,
        OP_XOR          ,
        OP_DOR          ,
        OP_COND_EXPR    ,
        OP_ANDASSIGN    ,
        OP_ORASSIGN     ,
        OP_DORASSIGN    ,
        OP_METHOD       ,
//        OP_ENTERSUB     ,
//        OP_LEAVESUB     ,
//        OP_LEAVESUBLV   ,
        OP_CALLER       ,
        OP_WARN         ,
        OP_DIE          ,
        OP_RESET        ,
//        OP_LINESEQ      ,
//        OP_NEXTSTATE    ,
//        OP_DBSTATE      ,
//        OP_UNSTACK      ,
//        OP_ENTER        ,
//        OP_LEAVE        ,
//        OP_SCOPE        ,
//        OP_ENTERITER    ,
//        OP_ITER         ,
//        OP_ENTERLOOP    ,
//        OP_LEAVELOOP    ,
//        OP_RETURN       ,
//        OP_LAST         ,
//        OP_NEXT         ,
//        OP_REDO         ,
//        OP_DUMP         ,
//        OP_GOTO         ,
//        OP_EXIT         ,
        OP_METHOD_NAMED ,
//        OP_ENTERGIVEN   ,
//        OP_LEAVEGIVEN   ,
//        OP_ENTERWHEN    ,
//        OP_LEAVEWHEN    ,
//        OP_BREAK        ,
//        OP_CONTINUE     ,
        OP_OPEN         ,
        OP_CLOSE        ,
        OP_PIPE_OP      ,
        OP_FILENO       ,
        OP_UMASK        ,
        OP_BINMODE      ,
        OP_TIE          ,
        OP_UNTIE        ,
        OP_TIED         ,
        OP_DBMOPEN      ,
        OP_DBMCLOSE     ,
        OP_SSELECT      ,
        OP_SELECT       ,
        OP_GETC         ,
        OP_READ         ,
        OP_ENTERWRITE   ,
        OP_LEAVEWRITE   ,
        OP_PRTF         ,
        OP_PRINT        ,
        OP_SAY          ,
        OP_SYSOPEN      ,
        OP_SYSSEEK      ,
        OP_SYSREAD      ,
        OP_SYSWRITE     ,
        OP_EOF          ,
        OP_TELL         ,
        OP_SEEK         ,
        OP_TRUNCATE     ,
        OP_FCNTL        ,
        OP_IOCTL        ,
        OP_FLOCK        ,
        OP_SEND         ,
        OP_RECV         ,
        OP_SOCKET       ,
        OP_SOCKPAIR     ,
        OP_BIND         ,
        OP_CONNECT      ,
        OP_LISTEN       ,
        OP_ACCEPT       ,
        OP_SHUTDOWN     ,
        OP_GSOCKOPT     ,
        OP_SSOCKOPT     ,
        OP_GETSOCKNAME  ,
        OP_GETPEERNAME  ,
        OP_LSTAT        ,
        OP_STAT         ,
        OP_FTRREAD      ,
        OP_FTRWRITE     ,
        OP_FTREXEC      ,
        OP_FTEREAD      ,
        OP_FTEWRITE     ,
        OP_FTEEXEC      ,
        OP_FTIS         ,
        OP_FTSIZE       ,
        OP_FTMTIME      ,
        OP_FTATIME      ,
        OP_FTCTIME      ,
        OP_FTROWNED     ,
        OP_FTEOWNED     ,
        OP_FTZERO       ,
        OP_FTSOCK       ,
        OP_FTCHR        ,
        OP_FTBLK        ,
        OP_FTFILE       ,
        OP_FTDIR        ,
        OP_FTPIPE       ,
        OP_FTSUID       ,
        OP_FTSGID       ,
        OP_FTSVTX       ,
        OP_FTLINK       ,
        OP_FTTTY        ,
        OP_FTTEXT       ,
        OP_FTBINARY     ,
        OP_CHDIR        ,
        OP_CHOWN        ,
        OP_CHROOT       ,
        OP_UNLINK       ,
        OP_CHMOD        ,
        OP_UTIME        ,
        OP_RENAME       ,
        OP_LINK         ,
        OP_SYMLINK      ,
        OP_READLINK     ,
        OP_MKDIR        ,
        OP_RMDIR        ,
        OP_OPEN_DIR     ,
        OP_READDIR      ,
        OP_TELLDIR      ,
        OP_SEEKDIR      ,
        OP_REWINDDIR    ,
        OP_CLOSEDIR     ,
//        OP_FORK         ,
//        OP_WAIT         ,
//        OP_WAITPID      ,
//        OP_SYSTEM       ,
//        OP_EXEC         ,
        OP_KILL         ,
        OP_GETPPID      ,
        OP_GETPGRP      ,
        OP_SETPGRP      ,
        OP_GETPRIORITY  ,
        OP_SETPRIORITY  ,
        OP_TIME         ,
        OP_TMS          ,
        OP_LOCALTIME    ,
        OP_GMTIME       ,
        OP_ALARM        ,
        OP_SLEEP        ,
        OP_SHMGET       ,
        OP_SHMCTL       ,
        OP_SHMREAD      ,
        OP_SHMWRITE     ,
        OP_MSGGET       ,
        OP_MSGCTL       ,
        OP_MSGSND       ,
        OP_MSGRCV       ,
        OP_SEMOP        ,
        OP_SEMGET       ,
        OP_SEMCTL       ,
        OP_REQUIRE      ,
        OP_DOFILE       ,
        OP_HINTSEVAL    ,
        OP_ENTEREVAL    ,
        OP_LEAVEEVAL    ,
        OP_ENTERTRY     ,
        OP_LEAVETRY     ,
        OP_GHBYNAME     ,
        OP_GHBYADDR     ,
        OP_GHOSTENT     ,
        OP_GNBYNAME     ,
        OP_GNBYADDR     ,
        OP_GNETENT      ,
        OP_GPBYNAME     ,
        OP_GPBYNUMBER   ,
        OP_GPROTOENT    ,
        OP_GSBYNAME     ,
        OP_GSBYPORT     ,
        OP_GSERVENT     ,
        OP_SHOSTENT     ,
        OP_SNETENT      ,
        OP_SPROTOENT    ,
        OP_SSERVENT     ,
        OP_EHOSTENT     ,
        OP_ENETENT      ,
        OP_EPROTOENT    ,
        OP_ESERVENT     ,
        OP_GPWNAM       ,
        OP_GPWUID       ,
        OP_GPWENT       ,
        OP_SPWENT       ,
        OP_EPWENT       ,
        OP_GGRNAM       ,
        OP_GGRGID       ,
        OP_GGRENT       ,
        OP_SGRENT       ,
        OP_EGRENT       ,
        OP_GETLOGIN     ,
        OP_SYSCALL      ,
        OP_LOCK         ,
        OP_ONCE         ,
        OP_CUSTOM       ,
        OP_REACH        ,
        OP_RKEYS        ,
        OP_RVALUES      ,
        OP_COREARGS     ,
        OP_RUNCV        ,
        OP_FC           ,
};

FILE* out;
bool active = FALSE;

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

static void
output_op_leader() {
    fprintf(
        out, "%s%s %s",
        cur_op_context(),
        PL_op->op_flags & OPf_MOD? "=": "",
        OP_NAME(PL_op)
    );
}

void
describe_string(pTHX_ const SV* const sv) {
    I32 prefix, size, sufix;
        IV res = 0;

    if (SvGAMAGIC(sv)) {
        /* For an overloaded or magic scalar, we can't know in advance if
           it's going to be UTF-8 or not. Also, we can't call sv_len_utf8 as
           it likes to cache the length. Maybe that should be a documented
           feature of it.
        */

/* XXX Why we need declarate this? include sv.h */
#define SV_UNDEF_RETURNS_NULL   2048
#define SV_CONST_RETURN         32
#define SV_GMAGIC               2

        STRLEN len;
        const char *const p
            = sv_2pv_flags(sv, &len,
                           SV_UNDEF_RETURNS_NULL|SV_CONST_RETURN|SV_GMAGIC);

        if (!p)
            res = 0;
        else if (DO_UTF8(sv)) {
            res = utf8_length((U8*)p, (U8*)p + len);
        }
        else
            res = len;
    } else if (SvOK(sv)) {
        /* Neither magic nor overloaded.  */
        if (DO_UTF8(sv))
            res = sv_len_utf8(sv);
        else
            res = sv_len(sv);
    } else {
        res = 0;
    }

    fprintf(out, "$%i", res);

}

void
describe_array(pTHX_ const AV* const av) {
    I32 prefix, size, sufix;

    if ( SvTIED_mg((const SV *)av, PERL_MAGIC_tied) ) {
        fprintf(out, "@T");
        return;
    }

    size = AvFILLp(av);
/*
    if ( size > 1000 )
        Perl_warner(aTHX_ packWARN(WARN_MISC), "Big array used: %"IVdf, (IV)size);
*/
    prefix = AvARRAY(av) - AvALLOC(av);
    sufix = AvMAX(av) - size;

    if ( GvAV(PL_defgv) == av ) {
        fprintf(out, "@_(0x%"UVxf")%"IVdf"-%"IVdf"-%"IVdf, PTR2UV(av), (IV)prefix, (IV)size+1, (IV)sufix);
    } else {
        fprintf(out, "@(0x%"UVxf")%"IVdf"-%"IVdf"-%"IVdf, PTR2UV(av), (IV)prefix, (IV)size+1, (IV)sufix);
    }

}

static OP *
pp_stmt_handle_push(pTHX)
{
    dSP; sMARK;

    output_op_leader();
    describe_array(aTHX_ (AV *)(*(MARK+1)) );
    fprintf(out, ", ...%"IVdf, SP-MARK-1);

    run_original_op(PL_op->op_type);
}

static OP *
pp_stmt_handle_substr(pTHX)
{
    dSP; sMARK;
    I32 nargs = SP-MARK-1;

    output_op_leader();
    describe_string(aTHX_ (*(MARK+1)) );
    if ( nargs-- > 0 ) {
        fprintf(out, ", %"IVdf, SvIV(*(SP-nargs)));
    }
    if ( nargs-- > 0 ) {
        fprintf(out, ", %"IVdf, SvIV(*(SP-nargs)));
    }
    if ( nargs-- > 0 ) {
        fprintf(out, ", ");
        describe_string(aTHX_ (*(SP-nargs)) );
    }

    run_original_op(PL_op->op_type);
}

static OP *
pp_stmt_handle_shift(pTHX)
{
    dSP; sMARK;

    output_op_leader();
    describe_array(aTHX_
        PL_op->op_flags & OPf_SPECIAL
        ? GvAV(PL_defgv) : (AV *)(TOPs)
    );

    run_original_op(PL_op->op_type);
}

static OP *
pp_stmt_handle_unshift(pTHX)
{
    dSP; sMARK;

    output_op_leader();
    describe_array(aTHX_ (AV*)*(MARK+1) );
    fprintf(out, ", ...%"IVdf, (IV)(SP-MARK-1));

    run_original_op(PL_op->op_type);
}

static OP *
pp_stmt_handle_splice(pTHX)
{
    dSP; sMARK;
    I32 nargs = SP-MARK-1;

    output_op_leader();
    describe_array(aTHX_ (AV *)(*(MARK+1)) );

    if ( nargs-- > 0 ) {
        fprintf(out, ", %"IVdf, SvIV(*(SP-nargs)));
    }
    if ( nargs-- > 0 ) {
        fprintf(out, ", %"IVdf, SvIV(*(SP-nargs)));
    }
    if ( nargs > 0 ) {
        fprintf(out, ", ...%"IVdf, nargs);
    }

    run_original_op(PL_op->op_type);
}

static OP *
pp_stmt_handle_aelem(pTHX)
{
    dSP; sMARK;

    output_op_leader();
    if ( SP-MARK > 1 ) { /* XXX: handle shift @_ */
        describe_array(aTHX_ (AV *)TOPm1s );
        fprintf(out, ", %"IVdf, (IV)SvIV(TOPs));
    }

    run_original_op(PL_op->op_type);
}

static OP *
pp_stmt_handle_aelemfast(pTHX)
{
    dSP; sMARK;

    output_op_leader();
    if ( PL_op->op_type == OP_AELEMFAST_LEX ) {
        describe_array(aTHX_ PAD_SV(PL_op->op_targ) );
    } else {
        // XXX: how safe is this?
        describe_array(aTHX_ GvAVn(cGVOP_gv) );
    }

    fprintf(out, ", %"IVdf, (IV) PL_op->op_private);

    run_original_op(PL_op->op_type);
}

static OP *
pp_stmt_handle_method(pTHX)
{
    dSP;

    output_op_leader();
    fprintf(out, ", %s", SvPV_nolen_const(TOPs));
    run_original_op(PL_op->op_type);
}

static OP *
pp_stmt_handle_method_named(pTHX)
{
    dSP;

    output_op_leader();
    fprintf(out, ", %s", SvPV_nolen_const(cSVOP_sv));
    run_original_op(PL_op->op_type);
}

static OP *
pp_stmt_handle_aassign(pTHX)
{
    dVAR; dSP;
    SV **lastlelem = PL_stack_sp;
    SV **lastrelem = PL_stack_base + TOPMARK;
    SV **firstrelem = PL_stack_base + *(PL_markstack_ptr-1) + 1;
    SV **firstlelem = lastrelem + 1;

    output_op_leader();
    while (firstlelem <= lastlelem) {
        switch (SvTYPE(*firstlelem)) {
        case SVt_PVAV:
            fprintf(out, ", @");
            break;
        case SVt_PVHV:
            fprintf(out, ", %%");
            break;
        default:
            fprintf(out, ", $");
            break;
        }
        firstlelem++;
    }
    fprintf(out, ", ...%"IVdf, lastrelem - firstrelem + 1);

    run_original_op(PL_op->op_type);
}

static OP *
pp_stmt_handle_simple(pTHX)
{
    dSP; sMARK;
    output_op_leader();
    run_original_op(PL_op->op_type);
}

static OP*
pp_stmt_dispatcher(pTHX)
{
    if (!active)
        return CALL_FPTR(PL_ppaddr_orig[PL_op->op_type])(aTHX);

    return CALL_FPTR(PL_ppaddr_mine[PL_op->op_type])(aTHX);
}

static int
init_handler(pTHX)
{
    int i;
    Newxc(PL_ppaddr_orig, OP_max, void *, orig_ppaddr_t);
    Copy(PL_ppaddr, PL_ppaddr_orig, OP_max, void *);

    Newxc(PL_ppaddr_mine, OP_max, void *, orig_ppaddr_t);
    Zero(PL_ppaddr_mine, OP_max, void *);

    PL_ppaddr_mine[OP_AASSIGN]    = pp_stmt_handle_aassign;
    PL_ppaddr_mine[OP_AELEM]      = pp_stmt_handle_aelem;
    PL_ppaddr_mine[OP_AELEMFAST]  = pp_stmt_handle_aelemfast;

    PL_ppaddr_mine[OP_METHOD]     = pp_stmt_handle_method;
    PL_ppaddr_mine[OP_METHOD_NAMED]     = pp_stmt_handle_method_named;

    PL_ppaddr_mine[OP_POP]        = pp_stmt_handle_shift;
    PL_ppaddr_mine[OP_PUSH]       = pp_stmt_handle_push;
    PL_ppaddr_mine[OP_SHIFT]      = pp_stmt_handle_shift;
    PL_ppaddr_mine[OP_UNSHIFT]    = pp_stmt_handle_unshift;
//    PL_ppaddr_mine[OP_SUBSTR]     = pp_stmt_handle_substr;

    PL_ppaddr_mine[OP_SPLICE]     = pp_stmt_handle_splice;

    for( i = 0; i < OP_max; i++ ) {
        if ( handle_ops[i] != 0 ) {
            if ( !PL_ppaddr_mine[handle_ops[i]] )
                PL_ppaddr_mine[handle_ops[i]] = pp_stmt_handle_simple;

            PL_ppaddr[handle_ops[i]] = pp_stmt_dispatcher;
        }
    }

    out = open_report_file();
}

static int
start()
{
    active = TRUE;
}
static int
stop()
{
    active = FALSE;
}


MODULE = Devel::PPAP   PACKAGE = Devel::PPAP

PROTOTYPES: DISABLE

int
init_handler()
    C_ARGS:
    aTHX

int
start()

int
stop()

