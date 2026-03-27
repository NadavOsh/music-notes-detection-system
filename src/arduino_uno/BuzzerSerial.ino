#define BUZZER_PIN 8

#define B3 247
#define C4 262
#define D4 294
#define E4 330
#define F4 349
#define G4 392
#define A4 440
#define B4 494
#define C5 523
#define D5 587
#define E5 659

String data = "";
int duration = 500;

void setup() {
  Serial.begin(9600);
  pinMode(BUZZER_PIN, OUTPUT);
}

void loop() {
  // Check if serial data is available
  if (Serial.available() > 0) {
    data = Serial.readStringUntil('\n');  // Read until newline
    data.trim();                          // Remove any trailing whitespace or newline

    if (data == "B3") {
      tone(BUZZER_PIN, B3, duration);
      Serial.println("Playing B3");
    } else if (data == "C4") {




      tone(BUZZER_PIN, C4, duration);
      Serial.println("Playing C4");
    } else if (data == "D4") {
      tone(BUZZER_PIN, D4, duration);
      Serial.println("Playing D4");
    } else if (data == "E4") {
      tone(BUZZER_PIN, E4, duration);
      Serial.println("Playing E4");
    } else if (data == "F4") {
      tone(BUZZER_PIN, F4, duration);
      Serial.println("Playing F4");
    } else if (data == "G4") {
      tone(BUZZER_PIN, G4, duration);
      Serial.println("Playing G4");
    } else if (data == "A4") {
      tone(BUZZER_PIN, A4, duration);
      Serial.println("Playing A4");
    } else if (data == "B4") {
      tone(BUZZER_PIN, B4, duration);
      Serial.println("Playing B4");
    } else if (data == "C5") {
      tone(BUZZER_PIN, C5, duration);
      Serial.println("Playing C5");
    } else if (data == "D5") {
      tone(BUZZER_PIN, D5, duration);
      Serial.println("Playing D5");
    } else if (data == "E5") {
      tone(BUZZER_PIN, E5, duration);
      Serial.println("Playing E5");
    }
  }
}
