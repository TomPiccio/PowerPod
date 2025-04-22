#include <Wire.h>
#include <Adafruit_INA219.h>
#include <WiFi.h>
#include <HTTPClient.h>
#include <NTPClient.h>
#include <FirebaseESP32.h>

const char* ssid = "SUTD_Guest";

// Firebase credentials
#define FIREBASE_HOST "eps-power-pod-default-rtdb.asia-southeast1.firebasedatabase.app"
#define FIREBASE_AUTH "AIzaSyC5Ao48KAW615zSgF3653Rx6ikeLUAm2-k"

FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

// Define NTP settings
const char* ntpServer = "pool.ntp.org";
const long  gmtOffset_sec = 8 * 3600; // GMT+8 (Singapore)
const int   daylightOffset_sec = 0;

// We create three instances of the Adafruit_INA219 class, one per sensor.
// NOTE: We are using 3x sensors on a single I²C bus.
Adafruit_INA219 ina219_1(0x41); // INA219 for USB Charge Controller #1
Adafruit_INA219 ina219_2(0x44); // INA219 for USB Charge Controller #2
Adafruit_INA219 ina219_3(0x45); // INA219 for Solar Panel production

// Pin Definitions
#define RELAY_PIN 0 // Relay controls power between AC Grid and Solar Panel

// ***** Limit Switch Definition *****
// The limit switch (SPDT) is connected as an analog input on GPIO1.
// With a 4.7kΩ pull-up resistor, the line is normally high; when pressed,
// the voltage is pulled below 2.0 V or 1.0 V.
#define LIMIT_SWITCH_THRESHOLD 1.0        // Below this = top switch
#define LIMIT_SWITCH_SUBTHRESHOLD 2.0     // Below this = bottom switch
#define LIMIT_SWITCH_BOUNDS_1 1 //Upper/Lower Limit switch for Pod #1
#define LIMIT_SWITCH_POD_1 6 //Power Limit switch for Pod #1
#define LIMIT_SWITCH_BOUNDS_2 2 //Upper/Lower Limit switch for Pod #2
#define LIMIT_SWITCH_POD_2 4 //Power Limit switch for Pod #2

// ***** Stepper Motor Definitions for DRV8825 *****
// Update the pin numbers according to your wiring.
#define MOTOR_STEP_PIN_1    18    // Connect to DRV8825 STEP pin for Pod #1
#define MOTOR_DIR_PIN_1     20    // Connect to DRV8825 DIR pin for Pod #1
#define MOTOR_ENABLE_PIN_1  19    // Connect to DRV8825 ENABLE pin (active LOW by default) for Pod #1
#define MOTOR_STEP_PIN_2    16    // Connect to DRV8825 STEP pin for Pod #2
#define MOTOR_DIR_PIN_2     17    // Connect to DRV8825 DIR pin for Pod #2
#define MOTOR_ENABLE_PIN_2  21    // Connect to DRV8825 ENABLE pin (active LOW by default) for Pod #2

#define CURRENT_THRESHOLD 40.0
#define NO_CURRENT_THRESHOLD 1.0
// Motor movement configuration
// Timing intervals for step pulse generation (in microseconds)
unsigned long motorLastChangeMicros = 0;
const unsigned long motorStepInterval = 2000;      // Time between steps (adjust as needed)
const unsigned long motorPulseHighDuration = 15;     // Duration the pulse stays HIGH
bool motorPulseState = false;                        // Tracks step pulse state

// Timing variable for sensor reading every 1 second
unsigned long previousSensorMillis = 0;

// --- Finite-State Machine for Motor Direction ---
// Define an enumerator representing motor direction.
enum MotorDirection { ANTICLOCKWISE, CLOCKWISE };
MotorDirection currentDirection_1 = ANTICLOCKWISE; // Start spinning anticlockwise for Stepper Motor for Pod #1
MotorDirection currentDirection_2 = ANTICLOCKWISE; // Start spinning anticlockwise for Stepper Motor for Pod #1

// Variables per pod

// From Website
// is_Rented : bool
// Renter Contact Number : str  None if not rented
// Renter Name : str 
// Rental_start_time: str/timestamp
// overdue_status : bool

// From ESP32
// is_Available : bool <- Charge is Enough and the Power Bank is there
// lastUpdated : str/timedate <- Time String
// power_input_status : bool

// Both systems
// to_rent : bool
// request_to_open
// request_to_close

