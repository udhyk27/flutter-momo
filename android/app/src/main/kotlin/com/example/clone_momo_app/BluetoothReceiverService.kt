//package com.oneidlab.momo
//
//import android.app.Service
//import android.content.Intent
//import android.os.IBinder
//import android.bluetooth.BluetoothAdapter
//import android.bluetooth.BluetoothServerSocket
//import android.bluetooth.BluetoothSocket
//import android.util.Log
//import java.io.InputStream
//import java.util.*
//import io.flutter.plugin.common.MethodChannel
//
//class BluetoothReceiverService : Service() {
//
//    private val CHANNEL = "com.example.watch/connection"
//    private val bluetoothAdapter: BluetoothAdapter? = BluetoothAdapter.getDefaultAdapter()
//    private var SERVER_UUID: UUID? = null  // UUID를 동적으로 설정
//
//    private val channel = MethodChannel(flutterEngine?.dartExecutor, CHANNEL)
//
//    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
//        // Intent로부터 UUID를 받아옵니다
//        SERVER_UUID = intent?.getSerializableExtra("UUID") as? UUID
//        if (SERVER_UUID != null) {
//            Log.d("WatchDebug", "#01")
//            startServer(SERVER_UUID!!)
//        } else {
//            Log.e("BluetoothReceiverService", "UUID를 찾을 수 없습니다.")
//        }
//        return START_STICKY
//    }
//
//    private fun startServer(uuid: UUID) {
//        Log.d("BluetoothReceiverService", "Bluetooth 데이터 수신 시작 (UUID: $uuid)")
//
//        try {
//            val serverSocket: BluetoothServerSocket? = bluetoothAdapter?.listenUsingRfcommWithServiceRecord("BluetoothReceiver", uuid)
//            val socket: BluetoothSocket? = serverSocket?.accept()
//
//            socket?.let {
//                val inputStream: InputStream = it.inputStream
//                receiveData(inputStream)
//                it.close()
//            }
//        } catch (e: Exception) {
//            Log.e("BluetoothReceiverService", "Bluetooth 서버 시작 실패: ${e.message}")
//        }
//    }
//
//    private fun receiveData(inputStream: InputStream) {
//        try {
//            val buffer = ByteArray(1024)
//            var bytesRead: Int
//
//            while (true) {
//                bytesRead = inputStream.read(buffer)
//                if (bytesRead == -1) break
//
//                val receivedData = buffer.copyOf(bytesRead)
//                val receivedString = String(receivedData)
//
//                Log.d("BluetoothReceiverService", "수신된 데이터: $receivedString")
//                sendDataToFlutter(receivedString)
//            }
//        } catch (e: Exception) {
//            Log.e("BluetoothReceiverService", "데이터 수신 오류: ${e.message}")
//        }
//    }
//
//    private fun sendDataToFlutter(data: String) {
//        channel.invokeMethod("onDataReceived", data)
//    }
//
//    override fun onBind(intent: Intent?): IBinder? {
//        return null
//    }
//}
