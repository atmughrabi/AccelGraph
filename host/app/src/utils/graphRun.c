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



void * generateGraphDataStructure(const char *fnameb, __u32 datastructure, __u32 sort){

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


void runGraphAlgorithms(void *graph, __u32 datastructure, __u32 algorithm, int root, __u32 iterations, double epsilon, __u32 trials, __u32 pushpull){

  switch (algorithm)
      {
        case 0: // bfs filename root 
          runBreadthFirstSearchAlgorithm(graph, datastructure, root, trials);
          break;
        case 1: // pagerank filename
          runPageRankAlgorithm(graph, datastructure, epsilon, iterations, trials, pushpull);
          break;
        case 2: // SSSP file name root
          printf(" SSSP to be implemented \n");
          break;
        default:// bfs file name root
          runBreadthFirstSearchAlgorithm(graph,datastructure, root, trials);
          break;          
      }

}



void runBreadthFirstSearchAlgorithm(void *graph, __u32 datastructure, int root, __u32 trials){

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
            while(trials){
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
               trials--;
            }
            Start(timer);
            graphCSRFree(graphCSR);
            Stop(timer);
            generateGraphPrintMessageWithtime("Free Graph CSR (Seconds)",Seconds(timer));
          break;

        case 1: // Grid
            graphGrid = (struct GraphGrid*)graph;
            if(root >= 0 && root <= graphGrid->num_vertices){
              breadthFirstSearchGraphGrid(root, graphGrid);
            } 
            while(trials){
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
               trials--;
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
            while(trials){
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
               trials--;
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
            while(trials){
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
               trials--;
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
            while(trials){
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
               trials--;
            }
            Start(timer);
            graphCSRFree(graphCSR);
            Stop(timer);
            generateGraphPrintMessageWithtime("Free Graph CSR (Seconds)",Seconds(timer));
          break;

         case 5: // Grid with no frontiers only Bitmaps
            graphGrid = (struct GraphGrid*)graph;
            if(root >= 0 && root <= graphGrid->num_vertices){
              breadthFirstSearchGraphGridBitmap(root, graphGrid);
            } 
            while(trials){
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
               trials--;
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
            while(trials){
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
               trials--;
            }
            Start(timer);
            graphCSRFree(graphCSR);
            Stop(timer);
            generateGraphPrintMessageWithtime("Free Graph CSR (Seconds)",Seconds(timer));
          break;          
      }

     free(timer);

}


void runPageRankAlgorithm(void *graph, __u32 datastructure, double epsilon, __u32 iterations, __u32 trials, __u32 pushpull){

    struct Timer* timer = (struct Timer*) malloc(sizeof(struct Timer));
    struct GraphCSR* graphCSR = NULL;
    struct GraphGrid* graphGrid = NULL;
    struct GraphAdjLinkedList* graphAdjLinkedList = NULL;
    struct GraphAdjArrayList* graphAdjArrayList = NULL;

            
    switch (datastructure)
      { 
        case 0: // CSR
            graphCSR = (struct GraphCSR*)graph;
            pageRankGraphCSR(epsilon , iterations, pushpull, graphCSR);
            Start(timer);
            graphCSRFree(graphCSR);
            Stop(timer);
            generateGraphPrintMessageWithtime("Free Graph CSR (Seconds)",Seconds(timer));
          break;

        case 1: // Grid
            graphGrid = (struct GraphGrid*)graph;
            pageRankGraphGrid(epsilon , iterations, pushpull, graphGrid);
            Start(timer); 
            graphGridFree(graphGrid);
            Stop(timer);
            generateGraphPrintMessageWithtime("Free Graph Grid (Seconds)",Seconds(timer));
          break;

        case 2: // Adj Linked List
            graphAdjLinkedList = (struct GraphAdjLinkedList*)graph;
            pageRankGraphAdjLinkedList(epsilon , iterations, pushpull, graphAdjLinkedList);
            Start(timer); 
            graphAdjLinkedListFree(graphAdjLinkedList);
            Stop(timer);
            generateGraphPrintMessageWithtime("Free Graph Adjacency Linked List (Seconds)",Seconds(timer));   
            break;

        case 3: // Adj Array List
            graphAdjArrayList = (struct GraphAdjArrayList*)graph;
            
            pageRankGraphAdjArrayList(epsilon , iterations, pushpull, graphAdjArrayList);

            Start(timer); 
            graphAdjArrayListFree(graphAdjArrayList);
            Stop(timer);
            generateGraphPrintMessageWithtime("Free Graph Adjacency Array List (Seconds)",Seconds(timer));
          break;
          
        default:// CSR
            graphCSR = (struct GraphCSR*)graph;
            pageRankGraphCSR(epsilon , iterations, pushpull, graphCSR);
            Start(timer);
            graphCSRFree(graphCSR);
            Stop(timer);
            generateGraphPrintMessageWithtime("Free Graph CSR (Seconds)",Seconds(timer));
          break;          
      }

     free(timer);

}