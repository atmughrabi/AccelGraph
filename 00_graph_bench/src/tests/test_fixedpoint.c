// -----------------------------------------------------------------------------
//
//      "00_AccelGraph"
//
// -----------------------------------------------------------------------------
// Copyright (c) 2014-2019 All rights reserved
// -----------------------------------------------------------------------------
// Author : Abdullah Mughrabi
// Email  : atmughra@ncsu.edu||atmughrabi@gmail.com
// File   : test_fixedpoint.c
// Create : 2019-06-21 17:15:17
// Revise : 2019-09-28 15:36:29
// Editor : Abdullah Mughrabi
// -----------------------------------------------------------------------------
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "fixedPoint.h"

int numThreads;

int main(int argc, char *argv[])
{

    struct FixedPoint *fp = (struct FixedPoint *)malloc(sizeof(struct FixedPoint));

    initFixedPoint(fp, 32, 16, 48);

    float damp = 0.85f;
    double dampd = 0.85f;
    __u32 out_degree = 70000000;
    __u32 N = 70000000;
    float sum_pr = 0.15f;

    float divincoming = sum_pr / out_degree;
    double divincomingd = (double)sum_pr / out_degree;

    __u64 out_degree_fp = UInt64ToFixed64(out_degree);
    __u64 sum_pr_fp = FloatToFixed64(sum_pr);
    __u64 divincomingfp = FloatToFixed64(divincoming);
    __u64 op1fp = FloatToFixed64(1 - damp);
    __u64 dampfp = FloatToFixed64(damp);

    printf("damp %.24f \n", damp);

    printf("damp_fp %u \n", FloatToFixed(damp));
    printf("damp_fp_d %u \n", DoubleToFixed(damp));

    printf("f_damp_fp %u \n", floatToFixed32(fp, damp));
    printf("f_damp_fp_d %u \n", doubleToFixed32(fp, dampd));

    printf("f_damp_fp_c %.24f \n", fixed32ToFloat(fp, floatToFixed32(fp, damp)) );
    printf("f_damp_fp_d_c %.24f \n\n", fixed32ToDouble(fp, doubleToFixed32(fp, dampd)) );



    printf("divincoming %.24f \n", divincoming);
    printf("divincomingd %.24f \n", divincomingd);

    printf("divincoming_fp %u \n", FloatToFixed64(divincoming));
    printf("divincoming_fp_d %u \n", DoubleToFixed64(divincomingd));

    printf("f_divincoming_fp %u \n", floatToFixed64(fp, divincoming));
    printf("f_divincoming_fp_d %u \n", doubleToFixed64(fp, divincomingd));

    printf("f_divincoming_fp_c %.24f \n", fixed64ToFloat(fp, floatToFixed64(fp, divincoming)) );
    printf("f_divincoming_fp_d_c %.24f \n\n", fixed64ToDouble(fp, doubleToFixed64(fp, divincomingd)) );


    __u32 i;
    __u64 sumfp = 0;
    double sumd = 0.0f;
    float sumf = 0.0f;

    for(i = 0 ; i < N ; i++)
    {

        sumfp += DIVFixed64V1(sum_pr_fp, out_degree_fp);
        sumf += divincoming;
        sumd += divincomingd;

    }


    printf("sumfp %24f \n", fixed64ToFloat(fp, sumfp));
    printf("sumf %.24f \n", sumf);
    printf("sumd %.24f \n\n", sumd);


    double pr = (1 - dampd) + dampd * sumd;
    __u64  pr_f = op1fp + MULFixed64V1(dampfp, sumfp);


    printf("pr %.24f \n", pr);
    printf("pr_fp %.24f \n", fixed64ToFloat(fp, pr_f));


}