//Firebase Variables
struct PodStatus {
  bool isAvailable = false;          // Default: false
  bool powerInputStatus = false;    // Default: false
  bool requestToClose = false;      // Default: false
  bool requestToOpen = false;       // Default: false
  bool requestedToClose = false;      // Default: false
  bool requestedToOpen = false;       // Default: false
  String errorMsg = "";             // Default: empty string
  bool topLimitPressed = false;     // Default: false
  bool bottomLimitPressed = false;  // Default: false
  bool to_rent = false;             // Default: false
  bool opening = false;             // Default: false
  bool closing = false;             // Default: false
  float current = 0.0;             // Default: 0.0
};
PodStatus pod1, pod2;

// Timing variables for periodic updates
unsigned long lastSendTime = 0;
unsigned long lastReceiveTime = 0;
const unsigned long SEND_INTERVAL = 2000;  // Send every 10 seconds
const unsigned long RECEIVE_INTERVAL = 5000;  // Receive every 5 seconds
unsigned long pauseStartTime = 0;
bool pauseInProgress = false;

void setup(void)
{
  Serial.begin(115200);
  Serial.println("Setting up Firebase...");
  FireBase_Setup();
  configTime(gmtOffset_sec, daylightOffset_sec, ntpServer);
  
  // ----- Initialize INA219 Sensors -----
  Serial.println("Initializing three INA219 sensors...");

  if (!ina219_1.begin()) {
    Serial.println("Failed to find INA219 chip at 0x41");
    while (1) { delay(10); }
  }
  if (!ina219_2.begin()) {
    Serial.println("Failed to find INA219 chip at 0x44");
    while (1) { delay(10); }
  }
  if (!ina219_3.begin()) {
    Serial.println("Failed to find INA219 chip at 0x45");
    while (1) { delay(10); }
  }
  
  // Optionally configure each sensor's calibration range.
  ina219_1.setCalibration_32V_1A();
  ina219_2.setCalibration_32V_1A();
  ina219_3.setCalibration_32V_1A();

  Serial.println("All INA219 sensors initialized.");

  // ----- Initialize Relay Control -----
  pinMode(RELAY_PIN, OUTPUT);
  digitalWrite(RELAY_PIN, LOW); // Start with relay pin LOW

  // ----- Initialize Stepper Motor Control Pins -----
  pinMode(MOTOR_STEP_PIN_1, OUTPUT);
  pinMode(MOTOR_DIR_PIN_1, OUTPUT);
  pinMode(MOTOR_ENABLE_PIN_1, OUTPUT);
  pinMode(MOTOR_STEP_PIN_2, OUTPUT);
  pinMode(MOTOR_DIR_PIN_2, OUTPUT);
  pinMode(MOTOR_ENABLE_PIN_2, OUTPUT);

  // Disable the motor driver (ENABLE is active LOW for most DRV8825 boards)
  digitalWrite(MOTOR_ENABLE_PIN_1, HIGH);
  digitalWrite(MOTOR_ENABLE_PIN_2, HIGH);
  // Set the initial motor direction based on the FSM.
  digitalWrite(MOTOR_DIR_PIN_1, (currentDirection_1 == ANTICLOCKWISE) ? HIGH : LOW);
  //digitalWrite(MOTOR_DIR_PIN_2, (currentDirection_2 == ANTICLOCKWISE) ? HIGH : LOW);

  // ----- Initialize Limit Switch Pin -----
  // We'll use analogRead on this pin, so setting mode is optional.
  pinMode(LIMIT_SWITCH_BOUNDS_1, INPUT);
  pinMode(LIMIT_SWITCH_POD_1, INPUT);
  pinMode(LIMIT_SWITCH_BOUNDS_2, INPUT);
  pinMode(LIMIT_SWITCH_POD_2, INPUT);

  // Initialize timing variables for stepper pulse generation
  motorLastChangeMicros = micros();
}

void loop(void)
{
  Motor_Limit_Switches();
  Stepper_Control();
  hardware_sensor_functions();
  Pause_Timer();
  if(!pauseInProgress){
    Firebase_Function();
  }
}

void Pause_Timer() {
  bool pause_updates = pod1.closing || pod2.closing || pod1.opening || pod2.opening;

  if (pause_updates && !pauseInProgress) {
    pauseStartTime = millis();       // Record the time pause started
    pauseInProgress = true;          // Start the pause
  }

  // Check if 8 seconds have passed
  if (pauseInProgress && millis() - pauseStartTime >= 8000) {
    pauseInProgress = false;         // End pause
  }
}

