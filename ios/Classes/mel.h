#ifndef __mel_h__
#define __mel_h__
typedef struct {
	float freq;
	int cidx;
	int width;
	double conv(double* fft) {
		double sum=0;
		float invW=1.f / width;
		for (int x=cidx-width, t=0; x<=cidx+width; t++, x++) {
			float w = x <= cidx ? invW*t : -invW*(t-width) + 1;
			sum += w * fft[x];
		}
		return sum;
	}
} Filter;

///////
template<int FFTN, int FREQ, int MELN>
class MEL {
	Filter m_filters[MELN];
public:
	MEL() {
		float min_freq=0.f, max_freq=FREQ/2;
		float minMelFreq = 2595. * log10(1. + min_freq / 700.);
		float maxMelFreq = 2595. * log10(1. + max_freq / 700.);
		float stepMelFreq = (maxMelFreq - minMelFreq) / (MELN + 2);
		float stepFreq = (max_freq - min_freq) / (FFTN / 2);

		Filter tmp[MELN+2];
		int i;
		for (i=0; i<MELN+2; i++) {
			float melCenter = min_freq + stepMelFreq*i;
			float tcent = 700. * (pow(10.f, melCenter/ 2595.) - 1.);

			int k = (tcent - min_freq) / stepFreq;
			float approx = min_freq + (stepFreq * k);
			if (fabs(tcent - approx) / stepFreq > 0.5)
				k++;
			tmp[i].freq = min_freq + stepFreq*k;
			tmp[i].cidx = k;
		}
		for (i=0; i<MELN; i++) {
			m_filters[i] = tmp[i+1];
			float fwidth = tmp[i+2].freq - tmp[i+1].freq;
			m_filters[i].width = fwidth / stepFreq + 0.5;
		}
	}
	void conv(double f[FFTN], double r[MELN]) {
		for (int i=0; i<MELN; i++) 
			r[i] = m_filters[i].conv(f);
	}
};
#endif // __mel_h__