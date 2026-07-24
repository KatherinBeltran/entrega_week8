-- Una sola query (UNION ALL + subconsultas) que devuelve las
-- 4 métricas principales del dashboard de MegaMart en una
-- sola pasada:
--   1) Ventas de hoy (monto total)
--   2) Top producto más vendido (por cantidad)
--   3) Top cliente (por monto gastado)
--   4) Cantidad de productos con stock bajo (stock = 0)
-- Nombre: Katherin Beltran
-- Fecha: [23/07/2026]

USE megamart_slow;

SELECT
    'ventas_hoy' AS metrica,
    CAST(COALESCE(SUM(cantidad * precio_unitario), 0) AS CHAR) AS valor
FROM ventas
WHERE fecha_venta >= CURDATE()
  AND fecha_venta < CURDATE() + INTERVAL 1 DAY

UNION ALL

SELECT
    'top_producto_mas_vendido' AS metrica,
    CONCAT(p.nombre, ' (', SUM(v.cantidad), ' unidades)') AS valor
FROM ventas v
JOIN productos p ON p.id = v.producto_id
GROUP BY p.id, p.nombre
ORDER BY SUM(v.cantidad) DESC
LIMIT 1

UNION ALL

SELECT
    'top_cliente' AS metrica,
    CONCAT(c.nombre, ' ($', FORMAT(SUM(v.cantidad * v.precio_unitario), 2), ')') AS valor
FROM ventas v
JOIN clientes c ON c.id = v.cliente_id
GROUP BY c.id, c.nombre
ORDER BY SUM(v.cantidad * v.precio_unitario) DESC
LIMIT 1

UNION ALL

SELECT
    'productos_stock_bajo' AS metrica,
    CAST(COUNT(*) AS CHAR) AS valor
FROM productos
WHERE stock = 0 AND activo = TRUE;