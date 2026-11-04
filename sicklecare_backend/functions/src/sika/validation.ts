export type SikaMessage = {
  role: 'user' | 'assistant';
  content: string;
};

export type SikaRequest = {
  prompt: string;
  history: SikaMessage[];
};

const MAX_PROMPT_LENGTH = 2000;
const MAX_HISTORY_MESSAGES = 20;
const MAX_MESSAGE_LENGTH = 2000;
const MAX_TOTAL_LENGTH = 8000;

/** Validate the only fields accepted by the authenticated Sika callable. */
export function normalizeSikaRequest(input: unknown): SikaRequest {
  if (!input || typeof input !== 'object' || Array.isArray(input)) {
    throw new TypeError('Request must be an object.');
  }

  const value = input as Record<string, unknown>;
  if (Object.keys(value).some((key) => key !== 'prompt' && key !== 'history')) {
    throw new TypeError('Request contains unsupported fields.');
  }

  if (typeof value.prompt !== 'string') {
    throw new TypeError('Prompt must be text.');
  }
  const prompt = value.prompt.trim();
  if (!prompt || prompt.length > MAX_PROMPT_LENGTH) {
    throw new TypeError('Prompt length is invalid.');
  }

  const rawHistory = value.history ?? [];
  if (!Array.isArray(rawHistory) || rawHistory.length > MAX_HISTORY_MESSAGES) {
    throw new TypeError('Conversation history is invalid.');
  }

  const history: SikaMessage[] = rawHistory.map((item) => {
    if (!item || typeof item !== 'object' || Array.isArray(item)) {
      throw new TypeError('Conversation message is invalid.');
    }
    const message = item as Record<string, unknown>;
    if (
      Object.keys(message).some((key) => key !== 'role' && key !== 'content') ||
      (message.role !== 'user' && message.role !== 'assistant') ||
      typeof message.content !== 'string'
    ) {
      throw new TypeError('Conversation message is invalid.');
    }
    const content = message.content.trim();
    if (!content || content.length > MAX_MESSAGE_LENGTH) {
      throw new TypeError('Conversation message length is invalid.');
    }
    return {role: message.role, content};
  });

  const totalLength = prompt.length +
    history.reduce((total, message) => total + message.content.length, 0);
  if (totalLength > MAX_TOTAL_LENGTH) {
    throw new TypeError('Conversation is too long.');
  }

  return {prompt, history};
}
