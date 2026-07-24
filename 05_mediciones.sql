-- Mediciones antes/después - Week 8
-- Nombre: Katherin Beltran
-- Fecha: [23/07/2026]

USE megamart_slow;

-- 1. VOLUMEN DE DATOS GENERADO

SELECT 'categorias' AS tabla, COUNT(*) AS filas FROM categorias UNION ALL
SELECT 'productos',                COUNT(*)         FROM productos UNION ALL
SELECT 'clientes',                 COUNT(*)         FROM clientes UNION ALL
SELECT 'ventas',                   COUNT(*)         FROM ventas;
-- Esperado: categorias=8, productos=50000, clientes=20000, ventas=200000
-- Resultado real: categorias=8, productos=50000, clientes=20000, ventas=200000

-- 2. TIEMPOS "ANTES" (ejecutar SIN índices todavía)

-- ---------- Q1: búsqueda de texto ----------
SELECT * FROM productos WHERE nombre LIKE '%laptop%';
-- Tiempo ANTES: 0.188 sec / 0.000 sec

EXPLAIN SELECT * FROM productos WHERE nombre LIKE '%laptop%';
-- type: ALL   key: NULL   rows: 49872

-- ---------- Q2: JOIN con filtro por categoría ----------
SELECT p.id, p.nombre, c.nombre AS categoria
FROM productos p
JOIN categorias c ON p.categoria_id = c.id
WHERE c.nombre = 'Electrónica'
LIMIT 100;
-- Tiempo ANTES: 0.000 sec / 0.000 sec

EXPLAIN SELECT p.id, p.nombre, c.nombre AS categoria
FROM productos p
JOIN categorias c ON p.categoria_id = c.id
WHERE c.nombre = 'Electrónica'
LIMIT 100;
-- type: ALL   key: NULL   rows: 8 - 49872

-- ---------- Q3: filtro por fecha con función en WHERE ----------
SELECT * FROM ventas
WHERE DATE(fecha_venta) = '2024-06-15'
LIMIT 100;
-- Tiempo ANTES: 0.063 sec / 0.000 sec

EXPLAIN SELECT * FROM ventas
WHERE DATE(fecha_venta) = '2024-06-15'
LIMIT 100;
-- type: ALL   key: NULL   rows: 199492

-- ---------- Q4: lookup por email ----------
SELECT * FROM clientes WHERE email = 'cliente12345@email.com';
-- Tiempo ANTES: 0.047 sec / 0.000 sec

EXPLAIN SELECT * FROM clientes WHERE email = 'cliente12345@email.com';
-- type: ALL   key: NULL   rows: 20077

-- ---------- Q5: filtro compuesto ----------
SELECT id, nombre, precio FROM productos
WHERE stock = 0 AND activo = TRUE
LIMIT 100;
-- Tiempo ANTES: 0.032 sec / 0.000 sec

EXPLAIN SELECT id, nombre, precio FROM productos
WHERE stock = 0 AND activo = TRUE
LIMIT 100;
-- type: ALL   key: NULL   rows: 49872

-- ---------- Q6: top clientes con subconsultas correlacionadas ----------
SELECT
    c.nombre,
    (SELECT COUNT(*) FROM ventas v WHERE v.cliente_id = c.id) AS total_compras,
    (SELECT SUM(cantidad * precio_unitario) FROM ventas v WHERE v.cliente_id = c.id) AS total_gastado
FROM clientes c
ORDER BY total_gastado DESC
LIMIT 10;
-- Tiempo ANTES: 30.000 sec

EXPLAIN SELECT
    c.nombre,
    (SELECT COUNT(*) FROM ventas v WHERE v.cliente_id = c.id) AS total_compras,
    (SELECT SUM(cantidad * precio_unitario) FROM ventas v WHERE v.cliente_id = c.id) AS total_gastado
FROM clientes c
ORDER BY total_gastado DESC
LIMIT 10;
-- type: ALL   key: NULL   rows: 20077 - 199492 - 199492

-- 3. TIEMPOS "DESPUÉS" (ejecutar CON índices y reescrituras)

-- ---------- Q1: reescrita con FULLTEXT ----------
SELECT * FROM productos WHERE MATCH(nombre) AGAINST('laptop');
-- Tiempo DESPUÉS: 0.016 sec / 0.000 sec

EXPLAIN SELECT * FROM productos WHERE MATCH(nombre) AGAINST('laptop');
-- type: fulltext   key: ft_productos_nombre   rows: 1

-- ---------- Q2: mismo SQL, ahora con índices ----------
SELECT p.id, p.nombre, c.nombre AS categoria
FROM productos p
JOIN categorias c ON p.categoria_id = c.id
WHERE c.nombre = 'Electrónica'
LIMIT 100;
-- Tiempo DESPUÉS: 0.016 sec / 0.000 sec

EXPLAIN SELECT p.id, p.nombre, c.nombre AS categoria
FROM productos p
JOIN categorias c ON p.categoria_id = c.id
WHERE c.nombre = 'Electrónica'
LIMIT 100;
-- type: ref   key: idx_categorias_nombre - idx_productos_categoria_id   rows: 1 - 7097

-- ---------- Q3: reescrita con rango de fechas ----------
SELECT * FROM ventas
WHERE fecha_venta >= '2024-06-15 00:00:00'
  AND fecha_venta <  '2024-06-16 00:00:00'
LIMIT 100;
-- Tiempo DESPUÉS: Error Code: 2013. Lost connection to MySQL server during query - 30.000 sec

EXPLAIN SELECT * FROM ventas
WHERE fecha_venta >= '2024-06-15 00:00:00'
  AND fecha_venta <  '2024-06-16 00:00:00'
LIMIT 100;
-- type:    key:    rows: Error Code: 2013. Lost connection to MySQL server during query - 30.000 sec

-- ---------- Q4: mismo SQL, ahora con índice UNIQUE ----------
SELECT * FROM clientes WHERE email = 'cliente12345@email.com';
-- Tiempo DESPUÉS: 0.032 sec / 0.000 sec

EXPLAIN SELECT * FROM clientes WHERE email = 'cliente12345@email.com';
-- Esperado: type=const, key=idx_clientes_email, rows=1
-- type: ALL   key: NULL   rows: 20077

-- ---------- Q5: mismo SQL, ahora con índice compuesto ----------
SELECT id, nombre, precio FROM productos
WHERE stock = 0 AND activo = TRUE
LIMIT 100;
-- Tiempo DESPUÉS: 0.032 sec / 0.000 sec

EXPLAIN SELECT id, nombre, precio FROM productos
WHERE stock = 0 AND activo = TRUE
LIMIT 100;
-- type: ALL   key: NULL   rows: 49872

-- ---------- Q6: reescrita con JOIN + GROUP BY ----------
SELECT
    c.nombre,
    COUNT(v.id) AS total_compras,
    SUM(v.cantidad * v.precio_unitario) AS total_gastado
FROM clientes c
JOIN ventas v ON c.id = v.cliente_id
GROUP BY c.id, c.nombre
ORDER BY total_gastado DESC
LIMIT 10;
-- Tiempo DESPUÉS: Error Code: 2013. Lost connection to MySQL server during query 30.015 sec

EXPLAIN SELECT
    c.nombre,
    COUNT(v.id) AS total_compras,
    SUM(v.cantidad * v.precio_unitario) AS total_gastado
FROM clientes c
JOIN ventas v ON c.id = v.cliente_id
GROUP BY c.id, c.nombre
ORDER BY total_gastado DESC
LIMIT 10;
-- type:   key:    rows: Error Code: 2013. Lost connection to MySQL server during query 30.015 sec