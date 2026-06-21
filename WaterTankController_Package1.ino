
#include <ESP8266WiFi.h>
#include <ESP8266WebServer.h>
#include <EEPROM.h>

#define RELAY_PIN 5
#define LED_PIN 2

const char* ssid = "Airtel_divy_7892_2.4Ghz";
const char* password = "air72986";

IPAddress local_IP(192,168,1,13);
IPAddress gateway(192,168,1,1);
IPAddress subnet(255,255,255,0);

ESP8266WebServer server(80);

bool pumpRunning = false;
bool tankFull = false;
bool lockout = false;

unsigned long sessionStartMillis = 0;
unsigned long currentRuntimeSeconds = 0;
unsigned long totalRuntimeSeconds = 0;

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
}
