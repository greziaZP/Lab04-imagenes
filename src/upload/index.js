"use strict";

const { S3Client, PutObjectCommand } = require("@aws-sdk/client-s3");
const busboy = require("busboy");
const { v4: uuidv4 } = require("uuid");

// Reutilizar el cliente entre invocaciones calientes (warm start)
// evita reconectar TCP en cada llamada y reduce latencia
const s3 = new S3Client({});

const ALLOWED_TYPES = new Set([
  "image/jpeg",
  "image/png",
  "image/gif",
  "image/webp"
]);

const MAX_BYTES = 10 * 1024 * 1024; // 10 MB

const MIME_TO_EXT = {
  "image/jpeg": "jpg",
  "image/png":  "png",
  "image/gif":  "gif",
  "image/webp": "webp"
};

// Lambda siempre exporta una funcion llamada "handler"
// que coincide con handler = "index.handler" en Terraform
exports.handler = async (event) => {
  console.log("upload-lambda iniciada | entorno:", process.env.ENVIRONMENT);

  try {
    const headers = event.headers || {};
    const contentType = (
      headers["content-type"] || headers["Content-Type"] || ""
    ).toLowerCase();

    let buffer, mime, filename = "upload";

    if (contentType.includes("multipart/form-data")) {
      const parsed = await parseMultipart(event);
      buffer   = parsed.buffer;
      mime     = parsed.mime;
      filename = parsed.filename || filename;

    } else if (contentType.includes("application/json")) {
      const body = JSON.parse(event.body || "{}");
      mime     = body.contentType;
      filename = body.filename || filename;
      buffer   = Buffer.from(body.image, "base64");

    } else {
      return respond(415, {
        error: "Content-Type no soportado. Usa multipart/form-data o application/json."
      });
    }

    // Validar tipo de archivo
    if (!ALLOWED_TYPES.has(mime)) {
      return respond(400, {
        error: `Tipo no permitido: ${mime}. Validos: jpg, png, gif, webp.`
      });
    }

    // Validar tamanio
    if (buffer.length > MAX_BYTES) {
      return respond(400, {
        error: `Imagen demasiado grande. Maximo 10 MB.`
      });
    }

    if (buffer.length === 0) {
      return respond(400, { error: "El archivo esta vacio." });
    }

    // Guardar en S3 con nombre unico
    const key = `${process.env.UPLOAD_PREFIX}${uuidv4()}.${MIME_TO_EXT[mime]}`;

    await s3.send(new PutObjectCommand({
      Bucket:      process.env.S3_BUCKET,
      Key:         key,
      Body:        buffer,
      ContentType: mime,
      Metadata: {
        "original-name": filename.replace(/[^\w.\-]/g, "_")
      }
    }));

    console.log(`Guardado: s3://${process.env.S3_BUCKET}/${key}`);

    return respond(200, {
      message: "Imagen subida exitosamente.",
      key,
      bucket: process.env.S3_BUCKET
    });

  } catch (err) {
    console.error("Error en upload-lambda:", err);
    return respond(500, { error: "Error interno del servidor." });
  }
};

// Parsea multipart/form-data usando busboy
function parseMultipart(event) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    let mime = "", filename = "";

    const bb = busboy({
      headers: {
        "content-type": event.headers["content-type"]
          || event.headers["Content-Type"]
      },
      limits: { fileSize: MAX_BYTES + 1 }
    });

    bb.on("file", (_field, stream, info) => {
      mime     = info.mimeType;
      filename = info.filename;
      stream.on("data", (chunk) => chunks.push(chunk));
      stream.on("limit", () => reject(new Error("FILE_TOO_LARGE")));
    });

    bb.on("close", () =>
      resolve({ buffer: Buffer.concat(chunks), mime, filename })
    );
    bb.on("error", reject);

    // API Gateway puede enviar el body en base64 si el payload es binario
    const body = event.isBase64Encoded
      ? Buffer.from(event.body, "base64")
      : Buffer.from(event.body || "");

    bb.write(body);
    bb.end();
  });
}

// Construye respuestas HTTP uniformes
function respond(statusCode, body) {
  return {
    statusCode,
    headers: {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*"
    },
    body: JSON.stringify(body)
  };
}