void Motor_Limit_Switches(){
  //Pod #1
  float limitVoltage_1 = analogRead(LIMIT_SWITCH_BOUNDS_1) * (3.3 / 4095.0); // Adjust ADC scale if needed

  bool topLimitPressed_1 = limitVoltage_1 < LIMIT_SWITCH_THRESHOLD;
  bool bottomLimitPressed_1 = (limitVoltage_1 >= LIMIT_SWITCH_THRESHOLD && limitVoltage_1 < LIMIT_SWITCH_SUBTHRESHOLD);

  // Motor logic based on direction
  if (currentDirection_1 == CLOCKWISE && topLimitPressed_1 && !pod1.topLimitPressed) {
    // Stop or reverse
    Serial.println("Top limit switch pressed. Stopping/upward motion.");
    digitalWrite(MOTOR_ENABLE_PIN_1, HIGH);
  }
  else if (currentDirection_1 == ANTICLOCKWISE && bottomLimitPressed_1 && !pod1.bottomLimitPressed) {
    Serial.println("Bottom limit switch pressed. Stopping/downward motion.");
    digitalWrite(MOTOR_ENABLE_PIN_1, HIGH);
  }
  else{
    digitalWrite(MOTOR_ENABLE_PIN_1, pod1.closing ? LOW : HIGH);
  }
  digitalWrite(MOTOR_DIR_PIN_1, pod1.closing ? HIGH : LOW);

  // Edge detection for each
  pod1.topLimitPressed = topLimitPressed_1;
  pod1.bottomLimitPressed = bottomLimitPressed_1;

  //Pod #2
  float limitVoltage_2 = analogRead(LIMIT_SWITCH_BOUNDS_2) * (3.3 / 4095.0); // Adjust ADC scale if needed

  bool topLimitPressed_2 = limitVoltage_2 < LIMIT_SWITCH_THRESHOLD;
  bool bottomLimitPressed_2 = (limitVoltage_2 >= LIMIT_SWITCH_THRESHOLD && limitVoltage_2 < LIMIT_SWITCH_SUBTHRESHOLD);

  // Motor logic based on direction
  if (currentDirection_2 == CLOCKWISE && topLimitPressed_2 && !pod2.topLimitPressed) {
    // Stop or reverse
    Serial.println("Top limit switch pressed. Stopping/upward motion.");
    digitalWrite(MOTOR_ENABLE_PIN_2, HIGH);
    pod2.requestToOpen = false;
  }
  else if (currentDirection_2 == ANTICLOCKWISE && bottomLimitPressed_2 && !pod2.bottomLimitPressed) {
    Serial.println("Bottom limit switch pressed. Stopping/downward motion.");
    digitalWrite(MOTOR_ENABLE_PIN_2, HIGH);
    pod2.requestToClose = false;
  }
  else{
    //digitalWrite(MOTOR_ENABLE_PIN_2, pod2.closing || pod2.opening  ? LOW : HIGH);
  }
  //digitalWrite(MOTOR_DIR_PIN_2, pod2.closing ? HIGH : LOW);

  // Edge detection for each
  pod2.topLimitPressed = topLimitPressed_2;
  pod2.bottomLimitPressed = bottomLimitPressed_2;
}

void Stepper_Control(){
  // --- Stepper Motor Control (nonblocking) ---
  unsigned long currentMicros = micros();
  // Generate a step pulse for continuous motor movement.
  if (!motorPulseState && (currentMicros - motorLastChangeMicros >= motorStepInterval)) {
    // Start the pulse.
    digitalWrite(MOTOR_STEP_PIN_1, HIGH);
    //digitalWrite(MOTOR_STEP_PIN_2, HIGH);
    motorPulseState = true;
    motorLastChangeMicros = currentMicros;
  }
  else if (motorPulseState && (currentMicros - motorLastChangeMicros >= motorPulseHighDuration)) {
    // End the pulse.
    digitalWrite(MOTOR_STEP_PIN_1, LOW);
    //digitalWrite(MOTOR_STEP_PIN_2, LOW);
    motorPulseState = false;
    motorLastChangeMicros = currentMicros;
  }
  digitalWrite(MOTOR_ENABLE_PIN_1, LOW);
}

