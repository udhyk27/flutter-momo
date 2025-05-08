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

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.clone_momo_app/bluetooth"
    private val SERVER_UUID: UUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")
    private val SERVICE_NAME = "WatchToPhoneBT"
    private var methodChannel: MethodChannel? = null
    private var bluetoothSocket: BluetoothSocket? = null  // BluetoothSocket을 클래스 멤버로 선언

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        startBluetoothServer()
    }

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

            if (permissionsToRequest.isNotEmpty()) {
                ActivityCompat.requestPermissions(this, permissionsToRequest.toTypedArray(), 1001)
                return false
            }
        }
        return true
    }

    private fun startBluetoothServer() {
        Log.d("phoneKotlin", "휴대폰 코틀린 블루투스 연결 시작")

        if (!checkAndRequestBluetoothPermissions()) {
            Log.d("phoneKotlin", "휴대폰 코틀린 블루투스 권한 없음")
            return
        }

        Thread {
            try {
                val bluetoothAdapter = BluetoothAdapter.getDefaultAdapter()
                val serverSocket: BluetoothServerSocket = bluetoothAdapter.listenUsingRfcommWithServiceRecord(SERVICE_NAME, SERVER_UUID)

                Log.d("phoneKotlin", "블루투스 연결 대기 중...")

                // 연결 대기
                val socket: BluetoothSocket = serverSocket.accept()

                // 워치로부터 요청을 받으면 소켓을 열고
                bluetoothSocket = socket  // 새로운 연결을 bluetoothSocket에 저장

                Log.d("phoneKotlin", "워치와 블루투스 연결됨!")

                // 연결된 후 데이터 받기
                val inputStream: InputStream = socket.inputStream
                val buffer = ByteArray(1024)

                while (true) {
                    val bytesRead = inputStream.read(buffer)
                    if (bytesRead > 0) {
                        val receivedData = String(buffer, 0, bytesRead)
                        Log.d("phoneKotlin", "받은 데이터: $receivedData")

                        Handler(Looper.getMainLooper()).post {
                            methodChannel?.invokeMethod("onBluetoothData", receivedData)
                        }
                    }
                }

            } catch (e: Exception) {
                Log.e("phoneKotlin", "블루투스 서버 오류: ${e.message}", e)
            }
        }.start()
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)

        if (requestCode == 1001) {
            if (grantResults.all { it == PackageManager.PERMISSION_GRANTED }) {
                Log.d("phoneKotlin", "블루투스 권한 허용됨")
                startBluetoothServer()
            } else {
                Log.d("phoneKotlin", "블루투스 권한 거부됨")
            }
        }
    }
}
