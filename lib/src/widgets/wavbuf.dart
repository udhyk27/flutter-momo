// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:ffi';
import 'dart:typed_data';
import 'dart:math';

class WaveBuf {
  final Uint8List _buf= Uint8List(48000*2*4);
  int _cur=0;
  bool push(Uint8List v) {
    if (_cur+v.length>_buf.length)
      return false;
    for (int i=0; i<v.length; i++, _cur++) {
      _buf[_cur]= v[i];
    }
    return true;
  }
  int pop(int n, {Uint8List? dst}) {
    n= min(n, _cur);
    if (dst!=null) {
      for (int i=0; i<n; i++)
        dst[i] = _buf[i];
    }
    int r= _cur-n;
    for (int i=0; i<r; i++)
      _buf[i]= _buf[n+i];
    _cur= r;
    return n;
  }
  int read(int n, Pointer<Uint8> p) {
    n= min(n, _cur);
    for (int i=0; i<n; i++)
      p[i]= _buf[i];
    return n;
  }
  int copy(int n, Uint8List dst) {
    n= min(n, _cur);
    for (int i=0; i<n; i++)
      dst[i]= _buf[i];
    return n;
  }
  int get length => _cur;
  void clear() => _cur=0;
}