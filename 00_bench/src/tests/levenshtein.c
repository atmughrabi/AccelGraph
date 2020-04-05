// -----------------------------------------------------------------------------
//
//      "00_AccelGraph"
//
// -----------------------------------------------------------------------------
// Copyright (c) 2014-2019 All rights reserved
// -----------------------------------------------------------------------------
// Author : http://www.martinbroadhurst.com/levenshtein-distance-in-c.html
// Email  : atmughra@ncsu.edu||atmughrabi@gmail.com
// File   : levenshtein.c
// Create : 2019-07-29 16:52:00
// Revise : 2019-09-28 15:36:29
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

#include "graphStats.h"
#include "edgeList.h"
#include "myMalloc.h"

#include "graphCSR.h"
#include "graphAdjLinkedList.h"
#include "graphAdjArrayList.h"
#include "graphGrid.h"

#include "mt19937.h"
#include "graphConfig.h"
#include "timer.h"
#include "graphRun.h"

#include "BFS.h"
#include "DFS.h"
#include "pageRank.h"
#include "incrementalAggregation.h"
#include "bellmanFord.h"
#include "SSSP.h"
#include "connectedComponents.h"
#include "triangleCount.h"


#include "graphTest.h"

int numThreads;
mt19937state *mt19937var;

// "   mm                        ""#             mmm                       #     \n"
// "   ##    mmm    mmm    mmm     #           m"   "  m mm   mmm   mmmm   # mm  \n"
// "  #  #  #"  "  #"  "  #"  #    #           #   mm  #"  " "   #  #" "#  #"  # \n"
// "  #mm#  #      #      #""""    #     """   #    #  #     m"""#  #   #  #   # \n"
// " #    # "#mm"  "#mm"  "#mm"    "mm          "mmm"  #     "mm"#  ##m#"  #   # \n"
// "                                                                #            \n"

typedef enum
{
    INSERTION,
    DELETION,
    SUBSTITUTION,
    NONE
} edit_type;

struct edit
{
    uint32_t score;
    edit_type type;
    uint32_t arg1;
    uint32_t arg2;
    uint32_t pos;
    struct edit *prev;
};
typedef struct edit edit;

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

static int insertionSort(uint32_t *arr, int len)
{
    int maxJ, i,j , swapCount = 0;

/* printf("enter insertionSort len=%d\n",len) ; */

    if(len < 2) { return 0; }

    maxJ = len - 1;
    for(i = len - 2; i >= 0; --i) {
        uint32_t  val = arr[i];
        for(j=i; j < maxJ && arr[j + 1] < val; ++j) {
            arr[j] = arr[j + 1];
        }

        arr[j] = val;
        swapCount += (j - i);
    }

    return swapCount;
}

/*-------------------------------------------------------------------------*/

static int merge(uint32_t *from, uint32_t *to, int middle, int len)
{
    int bufIndex, leftLen, rightLen , swaps ;
    uint32_t *left , *right;

/* printf("enter merge\n") ; */

    bufIndex = 0;
    swaps = 0;

    left = from;
    right = from + middle;
    rightLen = len - middle;
    leftLen = middle;

    while(leftLen && rightLen) {
        if(right[0] < left[0]) {
            to[bufIndex] = right[0];
            swaps += leftLen;
            rightLen--;
            right++;
        } else {
            to[bufIndex] = left[0];
            leftLen--;
            left++;
        }
        bufIndex++;
    }

    if(leftLen) {
#pragma omp critical (MEMCPY)
        memcpy(to + bufIndex, left, leftLen * sizeof(uint32_t));
    } else if(rightLen) {
#pragma omp critical (MEMCPY)
        memcpy(to + bufIndex, right, rightLen * sizeof(uint32_t));
    }

    return swaps;
}

/*-------------------------------------------------------------------------*/
/* Sorts in place, returns the bubble sort distance between the input array
 * and the sorted array.
 */

static int mergeSort(uint32_t *x, uint32_t *buf, int len)
{
    int swaps , half ;

/* printf("enter mergeSort\n") ; */

    if(len < 10) {
        return insertionSort(x, len);
    }

    swaps = 0;

    if(len < 2) { return 0; }

    half = len / 2;
    swaps += mergeSort(x, buf, half);
    swaps += mergeSort(x + half, buf + half, len - half);
    swaps += merge(x, buf, half, len);

#pragma omp critical (MEMCPY)
    memcpy(x, buf, len * sizeof(uint32_t));
    return swaps;
}

/*-------------------------------------------------------------------------*/

static int getMs(uint32_t *data, int len)  /* Assumes data is sorted */
{
    int Ms = 0, tieCount = 0 , i ;

/* printf("enter getMs\n") ; */

    for(i = 1; i < len; i++) {
        if(data[i] == data[i-1]) {
            tieCount++;
        } else if(tieCount) {
            Ms += (tieCount * (tieCount + 1)) / 2;
            tieCount = 0;
        }
    }
    if(tieCount) {
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

float kendallNlogN( uint32_t *arr1, uint32_t *arr2, int len )
{
    int m1 = 0, m2 = 0, tieCount, swapCount, nPair, s,i ;
    float cor ;

/* printf("enter kendallNlogN\n") ; */

    if( len < 2 ) return (float)0 ;

    nPair = len * (len - 1) / 2;
    s = nPair;

    tieCount = 0;
    for(i = 1; i < len; i++) {
        if(arr1[i - 1] == arr1[i]) {
            tieCount++;
        } else if(tieCount > 0) {
            insertionSort(arr2 + i - tieCount - 1, tieCount + 1);
            m1 += tieCount * (tieCount + 1) / 2;
            s += getMs(arr2 + i - tieCount - 1, tieCount + 1);
            tieCount = 0;
        }
    }
    if(tieCount > 0) {
        insertionSort(arr2 + i - tieCount - 1, tieCount + 1);
        m1 += tieCount * (tieCount + 1) / 2;
        s += getMs(arr2 + i - tieCount - 1, tieCount + 1);
    }

    swapCount = mergeSort(arr2, arr1, len);

    m2 = getMs(arr2, len);
    s -= (m1 + m2) + 2 * swapCount;

    if( m1 < nPair && m2 < nPair )
      cor = s / ( sqrtf((float)(nPair-m1)) * sqrtf((float)(nPair-m2)) ) ;
    else
      cor = 0.0f ;

    return cor ;
}

int main(void)
{
    edit *script;
    uint32_t distance;
    float kendall;
    uint32_t i;

    uint32_t array1[] = {0,1,2,3,4,8,9};
    uint32_t array2[] = {1,2,3,4,8,9,0};
    uint32_t array3[] = {0,1,2,4,3,5,7,6,8};
    uint32_t array4[] = {8,7,6,5,4,3,2,1,0};
    distance = levenshtein_distance(array1, 6, array2, 6, &script);
    kendall  = kendallNlogN(array3 , array4, 9);
    printf("Distance is %d:\n", distance);
    printf("kendall is %f:\n", kendall);
    for (i = 0; i < distance; i++)
    {
        print(&script[i]);
    }
    free(script);
    return 0;
}





