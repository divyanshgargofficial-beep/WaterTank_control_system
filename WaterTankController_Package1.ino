
  #include <ESP8266WiFi.h>
  #include <ESP8266WebServer.h>
  #include <ESP8266HTTPClient.h>
  #include <WiFiClientSecure.h>
  #include <EEPROM.h>

  #define RELAY_PIN 5
  #define LED_PIN 2

  const char* ssid = "Airtel_divy_7892_2.4Ghz";
  const char* password = "air72986";

  const char* firmwareVersion = "1.2.0-separated-local-cloud";
  const char* deviceId = "package-1";
  const char* deviceName = "Home Water Tank";
  const char* deviceToken = "tank-controller-2026-secret-7Hk9LmP2";
  const char* cloudBaseUrl = "https://water-tank-cloud-backend.onrender.com";
  const char* cloudHost = "water-tank-cloud-backend.onrender.com";

  IPAddress local_IP(192,168,1,13);
  IPAddress gateway(192,168,1,1);
  IPAddress subnet(255,255,255,0);
  IPAddress dns1(8,8,8,8);
  IPAddress dns2(1,1,1,1);

  ESP8266WebServer server(80);


  bool pumpRunning = false;
  bool tankFull = false;
  bool lockout = false;

  unsigned long sessionStartMillis = 0;
  unsigned long currentRuntimeSeconds = 0;
  unsigned long totalRuntimeSeconds = 0;
  unsigned long lastCloudCommandMillis = 0;
  unsigned long lastCloudStatusMillis = 0;
  unsigned long cloudBackoffUntilMillis = 0;
  unsigned long cloudBackoffSeconds = 1;
  unsigned long lastLocalRequestMillis = 0;
  unsigned long localCommandHoldoffUntilMillis = 0;
  unsigned long lastWiFiAttemptMillis = 0;
  unsigned long lastDiagnosticsMillis = 0;
  unsigned long lastCloudHttpDiagnosticsMillis = 0;
  unsigned long lastCloudWorkMillis = 0;
  unsigned long lastCloudCommandAttemptMillis = 0;
  unsigned long lastYieldMillis = 0;
  unsigned long ledBlinkLastMillis = 0;
  uint8_t wifiReconnectAttempts = 0;
  uint8_t ledBlinkTransitionsRemaining = 0;
  bool cloudOnline = false;
  bool forceCloudStatusUpload = false;
  bool wifiConnectedReported = false;
  bool serverStarted = false;
  bool ledBlinkActive = false;
  bool ledBlinkOn = false;
  bool pendingCloudAck = false;
  bool pendingCloudAckSuccess = false;
  int lastCloudCommandStatusCode = 0;
  int lastCloudStatusCode = 0;
  int lastCloudAckStatusCode = 0;
  String pendingCloudAckCommandId = "";
  String pendingCloudAckMessage = "";
  String lastCloudCommandPayload = "";

  const unsigned long wifiReconnectIntervalMs = 10000UL;
  const unsigned long diagnosticsIntervalMs = 30000UL;
  const unsigned long cloudHttpTimeoutMs = 1200UL;
  const unsigned long localPriorityWindowMs = 5000UL;
  const unsigned long cloudWorkGapMs = 350UL;

  void cloudLog(String message)
  {
    Serial.println("[CloudSync] " + message);
  }

  void addCorsHeaders()
  {
    server.sendHeader("Access-Control-Allow-Origin", "*");
    server.sendHeader("Access-Control-Allow-Methods", "GET,POST,OPTIONS");
    server.sendHeader("Access-Control-Allow-Headers", "Content-Type,Accept");
    server.sendHeader("Connection", "close");
    server.sendHeader("Cache-Control", "no-store");
  }

  void sendJson(int code, String body)
  {
    server.client().setNoDelay(true);
    addCorsHeaders();
    server.send(code, "application/json", body);
    yield();
  }

  String httpMethodName()
  {
    switch(server.method())
    {
      case HTTP_GET: return "GET";
      case HTTP_POST: return "POST";
      case HTTP_OPTIONS: return "OPTIONS";
      case HTTP_PUT: return "PUT";
      case HTTP_DELETE: return "DELETE";
      default: return "OTHER";
    }
  }

  void logServerRequest(String route)
  {
    lastLocalRequestMillis = millis();
    Serial.println("[HTTP] " + httpMethodName() + " " + route
                   + " from=" + server.client().remoteIP().toString()
                   + " freeHeap=" + String(ESP.getFreeHeap()));
  }

  bool shouldPrioritizeLocal()
  {
    unsigned long now = millis();
    return now - lastLocalRequestMillis < localPriorityWindowMs ||
           now < localCommandHoldoffUntilMillis;
  }

  void holdCloudForLocalCommand(String reason)
  {
    localCommandHoldoffUntilMillis = millis() + localPriorityWindowMs;
    cloudLog("local holdoff reason=" + reason
             + " untilMs=" + String(localCommandHoldoffUntilMillis));
  }

  void queueCloudStatusUpload(String reason)
  {
    forceCloudStatusUpload = true;
    cloudLog("queue status reason=" + reason
             + " pump=" + String(pumpRunning ? "true" : "false")
             + " tankFull=" + String(tankFull ? "true" : "false")
             + " lockout=" + String(lockout ? "true" : "false"));
  }

  void queueCloudAck(String commandId, bool success, String message)
  {
    if(commandId.length() == 0)
    {
      cloudLog("queue ack skipped: empty command id");
      return;
    }

    pendingCloudAck = true;
    pendingCloudAckSuccess = success;
    pendingCloudAckCommandId = commandId;
    pendingCloudAckMessage = message;
    cloudLog("queue ack commandId=" + commandId
             + " success=" + String(success ? "true" : "false")
             + " message=" + message);
  }

  void saveRuntime()
  {
    EEPROM.put(0, totalRuntimeSeconds);
    EEPROM.commit();
  }

  void loadRuntime()
  {
    EEPROM.get(0, totalRuntimeSeconds);
    if (totalRuntimeSeconds > 315360000UL) totalRuntimeSeconds = 0;
  }

  void blinkLed()
  {
    ledBlinkActive = true;
    ledBlinkOn = false;
    ledBlinkTransitionsRemaining = 10;
    ledBlinkLastMillis = 0;
  }

  void updateBlinkLed()
  {
    if(!ledBlinkActive) return;
    if(ledBlinkLastMillis != 0 && millis() - ledBlinkLastMillis < 200UL) return;
    ledBlinkLastMillis = millis();
    ledBlinkOn = !ledBlinkOn;
    digitalWrite(LED_PIN, ledBlinkOn ? LOW : HIGH);
    if(ledBlinkTransitionsRemaining > 0) ledBlinkTransitionsRemaining--;
    if(ledBlinkTransitionsRemaining == 0)
    {
      ledBlinkActive = false;
      ledBlinkOn = false;
      digitalWrite(LED_PIN, HIGH);
    }
  }

  void writePump(bool running)
  {
    if(running && !pumpRunning)
    {
      sessionStartMillis = millis();
      currentRuntimeSeconds = 0;
    }

    if(!running && pumpRunning)
    {
      currentRuntimeSeconds =
        (millis() - sessionStartMillis) / 1000UL;

      totalRuntimeSeconds += currentRuntimeSeconds;
      saveRuntime();
    }

    digitalWrite(RELAY_PIN, running ? LOW : HIGH);
    pumpRunning = running;
  }

  String formatTime(unsigned long sec)
  {
    char buf[20];
    sprintf(buf,"%02lu:%02lu:%02lu",
            sec/3600,
            (sec%3600)/60,
            sec%60);
    return String(buf);
  }

  String jsonStatus()
  {
    unsigned long current =
      pumpRunning ? (millis()-sessionStartMillis)/1000UL
                  : currentRuntimeSeconds;

    String s="{";
    s+="\"pumpRunning\":" + String(pumpRunning?"true":"false");
    s+=",\"tankFull\":" + String(tankFull?"true":"false");
    s+=",\"lockout\":" + String(lockout?"true":"false");
    s+=",\"currentRuntimeSeconds\":" + String(current);
    s+=",\"totalRuntimeSeconds\":" + String(totalRuntimeSeconds);
    s+=",\"wifiConnected\":" + String(WiFi.status()==WL_CONNECTED?"true":"false");
    s+=",\"firmwareVersion\":\"" + String(firmwareVersion) + "\"";
    s+=",\"cloudOnline\":" + String(cloudOnline?"true":"false");
    s+=",\"lastCloudCommandStatusCode\":" + String(lastCloudCommandStatusCode);
    s+=",\"lastCloudStatusCode\":" + String(lastCloudStatusCode);
    s+=",\"lastCloudAckStatusCode\":" + String(lastCloudAckStatusCode);
    s+=",\"lastCloudCommandAgeMs\":" + String(lastCloudCommandAttemptMillis == 0 ? 0 : millis() - lastCloudCommandAttemptMillis);
    s+="}";
    return s;
  }

  String cloudStatusJson()
  {
    unsigned long current =
      pumpRunning ? (millis()-sessionStartMillis)/1000UL
                  : currentRuntimeSeconds;

    String s="{";
    s+="\"deviceId\":\"" + String(deviceId) + "\"";
    s+=",\"deviceName\":\"" + String(deviceName) + "\"";
    s+=",\"firmwareVersion\":\"" + String(firmwareVersion) + "\"";
    s+=",\"pumpRunning\":" + String(pumpRunning?"true":"false");
    s+=",\"tankFull\":" + String(tankFull?"true":"false");
    s+=",\"lockout\":" + String(lockout?"true":"false");
    s+=",\"runtime\":" + String(current);
    s+=",\"totalRuntime\":" + String(totalRuntimeSeconds);
    s+=",\"wifiRSSI\":" + String(WiFi.RSSI());
    s+=",\"ipAddress\":\"" + WiFi.localIP().toString() + "\"";
    s+="}";
    return s;
  }

  void handleApiStatus()
  {
    logServerRequest("/api/status");
    sendJson(200, jsonStatus());
  }

  void handleOn()
  {
    logServerRequest(server.uri());
    if(lockout)
    {
      sendJson(423, "{\"error\":\"lockout\"}");
      return;
    }
    tankFull=false;
    writePump(true);
    holdCloudForLocalCommand("local pump on");
    sendJson(200, "{\"success\":true}");
  }

  void handleOff()
  {
    logServerRequest(server.uri());
    writePump(false);
    tankFull=true;
    lockout=true;
    blinkLed();
    holdCloudForLocalCommand("local tank full");
    queueCloudStatusUpload("local tank full");
    sendJson(200, "{\"success\":true}");
  }

  void handleReset()
  {
    logServerRequest(server.uri());
    lockout=false;
    tankFull=false;
    holdCloudForLocalCommand("local reset");
    sendJson(200, "{\"success\":true}");
  }

  void markCloudSuccess()
  {
    if(!cloudOnline) cloudLog("online");
    cloudOnline = true;
    cloudBackoffSeconds = 1;
    cloudBackoffUntilMillis = 0;
  }

  void markCloudFailure()
  {
    if(cloudOnline) cloudLog("offline");
    cloudOnline = false;
    cloudBackoffSeconds = min(cloudBackoffSeconds + 2UL, 30UL);
    cloudBackoffUntilMillis = millis() + (cloudBackoffSeconds * 1000UL);
    cloudLog("failure; backoff seconds=" + String(cloudBackoffSeconds));
  }

  bool cloudReady()
  {
    return WiFi.status() == WL_CONNECTED && millis() >= cloudBackoffUntilMillis;
  }

  void addCloudHeaders(HTTPClient& http)
  {
    http.addHeader("Content-Type", "application/json");
    http.addHeader("Accept", "application/json");
    http.addHeader("X-Device-Id", deviceId);
    http.addHeader("X-Device-Token", deviceToken);
  }

  void logCloudHttpDiagnostics(String label, String url)
  {
    if(millis() - lastCloudHttpDiagnosticsMillis < diagnosticsIntervalMs)
    {
      cloudLog(label + " url=" + url);
      return;
    }
    lastCloudHttpDiagnosticsMillis = millis();

    IPAddress resolvedIp;
    bool resolved = WiFi.hostByName(cloudHost, resolvedIp);

    cloudLog(label + " url=" + url);

    cloudLog(label + " wifi localIP=" + WiFi.localIP().toString()
            + " gateway=" + WiFi.gatewayIP().toString()
            + " dns=" + WiFi.dnsIP().toString()
            + " rssi=" + String(WiFi.RSSI()));

    cloudLog(label + " dns host=" + String(cloudHost)
            + " resolved=" + String(resolved ? "true" : "false")
            + " ip=" + (resolved ? resolvedIp.toString() : String("0.0.0.0")));

    cloudLog(label + " freeHeap=" + String(ESP.getFreeHeap()));

    cloudLog(label + " WiFiClientSecure=fresh instance reuse=false");
  }

  void logCloudHttpResult(String label, HTTPClient& http, int status)
  {
    if(status < 0)
    {
      cloudLog(label + " error=" + http.errorToString(status));
    }
  }

  String extractJsonValue(String json, String key)
  {
    String needle = "\"" + key + "\":\"";
    int start = json.indexOf(needle);
    if(start < 0) return "";
    start += needle.length();
    int end = json.indexOf("\"", start);
    if(end < 0) return "";
    return json.substring(start, end);
  }

  bool processPendingCloudAck()
  {
    if(!pendingCloudAck || !cloudReady())
    {
      return false;
    }

    WiFiClientSecure client;
    client.setInsecure();
    client.setTimeout(cloudHttpTimeoutMs);
   

    HTTPClient http;
    http.setReuse(false);
    http.useHTTP10(true);
    http.setTimeout(cloudHttpTimeoutMs);
    String url = String(cloudBaseUrl) + "/device/ack";
    cloudLog("POST " + url + " commandId=" + pendingCloudAckCommandId
             + " success=" + String(pendingCloudAckSuccess ? "true" : "false"));
    logCloudHttpDiagnostics("ACK", url);
    bool began = http.begin(client, url); 
    cloudLog("ACK begin=" + String(began ? "true" : "false"));
    if(!began)
    {
      cloudLog("ack begin failed");
      client.stop();
      return true;
    }
    addCloudHeaders(http);
    String body="{";
    body+="\"deviceId\":\"" + String(deviceId) + "\"";
    body+=",\"commandId\":\"" + pendingCloudAckCommandId + "\"";
    body+=",\"success\":" + String(pendingCloudAckSuccess ? "true" : "false");
    body+=",\"message\":\"" + pendingCloudAckMessage + "\"";
    body+="}";
    int code = http.POST(body);
    lastCloudAckStatusCode = code;
    server.handleClient();
    yield();
    cloudLog("ACK status=" + String(code));
    logCloudHttpResult("ACK", http, code);
    http.end();
    client.stop();
    if(code >= 200 && code < 300)
    {
      pendingCloudAck = false;
      pendingCloudAckCommandId = "";
      pendingCloudAckMessage = "";
      markCloudSuccess();
    }
    else
    {
      markCloudFailure();
    }
    return true;
  }

  void executeCloudCommand(String commandId, String command)
  {
    cloudLog("execute commandId=" + commandId + " command=" + command);
    if(command == "PUMP_ON" || command == "ON")
    {
      if(lockout)
      {
        cloudLog("PUMP_ON blocked by lockout");
        queueCloudAck(commandId, false, "lockout");
        queueCloudStatusUpload("cloud pump on blocked");
        return;
      }
      tankFull = false;
      cloudLog("calling writePump(true)");
      writePump(true);
      queueCloudAck(commandId, true, "pump started");
      queueCloudStatusUpload("cloud pump on");
      return;
    }

    if(command == "PUMP_OFF" || command == "OFF")
    {
      cloudLog("calling writePump(false)");
      writePump(false);
      tankFull = true;
      lockout = true;
      blinkLed();
      queueCloudAck(commandId, true, "pump stopped");
      queueCloudStatusUpload("cloud pump off");
      return;
    }

    if(command == "RESET_LOCKOUT" || command == "RESET")
    {
      cloudLog("resetting lockout");
      lockout = false;
      tankFull = false;
      queueCloudAck(commandId, true, "lockout reset");
      queueCloudStatusUpload("cloud reset");
      return;
    }

    if(command.length() > 0 && command != "NONE")
    {
      cloudLog("unknown command=" + command);
      queueCloudAck(commandId, false, "unknown command");
    }
  }

  bool pollCloudCommand()
  {
    if(!cloudReady()) return false;
    if(millis() - lastCloudCommandMillis < 2000UL) return false;
    lastCloudCommandMillis = millis();
    lastCloudCommandAttemptMillis = lastCloudCommandMillis;

    WiFiClientSecure client;
    client.setInsecure();
    client.setTimeout(cloudHttpTimeoutMs);
    

    HTTPClient http;
    http.setReuse(false);
    http.useHTTP10(true);
    http.setTimeout(cloudHttpTimeoutMs);
    String url = String(cloudBaseUrl) + "/device/command?deviceId=" + String(deviceId);
    cloudLog("GET " + url);
    logCloudHttpDiagnostics("COMMAND", url);
    bool began = http.begin(client, url);
    cloudLog("COMMAND begin=" + String(began ? "true" : "false"));
    if(!began)
    {
      cloudLog("command begin failed");
      markCloudFailure();
      client.stop();
      return true;
    }
    addCloudHeaders(http);
    int code = http.GET();
    lastCloudCommandStatusCode = code;
    server.handleClient();
    yield();
    String response = http.getString();
    lastCloudCommandPayload = response;
    cloudLog("COMMAND status=" + String(code) + " response=" + response);
    logCloudHttpResult("COMMAND", http, code);
    if(code >= 200 && code < 300)
    {
      markCloudSuccess();
      String command = extractJsonValue(response, "command");
      String commandId = extractJsonValue(response, "commandId");
      cloudLog("parsed commandId=" + commandId + " command=" + command);
      executeCloudCommand(commandId, command);
    }
    else
    {
      markCloudFailure();
    }
    http.end();
    client.stop();
    return true;
  }

  bool postCloudStatus()
  {
    if(!cloudReady()) return false;
    bool periodicDue = millis() - lastCloudStatusMillis >= 10000UL;
    if(!forceCloudStatusUpload && !periodicDue) return false;
    lastCloudStatusMillis = millis();

    WiFiClientSecure client;
    client.setInsecure();
    client.setTimeout(cloudHttpTimeoutMs);
    

    HTTPClient http;
    http.setReuse(false);
    http.useHTTP10(true);
    http.setTimeout(cloudHttpTimeoutMs);
    String url = String(cloudBaseUrl) + "/device/status";
    String body = cloudStatusJson();
    cloudLog("POST " + url + " body=" + body);
    logCloudHttpDiagnostics("STATUS", url);
    bool began = http.begin(client, url);
    cloudLog("STATUS begin=" + String(began ? "true" : "false"));
    if(!began)
    {
      cloudLog("status begin failed");
      markCloudFailure();
      client.stop();
      return true;
    }
    addCloudHeaders(http);
    int code = http.POST(body);
    lastCloudStatusCode = code;
    server.handleClient();
    yield();
    cloudLog("STATUS status=" + String(code));
    logCloudHttpResult("STATUS", http, code);
    if(code >= 200 && code < 300)
    {
      forceCloudStatusUpload = false;
      markCloudSuccess();
    }
    else
    {
      markCloudFailure();
    }
    http.end();
    client.stop();
    return true;
  }

  void syncCloud()
  {
    if(shouldPrioritizeLocal()) return;
    if(millis() - lastCloudWorkMillis < cloudWorkGapMs) return;
    if(processPendingCloudAck())
    {
      lastCloudWorkMillis = millis();
      return;
    }
    if(pollCloudCommand())
    {
      lastCloudWorkMillis = millis();
      return;
    }
    if(postCloudStatus())
    {
      lastCloudWorkMillis = millis();
      return;
    }
  }

  void handleDashboard()
  {
    logServerRequest("/");
    unsigned long current =
      pumpRunning ? (millis()-sessionStartMillis)/1000UL
                  : currentRuntimeSeconds;

    String html="<!DOCTYPE html><html><head><meta name='viewport' content='width=device-width,initial-scale=1'>";
    html+="<meta http-equiv='refresh' content='1'>";
    html+="<style>body{font-family:Arial;background:#111827;color:white;text-align:center;}";
    html+=".card{background:#1f2937;margin:12px;padding:20px;border-radius:16px;}";
    html+="button{width:220px;height:60px;font-size:20px;margin:8px;border-radius:12px;}</style></head><body>";
    html+="<h1>Water Tank Controller</h1>";
    html+="<div class='card'><h2>Pump: "+String(pumpRunning?"ON":"OFF")+"</h2>";
    html+="<h3>Tank Full: "+String(tankFull?"YES":"NO")+"</h3>";
    html+="<h3>Lockout: "+String(lockout?"ACTIVE":"INACTIVE")+"</h3>";
    html+="<h3>Current Runtime: "+formatTime(current)+"</h3>";
    html+="<h3>Total Runtime: "+formatTime(totalRuntimeSeconds)+"</h3></div>";
    html+="<a href='/on'><button>START PUMP</button></a><br>";
    html+="<a href='/off'><button>STOP PUMP</button></a><br>";
    html+="<a href='/reset'><button>RESET LOCKOUT</button></a>";
    html+="</body></html>";
    server.client().setNoDelay(true);
    addCorsHeaders();
    server.send(200,"text/html",html);
    yield();
  }

  void handleOptions()
  {
    logServerRequest(server.uri());
    server.client().setNoDelay(true);
    addCorsHeaders();
    server.send(204, "text/plain", "");
    yield();
  }

  void handleNotFound()
  {
    logServerRequest(server.uri());
    if(server.method() == HTTP_OPTIONS)
    {
      handleOptions();
      return;
    }
    sendJson(404, "{\"error\":\"not_found\"}");
  }

  void printHeapDiagnostics(String label)
  {
    Serial.println("[Heap] " + label
                   + " free=" + String(ESP.getFreeHeap())
                   + " maxBlock=" + String(ESP.getMaxFreeBlockSize())
                   + " fragmentation=" + String(ESP.getHeapFragmentation()) + "%");
  }

  void printWiFiDiagnostics(String label)
  {
    Serial.println("[WiFi] " + label
                   + " mode=" + String(WiFi.getMode())
                   + " status=" + String(WiFi.status())
                   + " ssid=" + String(ssid)
                   + " ip=" + WiFi.localIP().toString()
                   + " gateway=" + WiFi.gatewayIP().toString()
                   + " subnet=" + WiFi.subnetMask().toString()
                   + " dns=" + WiFi.dnsIP().toString()
                   + " rssi=" + String(WiFi.RSSI())
                   + " attempts=" + String(wifiReconnectAttempts));
  }

  void printDnsDiagnostics()
  {
    IPAddress resolvedIP;
    bool resolved = WiFi.hostByName(cloudHost, resolvedIP);
    Serial.println("[DNS] host=" + String(cloudHost)
                   + " resolved=" + String(resolved ? "true" : "false")
                   + " ip=" + (resolved ? resolvedIP.toString() : String("0.0.0.0")));
  }

  void configureWiFi()
  {
    WiFi.persistent(false);
    WiFi.mode(WIFI_STA);
    WiFi.setAutoReconnect(true);
    WiFi.hostname("water-tank-package-1");

    Serial.println("[WiFi] configuring static network");
    Serial.println("[WiFi] local=" + local_IP.toString()
                   + " gateway=" + gateway.toString()
                   + " subnet=" + subnet.toString()
                   + " dns1=" + dns1.toString()
                   + " dns2=" + dns2.toString());

    if(!WiFi.config(local_IP, gateway, subnet, dns1, dns2))
    {
      Serial.println("[WiFi] WiFi.config FAILED");
    }
    printWiFiDiagnostics("configured");
  }

  void beginWiFiConnect(String reason)
  {
    lastWiFiAttemptMillis = millis();
    wifiReconnectAttempts++;
    Serial.println("[WiFi] begin reason=" + reason
                   + " ssid=" + String(ssid)
                   + " attempt=" + String(wifiReconnectAttempts));
    WiFi.begin(ssid, password);
    printWiFiDiagnostics("begin");
    yield();
  }

  void maintainWiFi()
  {
    wl_status_t status = WiFi.status();
    if(status == WL_CONNECTED)
    {
      if(!wifiConnectedReported)
      {
        wifiConnectedReported = true;
        wifiReconnectAttempts = 0;
        Serial.println("[WiFi] connected");
        printWiFiDiagnostics("connected");
        printDnsDiagnostics();
      }
      return;
    }

    if(wifiConnectedReported && status != WL_CONNECTED)
    {
      wifiConnectedReported = false;
      cloudOnline = false;
      Serial.println("[WiFi] disconnected status=" + String(status));
      printWiFiDiagnostics("disconnected");
    }

    if(lastWiFiAttemptMillis == 0 || millis() - lastWiFiAttemptMillis >= wifiReconnectIntervalMs)
    {
      beginWiFiConnect("periodic_reconnect");
    }
  }

  void printPeriodicDiagnostics()
  {
    if(millis() - lastDiagnosticsMillis < diagnosticsIntervalMs) return;
    lastDiagnosticsMillis = millis();
    printWiFiDiagnostics("periodic");
    printHeapDiagnostics("periodic");
    if(WiFi.status() == WL_CONNECTED) printDnsDiagnostics();
  }

  void setupServer()
  {
    server.on("/", HTTP_GET, handleDashboard);
    server.on("/", HTTP_OPTIONS, handleOptions);
    server.on("/on", HTTP_GET, handleOn);
    server.on("/on", HTTP_OPTIONS, handleOptions);
    server.on("/off", HTTP_GET, handleOff);
    server.on("/off", HTTP_OPTIONS, handleOptions);
    server.on("/reset", HTTP_GET, handleReset);
    server.on("/reset", HTTP_OPTIONS, handleOptions);

    server.on("/api/status", HTTP_GET, handleApiStatus);
    server.on("/api/status", HTTP_OPTIONS, handleOptions);
    server.on("/api/pump/on", HTTP_POST, handleOn);
    server.on("/api/pump/on", HTTP_OPTIONS, handleOptions);
    server.on("/api/pump/off", HTTP_POST, handleOff);
    server.on("/api/pump/off", HTTP_OPTIONS, handleOptions);
    server.on("/api/pump/reset", HTTP_POST, handleReset);
    server.on("/api/pump/reset", HTTP_OPTIONS, handleOptions);

    server.onNotFound(handleNotFound);
    server.begin();
    serverStarted = true;
    Serial.println("[HTTP] server.begin complete port=80 routes=local+api");
  }

  void setup()
  {
    Serial.begin(115200);
    Serial.println();
    cloudLog("boot firmware=" + String(firmwareVersion) + " deviceId=" + String(deviceId));
    Serial.println("[Boot] resetReason=" + ESP.getResetReason());
    Serial.println("[Boot] coreVersion=" + ESP.getCoreVersion());
    EEPROM.begin(64);
    loadRuntime();

    pinMode(RELAY_PIN,OUTPUT);
    pinMode(LED_PIN,OUTPUT);

    digitalWrite(LED_PIN,HIGH);
    writePump(false);

    setupServer();
    configureWiFi();
    beginWiFiConnect("boot");
    printHeapDiagnostics("boot");
  }

  void loop()
  {
    server.handleClient();
    maintainWiFi();
    server.handleClient();
    updateBlinkLed();
    if(WiFi.status() == WL_CONNECTED) syncCloud();
    printPeriodicDiagnostics();
    if(millis() - lastYieldMillis >= 20UL)
    {
      lastYieldMillis = millis();
      yield();
    }
  }
