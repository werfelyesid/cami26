class_name Texto
extends RefCounted
## Ayuditas para escribir texto en pantalla.


## Escribe un número con puntos de miles (1000 -> "1.000"), como se hace aquí.
static func miles(n: int) -> String:
	var s := str(absi(n))
	var salida := ""
	var cuenta := 0
	for i in range(s.length() - 1, -1, -1):
		salida = s[i] + salida
		cuenta += 1
		if cuenta % 3 == 0 and i > 0:
			salida = "." + salida
	return ("-" if n < 0 else "") + salida
