
using System.Collections;
using System.IO.Ports;

// COM5 on my machine. You will probably need to change this.
// Open device manger to find port.
var mySerialPort = new SerialPort("COM5");

void MyDataReceivedHandler(object sender, SerialDataReceivedEventArgs e)
{
    //push buttun U (btnU) on Basyus 3 board to send up data
    var count = mySerialPort.BytesToRead;
    Console.WriteLine($"Got {count} bytes");
    byte[] ByteArray = new byte[count];
    mySerialPort.Read(ByteArray, 0, count);
    ushort humidityRecieved = ByteArray[1];
    humidityRecieved = (ushort)((humidityRecieved << 8) | ByteArray[0]);
    ushort tempRecieved = ByteArray[3];
    tempRecieved = (ushort)((tempRecieved << 8) | ByteArray[0]);

    var temperature = (((double)tempRecieved / 65536) * 165.00) - 40.0;
    var humidity = (((double)humidityRecieved / 65536) * 100.00);
    Console.WriteLine($"Temperature {temperature:F2} deg C, Himidity {humidity:F2} %");
}


mySerialPort.BaudRate = 115200;
mySerialPort.Parity = Parity.None;
mySerialPort.StopBits = StopBits.One;
mySerialPort.DataBits = 8;
mySerialPort.Handshake = Handshake.None;
mySerialPort.DataReceived += MyDataReceivedHandler;

mySerialPort.Open();

// Hold for data. Crude, but works well enough for demo!
Console.ReadLine();

Console.WriteLine("Hello, World!");
