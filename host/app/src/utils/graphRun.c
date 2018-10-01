#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include "graphCSR.h"
#include "graphAdjLinkedList.h"
#include "graphAdjArrayList.h"
#include "graphGrid.h"

#include "mt19937.h"
#include "graphConfig.h"
#include "timer.h"
#include "graphRun.h"

#include "BFS.h"
#include "pageRank.h"


void generateGraphPrintMessageWithtime(const char * msg, double time){

    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", msg);
    printf(" -----------------------------------------------------\n");
    printf("| %-51f | \n", time);
    printf(" -----------------------------------------------------\n");

}



void * generateGraphDataStructure(const char *fnameb, int datastructure, int sort){

    struct Timer* timer = (struct Timer*) malloc(sizeof(struct Timer));
    void *graph = NULL;

    printf("*-----------------------------------------------------*\n");
    printf("| %-20s %-30u | \n", "Number of Threads :",numThreads);
    printf(" -----------------------------------------------------\n");

    switch (datastructure)
      { 
        case 0: // CSR
            Start(timer);
            graph = (void *)graphCSRPreProcessingStep (fnameb, sort);
            Stop(timer);
            generateGraphPrintMessageWithtime("GraphCSR Preprocessing Step Time (Seconds)",Seconds(timer));
          break;
        case 1: // Grid
            Start(timer);
            graph = (void *)graphGridPreProcessingStep (fnameb, sort);
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
            graph = (void *)graphAdjArrayListPreProcessingStep (fnameb, sort);
            Stop(timer);
            generateGraphPrintMessageWithtime("GraphAdjArrayList Preprocessing Step Time (Seconds)",Seconds(timer));
          break;
        case 4: // CSR
            Start(timer);
            graph = (void *)graphCSRPreProcessingStep (fnameb, sort);
            Stop(timer);
            generateGraphPrintMessageWithtime("GraphCSR Preprocessing Step Time (Seconds)",Seconds(timer));
          break;
        case 5: // Grid
            Start(timer);
            graph = (void *)graphGridPreProcessingStep (fnameb, sort);
            Stop(timer);
            generateGraphPrintMessageWithtime("GraphGrid Preprocessing Step Time (Seconds)",Seconds(timer));
          break;
        default:// CSR
            Start(timer);
            graph = (void *)graphCSRPreProcessingStep (fnameb, sort);
            Stop(timer);
            generateGraphPrintMessageWithtime("GraphCSR Preprocessing Step Time (Seconds)",Seconds(timer));
       
          break;          
      }


     free(timer);
     return graph;

}


