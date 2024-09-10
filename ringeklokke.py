import asyncio
import websockets
import json
import pygame
import os

# Initialize pygame mixer
pygame.mixer.init()

def play_sound(sound_file):
    if os.path.exists(sound_file):
        print(f"Playing sound: {sound_file}")
        pygame.mixer.music.load(sound_file)
        pygame.mixer.music.play()
    else:
        print(f"Sound file {sound_file} not found")

async def listen_to_server(uri, button_configs):
    print(f"Connecting to WebSocket server at {uri}")
    async with websockets.connect(uri) as websocket:
        print("Connected to WebSocket server")
        while True:
            try:
                message = await websocket.recv()
                print(f"Message received: {message}")
                data = json.loads(message)
                button_id = data.get('button_id')
                print(f"Button ID received: {button_id}")
                button_config = next((config for config in button_configs if config['buttonId'] == button_id), None)
                if button_config:
                    print(f"Button config found: {button_config}")
                    play_sound(button_config['sound'])
                else:
                    print(f"No matching button config found for button ID: {button_id}")
            except Exception as e:
                print(f"Error receiving message: {e}")

def load_config(file_path):
    with open(file_path, 'r') as file:
        return json.load(file)

async def main():
    config = load_config('config.json')
    server_url = config['serverUrl']
    button_configs = config['buttons']
    await listen_to_server(server_url, button_configs)

if __name__ == "__main__":
    asyncio.run(main())
