// A C program to demonstrate linked list based implementation of DynamicQueue
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <linux/types.h>

#include "dynamicQueue.h"
#include "myMalloc.h"
 
// A utility function to create a new linked list node.
struct QNode* newQNode(__u32 k)
{
    #if ALIGNED
        struct QNode *temp = (struct QNode*)  my_aligned_malloc(sizeof(struct QNode));
    #else
        struct QNode *temp = (struct QNode*)  my_malloc(sizeof(struct QNode));
    #endif
    temp->key = k;
    temp->next = NULL;
    return temp; 
}
 
// A utility function to create an empty DynamicQueue
struct DynamicQueue *newDynamicQueue()
{
    #if ALIGNED
        struct DynamicQueue *q = (struct DynamicQueue*) my_aligned_malloc(sizeof(struct DynamicQueue));
    #else
        struct DynamicQueue *q = (struct DynamicQueue*) my_malloc(sizeof(struct DynamicQueue));
    #endif

    q->size = 0;
    q->front = q->rear = NULL;
    return q;
}
 
// The function to add a key k to q
void enDynamicQueue(struct DynamicQueue *q, __u32 k)
{
    // Create a new LL node
    struct QNode *temp = newQNode(k);
 
    // If DynamicQueue is empty, then new node is front and rear both
    if (q->rear == NULL)
    {
       q->front = q->rear = temp;
       return;
    }
 
    // Add the new node at the end of DynamicQueue and change rear
    q->rear->next = temp;
    q->rear = temp;
}
 
// Function to remove a key from given DynamicQueue q
struct QNode *deDynamicQueue(struct DynamicQueue *q)
{
    // If DynamicQueue is empty, return NULL.
    if (q->front == NULL)
       return NULL;
 
    // Store previous front and move front one node ahead
    struct QNode *temp = q->front;
    q->front = q->front->next;
 
    // If front becomes NULL, then change rear also as NULL
    if (q->front == NULL)
       q->rear = NULL;
    return temp;
}
 

struct QNode *frontDynamicQueue(struct DynamicQueue *q)
{
    // If DynamicQueue is empty, return NULL.
    if (q->front == NULL)
       return NULL;
 
    // Store previous front and move front one node ahead
    struct QNode *temp = q->front;
    // q->front = q->front->next;
 
    // If front becomes NULL, then change rear also as NULL
    // if (q->front == NULL)
    //    q->rear = NULL;

    return temp;
}


__u8 isEmptyDynamicQueue (struct DynamicQueue *q){

  if((q->front == NULL) && (q->rear == NULL))
    return 1;
  else
    return 0;

}