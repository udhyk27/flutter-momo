package com.example.clone_momo_app

import android.app.*
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothServerSocket
import android.bluetooth.BluetoothSocket
import android.content.Context
import android.content.Intent
import android.os.*
import android.util.Log
import androidx.core.app.NotificationCompat
import java.io.InputStream
import java.util.*
import android.content.pm.PackageManager
import androidx.core.content.ContextCompat
import androidx.core.app.ActivityCompat
import android.Manifest


import okhttp3.*
import org.json.JSONObject
import java.io.IOException

import okhttp3.MediaType.Companion.toMediaType
import okhttp3.RequestBody.Companion.toRequestBody


class BluetoothService : Service() {

    companion object {
        const val CHANNEL_ID = "bluetooth_service_channel"
        const val SERVER_UUID_STR = "00001101-0000-1000-8000-00805F9B34FB"
        const val SERVICE_NAME = "WatchToPhoneBT"
    }

    private var bluetoothSocket: BluetoothSocket? = null
    private val handlerThread = HandlerThread("BluetoothServerThread")

    override fun onCreate() {
        super.onCreate()
        Log.d("PhoneDebug", "[Service] Bluetooth Service onCreate 호출됨")
        createNotificationChannel()
        startForegroundServiceNotification()

        handlerThread.start() // Bluetooth 서버 스레드 시작
        startBluetoothServer()
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null // 바인딩은 사용하지 않음
    }

    override fun onDestroy() {
        super.onDestroy()
        bluetoothSocket?.close() // Bluetooth 연결 종료
        handlerThread.quitSafely() // 스레드 안전하게 종료
        Log.d("PhoneDebug", "[Service] Bluetooth 연결 종료")
        stopForeground(true) // 서비스 알림 종료
    }

    private fun startForegroundServiceNotification() {
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("[Service] 워치 연결 대기 중")
            .setContentText("[Service] 블루투스를 통해 워치 요청을 기다리고 있습니다.")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .build()

        startForeground(1, notification)
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Bluetooth Background Service",
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager?.createNotificationChannel(channel)
        }
    }

    private fun startBluetoothServer() {
        Log.d("PhoneDebug", "[Service] 블루투스 서버 시작")

        val bluetoothAdapter = BluetoothAdapter.getDefaultAdapter()
        val serverSocket: BluetoothServerSocket =
            bluetoothAdapter.listenUsingRfcommWithServiceRecord(
                SERVICE_NAME,
                UUID.fromString(SERVER_UUID_STR)
            )

        Thread {
            try {
                Log.d("PhoneDebug", "[Service] 블루투스 연결 대기 중...")

                val socket: BluetoothSocket = serverSocket.accept()
                bluetoothSocket = socket

                Log.d("PhoneDebug", "[Service] 워치와 블루투스 연결됨!")

                val inputStream: InputStream = socket.inputStream
                val buffer = ByteArray(1024)
                val stringBuffer = StringBuilder()

                while (true) {
                    val bytesRead = inputStream.read(buffer)
                    if (bytesRead > 0) {
                        val receivedData = String(buffer, 0, bytesRead)
                        Log.d("PhoneDebug", "[Service] 받은 데이터: $receivedData")

                        stringBuffer.append(receivedData)

                        if (receivedData.trim().endsWith("}")) {
                            val completeJson = stringBuffer.toString()
                            stringBuffer.clear()

                            Log.d("PhoneDebug", "[Service] 완성된 JSON: $completeJson")

                            sendDataToServer(completeJson) // 서버에 데이터 전송
                        }
                    }
                }

            } catch (e: Exception) {
                Log.e("PhoneDebug", "[Service] 블루투스 오류: ${e.message}", e)
            }
        }.start()
    }

    // 서버와 통신
    private fun sendDataToServer(jsonString: String) {
        val client = OkHttpClient()

        val mediaType = "application/json; charset=utf-8".toMediaType()
        val requestBody = jsonString.toRequestBody(mediaType)

        val request = Request.Builder()
            .url("https://www.mo-mo.co.kr/api/getdnasong") // 실제 API URL 사용
            .post(requestBody)
            .build()

        client.newCall(request).enqueue(object : Callback {
            override fun onFailure(call: Call, e: IOException) {
                Log.e("PhoneDebug",  "[Service] 서버 통신 실패: ${e.message}")
            }

            override fun onResponse(call: Call, response: Response) {
                response.use {
                    if (!response.isSuccessful) {
                        Log.e("PhoneDebug", "[Service] 서버 응답 실패: ${response.code}")
                    } else {
                        val responseString = response.body?.string()
                        Log.d("PhoneDebug", "[Service] 서버 응답: $responseString")

                        // 서버 응답 처리 후 워치로 데이터 전송
                        sendDataToWatch(responseString ?: "Error")
                    }
                }
            }
        })
    }

    // 서버 응답을 워치로 전송
    private fun sendDataToWatch(responseString: String) {
        try {
            // BluetoothSocket의 outputStream을 사용하여 데이터를 워치로 전송
            bluetoothSocket?.let { socket ->
                val outputStream = socket.outputStream
                val dataToSend = responseString.toByteArray()

                outputStream.write(dataToSend)
                outputStream.flush()

                Log.d("PhoneDebug", "[Service] 워치로 데이터 전송 완료")
            }
        } catch (e: Exception) {
            Log.e("PhoneDebug", "[Service] 워치로 데이터 전송 실패: ${e.message}", e)
        }
    }
}
