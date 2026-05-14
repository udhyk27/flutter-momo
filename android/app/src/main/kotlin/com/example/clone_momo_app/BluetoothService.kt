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
    private var serverSocket: BluetoothServerSocket? = null
    private val handlerThread = HandlerThread("BluetoothServerThread")
    private var isServiceRunning = false

    override fun onCreate() {
        super.onCreate()
        Log.d("PhoneDebug", "[Service] Bluetooth Service onCreate 호출됨")

        try {
            createNotificationChannel()
            startForegroundServiceNotification()

            // 1) 블루투스 어댑터 체크
            val bluetoothAdapter = BluetoothAdapter.getDefaultAdapter()
            if (bluetoothAdapter == null) {
                Log.d("PhoneDebug", "[Service] 블루투스 어댑터 없음, 서비스 종료")
                stopSelf()
                return
            }
            if (!bluetoothAdapter.isEnabled) {
                Log.d("PhoneDebug", "[Service] 블루투스 비활성화 상태, 서비스 종료")
                stopSelf()
                return
            }

            // 2) Android 12+ 블루투스 권한 체크
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                if (ContextCompat.checkSelfPermission(
                        this,
                        Manifest.permission.BLUETOOTH_CONNECT
                    ) != PackageManager.PERMISSION_GRANTED
                ) {
                    Log.d("PhoneDebug", "[Service] BLUETOOTH_CONNECT 권한 없음, 서비스 종료")
                    stopSelf()
                    return
                }
            }

            isServiceRunning = true
            handlerThread.start()
            startBluetoothServer()
        } catch (e: Exception) {
            Log.e("PhoneDebug", "[Service] onCreate 오류: ${e.message}", e)
            stopSelf()
        }
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    override fun onDestroy() {
        super.onDestroy()
        isServiceRunning = false

        try {
            bluetoothSocket?.close()
            serverSocket?.close()
        } catch (e: IOException) {
            Log.e("PhoneDebug", "[Service] 소켓 종료 오류: ${e.message}", e)
        }

        try {
            handlerThread.quitSafely()
        } catch (e: Exception) {
            Log.e("PhoneDebug", "[Service] 스레드 종료 오류: ${e.message}", e)
        }

        Log.d("PhoneDebug", "[Service] Bluetooth 연결 종료")
        stopForeground(true)
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
        if (!isServiceRunning) {
            Log.d("PhoneDebug", "[Service] 서비스가 종료된 상태, 서버 시작 중단")
            return
        }

        Log.d("PhoneDebug", "[Service] 블루투스 서버 시작")

        val bluetoothAdapter = BluetoothAdapter.getDefaultAdapter() ?: run {
            Log.e("PhoneDebug", "[Service] 블루투스 어댑터 없음")
            stopSelf()
            return
        }

        // listenUsingRfcommWithServiceRecord 자체에서 예외가 발생할 수 있으므로 안전하게 처리
        serverSocket = try {
            bluetoothAdapter.listenUsingRfcommWithServiceRecord(
                SERVICE_NAME,
                UUID.fromString(SERVER_UUID_STR)
            )
        } catch (e: SecurityException) {
            Log.e("PhoneDebug", "[Service] 블루투스 권한 오류: ${e.message}", e)
            stopSelf()
            return
        } catch (e: IOException) {
            Log.e("PhoneDebug", "[Service] 블루투스 서버 소켓 생성 오류: ${e.message}", e)
            stopSelf()
            return
        } catch (e: Exception) {
            Log.e("PhoneDebug", "[Service] 블루투스 서버 알 수 없는 오류: ${e.message}", e)
            stopSelf()
            return
        }

        Thread {
            try {
                Log.d("PhoneDebug", "[Service] 블루투스 연결 대기 중...")

                val socket: BluetoothSocket = serverSocket?.accept() ?: run {
                    Log.e("PhoneDebug", "[Service] 서버 소켓이 null")
                    return@Thread
                }
                bluetoothSocket = socket

                Log.d("PhoneDebug", "[Service] 워치와 블루투스 연결됨!")

                val inputStream: InputStream = socket.inputStream
                val buffer = ByteArray(1024)
                val stringBuffer = StringBuilder()

                while (isServiceRunning) {
                    val bytesRead = inputStream.read(buffer)
                    if (bytesRead > 0) {
                        val receivedData = String(buffer, 0, bytesRead)
                        Log.d("PhoneDebug", "[Service] 받은 데이터: $receivedData")

                        stringBuffer.append(receivedData)

                        if (receivedData.trim().endsWith("}")) {
                            // JSON 완성
                            val completeJson = stringBuffer.toString()
                            stringBuffer.clear()

                            Log.d("PhoneDebug", "[Service] 완성된 JSON: $completeJson")

                            sendDataToServer(completeJson)
                        } else if (receivedData.trim().endsWith(".getHistoryList")) {
                            Log.d("PhoneDebug", "[Service] 히스토리 요청")

                            val completeUid = receivedData.trim().removeSuffix(".getHistoryList")
                            Log.d("PhoneDebug", "정제된 UID: $completeUid")

                            stringBuffer.clear()
                            historyListServer(completeUid)
                        } else if (receivedData.trim().endsWith(".delHistoryList")) {
                            Log.d("PhoneDebug", "[Service] 히스토리 삭제 요청")

                            val completeUid = receivedData.trim().removeSuffix(".delHistoryList")
                            Log.d("PhoneDebug", "DELETE 정제된 UID: $completeUid")

                            stringBuffer.clear()
                            delHistoryList(completeUid)
                        }
                    }
                }
            } catch (e: Exception) {
                Log.e("PhoneDebug", "[Service] 블루투스 오류: ${e.message}", e)

                try {
                    serverSocket?.close()
                    bluetoothSocket?.close()
                    bluetoothSocket = null
                } catch (closeEx: IOException) {
                    Log.e("PhoneDebug", "[Service] 소켓 재시작 오류: ${closeEx.message}", closeEx)
                }

                // 서비스가 살아있을 때만 재시작
                if (isServiceRunning) {
                    try {
                        Thread.sleep(1000)
                        Log.d("PhoneDebug", "[Service] 블루투스 서버 재시작")
                        startBluetoothServer()
                    } catch (ie: InterruptedException) {
                        Log.e("PhoneDebug", "[Service] 재시작 대기 중 중단됨", ie)
                    }
                }
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

    // historyList DELETE
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

                val message = if (response.isSuccessful) "del_success" else "del_fail"
                Log.d("PhoneDebug", "히스토리 삭제 응답 코드: ${response.code}")
                response.close()

                sendDataToWatch(message)
            } catch (e: IOException) {
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
            .url("https://www.mo-mo.co.kr/api/getdnasong")
            .post(requestBody)
            .build()

        client.newCall(request).enqueue(object : Callback {
            override fun onFailure(call: Call, e: IOException) {
                Log.e("PhoneDebug", "[Service] 서버 통신 실패: ${e.message}")
            }

            override fun onResponse(call: Call, response: Response) {
                response.use {
                    if (!response.isSuccessful) {
                        Log.e("PhoneDebug", "[Service] 서버 응답 실패: ${response.code}")
                    } else {
                        val responseString = response.body?.string()
                        Log.d("PhoneDebug", "[Service] 서버 응답: $responseString")

                        sendDataToWatch(responseString ?: "Error")
                    }
                }
            }
        })
    }

    // 서버 응답을 워치로 전송
    private fun sendDataToWatch(responseString: String) {
        Log.d("PhoneDebug", "[Service] 워치로 데이터 전송 하는 sendDataToWatch 호출됨")
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