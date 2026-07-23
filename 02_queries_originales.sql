-- Las 6 queries lentas 
-- Nombre: Katherin Beltran
-- Fecha: [23/07/2026]

USE megamart_slow;

-- Query 1: búsqueda de texto

SELECT * FROM productos WHERE nombre LIKE '%laptop%';

-- Query 2: JOIN con filtro por categoría

SELECT p.id, p.nombre, c.nombre AS categoria
FROM productos p
JOIN categorias c ON p.categoria_id = c.id
WHERE c.nombre = 'Electrónica'
LIMIT 100;

-- Query 3: filtro por fecha con función en WHERE (antipatrón)

SELECT * FROM ventas
WHERE DATE(fecha_venta) = '2024-06-15'
LIMIT 100;

-- Query 4: lookup exacto por email

SELECT * FROM clientes WHERE email = 'cliente12345@email.com';

-- Query 5: filtro compuesto

SELECT id, nombre, precio FROM productos
WHERE stock = 0 AND activo = TRUE
LIMIT 100;

-- Query 6: top clientes con subconsultas correlacionadas (antipatrón)

SELECT
    c.nombre,
    (SELECT COUNT(*) FROM ventas v WHERE v.cliente_id = c.id) AS total_compras,
    (SELECT SUM(cantidad * precio_unitario) FROM ventas v WHERE v.cliente_id = c.id) AS total_gastado
FROM clientes c
ORDER BY total_gastado DESC
LIMIT 10;