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

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

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
    }

}
