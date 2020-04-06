// -----------------------------------------------------------------------------
//
//      "00_AccelGraph"
//
// -----------------------------------------------------------------------------
// Copyright (c) 2014-2019 All rights reserved
// -----------------------------------------------------------------------------
// Author : Abdullah Mughrabi/http://www.martinbroadhurst.com/levenshtein-distance-in-c.html
// Email  : atmughra@ncsu.edu||atmughrabi@gmail.com
// File   : graphStats.c
// Create : 2019-06-21 17:15:17
// Revise : 2019-09-28 15:37:12
// Editor : Abdullah Mughrabi
// -----------------------------------------------------------------------------
#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <argp.h>
#include <stdbool.h>
#include <omp.h>
#include <string.h>
#include <math.h>
#include <stdint.h>
#include <assert.h>

#include "timer.h"
#include "myMalloc.h"
#include "graphConfig.h"
#include "graphCSR.h"
#include "pageRank.h"
#include "graphStats.h"



static int min3(int a, int b, int c)
{
    if (a < b && a < c)
    {
        return a;
    }
    if (b < a && b < c)
    {
        return b;
    }
    return c;
}

static uint32_t levenshtein_matrix_calculate(edit **mat, const uint32_t *array1, uint32_t len1,
        const uint32_t *array2, uint32_t len2)
{
    uint32_t i, j;
    for (j = 1; j <= len2; j++)
    {
        for (i = 1; i <= len1; i++)
        {
            uint32_t substitution_cost;
            uint32_t del = 0, ins = 0, subst = 0;
            uint32_t best;
            if (array1[i - 1] == array2[j - 1])
            {
                substitution_cost = 0;
            }
            else
            {
                substitution_cost = 1;
            }
            del = mat[i - 1][j].score + 1; /* deletion */
            ins = mat[i][j - 1].score + 1; /* insertion */
            subst = mat[i - 1][j - 1].score + substitution_cost; /* substitution */
            best = min3(del, ins, subst);
            mat[i][j].score = best;
            mat[i][j].arg1 = array1[i - 1];
            mat[i][j].arg2 = array2[j - 1];
            mat[i][j].pos = i - 1;
            if (best == del)
            {
                mat[i][j].type = DELETION;
                mat[i][j].prev = &mat[i - 1][j];
            }
            else if (best == ins)
            {
                mat[i][j].type = INSERTION;
                mat[i][j].prev = &mat[i][j - 1];
            }
            else
            {
                if (substitution_cost > 0)
                {
                    mat[i][j].type = SUBSTITUTION;
                }
                else
                {
                    mat[i][j].type = NONE;
                }
                mat[i][j].prev = &mat[i - 1][j - 1];
            }
        }
    }
    return mat[len1][len2].score;
}

static edit **levenshtein_matrix_create(const uint32_t *array1, uint32_t len1, const uint32_t *array2,
                                        uint32_t len2)
{
    uint32_t i, j;
    edit **mat = malloc((len1 + 1) * sizeof(edit *));
    if (mat == NULL)
    {
        return NULL;
    }
    for (i = 0; i <= len1; i++)
    {
        mat[i] = malloc((len2 + 1) * sizeof(edit));
        if (mat[i] == NULL)
        {
            for (j = 0; j < i; j++)
            {
                free(mat[j]);
            }
            free(mat);
            return NULL;
        }
    }
    for (i = 0; i <= len1; i++)
    {
        mat[i][0].score = i;
        mat[i][0].prev = NULL;
        mat[i][0].arg1 = 0;
        mat[i][0].arg2 = 0;
    }

    for (j = 0; j <= len2; j++)
    {
        mat[0][j].score = j;
        mat[0][j].prev = NULL;
        mat[0][j].arg1 = 0;
        mat[0][j].arg2 = 0;
    }
    return mat;
}