void hardware_sensor_functions(){
  unsigned long currentMillis = millis();
  
  // --- Sensor Reading and Relay Control (every 1 second) ---
  if (currentMillis - previousSensorMillis >= 1000) {
    previousSensorMillis = currentMillis;

    // INA219 #1 readings
    float shuntvoltage_1 = ina219_1.getShuntVoltage_mV();
    float busvoltage_1   = ina219_1.getBusVoltage_V();
    float current_mA_1   = ina219_1.getCurrent_mA();
    float power_mW_1     = ina219_1.getPower_mW();
    float loadvoltage_1  = busvoltage_1 + (shuntvoltage_1 / 1000);
    pod1.current = current_mA_1;
    pod1.powerInputStatus = current_mA_1 > CURRENT_THRESHOLD;

    // INA219 #2 readings
    float shuntvoltage_2 = ina219_2.getShuntVoltage_mV();
    float busvoltage_2   = ina219_2.getBusVoltage_V();
    float current_mA_2   = ina219_2.getCurrent_mA();
    float power_mW_2     = ina219_2.getPower_mW();
    float loadvoltage_2  = busvoltage_2 + (shuntvoltage_2 / 1000);
    pod2.current = current_mA_2;
    pod2.powerInputStatus = current_mA_2 > CURRENT_THRESHOLD;

    // INA219 #3 readings
    float shuntvoltage_3 = ina219_3.getShuntVoltage_mV();
    float busvoltage_3   = ina219_3.getBusVoltage_V();
    float current_mA_3   = ina219_3.getCurrent_mA();
    float power_mW_3     = ina219_3.getPower_mW();
    float loadvoltage_3  = busvoltage_3 + (shuntvoltage_3 / 1000);

    // Print sensor readings
    Serial.print("INA219_1  => Bus: ");
    Serial.print(busvoltage_1); Serial.print(" V; Shunt: ");
    Serial.print(shuntvoltage_1); Serial.print(" mV; Load: ");
    Serial.print(loadvoltage_1); Serial.print(" V; Current: ");
    Serial.print(current_mA_1); Serial.print(" mA; Power: ");
    Serial.print(power_mW_1); Serial.println(" mW");

    Serial.print("INA219_2  => Bus: ");
    Serial.print(busvoltage_2); Serial.print(" V; Shunt: ");
    Serial.print(shuntvoltage_2); Serial.print(" mV; Load: ");
    Serial.print(loadvoltage_2); Serial.print(" V; Current: ");
    Serial.print(current_mA_2); Serial.print(" mA; Power: ");
    Serial.print(power_mW_2); Serial.println(" mW");

    Serial.print("INA219_3  => Bus: ");
    Serial.print(busvoltage_3); Serial.print(" V; Shunt: ");
    Serial.print(shuntvoltage_3); Serial.print(" mV; Load: ");
    Serial.print(loadvoltage_3); Serial.print(" V; Current: ");
    Serial.print(current_mA_3); Serial.print(" mA; Power: ");
    Serial.print(power_mW_3); Serial.println(" mW");

    // Relay control: if INA219_3's bus voltage is below 11.8V, set relay HIGH.
    if (busvoltage_3 < 11.8) {
      digitalWrite(RELAY_PIN, HIGH);
      Serial.println("INA219_3 voltage < 11.8V: Relay set to HIGH.");
    } else {
      digitalWrite(RELAY_PIN, LOW);
      Serial.println("INA219_3 voltage >= 11.8V: Relay set to LOW.");
    }
    Serial.println();
  }
}

String getCurrentTime() {
    struct tm timeinfo;
    if (!getLocalTime(&timeinfo)) {
        return "Failed to obtain time";
    }

    char timeString[20]; // Buffer for formatted time
    strftime(timeString, sizeof(timeString), "%Y-%m-%d %H:%M:%S", &timeinfo);
    return String(timeString);
}

void FireBase_Setup(){
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
  Firebase_Function();
}

void sendPodStatus(const int& podID, PodStatus& pod) {
  // Build the base path
  String path = "/pod_" + String(podID);

  // Determine availability from the appropriate limit switch
  bool isAvailable = digitalRead(podID == 1 ? LIMIT_SWITCH_POD_1 : LIMIT_SWITCH_POD_2) == HIGH;
  pod.isAvailable = isAvailable; // Optional: keep it updated in your struct

  // Send each field individually
  Firebase.setBool(fbdo, path + "/is_Available", isAvailable);
  Firebase.setString(fbdo, path + "/lastUpdated", getCurrentTime());
  Firebase.setBool(fbdo, path + "/power_input_status", pod.powerInputStatus);
  Firebase.setBool(fbdo, path + "/request_to_close", pod.requestToClose && pod.requestedToClose);
  Firebase.setBool(fbdo, path + "/request_to_open", pod.requestToOpen && pod.requestedToOpen);
  Firebase.setString(fbdo, path + "/error_msg", pod.errorMsg);
}


