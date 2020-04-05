#ifndef GRAPHSTATS_H
#define GRAPHSTATS_H

#include <stdint.h>
#include "graphConfig.h"
#include "graphCSR.h"
#include "pageRank.h"

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


uint32_t levenshtein_distance(const uint32_t *array1, const uint32_t len1, const uint32_t *array2, const uint32_t len2, edit **script);
void print(const edit *e);
float kendallNlogN( float *arr1, float *arr2, int len );

void collectStatsPageRank( struct Arguments *arguments, struct PageRankStats *stats, struct PageRankStats *ref_stats, uint32_t trial);
void collectStats( struct Arguments *arguments);
void countHistogram(struct GraphCSR *graphStats, uint32_t *histogram, uint32_t binSize, uint32_t inout_degree);
void printHistogram(const char *fname_stats, uint32_t *histogram, uint32_t binSize);
void printSparseMatrixList(const char *fname_stats, struct GraphCSR *graphStats, uint32_t binSize);

#endif

