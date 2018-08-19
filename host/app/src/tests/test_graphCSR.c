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

    #if DIRECTED
        Start(timer);
        struct EdgeList* inverse_edgeList = readEdgeListsbin(fnameb,1);
        Stop(timer);
        // edgeListPrint(inverse_edgeList);
        printMessageWithtime("Read Inverse Edge List From File (Seconds)",Seconds(timer));
    #endif

    #if DIRECTED
        struct GraphCSR* graphCSR = graphCSRNew(edgeList->num_vertices, edgeList->num_edges, 1);
    #else
        struct GraphCSR* graphCSR = graphCSRNew(edgeList->num_vertices, edgeList->num_edges, 0);
    #endif

    
   
    Start(timer);
    edgeList = radixSortEdgesBySourceOptimized(edgeList);
    Stop(timer);
    printMessageWithtime("Radix Sort Edges By Source (Seconds)",Seconds(timer));


     #if DIRECTED
        Start(timer);
        inverse_edgeList = radixSortEdgesBySourceOptimized(inverse_edgeList);
        Stop(timer);
        printMessageWithtime("Radix Sort Inverse Edges By Source (Seconds)",Seconds(timer));
    #endif
    
    // edgeListPrint(inverse_edgeList);

    Start(timer);
    graphCSR = graphCSRAssignEdgeList (graphCSR,edgeList, 0);
    Stop(timer);
    printMessageWithtime("Process In/Out degrees of Nodes (Seconds)",Seconds(timer));

    #if DIRECTED
        Start(timer);
        graphCSR = graphCSRAssignEdgeList (graphCSR,inverse_edgeList, 1);
        Stop(timer);
        printMessageWithtime("Process In/Out degrees of Inverse Nodes (Seconds)",Seconds(timer));
    #endif

    graphCSRPrint(graphCSR);
    

    Start(timer);
    breadthFirstSearchGraphCSR(428333, graphCSR);
    // breadthFirstSearchGraphCSR(6, graphCSR);
    Stop(timer);
    printMessageWithtime("Breadth First Search Total Time (Seconds)",Seconds(timer));


    // printGraphParentsArray(graphCSR);

    graphCSRFree(graphCSR);
    // freeEdgeList(edgeList);
    // #if DIRECTED
    //     freeEdgeList(inverse_edgeList);
    // #endif
    free(timer);
    return 0;
}