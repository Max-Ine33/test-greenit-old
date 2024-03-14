# app.py
import subprocess
import os
from flask import Flask, render_template
from flask_socketio import SocketIO

app = Flask(__name__, static_url_path='/static', static_folder='static')
socketio = SocketIO(app)
current_directory = os.getcwd()  # Get initial current directory

@app.route('/')
def index():
    return render_template('terminal.html')

@socketio.on('connect')
def connect():
    print('Client connected')

@socketio.on('disconnect')
def disconnect():
    print('Client disconnected')

import re

def remove_ansi_escape_codes(text):
    ansi_escape = re.compile(r'\x1B\[[0-?]*[ -/]*[@-~]')
    return ansi_escape.sub('', text)

@socketio.on('terminal_input')
def handle_terminal_input(command):
    global current_directory
    if command.startswith('cd '):
        directory = command.split(' ')[1]  # Extract directory from command
        try:
            os.chdir(directory)  # Change directory
            current_directory = os.getcwd()  # Update current directory
        except FileNotFoundError:
            emit_terminal_output(f"cd: {directory}: No such file or directory\n")
    else:
        process = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, bufsize=1, universal_newlines=True)
        for line in process.stdout:
            cleaned_line = remove_ansi_escape_codes(line.strip())
            emit_terminal_output(cleaned_line)
        process.wait()

def emit_terminal_output(output):
    socketio.emit('terminal_output', output)

if __name__ == '__main__':
    socketio.run(app, host='0.0.0.0', port=5000, debug=True)
