RoboStream v1.00
🚀 Step 1: Initialize the Server
First, we need to initialize the server. In the directory from the folder you downloaded from the drive, open a terminal and run the following command docker-compose up -d --build. This command uses Docker to build the project's required environment and start all necessary services in the background.
![image](https://github.com/user-attachments/assets/ce3605da-4f5f-458c-bd9d-7468db23b7fb)

📲 Step 2: Install and Open the App
Once the server is running, install the provided APK file on your Android device. You may need to enable 'Install from unknown sources' in your device's settings. After the installation is complete, open the app.
![Screenshot_1751806394](https://github.com/user-attachments/assets/8636efdf-8e61-4e00-a363-f22da4a4bb1d)
![Captura de pantalla 2025-07-06 151804](https://github.com/user-attachments/assets/c8035bb7-0fdd-49c0-94dd-ea3985aa60cf)

🔌 Step 3: Server IP Address
When you open the app, the first thing you will see is the server configuration screen. Here, the app needs the IP ADDRESS of the device where the server is running. It's very important not to include the port; the app will add it automatically, as the server runs on port 8000 always. If you are running the app in the Android Emulator on the same machine as the server, use the special address 10.0.2.2 to connect.
![Screenshot_1751806416](https://github.com/user-attachments/assets/406d0f3b-53d9-465f-84fb-2314790f79dd)

🌌 Step 4: Liquid Galaxy Configuration
After connecting to the server, the next screen is for the Liquid Galaxy configuration. You will need the main LG's IP Address, username, password and the total number of screens.
When you click 'Connect', the app will attempt to establish a connection. If successful, the RoboStream logo will appear on the leftmost screen of the Liquid Galaxy as a visual confirmation, and the app will take you to the home screen.
![Screenshot_1751806442](https://github.com/user-attachments/assets/7d483b87-69d0-44c3-b035-e932cb395423)

🏠 Step 5: Explore the Home Screen
The home screen has several buttons and indicators: a settings button that opens a configuration menu, sensor cards that display detailed data for each sensor, and a 'Start Streaming' button that opens a menu to begin sending data to Liquid Galaxy. Also the home screen has two indicators of connection: to the server and to the Liquid Galaxy.
![Screenshot_1751806453](https://github.com/user-attachments/assets/165f5fca-7460-463d-b6bb-668b48f81188)

Settings Menu and Options
Pressing the settings button opens a configuration menu. Here you can choose to change the server or Liquid Galaxy connection details if your network or setup changes. On the server screen, you can update the server IP address and test the connection before saving. On the Liquid Galaxy configuration screen, you can change the LG connection details or clear all KMLs currently being displayed.
![Screenshot_1751806504](https://github.com/user-attachments/assets/fc809aaa-3b40-4ff9-9df2-4166eab35109) ![Screenshot_1751806462](https://github.com/user-attachments/assets/a5c4b6be-0a48-493e-af64-0e6400c9f927)![Screenshot_1751806466](https://github.com/user-attachments/assets/f85e71cf-6e40-4d8a-8098-2973f4a8e24b)

Sensor Data and Details
When you press a sensor card, you can see all the data from that specific sensor. This data comes from the server and is what will be shown on Liquid Galaxy. The data from the server is updated in the app every 30 seconds.
![Screenshot_1751806491](https://github.com/user-attachments/assets/957e445f-a745-4d69-81ac-32b3f8afd3bf)![Screenshot_1751806496](https://github.com/user-attachments/assets/916a388d-b021-4c2a-909d-edfabc0804e9)

📡 Step 6: Stream to the Liquid Galaxy
To start streaming you need to press the 'Start Streaming' button then a menu will appear with different options. You can choose to stream the RGB Camera, or select from the other available sensors to stream to Liquid Galaxy. If you select the Camera, it will start streaming immediately. For other sensors, you must select the one you want and then press 'Start Streaming'.
The data shown on Liquid Galaxy is updated every 30 seconds, at the same time as in the app.
![Screenshot_1751806501](https://github.com/user-attachments/assets/333a18ea-7d27-4dc0-b088-222786c13310)![Screenshot_1751806510](https://github.com/user-attachments/assets/1d62ee7c-0069-4ad5-9bde-64dad96e2914)


How Streaming Should Look Like
(Sizes are meant for bigger screens)
![Captura de pantalla 2025-07-06 155513](https://github.com/user-attachments/assets/4fe76981-35c2-4ba0-bd3a-85eb1f51bbfb)
![Captura de pantalla 2025-07-06 155544](https://github.com/user-attachments/assets/6495c8f5-159a-4b87-ae06-43229435a328)

⏹️ Step 7: End Streaming
To stop streaming, just press the 'Stop Streaming' button and the app will immediately stop sending data or images from the camera to Liquid Galaxy.
![Screenshot_1751810573](https://github.com/user-attachments/assets/b1ff3672-df68-4cc9-aa16-bce5b0ed7545)
