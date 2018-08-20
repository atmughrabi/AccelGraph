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
            generateGraphPrintMessageWithtime("GraphCSR Preprocessing Step Time (Seconds)",Seconds(timer));
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


void runGraphAlgorithms(void *graph, int datastructure,int algorithm, int root){

  switch (algorithm)
      {
        case 0: // bfs filename root 
          runBreadthFirstSearchAlgorithm(graph,datastructure, root);
          break;
        case 1: // pagerank filename
          printf(" pagerank to be implemented \n");
          break;
        case 2: // SSSP file name root
           printf(" SSSP to be implemented \n");
          break;
        default:// bfs file name root
          runBreadthFirstSearchAlgorithm(graph,datastructure, root);
          break;          
      }

}


void runBreadthFirstSearchAlgorithm(void *graph, int datastructure, int root){

    struct Timer* timer = (struct Timer*) malloc(sizeof(struct Timer));
    struct GraphCSR* graphCSR = NULL;
    struct GraphGrid* graphGrid = NULL;
    struct GraphAdjLinkedList* graphAdjLinkedList = NULL;
    struct GraphAdjArrayList* graphAdjArrayList = NULL;

    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting Breadth First Search (SOURCE NODE) ");
    printf(" -----------------------------------------------------\n");
    printf("| %-51u | \n", root);
    printf(" -----------------------------------------------------\n");

    switch (datastructure)
      { 
        case 0: // CSR
            graphCSR = (struct GraphCSR*)graph;
            Start(timer);
            breadthFirstSearchGraphCSR(root, graphCSR);
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