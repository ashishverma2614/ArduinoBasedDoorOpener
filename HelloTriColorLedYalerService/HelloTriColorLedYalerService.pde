#include <SPI.h>

#include <Ethernet.h>
#include <EthernetDHCP.h>

const char html[] =
  "<html><head>"
    "<script type=\"text/javascript\">"
    "var r;"
    "try {"
      "r = new XMLHttpRequest();"
    "} catch (e) {"
      "try {"
        "r = new ActiveXObject('Microsoft.XMLHTTP');"
      "} catch (e) {}"
    "}"
    "function set (c) {"
      "r.open('PUT', './led/' + c, false);"
      "r.send(null);"
    "}"
    "</script>"
    "<style type=\"text/css\">"
      ".b {width:112; height:112}"
      ".g {color:lightgrey}"
    "</style>"
  "</head>"
  "<body><table height=\"100%\" width=\"100%\">"
    "<tr><td align=\"center\" valign=\"middle\">"
      "<p>"
        "<input type=\"button\" class=\"b\" style=\"background-color:#ff0000\" onclick=\"set('ff0000')\"/>&nbsp;&nbsp;"
        "<input type=\"button\" class=\"b\" style=\"background-color:#00ff00\" onclick=\"set('00ff00')\"/>&nbsp;&nbsp;"
        "<input type=\"button\" class=\"b\" style=\"background-color:#0000ff\" onclick=\"set('0000ff')\"/>"
      "</p>"
      "<p>HTML served from <a href=\"\">this</a> Arduino, made accessible by <a href=\"http://www.yaler.org/\">Yaler</a>.</p>"
    "</td></tr>"
  "</table></body></html>";

const char http200[] = "HTTP/1.1 200 OK";
const char contentLength[] = "Content-Length: ";
const char connectionClose[] = "Connection: close";
const char contentTypeTextHtml[] = "Content-Type: text/html";
const char contentTypeTextPlain[] = "Content-Type: text/plain";

const byte RECEIVING = 0, READ_CR = 1, READ_CRLF = 2, READ_CRLFCR = 3, DONE = 4;
const byte YALER_RECEIVING = 0, YALER_UPGRADING = 1, YALER_TIMEOUT = 2, YALER_UPGRADED = 3;

const char yalerId[] = "folio"; // TODO: change
byte mac[] = { 0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED }; // TODO: change
byte server[] = { 46, 137, 106, 125 }; // try.yaler.net

boolean isPut;
byte state;
int count;
byte ledIndex;
byte ledUriOffset;
int htmlLength;

byte yalerState;
int yalerCount;

byte rPin = 5;
byte gPin = 3;
byte bPin = 4;
byte led[] = {0, 0, 0};

void setColor (byte r, byte g, byte b) {
  // SparkFun LED
  analogWrite(rPin, r);
  analogWrite(gPin, g); 
  analogWrite(bPin, b);

  // Ladyada LED
  //analogWrite(rPin, 255 - r);
  //analogWrite(gPin, 255 - g); 
  //analogWrite(bPin, 255 - b);  
}

byte byteFromHexChar (char ch) {
  byte result;
  if ((ch >= '0') && (ch <= '9')) {
    result = ch - '0';
  } else if ((ch >= 'a') && (ch <= 'f')) {
    result = 10 + (ch - 'a');
  } else if ((ch >= 'A') && (ch <= 'F')) {
    result = 10 + (ch - 'A');
  } else {
    result = 0;
  }
  return result;
}

