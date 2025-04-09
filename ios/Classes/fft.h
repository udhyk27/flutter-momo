#ifndef __fft_h__
#define __fft_h__


#include <math.h>
#define pi 3.141592654

template<int N>
class FFT {
public:
	void transform(short f[N], double dst[N]) {
		float f2[N];
		for (int i=0; i<N; i++)
			f2[i] = f[i];
		//hanning(f2);
		transform(f2, dst);
	}
	void transform(float f[N], double dst[N]) {
		rfft(f, N, (int)(log10(N) / log10(2))); //12
		//Re(0), Re(1), ..., Re(n/2), Im(N/2-1), ..., Im(1)
		for (int i=1; i<N/2; i++) { 
			float r = f[i];
			float m = f[N-i];
			dst[i-1] = (r*r+m*m);
		}
		dst[N/2-1] = (f[N/2]*f[N/2]);
	}
	static void hanning(float src[N]) {
		double* w = N==256? _hwnd_256 : N==512? _hwnd_512 : N==1024 ? _hwnd_1K : N==2048 ? _hwnd_2K : _hwnd_4K;
		//for (int i=0; i<N-1; i++)
		//	src[i] = w[i]*(src[i+1] - 0.97*src[i]);
		for (int i=0; i<N; i++)
			src[i] = (float)(w[i]*src[i]);
	}
private:
	void rfft(float *x, int n, int m) {
		/* OUTPUT (N=8)
		0   1	2	3	4	5	6	7
		x : r0	r1	r2	r3	r4	i3	i2	i1
		*/
		int j, i, k, is, id;
		int i0, i1, i2, i3, i4, i5, i6, i7, i8;
		int n2, n4, n8;
		float xt, a0;
		float t1, t2, t3, t4, t5, t6;
		float cc1, ss1, cc3, ss3;
		float *r0;

		/* Digit reverse counter */
		j = 0;
		r0 = x;
		for (i = 0; i < n - 1; i++) {
			if (i < j) {
				xt = x[j];
				x[j] = *r0;
				*r0 = xt;
			}
			r0++;
			k = n >> 1;
			while (k <= j) {
				j = j - k;
				k >>= 1;
			}
			j += k;
		}
		/* Length two butterflies */
		is = 0;
		id = 4;
		while (is < n - 1) {
			for (i0 = is; i0 < n; i0 += id) {
				i1 = i0 + 1;
				a0 = x[i0];
				x[i0] += x[i1];
				x[i1] = a0 - x[i1];
			}

			is = (id << 1) - 2;
			id <<= 2;
		}
		/* L shaped butterflies */
		n2 = 2;
		for (k = 1; k < m; k++) {
			n2 <<= 1;
			n4 = n2 >> 2;
			n8 = n2 >> 3;
			is = 0;
			id = n2 << 1;
			while (is < n) {
				for (i = is; i <= n - 1; i += id) {
					i1 = i;
					i2 = i1 + n4;
					i3 = i2 + n4;
					i4 = i3 + n4;
					t1 = x[i4] + x[i3];
					x[i4] -= x[i3];
					x[i3] = x[i1] - t1;
					x[i1] += t1;
					if (n4 != 1) {
						i1 += n8;
						i2 += n8;
						i3 += n8;
						i4 += n8;
						t1 = (x[i3] + x[i4]) / 1.414213562f; //*0.7071068
						t2 = (x[i3] - x[i4]) / 1.414213562f;
						x[i4] = x[i2] - t1;
						x[i3] = -x[i2] - t1;
						x[i2] = x[i1] - t2;
						x[i1] = x[i1] + t2;
					}
				}
				is = (id << 1) - n2;
				id <<= 2;
			}
			for (j = 1; j < n8; j++) {
				if (1) {
					cc1=(float)_cos_[j-1][k-3];
					ss1=(float)_sin_[j-1][k-3];
					cc3=(float)_cos3_[j-1][k-3];
					ss3=(float)_sin3_[j-1][k-3];
				}
				else {
					float e = (float)((pi * 2) / n2);
					float a = j * e;
					float a3 = 3 * a;
					cc1 = cos(a);
					ss1 = sin(a);
					cc3 = cos(a3);
					ss3 = sin(a3);
				}
				is = 0;
				id = n2 << 1;

				while (is < n) {
					for (i = is; i <= n - 1; i += id) {
						i1 = i + j;
						i2 = i1 + n4;
						i3 = i2 + n4;
						i4 = i3 + n4;
						i5 = i + n4 - j;
						i6 = i5 + n4;
						i7 = i6 + n4;
						i8 = i7 + n4;
						t1 = x[i3] * cc1 + x[i7] * ss1;
						t2 = x[i7] * cc1 - x[i3] * ss1;
						t3 = x[i4] * cc3 + x[i8] * ss3;
						t4 = x[i8] * cc3 - x[i4] * ss3;
						t5 = t1 + t3;
						t6 = t2 + t4;
						t3 = t1 - t3;
						t4 = t2 - t4;
						t2 = x[i6] + t6;
						x[i3] = t6 - x[i6];
						x[i8] = t2;
						t2 = x[i2] - t3;
						x[i7] = -x[i2] - t3;
						x[i4] = t2;
						t1 = x[i1] + t5;
						x[i6] = x[i1] - t5;
						x[i1] = t1;
						t1 = x[i5] + t4;
						x[i5] = x[i5] - t4;
						x[i2] = t1;
					}
					is = (id << 1) - n2;
					id <<= 2;
				}
			}
		}
	}
};

#endif // __fft_h__