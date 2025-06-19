#ifndef __def_h__
#define __def_h__

#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <deque>
#include <assert.h>
#include <float.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <assert.h>
#include <stack>
#include <list>
#include <algorithm>
#include <utility>
#include <functional>
#include <map>
using namespace std;


typedef unsigned int uint32;
typedef unsigned short uint16;
typedef unsigned char uint8;
typedef int64_t __int64;
typedef struct __f128 {
	__int64 f[2];
	bool is_zero() { return f[0]==0 && f[1]==0; }
} __f128;

typedef struct __f256 {
	__int64 f[4];
} __f256;

#define _In(s, x, e) ((s)<=(x) && (x)<(e))
#define _ABS(a) ((a)<=0 ? -(a) : (a))

#define _delete(p) if ((p)) { delete p; p=0; }
#define _delete2(p) if ((p)) { delete [] p; p=0; }
#define _In(s, x, e) ((s)<=(x) && (x)<(e))
#define _ABS(a) ((a)<=0 ? -(a) : (a))

#define srate 16000
#define fftN (2*1024)
#define fftHop 1000
#define Fps (srate/fftHop)
#define qLen (Fps*4)
#define qLen2 (Fps*2)

#endif 