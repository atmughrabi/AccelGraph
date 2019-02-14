/*******************************************************************************
 * Copyright (c) 2008-2010 The Khronos Group Inc.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and/or associated documentation files (the
 * "Materials"), to deal in the Materials without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Materials, and to
 * permit persons to whom the Materials are furnished to do so, subject to
 * the following conditions:
 *
 * The above copyright notice and this permission notice shall be included
 * in all copies or substantial portions of the Materials.
 *
 * THE MATERIALS ARE PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * MATERIALS OR THE USE OR OTHER DEALINGS IN THE MATERIALS.
 ******************************************************************************/

/* $Revision: 11928 $ on $Date: 2010-07-13 09:04:56 -0700 (Tue, 13 Jul 2010) $ */

/* cl_ext.h contains OpenCL extensions which don't have external */
/* (OpenGL, D3D) dependencies.                                   */

#ifndef __CL_EXT_H
#define __CL_EXT_H

#ifdef __cplusplus
extern "C" {
#endif

#ifdef __APPLE__
	#include <OpenCL/cl.h>
    #include <AvailabilityMacros.h>
#else
	#include <CL/cl.h>
#endif

/* cl_khr_fp64 extension - no extension #define since it has no functions  */
#define CL_DEVICE_DOUBLE_FP_CONFIG                  0x1032

/* cl_khr_fp16 extension - no extension #define since it has no functions  */
#define CL_DEVICE_HALF_FP_CONFIG                    0x1033

/* Memory object destruction
 *
 * Apple extension for use to manage externally allocated buffers used with cl_mem objects with CL_MEM_USE_HOST_PTR
 *
 * Registers a user callback function that will be called when the memory object is deleted and its resources 
 * freed. Each call to clSetMemObjectCallbackFn registers the specified user callback function on a callback 
 * stack associated with memobj. The registered user callback functions are called in the reverse order in 
 * which they were registered. The user callback functions are called and then the memory object is deleted 
 * and its resources freed. This provides a mechanism for the application (and libraries) using memobj to be 
 * notified when the memory referenced by host_ptr, specified when the memory object is created and used as 
 * the storage bits for the memory object, can be reused or freed.
 *
 * The application may not call CL api's with the cl_mem object passed to the pfn_notify.
 *
 * Please check for the "cl_APPLE_SetMemObjectDestructor" extension using clGetDeviceInfo(CL_DEVICE_EXTENSIONS)
 * before using.
 */
#define cl_APPLE_SetMemObjectDestructor 1
cl_int	CL_API_ENTRY clSetMemObjectDestructorAPPLE(  cl_mem /* memobj */, 
                                        void (* /*pfn_notify*/)( cl_mem /* memobj */, void* /*user_data*/), 
                                        void * /*user_data */ )             CL_EXT_SUFFIX__VERSION_1_0;  


/* Context Logging Functions
 *
 * The next three convenience functions are intended to be used as the pfn_notify parameter to clCreateContext().
 * Please check for the "cl_APPLE_ContextLoggingFunctions" extension using clGetDeviceInfo(CL_DEVICE_EXTENSIONS)
 * before using.
 *
 * clLogMessagesToSystemLog fowards on all log messages to the Apple System Logger 
 */
#define cl_APPLE_ContextLoggingFunctions 1
extern void CL_API_ENTRY clLogMessagesToSystemLogAPPLE(  const char * /* errstr */, 
                                            const void * /* private_info */, 
                                            size_t       /* cb */, 
                                            void *       /* user_data */ )  CL_EXT_SUFFIX__VERSION_1_0;

/* clLogMessagesToStdout sends all log messages to the file descriptor stdout */
extern void CL_API_ENTRY clLogMessagesToStdoutAPPLE(   const char * /* errstr */, 
                                          const void * /* private_info */, 
                                          size_t       /* cb */, 
                                          void *       /* user_data */ )    CL_EXT_SUFFIX__VERSION_1_0;

/* clLogMessagesToStderr sends all log messages to the file descriptor stderr */
extern void CL_API_ENTRY clLogMessagesToStderrAPPLE(   const char * /* errstr */, 
                                          const void * /* private_info */, 
                                          size_t       /* cb */, 
                                          void *       /* user_data */ )    CL_EXT_SUFFIX__VERSION_1_0;


/************************ 
* cl_khr_icd extension *                                                  
************************/
#define cl_khr_icd 1

/* cl_platform_info                                                        */
#define CL_PLATFORM_ICD_SUFFIX_KHR                  0x0920

/* Additional Error Codes                                                  */
#define CL_PLATFORM_NOT_FOUND_KHR                   -1001

extern CL_API_ENTRY cl_int CL_API_CALL
clIcdGetPlatformIDsKHR(cl_uint          /* num_entries */,
                       cl_platform_id * /* platforms */,
                       cl_uint *        /* num_platforms */);

typedef CL_API_ENTRY cl_int (CL_API_CALL *clIcdGetPlatformIDsKHR_fn)(
    cl_uint          /* num_entries */,
    cl_platform_id * /* platforms */,
    cl_uint *        /* num_platforms */);


/******************************************
* cl_nv_device_attribute_query extension *
******************************************/
/* cl_nv_device_attribute_query extension - no extension #define since it has no functions */
#define CL_DEVICE_COMPUTE_CAPABILITY_MAJOR_NV       0x4000
#define CL_DEVICE_COMPUTE_CAPABILITY_MINOR_NV       0x4001
#define CL_DEVICE_REGISTERS_PER_BLOCK_NV            0x4002
#define CL_DEVICE_WARP_SIZE_NV                      0x4003
#define CL_DEVICE_GPU_OVERLAP_NV                    0x4004
#define CL_DEVICE_KERNEL_EXEC_TIMEOUT_NV            0x4005
#define CL_DEVICE_INTEGRATED_MEMORY_NV              0x4006


/*********************************
* cl_amd_device_attribute_query *
*********************************/
#define CL_DEVICE_PROFILING_TIMER_OFFSET_AMD        0x4036


#ifdef CL_VERSION_1_1
   /***********************************
    * cl_ext_device_fission extension *
    ***********************************/
    #define cl_ext_device_fission   1
    
    extern CL_API_ENTRY cl_int CL_API_CALL
    clReleaseDeviceEXT( cl_device_id /*device*/ ) CL_EXT_SUFFIX__VERSION_1_1; 
    
    typedef CL_API_ENTRY cl_int 
    (CL_API_CALL *clReleaseDeviceEXT_fn)( cl_device_id /*device*/ ) CL_EXT_SUFFIX__VERSION_1_1;

    extern CL_API_ENTRY cl_int CL_API_CALL
    clRetainDeviceEXT( cl_device_id /*device*/ ) CL_EXT_SUFFIX__VERSION_1_1; 
    
    typedef CL_API_ENTRY cl_int 
    (CL_API_CALL *clRetainDeviceEXT_fn)( cl_device_id /*device*/ ) CL_EXT_SUFFIX__VERSION_1_1;

    typedef cl_ulong  cl_device_partition_property_ext;
    extern CL_API_ENTRY cl_int CL_API_CALL
    clCreateSubDevicesEXT(  cl_device_id /*in_device*/,
                            const cl_device_partition_property_ext * /* properties */,
                            cl_uint /*num_entries*/,
                            cl_device_id * /*out_devices*/,
                            cl_uint * /*num_devices*/ ) CL_EXT_SUFFIX__VERSION_1_1;

    typedef CL_API_ENTRY cl_int 
    ( CL_API_CALL * clCreateSubDevicesEXT_fn)(  cl_device_id /*in_device*/,
                                                const cl_device_partition_property_ext * /* properties */,
                                                cl_uint /*num_entries*/,
                                                cl_device_id * /*out_devices*/,
                                                cl_uint * /*num_devices*/ ) CL_EXT_SUFFIX__VERSION_1_1;

    /* cl_device_partition_property_ext */
    #define CL_DEVICE_PARTITION_EQUALLY_EXT             0x4050
    #define CL_DEVICE_PARTITION_BY_COUNTS_EXT           0x4051
    #define CL_DEVICE_PARTITION_BY_NAMES_EXT            0x4052
    #define CL_DEVICE_PARTITION_BY_AFFINITY_DOMAIN_EXT  0x4053
    
    /* clDeviceGetInfo selectors */
    #define CL_DEVICE_PARENT_DEVICE_EXT                 0x4054
    #define CL_DEVICE_PARTITION_TYPES_EXT               0x4055
    #define CL_DEVICE_AFFINITY_DOMAINS_EXT              0x4056
    #define CL_DEVICE_REFERENCE_COUNT_EXT               0x4057
    #define CL_DEVICE_PARTITION_STYLE_EXT               0x4058
    
    /* error codes */
    #define CL_DEVICE_PARTITION_FAILED_EXT              -1057
    #define CL_INVALID_PARTITION_COUNT_EXT              -1058
    #define CL_INVALID_PARTITION_NAME_EXT               -1059
    
    /* CL_AFFINITY_DOMAINs */
    #define CL_AFFINITY_DOMAIN_L1_CACHE_EXT             0x1
    #define CL_AFFINITY_DOMAIN_L2_CACHE_EXT             0x2
    #define CL_AFFINITY_DOMAIN_L3_CACHE_EXT             0x3
    #define CL_AFFINITY_DOMAIN_L4_CACHE_EXT             0x4
    #define CL_AFFINITY_DOMAIN_NUMA_EXT                 0x10
    #define CL_AFFINITY_DOMAIN_NEXT_FISSIONABLE_EXT     0x100
    
    /* cl_device_partition_property_ext list terminators */
    #define CL_PROPERTIES_LIST_END_EXT                  ((cl_device_partition_property_ext) 0)
    #define CL_PARTITION_BY_COUNTS_LIST_END_EXT         ((cl_device_partition_property_ext) 0)
    #define CL_PARTITION_BY_NAMES_LIST_END_EXT          ((cl_device_partition_property_ext) 0 - 1)



#endif /* CL_VERSION_1_1 */


/* Altera extensions. */


/*********************************
* cl_altera_mem_banks
*********************************/
/* cl_mem_flags - bitfield */
#define CL_MEM_BANK_AUTO_ALTERA           (0<<6)
#define CL_MEM_BANK_1_ALTERA              (1<<6)
#define CL_MEM_BANK_2_ALTERA              (2<<6)
#define CL_MEM_BANK_3_ALTERA              (3<<6)
#define CL_MEM_BANK_4_ALTERA              (4<<6)
#define CL_MEM_BANK_5_ALTERA              (5<<6)
#define CL_MEM_BANK_6_ALTERA              (6<<6)
#define CL_MEM_BANK_7_ALTERA              (7<<6)


#define CL_MEM_HETEROGENEOUS_ALTERA  (1<<10)



/*********************************
* clGetDeviceInfo extension
*********************************/
#define cl_altera_device_temperature
/* Enum query for clGetDeviceInfo to get the die temperature in Celsius as a cl_int.
 * If the device does not support the query then the result will be 0 */
#define CL_DEVICE_CORE_TEMPERATURE_ALTERA        0x40F3



/*********************************
* CL API object tracking.
*********************************/
#define cl_altera_live_object_tracking

/* Call this to begin tracking CL API objects.  
 * Ideally, do this immediately after getting the platform ID.
 * This takes extra space and time.
 */
extern CL_API_ENTRY void CL_API_CALL
clTrackLiveObjectsAltera(cl_platform_id platform);

/* Call this to be informed of all the live CL API objects, with their
 * reference counts.
 * The type name argument to the callback will be the string form of the type name
 * e.g. "cl_event" for a cl_event.
 */
extern CL_API_ENTRY void CL_API_CALL
clReportLiveObjectsAltera(
      cl_platform_id platform,
      void (CL_CALLBACK * /*report_fn*/)(
         void* /* user_data */,
         void* /* obj_ptr */,
         const char* /* type_name */, 
         cl_uint /* refcount */ ),
      void* /* user_data*/ );

/* Call this to query the FPGA and collect dynamic profiling data
 * for a single kernel.
 *
 * The event passed to this call must be the event used
 * in the kernel clEnqueueNDRangeKernel call. If the kernel
 * completes execution before this function is invoked, 
 * this function will return an event error code.
 *
 * NOTE: 
 * Invoking this function while the kernel is running will
 * disable the profile counters for a given interval.
 * For example, on a PCIe-based system this was measured
 * to be approximately 100us.
 */
extern CL_API_ENTRY cl_int CL_API_CALL
clGetProfileInfoAltera(
      cl_event /* kernel event */
      );

/*********************************
* Altera offline compiler modes, offline device emulation.
*********************************/
#define cl_altera_compiler_mode

#define CL_CONTEXT_COMPILER_MODE_ALTERA 0x40F0

#define CL_CONTEXT_COMPILER_MODE_OFFLINE_ALTERA 0
#define CL_CONTEXT_COMPILER_MODE_OFFLINE_CREATE_EXE_LIBRARY_ALTERA 1
#define CL_CONTEXT_COMPILER_MODE_OFFLINE_USE_EXE_LIBRARY_ALTERA 2
#define CL_CONTEXT_COMPILER_MODE_PRELOADED_BINARY_ONLY_ALTERA 3

/* This property is used to specify the root directory of
 * the executable program library for compiler modes 
 * CL_CONTEXT_COMPILER_MODE_OFFLINE_CREATE_EXE_LIBRARY and
 * CL_CONTEXT_COMPILER_MODE_OFFLINE_USE_EXE_LIBRARY.
 * The value should be a pointer to a C-style character string naming
 * the directory.  It can be relative, but will be resolved to an absolute
 * directory at context creation time.
 */
#define CL_CONTEXT_PROGRAM_EXE_LIBRARY_ROOT_ALTERA 0x40F1

/* This property is used to emulate, as much as possible,
 * having a device that is actually not attached.
 * Kernels may be enqueued but their code will not be run, 
 * so data coming back from the device may be invalid.
 * The value should be a pointer to a C-style character string with the
 * short name for the device.
 */
#define CL_CONTEXT_OFFLINE_DEVICE_ALTERA 0x40F2

/******************************************
 * SVM extentions
 */
// OpenCL 2.0 cl.h definitions
typedef cl_bitfield         cl_device_svm_capabilities;
typedef cl_bitfield         cl_svm_mem_flags;

#define CL_MEM_SVM_FINE_GRAIN_BUFFER                (1 << 10)   /* used by cl_svm_mem_flags only */
#define CL_MEM_SVM_ATOMICS                          (1 << 11)   /* used by cl_svm_mem_flags only */

#define CL_DEVICE_SVM_CAPABILITIES                      0x1053

#define CL_MEM_USES_SVM_POINTER                     0x1109

/* cl_device_svm_capabilities */
#define CL_DEVICE_SVM_COARSE_GRAIN_BUFFER           (1 << 0)
#define CL_DEVICE_SVM_FINE_GRAIN_BUFFER             (1 << 1)
#define CL_DEVICE_SVM_FINE_GRAIN_SYSTEM             (1 << 2)
#define CL_DEVICE_SVM_ATOMICS                       (1 << 3)

#define CL_COMMAND_SVM_FREE                         0x1209
#define CL_COMMAND_SVM_MEMCPY                       0x120A
#define CL_COMMAND_SVM_MEMFILL                      0x120B
#define CL_COMMAND_SVM_MAP                          0x120C
#define CL_COMMAND_SVM_UNMAP                        0x120D


//////////////////////////////
// OpenCL API

/* SVM Allocation APIs */
extern CL_API_ENTRY void * CL_API_CALL
clSVMAllocAltera(cl_context       /* context */,
           cl_svm_mem_flags /* flags */,
           size_t           /* size */,
           cl_uint          /* alignment */);

extern CL_API_ENTRY void CL_API_CALL
clSVMFreeAltera(cl_context        /* context */,
          void *            /* svm_pointer */);
    
extern CL_API_ENTRY cl_int CL_API_CALL
clEnqueueSVMFreeAltera(cl_command_queue  /* command_queue */,
                 cl_uint           /* num_svm_pointers */,
                 void *[]          /* svm_pointers[] */,
                 void (CL_CALLBACK * /*pfn_free_func*/)(cl_command_queue /* queue */,
                                                        cl_uint          /* num_svm_pointers */,
                                                        void *[]         /* svm_pointers[] */,
                                                        void *           /* user_data */),
                 void *            /* user_data */,
                 cl_uint           /* num_events_in_wait_list */,
                 const cl_event *  /* event_wait_list */,
                 cl_event *        /* event */);

extern CL_API_ENTRY cl_int CL_API_CALL
clEnqueueSVMMemcpyAltera(cl_command_queue  /* command_queue */,
                   cl_bool           /* blocking_copy */,
                   void *            /* dst_ptr */,
                   const void *      /* src_ptr */,
                   size_t            /* size */,
                   cl_uint           /* num_events_in_wait_list */,
                   const cl_event *  /* event_wait_list */,
                   cl_event *        /* event */);

extern CL_API_ENTRY cl_int CL_API_CALL
clEnqueueSVMMemFillAltera(cl_command_queue  /* command_queue */,
                    void *            /* svm_ptr */,
                    const void *      /* pattern */,
                    size_t            /* pattern_size */,
                    size_t            /* size */,
                    cl_uint           /* num_events_in_wait_list */,
                    const cl_event *  /* event_wait_list */,
                    cl_event *        /* event */);
    
extern CL_API_ENTRY cl_int CL_API_CALL
clEnqueueSVMMapAltera(cl_command_queue  /* command_queue */,
                cl_bool           /* blocking_map */,
                cl_map_flags      /* flags */,
                void *            /* svm_ptr */,
                size_t            /* size */,
                cl_uint           /* num_events_in_wait_list */,
                const cl_event *  /* event_wait_list */,
                cl_event *        /* event */);
    
extern CL_API_ENTRY cl_int CL_API_CALL
clEnqueueSVMUnmapAltera(cl_command_queue  /* command_queue */,
                  void *            /* svm_ptr */,
                  cl_uint           /* num_events_in_wait_list */,
                  const cl_event *  /* event_wait_list */,
                  cl_event *        /* event */);

extern CL_API_ENTRY cl_int CL_API_CALL
clSetKernelArgSVMPointerAltera (cl_kernel      /* kernel */,
                                 cl_uint        /* arg_index */,
                                 const void *   /* arg_value */);

extern CL_API_ENTRY void CL_API_CALL
clSetBoardLibraryAltera  (char* /* library_name */);

/* Image Support */

// Ignore warning about nameless union
#pragma warning( push )
#pragma warning( disable:4201 )
typedef struct _cl_image_desc {
    cl_mem_object_type      image_type;
    size_t                  image_width;
    size_t                  image_height;
    size_t                  image_depth;
    size_t                  image_array_size;
    size_t                  image_row_pitch;
    size_t                  image_slice_pitch;
    cl_uint                 num_mip_levels;
    cl_uint                 num_samples;
    union {
      cl_mem                  buffer;
      cl_mem                  mem_object;
    };
} cl_image_desc;
#pragma warning( pop )

extern CL_API_ENTRY cl_mem CL_API_CALL
clCreateImage (cl_context /* context */,
               cl_mem_flags /* flags */,
               const cl_image_format * /* image_format */,
               const cl_image_desc * /* image_desc */,
               void * /* host_ptr */,
               cl_int * /* errcode_ret */);

#define CL_MEM_OBJECT_IMAGE2D_ARRAY                 0x10F3
#define CL_MEM_OBJECT_IMAGE1D                       0x10F4
#define CL_MEM_OBJECT_IMAGE1D_ARRAY                 0x10F5
#define CL_MEM_OBJECT_IMAGE1D_BUFFER                0x10F6

#define CL_INVALID_IMAGE_DESCRIPTOR                 -65

/* Pipe Support */

typedef intptr_t            cl_pipe_properties;
typedef cl_uint             cl_pipe_info;

extern CL_API_ENTRY cl_mem CL_API_CALL
clCreatePipe(cl_context                 /* context */,
             cl_mem_flags               /* flags */,
             cl_uint                    /* pipe_packet_size */,
             cl_uint                    /* pipe_max_packets */,
             const cl_pipe_properties * /* properties */,
             cl_int *                   /* errcode_ret */);

extern CL_API_ENTRY cl_int CL_API_CALL
clGetPipeInfo(cl_mem           /* pipe */,
              cl_pipe_info     /* param_name */,
              size_t           /* param_value_size */,
              void *           /* param_value */,
              size_t *         /* param_value_size_ret */);

#define CL_MEM_OBJECT_PIPE                          0x10F7

#define CL_DEVICE_MAX_PIPE_ARGS                         0x1055
#define CL_DEVICE_PIPE_MAX_ACTIVE_RESERVATIONS          0x1056
#define CL_DEVICE_PIPE_MAX_PACKET_SIZE                  0x1057

/* cl_pipe_info */
#define CL_PIPE_PACKET_SIZE                         0x1120
#define CL_PIPE_MAX_PACKETS                         0x1121

#define CL_INVALID_PIPE_SIZE                        -69

/* ACD Support for Board Specific Functions */

extern CL_API_ENTRY void* CL_API_CALL 
clGetBoardExtensionFunctionAddressAltera(const char * /* func_name */,
                                         cl_device_id    /* device */);

#ifdef __cplusplus
}
#endif


#endif /* __CL_EXT_H */
