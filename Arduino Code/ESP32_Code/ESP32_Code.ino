#include <WiFi.h>
#include <HTTPClient.h>
#include <NTPClient.h>
#include <FirebaseESP32.h>

const char* ssid = "SUTD_Guest";

// Firebase credentials
#define FIREBASE_HOST "eps-power-pod-default-rtdb.asia-southeast1.firebasedatabase.app"
#define FIREBASE_AUTH "AIzaSyC5Ao48KAW615zSgF3653Rx6ikeLUAm2-k"

FirebaseData fbData;
FirebaseAuth auth;
FirebaseConfig config;

#define DIR_PIN 1
#define STEP_PIN_1 2
#define STEP_PIN_2 3
#define STEP_PIN_3 4
#define LIMIT_SWITCH_1 5
#define LIMIT_SWITCH_2 6
#define LIMIT_SWITCH_3 7
#define CHARGING_1 8
#define CHARGING_2 9
#define CHARGING_3 10

// Define NTP settings
const char* ntpServer = "pool.ntp.org";
const long  gmtOffset_sec = 8 * 3600; // GMT+8 (Singapore)
const int   daylightOffset_sec = 0;


String getCurrentTime() {
    struct tm timeinfo;
    if (!getLocalTime(&timeinfo)) {
        return "Failed to obtain time";
    }

    char timeString[20]; // Buffer for formatted time
    strftime(timeString, sizeof(timeString), "%Y-%m-%d %H:%M:%S", &timeinfo);
    return String(timeString);
}

void setup() {
    Serial.begin(115200);
    WiFi.begin(ssid);
    
    Serial.print("Connecting to WiFi");
    while (WiFi.status() != WL_CONNECTED) {
        delay(500);
        Serial.print(".");
    }
    Serial.println("\nConnected to WiFi");
    Serial.print("IP Address: ");
    Serial.println(WiFi.localIP());

    // Configure Firebase
    config.host = FIREBASE_HOST;
    config.signer.tokens.legacy_token = FIREBASE_AUTH;
    Firebase.begin(&config, &auth);
    Firebase.reconnectWiFi(true);

    // Send initial data
    sendDataToFirebase();
    receiveDataFromFirebase();

    //Setup Pin Modes
    pinMode(DIR_PIN, OUTPUT);
    pinMode(STEP_PIN_1, OUTPUT);
    pinMode(STEP_PIN_2, OUTPUT);
    pinMode(STEP_PIN_3, OUTPUT);
    pinMode(LIMIT_SWITCH_1, INPUT);
    pinMode(LIMIT_SWITCH_2, INPUT);
    pinMode(LIMIT_SWITCH_3, INPUT);
    pinMode(CHARGING_1, INPUT);
    pinMode(CHARGING_2, INPUT);
    pinMode(CHARGING_3, INPUT);

    configTime(gmtOffset_sec, daylightOffset_sec, ntpServer);
}


void loop() {
    delay(10000);
    sendDataToFirebase();
    //receiveDataFromFirebase();
}


// Variables per pod

// From Website
// is_Rented : bool
// mode : int (0 - Charging, 1 - Idle, 2 - Open, 2 - Rented (awaiting to return) )
// Renter Contact Number : str (no need for ESP32) None if not rented
// Renter Student ID : str (no need for ESP32)
// Renter Name : str (no need for ESP32)
// Rental_start_time: str/timestamp
// overdue_status : bool

// From ESP32
// is_Available : bool <- Charge is Enough and the Power Bank is there
// lastUpdated : str/timedate <- Time String
// power_input_status : bool
// status_code : int (0 - No Error,  1 - Power Error, 2 - Powerbank Missing)

//Firebase Variables
bool is_Available_1 = false;
bool is_Available_2 = false;
bool is_Available_3 = false;
bool power_input_status_1 = false;
bool power_input_status_2 = false;
bool power_input_status_3 = false;
int status_code_1 = 0;
int status_code_2 = 0;
int status_code_3 = 0;
bool is_Rented_1 = false;
bool is_Rented_2 = false;
bool is_Rented_3 = false;
int mode_1 = 0;
int mode_2 = 0;
int mode_3 = 0;


void sendDataToFirebase() {
    Serial.println("Sending data to Firebase...");
    
    //Pod 1
    Firebase.setBool(fbData, "/pod_1/is_Available", is_Available_1);
    Firebase.setString(fbData, "/pod_1/lastUpdated", getCurrentTime());
    Firebase.setBool(fbData, "/pod_1/power_input_status", power_input_status_1);
    Firebase.setInt(fbData, "/pod_1/status_code", status_code_1);

    //Pod 2
    Firebase.setBool(fbData, "/pod_2/is_Available", is_Available_2);
    Firebase.setString(fbData, "/pod_2/lastUpdated", getCurrentTime());
    Firebase.setBool(fbData, "/pod_2/power_input_status", power_input_status_2);
    Firebase.setInt(fbData, "/pod_2/status_code", status_code_2);

    //Pod 3
    Firebase.setBool(fbData, "/pod_3/is_Available", is_Available_3);
    Firebase.setString(fbData, "/pod_3/lastUpdated", getCurrentTime());
    Firebase.setBool(fbData, "/pod_3/power_input_status", power_input_status_3);
    Firebase.setInt(fbData, "/pod_3/status_code", status_code_3);
    
    Serial.println("Data sent to Firebase.");
}

void receiveDataFromFirebase() {
    Serial.println("Receiving data from Firebase...");
    
    // Get website-controlled variables from Firebase
    if (Firebase.getBool(fbData, "/pod_1/is_Rented")) {
        is_Rented_1 = fbData.boolData();
    }

    if (Firebase.getInt(fbData, "/pod_1/mode")) {
        mode_1 = fbData.intData();
    }

    if (Firebase.getBool(fbData, "/pod_2/is_Rented")) {
        is_Rented_2 = fbData.boolData();
    }

    if (Firebase.getInt(fbData, "/pod_2/mode")) {
        mode_2 = fbData.intData();
    }

    if (Firebase.getBool(fbData, "/pod_3/is_Rented")) {
        is_Rented_3 = fbData.boolData();
    }

    if (Firebase.getInt(fbData, "/pod_3/mode")) {
        mode_3 = fbData.intData();
    }

    Serial.println("Data received from Firebase.");
}

void stepperMove(int steps, int direction, int speed, int index) {
  // move motor <index> by <steps> steps in 2*<speed> microseconds per step 
  digitalWrite(DIR_PIN, direction); // Set direction: 1 = CW, 0 = CCW
  int step_pin = index == 3 ? STEP_PIN_3 : index == 2 ? STEP_PIN_2 : STEP_PIN_1;
  for (int i = 0; i < steps; i++) {
    digitalWrite(step_pin, HIGH);
    delayMicroseconds(speed);
    digitalWrite(step_pin, LOW);
    delayMicroseconds(speed);
  }
}
