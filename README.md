# Laboratorio 04: AWS + Lambda Integration

Descripción
-----------
Proyecto para desplegar tres entornos independientes: `dev`, `qa` y `prod`. La infraestructura está definida con Terraform en el directorio `iac/` y las funciones Lambda en `src/crop` y `src/upload`.

Requisitos
----------
- Terraform >= 1.0
- AWS CLI con un perfil configurado
- Node.js 20.x
- npm (incluido con Node.js)
- Credenciales AWS con permisos para IAM, S3, Lambda, VPC, CloudWatch y SQS

Guía de Despliegue
------------------
1) Instalar dependencias de las Lambdas

```bash
cd src/crop
npm install

cd ../upload
npm install
```

2) Preparar y desplegar Terraform

```bash
cd iac
terraform init
# Seleccionar o crear workspace por entorno (dev, qa, prod)
terraform workspace select dev || terraform workspace new dev
terraform apply
```

Notas:
- El estado por entorno se guarda en `iac/terraform.tfstate.d/`.
- `iac/terraform.tfvars` contiene valores por defecto (mapas por entorno) para `vpc_cidr`, `uploads_expiration_days`, `processed_expiration_days`, `upload_memory`, `upload_timeout`, `crop_memory`, `crop_timeout` y `log_retention_days`.
- Si necesitas sobreescribir valores, edita `iac/terraform.tfvars` o usa `terraform apply -var='key=value'`.

Variables importantes
---------------------
- Los parámetros de memoria y timeout de las Lambdas están definidos por entorno en `iac/variables.tf` y `iac/terraform.tfvars`.
- El provider AWS en `iac/providers.tf` fija `region = "us-east-1"` por defecto; cámbialo si necesitas otra región.

Estructura del proyecto
-----------------------
- `iac/` — Configuración Terraform (providers, recursos y módulos). Estado por workspace en `iac/terraform.tfstate.d/`.
- `src/crop` — Lambda que procesa/croppea imágenes.
- `src/upload` — Lambda que recibe y sube imágenes.
- `diagram.mermaid` —  Diagrama de la arquitectura.
