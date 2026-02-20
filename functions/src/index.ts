import { onRequest } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import * as vision from '@google-cloud/vision';
import { filterLabels } from './ingredientFilter';

admin.initializeApp();

const visionClient = new vision.ImageAnnotatorClient();

export const analyzeIngredients = onRequest(
  {
    cors: true,
    region: 'us-central1',
    timeoutSeconds: 30,
    memory: '256MiB',
  },
  async (req, res) => {
    // Only accept POST
    if (req.method !== 'POST') {
      res.status(405).json({ error: 'Method not allowed' });
      return;
    }

    // Verify Firebase ID token
    const authHeader = req.headers.authorization ?? '';
    if (!authHeader.startsWith('Bearer ')) {
      res.status(401).json({ error: 'Unauthorized' });
      return;
    }
    try {
      await admin.auth().verifyIdToken(authHeader.split('Bearer ')[1]);
    } catch {
      res.status(401).json({ error: 'Unauthorized' });
      return;
    }

    // Validate input
    const { imageBase64 } = req.body as { imageBase64?: string };
    if (!imageBase64) {
      res.status(400).json({ error: 'imageBase64 is required' });
      return;
    }

    // Call Google Cloud Vision
    let visionResult;
    try {
      [visionResult] = await visionClient.labelDetection({
        image: { content: imageBase64 },
      });
    } catch (err) {
      console.error('Vision API error', err);
      res.status(500).json({ error: 'Vision API error' });
      return;
    }

    const rawLabels = (visionResult.labelAnnotations ?? []).map(l => ({
      description: l.description ?? '',
      score: l.score ?? 0,
    }));

    const ingredients = filterLabels(rawLabels);

    res.json({ ingredients });
  }
);
