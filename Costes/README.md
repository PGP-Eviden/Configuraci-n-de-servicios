# PowerShell Automate Budget Alert Scripts

## Descripción

Este script crea alertas de costes predefinidas y utiliza un archivo de texto simple (`.txt`, `.csv`, etc.) para la configuración del grupo de los emails.

### Alertas definidas

| Límite (%) | Tipo de Límite |
| ------ | ------- |
| 80 | Real |
| 100 | Estimado |
| 110 | Estimado |

## Modo de uso

Copiar los scripts (`main.ps1`, `resourceGroup.ps1`, `subscription.ps1`, `actiongroup.psm1`, `fmt.psm1`) en un fichero accesible desde la terminal y ejecutar `main.ps1`.
Se deben proporcionar los archivos de configuración:

- emails: archivo txt o csv con los nombres y los emails a los que se enviarán las alertas. Ejemplo: `emails.example.txt`.

### Opciones

| Opción | Descripción | Ejemplo | Requerido |
| ------ | ----------- | ------- | --------- |
| email file | Archivo de texto simple en el que se encuentran los nombres y emails a los que se enviarán las alertas. | `.\path\to\script .\path\to\emails.txt` | Sí |
| rg | Nombre del grupo de recursos en el que se crea el grupo de acción. | `-rg defender-prueba` | Sí |
| resourceGroup | Crea un budget para cada grupo de recursos. | `-resourceGroup` | No |  
| subscription | Crea un budget para la suscripción. |`-subscription` | No

### Ejemplos

```ps
.\path-to\main.ps1 .\path-to\emails.txt -rg rg -resourceGroup
.\path-to\main.ps1 .\path-to\emails.txt -rg rg -subscription
```
## Roadmap
- [ ] Añadir como parámetro obligatorio la suscripción (ya que puedes tener varias suscripciones).

## Referencias

[Documentación oficial budget alerts](https://learn.microsoft.com/en-us/rest/api/consumption/budgets/create-or-update?tabs=HTTP)
