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


#include "mt19937.h"
#include "edgeList.h"
#include "myMalloc.h"
#include "graphConfig.h"

__u32 maxTwoIntegers(__u32 num1, __u32 num2)
{

    if(num1 >= num2)
        return num1;
    else
        return num2;

}


// read edge file to edge_array in memory
struct EdgeList *newEdgeList( __u32 num_edges)
{


    struct EdgeList *newEdgeList = (struct EdgeList *) my_malloc(sizeof(struct EdgeList));
    newEdgeList->edges_array_src = (__u32 *) my_malloc(num_edges * sizeof(__u32));
    newEdgeList->edges_array_dest = (__u32 *) my_malloc(num_edges * sizeof(__u32));

#if WEIGHTED
    newEdgeList->edges_array_weight = (__u32 *) my_malloc(num_edges * sizeof(__u32));
#endif

    __u32 i;
    #pragma omp parallel for
    for(i = 0; i < num_edges; i++)
    {
        newEdgeList->edges_array_dest[i] = 0;
        newEdgeList->edges_array_src[i] = 0;
#if WEIGHTED
        newEdgeList->edges_array_weight[i] = 0;
#endif
    }

    newEdgeList->num_edges = num_edges;
    newEdgeList->num_vertices = 0;
    // newEdgeList->edges_array = newEdgeList(num_edges);

#if WEIGHTED
    newEdgeList->max_weight = 0;
#endif

    return newEdgeList;

}

void freeEdgeList( struct EdgeList *edgeList)
{

    if(edgeList)
    {
        // freeEdgeArray(edgeList->edges_array);
        if(edgeList->edges_array_src)
            free(edgeList->edges_array_src);
        if(edgeList->edges_array_dest)
            free(edgeList->edges_array_dest);

#if WEIGHTED
        if(edgeList->edges_array_weight)
            free(edgeList->edges_array_weight);
#endif

        free(edgeList);
    }


}



// struct Edge* newEdgeList(__u32 num_edges){

//         // struct Edge* edges_array = (struct Edge*) aligned_alloc(CACHELINE_BYTES, num_edges * sizeof(struct Edge));
//         struct Edge* edges_array = (struct Edge*) my_malloc( num_edges * sizeof(struct Edge));

//         __u32 i;

//         for(i = 0; i < num_edges; i++){

//                 edges_array[i].dest = 0;
//                 edges_array[i].src = 0;

//                 #if WEIGHTED
//                     edges_array[i].weight = 0;
//                 #endif
//         }

//         return edges_array;

// }

// void freeEdgeArray(struct Edge* edges_array){

//         if(edges_array)
//             free(edges_array);
//         // printf("edges_array freed \n");

// }


char *readEdgeListstxt(const char *fname, __u32 weighted)
{

    FILE *pText, *pBinary;
    __u32 size = 0, i;
    __u32 src = 0, dest = 0;

#if WEIGHTED
    __u32 weight = 1;
#endif

    char *fname_txt = (char *) malloc((strlen(fname) + 10) * sizeof(char));
    char *fname_bin = (char *) malloc((strlen(fname) + 10) * sizeof(char));

    fname_txt = strcpy (fname_txt, fname);

#if WEIGHTED
    fname_bin = strcat (fname_txt, ".wbin");
#else
    fname_bin = strcat (fname_txt, ".bin");
#endif



    // printf("Filename : %s \n",fname);
    // printf("Filename : %s \n",fname_bin);


    pText = fopen(fname, "r");
    pBinary = fopen(fname_bin, "wb");



    if (pText == NULL)
    {
        err(1, "open: %s", fname);
        return NULL;
    }
    if (pBinary == NULL)
    {
        err(1, "open: %s", fname_bin);
        return NULL;
    }

    // char type;
    // __u32 time =0;
    //  char * buffer = (char *) malloc(200*sizeof(char));

    while (1)
    {

        // if(size > 48){
#if WEIGHTED
        if(weighted)
        {
            i = fscanf(pText, "%u\t%u\n", &src, &dest);
            weight = (generateRandInt(mt19937var) % 256) + 1;
        }
        else
        {
            i = fscanf(pText, "%u\t%u\t%u\n", &src, &dest, &weight);
            // printf("%c\t%u\t%u\t%u\n",type, src, dest, weight);
        }
#else
        i = fscanf(pText, "%u\t%u\n", &src, &dest);
#endif

        if( i == EOF )
            break;


        fwrite(&src, sizeof (src), 1, pBinary);
        fwrite(&dest, sizeof (dest), 1, pBinary);

#if WEIGHTED
        fwrite(&weight, sizeof (weight), 1, pBinary);

#endif
        // }
        // else{
        //     i = fscanf(pText, "%[^\n]",buffer);
        //     fgetc(pText);
        //     // printf("%s\n",buffer);
        // }
        size++;
        // if( size == 70 )
        //      break;



    }


    fclose(pText);
    fclose(pBinary);


    return fname_bin;


}

