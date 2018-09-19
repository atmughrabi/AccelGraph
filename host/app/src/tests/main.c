#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <omp.h>

#include "graphRun.h"

int numThreads;

static void usage(void) {
  printf("\nUsage: ./main -f <graph file> -d [data structure] -a [algorithm] -r [root] -n [num threads] [-u -s -w]\n");
  printf("\t-a [algorithm] : 0 bfs, 1 pagerank, 2 SSSP\n");
  printf("\t-d [data structure] : 0 CSR, 1 Grid, 2 Adj Linked List, 3 Adj Array List\n");
  printf("\t-r [root]: BFS & SSSP root\n");
  printf("\t-n [num threads] default:max number of threads the system has\n");
  printf("\t-u: create undirected on load => check graphConfig.h #define DIRECTED 0 then recompile\n");
  printf("\t-w: weighted input graph check graphConfig.h #define WEIGHTED 1 then recompile\n");
  printf("\t-s: symmetrict graph, if not given set of incoming edges will be created \n"); 
  _exit(-1);
}

int main (int argc, char **argv)
{
  int uflag = 0;
  int wflag = 0;
  int sflag = 0;

  char *fvalue = NULL;
  char *avalue = NULL;
  char *rvalue = NULL;
  char *dvalue = NULL;
  char *nvalue = NULL;

  int root = 0;
  int algorithm = 0;
  int datastructure = 0;
  numThreads = omp_get_max_threads();

  char *fnameb = NULL;
  void *graph = NULL;


  int c;
  opterr = 0;

  while ((c = getopt (argc, argv, "h:f:d:a:r:n:usw")) != -1)
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
      case 'u':
        uflag = 1;
        break;
      case 's':
        wflag = 1;
        break;
      case 'w':
        sflag = 1;
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
        else if (optopt == 'r')
          fprintf (stderr, "Option -%c [root] requires an argument.\n", optopt);
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

     
      omp_set_nested(1);
      omp_set_num_threads(numThreads);
      graph = generateGraphDataStructure(fnameb, datastructure);
      runGraphAlgorithms(graph, datastructure, algorithm, root);

  return 0;
}



