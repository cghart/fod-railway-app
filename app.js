const express = require('express');
const { v4: uuidv4 } = require('uuid');

const app = express();
const port = process.env.PORT || 8080;

app.use(express.json());

// Health check endpoint
app.get('/health', (req, res) => {
    res.status(200).send('OK');
});

// Workout API endpoints
app.post('/api/v1/workouts', (req, res) => {
    const workoutId = uuidv4();
    console.log('Created workout:', workoutId);
    res.status(201).json({ id: workoutId });
});

app.put('/api/v1/workouts/:id', (req, res) => {
    const { id } = req.params;
    console.log('Updated workout:', id, req.body);
    res.status(200).json({ message: 'Updated', id });
});

app.get('/api/v1/workouts/:facilityID/listen', (req, res) => {
    const { facilityID } = req.params;
    console.log('WebSocket endpoint requested for facility:', facilityID);
    res.status(200).json({ message: 'WebSocket endpoint', facilityID });
});

app.listen(port, '0.0.0.0', () => {
    console.log(`FOD API Server running on port ${port}`);
});