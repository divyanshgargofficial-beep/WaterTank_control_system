
#include <ESP8266WiFi.h>
#include <ESP8266WebServer.h>
#include <ESP8266HTTPClient.h>
#include <WiFiClientSecure.h>
#include <EEPROM.h>

#define RELAY_PIN 5
#define LED_PIN 2

const char* ssid = "Airtel_divy_7892_2.4Ghz";
const char* password = "air72986";

const char* firmwareVersion = "1.1.0-cloud";
const char* deviceId = "package-1";
const char* deviceName = "Home Water Tank";
const char* deviceToken = "replace-with-device-token";
const char* cloudBaseUrl = "https://your-water-tank-backend.railway.app";

IPAddress local_IP(192,168,1,13);
IPAddress gateway(192,168,1,1);
IPAddress subnet(255,255,255,0);

ESP8266WebServer server(80);
WiFiClientSecure cloudClient;

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
bool cloudOnline = false;

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
  for(int i=0;i<5;i++)
  {
    digitalWrite(LED_PIN, LOW);
    delay(200);
    digitalWrite(LED_PIN, HIGH);
    delay(200);
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

void handleApiStatus(){ server.send(200,"application/json",jsonStatus()); }

void handleOn()
{
  if(lockout)
  {
    server.send(423,"application/json","{\"error\":\"lockout\"}");
    return;
  }
  tankFull=false;
  writePump(true);
  server.send(200,"application/json","{\"success\":true}");
}

void handleOff()
{
  writePump(false);
  tankFull=true;
  lockout=true;
  blinkLed();
  server.send(200,"application/json","{\"success\":true}");
}

void handleReset()
{
  lockout=false;
  tankFull=false;
  server.send(200,"application/json","{\"success\":true}");
}

void markCloudSuccess()
{
  cloudOnline = true;
  cloudBackoffSeconds = 1;
  cloudBackoffUntilMillis = 0;
}

void markCloudFailure()
{
  cloudOnline = false;
  if(cloudBackoffSeconds < 60) cloudBackoffSeconds *= 2;
  cloudBackoffUntilMillis = millis() + (cloudBackoffSeconds * 1000UL);
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

void ackCloudCommand(String commandId, bool success, String message)
{
  if(commandId.length() == 0 || !cloudReady()) return;

  HTTPClient http;
  String url = String(cloudBaseUrl) + "/device/ack";
  if(!http.begin(cloudClient, url)) return;
  addCloudHeaders(http);
  String body="{";
  body+="\"deviceId\":\"" + String(deviceId) + "\"";
  body+=",\"commandId\":\"" + commandId + "\"";
  body+=",\"success\":" + String(success ? "true" : "false");
  body+=",\"message\":\"" + message + "\"";
  body+="}";
  int code = http.POST(body);
  http.end();
  if(code >= 200 && code < 300) markCloudSuccess();
  else markCloudFailure();
}

void executeCloudCommand(String commandId, String command)
{
  if(command == "PUMP_ON")
  {
    if(lockout)
    {
      ackCloudCommand(commandId, false, "lockout");
      return;
    }
    tankFull = false;
    writePump(true);
    ackCloudCommand(commandId, true, "pump started");
    return;
  }

  if(command == "PUMP_OFF")
  {
    writePump(false);
    tankFull = true;
    lockout = true;
    blinkLed();
    ackCloudCommand(commandId, true, "pump stopped");
    return;
  }

  if(command == "RESET_LOCKOUT")
  {
    lockout = false;
    tankFull = false;
    ackCloudCommand(commandId, true, "lockout reset");
    return;
  }

  if(command.length() > 0 && command != "NONE")
  {
    ackCloudCommand(commandId, false, "unknown command");
  }
}

void pollCloudCommand()
{
  if(!cloudReady()) return;
  if(millis() - lastCloudCommandMillis < 1000UL) return;
  lastCloudCommandMillis = millis();

  HTTPClient http;
  String url = String(cloudBaseUrl) + "/device/command?deviceId=" + String(deviceId);
  if(!http.begin(cloudClient, url))
  {
    markCloudFailure();
    return;
  }
  addCloudHeaders(http);
  int code = http.GET();
  if(code >= 200 && code < 300)
  {
    String response = http.getString();
    markCloudSuccess();
    String command = extractJsonValue(response, "command");
    String commandId = extractJsonValue(response, "commandId");
    executeCloudCommand(commandId, command);
  }
  else
  {
    markCloudFailure();
  }
  http.end();
}

void postCloudStatus()
{
  if(!cloudReady()) return;
  if(millis() - lastCloudStatusMillis < 2000UL) return;
  lastCloudStatusMillis = millis();

  HTTPClient http;
  String url = String(cloudBaseUrl) + "/device/status";
  if(!http.begin(cloudClient, url))
  {
    markCloudFailure();
    return;
  }
  addCloudHeaders(http);
  int code = http.POST(cloudStatusJson());
  if(code >= 200 && code < 300) markCloudSuccess();
  else markCloudFailure();
  http.end();
}

void syncCloud()
{
  pollCloudCommand();
  postCloudStatus();
}

void handleDashboard()
{
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
  server.send(200,"text/html",html);
}

void connectWiFi()
{
  WiFi.mode(WIFI_STA);
  WiFi.config(local_IP,gateway,subnet);
  WiFi.begin(ssid,password);
  while(WiFi.status()!=WL_CONNECTED) delay(500);
}

void setup()
{
  EEPROM.begin(64);
  loadRuntime();

  pinMode(RELAY_PIN,OUTPUT);
  pinMode(LED_PIN,OUTPUT);

  digitalWrite(LED_PIN,HIGH);
  writePump(false);

  connectWiFi();
  cloudClient.setInsecure();

  server.on("/", handleDashboard);
  server.on("/on", handleOn);
  server.on("/off", handleOff);
  server.on("/reset", handleReset);

  server.on("/api/status", handleApiStatus);
  server.on("/api/pump/on", HTTP_POST, handleOn);
  server.on("/api/pump/off", HTTP_POST, handleOff);
  server.on("/api/pump/reset", HTTP_POST, handleReset);

  server.begin();
}

void loop()
{
  if(WiFi.status()!=WL_CONNECTED)
  {
    WiFi.disconnect();
    WiFi.begin(ssid,password);
  }

  server.handleClient();
  syncCloud();
}
