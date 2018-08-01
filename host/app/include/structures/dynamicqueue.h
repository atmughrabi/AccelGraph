#ifndef DYNAMICQUEUE_H
#define DYNAMICQUEUE_H



// A linked list (LL) node to store a queue entry
struct QNode
{
    int key;
    struct QNode *next;
};
 
// The queue, front stores the front node of LL and rear stores ths
// last node of LL
struct Queue
{
    struct QNode *front, *rear;
};
 
// A utility function to create a new linked list node.
struct QNode* newNode(int k);

 
// A utility function to create an empty queue
struct Queue *createQueue();

 
// The function to add a key k to q
void enQueue(struct Queue *q, int k);

 
// Function to remove a key from given queue q
struct QNode *deQueue(struct Queue *q);

#endif