# Caso del Mundo Real: Procedimientos Almacenados Dinámicos en PostgreSQL
### Contexto
Eres el administrador de bases de datos de una empresa tecnológica en crecimiento que maneja múltiples tablas en su base de datos PostgreSQL. Para facilitar el mantenimiento y garantizar la integridad de los datos, se ha decidido automatizar la generación de procedimientos almacenados que permitan eliminar y modificar registros en estas tablas.
### Tarea
Tu tarea consiste en crear un procedimiento almacenado en PostgreSQL que, de manera dinámica, genere otros procedimientos para eliminar y modificar registros en cualquier tabla de la base de datos. Estos procedimientos generados deben estar basados en la llave primaria de cada tabla.
### Requisitos Específicos
- Generación Dinámica de Procedimientos de Eliminación:
- Crea un procedimiento almacenado que genere, para cualquier tabla especificada, un procedimiento que permita eliminar registros de esa tabla.
- El procedimiento de eliminación debe utilizar la llave primaria de la tabla como filtro para asegurar la eliminación precisa de registros.
- Generación Dinámica de Procedimientos de Modificación:
- Crea un procedimiento almacenado que genere, para cualquier tabla especificada, un procedimiento que permita modificar registros de esa tabla.
- El procedimiento de modificación debe permitir actualizar cualquier columna, utilizando la llave primaria de la tabla como filtro.
### Uso de information_schema:
Utiliza information_schema para extraer información sobre las tablas y las llaves primarias. Esto garantizará que los procedimientos generados sean aplicables a cualquier tabla en la base de datos.
### Creación del Procedimiento con Cursores:
Desarrolla un procedimiento almacenado adicional que recorra todas las tablas de la base de datos utilizando cursores e invoque los procedimientos de generación de código para eliminar y modificar datos en cada tabla.
### Eficiencia y Documentación:
Asegúrate de que el código SQL sea eficiente y esté bien documentado, con comentarios que expliquen claramente la lógica detrás de cada paso.
Entrega
Deberás entregar el código SQL completo que realiza estas tareas, asegurándote de que sea funcional y esté bien estructurado.
