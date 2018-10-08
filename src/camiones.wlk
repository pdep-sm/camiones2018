class Camion {
	var property destinos = new Dictionary()
	const pesoMaximo = 1000
	var property estado = disponible
	
	
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
	
	method puedeAceptarPesoDe(coso) = pesoMaximo >= self.pesoCargado() + coso.peso()
	
	method pesoCargado() = self.cosos().sum({coso => coso.peso()})

	/* 5 */
	method estaListo() = self.estaBienCargado() and self.estaDisponible()
	
	method estaBienCargado() = self.pesoCargado() > pesoMaximo * 0.75

	/* 7 */
	method elementosCargados() = self.cosos().map({coso => coso.elemento()}).asSet()

	method estaCargando(elemento) = 
		not self.estaListo() and self.elementosCargados().contains(elemento)

	/* 9 */
	method elementosEnComun(deposito) =
		self.elementosCargados().intersection(deposito.elementosCargados())

	/* 10 */
	method cosoMasLiviano() = self.cosos().min({coso => coso.peso()})

	method cantidadDeCosos() = self.cosos().size()

	method cososCon(elementos) = self.cosos().filter({coso => elementos.contains(coso.elemento())})
		
	method cosos() = destinos.values().flatten()
	
	method cargar(coso, destino) {
		const cosos = destinos.getOrElse(destino, {[]})
		cosos.add(coso)
		destinos.put(destino, cosos)
	}
	
	method descargar(deposito) {
		self.validarDescarga(deposito)
		deposito.almacenar(destinos.get(deposito))
		destinos.remove(deposito)
	}
	
	method validarDescarga(deposito) {
		estado.validarDescarga(self, deposito)
	}
	
	method cososPara(deposito) = destinos.getOrElse(deposito, {[]})
	
}

class CamionFrigorifico inherits Camion {
	
	override method puedeAceptar(coso) = (coso.temperaturaMaxima() <= camionFrigorifico.temperaturaMaxima()) and super(coso)
}

object camionFrigorifico {
	var property temperaturaMaxima
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

class Caja inherits Coso {
	const property elemento
	const property peso
}

class Bidon inherits Coso {
	const liquido
	const capacidad
	
	override method peso() = capacidad * liquido.densidad()
	override method elemento() = liquido.elemento()
}

class Bulto inherits Coso {
	const cantidadCajas
	const cajas
	const pesoPallet
	
	override method peso() = cajas.sum({ caja => caja.peso()}) + pesoPallet
	override method elemento() = cajas.anyOne().elemento()
	
	method agregarCaja(caja) {
		self.validarElemento(caja)
		cajas.add(caja)
	}
	
	method validarElemento(caja) {
		if(cajas.isNotEmpty() and self.elemento() != caja.elemento()){
			throw new UserException("El elemento de la caja es distinto al del bulto")
		}
	}
}

class Liquido {
	const property elemento
	const property densidad
}

class Coso {
	method temperaturaMaxima() = self.elemento().temperaturaMaxima()
	method elemento()
	method peso()
}

class Estado {
	const property estaDisponible = false
	const property estaDeViaje = false
	
	method sacarDeReparacion(camion) {}
	method llevarAReparacion(camion) {}
	method sacarDeViaje(camion) {}
	method volverDeViaje(camion) {}
	method validarDescarga(camion, deposito) {
		throw new UserException("No se puede descargar")
	}
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
	
	override method validarDescarga(camion, deposito) {
		if(camion.cososPara(deposito).isEmpty()){
			throw new UserException("No hay cosos para descargar")
		}
	}
}

object enReparacion inherits Estado {
	override method sacarDeReparacion(camion) {
		camion.estado(disponible)
	}
}