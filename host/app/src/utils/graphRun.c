#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include "graphCSR.h"
#include "graphAdjLinkedList.h"
#include "graphAdjArrayList.h"
#include "graphGrid.h"

#include "graphConfig.h"
#include "timer.h"
#include "graphRun.h"
#include "BFS.h"
#include "mt19937.h"

void generateGraphPrintMessageWithtime(const char * msg, double time){

    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", msg);
    printf(" -----------------------------------------------------\n");
    printf("| %-51f | \n", time);
    printf(" -----------------------------------------------------\n");

}



void * generateGraphDataStructure(const char *fnameb, int datastructure){

    struct Timer* timer = (struct Timer*) malloc(sizeof(struct Timer));
    void *graph = NULL;

    switch (datastructure)
      { 
        case 0: // CSR
            Start(timer);
            graph = (void *)graphCSRPreProcessingStep (fnameb);
            Stop(timer);
            generateGraphPrintMessageWithtime("GraphCSR Preprocessing Step Time (Seconds)",Seconds(timer));
          break;
        case 1: // Grid
            Start(timer);
            graph = (void *)graphGridPreProcessingStep (fnameb);
            Stop(timer);
            generateGraphPrintMessageWithtime("GraphGrid Preprocessing Step Time (Seconds)",Seconds(timer));
          break;
        case 2: // Adj Linked List     
            Start(timer);
            graph = (void *)graphAdjLinkedListPreProcessingStep (fnameb);
            Stop(timer);
            generateGraphPrintMessageWithtime("GraphAdjLinkedList Preprocessing Step Time (Seconds)",Seconds(timer));
          break;
        case 3: // Adj Array List
            Start(timer);
            graph = (void *)graphAdjArrayListPreProcessingStep (fnameb);
            Stop(timer);
            generateGraphPrintMessageWithtime("GraphAdjArrayList Preprocessing Step Time (Seconds)",Seconds(timer));
          break;
        default:// CSR
            Start(timer);
            graph = (void *)graphCSRPreProcessingStep (fnameb);
            Stop(timer);
            generateGraphPrintMessageWithtime("GraphCSR Preprocessing Step Time (Seconds)",Seconds(timer));
       
          break;          
      }


     free(timer);
     return graph;

}


void runGraphAlgorithms(void *graph, int datastructure,int algorithm, int root, int iterations){

  switch (algorithm)
      {
        case 0: // bfs filename root 
          runBreadthFirstSearchAlgorithm(graph, datastructure, root, iterations);
          break;
        case 1: // pagerank filename
          printf(" pagerank to be implemented %d \n", iterations);
          break;
        case 2: // SSSP file name root
          printf(" SSSP to be implemented \n");
          break;
        default:// bfs file name root
          runBreadthFirstSearchAlgorithm(graph,datastructure, root, iterations);
          break;          
      }

}