void runGraphAlgorithms(void *graph, int datastructure,int algorithm, int root, int iterations, double epsilon, int trials, int pushpull){

  switch (algorithm)
      {
        case 0: // bfs filename root 
          runBreadthFirstSearchAlgorithm(graph, datastructure, root, iterations);
          break;
        case 1: // pagerank filename
          runPageRankAlgorithm(graph, datastructure, epsilon, trials, iterations);
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

    switch (datastructure)
      { 
        case 0: // CSR
            graphCSR = (struct GraphCSR*)graph;
            if(root >= 0 && root <= graphCSR->num_vertices){
              breadthFirstSearchGraphCSR(root, graphCSR);
            } 
            while(iterations){
              while(1){
                root = genrand_int32();
                  if(root < graphCSR->num_vertices){
                    if(graphCSR->vertices[root].out_degree > 0)
                     break;
                  }
              }
              if(root >= 0 && root <= graphCSR->num_vertices){
                breadthFirstSearchGraphCSR(root, graphCSR);
              }   
               iterations--;
            }
            graphCSRFree(graphCSR);
          break;

        case 1: // Grid
            graphGrid = (struct GraphGrid*)graph;
            if(root >= 0 && root <= graphGrid->num_vertices){
              breadthFirstSearchGraphGrid(root, graphGrid);
            } 
            while(iterations){
              while(1){
                root = genrand_int32();
                  if(root < graphGrid->num_vertices){
                    if(graphGrid->grid->out_degree[root] > 0)
                     break;
                  }
              }
              if(root >= 0 && root <= graphGrid->num_vertices){
                breadthFirstSearchGraphGrid(root, graphGrid);
              }   
               iterations--;
            }
            Start(timer); 
            graphGridFree(graphGrid);
            Stop(timer);
            generateGraphPrintMessageWithtime("Free Graph Grid (Seconds)",Seconds(timer));
          break;

        case 2: // Adj Linked List
            graphAdjLinkedList = (struct GraphAdjLinkedList*)graph;
              if(root >= 0 && root <= graphAdjLinkedList->num_vertices){
              breadthFirstSearchGraphAdjLinkedList(root, graphAdjLinkedList);
            } 
            while(iterations){
              while(1){
                root = genrand_int32();
                  if(root < graphAdjLinkedList->num_vertices){
                    if(graphAdjLinkedList->vertices[root].out_degree > 0)
                     break;
                  }
              }
              if(root >= 0 && root <= graphAdjLinkedList->num_vertices){
                breadthFirstSearchGraphAdjLinkedList(root, graphAdjLinkedList);
              }   
               iterations--;
            }
            Start(timer); 
            graphAdjLinkedListFree(graphAdjLinkedList);
            Stop(timer);
            generateGraphPrintMessageWithtime("Free Graph Adjacency Linked List (Seconds)",Seconds(timer));   
            break;

        case 3: // Adj Array List
            graphAdjArrayList = (struct GraphAdjArrayList*)graph;
            if(root >= 0 && root <= graphAdjArrayList->num_vertices){
              breadthFirstSearchGraphAdjArrayList(root, graphAdjArrayList);
            } 
            while(iterations){
              while(1){
                root = genrand_int32();
                  if(root < graphAdjArrayList->num_vertices){
                    if(graphAdjArrayList->vertices[root].out_degree > 0)
                     break;
                  }
              }
              if(root >= 0 && root <= graphAdjArrayList->num_vertices){
                breadthFirstSearchGraphAdjArrayList(root, graphAdjArrayList);
              }   
               iterations--;
            }
            Start(timer); 
            graphAdjArrayListFree(graphAdjArrayList);
            Stop(timer);
            generateGraphPrintMessageWithtime("Free Graph Adjacency Array List (Seconds)",Seconds(timer));
          break;

        case 4: // CSR with no frontier only Bitmaps
            graphCSR = (struct GraphCSR*)graph;
            if(root >= 0 && root <= graphCSR->num_vertices){
              breadthFirstSearchUsingBitmapsGraphCSR(root, graphCSR);
            } 
            while(iterations){
              while(1){
                root = genrand_int32();
                  if(root < graphCSR->num_vertices){
                    if(graphCSR->vertices[root].out_degree > 0)
                     break;
                  }
              }
              if(root >= 0 && root <= graphCSR->num_vertices){
                breadthFirstSearchUsingBitmapsGraphCSR(root, graphCSR);
              }   
               iterations--;
            }
            graphCSRFree(graphCSR);
          break;

         case 5: // Grid with no frontiers only Bitmaps
            graphGrid = (struct GraphGrid*)graph;
            if(root >= 0 && root <= graphGrid->num_vertices){
              breadthFirstSearchGraphGridBitmap(root, graphGrid);
            } 
            while(iterations){
              while(1){
                root = genrand_int32();
                  if(root < graphGrid->num_vertices){
                    if(graphGrid->grid->out_degree[root] > 0)
                     break;
                  }
              }
              if(root >= 0 && root <= graphGrid->num_vertices){
                breadthFirstSearchGraphGridBitmap(root, graphGrid);
              }   
               iterations--;
            }
            Start(timer); 
            graphGridFree(graphGrid);
            Stop(timer);
            generateGraphPrintMessageWithtime("Free Graph Grid (Seconds)",Seconds(timer));
          break;

          

        default:// CSR
            graphCSR = (struct GraphCSR*)graph;
            if(root >= 0 && root <= graphCSR->num_vertices){
              breadthFirstSearchGraphCSR(root, graphCSR);
            } 
            while(iterations){
              while(1){
                root = genrand_int32();
                  if(root < graphCSR->num_vertices){
                    if(graphCSR->vertices[root].out_degree > 0)
                     break;
                  }
              }
              if(root >= 0 && root <= graphCSR->num_vertices){
                breadthFirstSearchGraphCSR(root, graphCSR);
              }   
               iterations--;
            }
            graphCSRFree(graphCSR);
          break;          
      }

     free(timer);

}


void runPageRankAlgorithm(void *graph, int datastructure, double epsilon, int trials, int iterations){

    struct Timer* timer = (struct Timer*) malloc(sizeof(struct Timer));
    struct GraphCSR* graphCSR = NULL;
    struct GraphGrid* graphGrid = NULL;
    struct GraphAdjLinkedList* graphAdjLinkedList = NULL;
    struct GraphAdjArrayList* graphAdjArrayList = NULL;

            
    switch (datastructure)
      { 
        case 0: // CSR
            graphCSR = (struct GraphCSR*)graph;
            pageRankPullGraphCSR(epsilon , trials, graphCSR);
            graphCSRFree(graphCSR);
          break;

        case 1: // Grid
            graphGrid = (struct GraphGrid*)graph;
         
            Start(timer); 
            graphGridFree(graphGrid);
            Stop(timer);
            generateGraphPrintMessageWithtime("Free Graph Grid (Seconds)",Seconds(timer));
          break;

        case 2: // Adj Linked List
            graphAdjLinkedList = (struct GraphAdjLinkedList*)graph;
            
            Start(timer); 
            graphAdjLinkedListFree(graphAdjLinkedList);
            Stop(timer);
            generateGraphPrintMessageWithtime("Free Graph Adjacency Linked List (Seconds)",Seconds(timer));   
            break;

        case 3: // Adj Array List
            graphAdjArrayList = (struct GraphAdjArrayList*)graph;
          
            Start(timer); 
            graphAdjArrayListFree(graphAdjArrayList);
            Stop(timer);
            generateGraphPrintMessageWithtime("Free Graph Adjacency Array List (Seconds)",Seconds(timer));
          break;

        case 4: // CSR with no frontier only Bitmaps
            graphCSR = (struct GraphCSR*)graph;
          
            graphCSRFree(graphCSR);
          break;
          
        default:// CSR
            graphCSR = (struct GraphCSR*)graph;
           
            graphCSRFree(graphCSR);
          break;          
      }

     free(timer);

}