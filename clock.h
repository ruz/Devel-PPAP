
/* time tracking */
/*
    Almost exact copy from NYTProf, I would love to see it
    generalized.

*/

#ifdef HAS_CLOCK_GETTIME
typedef struct timespec time_of_day_t;
#  define CLOCK_GETTIME(ts) clock_gettime(profile_clock, ts)
#  define CLOCKS_PER_TICK 10000000                /* 10 million - 100ns */
#  define get_time_of_day(into) CLOCK_GETTIME(&into)
#  define get_ticks_between(s, e, ticks, overflow) STMT_START { \
    overflow = 0; \
    ticks = ((e.tv_sec - s.tv_sec) * CLOCKS_PER_TICK + (e.tv_nsec / 100) - (s.tv_nsec / 100)); \
} STMT_END

#else                                             /* !HAS_CLOCK_GETTIME */

#ifdef HAS_MACH_TIME

#include <mach/mach.h>
#include <mach/mach_time.h>

mach_timebase_info_data_t  our_timebase;
typedef uint64_t time_of_day_t;

#  define CLOCKS_PER_TICK 10000000                /* 10 million - 100ns */
#  define get_time_of_day(into) into = mach_absolute_time()
#  define get_ticks_between(s, e, ticks, overflow) STMT_START { \
    overflow = 0; \
    if( our_timebase.denom == 0 ) mach_timebase_info(&our_timebase); \
    ticks = (e-s) * our_timebase.numer / our_timebase.denom / 100; \
} STMT_END

#else                                             /* !HAS_MACH_TIME */

#ifdef HAS_GETTIMEOFDAY
typedef struct timeval time_of_day_t;
#  define CLOCKS_PER_TICK 10000000                 /* 1 million */
#  define get_time_of_day(into) gettimeofday(&into, NULL)
#  define get_ticks_between(s, e, ticks, overflow) STMT_START { \
    overflow = 0; \
    ticks = ((e.tv_sec - s.tv_sec) * CLOCKS_PER_TICK + (e.tv_usec - s.tv_usec)*10); \
} STMT_END
#else
static int (*u2time)(pTHX_ UV *) = 0;
typedef UV time_of_day_t[2];
#  define CLOCKS_PER_TICK 10000000                 /* 1 million */
#  define get_time_of_day(into) (*u2time)(aTHX_ into)
#  define get_ticks_between(s, e, ticks, overflow)  STMT_START { \
    overflow = 0; \
    ticks = ((e[0] - s[0]) * CLOCKS_PER_TICK + (e[1] - s[1])*10); \
} STMT_END
#endif
#endif
#endif

static time_of_day_t start_time, end_time;
/* end of time tracking */

