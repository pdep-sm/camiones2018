class Camion {
	const property cosos = []
	const pesoMaximo = 1000
	var property estado = disponible
	
	/* 1 con 3 agregado */
	method cargar(coso) {
		if(self.puedeAceptar(coso))
			cosos.add(coso)
	}
	
	/* 2 */
	method puedeAceptar(coso) = 
		self.puedeAceptarPesoDe(coso) and self.estaDisponible()
		
	method estaDisponible() = estado.estaDisponible()
	
	method estaDeViaje() = estado.estaDeViaje()

	/* 4.a */
	method salirDeReparacion() { estado.sacarDeReparacion(self) }

	/* 4.b */
	method llevarAReparacion() { estado.llevarAReparacion(self) }

	/* 4.c */
	method salirDeViaje() { estado.sacarDeViaje(self) }

	/* 4.d */
	method volverDeViaje() { estado.volverDeViaje(self) }
	
	method puedeAceptarPesoDe(coso) = coso.peso() <= self.pesoDisponible()

	method pesoDisponible() = pesoMaximo - self.pesoCargado()
	
	method pesoCargado() = cosos.sum({coso => coso.peso()})

	/* 5 */
	method estaListo() = self.estaBienCargado() and self.estaDisponible()
	
	method estaBienCargado() = self.pesoCargado() > pesoMaximo * 0.75

	/* 7 */
	method elementosCargados() = cosos.map({coso => coso.elemento()}).asSet()

	method estaCargando(elemento) = 
		not self.estaListo() and self.elementosCargados().contains(elemento)

	/* 9 */
	method elementosEnComun(deposito) =
		self.elementosCargados().intersection(deposito.elementosCargados())

	/* 10 */
	method cosoMasLiviano() = cosos.min({coso => coso.peso()})

	method cantidadDeCosos() = cosos.size()

	method cososCon(elementos) =
		cosos.filter({coso => elementos.contains(coso.elemento())})
}

class Deposito {
	const camiones = []
	
	method agregarCamion(camion) {
		camiones.add(camion)
	}
	
	/* 6 */
	method pesoTotalDeViaje() = 
		self.camionesDeViaje().sum({camion => camion.pesoCargado()})
	
	method camionesDeViaje() = camiones.filter({camion => camion.estaDeViaje()})
	
	/* 8 */
	method estaCargando(elemento) = 
		camiones.filter({camion => camion.estaCargando(elemento)})

	/* 11 */
	method camionConMasCosos() = 
		camiones.max({camion => camion.cantidadDeCosos()})

	/* 12 */
	method cososConElementosEnComunOrdenados(deposito){
		const elementos = self.elementosEnComun(deposito)
		const cosos = self.cososCon(elementos)
		cosos.addAll(deposito.cososCon(elementos))
		return cosos.sortedBy({coso1, coso2 => coso1.peso() < coso2.peso()})
	}
	
	method elementosEnComun(deposito) =
		self.elementosCargados().intersection(deposito.elementosCargados())
	
	method elementosCargados() = 
		camiones.flatMap({camion => camion.elementosCargados()}).asSet()
		
	method cososCon(elementos) =
		camiones.flatMap({camion => camion.cososCon(elementos)}).asSet()
}

class Caja {
	const property elemento
	const property peso
}

class Bidon {
	const liquido
	const capacidad
	
	method peso() = capacidad * liquido.densidad()
	method elemento() = liquido.elemento()
}

class Bulto {
	const cantidadCajas
	const caja
	const pesoPallet
	
	method peso() = caja.peso() * cantidadCajas + pesoPallet
	method elemento() = caja.elemento()
}

class Liquido {
	const property elemento
	const property densidad
}

class Estado {
	const property estaDisponible = false
	const property estaDeViaje = false
	
	method sacarDeReparacion(camion) {}
	method llevarAReparacion(camion) {}
	method sacarDeViaje(camion) {}
	method volverDeViaje(camion) {}
}

object disponible inherits Estado( estaDisponible = true ) {
	override method llevarAReparacion(camion) {
		camion.estado(enReparacion)
	}
	
	override method sacarDeViaje(camion) {
		camion.estado(deViaje)
	}
}

object deViaje inherits Estado( estaDeViaje = true ) {
	override method volverDeViaje(camion) {
		camion.estado(disponible)
	}
}

object enReparacion inherits Estado {
	override method sacarDeReparacion(camion) {
		camion.estado(disponible)
	}
}