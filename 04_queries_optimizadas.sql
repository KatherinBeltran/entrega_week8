-- Reescritura de Q1, Q3 y Q6
-- Nombre: Katherin Beltran
-- Fecha: [23/07/2026]

USE megamart_slow;

-- Q1: LIKE '%xxx%' -> FULLTEXT MATCH() AGAINST()

-- ❌ Original (full scan incluso con índice B-tree)
SELECT * FROM productos WHERE nombre LIKE '%laptop%';

-- ✅ Optimizada (usa el FULLTEXT INDEX que creamos)
SELECT * FROM productos
WHERE MATCH(nombre) AGAINST('laptop');

-- Q3: función DATE() en WHERE -> rango de fechas sin función

-- ❌ Original (índice en fecha_venta no se usa porque DATE() lo invalida)
SELECT * FROM ventas
WHERE DATE(fecha_venta) = '2024-06-15';

-- ✅ Optimizada (rango sin función en columna)
SELECT * FROM ventas
WHERE fecha_venta >= '2024-06-15 00:00:00'
  AND fecha_venta <  '2024-06-16 00:00:00';
  
-- Q6: subconsultas correlacionadas -> JOIN + GROUP BY

-- ❌ Original (las 2 subconsultas se ejecutan por cada cliente — 40k ejecuciones)
SELECT
    c.nombre,
    (SELECT COUNT(*) FROM ventas v WHERE v.cliente_id = c.id) AS total_compras,
    (SELECT SUM(cantidad * precio_unitario) FROM ventas v WHERE v.cliente_id = c.id) AS total_gastado
FROM clientes c
ORDER BY total_gastado DESC
LIMIT 10;

-- ✅ Optimizada (1 sola pasada con JOIN + GROUP BY)
SELECT
    c.nombre,
    COUNT(v.id) AS total_compras,
    SUM(v.cantidad * v.precio_unitario) AS total_gastado
FROM clientes c
JOIN ventas v ON c.id = v.cliente_id
GROUP BY c.id, c.nombre
ORDER BY total_gastado DESC
LIMIT 10;