uint32_t levenshtein_distance(const uint32_t *array1, const uint32_t len1, const uint32_t *array2, const uint32_t len2, edit **script)
{
    uint32_t i, distance;
    edit **mat, *head;

    /* If either string is empty, the distance is the other string's length */
    if (len1 == 0)
    {
        return len2;
    }
    if (len2 == 0)
    {
        return len1;
    }
    /* Initialise the matrix */
    mat = levenshtein_matrix_create(array1, len1, array2, len2);
    if (!mat)
    {
        *script = NULL;
        return 0;
    }
    /* Main algorithm */
    distance = levenshtein_matrix_calculate(mat, array1, len1, array2, len2);
    /* Read back the edit script */
    *script = malloc(distance * sizeof(edit));
    if (*script)
    {
        i = distance - 1;
        for (head = &mat[len1][len2];
                head->prev != NULL;
                head = head->prev)
        {
            if (head->type != NONE)
            {
                memcpy(*script + i, head, sizeof(edit));
                i--;
            }
        }
    }
    else
    {
        distance = 0;
    }
    /* Clean up */
    for (i = 0; i <= len1; i++)
    {
        free(mat[i]);
    }
    free(mat);

    return distance;
}

void print(const edit *e)
{
    if (e->type == INSERTION)
    {
        printf("Insert %u", e->arg2);
    }
    else if (e->type == DELETION)
    {
        printf("Delete %u", e->arg1);
    }
    else
    {
        printf("Substitute %u for %u", e->arg2, e->arg1);
    }
    printf(" at %u\n", e->pos);
}


/*-------------------------------------------------------------------------*/
/* Sorts in place, returns the bubble sort distance between the input array
 * and the sorted array.
 */

static int insertionSort(float *arr, int len)
{
    int maxJ, i, j, swapCount = 0;

    /* printf("enter insertionSort len=%d\n",len) ; */

    if(len < 2)
    {
        return 0;
    }

    maxJ = len - 1;
    for(i = len - 2; i >= 0; --i)
    {
        float  val = arr[i];
        for(j = i; j < maxJ && arr[j + 1] < val; ++j)
        {
            arr[j] = arr[j + 1];
        }

        arr[j] = val;
        swapCount += (j - i);
    }

    return swapCount;
}

/*-------------------------------------------------------------------------*/

static int merge(float *from, float *to, int middle, int len)
{
    int bufIndex, leftLen, rightLen, swaps ;
    float *left, *right;

    /* printf("enter merge\n") ; */

    bufIndex = 0;
    swaps = 0;

    left = from;
    right = from + middle;
    rightLen = len - middle;
    leftLen = middle;

    while(leftLen && rightLen)
    {
        if(right[0] < left[0])
        {
            to[bufIndex] = right[0];
            swaps += leftLen;
            rightLen--;
            right++;
        }
        else
        {
            to[bufIndex] = left[0];
            leftLen--;
            left++;
        }
        bufIndex++;
    }

    if(leftLen)
    {
        #pragma omp critical (MEMCPY)
        memcpy(to + bufIndex, left, leftLen * sizeof(float));
    }
    else if(rightLen)
    {
        #pragma omp critical (MEMCPY)
        memcpy(to + bufIndex, right, rightLen * sizeof(float));
    }

    return swaps;
}

/*-------------------------------------------------------------------------*/
/* Sorts in place, returns the bubble sort distance between the input array
 * and the sorted array.
 */

static int mergeSort(float *x, float *buf, int len)
{
    int swaps, half ;

    /* printf("enter mergeSort\n") ; */

    if(len < 10)
    {
        return insertionSort(x, len);
    }

    swaps = 0;

    if(len < 2)
    {
        return 0;
    }

    half = len / 2;
    swaps += mergeSort(x, buf, half);
    swaps += mergeSort(x + half, buf + half, len - half);
    swaps += merge(x, buf, half, len);

    #pragma omp critical (MEMCPY)
    memcpy(x, buf, len * sizeof(float));
    return swaps;
}

/*-------------------------------------------------------------------------*/

static int getMs(float *data, int len)  /* Assumes data is sorted */
{
    int Ms = 0, tieCount = 0, i ;

    /* printf("enter getMs\n") ; */

    for(i = 1; i < len; i++)
    {
        if(data[i] == data[i - 1])
        {
            tieCount++;
        }
        else if(tieCount)
        {
            Ms += (tieCount * (tieCount + 1)) / 2;
            tieCount = 0;
        }
    }
    if(tieCount)
    {
        Ms += (tieCount * (tieCount + 1)) / 2;
    }
    return Ms;
}

