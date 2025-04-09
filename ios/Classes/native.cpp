#include "def.h"
#include "util.h"
#include "dna.h"

extern "C" __attribute__((visibility("default"))) __attribute__((used))
int pcm_to_dna(short* pcm, int count, char* dna) {
    AudioDNA q;
    q.extract(pcm, count);
    int l= q.write(dna);
    q.free();
    return l;
}