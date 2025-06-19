
#include "dna.h"

extern "C" __attribute__((visibility("default"))) __attribute__((used))
void __pcm_to_dna(short* pcm, char* dna) {
   DNA().to_dna(pcm, dna);
//    printf("native C++ 호출됨     ");
}