/*-------------------------------------------------------------------------*/
/* This function calculates the Kendall correlation tau_b.
 * The arrays arr1 should be sorted before this call, and arr2 should be
 * re-ordered in lockstep.  This can be done by calling
 *   qsort_floatfloat(len,arr1,arr2)
 * for example.
 * Note also that arr1 and arr2 will be modified, so if they need to
 * be preserved, do so before calling this function.
 */

float kendallNlogN( float *arr1, float *arr2, int len )
{
    int m1 = 0, m2 = 0, tieCount, swapCount, nPair, s, i ;
    float cor ;

    /* printf("enter kendallNlogN\n") ; */

    if( len < 2 ) return (float)0 ;

    nPair = len * (len - 1) / 2;
    s = nPair;

    tieCount = 0;
    for(i = 1; i < len; i++)
    {
        if(arr1[i - 1] == arr1[i])
        {
            tieCount++;
        }
        else if(tieCount > 0)
        {
            insertionSort(arr2 + i - tieCount - 1, tieCount + 1);
            m1 += tieCount * (tieCount + 1) / 2;
            s += getMs(arr2 + i - tieCount - 1, tieCount + 1);
            tieCount = 0;
        }
    }
    if(tieCount > 0)
    {
        insertionSort(arr2 + i - tieCount - 1, tieCount + 1);
        m1 += tieCount * (tieCount + 1) / 2;
        s += getMs(arr2 + i - tieCount - 1, tieCount + 1);
    }

    swapCount = mergeSort(arr2, arr1, len);

    m2 = getMs(arr2, len);
    s -= (m1 + m2) + 2 * swapCount;

    if( m1 < nPair && m2 < nPair )
        cor = s / ( sqrtf((float)(nPair - m1)) * sqrtf((float)(nPair - m2)) ) ;
    else
        cor = 0.0f ;

    return cor ;
}

/*-------------------------------------------------------------------------*/
/* This function uses a simple O(N^2) implementation.  It probably has a
 * smaller constant and therefore is useful in the small N case, and is also
 * useful for testing the relatively complex O(N log N) implementation.
 */

float kendallSmallN( float *arr1, float *arr2, int len )
{
    int m1 = 0, m2 = 0, s = 0, nPair, i, j ;
    float cor ;

    /* printf("enter kendallSmallN\n") ; */

    for(i = 0; i < len; i++)
    {
        for(j = i + 1; j < len; j++)
        {
            if(arr2[i] > arr2[j])
            {
                if (arr1[i] > arr1[j])
                {
                    s++;
                }
                else if(arr1[i] < arr1[j])
                {
                    s--;
                }
                else
                {
                    m1++;
                }
            }
            else if(arr2[i] < arr2[j])
            {
                if (arr1[i] > arr1[j])
                {
                    s--;
                }
                else if(arr1[i] < arr1[j])
                {
                    s++;
                }
                else
                {
                    m1++;
                }
            }
            else
            {
                m2++;

                if(arr1[i] == arr1[j])
                {
                    m1++;
                }
            }
        }
    }

    nPair = len * (len - 1) / 2;

    if( m1 < nPair && m2 < nPair )
        cor = s / ( sqrtf((float)(nPair - m1)) * sqrtf((float)(nPair - m2)) ) ;
    else
        cor = 0.0f ;

    return cor ;
}

void rvereseArray(uint32_t *arr, uint32_t start, uint32_t end)
{
    while (start < end)
    {
        int temp = arr[start];
        arr[start] = arr[end];
        arr[end] = temp;
        start++;
        end--;
    }
}


uint32_t levenshtein_distance_topK(uint32_t *array1, uint32_t *array2, uint32_t size_k)
{

    edit *script;
    uint32_t distance;

    distance = levenshtein_distance(array1, size_k, array2, size_k, &script);

    return distance;
}

