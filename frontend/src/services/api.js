// frontend/src/services/api.js

const API_BASE = 'http://localhost:3000/api/v1';

export const analyzeWorriesAPI = async (text) => {
  const response = await fetch(`${API_BASE}/gemini/analyze_worries`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ text })
  });
  if (!response.ok) throw new Error("API request failed");
  return response.json();
};

export const generateStepsAPI = async (goal) => {
  const response = await fetch(`${API_BASE}/gemini/generate_steps`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ goal })
  });
  if (!response.ok) throw new Error("API request failed");
  return response.json();
};

export const generatePlanAPI = async (goal, steps) => {
  const response = await fetch(`${API_BASE}/gemini/generate_plan`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ goal, steps })
  });
  if (!response.ok) throw new Error("API request failed");
  return response.json();
};

export const processUnplannedTaskAPI = async (input) => {
  const response = await fetch(`${API_BASE}/gemini/process_unplanned_task`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ input })
  });
  if (!response.ok) throw new Error("API request failed");
  const data = await response.json();
  return data.title;
};