void parseRequestChar (char ch) {
  // PUT /<yaler-id>/led/ff0000 ... \r\n\r\n
  // GET /<yaler-id>/led ... \r\n\r\n
  if (count == 0) {
    isPut = ch == 'P';
  } else if ((count >= ledUriOffset) && (count < ledUriOffset + 6)) {
    byte d = byteFromHexChar(ch);
    //Serial.print(ch);
    if ((count - ledUriOffset) % 2 == 0) {
      led[ledIndex] = d;
    } else {
      led[ledIndex] = led[ledIndex] * 16 + d;
      ledIndex++;
    }
  }
  if (state == RECEIVING) {
    if (ch == '\r') {
      state = READ_CR;
    }
  } else if (state == READ_CR) {
    // assert ch == '\n'
    state = READ_CRLF;
  } else if (state == READ_CRLF) {
    if (ch == '\r') {
      state = READ_CRLFCR;
    } else {
      state = RECEIVING;
    }
  } else if (state == READ_CRLFCR) {
    // assert ch == '\n'
    state = DONE;
  }
  count++;
}

void parseYalerResponseChar (char ch) {
  // HTTP/1.1 101 ... \r\n\r\n
  // HTTP/1.1 204 ... \r\n\r\n
  if (yalerState == YALER_RECEIVING) {
    if (yalerCount == 9) { // sizeof("HTTP/1.1 ?") - 1;
      if (ch == '1') { // 101
        yalerState = YALER_UPGRADING;
      } else { // 204
        // assert ch == '2'
        yalerState = YALER_TIMEOUT;
      }
    }
  } else if (yalerState == YALER_UPGRADING) {
    if (yalerCount == 56) { // sizeof("HTTP/1.1 101 ... \r\n\r\n") - 1
      yalerState = YALER_UPGRADED;
    }
  }
  yalerCount++;
}

void sendYalerPostRequest (Client c) {
  c.print("POST /");
  c.print(yalerId);
  c.println(" HTTP/1.1");
  c.println("Upgrade: PTTH/1.0");
  c.println("Connection: Upgrade");
  c.println("Host: www.yaler.net");
  c.print(contentLength);
  c.println("0");
  c.println();
  c.flush();
}

void receiveYalerResponse (Client c) {
  yalerCount = 0;
  yalerState = YALER_RECEIVING;
  while (c.connected() && (c.available() <= 0)) {} // Yaler sends 101 or 204 in < 30s
  while (c.connected() && (c.available() > 0) &&
    (yalerState != YALER_UPGRADED) &&
    (yalerState != YALER_TIMEOUT)) 
  {
    char ch = c.read();
    parseYalerResponseChar(ch);
  }
}

void sendPutResponse (Client c) {
  c.println(http200);
  c.println(contentTypeTextPlain);
  c.print(contentLength);
  c.println("3");
  c.println(connectionClose);
  c.println();
  c.print("200");
  c.flush();
}

void sendGetResponse (Client c) {
  c.println(http200);
  c.println(contentTypeTextHtml);
  c.print(contentLength);
  c.println(htmlLength);
  c.println(connectionClose);
  c.println();
  c.print(html);
  c.flush();
}

void receiveRequest (Client c) {
  count = 0;
  ledIndex = 0;
  state = RECEIVING;
  while (c.connected() && (c.available() > 0) && (state != DONE)) {
    char ch = c.read();
    //Serial.print(ch);
    parseRequestChar(ch);
  }
}

void setup() {
  //Serial.begin(9600);
  //Serial.println("setup");
  pinMode(rPin, OUTPUT);
  pinMode(gPin, OUTPUT);
  pinMode(bPin, OUTPUT);
  setColor(255, 255, 255);
  EthernetDHCP.begin(mac);
  htmlLength = sizeof(html) - 1;
  ledUriOffset = sizeof("PUT /") + sizeof(yalerId) + sizeof("/led/") - 3 * 1;
  setColor(0, 0, 0);
}

void loop() {
  Client client(server, 80);
  client.connect();
  if (client.connected()) {
    //Serial.println("connected");
    sendYalerPostRequest(client);
    receiveYalerResponse(client);
    if (yalerState == YALER_UPGRADED) {
      //Serial.println("upgraded");
      receiveRequest(client);
      if (state == DONE) {
        if (isPut) {
          setColor(led[0], led[1], led[2]);
          sendPutResponse(client);
        } else {
          sendGetResponse(client);
        }
      }
    } else {
      //Serial.println("timeout");
    }
    client.stop();
  }
}
