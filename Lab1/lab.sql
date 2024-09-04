CREATE OR REPLACE PROCEDURE control_acceso_atributos(
    p_tabla TEXT,
    p_insertar TEXT[],
    p_modificar TEXT[],
    p_eliminar TEXT[]
)
LANGUAGE plpgsql
AS $$
DECLARE
    view_name TEXT := lower(p_tabla) || '_vista_acceso';
    combined_cols TEXT[] := p_insertar || p_modificar || p_eliminar;
    valid_cols TEXT;
    col_name TEXT;
BEGIN
    RAISE NOTICE 'Tabla: %, Vista: %', p_tabla, view_name;

    -- Validar que los atributos especificados existen en la tabla
    FOREACH col_name IN ARRAY combined_cols LOOP
        PERFORM 1
        FROM information_schema.columns 
        WHERE table_name = lower(p_tabla) AND column_name = col_name;
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Atributo % no existe en la tabla %', col_name, p_tabla;
        END IF;
    END LOOP;

    -- Convertir los atributos válidos a una cadena separada por comas
    valid_cols := array_to_string(ARRAY(SELECT UNNEST(combined_cols)), ', ');
    RAISE NOTICE 'Atributos válidos: %', valid_cols;

    -- Crear la vista con los atributos permitidos
    EXECUTE format('CREATE OR REPLACE VIEW %I AS SELECT %s FROM %I;', view_name, valid_cols, lower(p_tabla));

    -- Crear la función de trigger
    EXECUTE format(' 
        CREATE OR REPLACE FUNCTION %I_trigger_func() RETURNS TRIGGER AS $body$
        BEGIN
            IF (TG_OP = ''INSERT'') THEN
                INSERT INTO %I (%s) VALUES (NEW.*);
                RETURN NEW;
            ELSIF (TG_OP = ''UPDATE'') THEN
                UPDATE %I SET (%s) = ROW(NEW.*) WHERE id = OLD.id;
                RETURN NEW;
            ELSIF (TG_OP = ''DELETE'') THEN
                DELETE FROM %I WHERE id = OLD.id;
                RETURN OLD;
            END IF;
            RETURN NULL;
        END;
        $body$ LANGUAGE plpgsql;
    ', view_name, lower(p_tabla), valid_cols, lower(p_tabla), valid_cols, lower(p_tabla));

    -- Crear el trigger asociado a la vista
    EXECUTE format('
        CREATE TRIGGER control_acceso_trigger
        INSTEAD OF INSERT OR UPDATE OR DELETE ON %I
        FOR EACH ROW EXECUTE FUNCTION %I_trigger_func();', view_name, view_name);

    RAISE NOTICE 'Trigger y función creados para la vista: %', view_name;

END;
$$;





-- Creación de tablas de pruebas

-- Tabla 1: empleados
CREATE TABLE empleados (
    id SERIAL PRIMARY KEY,
    nombre TEXT,
    apellido TEXT,
    edad INT,
    salario NUMERIC
);

-- Tabla 2: productos
CREATE TABLE productos (
    id SERIAL PRIMARY KEY,
    nombre TEXT,
    descripcion TEXT,
    precio NUMERIC,
    stock INT
);

-- Tabla 3: clientes
CREATE TABLE clientes (
    id SERIAL PRIMARY KEY,
    nombre TEXT,
    email TEXT,
    telefono TEXT,
    direccion TEXT
);



-- Ejecución de procedimiento almacenado

-- Ejemplo 1: Tabla empleados
CALL control_acceso_atributos('empleados', ARRAY['id','nombre', 'apellido'], ARRAY['edad'], ARRAY['salario']);

drop view empleados_vista_acceso ;

select * from empleados_vista_acceso;

drop view clientes_vista_acceso ;


-- Insertar en la vista empleados_vista_acceso
INSERT INTO empleados_vista_acceso (id,nombre, apellido) VALUES (208400858,'Roosevelt', 'Pérez');
insert into empleados_vista_acceso (id, nombre, apellido ) values (2, 'María', 'Gonzalez')
INSERT INTO empleados_vista_acceso (id,nombre, apellido) VALUES (3,'Marco', 'Jimenez'); 


-- Actualizar en la vista empleados_vista_acceso
UPDATE empleados_vista_acceso SET edad = 75 WHERE id = 3;

-- Eliminar en la vista empleados_vista_acceso
DELETE FROM empleados_vista_acceso WHERE id = 208400858;

----------------------------------------------------------------
-- Ejecución del procedimiento almacenado para productos
CALL control_acceso_atributos('productos', ARRAY['id', 'nombre', 'descripcion'], ARRAY['precio'], ARRAY['stock']);

-- Eliminar la vista si ya existe
DROP VIEW IF EXISTS productos_vista_acceso;

-- Seleccionar desde la vista productos_vista_acceso
SELECT * FROM productos_vista_acceso;

-- Insertar en la vista productos_vista_acceso
INSERT INTO productos_vista_acceso (id, nombre, descripcion) VALUES (1, 'Producto A', 'Descripción A');
INSERT INTO productos_vista_acceso (id, nombre, descripcion) VALUES (2, 'Producto B', 'Descripción B');
INSERT INTO productos_vista_acceso (id, nombre, descripcion) VALUES (3, 'Producto C', 'Descripción C');

-- Actualizar en la vista productos_vista_acceso
UPDATE productos_vista_acceso SET precio = 19.99 WHERE id = 1;

-- Eliminar en la vista productos_vista_acceso
DELETE FROM productos_vista_acceso WHERE id = 2;

------------------------------------------------------------------------

-- Ejecución del procedimiento almacenado para clientes
CALL control_acceso_atributos('clientes', ARRAY['id', 'nombre', 'email'], ARRAY['telefono'], ARRAY['direccion']);

-- Eliminar la vista si ya existe
DROP VIEW IF EXISTS clientes_vista_acceso;

-- Seleccionar desde la vista clientes_vista_acceso
SELECT * FROM clientes_vista_acceso;

-- Insertar en la vista clientes_vista_acceso
INSERT INTO clientes_vista_acceso (id, nombre, email) VALUES (1, 'Cliente A', 'clienteA@example.com');
INSERT INTO clientes_vista_acceso (id, nombre, email) VALUES (2, 'Cliente B', 'clienteB@example.com');
INSERT INTO clientes_vista_acceso (id, nombre, email) VALUES (3, 'Cliente C', 'clienteC@example.com');

-- Actualizar en la vista clientes_vista_acceso
UPDATE clientes_vista_acceso SET telefono = '123456789' WHERE id = 1;

-- Eliminar en la vista clientes_vista_acceso
DELETE FROM clientes_vista_acceso WHERE id = 2;

