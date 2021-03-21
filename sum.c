#include "sum.h"

int sum(int *array, int size)
{
    int sumSoFar = 0;
    int i;
    for (i = 0; i < size; i++)
    {
        sumSoFar = sumSoFar + array[i];
    }
    return sumSoFar;
}
