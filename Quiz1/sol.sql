CREATE OR REPLACE FUNCTION public.createinsertfunction(
	p_schemaname character varying,
	p_tablename character varying)
    RETURNS character varying
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE
	vColumnas REFCURSOR;
	vListaParametros		varchar;
	vListaParametrosSinTipo	varchar;
	vListaAtributos			varchar;
	vSQL	varchar;
	vRegistro RECORD;
BEGIN
	vSQL:='CREATE OR REPLACE FUNCTION '||p_schemaName||'.ins_'||p_tableName||' (';
	vListaParametros:='';
	vListaParametrosSinTipo:='';
	vListaAtributos:='';
	OPEN vColumnas FOR
		SELECT column_name,data_type
		FROM information_schema.columns
		WHERE table_schema=p_schemaName and table_name = p_tableName;
	LOOP
	    FETCH vColumnas INTO vRegistro;
		IF FOUND THEN
			vListaParametros := vListaParametros || 'p_'||  vRegistro.column_name ||' '|| vRegistro.data_type || ', ';
			vListaParametrosSinTipo := vListaParametrosSinTipo || 'p_'|| vRegistro.column_name || ', ';
			vListaAtributos := vListaAtributos || vRegistro.column_name || ', ';
		ELSE
			EXIT;
		END IF ;
	END LOOP ;
	CLOSE vColumnas;
	vListaParametros:=substring(vListaParametros,0,length(vListaParametros)-1);
	vListaParametrosSinTipo:=substring(vListaParametrosSinTipo,0,length(vListaParametrosSinTipo)-1);
	vListaAtributos:=substring(vListaAtributos,0,length(vListaAtributos)-1);
	vSQL:=vSQL || vListaParametros || ')' || E'\n' || 'RETURNS void'|| E'\n';
	vSQL:=vSQL || 'AS' || E'\n' || E'\$' || E'\$' || E'\n' || 'BEGIN' || E'\n';
	vSQL:=vSQL || E'\t' || 'INSERT INTO ' || p_schemaName || '.' || p_tableName;
	vSQL:=vSQL || '(' || vListaAtributos || ')' || E'\n';
	vSQL:=vSQL || E'\t' || 'VALUES (' || vListaParametrosSinTipo || ');' || E'\n';
	vSQL:=vSQL || 'END' || E'\n'|| E'\$' || E'\$' || E'\n' ||'LANGUAGE PLPGSQL;';
	execute vSQL;
	return vSQL;
END;
$BODY$;


-- FUNCTION: public.generatefunctions()

-- DROP FUNCTION IF EXISTS public.generatefunctions();

CREATE OR REPLACE FUNCTION public.generatefunctions(
	)
    RETURNS void
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE
	vtables REFCURSOR;
	vtable	RECORD;
	vSql	varchar;
	v_table_name varchar;
	v_table_schema varchar;
BEGIN
	OPEN vTables FOR
		SELECT table_schema,table_name, table_type
		FROM information_schema.tables
		WHERE table_schema not in ('pg_catalog','information_schema') and table_type='BASE TABLE';
	LOOP
		FETCH vtables INTO vtable;
		IF FOUND THEN
			raise notice 'Esquema: % tabla: %',vtable.table_schema,vtable.table_name;
			v_table_name:= vtable.table_name;
			v_table_schema:= vtable.table_schema;
			 vsql:=public.createinsertfunction(v_table_schema,v_table_name);
			 
		ELSE
			EXIT;
		END IF ;
	END LOOP ;
CLOSE vTables;
END;
$BODY$;


CREATE TABLE public.test_table (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);




SELECT public.generatefunctions();

SELECT public.createinsertfunction('public', 'test_table');

SELECT public.ins_test_table('208400858', 'Roosevelt', 'roperez@tec.cr', current_date);

SELECT * from test_table;

-- hasta aquí llegó el ejemplo de Leonardo 

CREATE OR REPLACE FUNCTION public.create_delete_function(
    p_schemaname character varying,
    p_tablename character varying
) RETURNS character varying
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    vPrimaryKeyName varchar;
    vSQL varchar;
BEGIN
    -- Obtener el nombre de la llave primaria de la tabla
    SELECT kcu.column_name
    INTO vPrimaryKeyName
    FROM information_schema.table_constraints tc
    JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
    WHERE tc.table_schema = p_schemaname 
    AND tc.table_name = p_tablename 
    AND tc.constraint_type = 'PRIMARY KEY';

    -- Generar el SQL para el procedimiento de eliminación
    vSQL := 'CREATE OR REPLACE FUNCTION ' || p_schemaname || '.del_' || p_tablename || '(' || vPrimaryKeyName || ' ' || (SELECT data_type FROM information_schema.columns WHERE table_schema = p_schemaname AND table_name = p_tablename AND column_name = vPrimaryKeyName) || ') RETURNS void AS $$' ||
    'BEGIN ' ||
    'DELETE FROM ' || p_schemaname || '.' || p_tablename || ' WHERE ' || vPrimaryKeyName || ' = $1;' ||
    'END; $$ LANGUAGE plpgsql;';

    -- Ejecutar la sentencia SQL generada
    EXECUTE vSQL;
    RETURN vSQL;