uint32_t intersection_topK(uint32_t *array1, uint32_t *array2, uint32_t size_k, uint32_t topk)
{

    uint32_t v;
    uint32_t intersection = 0;

    if(topk > size_k)
        topk = size_k;

    for(v = size_k - topk; v < size_k; v++)
    {
        // printf("%d %d %d %d\n",v,array1[v], array2[array1[v]], size_k-topk);
        if(array2[array1[v]] >= size_k - topk)
            intersection++;
    }

    return intersection;
}

void collectStatsPageRank( struct Arguments *arguments,  struct PageRankStats *stats, struct PageRankStats *ref_stats, uint32_t trial)
{

    uint32_t v;
    uint32_t u;
    uint32_t topk;

    topk = arguments->binSize;


    if(topk > ref_stats->num_vertices)
        topk = ref_stats->num_vertices;

    uint32_t *rankedVertices = (uint32_t *) my_malloc(topk * sizeof(uint32_t));
    uint32_t *rankedVertices_inverse = (uint32_t *) my_malloc(ref_stats->num_vertices * sizeof(uint32_t));
    uint32_t *ref_rankedVertices = (uint32_t *) my_malloc(topk * sizeof(uint32_t));
    uint32_t *ref_rankedVertices_total = (uint32_t *) my_malloc(ref_stats->num_vertices * sizeof(uint32_t));

    float *rankedVerticesfloat = (float *) my_malloc(topk * sizeof(float));
    float *ref_rankedVerticesfloat = (float *) my_malloc(topk * sizeof(float));

    uint32_t levenshtein_distance = 0;
    float Kendall = 0.0f;
    uint32_t intersection = 0;

    // rvereseArray(stats->realRanks, 0, stats->num_vertices-1);
    // rvereseArray(stats->pageRanks, 0, stats->num_vertices-1);
    // rvereseArray(ref_stats->realRanks, 0, ref_stats->num_vertices-1);
    // rvereseArray(ref_stats->pageRanks, 0, ref_stats->num_vertices-1);


    // invert the array now the rank -> vetrex
    for(u = 0, v = (stats->num_vertices - topk); v < stats->num_vertices; v++, u++)
    {
        rankedVertices[u] =  stats->realRanks[v];

        // printf("%d %d %d %d\n",stats->realRanks[v],v,stats->realRanks[v]-(topk+1),u );
        // rankedVertices_inverse[stats->realRanks[v]] = v;
        rankedVerticesfloat[u] =  stats->pageRanks[stats->realRanks[v]];
    }

    for(v = 0; v < stats->num_vertices; v++)
    {
        rankedVertices_inverse[stats->realRanks[v]] = v;
        ref_rankedVertices_total[v] = ref_stats->realRanks[v];

    }

    for(u = 0, v = (ref_stats->num_vertices - topk); v < ref_stats->num_vertices; v++, u++)
    {
        ref_rankedVertices[u] = ref_stats->realRanks[v];
        ref_rankedVerticesfloat[u] =  ref_stats->pageRanks[stats->realRanks[v]];
    }


    // for(v = (stats->num_vertices-topk); v < stats->num_vertices; v++)
    // {
    //     printf("rank %u vertex %u pr %.22f \n", v,  stats->realRanks[v], stats->pageRanks[stats->realRanks[v]]);
    // }

    // for(v = (ref_stats->num_vertices-topk); v < ref_stats->num_vertices; v++)
    // {
    //     printf("rank %u vertex %u pr %.22f \n", v,  ref_stats->realRanks[v], ref_stats->pageRanks[ref_stats->realRanks[v]]);
    // }


    levenshtein_distance = levenshtein_distance_topK(ref_rankedVertices, rankedVertices, topk);
    Kendall = kendallNlogN(ref_rankedVerticesfloat, rankedVerticesfloat, topk);
    intersection = intersection_topK(ref_rankedVertices_total, rankedVertices_inverse, ref_stats->num_vertices, topk);

    if(arguments->verbosity > 0)
    {

        char *fname_txt = (char *) malloc((strlen(arguments->fnameb) + 50) * sizeof(char));
        // char *fname_stats_out = (char *) malloc((strlen(arguments->fnameb) + 20) * sizeof(char));
        // fname_txt = strcpy (fname_txt, arguments->fnameb);
        // fname_txt = strcat (fname_txt, ".stats");
        sprintf(fname_txt, "%s_%d_%d_%d_%d.%s", arguments->fnameb, arguments->algorithm, arguments->datastructure, arguments->pushpull, arguments->numThreads, "stats");
        FILE *fptr;
        fptr = fopen(fname_txt, "a+");

        fprintf(fptr, "\n-----------------------------------------------------\n");
        fprintf(fptr, "topk:         %d \n", topk);
        fprintf(fptr, "-----------------------------------------------------\n");
        fprintf(fptr, "levenshtein_distance: %d \n", levenshtein_distance);
        fprintf(fptr, "Kendall_cor:      %lf\n", Kendall);
        fprintf(fptr, "intersection: %d \n", intersection);

        fprintf(fptr, "numThreads:   %d \n", arguments->numThreads);
        fprintf(fptr, "Time (S):     %lf\n", stats->time_total);
        fprintf(fptr, "Iterations:   %d \n", stats->iterations);

        if(arguments->verbosity > 1)
        {
            fprintf(fptr, " ----------------------------------------------------- ");
            fprintf(fptr, " -----------------------------------------------------\n");
            fprintf(fptr, "| %-14s | %-14s | %-17s | ", "Ref Rank", "Vertex", "PageRank");
            fprintf(fptr, "| %-14s | %-14s | %-17s | \n", "Rank", "Vertex", "PageRank");
            fprintf(fptr, " ----------------------------------------------------- ");
            fprintf(fptr, " -----------------------------------------------------\n");

            for(v = (ref_stats->num_vertices - topk); v < ref_stats->num_vertices; v++)
            {
                // fprintf(fptr,"rank %u vertex %u pr %.22f \n", v,  ref_stats->realRanks[v], ref_stats->pageRanks[ref_stats->realRanks[v]]);
                fprintf(fptr, "| %-14u | %-14u | %-10.15lf | ", v, ref_stats->realRanks[v], ref_stats->pageRanks[ref_stats->realRanks[v]]);
                fprintf(fptr, "| %-14u | %-14u | %-10.15lf | \n", v, stats->realRanks[v], stats->pageRanks[stats->realRanks[v]]);
            }

            fprintf(fptr, " ----------------------------------------------------- ");
        }

        fprintf(fptr, " -----------------------------------------------------\n");
        // printf("levenshtein_distance: %d \n", levenshtein_distance);
        // printf("Kendall:      %lf \n", Kendall);
        // printf("intersection: %d \n", intersection);

        fclose(fptr);
        free(fname_txt);
    }

    free(rankedVertices);
    free(ref_rankedVertices_total);
    free(rankedVertices_inverse);
    free(ref_rankedVertices);
    free(rankedVerticesfloat);
    free(ref_rankedVerticesfloat);
}

