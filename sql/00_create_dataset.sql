CREATE SCHEMA IF NOT EXISTS `${PROJECT_ID}.${DATASET_ID}`
OPTIONS (
  location = '${BQ_LOCATION}',
  description = 'Datos sintéticos de origen para demostraciones del sector seguros',
  labels = [('clasificacion', 'sintetico'), ('dominio', 'seguros'), ('entorno', 'demo')]
);
