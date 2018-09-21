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
#include <linux/types.h>
#include <omp.h>

#include "edgeList.h"
#include "progressbar.h"
#include "myMalloc.h"
#include "graphConfig.h"

__u32 maxTwoIntegers(__u32 num1, __u32 num2){

        if(num1 >= num2)
                return num1;
        else
                return num2;

}


// read edge file to edge_array in memory
struct EdgeList* newEdgeList( __u32 num_edges){

        // struct EdgeList* newEdgeList = (struct EdgeList*) aligned_alloc(CACHELINE_BYTES, sizeof(struct EdgeList));
        #if ALIGNED
                struct EdgeList* newEdgeList = (struct EdgeList*) my_aligned_malloc(sizeof(struct EdgeList));
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
        #if ALIGNED
                struct Edge* edges_array = (struct Edge*) my_aligned_malloc( num_edges * sizeof(struct Edge));
        #else
                struct Edge* edges_array = (struct Edge*) my_malloc( num_edges * sizeof(struct Edge));
        #endif

        __u32 i;

        for(i = 0; i < num_edges; i++){

                edges_array[i].dest = 0;
                edges_array[i].src = 0;  
                
                #if WEIGHTED
                    edges_array[i].weight = 0;
                #endif
        }

        return edges_array;

}

void freeEdgeArray(struct Edge* edges_array){

        free(edges_array);

}


char * readEdgeListstxt(const char * fname){

        FILE *pText, *pBinary;
        __u32 size = 0, i;
        __u32 src = 0, dest = 0;

        #if WEIGHTED
                __u32 weight = 1;
        #endif

        char * fname_txt = (char *) malloc((strlen(fname)+5)*sizeof(char));
        char * fname_bin = (char *) malloc((strlen(fname)+5)*sizeof(char));

        
        fname_txt = strcpy (fname_txt, fname);
        fname_bin = strcat (fname_txt, ".bin");

        // printf("Filename : %s \n",fname);
        // printf("Filename : %s \n",fname_bin);


        pText = fopen(fname, "r");
        pBinary = fopen(fname_bin, "wb");



        if (pText == NULL) {
                err(1, "open: %s", fname);
                return NULL;
        }
         if (pBinary == NULL) {
                err(1, "open: %s", fname_bin);
                return NULL;
        }


        while (1)
        {
        size++;
        i = fscanf(pText, "%u\t%u\n", &src, &dest);

        // printf(" %lu -> %lu \n", src,dest);

        fwrite(&src, sizeof (src), 1, pBinary);
        fwrite(&dest, sizeof (dest), 1, pBinary);

        #if WEIGHTED
                fwrite(&weight, sizeof (weight), 1, pBinary);
        #endif

        // if( size == 150000000 ) 
        //      break;

        if( i == EOF ) 
           break;
        }

      
        fclose(pText);
        fclose(pBinary);


        return fname_bin;


}

struct EdgeList* readEdgeListsbin(const char * fname, __u8 inverse){


        int fd = open(fname, O_RDONLY);
        struct stat fs;
        char *buf_addr;
        __u32  *buf_pointer;
        __u32  src=0 ,dest=0;
 
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

        #if WEIGHTED
         __u32 offset = 3;
        #else
         __u32 offset = 2; 
        #endif

        __u32 num_edges = (__u64)fs.st_size/((offset)*sizeof(__u32));

        #if DIRECTED                                    
                    struct EdgeList* edgeList = newEdgeList(num_edges-1);
        #else
                    if(inverse){
                        struct EdgeList* edgeList = newEdgeList((num_edges-1)*2);
                    }else{
                        struct EdgeList* edgeList = newEdgeList(num_edges-1);
                    }
        #endif
        
        __u32 i;
        __u32 num_vertices = 0;

        // #pragma omp parallel for reduction(max:num_vertices) 
        for(i = 0; i < num_edges-1; i++){

                src = buf_pointer[((offset)*i)+0];
                dest = buf_pointer[((offset)*i)+1];

                #if DIRECTED

                if(!inverse){
                    
                    edgeList->edges_array[i].src = src;
                    edgeList->edges_array[i].dest = dest;

                }else{

                    edgeList->edges_array[i].src = dest;
                    edgeList->edges_array[i].dest = src;
                }
                       

                #else
                        if(inverse){
                            edgeList->edges_array[i].src = src;
                            edgeList->edges_array[i].dest = dest;
                            edgeList->edges_array[i+(num_edges-1)].src = dest;
                            edgeList->edges_array[i+(num_edges-1)].dest = src;
                        }else{
                            edgeList->edges_array[i].src = src;
                            edgeList->edges_array[i].dest = dest;
                        }
                #endif
                
                num_vertices = maxTwoIntegers(num_vertices,maxTwoIntegers(edgeList->edges_array[i].src, edgeList->edges_array[i].dest));
               
                 #if WEIGHTED
                        edgeList->edges_array[i].weight = buf_pointer[((offset)*i)+2];
                 #endif
        }

        edgeList->num_vertices = num_vertices+1; // max number of veritices Array[0-max]

        // printf("DONE Reading EdgeList from file %s \n", fname);
        // edgeListPrint(edgeList);

        munmap(buf_addr, fs.st_size);
        close(fd);

        return edgeList;
}

void edgeListPrint(struct EdgeList* edgeList){

        
        printf("number of vertices (V) : %u \n", edgeList->num_vertices);
        printf("number of edges    (E) : %u \n", edgeList->num_edges);   

        __u32 i;
        for(i = 0; i < edgeList->num_edges; i++){

                #if WEIGHTED
                        printf("%u -> %u w: %d \n", edgeList->edges_array[i].src, edgeList->edges_array[i].dest, edgeList->edges_array[i].weight);   
                #else
                        printf("%u -> %u \n", edgeList->edges_array[i].src, edgeList->edges_array[i].dest);   
                #endif
        }

}