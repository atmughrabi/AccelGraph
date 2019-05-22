#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <argp.h>
#include <stdbool.h>
#include <omp.h>

#include "graphRun.h"
#include "graphStats.h"
#include "edgeList.h"
#include "myMalloc.h"
#include "timer.h"
#include "mt19937.h"

int numThreads;
mt19937state *mt19937var;

const char *argp_program_version =
    "AccelGraph 1.0";
const char *argp_program_bug_address =
    "<atmughra@ncsu.edu>";
/* Program documentation. */
static char doc[] =
    "AccelGraph is an open source graph processing framework, it is designed to be a portable benchmarking suite for various graph processing algorithms.";

/* A description of the arguments we accept. */
static char args_doc[] = "-f <graph file> -d [data structure] -a [algorithm] -r [root] -n [num threads] [-h -c -s -w]";

/* The options we understand. */
static struct argp_option options[] =
{
    {
        "graph-file",         'f', "<FILE>",      0,
        "edge list represents the graph binary format to run the algorithm textual format with -convert option"
    },
    {
        "algorithm",         'a', "[ALGORITHM #]",      0,
        "[0]-BFS, [1]-Pagerank, [2]-SSSP-DeltaStepping, [3]-SSSP-BellmanFord, [4]-DFS [5]-IncrementalAggregation"
    },
    {
        "data-structure",    'd', "[TYPE #]",      0,
        "[0]-CSR, [1]-Grid, [2]-Adj LinkedList, [3]-Adj ArrayList [4-5] same order bitmap frontiers"
    },
    {
        "root",              'r', "[SOURCE|ROOT]",      0,
        "BFS, DFS, SSSP root"
    },
    {
        "direction",         'p', "[PUSH|PULL]",      0,
        "[0-1]-push/pull [2-3]-push/pull fixed point arithmetic [4-6]-same order but using data driven"
    },
    {
        "sort",              'o', "[RADIX|COUNT]",      0,
        "[0]-radix-src [1]-radix-src-dest [2]-count-src [3]-count-src-dst"
    },
    {
        "num-threads",       'n', "[# THREADS]",      0,
        "default:max number of threads the system has"
    },
    {
        "num-iterations",    'i', "[# ITERATIONS]",      0,
        "number of iterations for pagerank to converge [default:20] SSSP-BellmanFord [default:V-1] "
    },
    {
        "num-trials",        't', "[# TRIALS]",      0,
        "number of random trials for each whole run (graph algorithm run) [default:0] "
    },
    {
        "tolerance",         'e', "[EPSILON:0.0001]",      0,
        "tolerance value of for page rank [default:0.0001] "
    },
    {
        "epsilon",           'e', "[EPSILON:0.0001]",      OPTION_ALIAS
    },
    {
        "delta",             'b', "[DELTA:1]",      0,
        " SSSP Delta value [Default:1]"
    },
    {
        "light-reorder",     'l', "[ORDER:0]",      0,
        "Relabels the graph for better cache performance. [default:0]-no-reordering [1]-pagerank-order [2]-in-degree [3]-out-degree [4]-in/out degree [5]-Rabbit [6]-Epoch-pageRank [7]-Epoch-BFS [8]-LoadFromFile "
    },
    {
        "convert-bin",       'c', 0,      0,
        "read graph text format convert to bin graph file on load example:-f <graph file> -c"
    },
    {
        "generate-weights",  'w', 0,      0,
        "generate random weights don't load from graph file. Check ->graphConfig.h #define WEIGHTED 1 beforehand then recompile using this option"
    },
    {
        "symmetrise",        's', 0,      0,
        "Symmetric graph, create a set of incoming edges"
    },
    {
        "stats",             'x', 0,      0,
        "dump a histogram to file based on in-out degree count bins / sorted according to in/out-degree or pageranks "
    },
    { 0 }
};

/* Used by main to communicate with parse_opt. */
struct arguments
{
    int wflag;
    int xflag;
    int sflag;
    int cflag;

