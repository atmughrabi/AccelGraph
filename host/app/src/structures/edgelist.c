#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>
#include <errno.h>
#include <err.h>
#include <string.h>

#include "edgelist.h"
#include "capienv.h"
#include "progressbar.h"
#include "mymalloc.h"
#include "graphconfig.h"

__u32 maxTwoIntegers(__u32 num1, __u32 num2){

        if(num1 >= num2)
                return num1;
        else
                return num2;

}

// read edge file to edge_array in memory
struct EdgeList* newEdgeList( __u32 num_edges){

        // struct EdgeList* newEdgeList = (struct EdgeList*) aligned_alloc(CACHELINE_BYTES, sizeof(struct EdgeList));
        #ifdef ALIGNED
                struct EdgeList* newEdgeList = (struct EdgeList*) my_aligned_alloc(sizeof(struct EdgeList));
        #else
                struct EdgeList* newEdgeList = (struct EdgeList*) my_malloc(sizeof(struct EdgeList));
        #endif


        newEdgeList->num_edges = num_edges;
        newEdgeList->num_vertices = 0;
        newEdgeList->edges_array = newEdgeArray(num_edges);

        return newEdgeList;

}

 void freeEdgeList( struct EdgeList* edgeList){

        freeEdgeArray(edgeList->edges_array);
        free(edgeList);

}



struct Edge* newEdgeArray(__u32 num_edges){

        // struct Edge* edges_array = (struct Edge*) aligned_alloc(CACHELINE_BYTES, num_edges * sizeof(struct Edge));
        #ifdef ALIGNED
                struct Edge* edges_array = (struct Edge*) my_aligned_alloc( num_edges * sizeof(struct Edge));
        #else
                struct Edge* edges_array = (struct Edge*) my_malloc( num_edges * sizeof(struct Edge));
        #endif

        __u32 i;

        for(i = 0; i < num_edges; i++){

                edges_array[i].dest = 0;
                edges_array[i].src = 0;  
                edges_array[i].weight = 0;

        }

        return edges_array;

}

void freeEdgeArray(struct Edge* edges_array){

        free(edges_array);

}


struct EdgeList* readEdgeListstxt(const char * fname){

        FILE *pText, *pBinary;
        __u32 size = 0, i;
        __u32 src = 0, dest = 0, weight = 1;

        char * fname_txt = (char *) malloc((strlen(fname)+5)*sizeof(char));
        char * fname_bin = (char *) malloc((strlen(fname)+5)*sizeof(char));

        

        fname_txt = strcpy (fname_txt, fname);
        fname_bin = strcat (fname_txt, ".bin");

        printf("Filename : %s \n",fname);
        printf("Filename : %s \n",fname_bin);


        pText = fopen(fname, "r");
        pBinary = fopen(fname_bin, "wb");



        if (pText == NULL) {
                err(1, "open: %s", fname);
                return 0;
        }
         if (pBinary == NULL) {
                err(1, "open: %s", fname_bin);
                return 0;
        }

        // int offset = (2+attr->WEIGHTED);
        // double percentage_sum = 0.0;
        // double percentage = 0.0;


        

        while (1)
        {
        size++;
        i = fscanf(pText, "%u\t%u\n", &src, &dest);

        // printf(" %lu -> %lu \n", src,dest);

        fwrite(&src, sizeof (src), 1, pBinary);
        fwrite(&dest, sizeof (dest), 1, pBinary);

        #ifdef WEIGHTED
                fwrite(&weight, sizeof (weight), 1, pBinary);
        #endif

        if( i == EOF ) 
           break;
        }

      
        fclose(pText);
        fclose(pBinary);

        // struct EdgeList* edgeList = readEdgeListsbin(fname_bin, attr);

        struct EdgeList* edgeList = NULL;

        return edgeList;

}

struct EdgeList* readEdgeListsbin(const char * fname){


        int fd = open(fname, O_RDONLY);
        struct stat fs;
        char *buf_addr;
        __u32  *buf_pointer;
 
        if (fd == -1) {
                err(1, "open: %s", fname);
                return 0;
        }
 
        if (fstat(fd, &fs) == -1) {
                err(1, "stat: %s", fname);
                return 0;
        }
 
        /* fs.st_size could have been 0 actually */
        buf_addr = mmap(0, fs.st_size, PROT_READ, MAP_PRIVATE, fd, 0);

        if (buf_addr == (void*) -1) {
                err(1, "mmap: %s", fname);
                close(fd);
                return 0;
        }


        buf_pointer = (__u32 *) buf_addr;

        #ifdef WEIGHTED
         __u32 offset = 3;
        #else
         __u32 offset = 2; 
        #endif

        __u32 num_edges = (__u64)fs.st_size/((offset)*sizeof(__u32));
        // double percentage = 0.0;
        // double percentage_sum = 0.0;

         num_edges /= 4;

        printf("START Reading EdgeList from file %s \n",fname);


        struct EdgeList* edgeList = newEdgeList(num_edges-1);

        __u32 i;
        for(i = 0; i < edgeList->num_edges; i++){

                // percentage_sum += (double)offset;
                // percentage = percentage_sum / (double)num_edges;
                // printProgress (percentage);
                
                edgeList->edges_array[i].src = buf_pointer[((offset)*i)+0];
                edgeList->edges_array[i].dest = buf_pointer[((offset)*i)+1];
                edgeList->num_vertices = maxTwoIntegers(edgeList->num_vertices,maxTwoIntegers(edgeList->edges_array[i].src, edgeList->edges_array[i].dest));
               
                 #ifdef WEIGHTED
                        edgeList->edges_array[i].weight = buf_pointer[((offset)*i)+2];
                 #endif
             
        }

        printf("DONE Reading EdgeList from file %s \n", fname);
        edgeListPrint(edgeList);

        munmap(buf_addr, fs.st_size);
        close(fd);

        return edgeList;
}

void edgeListPrint(struct EdgeList* edgeList){

        
        printf("number of vertices (V) : %u \n", edgeList->num_vertices);
        printf("number of edges    (E) : %u \n", edgeList->num_edges);   

        // int i;
        // for(i = 0; i < edgeList->num_edges; i++){

        //          printf("%d -> %d w: %d \n", edgeList->edges_array[i].src, edgeList->edges_array[i].dest, edgeList->edges_array[i].weight);   

        // }


}