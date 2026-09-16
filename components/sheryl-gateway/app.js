const express = require('express');
const axios = require('axios');
const fs = require('fs');
const path = require('path');
const { Storage } = require('@google-cloud/storage');
require('dotenv').config();

const app = express();
app.use(express.json());

const storage = new Storage();
const BUCKET_NAME = process.env.GCS_MEMORY_BUCKET || 'suad-sheryl-memory-suad-claw-nexus-hybrid-01';
const bucket = storage.bucket(BUCKET_NAME);

const PORT = process.env.PORT || 8080;
const TELEGRAM_TOKEN = process.env.TELEGRAM_TOKEN;
const LITELLM_URL = process.env.LITELLM_URL || 'https://suad-litellm-proxy-398899866173.us-east4.run.app/v1';
const APINOW_TOKEN = process.env.APINOW_TOKEN;
const MODEL = process.env.MODEL || 'gemini-flash';
const MAX_TURNS = 30;
const WEBHOOK_URL = process.env.WEBHOOK_URL;
// Register webhook with Telegram
async function registerWebhook() {
  if (!WEBHOOK_URL) {
    console.warn('WEBHOOK_URL not set; skipping webhook registration.');
    return;
  }
  try {
    const resp = await axios.get(`https://api.telegram.org/bot${TELEGRAM_TOKEN}/setWebhook?url=${encodeURIComponent(WEBHOOK_URL)}`);
    console.log('Webhook registration response:', resp.data);
  } catch (err) {
    console.error('Failed to register webhook:', err.message);
  }
}

// Load system memory (fallback to local file)
async function loadSystemMemory() {
  try {
    const file = bucket.file('sherylmemory.md');
    const [exists] = await file.exists();
    if (exists) {
      const [contents] = await file.download();
      return contents.toString('utf8');
    }
  } catch (err) {
    console.error('Failed reading sherylmemory.md from GCS:', err.message);
  }
  const localPath = path.join(__dirname, 'sherylmemory.md');
  if (fs.existsSync(localPath)) {
    return fs.readFileSync(localPath, 'utf8');
  }
  return 'You are Sheryl.';
}

// Load per-chat session history
async function getChatHistory(chatId) {
  try {
    const file = bucket.file(`sessions/${chatId}.json`);
    const [exists] = await file.exists();
    if (exists) {
      const [contents] = await file.download();
      return JSON.parse(contents.toString('utf8'));
    }
  } catch (err) {
    console.error(`Error loading session ${chatId} from GCS:`, err.message);
  }
  return [];
}

// Save per-chat session history
async function saveChatHistory(chatId, history) {
  try {
    const file = bucket.file(`sessions/${chatId}.json`);
    await file.save(JSON.stringify(history, null, 2), { contentType: 'application/json', resumable: false });
  } catch (err) {
    console.error(`Error saving session ${chatId} to GCS:`, err.message);
  }
}

app.get('/', (req, res) => res.status(200).send('Sheryl Gateway with GCS Persistent Memory is active.'));
app.get('/healthz', (req, res) => res.status(200).send('OK'));

app.post('/telegram-webhook', async (req, res) => {
  // Log raw payload for debugging
  console.log('Telegram webhook received:', JSON.stringify(req.body));
  res.sendStatus(200);
  // Support various update types
  const update = req.body || {};
  const message = update.message || update.edited_message || update.channel_post || update.edited_channel_post;
  if (!message?.text) {
    console.warn('No text in incoming update, ignoring');
    return;
  }

  const chatId = message.chat?.id;
  const userText = message.text;

  const [systemMemory, history] = await Promise.all([loadSystemMemory(), getChatHistory(chatId)]);

  history.push({ role: 'user', content: userText });
  if (history.length > MAX_TURNS) history.splice(0, history.length - MAX_TURNS);

  const payload = [{ role: 'system', content: systemMemory }, ...history];

  try {
    const llmResp = await axios.post(
      `${LITELLM_URL}/chat/completions`,
      { model: MODEL, messages: payload },
      { headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${APINOW_TOKEN}` }, timeout: 45000 }
    );
    const reply = llmResp.data?.choices?.[0]?.message?.content || '...';
    history.push({ role: 'assistant', content: reply });

    await Promise.all([
      saveChatHistory(chatId, history),
      axios.post(`https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage`, { chat_id: chatId, text: reply }, { timeout: 10000 })
    ]);
  } catch (err) {
    console.error('Relay Error:', err?.response?.data || err.message);
  }
});

app.listen(PORT, '0.0.0.0', async () => {
  await registerWebhook();
  console.log(`Sheryl Gateway listening on 0.0.0.0:${PORT} with GCS bucket ${BUCKET_NAME}`);
});