void runBreadthFirstSearchAlgorithm(void *graph, int datastructure, int root, int iterations){

    struct Timer* timer = (struct Timer*) malloc(sizeof(struct Timer));
    struct GraphCSR* graphCSR = NULL;
    struct GraphGrid* graphGrid = NULL;
    struct GraphAdjLinkedList* graphAdjLinkedList = NULL;
    struct GraphAdjArrayList* graphAdjArrayList = NULL;
    printf("*-----------------------------------------------------*\n");
    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting Breadth First Search (SOURCE NODE) ");
    printf(" -----------------------------------------------------\n");
    printf("| %-51u | \n", root);
    printf(" -----------------------------------------------------\n");
    printf("| %-20s %-30u | \n", "Number of Threads :",numThreads);
    printf(" -----------------------------------------------------\n");

    switch (datastructure)
      { 
        case 0: // CSR
            graphCSR = (struct GraphCSR*)graph;
            // if(root >= 0 && root <= graphCSR->num_vertices){
            //   Start(timer);
            //   breadthFirstSearchGraphCSR(root, graphCSR);
            //   Stop(timer);
            //   generateGraphPrintMessageWithtime("Breadth First Search Total Time (Seconds)",Seconds(timer));
            // }
            // while(iterations){
            //   while(1){
            //     root = genrand_int32();
            //       if(root < graphCSR->num_vertices){
            //         if( graphCSR->vertices[root].out_degree > 0 )
            //          break;
            //     }
            //   }
            // if(root >= 0 && root <= graphCSR->num_vertices){
            //   Start(timer);
            //   breadthFirstSearchGraphCSR(root, graphCSR);
            //   Stop(timer);
            //   generateGraphPrintMessageWithtime("Breadth First Search Total Time (Seconds)",Seconds(timer));
            // }   
            //    iterations--;
            // }

             
            
            Start(timer);
            breadthFirstSearchGraphCSR(12441072, graphCSR);
            breadthFirstSearchGraphCSR(54488257, graphCSR);
            breadthFirstSearchGraphCSR(25451915, graphCSR);
            breadthFirstSearchGraphCSR(57714473, graphCSR);
            breadthFirstSearchGraphCSR(14839494, graphCSR);
            breadthFirstSearchGraphCSR(32081104, graphCSR);
            breadthFirstSearchGraphCSR(52957357, graphCSR);
            breadthFirstSearchGraphCSR(50444380, graphCSR);
            Stop(timer);
            generateGraphPrintMessageWithtime("Breadth First Search Total Time (Seconds)",Seconds(timer));
            graphCSRFree(graphCSR);
          break;
        case 1: // Grid
            graphGrid = (struct GraphGrid*)graph;
            Start(timer);
            breadthFirstSearchGraphGrid(root, graphGrid);
            Stop(timer);
            generateGraphPrintMessageWithtime("Breadth First Search Total Time (Seconds)",Seconds(timer));
            Start(timer); 
            graphGridFree(graphGrid);
            Stop(timer);
            generateGraphPrintMessageWithtime("Free Graph Grid (Seconds)",Seconds(timer));
          break;
        case 2: // Adj Linked List
            graphAdjLinkedList = (struct GraphAdjLinkedList*)graph;
            Start(timer);
            breadthFirstSearchGraphAdjLinkedList(root, graphAdjLinkedList);
            Stop(timer);
            generateGraphPrintMessageWithtime("Breadth First Search Total Time (Seconds)",Seconds(timer));
            Start(timer); 
            graphAdjLinkedListFree(graphAdjLinkedList);
            Stop(timer);
            generateGraphPrintMessageWithtime("Free Graph Adjacency Linked List (Seconds)",Seconds(timer));     break;
        case 3: // Adj Array List
            graphAdjArrayList = (struct GraphAdjArrayList*)graph;
            Start(timer);
            breadthFirstSearchGraphAdjArrayList(root, graphAdjArrayList);
            Stop(timer);
            generateGraphPrintMessageWithtime("Breadth First Search Total Time (Seconds)",Seconds(timer));
            Start(timer); 
            graphAdjArrayListFree(graphAdjArrayList);
            Stop(timer);
            generateGraphPrintMessageWithtime("Free Graph Adjacency Array List (Seconds)",Seconds(timer));
          break;
        case 4: // CSR with no frontier only Bitmaps
            graphCSR = (struct GraphCSR*)graph;
            Start(timer);
            breadthFirstSearchUsingBitmapsGraphCSR(root, graphCSR);
            Stop(timer);
            generateGraphPrintMessageWithtime("Breadth First Search Total Time (Seconds)",Seconds(timer));
            graphCSRFree(graphCSR);
          break;
        default:// CSR
            graphCSR = (struct GraphCSR*)graph;
            Start(timer);
            breadthFirstSearchGraphCSR(root, graphCSR);
            Stop(timer);
            generateGraphPrintMessageWithtime("Breadth First Search Total Time (Seconds)",Seconds(timer));
            graphCSRFree(graphCSR);
          break;          
      }

     free(timer);

}