struct EdgeList *readEdgeListsbin(const char *fname, __u8 inverse, __u32 symmetric, __u32 weighted)
{


    int fd = open(fname, O_RDONLY);
    struct stat fs;
    char *buf_addr;
    __u32  *buf_pointer;
    __u32  src = 0, dest = 0;
    __u32 offset;

    if (fd == -1)
    {
        err(1, "open: %s", fname);
        return 0;
    }

    if (fstat(fd, &fs) == -1)
    {
        err(1, "stat: %s", fname);
        return 0;
    }

    /* fs.st_size could have been 0 actually */
    buf_addr = mmap(0, fs.st_size, PROT_WRITE, MAP_PRIVATE, fd, 0);

    if (buf_addr == (void *) -1)
    {
        err(1, "mmap: %s", fname);
        close(fd);
        return 0;
    }


    buf_pointer = (__u32 *) buf_addr;

#if WEIGHTED
    if(weighted)
        offset = 2;
    else
        offset = 3;

#else
    offset = 2;
#endif

    __u32 num_edges = (__u64)fs.st_size / ((offset) * sizeof(__u32));
    struct EdgeList *edgeList;

#if DIRECTED
    if(symmetric)
    {
        edgeList = newEdgeList((num_edges) * 2);
    }
    else
    {
        edgeList = newEdgeList(num_edges);
    }
#else
    if(symmetric)
    {
        edgeList = newEdgeList((num_edges) * 2);
    }
    else
    {
        edgeList = newEdgeList(num_edges);
    }
#endif

    __u32 i;
    __u32 num_vertices = 0;

#if WEIGHTED
    __u32 max_weight = 0;
#endif

    // #pragma omp parallel for reduction(max:num_vertices)
    for(i = 0; i < num_edges; i++)
    {

        src = buf_pointer[((offset) * i) + 0];
        dest = buf_pointer[((offset) * i) + 1];
        // printf(" %u %lu -> %lu \n",src,dest);
#if DIRECTED

        if(!inverse)
        {

            if(symmetric)
            {
                edgeList->edges_array_src[i] = src;
                edgeList->edges_array_dest[i] = dest;
                edgeList->edges_array_src[i + (num_edges)] = dest;
                edgeList->edges_array_dest[i + (num_edges)] = src;
            }
            else
            {
                edgeList->edges_array_src[i] = src;
                edgeList->edges_array_dest[i] = dest;
            }

        }
        else
        {

            if(symmetric)
            {
                edgeList->edges_array_src[i] = dest;
                edgeList->edges_array_dest[i] = src;
                edgeList->edges_array_src[i + (num_edges)] = src;
                edgeList->edges_array_dest[i + (num_edges)] = dest;
            }
            else
            {
                edgeList->edges_array_src[i] = dest;
                edgeList->edges_array_dest[i] = src;
            }

        }

#else
        if(symmetric)
        {
            edgeList->edges_array_src[i] = src;
            edgeList->edges_array_dest[i] = dest;
            edgeList->edges_array_src[i + (num_edges)] = dest;
            edgeList->edges_array_dest[i + (num_edges)] = src;
        }
        else
        {
            edgeList->edges_array_src[i] = src;
            edgeList->edges_array_dest[i] = dest;
        }
#endif

        num_vertices = maxTwoIntegers(num_vertices, maxTwoIntegers(edgeList->edges_array_src[i], edgeList->edges_array_dest[i]));

#if WEIGHTED
        if(weighted)
        {
            // edgeList->edges_array_weightt[i] = (genrand_int32() % 255)+1;
            edgeList->edges_array_weight[i] = 1;

            if(symmetric)
            {
                edgeList->edges_array_weight[i + (num_edges)] = 1;
            }
        }
        else
        {
            edgeList->edges_array_weight[i] = buf_pointer[((offset) * i) + 2];

        }

        max_weight = maxTwoIntegers(max_weight, edgeList->edges_array_weight[i]);

#endif
    }

