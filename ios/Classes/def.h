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

#define _In(s, x, e) ((s)<=(x) && (x)<(e))
#define _ABS(a) ((a)<=0 ? -(a) : (a))

#define _Delete(p) if ((p)) { delete p; p=0; }
#define _Delete2(p) if ((p)) { delete [] p; p=0; }
#define _In(s, x, e) ((s)<=(x) && (x)<(e))
#define _ABS(a) ((a)<=0 ? -(a) : (a))


#define fpVer "vi"
#define srate 22050
#define fftN 2048
#define fftHop 1470
#define Fps (srate/fftHop) //15
#define qLen (37)

#endif 