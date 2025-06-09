#ifndef _native_h__
#define _native_h__

#ifdef __cplusplus
extern "C" {
#endif

__attribute__((visibility("default"))) __attribute__((used))
void __pcm_to_dna(short* pcm, char* dna);

#ifdef __cplusplus
}
#endif

#endif