    edgeList->num_vertices = num_vertices + 1; // max number of veritices Array[0-max]

#if WEIGHTED
    edgeList->max_weight = max_weight;
#endif
    // printf("DONE Reading EdgeList from file %s \n", fname);
    // edgeListPrint(edgeList);

    munmap(buf_addr, fs.st_size);
    close(fd);

    return edgeList;
}

struct EdgeList *readEdgeListsMem( struct EdgeList *edgeListmem, __u8 inverse, __u32 symmetric)
{


    __u32 num_edges = edgeListmem->num_edges;
    struct EdgeList *edgeList;
#if DIRECTED
    if(symmetric)
    {
        edgeList = newEdgeList((num_edges) * 2);
    }
    else
    {
        edgeList = newEdgeList(num_edges);
    }
#else
    if(symmetric)
    {
        edgeList = newEdgeList((num_edges) * 2);
    }
    else
    {
        edgeList = newEdgeList(num_edges);
    }
#endif

    __u32 i;

    #pragma omp parallel for
    for(i = 0; i < num_edges; i++)
    {

#if DIRECTED

        if(!inverse)
        {

            if(symmetric)
            {
                edgeList->edges_array_src[i] = edgeListmem->edges_array_src[i];
                edgeList->edges_array_dest[i] = edgeListmem->edges_array_dest[i];
                edgeList->edges_array_src[i + (num_edges)] = edgeListmem->edges_array_dest[i];
                edgeList->edges_array_dest[i + (num_edges)] = edgeListmem->edges_array_src[i];
            }
            else
            {
                edgeList->edges_array_src[i] = edgeListmem->edges_array_src[i];
                edgeList->edges_array_dest[i] = edgeListmem->edges_array_dest[i];
            }

        }
        else
        {

            if(symmetric)
            {
                edgeList->edges_array_src[i] = edgeListmem->edges_array_src[i];
                edgeList->edges_array_dest[i] = edgeListmem->edges_array_dest[i];
                edgeList->edges_array_src[i + (num_edges)] = edgeListmem->edges_array_dest[i];
                edgeList->edges_array_dest[i + (num_edges)] = edgeListmem->edges_array_src[i];
            }
            else
            {
                edgeList->edges_array_src[i] = edgeListmem->edges_array_dest[i];
                edgeList->edges_array_dest[i] = edgeListmem->edges_array_src[i];
            }

        }


#else
        if(symmetric)
        {
            edgeList->edges_array_src[i] = edgeListmem->edges_array_src[i];
            edgeList->edges_array_dest[i] = edgeListmem->edges_array_dest[i];
            edgeList->edges_array_src[i + (num_edges)] = edgeListmem->edges_array_dest[i];
            edgeList->edges_array_dest[i + (num_edges)] = edgeListmem->edges_array_src[i];
        }
        else
        {
            edgeList->edges_array_src[i] = edgeListmem->edges_array_src[i];
            edgeList->edges_array_dest[i] = edgeListmem->edges_array_dest[i];
        }
#endif

#if WEIGHTED
        edgeList->edges_array_weight[i] = edgeListmem->edges_array_weight[i];
#endif
    }

    edgeList->num_vertices = edgeListmem->num_vertices; // max number of veritices Array[0-max]

#if WEIGHTED
    edgeList->max_weight =  edgeListmem->max_weight;
#endif

    return edgeList;
}

void edgeListPrint(struct EdgeList *edgeList)
{


    printf("number of vertices (V) : %u \n", edgeList->num_vertices);
    printf("number of edges    (E) : %u \n", edgeList->num_edges);

    __u32 i;
    for(i = 0; i < edgeList->num_edges; i++)
    {

#if WEIGHTED
        printf("%u -> %u w: %d \n", edgeList->edges_array_src[i], edgeList->edges_array_dest[i], edgeList->edges_array_weight[i]);
#else
        printf("%u -> %u \n", edgeList->edges_array_src[i], edgeList->edges_array_dest[i]);
#endif
    }

}