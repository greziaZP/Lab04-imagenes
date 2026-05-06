"use strict";

const { S3Client, GetObjectCommand, PutObjectCommand } = require("@aws-sdk/client-s3");
const Jimp = require("jimp");
const path = require("path");

const s3 = new S3Client({});

exports.handler = async (event) => {
  // Array para acumular mensajes que fallaron en este batch
  const batchItemFailures = [];

  console.log(
    `crop-lambda: batch de ${event.Records.length} mensajes`,
    `| entorno: ${process.env.ENVIRONMENT}`
  );

  // Procesamos cada mensaje de forma independiente con su propio try/catch
  // Si usaramos Promise.all y uno falla, cancela todos los demas
  for (const record of event.Records) {
    try {
      await processRecord(record);
    } catch (err) {
      console.error(`Fallo el mensaje ${record.messageId}:`, err.message);
      // ReportBatchItemFailures: SQS solo reintenta ESTE mensaje,
      // no los que ya se procesaron correctamente en el mismo batch
      batchItemFailures.push({ itemIdentifier: record.messageId });
    }
  }

  return { batchItemFailures };
};

async function processRecord(record) {
  // El body del mensaje SQS contiene el JSON de notificacion de S3
  const sqsBody = JSON.parse(record.body);

  // S3 puede enviar el evento directo o envuelto en SNS
  const s3Event = sqsBody.Records
    ? sqsBody
    : JSON.parse(sqsBody.Message || record.body);

  for (const s3Record of s3Event.Records) {
    const srcBucket = s3Record.s3.bucket.name;

    // La key puede tener caracteres URL-encoded (ej: espacios como %20)
    const srcKey = decodeURIComponent(
      s3Record.s3.object.key.replace(/\+/g, " ")
    );

    console.log(`Procesando: s3://${srcBucket}/${srcKey}`);

    // Paso 6: descargar imagen original de S3
    const { Body } = await s3.send(
      new GetObjectCommand({ Bucket: srcBucket, Key: srcKey })
    );
    const inputBuffer = await streamToBuffer(Body);

    // Paso 7: recortar a 40x40 con mascara circular
    const outputBuffer = await cropCircular(inputBuffer);

    // Construir key de destino
    // uploads/abc123.jpg → processed/abc123_circular.png
    const base    = path.basename(srcKey, path.extname(srcKey));
    const destKey = `${process.env.PROCESSED_PREFIX}${base}_circular.png`;

    // Guardar PNG circular en S3
    await s3.send(new PutObjectCommand({
      Bucket:      srcBucket,
      Key:         destKey,
      Body:        outputBuffer,
      ContentType: "image/png",
      Metadata:    { "source-key": srcKey }
    }));

    console.log(`Guardado: s3://${srcBucket}/${destKey}`);
  }
}

async function cropCircular(inputBuffer) {
  // Leer la imagen con Jimp
  const image = await Jimp.read(inputBuffer);

  // cover(40, 40): redimensiona manteniendo proporcion y recorta
  // el exceso desde el centro para llenar exactamente 40x40
  image.cover(40, 40);

  // Crear mascara circular: 40x40 con fondo negro
  // Negro = transparente, Blanco = opaco (en el sistema de mascaras de Jimp)
  const mask = new Jimp(40, 40, 0x000000ff);
  const cx = 20, cy = 20, r = 20;

  mask.scan(0, 0, 40, 40, function(x, y, idx) {
    const dist = Math.sqrt((x - cx) ** 2 + (y - cy) ** 2);
    if (dist <= r) {
      // Pixeles dentro del circulo: blancos (visibles)
      this.bitmap.data[idx]     = 255; // R
      this.bitmap.data[idx + 1] = 255; // G
      this.bitmap.data[idx + 2] = 255; // B
      this.bitmap.data[idx + 3] = 255; // A
    }
    // Pixeles fuera del circulo quedan negros (transparentes)
  });

  // Aplicar mascara: donde la mascara es blanca el pixel es visible,
  // donde es negra el pixel queda transparente
  image.mask(mask, 0, 0);

  // Devolver como PNG (necesario para preservar la transparencia)
  return image.getBufferAsync(Jimp.MIME_PNG);
}

// Convierte el ReadableStream de S3 GetObject en un Buffer
// El SDK v3 devuelve streams, no buffers directamente
function streamToBuffer(stream) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    stream.on("data",  (chunk) => chunks.push(chunk));
    stream.on("end",   ()      => resolve(Buffer.concat(chunks)));
    stream.on("error", reject);
  });
}