#ifndef __util_h__
#define __util_h__

#include "def.h"
#include "table.h"
#define PI 3.141592653

#ifdef ___linux__
#define JniPath "/storage/emulated/0/Android/data/com.anomalo.watchpay_pos/files"
#else
#define JniPath "."
#endif

inline void __log(const char* lpszFormat, ...) {
    static FILE* fd_log=0;
    static char szBuffer[1024];
    if (!fd_log) {
		char path[128];
		sprintf(path, "%s/jni_log.txt", JniPath);
        if (!(fd_log=fopen(path, "w+b")))
            return;
    }
    char* p=szBuffer;

    va_list args;
    va_start(args, lpszFormat) ;
    int nBuf = vsprintf(p, lpszFormat, args);
    p += strlen(p);
    strcpy(p, "\r\n");
    fwrite(szBuffer, strlen(szBuffer), 1, fd_log);
    fflush(fd_log);
    va_end(args);
}

#define RIF(x) { if (!(x)) \
{ __log("FAILED in " #x); return 0; }}
#define JIF(x) { if (!(x)) \
{ __log("FAILED in " #x); return; }}

inline uint8 hamming_dist_32(uint32 a, uint32 b) {
	uint32 x = a^b;
	uint8 r = bitCostTable16[x & 0xffff]; x>>=16;
	return r + bitCostTable16[x & 0xffff];
}


inline int _calc_y(int x, int x0, int y0, int x1, int y1) {
	float grad = ((float)(y1-y0))/(x1-x0);
	return (x-x0)*grad + y0 + 0.5f;
}

inline char* getExtension(char* pFilePath) {
	char* p;
	for (p=pFilePath+strlen(pFilePath)-1; pFilePath<p && *p != '.'; p--);
	return *p == '.' ? p+1 : NULL;
}
inline void changeExtension(char* path, char* ext) {
	char* p = path + strlen(path) - 3;
	*p++ = *ext++;
	*p++ = *ext++;
	*p++ = *ext++;
}
inline void eraseExtension(char* path) {
	char* p = path + strlen(path) - 4;
	*p = 0;
}
inline char* fileName(char* path) {
	char* p;
	for (p=path+strlen(path)-1; path<p && *p != '/' && *p != '\\'; p--);
	return *p == '/' ? p+1 : *p == '\\' ? p+1 : p;
}
inline char* fileName2(char* path) {
	path = strdup(path);
	char* p;
	for (p = path + strlen(path) - 1; path<p && *p != '/' && *p != '\\'; p--) {
		if (*p == '.') {
			*p = 0;
			for (p--; path<p && *p != '/' && *p != '\\'; p--);
			break;
		}
	}
	return *p == '/' ? p + 1 : *p == '\\' ? p + 1 : p;
}
inline char* str_trim(char* str) {
	char* p;
	for (p=str+strlen(str)-1; str<p && (*p == ' ' || *p == '\t'); p--);
	*(p+1)=0;
	for (p=str; *p && (*p == ' ' || *p == '\t'); p++);
	return p;
}
inline char* milliToStr(int ms) {
	static char buf[128];
	int h = ms/1000/60/60;
	ms -= h*1000*60*60;
	int m = ms/1000/60;
	ms -= m*1000*60;
	int s = ms/1000;
	ms -= s*1000;
	sprintf(buf, "%d:%02d:%02d.%d", h, m, s, ms/100);
	return buf;
}
inline char* secToStr(int sec) {
	static char buf[128];
	int h = sec/60/60;
	sec -= h*60*60;
	int m = sec/60;
	sec -= m*60;
	int s = sec;
	sprintf(buf, "%d:%02d:%02d", h, m, s);
	return buf;
}
inline uint32 strToMilli(char* str) {
	int h,m,s;
	sscanf(str, "%d:%d:%d", &h, &m, &s);
	return h*3600*1000 + m*60*1000 + s*1000;
}
inline uint32 strToSec(char* str) {
	int h,m,s;
	sscanf(str, "%d:%d:%d", &h, &m, &s);
	return h*3600 + m*60 + s;
}
inline char* get_date_str() {
	static char buf[48];
	time_t timer = time(NULL);
    struct tm *t = localtime(&timer);
    sprintf(buf, "%04d-%02d-%02d %02d.%02d.%02d", 
		t->tm_year + 1900, t->tm_mon + 1, t->tm_mday, 
		t->tm_hour, t->tm_min, t->tm_sec);
	return buf;
}
inline uint32 L1Dist(uint8* x, uint8* y, int n) {
	uint32 s=0;
	for (int i=0; i<n; i++)
		s += abs(x[i]-y[i]);
	return s;
}
inline int calc_itvl(int s0, int e0, int s1, int e1) {
	int max_s = max(s0, s1);
	int min_e = min(e0, e1);
	return max_s-min_e-1;
}
inline int calc_union(int s0, int e0, int s1, int e1) {
	int max_e = max(e0, e1);
	int min_s = min(s0, s1);
	return max_e-min_s+1;
}
inline int read_int32(uint8* p) {
	int n = *p++;
	n = (n << 8) | *p++;
	n = (n << 8) | *p++;
	n = (n << 8) | *p++;
	return n;
}
inline void write_int32(char* p, int n) {
	p[0] = (n>>24) & 0xff;
	p[1] = (n>>16) & 0xff;
	p[2] = (n>>8) & 0xff;
	p[3] = n & 0xff;
}
inline bool is_overlap(int s0, int e0, int s1, int e1) {
	int min_e = min(e0, e1);
	int max_s = max(s0, s1);
	return max_s <= min_e;
}

template<class T>
inline float average(T* v, int s, int e) {
	float u=0;
	for (int i=s; i<e; i++)
		u += v[i];
	return u/(e-s);
}
template<class T>
inline T summation(T* v, int s, int e) {
	T u=0;
	for (int i=s; i<e; i++)
		u += v[i];
	return u;
}
inline double average_f(double* v, int s, int e) {
	double u=0;
	for (int i=s; i<e; i++)
		u += v[i];
	return u/(e-s);
}
template<class T>
inline float getmetric_mean(T* v, int s, int e) {
	double u=0;
	double pw = 1.0 / (e-s);
	for (int i=s; i<e; i++)
		u *= pow(v[i], pw);
	return pw;
}
template<class T>
inline T maximum(T* v, int s, int e) {
	T maxV=0;
	for (int i=s; i<e; i++) {
		if (maxV < v[i])
			maxV=v[i];
	}
	return maxV;
}
template<class T>
inline T minimum(T* v, int s, int e) {
	T minV=v[0];
	for (int i=s; i<e; i++) {
		if (minV > v[i])
			minV=v[i];
	}
	return minV;
}
template<class T>
inline double std_dev(T* v, int s, int e) {
	double u=0;
	for (int i=s; i<e; i++)
		u += v[i];
	u /= (e-s);
	double sd=0;
	for (int i=s; i<e; i++)
		sd += pow(v[i]-u, 2);
	return sqrt(sd/(e-s));
}

template<class T>
inline void veccat(vector<T>& v, vector<T>& u) {
	for (int i=0; i<u.size(); i++)
		v.push_back(u[i]);
}
template<class T>
inline int vecmax(vector<T>& v) {
	T maxV=0, p;
	for (int i=0; i<v.size(); i++) {
		if (maxV < v[i])
			p=i, maxV=v[i];
	}
	if (p<v.size()-2 && v[p]==v[p+1] && v[p]==v[p+2])
		p++;
	return p;
}
template<class T>
inline int vecmax(vector<T>& v, int s, int e) {
	T maxV=0, p;
	for (int i=s; i<e; i++) {
		if (maxV < v[i])
			p=i, maxV=v[i];
	}
	if (p<v.size()-2 && v[p]==v[p+1] && v[p]==v[p+2])
		p++;
	return p;
}
template<class T>
inline float vecavg(vector<T>& v) {
	float sum=0;
	for (int i=0; i<v.size(); i++)
		sum += v[i];
	return (float)sum/v.size();
}
template<class T>
inline float vecavg(vector<T>& v, int s, int e) {
	float sum=0;
	for (int i=s; i<e; i++)
		sum += v[i];
	return (float)sum/(e-s);
}
template<class T>
inline void vecrem(vector<T>& v, T& u) {
	for (int i=0; i<v.size(); i++) {
		if (v[i] == u)
			v.erase(v.begin()+i);
	}
}
template<class T>
inline int vecfind(vector<T>& v, T& u) {
	for (int i=0; i<v.size(); i++) {
		if (v[i] == u)
			return i;
	}
	return -1;
}

template<class T>
class sortE {
public:
	T val;
	uint32 idx, idx2;
	bool operator<=(const sortE& x) const { return val <= x.val; }
	bool operator>=(const sortE& x) const { return val >= x.val; }
	bool operator< (const sortE& x) const { return val <  x.val; }
	bool operator> (const sortE& x) const { return val >  x.val; }
	bool operator==(const sortE& x) const { return val==x.val; }
};
template<class T>
class usortE {
public:
	T val;
	uint32 idx, idx2;
	bool operator<=(const usortE& x) const { return val >= x.val; }
	bool operator>=(const usortE& x) const { return val <= x.val; }
	bool operator< (const usortE& x) const { return val >  x.val; }
	bool operator> (const usortE& x) const { return val <  x.val; }
	bool operator==(const usortE& x) const { return val==x.val; }
};
typedef struct {
	int i, j;
} Pair;


#endif 