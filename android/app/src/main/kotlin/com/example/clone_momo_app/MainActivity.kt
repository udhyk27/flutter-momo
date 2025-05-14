package com.example.clone_momo_app

import android.Manifest
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothServerSocket
import android.bluetooth.BluetoothSocket
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.InputStream
import java.util.*
import android.content.Intent

import org.json.JSONObject

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.clone_momo_app/bluetooth"
    private val SERVER_UUID: UUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")
    private val SERVICE_NAME = "WatchToPhoneBT"
    private var methodChannel: MethodChannel? = null
    private var bluetoothSocket: BluetoothSocket? = null  // BluetoothSocket을 클래스 멤버로 선언

//    private var bluetoothService: BluetoothService? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)

        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "songResultResponse" -> {
                    val jsonString = call.arguments as String
//                    sendToWatchKotlin(jsonString)
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
//        startBluetoothServer()

        if (checkAndRequestBluetoothPermissions()) {
            startBluetoothService()
        }
    }

    // 블루투스 권한 확인 및 요청
    // 블루투스 권한 확인 및 요청
    private fun checkAndRequestBluetoothPermissions(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val connectPermission = ContextCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_CONNECT)
            val scanPermission = ContextCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_SCAN)

            val permissionsToRequest = mutableListOf<String>()
            if (connectPermission != PackageManager.PERMISSION_GRANTED) {
                permissionsToRequest.add(Manifest.permission.BLUETOOTH_CONNECT)
            }
            if (scanPermission != PackageManager.PERMISSION_GRANTED) {
                permissionsToRequest.add(Manifest.permission.BLUETOOTH_SCAN)
            }

            // Foreground Service 권한
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                val foregroundPermission = ContextCompat.checkSelfPermission(
                    this,
                    Manifest.permission.FOREGROUND_SERVICE_CONNECTED_DEVICE
                )
                if (foregroundPermission != PackageManager.PERMISSION_GRANTED) {
                    permissionsToRequest.add(Manifest.permission.FOREGROUND_SERVICE_CONNECTED_DEVICE)
                }
            }

            if (permissionsToRequest.isNotEmpty()) {
                ActivityCompat.requestPermissions(this, permissionsToRequest.toTypedArray(), 1001)
                return false
            }
        }
        return true
    }


    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)

        if (requestCode == 1001) {
            if (grantResults.all { it == PackageManager.PERMISSION_GRANTED }) {
                Log.d("PhoneDebug", "블루투스 권한 허용됨")
//                startBluetoothServer()
                startBluetoothService()
            } else {
                Log.d("PhoneDebug", "블루투스 권한 거부됨")
            }
        }
    }



    // 백그라운드 사용을 위해 알림, 서비스 실행
    private fun startBluetoothService() {
        val intent = Intent(this, BluetoothService::class.java)
        startForegroundService(intent)

//        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
//            startForegroundService(intent)
//        } else {
//            startService(intent)
//        }
    }

    // --------------------------------------------------------------------------------------
    // 서버와 통신 후 결과값 워치로 돌려주는 메서드
//    private fun sendToWatchKotlin(result: String) {
//        try {
//            if (bluetoothSocket != null && bluetoothSocket!!.isConnected) {
//                val outputStream = bluetoothSocket!!.outputStream
//                outputStream.write(result.toByteArray())
//                outputStream.flush()  // 버퍼 비우기 (명시적 전송)
//                Log.d("PhoneDebug", "(폰 코틀린)워치로 전송 완료: $result")
//            } else {
//                Log.e("PhoneDebug", "(폰 코틀린)워치와 블루투스 연결이 없습니다.")
//            }
//        } catch (e: Exception) {
//            Log.e("PhoneDebug", "(폰 코틀린)워치로 데이터 전송 중 오류: ${e.message}")
//        }
//    }
    // --------------------------------------------------------------------------------------
    // 워치에서 데이터 수신받아 서버로 보내는 코드

//    private fun startBluetoothServer() {
//        Log.d("PhoneDebug", "휴대폰 코틀린 블루투스 연결 시작")
//
//        if (!checkAndRequestBluetoothPermissions()) {
//            Log.d("PhoneDebug", "휴대폰 코틀린 블루투스 권한 없음")
//            return
//        }
//
//        Thread {
//            try {
//                val bluetoothAdapter = BluetoothAdapter.getDefaultAdapter()
//                val serverSocket: BluetoothServerSocket = bluetoothAdapter.listenUsingRfcommWithServiceRecord(SERVICE_NAME, SERVER_UUID)
//
//                Log.d("PhoneDebug", "블루투스 연결 대기 중...")
//
//                // 연결 대기
//                val socket: BluetoothSocket = serverSocket.accept()
//
//                // 워치로부터 요청을 받으면 소켓을 열고
//                bluetoothSocket = socket  // 새로운 연결을 bluetoothSocket에 저장
//
//                Log.d("PhoneDebug", "워치와 블루투스 연결됨!")
//
//                // 연결된 후 데이터 받기
//                val inputStream: InputStream = socket.inputStream
//                val buffer = ByteArray(1024)
//                val stringBuffer = StringBuilder() // 누적 버퍼
//
//                while (true) {
//                    val bytesRead = inputStream.read(buffer)
//                    if (bytesRead > 0) {
//                        val receivedData = String(buffer, 0, bytesRead)
//                        Log.d("PhoneDebug", "(폰 코틀린) 받은 데이터: $receivedData")
//
//                        stringBuffer.append(receivedData)
//
//                        // JSON 문자열이 완성되었는지 확인 (여기선 }로 끝나는 걸로 판별)
//                        if (receivedData.trim().endsWith("}")) {
//                            val completeJson = stringBuffer.toString()
//                            stringBuffer.clear() // 버퍼 초기화
//
//                            Log.d("PhoneDebug", "완성된 JSON: $completeJson")
//
//                            Handler(Looper.getMainLooper()).post {
//                                methodChannel?.invokeMethod("onBluetoothData", completeJson)
//                            }
//                        }
//                    }
//                }
//
//            } catch (e: Exception) {
//                Log.e("PhoneDebug", "블루투스 서버 오류: ${e.message}", e)
//            }
//        }.start()
//    }


}
