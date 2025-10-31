<?php
$host = getenv('DB_HOST') ?: '192.168.56.11';
$dbname = getenv('DB_NAME') ?: 'tallerdb';
$user = getenv('DB_USER') ?: 'appuser';
$password = getenv('DB_PASS') ?: 'apppassword';

// DSN en formato estándar (pgsql:host=...;port=...;dbname=...)
$dsn = "pgsql:host={$host};dbname={$dbname}";

try {
    // Opciones PDO para mayor robustez (no cambian la funcionalidad)
    $options = [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES => false,
    ];

    // Conexión (se pasan usuario y contraseña como parámetros separados)
    $pdo = new PDO($dsn, $user, $password, $options);
    echo "<h1>Conexión a PostgreSQL Exitosa!</h1>";

    // Consulta SQL (sin cambios en la consulta original)
    $stmt = $pdo->query('SELECT id, nombre, rol FROM usuarios ORDER BY id');
    $usuarios = $stmt->fetchAll();

    // Despliegue de los datos en una tabla HTML
    echo "<h2>Datos de la Tabla 'usuarios'</h2>";
    echo "<table border='1' cellpadding='10'>";
    echo "<tr><th>ID</th><th>Nombre</th><th>Rol</th></tr>";

    foreach ($usuarios as $usuario) {
        echo "<tr>";
        echo "<td>" . htmlspecialchars($usuario['id']) . "</td>";
        echo "<td>" . htmlspecialchars($usuario['nombre']) . "</td>";
        echo "<td>" . htmlspecialchars($usuario['rol']) . "</td>";
        echo "</tr>";
    }

    echo "</table>";

} catch (PDOException $e) {
    // Manejo de errores (mejor mensaje y registro)
    echo "<h1>Error al conectar a la base de datos:</h1>";
    echo "<p>Verifica que la máquina DB ({$host}:{$port}) esté encendida y configurada.</p>";
    error_log('[DB ERROR] ' . $e->getMessage());

    // Mostrar phpinfo() sólo si no estamos en modo CLI (mismo comportamiento informativo que antes)
    if (php_sapi_name() !== 'cli') {
        phpinfo();
    }
    // Salida controlada
    exit;
}
?>
