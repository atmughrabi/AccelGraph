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


int maxTwoIntegers(int num1, int num2){

        if(num1 >= num2)
                return num1;
        else
                return num2;

}

// read edge file to edge_array in memory
struct EdgeList* newEdgeList( int num_edges){

        struct EdgeList* newEdgeList = (struct EdgeList*) aligned_alloc(CACHELINE_BYTES, sizeof(struct EdgeList));

        newEdgeList->num_edges = num_edges;
        newEdgeList->num_vertices = 0;

        newEdgeList->edges_array = (struct Edge*) aligned_alloc(CACHELINE_BYTES, num_edges * sizeof(struct Edge));

        int i;

        for(i = 0; i < newEdgeList->num_edges; i++){

                newEdgeList->edges_array[i].dest = 0;
                newEdgeList->edges_array[i].src = 0;  
                newEdgeList->edges_array[i].weight = 0;
       
        }

       
        return newEdgeList;

}

struct EdgeList* readEdgeListstxt(const char * fname)
{

        FILE *pText, *pBinary;
        int size = 0, i;
        int src = 0, dest = 0, weight = 1;

        char * fname_txt = (char *) malloc(strlen(fname)*sizeof(char));
        char * fname_bin;

        

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


        while (1)
        {
        size++;
        i = fscanf(pText, "%d\t%d\n", &src, &dest);

        // printf(" %d -> %d \n", src,dest);

        fwrite(&src, sizeof (src), 1, pBinary);
        fwrite(&dest, sizeof (dest), 1, pBinary);
        fwrite(&weight, sizeof (weight), 1, pBinary);

        if( i == EOF ) 
           break;
        }

      
        fclose(pText);
        fclose(pBinary);

        struct EdgeList* edgeList = readEdgeListsbin(fname_bin);

        return edgeList;

}

struct EdgeList* readEdgeListsbin(const char * fname )
{
        

        int fd = open(fname, O_RDONLY);
        struct stat fs;
        char *buf_addr;
        int  *buf_pointer;
 
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

        // printf("#Size: %llu\n", (__u64)fs.st_size/(3*sizeof(int)));
        buf_pointer = (int *) buf_addr;
        int num_edges = (__u32)fs.st_size/(3*sizeof(int));

        // printf("%d -> %d w: %d \n", buf_pointer[0], buf_pointer[1], buf_pointer[2]);   

        struct EdgeList* edgeList = newEdgeList(num_edges-1);

        int i;
        for(i = 0; i < edgeList->num_edges; i++){
                
                edgeList->edges_array[i].src = buf_pointer[(3*i)+0];
                edgeList->edges_array[i].dest = buf_pointer[(3*i)+1];
                edgeList->num_vertices = maxTwoIntegers(edgeList->num_vertices,maxTwoIntegers(edgeList->edges_array[i].src, edgeList->edges_array[i].dest));
                edgeList->edges_array[i].weight = buf_pointer[(3*i)+2];
             
        }


        munmap(buf_addr, fs.st_size);
        close(fd);

        return edgeList;
}

void edgeListPrint(struct EdgeList* edgeList){

        int i;
        printf("number of vertices (V) : %d \n", edgeList->num_vertices);
        printf("number of edges    (E) : %d \n", edgeList->num_edges);   

        // for(i = 0; i < edgeList->num_edges; i++){

        //          printf("%d -> %d w: %d \n", edgeList->edges_array[i].src, edgeList->edges_array[i].dest, edgeList->edges_array[i].weight);   

        // }


}