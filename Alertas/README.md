# PowerShell Automate Alert Scripts

## Descripción

Este script crea las alertas deseadas y utiliza un archivo de texto simple (`.txt`, `.csv`, etc.) para la configuración de las alertas.
Se pueden crear alertas en máquinas virtuales o en cuentas de almacenamiento (o ambos), pudiendo elegir el ámbito de aplicación (grupo de recursos o suscripción).

El script permite crear alertas con distintos límites para cada recurso deseado.

### Tipos de alerta métricas

| Alerta | Recurso | Descripción | Límite por defecto |
| ------ | ------- | ----------- | ------ |
| Porcentaje CPU | Máquina virtual | Uso de la CPU en puntos porcentuales | 80% |
| Memoria disponible | Máquina virtual | Uso de la RAM en bytes | 60% GB (10<sup>9</sup> Bytes) |
| Disponibilidad | Máquina virtual | Media de disponibilidad de la máquina virtual, siendo 1 un funcionamiento correcto. | 0.95 |
| Almacenamiento en uso | Cuenta de almacenamiento | Capacidad de uso de la cuenta de almacenamiento en bytes | 100 GiB (2<sup>30</sup> Bytes ) |
| Latencia | Cuenta de almac enamiento | Tiempo de respuesta de la cuenta de almacenamiento | 150 ms |

### Tipos de alertas de coste

| Límite | Tipo de límite |
| ------ | -------------- |
| 80 | Actual |
| 100 | Estimado |
| 110 | Estimado |

## Modo de uso

Antes de generar las alertas es necesario comprobar que estás en el tenant adecuado. Para seleccionar el tenant deseado, se utiliza el siguiente comando:

```ps
Connect-AzAccount -Tenant idTenant
```

El valor del Id del tenant se debe almacenar para utilizar posteriormente, ya que, en caso de que la cuenta de Microsoft esté vinculada con varios tenant, será necesario especificar el tenant exacto en el momento de ejecutar el script.

Copiar los archivos de script (`main.ps1`, `stacc.ps1`,`vm.ps1`, `actiongroup.psm1`, `fmt.psm1`) en un fichero accesible desde la terminal y ejecutar el archivo main con las opciones deseadas.
Se deben proporcionar los archivos de configuración:

- emails: archivo txt o csv con los nombres y los emails a los que se enviarán las alertas. Ejemplo: `emails.example.txt`.
- vars: archivo csv con los recursos que se quieren monitorizar y los límites. El `*` especifica que las alertas se crearán en el resto de los recursos dentro del ámbito indicado.
Debe estar tras el resto de recursos del mismo tipo. Ejemplo: `vars.example.txt`

El script preguntará en cada paso los datos necesarios y si son correctos o no.

### Opciones

| Opción | Descripción | Ejemplo | Requerido |
| ------ | ----------- | ------- | --------- |
| email file | Archivo de texto simple en el que se encuentran los nombres y emails a los que se enviarán las alertas. | `.\path\to\script .\path\to\emails.txt` | Sí |
| var file | Archivo de texto simple en que se detallan los recursos y su límites. | `-VarFile .\path\to\vars.csv` | Sí |
| rg | Nombre del grupo de recursos en el que se encuentran los recursos a monitorizar | `-rg defender-prueba` | Sí |
| subscription | Id del tenant en el que se encuentran los recursos a monitorizar | `-rg defender-prueba` | Sí |

### Ejemplos

```ps
.\main.ps1 .\emails.txt -rg rg -VarFile .\vars.csv
```

```ps
.\main.ps1 .\emails.txt -rg rg -VarFile .\vars.csv -subscription ID
```

## Roadmap

- [ ] Añadir explicación de alto nivel de qué recursos se crean (y porqué) en Azure.
- [x] Modificar los nombres según convención deseada.
- [x] Permitir modificación de los límites de las alertas.
- [x] Bucle por Get-AzVM (preguntar si el scope es correcto) y devolver en ParseResource una lista de recursos.
- [x] Especificar en el README que la estrellita tiene que estar al final y solo crear una alerta por VM.
- [ ] En caso de no encontrarse VarFile crear los recursos automáticos (notificar, etc.)
- [ ] Utilizar colores y mejor formateo de los mensajes.
- [ ] Separar el contenido en módulos y revisar las variables.

## Referencias

[Enlace con los tipos de métricas y sus respectivos nombres](https://learn.microsoft.com/en-us/azure/azure-monitor/essentials/metrics-supported)
