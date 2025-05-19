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
                        Log.d("PhoneDebug", "[Service] 여기까진 오류 XXXX ## 11")

                        if (receivedData.trim().endsWith("}")) {
                            // JSON 완성
                            val completeJson = stringBuffer.toString()
                            stringBuffer.clear()

                            Log.d("PhoneDebug", "[Service] 완성된 JSON: $completeJson")

                            sendDataToServer(completeJson) // 서버에 전송
                        } else if (receivedData.trim().endsWith(".getHistoryList")) {
                            Log.d("PhoneDebug", "[Service] 히스토리 요청일때만 이곳에 들어와야 함 !!!!!!")

                            val completeUid = receivedData.trim().removeSuffix(".getHistoryList")
                            Log.d("PhoneDebug", "정제된 UID: $completeUid")

                            stringBuffer.clear()
                            historyListServer(completeUid)

                        } else if (receivedData.trim().endsWith(".delHistoryList")) {
                            Log.d("PhoneDebug", "[Service] 히스토리 삭제일때만 이곳에 들어와야 함 @@@")

                            val completeUid = receivedData.trim().removeSuffix(".delHistoryList")
                            Log.d("PhoneDebug", "DELETE 정제된 UID: $completeUid")

                            stringBuffer.clear()
                            delHistoryList(completeUid)

                        }

                    }
                }

            } catch (e: Exception) {
                Log.e("PhoneDebug", "[Service] 블루투스 오류: ${e.message}", e)

                try { // 블루투스 서버 다시 시작
                    serverSocket?.close()
                    bluetoothSocket?.close()
                    bluetoothSocket = null
                } catch (closeEx: IOException) {
                    Log.e("PhoneDebug", "[Service] 소켓 재시작 오류: ${closeEx.message}", closeEx)
                }

                // 잠깐 쉬고 재시작
                Thread.sleep(1000)
                Log.d("PhoneDebug", "[Service] 블루투스 서버 재시작")
                startBluetoothServer()
            }
        }.start()
    }

    // history List 받아오는 서버통신
    private fun historyListServer(uid: String) {
        Log.d("PhoneDebug", "(Service History) 히스토리 리스트 받는 서버 메소드 호출됨")
        Thread {
            try {
                val client = OkHttpClient()
                val request = Request.Builder()
                    .url("https://www.mo-mo.co.kr/api/get_song_history/json?uid=$uid")
                    .get()
                    .build()

                val response = client.newCall(request).execute()
                if (response.isSuccessful) {
                    val responseBody = response.body?.string()
                    Log.d("PhoneDebug", "(Service History) 서버 응답 성공: $responseBody")

                    // 서버 응답을 워치로 전송
                    sendDataToWatch(responseBody ?: "No Data")
                } else {
                    Log.e("PhoneDebug", "(Service History) 서버 응답 실패: ${response.code}")
                    sendDataToWatch("Error: ${response.code}")
                }
            } catch (e: IOException) {
                Log.e("PhoneDebug", "(Service History) 서버 통신 오류", e)
                sendDataToWatch("Error: IOException")
            }
        }.start()
    }

    // hisotryList DELETE
    private fun delHistoryList(uid: String) {
        Thread {
            val client = OkHttpClient()
            val url = "https://www.mo-mo.co.kr/api/get_song_history/json?uid=$uid&proc=del"

            val request = Request.Builder()
                .url(url)
                .get()
                .build()

            try {
                val response = client.newCall(request).execute()

                // HTTP 200이면 성공
                val message = if (response.isSuccessful) "del_success" else "del_fail"
                Log.d("PhoneDebug", "히스토리 삭제 응답 코드: ${response.code}")
                response.close()

                sendDataToWatch(message)
            } catch(e: IOException) {
                Log.e("PhoneDebug", "(폰 코틀린) 히스토리 삭제 서버 통신 오류", e)
                sendDataToWatch("del_fail")
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
        Log.d("PhoneDebug", "[Service] 워치로 데이터 전송 하는 sendDataToWatch 호출됨 !!")
        Thread {
            try {
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
        }.start()
    }
}