    __u32 iterations;
    __u32 trials;
    double epsilon;
    int root;
    __u32 algorithm;
    __u32 datastructure;
    __u32 pushpull;
    __u32 sort;
    __u32 lmode;
    __u32 symmetric;
    __u32 weighted;
    __u32 delta;
    __u32 numThreads;
    char *fnameb;
};


/* Parse a single option. */
static error_t
parse_opt (int key, char *arg, struct argp_state *state)
{
    /* Get the input argument from argp_parse, which we
       know is a pointer to our arguments structure. */
    struct arguments *arguments = state->input;

    switch (key)
    {
    case 'f':
        arguments->fnameb = arg;
        break;
    case 'd':
        arguments->datastructure = atoi(arg);
        break;
    case 'a':
        arguments->algorithm = atoi(arg);
        break;
    case 'r':
        arguments->root = atoi(arg);
        break;
    case 'n':
        arguments->numThreads = atoi(arg);
        break;
    case 'i':
        arguments->iterations = atoi(arg);
        break;
    case 't':
        arguments->trials = atoi(arg);
        break;
    case 'e':
        arguments->epsilon = atof(arg);
        break;
    case 'p':
        arguments->pushpull = atoi(arg);
        break;
    case 'o':
        arguments->sort = atoi(arg);
        break;
    case 'l':
        arguments->lmode = atoi(arg);
        break;
    case 'b':
        arguments->delta = atoi(arg);
        break;
    case 's':
        arguments->symmetric = 1;
        break;
    case 'w':
        arguments->weighted = 1;
        break;
    case 'x':
        arguments->xflag = 1;
        break;
    case 'c':
        arguments->cflag = 1;
        break;

    default:
        return ARGP_ERR_UNKNOWN;
    }
    return 0;
}


static struct argp argp = { options, parse_opt, args_doc, doc };

int
main (int argc, char **argv)
{

    struct arguments arguments;
    /* Default values. */

    arguments.wflag = 0;
    arguments.xflag = 0;
    arguments.sflag = 0;
    arguments.cflag = 0;

    arguments.iterations = 20;
    arguments.trials = 0;
    arguments.epsilon = 0.0001;
    arguments.root = -1;
    arguments.algorithm = 0;
    arguments.datastructure = 0;
    arguments.pushpull = 0;
    arguments.sort = 0;
    arguments.lmode = 0;
    arguments.symmetric = 0;
    arguments.weighted = 0;
    arguments.delta = 1;
    arguments.numThreads = omp_get_max_threads();
    arguments.fnameb = NULL;


    void *graph = NULL;

    argp_parse (&argp, argc, argv, 0, 0, &arguments);

    numThreads =  arguments.numThreads;

    struct Timer *timer = (struct Timer *) my_malloc(sizeof(struct Timer));

    mt19937var = (mt19937state *) my_malloc(sizeof(mt19937state));
    initializeMersenneState (mt19937var, 27491095);

    omp_set_nested(1);
    omp_set_num_threads(numThreads);

    __u32 binSize = arguments.iterations;
    __u32 inout_degree = arguments.pushpull;
    __u32 inout_lmode = arguments.lmode;


    if(arguments.xflag)
    {
        collectStats(binSize, arguments.fnameb, arguments.sort, inout_lmode, arguments.symmetric, arguments.weighted, inout_degree);
    }
    else
    {

        if(arguments.cflag)
        {
            Start(timer);
            arguments.fnameb = readEdgeListstxt(arguments.fnameb, arguments.weighted);
            Stop(timer);
            printf("Read Edge List From File converted to binary : %f Seconds \n", Seconds(timer));
        }
        else
        {
            graph = generateGraphDataStructure(arguments.fnameb, arguments.datastructure, arguments.sort, arguments.lmode, arguments.symmetric, arguments.weighted);
            runGraphAlgorithms(graph, arguments.datastructure, arguments.algorithm, arguments.root, arguments.iterations, arguments.epsilon, arguments.trials, arguments.pushpull, arguments.delta);
        }
    }




    free(timer);
    exit (0);
}