// void collectStats(struct Arguments *arguments)
// {

//     struct Timer *timer = (struct Timer *) malloc(sizeof(struct Timer));
//     // printf("Filename : %s \n",fnameb);

//     printf(" *****************************************************\n");
//     printf(" -----------------------------------------------------\n");
//     printf("| %-51s | \n", "Collect Stats Process");
//     printf(" -----------------------------------------------------\n");
//     Start(timer);

//     struct GraphCSR *graphStats = graphCSRPreProcessingStep (arguments);


//     uint32_t *histogram_in = (uint32_t *) my_malloc(sizeof(uint32_t) * arguments->binSize);
//     uint32_t *histogram_out = (uint32_t *) my_malloc(sizeof(uint32_t) * arguments->binSize);


//     uint32_t i = 0;
//     #pragma omp parallel for
//     for(i = 0 ; i < arguments->binSize; i++)
//     {
//         histogram_in[i] = 0;
//         histogram_out[i] = 0;
//     }

//     char *fname_txt = (char *) malloc((strlen(arguments->fnameb) + 20) * sizeof(char));
//     char *fname_stats_out = (char *) malloc((strlen(arguments->fnameb) + 20) * sizeof(char));
//     char *fname_stats_in = (char *) malloc((strlen(arguments->fnameb) + 20) * sizeof(char));
//     char *fname_adjMat = (char *) malloc((strlen(arguments->fnameb) + 20) * sizeof(char));


