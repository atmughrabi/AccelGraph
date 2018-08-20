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
#include "myMalloc.h"

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


    const char * fnameb = "host/app/datasets/test/test.txt.bin";
    // const char * fnameb = "host/app/datasets/twitter/twitter_rv.txt.bin";
    // const char * fnameb = "host/app/datasets/twitter/twitter_rv.txt.bin8";
    // const char * fnameb = "host/app/datasets/facebook/facebook_combined.txt.bin";
    // const char * fnameb = "host/app/datasets/wiki-vote/wiki-Vote.txt.bin";


    struct Timer* timer = (struct Timer*) my_malloc(sizeof(struct Timer));
    struct GraphAdjArrayList* graphAdjArrayList = NULL;
    __u32 root = 6;
    // printf("Filename : %s \n",fnameb);
    
    // Start(timer);
    // readEdgeListstxt(fname);
    // Stop(timer);
    // printf("Read Edge List From File converted to binary : %f Seconds \n",Seconds(timer));
   
    Start(timer);
    graphAdjArrayList = graphAdjArrayListPreProcessingStep (fnameb);
    Stop(timer);
    printMessageWithtime("GraphAdjArrayList Preprocessing Step Total Time (Seconds)",Seconds(timer));

    Start(timer);
    breadthFirstSearchGraphAdjArrayList(root, graphAdjArrayList);
    Stop(timer);
    printMessageWithtime("Breadth First Search Total Time (Seconds)",Seconds(timer));

    Start(timer); 
    graphAdjArrayListFree(graphAdjArrayList);
    Stop(timer);
    printMessageWithtime("Free Graph Adjacency Array List (Seconds)",Seconds(timer));
    

    free(timer);
    return 0;
}