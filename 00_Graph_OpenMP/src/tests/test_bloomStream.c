#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>


#include "bloomStream.h"

int numThreads;

int main(int argc, char *argv[])
{


	__u32 i;
	__u32 size = 3355;
	__u32 found = 0;
	__u32 falsepos =0;
	printf("%s\n", "Create bloomStream" );
	struct BloomStream * bloomStream = newBloomStream(size,4);


	for(i=0; i < 10 ; i++ ){

	 addToBloomStream(bloomStream,i);

	}

	for(i=0; i < 15 ; i++ ){

	 addToBloomStream(bloomStream,i);

	}

	for(i=0; i < 20 ; i++ ){

	 addToBloomStream(bloomStream,i);

	}

	for(i=0; i < 25 ; i++ ){

	 addToBloomStream(bloomStream,i);

	}

	for(i=0; i < 10 ; i++ ){

	 addToBloomStream(bloomStream,i);

	}

	for(i=0; i < 10 ; i++ ){

	 addToBloomStream(bloomStream,i);

	}

	for(i=0; i < 10 ; i++ ){

	 addToBloomStream(bloomStream,i);

	}

	for(i=0; i<25 ; i++ ){

		found = findInBloomStream(bloomStream,i);


		
	}


	printf("%.24f \n", (falsepos/(float)size) );

	printf("%s\n", "free BloomStream" );
	freeBloomStream(bloomStream);




	return 0;	

}