import {
  GetObjectCommand,
  HeadObjectCommand,
  PutObjectCommand,
  S3Client,
  S3ServiceException,
} from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { defineSecret } from 'firebase-functions/params';

const accessKeyId = defineSecret('AWS_ACCESS_KEY_ID');
const secretAccessKey = defineSecret('AWS_SECRET_ACCESS_KEY');

export const credentialStorageSecrets = [accessKeyId, secretAccessKey];

let client: S3Client | undefined;

function getClient(): S3Client {
  if (client) return client;
  const credentials = {
    accessKeyId: accessKeyId.value(),
    secretAccessKey: secretAccessKey.value(),
  };
  if (!credentials.accessKeyId || !credentials.secretAccessKey) {
    throw new Error('AWS credential-storage secrets are not configured.');
  }
  client = new S3Client({
    region: process.env.AWS_S3_REGION || 'us-east-1',
    credentials,
  });
  return client;
}

function getBucket(): string {
  const bucket = process.env.AWS_S3_BUCKET?.trim();
  if (!bucket) throw new Error('AWS_S3_BUCKET is not configured.');
  return bucket;
}

export async function createCredentialUploadUrl(
  key: string,
  contentType: string,
  size: number,
): Promise<{ url: string; headers: Record<string, string> }> {
  const headers = {
    'Content-Type': contentType,
    'x-amz-server-side-encryption': 'AES256',
  };
  const command = new PutObjectCommand({
    Bucket: getBucket(),
    Key: key,
    ContentType: contentType,
    ContentLength: size,
    ServerSideEncryption: 'AES256',
  });
  return {
    url: await getSignedUrl(getClient(), command, { expiresIn: 300 }),
    headers,
  };
}

export async function inspectCredential(
  key: string,
): Promise<{ contentType: string | undefined; size: number | undefined }> {
  const result = await getClient().send(new HeadObjectCommand({
    Bucket: getBucket(),
    Key: key,
  }));
  return { contentType: result.ContentType, size: result.ContentLength };
}

export async function downloadCredential(key: string): Promise<Buffer> {
  const result = await getClient().send(new GetObjectCommand({
    Bucket: getBucket(),
    Key: key,
  }));
  if (!result.Body) throw new Error('The credential object has no content.');
  return Buffer.from(await result.Body.transformToByteArray());
}

export async function createCredentialViewUrl(key: string): Promise<string> {
  return getSignedUrl(
    getClient(),
    new GetObjectCommand({
      Bucket: getBucket(),
      Key: key,
      ResponseContentDisposition: 'attachment',
    }),
    { expiresIn: 300 },
  );
}

export function isCredentialNotFound(error: unknown): boolean {
  return error instanceof S3ServiceException &&
    (error.$metadata.httpStatusCode === 404 || error.name === 'NotFound');
}

export async function credentialExists(key: string): Promise<boolean> {
  try {
    await inspectCredential(key);
    return true;
  } catch (error) {
    if (isCredentialNotFound(error)) return false;
    throw error;
  }
}
