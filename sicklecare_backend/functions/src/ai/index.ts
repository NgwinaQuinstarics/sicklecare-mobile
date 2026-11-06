import axios from 'axios';
import * as functions from 'firebase-functions';
import { checkRateLimit } from '../utils';

const groqApiKey = 'GROQ_API_KEY';
const maxPromptLength = 2000;
const maxHistoryMessages = 6;
const maxHistoryMessageLength = 1000;

const emergencyPattern =
  /\b(chest pain|pain in (my )?chest|trouble breathing|difficulty breathing|shortness of breath|can't breathe|cannot breathe|fainting|unconscious|severe bleeding|high fever|douleur thoracique|difficult[eé] [àa] respirer|essoufflement|perte de connaissance|forte fi[eè]vre)\b/i;
const medicationDosePattern =
  /\b(dosage|dose|how much .* (take|use)|how many .* (take|use)|increase .* medication|dosing|posologie|combien .* (prendre|utiliser)|augmenter .* m[eé]dicament)\b/i;

export const askSika = functions
  .runWith({
    enforceAppCheck: true,
    maxInstances: 10,
    secrets: [groqApiKey],
  })
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'Sign in to use the online assistant',
      );
    }

    const prompt = typeof data?.prompt === 'string' ? data.prompt.trim() : '';
    if (prompt.length === 0 || prompt.length > maxPromptLength) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        `Prompt must contain between 1 and ${maxPromptLength} characters`,
      );
    }

    if (emergencyPattern.test(prompt)) {
      return {
        reply:
          /douleur|respirer|essoufflement|connaissance|fi[eè]vre/i.test(prompt)
            ? 'Cela peut être une urgence. Appelle les services d’urgence locaux ou rends-toi immédiatement à l’hôpital le plus proche. Sika ne peut pas évaluer ni traiter une urgence.'
            : 'This may be an emergency. Please contact local emergency services or go to the nearest hospital now. Sika cannot assess or treat emergencies.',
      };
    }

    if (medicationDosePattern.test(prompt)) {
      return {
        reply:
          'Sika cannot recommend medication doses or treatment changes. Please follow your prescription and ask your clinician or pharmacist for advice.',
      };
    }

    if (!(await checkRateLimit(context.auth.uid, 'askSika', 15, 60000))) {
      throw new functions.https.HttpsError(
        'resource-exhausted',
        'Assistant request limit reached; try again shortly',
      );
    }

    const apiKey = process.env[groqApiKey];
    if (!apiKey) {
      throw new functions.https.HttpsError(
        'failed-precondition',
        'The online assistant is not configured',
      );
    }

    const history = data?.history;
    if (history !== undefined && !Array.isArray(history)) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'History must be a list of messages',
      );
    }
    if ((history?.length ?? 0) > maxHistoryMessages) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        `History must contain at most ${maxHistoryMessages} messages`,
      );
    }

    const messages = (history ?? [])
      .map((message: unknown) => {
        if (
          message === null ||
          typeof message !== 'object' ||
          !('role' in message) ||
          !('content' in message)
        ) {
          throw new functions.https.HttpsError(
            'invalid-argument',
            'History contains an invalid message',
          );
        }

        const role = message.role;
        const content =
          typeof message.content === 'string' ? message.content.trim() : '';
        if (
          (role !== 'user' && role !== 'assistant') ||
          content.length === 0 ||
          content.length > maxHistoryMessageLength
        ) {
          throw new functions.https.HttpsError(
            'invalid-argument',
            'History contains an invalid message',
          );
        }

        return { role, content };
      });

    try {
      const response = await axios.post(
        'https://api.groq.com/openai/v1/chat/completions',
        {
          model: 'llama-3.3-70b-versatile',
          messages: [
            {
              role: 'system',
              content:
                'You are Sika, a supportive general health companion for people affected by sickle cell disease. Give brief, empathetic, general educational information only. Do not diagnose, prescribe, recommend changing treatment, or provide medication dosages. Encourage users to follow their clinician’s care plan. Direct urgent symptoms to emergency care. If uncertain, say so and recommend contacting a qualified healthcare professional.',
            },
            ...messages,
            { role: 'user', content: prompt },
          ],
          max_tokens: 450,
          temperature: 0.3,
        },
        {
          headers: {
            Authorization: `Bearer ${apiKey}`,
            'Content-Type': 'application/json',
          },
          timeout: 20000,
        },
      );

      const reply = response.data?.choices?.[0]?.message?.content;
      if (typeof reply !== 'string' || reply.trim().length === 0) {
        throw new Error('Assistant returned an empty response');
      }

      return { reply: reply.trim().slice(0, 4000) };
    } catch (error) {
      const status = axios.isAxiosError(error) ? error.response?.status : null;
      functions.logger.error('Sika provider request failed', {
        status,
        uid: context.auth.uid,
      });
      throw new functions.https.HttpsError(
        'unavailable',
        'The online assistant is temporarily unavailable',
      );
    }
  });
