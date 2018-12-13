#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <omp.h>

#include "graphRun.h"
#include "edgeList.h"
#include "myMalloc.h"
#include "timer.h"
#include "mt19937.h"

int numThreads;

static void usage(void) {
  printf("\nUsage: ./main -f <graph file> -d [data structure] -a [algorithm] -r [root] -n [num threads] [-h -c -s -w]\n");
  printf("\t-h [Help] \n");
  printf("\t-a [algorithm] : [0]-BFS, [1]-Pagerank, [2]-SSSP-DeltaStepping, [3]-SSSP-BellmanFord, [4]-DFS [5]-IncrementalAggregation\n");
  printf("\t-d [data structure] : [0]-CSR, [1]-Grid, [2]-Adj LinkedList, [3]-Adj ArrayList [4-5] same order bitmap frontiers\n");
  printf("\t-r [root]: BFS, DFS, SSSP root\n");
  printf("\t-p [algorithm direction] [0-1]-push/pull [2-3]-push/pull fixed point arithmetic [4-6]-same order but using data driven\n");
  printf("\t-o [sorting algorithm] [0]-radix-src [1]-radix-src-dest [2]-count-src [3]-count-src-dst.\n");
  printf("\t-n [num threads] default:max number of threads the system has\n");
  printf("\t-i [num iterations] number of iterations for pagerank to converge [default:20] SSSP-BellmanFord [default:V-1] \n");
  printf("\t-t [num trials] number of random trials for each whole run [default:0]\n");
  printf("\t-e [epsilon/tolerance] tolerance value of for page rank [default:0.0001]\n");
  printf("\t-l [mode] lightweight reordering [default:0]-no-reordering [1]-pagerank-order [2]-in-degree [3]-out-degree [4]-in/out degree [5]-Rabbit  \n");
  printf("\t-c: read text format convert to bin file on load example:-f <graph file> -c\n");
  printf("\t-w: Weight generate random or load from file graph check graphConfig.h #define WEIGHTED 1 beforehand then recompile with using this option\n");
  printf("\t-s: Symmetric graph, if not given set of incoming edges will be created \n");
  printf("\t-b: SSSP Delta value Default [1] \n"); 
  _exit(-1);
}

int main (int argc, char **argv)
{
  // int uflag = 0;
  int wflag = 0;
  int sflag = 0;
  int cflag = 0;

  char *fvalue = NULL;
  char *avalue = NULL;
  char *rvalue = NULL;
  char *dvalue = NULL;
  char *nvalue = NULL;
  char *ivalue = NULL;
  char *tvalue = NULL;
  char *evalue = NULL;
  char *pvalue = NULL;
  char *ovalue = NULL;
  char *lvalue = NULL;
  char *bvalue = NULL;

  __u32 iterations = 20;
  __u32 trials = 0;
  double epsilon = 0.0001;
  int root = -1;
  __u32 algorithm = 0;
  __u32 datastructure = 0;
  __u32 pushpull = 0;
  __u32 sort = 0;
  __u32 lmode = 0;
  __u32 symmetric = 0;
  __u32 weighted = 0;
  __u32 delta = 1;


  numThreads = omp_get_max_threads();

  char *fnameb = NULL;
  void *graph = NULL;


  int c;
  opterr = 0;

  while ((c = getopt (argc, argv, "h:f:d:a:r:n:i:t:e:p:o:l:b:chsw")) != -1)
    switch (c)
      {
      case 'h':
        usage();
        break;
      case 'f':
        fvalue = optarg;
        fnameb = fvalue;
        break;
      case 'd':
        dvalue = optarg;
        datastructure = atoi(dvalue);
        break;
      case 'a':
        avalue = optarg;
        algorithm = atoi(avalue);
        break;
      case 'r':
        rvalue = optarg;
        root = atoi(rvalue);
        break;
       break;
      case 'n':
        nvalue = optarg;
        numThreads = atoi(nvalue);
        break;
      case 'i':
        ivalue = optarg;
        iterations = atoi(ivalue);
        break;
      case 't':
        tvalue = optarg;
        trials = atoi(tvalue);
        break;
      case 'e':
        evalue = optarg;
        epsilon = atof(evalue);
        break;
      case 'p':
        pvalue = optarg;
        pushpull = atoi(pvalue);
        break;
      case 'o':
        ovalue = optarg;
        sort = atoi(ovalue);
        break;
      case 'l':
        lvalue = optarg;
        lmode = atoi(lvalue);
        break;
      case 'b':
        bvalue = optarg;
        delta = atoi(bvalue);
        break;
      case 's':
        sflag = 1;
        symmetric = sflag;
        break;
      case 'w':
        wflag = 1;
        weighted = wflag;
        break;
      case 'c':
        cflag = 1;
        break;
      case '?':
        if (optopt == 'f')
          fprintf (stderr, "Option -%c <graph file> requires an argument  .\n", optopt);
        else if (optopt == 'd')
          fprintf (stderr, "Option -%c [data structure] requires an argument.\n", optopt);
        else if (optopt == 'a')
          fprintf (stderr, "Option -%c [algorithm] requires an argument.\n", optopt);
        else if (optopt == 'r')
          fprintf (stderr, "Option -%c [root] requires an argument.\n", optopt);
        else if (optopt == 'n')
          fprintf (stderr, "Option -%c [num threads] requires an argument.\n", optopt);
        else if (optopt == 'i')
          fprintf (stderr, "Option -%c [num iterations] requires an argument.\n", optopt);
        else if (optopt == 't')
          fprintf (stderr, "Option -%c [num trials] requires an argument.\n", optopt);
        else if (optopt == 'e')
          fprintf (stderr, "Option -%c [epsilon] requires an argument.\n", optopt);
        else if (optopt == 'p')
          fprintf (stderr, "Option -%c [push/pull] requires an argument.\n", optopt);
        else if (optopt == 'o')
          fprintf (stderr, "Option -%c [radix/count] requires an argument.\n", optopt);
        else if (optopt == 'l')
          fprintf (stderr, "Option -%c [mode] lightweight reordering requires an argument.\n", optopt);
        else if (optopt == 'b')
          fprintf (stderr, "Option -%c [delta] SSSP delta stepping value requires an argument.\n", optopt);
        else if (isprint (optopt))
          fprintf (stderr, "Unknown option `-%c'.\n", optopt);
        else
          fprintf (stderr,
                   "Unknown option character `\\x%x'.\n",
                   optopt);

        usage();
        return 1;
      default:
        abort ();
      }

      struct Timer* timer = (struct Timer*) my_malloc(sizeof(struct Timer));
      
      init_genrand(27491095);
      omp_set_nested(1);
      omp_set_num_threads(numThreads);

      if(cflag)
      {
        Start(timer);
        fnameb = readEdgeListstxt(fnameb, weighted);
        Stop(timer);
        printf("Read Edge List From File converted to binary : %f Seconds \n",Seconds(timer));
      }
      else{
        graph = generateGraphDataStructure(fnameb, datastructure, sort, lmode, symmetric, weighted);
        runGraphAlgorithms(graph, datastructure, algorithm, root, iterations, epsilon, trials, pushpull,delta);
      }

     
     


      free(timer);
  return 0;
}



