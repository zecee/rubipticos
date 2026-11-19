# Convenciones del proyecto

## Idioma
- Escribir código en inglés: clases, métodos, variables, archivos y nombres de tablas.
- Seguir las convenciones de nombres de Ruby y Rails.

## Organización de la lógica
- Mantener los controladores enfocados en manejar la petición y la respuesta.
- Ubicar en los modelos las asociaciones, validaciones y reglas de negocio
  propias de la entidad.
- Usar service objects cuando un caso de uso coordine varios modelos,
  integre servicios externos o tenga un flujo de varios pasos que no
  pertenezca naturalmente a un modelo.
- No crear service objects para envolver una única operación de Active Record
  sin aportar comportamiento.
- Evitar abstracciones que no aporten claridad a la solución.

## Service objects
- Implementarlos como clases Ruby simples en `app/services`.
- Nombrarlos según el caso de uso, usando namespaces cuando ayuden
  a agruparlos: `Appointments::Book`.
- Recibir dependencias y datos mediante argumentos keyword en `initialize`.
- Exponer `call` como único método público de ejecución.
- Retornar el resultado principal cuando la operación sea exitosa.
- Comunicar fallos mediante excepciones específicas o las excepciones
  de validación de Active Record; no alternar entre objetos, `false` y `nil`.
- Usar transacciones cuando varias escrituras deban completarse juntas.
- No introducir clases base o librerías de servicios sin una necesidad concreta.

## Cambios y verificación
- Seguir el estilo y los patrones existentes en el proyecto.
- Mantener cada cambio enfocado en una sola tarea.
- Agregar o actualizar tests cuando se modifica comportamiento.
- Ejecutar los tests relevantes y RuboCop antes de dar por terminado un cambio.
- No incluir secretos ni credenciales en el repositorio.

## Commits
- Usar Conventional Commits: `tipo(scope opcional): descripción`.
- Escribir las descripciones en inglés y mantenerlas breves.
- Ejemplos:
  - `feat: add appointment booking`
  - `fix: prevent overlapping appointments`
  - `refactor: extract booking service`
- Crear commits solo cuando el usuario lo solicite.
