const express = require('express');
const { v4: uuidv4 } = require('uuid');
const http = require('http');
const WebSocket = require('ws');
const path = require('path');

const app = express();
const server = http.createServer(app);
const wss = new WebSocket.Server({ server });
const port = process.env.PORT || 8080;

// Store active workouts in memory
const activeWorkouts = new Map();

app.use(express.json());
app.use(express.static('public'));

// Root endpoint now serves the dashboard
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// Health check endpoint
app.get('/health', (req, res) => {
    res.status(200).send('OK');
});

// Workout API endpoints
app.post('/api/v1/workouts', (req, res) => {
    const workoutId = uuidv4();
    const workout = {
        id: workoutId,
        ...req.body,
        createdAt: new Date(),
        updatedAt: new Date()
    };
    activeWorkouts.set(workoutId, workout);
    console.log('Created workout:', workoutId);
    res.status(201).json({ id: workoutId });
});

app.put('/api/v1/workouts/:id', (req, res) => {
    const { id } = req.params;
    const workout = activeWorkouts.get(id);
    if (workout) {
        // Update workout with new data
        Object.assign(workout, req.body, { updatedAt: new Date() });
        activeWorkouts.set(id, workout);
        
        // Broadcast to WebSocket clients for this facility
        broadcastWorkoutUpdate(workout);
    }
    console.log('Updated workout:', id, req.body);
    res.status(200).json({ message: 'Updated', id });
});

// WebSocket connection handling
wss.on('connection', (ws, req) => {
    const url = new URL(req.url, `http://${req.headers.host}`);
    const facilityID = url.pathname.split('/')[4]; // Extract from /api/v1/workouts/{facilityID}/listen
    
    console.log(`WebSocket client connected for facility: ${facilityID}`);
    
    ws.on('message', (message) => {
        // Handle ping/pong or other messages
        console.log('WebSocket message received:', message.toString());
    });
    
    ws.on('close', () => {
        console.log(`WebSocket client disconnected for facility: ${facilityID}`);
    });
    
    // Store facilityID with the connection
    ws.facilityID = facilityID;
});

function broadcastWorkoutUpdate(workout) {
    // Create participant data for the dashboard
    const participant = {
        userId: workout.userID || workout.id,
        displayName: workout.firstName || 'Anonymous',
        heartRate: workout.heartRate || Math.floor(Math.random() * 100 + 60),
        totalPoints: workout.totalPoints || 0,
        activeEnergyBurned: workout.activeEnergyBurned || 80,
        dateOfBirth: '1990-01-01', // Default for age calculation
        weight: 70
    };
    
    // Broadcast to all connected WebSocket clients
    wss.clients.forEach((client) => {
        if (client.readyState === WebSocket.OPEN) {
            client.send(JSON.stringify(participant));
        }
    });
}

// Handle WebSocket upgrade for the listen endpoint
app.get('/api/v1/workouts/:facilityID/listen', (req, res) => {
    res.status(426).json({ 
        message: 'Upgrade Required',
        note: 'This endpoint requires WebSocket connection',
        facilityID: req.params.facilityID 
    });
});

server.listen(port, '0.0.0.0', () => {
    console.log(`FOD Server with WebSocket running on port ${port}`);
});