END;
$BODY$;


CREATE OR REPLACE FUNCTION public.create_update_function(
    p_schemaname character varying,
    p_tablename character varying
) RETURNS character varying
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    vColumnas REFCURSOR;
    vListaParametros varchar;
    vListaSet varchar;
    vPrimaryKeyName varchar;
    vSQL varchar;
    vRegistro RECORD;
BEGIN
    -- Obtener el nombre de la llave primaria de la tabla
    SELECT kcu.column_name
    INTO vPrimaryKeyName
    FROM information_schema.table_constraints tc
    JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
    WHERE tc.table_schema = p_schemaname 
    AND tc.table_name = p_tablename 
    AND tc.constraint_type = 'PRIMARY KEY';

    -- Generar la lista de columnas para SET y los parámetros
    OPEN vColumnas FOR
        SELECT column_name, data_type
        FROM information_schema.columns
        WHERE table_schema = p_schemaname 
        AND table_name = p_tablename;

    vListaParametros := '';
    vListaSet := '';
    LOOP
        FETCH vColumnas INTO vRegistro;
        EXIT WHEN NOT FOUND;
        IF vRegistro.column_name != vPrimaryKeyName THEN
            vListaParametros := vListaParametros || 'p_' || vRegistro.column_name || ' ' || vRegistro.data_type || ', ';
            vListaSet := vListaSet || vRegistro.column_name || ' = ' || 'p_' || vRegistro.column_name || ', ';
        END IF;
    END LOOP;
    CLOSE vColumnas;

    -- Quitar la última coma y espacio
    vListaParametros := substring(vListaParametros, 1, length(vListaParametros) - 2);
    vListaSet := substring(vListaSet, 1, length(vListaSet) - 2);

    -- Generar el SQL para el procedimiento de modificación
    vSQL := 'CREATE OR REPLACE FUNCTION ' || p_schemaname || '.upd_' || p_tablename || '(' || vListaParametros || ', p_' || vPrimaryKeyName || ' ' || (SELECT data_type FROM information_schema.columns WHERE table_schema = p_schemaname AND table_name = p_tablename AND column_name = vPrimaryKeyName) || ') RETURNS void AS $$' ||
    'BEGIN ' ||
    'UPDATE ' || p_schemaname || '.' || p_tablename || ' SET ' || vListaSet || ' WHERE ' || vPrimaryKeyName || ' = p_' || vPrimaryKeyName || ';' ||
    'END; $$ LANGUAGE plpgsql;';

    -- Ejecutar la sentencia SQL generada
    EXECUTE vSQL;
    RETURN vSQL;
END;
$BODY$;



CREATE OR REPLACE FUNCTION public.generatefunctions()
RETURNS void
LANGUAGE 'plpgsql'
COST 100
VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE
    vtables REFCURSOR;
    vtable RECORD;
    vSql varchar;
    v_table_name varchar;
    v_table_schema varchar;
BEGIN
    -- Abrir el cursor para obtener todas las tablas base
    OPEN vTables FOR
        SELECT table_schema, table_name, table_type
        FROM information_schema.tables
        WHERE table_schema NOT IN ('pg_catalog', 'information_schema') AND table_type = 'BASE TABLE';
    
    -- Iterar sobre las tablas
    LOOP
        FETCH vtables INTO vtable;
        IF FOUND THEN
            -- Obtener el nombre de la tabla y el esquema
            v_table_name := vtable.table_name;
            v_table_schema := vtable.table_schema;
            
            -- Generar la función de inserción
            vSql := public.createinsertfunction(v_table_schema, v_table_name);
            RAISE NOTICE 'Function created: %', vSql;

            -- Generar la función de eliminación
            vSql := public.create_delete_function(v_table_schema, v_table_name);
            RAISE NOTICE 'Function created: %', vSql;

            -- Generar la función de actualización
            vSql := public.create_update_function(v_table_schema, v_table_name);
            RAISE NOTICE 'Function created: %', vSql;
            
        ELSE
            EXIT;
        END IF;
    END LOOP;
    
    -- Cerrar el cursor
    CLOSE vTables;
END;
$BODY$;

SELECT public.generatefunctions(); --función que genera todas las funciones dinamicamente 

CREATE TABLE public.alumnos ( -- Otra tabla de pruebas
    id SERIAL PRIMARY KEY,           -- Identificador único para cada alumno
    nombre VARCHAR(100) NOT NULL,    -- Nombre del alumno
    apellido VARCHAR(100) NOT NULL,  -- Apellido del alumno
    fecha_nacimiento DATE NOT NULL,  -- Fecha de nacimiento del alumno
    correo_electronico VARCHAR(100) UNIQUE NOT NULL, -- Correo electrónico del alumno
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP -- Fecha en que se registró el alumno
);


