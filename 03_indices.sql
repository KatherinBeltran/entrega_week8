-- Índices estratégicos
-- Nombre: Katherin Beltran
-- Fecha: [23/07/2026]

USE megamart_slow;

-- idx_ft_productos_nombre
-- Para: Q1 (búsqueda de texto "LIKE '%laptop%'")
-- Justificación: ningún índice B-tree sirve para % al inicio.
-- Un FULLTEXT INDEX permite usar MATCH() AGAINST() para buscar
-- palabras dentro del texto en tiempo casi constante.

CREATE FULLTEXT INDEX ft_productos_nombre ON productos(nombre);

-- idx_productos_categoria_id
-- Para: Q2 (JOIN productos.categoria_id <-> categorias.id)
-- Justificación: sin índice, cada fila de productos requiere
-- comparar contra categorias en un nested loop scan completo.
-- Con índice, el JOIN localiza directamente las filas por
-- categoria_id (type: ref).

CREATE INDEX idx_productos_categoria_id ON productos(categoria_id);

-- idx_categorias_nombre
-- Para: Q2 (filtro WHERE c.nombre = 'Electrónica')
-- Justificación: categorias.nombre no tenía índice, forzando
-- un full scan de la tabla categorias para encontrar el id.

CREATE INDEX idx_categorias_nombre ON categorias(nombre);

-- idx_ventas_fecha
-- Para: Q3 (filtro por rango de fecha en ventas)
-- Justificación: permite que la versión reescrita de la query
-- (rango fecha_venta >= X AND fecha_venta < Y, sin función)
-- use el índice en vez de leer las 200,000 filas de ventas.

CREATE INDEX idx_ventas_fecha ON ventas(fecha_venta);

-- idx_clientes_email
-- Para: Q4 (lookup por email)
-- Justificación: WHERE email = 'X' sobre 20k filas → sin índice = full scan.
-- Con índice = búsqueda directa al árbol B-tree, devuelve en ~0.001s.
-- UNIQUE porque cada email aparece una sola vez.

CREATE UNIQUE INDEX idx_clientes_email ON clientes(email);

-- idx_productos_stock_activo
-- Para: Q5 (filtro compuesto WHERE stock = 0 AND activo = TRUE)
-- Justificación: ambas columnas son de baja cardinalidad por sí
-- solas (activo solo tiene 2 valores), pero combinadas en un
-- índice compuesto filtran de forma efectiva la combinación
-- específica que pide la query.

CREATE INDEX idx_productos_stock_activo ON productos(stock, activo);

-- idx_ventas_cliente
-- Para: Q6 (JOIN/agregación ventas <-> clientes por cliente_id)
-- Justificación: sin índice, el JOIN reescrito con GROUP BY
-- seguiría siendo lento al tener que escanear ventas por cada
-- cliente. Con índice, MySQL accede directo a las ventas de
-- cada cliente_id.

CREATE INDEX idx_ventas_cliente ON ventas(cliente_id);

-- idx_ventas_producto
-- Para: soporte general de JOINs futuros (dashboard, reportes
-- de top productos) sobre ventas.producto_id.
-- Justificación: evita full scan cuando se cruza ventas con
-- productos, mismo razonamiento que idx_ventas_cliente.

CREATE INDEX idx_ventas_producto ON ventas(producto_id);

-- Foreign Keys
-- Nota: en MySQL 8, agregar una FK crea automáticamente un
-- índice en la columna si no existe uno ya. Aquí los índices
-- ya fueron creados manualmente arriba, así que las FKs solo
-- agregan la restricción de integridad referencial.

ALTER TABLE productos
    ADD CONSTRAINT fk_productos_categoria
    FOREIGN KEY (categoria_id) REFERENCES categorias(id);

ALTER TABLE ventas
    ADD CONSTRAINT fk_ventas_cliente FOREIGN KEY (cliente_id) REFERENCES clientes(id),
    ADD CONSTRAINT fk_ventas_producto FOREIGN KEY (producto_id) REFERENCES productos(id);