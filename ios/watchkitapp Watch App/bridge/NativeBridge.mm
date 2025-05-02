// NativeBridge.mm
#import "NativeBridge.h"
#include "../cpp/native.h"  // C++ 함수가 정의된 파일 포함

// Swift에서 호출할 함수 정의
void __pcm_to_dna(short* pcm, unsigned char* dna) {
    cpp_pcm_to_dna(pcm, reinterpret_cast<char*>(dna));  // C++ 함수 호출
}
