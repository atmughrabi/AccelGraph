#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include "libcxl.h"

#include "capienv.h"
#include "adjLinkedList.h" 
#include "dynamicQueue.h"
#include "edgeList.h"

//edgelist prerpcessing
#include "countsort.h"
#include "radixsort.h"


#include "graphCSR.h"
#include "graphAdjLinkedList.h"
#include "graphAdjArrayList.h"

#include "vertex.h"
#include "timer.h"
#include "BFS.h"


void printMessageWithtime(const char * msg, double time){

    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", msg);
    printf(" -----------------------------------------------------\n");
    printf("| %-51f | \n", time);
    printf(" -----------------------------------------------------\n");

}


int main()
{
    // create the graph given in above fugure
    // int V = 5;

    // const char * fname = "host/app/datasets/test/test.txt";
    // const char * fname = "host/app/datasets/wiki-vote/wiki-Vote.txt";
    // const char * fname = "host/app/datasets/twitter/twitter_rv.txt";
    // const char * fname = "host/app/datasets/facebook/facebook_combined.txt";


    // const char * fnameb = "host/app/datasets/test/test.txt.bin";
    // const char * fnameb = "host/app/datasets/twitter/twitter_rv.txt.bin";
    const char * fnameb = "host/app/datasets/twitter/twitter_rv.txt.bin8";
    // const char * fnameb = "host/app/datasets/facebook/facebook_combined.txt.bin";
    // const char * fnameb = "host/app/datasets/wiki-vote/wiki-Vote.txt.bin";


    struct Timer* timer = (struct Timer*) malloc(sizeof(struct Timer));

    printf("Filename : %s \n",fnameb);
    
    // Start(timer);
    // readEdgeListstxt(fname);
    // Stop(timer);
    // printf("Read Edge List From File converted to binary : %f Seconds \n",Seconds(timer));

    Start(timer);
    struct EdgeList* edgeList = readEdgeListsbin(fnameb,0);
    Stop(timer);
    // edgeListPrint(edgeList);
    printMessageWithtime("Read Edge List From File (Seconds)",Seconds(timer));

    Start(timer);
    edgeList = radixSortEdgesBySourceOptimized(edgeList);
    Stop(timer);
    printMessageWithtime("Radix Sort Edges By Source (Seconds)",Seconds(timer));

    Start(timer); 
    struct GraphAdjArrayList* graph = graphAdjArrayListEdgeListNew(edgeList);
    Stop(timer);
    printMessageWithtime("Create Adj Array List from EdgeList (Seconds)",Seconds(timer));
  

    graphAdjArrayListPrint(graph);

    Start(timer); 
    graphAdjArrayListFree(graph);
    Stop(timer);
    printMessageWithtime("Free Graph Adjacency Array List (Seconds)",Seconds(timer));
  
 
    return 0;
}