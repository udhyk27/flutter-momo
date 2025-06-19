#ifndef dna_h__
#define dna_h__

#include "def.h"
#include "util.h"
#include "fft.h"
#include "mel.h"

typedef struct DNA {
	void to_dna(short* pcm, char* dna) {
		static MEL<fftN, srate, 64> melh;
		static MEL<fftN, srate, 128> mel;
		FFT<fftN> fft;

        float f0[fftN];
        for (int j=0; j<fftN; j++)
            f0[j]= pcm[j];
        double f1[fftN];
        fft.transform(f0, f1);
        __int64 h= _extract_h(f1, melh);
        __f128 f= _extract_f(f1, mel);
        memcpy(dna, &h, 8);
        memcpy(dna+8, &f, 16);
	}
	__int64 _extract_h(double f1[fftN], MEL<fftN, srate, 64>& mel) {
		double f2[64];
		mel.conv(f1, f2);
		float f3[64];
		for (int y=0; y<64; y++) {
			float f = (float)(10.f*log10(f2[y]+1));
			f3[y] = f;
		}
		__int64 w=0;
		for (int i=0; i<64; i++) {
			w <<= 1;
			w |= f3[i] > f3[i+1] ? 1 : 0;
		}
		return w;
	}
	__f128 _extract_f(double f1[fftN], MEL<fftN, srate, 128>& mel) {
		double f2[128];
		mel.conv(f1, f2);
		float f3[128];
		for (int y=0; y<128; y++) {
			float f = (float)(10.f*log10(f2[y]+1));
			f3[y] = f;
		}
		__f128 f;
		__int64 w=0;
		for (int i=0; i<64; i++) {
			w <<= 1;
			w |= f3[i] > f3[i+1] ? 1 : 0;
		}
		f.f[0]= w;
		w=0;
		for (int i=64; i<128-1; i++) {
			w <<= 1;
			w |= f3[i] > f3[i+1] ? 1 : 0;
		}
		f.f[1]= w;
		return f;
	}
} DNA;


#endif // dna_h__
