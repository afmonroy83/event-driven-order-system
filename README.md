# Arquitectura de Microservicios con Docker Compose

Este proyecto implementa una arquitectura de microservicios que gestiona **órdenes** y **clientes**, utilizando **PostgreSQL** como base de datos y **RabbitMQ** como sistema de mensajería para comunicación asincrónica.

---

## Diagrama de Arquitectura

![Arquitectura de Microservicios](./arquitectura.png)

---

## Servicios incluidos

| Servicio             | Puerto Expuesto | Descripción |
|----------------------|-----------------|-------------|
| **order-service**    | `3000`          | API REST para crear y consultar órdenes. |
| **customer-service** | `3001`          | API REST para gestionar clientes. |
| **order-db**         | interno         | Base de datos PostgreSQL para órdenes. |
| **customer-db**      | interno         | Base de datos PostgreSQL para clientes. |
| **rabbitmq**         | `5672`, `15672` | Broker de mensajería con panel de administración en `http://localhost:15672`. |
| **customer-consumer**| interno         | Servicio consumidor que escucha eventos `OrderCreated` desde RabbitMQ y actualiza la base de datos de clientes. |

---

## Endpoints principales

- **Order Service (localhost:3000)**
  - `POST /api/v1/orders` → Crear una nueva orden.
  - `GET /api/v1/orders?customer_id=1` → Consultar órdenes por cliente.

- **Customer Service (localhost:3001)**
  - `GET /api/v1/customers/:id` → Obtener información de un cliente.

---

## Requisitos previos

- Docker y Docker Compose instalados.
- Puertos `3000`, `3001`, `5672`, `15672` disponibles en tu máquina.

---
## Permisos para el script `entrypoint.sh`

El servicio **customer_service** utiliza un script `entrypoint.sh` que debe tener permisos de ejecución para poder correr correctamente dentro del contenedor.  

Ejecuta el siguiente comando en la raíz del proyecto:

```bash
chmod +x services/customer_service/entrypoint.sh

## Levantar el proyecto

```bash
docker-compose up --build

## Inicialización de las Bases de Datos

Una vez levantados los servicios con `docker compose up`, es necesario crear, migrar y poblar las bases de datos de cada microservicio.  

Ejecuta los siguientes comandos:

```bash
# Inicializar la base de datos del Customer Service
docker compose exec customer-service rails db:create db:migrate db:seed
# Salida esperada:
# Created database 'customer_service_development'
# Created database 'customer_service_test'

# Inicializar la base de datos del Order Service
docker compose exec order-service rails db:create db:migrate db:seed
# Salida esperada:
# Created database 'order_service_development'
# Created database 'order_service_test'

## Ejecutar Tests

Para correr la suite de pruebas del **Order Service**, utiliza el siguiente comando dentro de tu proyecto:

```bash
docker compose exec order-service bundle exec rails spec

Para correr la suite de pruebas del **Customer Service**, utiliza el siguiente comando dentro de tu proyecto:

```bash
docker compose exec customer-service bundle exec rails spec