//     fname_txt = strcpy (fname_txt, arguments->fnameb);
//     fname_adjMat = strcpy (fname_adjMat, arguments->fnameb);


//     fname_adjMat  = strcat (fname_adjMat, ".bin-adj-SM.dat");// out-degree

//     if(arguments->lmode == 1)
//     {
//         fname_stats_in = strcat (fname_txt, ".in-degree.dat");// in-degree
//         countHistogram(graphStats, histogram_in, arguments->binSize, arguments->inout_degree);
//         printHistogram(fname_stats_in, histogram_in, arguments->binSize);
//     }
//     else if(arguments->lmode == 2)
//     {
//         fname_stats_out = strcat (fname_txt, ".out-degree.dat");// out-degree
//         countHistogram(graphStats, histogram_out, arguments->binSize, arguments->inout_degree);
//         printHistogram(fname_stats_out, histogram_out, arguments->binSize);
//     }


//     printSparseMatrixList(fname_adjMat,  graphStats, arguments->binSize);


//     Stop(timer);


//     printf(" -----------------------------------------------------\n");
//     printf("| %-51s | \n", "Collect Stats Complete");
//     printf(" -----------------------------------------------------\n");
//     printf("| %-51f | \n", Seconds(timer));
//     printf(" -----------------------------------------------------\n");
//     printf(" *****************************************************\n");

//     free(timer);
//     graphCSRFree(graphStats);
//     free(histogram_in);
//     free(histogram_out);
//     free(fname_txt);
//     free(fname_stats_out);
//     free(fname_stats_in);
//     free(fname_adjMat);

// }


// void countHistogram(struct GraphCSR *graphStats, uint32_t *histogram, uint32_t binSize, uint32_t inout_degree)
// {

//     uint32_t v;
//     uint32_t index;

//     #pragma omp parallel for
//     for(v = 0; v < graphStats->num_vertices; v++)
//     {

//         index = v / ((graphStats->num_vertices / binSize) + 1);

//         if(inout_degree == 1)
//         {
//             #pragma omp atomic update
//             histogram[index] += graphStats->vertices->in_degree[v];
//         }
//         else if(inout_degree == 2)
//         {
//             #pragma omp atomic update
//             histogram[index] += graphStats->vertices->out_degree[v];
//         }
//     }

// }


// void printHistogram(const char *fname_stats, uint32_t *histogram, uint32_t binSize)
// {

//     uint32_t index;
//     FILE *fptr;
//     fptr = fopen(fname_stats, "w");
//     for(index = 0; index < binSize; index++)
//     {
//         fprintf(fptr, "%u %u \n", index, histogram[index]);
//     }
//     fclose(fptr);
// }


// void printSparseMatrixList(const char *fname_stats, struct GraphCSR *graphStats, uint32_t binSize)
// {


//     uint32_t *SparseMatrix = (uint32_t *) my_malloc(sizeof(uint32_t) * binSize * binSize);


//     uint32_t x;
//     uint32_t y;
//     #pragma omp parallel for private(y) shared(SparseMatrix)
//     for(x = 0; x < binSize; x++)
//     {
//         for(y = 0; y < binSize; y++)
//         {
//             SparseMatrix[(binSize * y) + x] = 0;
//         }
//     }


//     uint32_t i;

//     #pragma omp parallel for
//     for(i = 0; i < graphStats->num_edges; i++)
//     {
//         uint32_t src;
//         uint32_t dest;
//         src = graphStats->sorted_edges_array->edges_array_src[i] / ((graphStats->num_vertices / binSize) + 1);
//         dest = graphStats->sorted_edges_array->edges_array_dest[i] / ((graphStats->num_vertices / binSize) + 1);

//         #pragma omp atomic update
//         SparseMatrix[(binSize * dest) + src]++;

//     }

//     FILE *fptr;
//     fptr = fopen(fname_stats, "w");
//     for(x = 0; x < binSize; x++)
//     {
//         for(y = 0; y < binSize; y++)
//         {
//             fprintf(fptr, "%u %u %u\n", x, y, SparseMatrix[(binSize * y) + x]);
//         }
//     }

//     fclose(fptr);
//     free(SparseMatrix);

// }

