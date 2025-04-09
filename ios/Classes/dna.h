#ifndef _dna_h__
#define _dna_h__

#include "util.h"
#include "table.h"
#include "fft.h"
#include "mel.h"

typedef struct AudioDNA {
    typedef struct __f128 {
		__int64 f[2];
	} __f128;

    __int64* H;
	__f128* F;
	int N;

	AudioDNA() { memset(this, 0, sizeof(AudioDNA)); }

	void free() {
		_Delete(H);
        _Delete(F);
	}
	int write(char* buf) {
		char* p= buf;
		memcpy(p, fpVer, 2); p+=2;
		memcpy(p, &N, 4);	p+=4;
		memcpy(p, H, N*8);  p+=N*8;
		memcpy(p, F, N*16); p+=N*16;
		return (int)(p-buf);
	}
	int extract(short* pcm, int len) {
		FFT<fftN> fft;
		static MEL<fftN/2, 16000, 64> mel;
		N= (len-fftN)/fftHop+1;
		H= new __int64[N];
		F= new __f128[N];
		for (int i=0; i<N; i++) {
			float f0[fftN];
			for (int j=0, p= i*fftHop; j<fftN; j++, p++)
				f0[j]= pcm[p];
			FFT<fftN>::hanning(f0);
			double f1[fftN];
			fft.transform(f0, f1);

			double f2[64];
			mel.conv(f1, f2);

			float f3[64];
			for (int j=0; j<64; j++) {
				double t= f2[j];
				f3[j]= (float)(10.f*log10(t+1));
			}
			for (int j=0; j<64-1; j++)
				f3[j] = (f3[j+1]-f3[j]);
			f3[63]= 0;
			_extract(f3, H[i], F[i]);
		}
		return 2+4+ 8*N+ 16*N;
	}
	void _extract(float M[64], __int64& h, __f128& f) {
		__int64 v=0;
		for (int i=0; i<64; i++) {
			v<<= 1;
			v|= M[i]>0;
		}
		h= v;
		float zt= 2;
		for (int i=0, y=0; i<2; i++) {
			__int64 v=0;
			for (int j=0; j<32; j++, y++) {
				v <<= 2;
				v |= M[y] >zt ? 2 : M[y]> -zt ? 1 : 0;
			}
			f.f[i]= v;
		}
	}
} AudioDNA;

#endif // _dna_h__
