const express = require('express');
const app = express();
const PORT = 3000;

app.get('/tasks', (req,res) => {
    res.json([
        {id: 1, task: 'Learn Docker' },
        {id: 2, task: 'Deploy to AKS' },
    ]);
});

app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
});