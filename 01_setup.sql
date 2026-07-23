-- Week 8 - Optimización de sistema lento
-- Nombre: Katherin Beltran
-- Fecha: [23/07/2026]

DROP DATABASE IF EXISTS megamart_slow;
CREATE DATABASE megamart_slow;
USE megamart_slow;

-- Tablas (sin índices, excepto Primary Key)

CREATE TABLE categorias (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(100),
    descripcion TEXT
);

CREATE TABLE productos (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(200),
    descripcion TEXT,
    categoria_id INT,
    precio DECIMAL(10,2),
    stock INT,
    fecha_creacion DATETIME,
    activo BOOLEAN DEFAULT TRUE
);

CREATE TABLE clientes (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(100),
    email VARCHAR(150),
    ciudad VARCHAR(100),
    pais VARCHAR(100),
    fecha_registro DATE
);

CREATE TABLE ventas (
    id INT PRIMARY KEY AUTO_INCREMENT,
    cliente_id INT,
    producto_id INT,
    cantidad INT,
    precio_unitario DECIMAL(10,2),
    fecha_venta DATETIME,
    estado VARCHAR(50)
);
-
-- Generación de datos volumétricos

-- 8 categorías
INSERT INTO categorias (nombre, descripcion) VALUES
    ('Electrónica', '...'), ('Ropa', '...'), ('Deportes', '...'),
    ('Hogar', '...'), ('Libros', '...'), ('Juguetes', '...'),
    ('Alimentos', '...'), ('Belleza', '...');

-- 50,000 productos
INSERT INTO productos (nombre, descripcion, categoria_id, precio, stock, fecha_creacion, activo)
SELECT
    CONCAT('Producto ', ROW_NUMBER() OVER (ORDER BY a.column_name, b.column_name)),
    'Descripción genérica del producto',
    1 + FLOOR(RAND() * 8),
    ROUND(10 + RAND() * 1990, 2),
    FLOOR(RAND() * 100),
    DATE_ADD('2020-01-01', INTERVAL FLOOR(RAND() * 1500) DAY),
    IF(RAND() > 0.05, TRUE, FALSE)
FROM information_schema.columns a
CROSS JOIN information_schema.columns b
LIMIT 50000;

-- 20,000 clientes
INSERT INTO clientes (nombre, email, ciudad, pais, fecha_registro)
SELECT
    CONCAT('Cliente ', n),
    CONCAT('cliente', n, '@email.com'),
    ELT(1 + FLOOR(RAND() * 5), 'CDMX', 'Madrid', 'Buenos Aires', 'Bogotá', 'Lima'),
    ELT(1 + FLOOR(RAND() * 5), 'México', 'España', 'Argentina', 'Colombia', 'Perú'),
    DATE_ADD('2022-01-01', INTERVAL FLOOR(RAND() * 800) DAY)
FROM (
    SELECT ROW_NUMBER() OVER () AS n
    FROM information_schema.columns a CROSS JOIN information_schema.columns b
    LIMIT 20000
) AS gen;

-- 200,000 ventas
INSERT INTO ventas (cliente_id, producto_id, cantidad, precio_unitario, fecha_venta, estado)
SELECT
    1 + FLOOR(RAND() * 20000),
    1 + FLOOR(RAND() * 50000),
    1 + FLOOR(RAND() * 5),
    ROUND(10 + RAND() * 1000, 2),
    DATE_ADD('2024-01-01', INTERVAL FLOOR(RAND() * 365) DAY),
    ELT(1 + FLOOR(RAND() * 3), 'completada', 'cancelada', 'pendiente')
FROM (
    SELECT ROW_NUMBER() OVER () AS n
    FROM information_schema.columns a CROSS JOIN information_schema.columns b
    LIMIT 200000
) AS gen;

-- Confirmar volúmenes generados

SELECT 'categorias' AS tabla, COUNT(*) AS filas FROM categorias UNION ALL
SELECT 'productos',                COUNT(*)         FROM productos UNION ALL
SELECT 'clientes',                 COUNT(*)         FROM clientes UNION ALL
SELECT 'ventas',                   COUNT(*)         FROM ventas;