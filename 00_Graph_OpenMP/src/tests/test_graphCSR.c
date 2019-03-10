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


    // const char * fnameb = "/home/atmughra/12_Github/1_Graph_Benchmark_Tools/gapbs/benchmark/graphs/raw/twitter_rv.net";
    // const char * fname = "host/app/datasets/test/test.txt";
    // const char * fname = "host/app/datasets/wiki-vote/wiki-Vote.txt";
    // const char * fname = "host/app/datasets/twitter/twitter_rv.txt";
    // const char * fname = "host/app/datasets/facebook/facebook_combined.txt";

                           
    // const char * fnameb = "/home/atmughra/12_Github/1_Graph_Benchmark_Tools/gapbs/benchmark/graphs/bin/twitter_rv.net.bin8";
    const char * fnameb = "host/app/datasets/test/test.txt.bin";
    // const char * fnameb = "host/app/datasets/twitter/twitter_rv.txt.bin";
    // const char * fnameb = "host/app/datasets/twitter/twitter_rv.txt.bin8";
    // const char * fnameb = "host/app/datasets/facebook/facebook_combined.txt.bin";
    // const char * fnameb = "host/app/datasets/wiki-vote/wiki-Vote.txt.bin";


    struct Timer* timer = (struct Timer*) malloc(sizeof(struct Timer));
    struct GraphCSR* graphCSR = NULL;
    __u32 root = 6;

    // printf("Filename : %s \n",fnameb);
    
    // // Start(timer);
    // // readEdgeListstxt(fname);
    // // Stop(timer);
    // // printf("Read Edge List From File converted to binary : %f Seconds \n",Seconds(timer));

    Start(timer);
    graphCSR = graphCSRPreProcessingStep (fnameb);
    Stop(timer);
    printMessageWithtime("GraphCSR Preprocessing Step Total Time (Seconds)",Seconds(timer));


    Start(timer);
    breadthFirstSearchGraphCSR(root, graphCSR);
    Stop(timer);
    printMessageWithtime("Breadth First Search Total Time (Seconds)",Seconds(timer));

    graphCSRFree(graphCSR);
    free(timer);
    return 0;
}