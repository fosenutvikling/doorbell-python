from flask import Flask, render_template, request, redirect, url_for, jsonify, send_from_directory
from flask_socketio import SocketIO, emit
import json
import asyncio
import websockets
import pygame
from threading import Thread
import os
from datetime import datetime

# Initialize pygame mixer at the start of the script
pygame.mixer.init()

app = Flask(__name__)
socketio = SocketIO(app)  # Initialize SocketIO with Flask
CONFIG_PATH = 'config.json'
SOUNDS_PATH = 'sounds'  # Path to the sounds folder
websocket_task = None
websocket_running = False
connection_error = None  # To store connection error message
last_button_pressed = None  # To store the last button press information

def load_config():
    with open(CONFIG_PATH, 'r') as file:
        return json.load(file)

def save_config(config):
    with open(CONFIG_PATH, 'w') as file:
        json.dump(config, file, indent=4)

def get_sounds():
    """Fetch all sound files from the sounds directory."""
    return [f for f in os.listdir(SOUNDS_PATH) if f.endswith('.mp3')]

def play_sound(sound_file):
    """Play the specified sound file using Pygame."""
    if os.path.exists(sound_file):
        try:
            print(f"Playing sound: {sound_file}")
            pygame.mixer.music.stop()  # Stop any currently playing music
            pygame.mixer.music.load(sound_file)
            pygame.mixer.music.set_volume(1.0)  # Ensure the volume is set to max
            pygame.mixer.music.play()
        except pygame.error as e:
            print(f"Error playing sound: {e}")
    else:
        print(f"Sound file {sound_file} not found")

@app.route('/sounds/<path:filename>')
def serve_sound(filename):
    """Serve sound files from the sounds directory."""
    return send_from_directory(SOUNDS_PATH, filename)

async def listen_to_server(uri, button_configs):
    global websocket_running, last_button_pressed
    websocket_running = True
    try:
        async with websockets.connect(uri) as websocket:
            while websocket_running:
                try:
                    message = await websocket.recv()
                    data = json.loads(message)
                    button_id = data.get('button_id')
                    button_config = next((config for config in button_configs if config['buttonId'] == button_id), None)
                    if button_config:
                        last_button_pressed = {
                            'button_id': button_id,
                            'button_name': button_config['buttonName'],
                            'time': datetime.now().strftime('%Y-%m-%d %H:%M:%S')
                        }
                        play_sound(button_config['sound'])  # Play the sound when button is pressed
                        socketio.emit('button_press', last_button_pressed)
                        print(f"Button Name: {button_config['buttonName']} pressed at {last_button_pressed['time']}")
                    else:
                        print(f"No matching button config found for button ID: {button_id}")
                except Exception as e:
                    print(f"Error receiving message: {e}")
    except Exception as e:
        print(f"Could not connect to WebSocket server: {e}")
        global connection_error
        connection_error = str(e)
    websocket_running = False


def start_websocket():
    global websocket_task, connection_error
    connection_error = None
    if websocket_task is None or not websocket_task.is_alive():
        config = load_config()
        server_url = config['serverUrl']
        button_configs = config['buttons']
        websocket_task = Thread(target=asyncio.run, args=(listen_to_server(server_url, button_configs),))
        websocket_task.start()

def stop_websocket():
    global websocket_running
    websocket_running = False
    if websocket_task:
        websocket_task.join()

async def check_initial_connection():
    """Tries to connect when the app starts. If it fails, it sets a connection error message."""
    global connection_error
    config = load_config()
    try:
        # Attempt to connect to WebSocket to check if the server is reachable
        async with websockets.connect(config['serverUrl']):
            print("Initial connection successful")
        start_websocket()  # If successful, start the websocket service
    except Exception as e:
        connection_error = f"Failed to connect to WebSocket: {str(e)}"

def restart_service():
    """Restart the ringeklokke service to apply changes in config.json."""
    os.system('sudo systemctl restart ringeklokke.service')

@app.route('/')
def index():
    config = load_config()
    sounds = get_sounds()  # Get sound files
    return render_template('index.html', config=config, websocket_running=websocket_running, connection_error=connection_error, sounds=sounds)

@app.route('/update', methods=['POST'])
def update_config():
    config = load_config()
    config['serverUrl'] = request.form.get('serverUrl')
    buttons = []
    button_ids = request.form.getlist('buttonId')
    button_names = request.form.getlist('buttonName')
    button_sounds = request.form.getlist('buttonSound')

    for button_id, button_name, button_sound in zip(button_ids, button_names, button_sounds):
        buttons.append({
            'buttonId': button_id,
            'buttonName': button_name,
            'sound': button_sound
        })

    config['buttons'] = buttons
    save_config(config)

    # Restart the ringeklokke service to apply changes
    restart_service()

    return redirect(url_for('index'))

@app.route('/start_websocket', methods=['POST'])
def start_websocket_route():
    start_websocket()
    return redirect(url_for('index'))

@app.route('/stop_websocket', methods=['POST'])
def stop_websocket_route():
    stop_websocket()
    return redirect(url_for('index'))

if __name__ == '__main__':
    asyncio.run(check_initial_connection())  # Check connection on app start in an async context
    socketio.run(app, debug=True)  # Use SocketIO to run the app
