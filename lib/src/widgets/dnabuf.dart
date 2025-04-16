// ignore_for_file: prefer_const_constructors, avoid_print, curly_braces_in_flow_control_structures, avoid_single_cascade_in_expression_statements

import 'dart:ffi';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';

final DynamicLibrary nativeLib = Platform.isAndroid
    ? DynamicLibrary.open("libnative.so")
    : DynamicLibrary.process();
void Function(Pointer<Int16>, Pointer<Uint8>) __pcm_to_dna = nativeLib
    .lookup<
    NativeFunction<
        Void Function(
            Pointer<Int16>, Pointer<Uint8>)>>("__pcm_to_dna")
    .asFunction();

const bufLen= 500;

class DnaBuf {
  int _cur=0;
  final Uint8List H= Uint8List(bufLen*8);
  final Uint8List F= Uint8List(bufLen*16);
  final Pointer<Uint8> _frame = malloc.allocate<Uint8>(24);
  int get length => _cur;

  void clear() { _cur=0; }

  void push(Pointer<Uint8> pcm) {

    print('DNA buf push 하는 중');
    __pcm_to_dna(pcm.cast<Int16>(), _frame.cast<Uint8>());

    print('DNA 형 변환 완료');


    for (int i=0; i<8; i++)
      H[_cur*8+i] = _frame[i];
    for (int i=0; i<16; i++)
      F[_cur*16+i]= _frame[8+i];
    _cur++;
  }
  void pop(int n) {
    n= min(n, _cur);
    int r= _cur-n;
    H.setRange(0, r*8, H, n*8);
    F.setRange(0, r*16, F, n*16);
    _cur= r;
  }
  Uint8List pack() {
    Uint8List dna32= Uint8List(_cur*24);
    for (int i=0; i<_cur*8; i++)
      dna32[i]= H[i];
    int p= _cur*8;
    for (int i=0; i<_cur*16; i++)
      dna32[p+i]= F[i];
    return dna32;
  }
}