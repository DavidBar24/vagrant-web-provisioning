<?php
$host = '192.168.56.11';
$dbname = 'tallerdb';
$user = 'appuser';
$password = 'apppassword';

$dsn = "host=$host dbname=$dbname user=$user password=$password";

try {
    // Conexión
    $pdo = new PDO("pgsql:$dsn");
    echo "<h1>Conexión a PostgreSQL Exitosa!</h1>";
    
    // Consulta SQL
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
    echo "<h1> Error al conectar a la base de datos:</h1>";
    echo "<p>Verifica que la máquina DB (192.168.56.11) esté encendida y configurada.</p>";
    error_log($e->getMessage());
    phpinfo();
}
?>