void receivePodStatus(const String& podID, PodStatus& pod) {
  String path = "/pod_" + podID;

  // Get "request_to_open"
  if (Firebase.getBool(fbdo, path + "/request_to_open")) {
    if (!pod.requestedToOpen) {
      pod.requestToOpen = fbdo.boolData();
    }
  } else {
    Serial.println("Failed to get request_to_open");
  }

  // Get "request_to_close"
  if (Firebase.getBool(fbdo, path + "/request_to_close")) {
    if (!pod.requestedToClose) {
      pod.requestToClose = fbdo.boolData();
    }
  } else {
    Serial.println("Failed to get request_to_close");
  }

  // Get "to_rent"
  if (Firebase.getBool(fbdo, path + "/to_rent")) {
    pod.to_rent = fbdo.boolData();
  } else {
    Serial.println("Failed to get to_rent status");
  }
}

void Firebase_Function(){
  unsigned long currentMillis = millis();

  // Periodically send data to Firebase (every SEND_INTERVAL ms)
  if (currentMillis - lastSendTime >= SEND_INTERVAL) {
    sendPodStatus(1, pod1);  // Send Pod 1 data
    sendPodStatus(2, pod2);  // Send Pod 2 data
    lastSendTime = currentMillis;
    Serial.println("Data sent to Firebase");
  }

  handle_requests(pod1);
  handle_requests(pod2);

  // Periodically receive data from Firebase (every RECEIVE_INTERVAL ms)
  if (currentMillis - lastReceiveTime >= RECEIVE_INTERVAL) {
    receivePodStatus("1", pod1);  // Receive Pod 1 data
    receivePodStatus("2", pod2);  // Receive Pod 2 data
    lastReceiveTime = currentMillis;
    Serial.println("Data received from Firebase");
  }
}

void handleCloseRequest(PodStatus &pod) {
  // Step 1: Check if user requests to close
  if(!pod.to_rent){
    if (pod.requestToClose) {
      if (!pod.isAvailable) {
        pod.errorMsg = "Place the power bank inside.";
      } else {
        digitalWrite(MOTOR_ENABLE_PIN_1, LOW);  // Enable motor
        pod.requestToClose = false;             // Clear request flag
        pod.requestedToClose = true;            // Mark closing process started
        pod.errorMsg = "";
      }
    }
    else if (pod.requestedToClose) {
      // Step 2: If closing was requested previously
      if (!pod.isAvailable) {
        pod.errorMsg = "Place the power bank inside.";
      } 
      else {
        // Step 3: If available and closing, check current
        if(pod.bottomLimitPressed){
          pod.closing = false; 
          if (pod.current < NO_CURRENT_THRESHOLD) {
            pod.errorMsg = "Plug the charging cable.";
          } else {
            pod.requestedToClose = false;  // Done closing
            pod.errorMsg = "";
          }
        }
        else{
          pod.closing = true;
          pod.errorMsg = "";
        }
      }
    }
  }
  else{
    if(pod.bottomLimitPressed){
      pod.closing = false;
    }
    else{
      pod.closing = true;
    }
  }
}

void handleOpenRequest(PodStatus &pod) {
  // Step 1: Check if user requests to open
  if(pod.to_rent){
    if (pod.requestToOpen) {
      if (pod.current >= NO_CURRENT_THRESHOLD) {
        pod.errorMsg = "Unplug the charging cable!";
      } else {
        pod.requestToOpen = false;             // Clear request flag
        pod.requestedToOpen = true;            // Mark opening process started
        pod.errorMsg = "";
      }
    }
    else if (pod.requestedToOpen) {
      // Step 2: If opening was requested previously
      if (pod.current >= NO_CURRENT_THRESHOLD) {
        pod.errorMsg = "Unplug the charging cable!";
      } 
      else {
        // Step 3: If available and opening, check current
        if(pod.topLimitPressed){
          pod.opening = false;
          if (!pod.isAvailable) {
            pod.errorMsg = "Place the power bank inside.";
          } else {
            pod.requestedToOpen = false;  // Done opening
            pod.errorMsg = "";
          }
        }
        else{
          pod.opening = true;
          pod.errorMsg = "";
        }
      }
    }
  }
  else{
    if(pod.topLimitPressed){
      pod.opening = false;
    }
    else{
      pod.opening = true;
    }
  }
}

void handle_requests(PodStatus &pod){
  if(pod.requestToClose || pod.requestedToClose){
    handleCloseRequest(pod);
  }
  else if(pod.requestToOpen || pod.requestedToOpen){
    handleOpenRequest(pod);
  }
}
