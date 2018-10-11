class Camion {
	var property destinos
	const pesoMaximo = 1000
	var property estado = disponible
	
	method validarCarga(coso) = {
		if (not self.puedeAceptarPesoDe(coso)) 
			throw new Exception("No se puede cargar. El peso del coso es mayor al máximo permitido por el camión.")
		if (not self.estaDisponible()) 
			throw new Exception("El camión no está disponible.")
	}
		
	method estaDisponible() =
		estado.estaDisponible()
	
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

	method estaCargando(elemento) = not self.estaListo() and self.elementosCargados().contains(elemento)

	/* 9 */
	method elementosEnComun(deposito) = self.elementosCargados().intersection(deposito.elementosCargados())

	/* 10 */
	method cosoMasLiviano() = self.cosos().min({coso => coso.peso()})

	method cantidadDeCosos() = self.cosos().size()

	method cososCon(elementos) = self.cosos().filter({coso => elementos.contains(coso.elemento())})
		
	method cosos() = self.destinos().values().flatten()
	
	method cargar(coso, destino) {
		self.validarCarga(coso)
		const cosos = destinos.getOrElse(destino, {[]})
		cosos.add(coso)
		destinos.put(destino, cosos)
	}
	
	method descargar(deposito) {
		self.validarDescarga(deposito)
		deposito.almacenar(destinos.get(deposito))
		destinos.remove(deposito)
	}
	
	method validarDescarga(deposito) = estado.validarDescarga(self, deposito)
	
	method cososPara(deposito) = destinos.getOrElse(deposito, {[]})
	
}

class CamionFrigorifico inherits Camion {
	
	override method validarCarga(coso) = {
		if (coso.temperaturaMaxima() >= camionFrigorifico.temperaturaMaxima())
			throw new Exception("La temperatura máxima del coso es mayor que la del camión.")
		super(coso)
	}
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
	method pesoTotalDeViaje() = self.camionesDeViaje().sum({camion => camion.pesoCargado()})
	
	method camionesDeViaje() = camiones.filter({camion => camion.estaDeViaje()})
	
	/* 8 */
	method estaCargando(elemento) = camiones.filter({camion => camion.estaCargando(elemento)})

	/* 11 */
	method camionConMasCosos() = camiones.max({camion => camion.cantidadDeCosos()})

	/* 12 */
	method cososConElementosEnComunOrdenados(deposito){
		const elementos = self.elementosEnComun(deposito)
		const cosos = self.cososCon(elementos)
		cosos.addAll(deposito.cososCon(elementos))
		return cosos.sortedBy({coso1, coso2 => coso1.peso() < coso2.peso()})
	}
	
	method elementosEnComun(deposito) = self.elementosCargados().intersection(deposito.elementosCargados())
	
	method elementosCargados() = camiones.flatMap({camion => camion.elementosCargados()}).asSet()
		
	method cososCon(elementos) = camiones.flatMap({camion => camion.cososCon(elementos)}).asSet()
}

class Coso {
	method temperaturaMaxima() = self.elemento().temperaturaMaxima()
	method elemento()
	method peso()
}

class Caja inherits Coso {
	const property elemento
	const property peso
	
	constructor(_elemento, _peso) {
		elemento = _elemento
		peso = _peso
	}
	
	override method elemento() = elemento
	override method peso() = peso

}

class Bidon inherits Coso {
	const liquido
	const capacidad
	
	constructor(_liquido, _capacidad) {
		liquido = _liquido
		capacidad = _capacidad
	}
	
	override method peso() = capacidad * liquido.densidad()
	override method elemento() = liquido.elemento()
}

class Bulto inherits Coso {
	const cantidadCajas
	const cajas
	const pesoPallet
	
	constructor(_cajas, _cantidadCajas, _pesoPallet) {
		cajas = _cajas
		cantidadCajas = _cantidadCajas
		pesoPallet = _pesoPallet
	}
	
	override method peso() = cajas.sum({ caja => caja.peso() * cantidadCajas }) + pesoPallet
	override method elemento() = cajas.anyOne().elemento()
	
	method agregarCaja(caja) {
		self.validarElemento(caja)
		cajas.add(caja)
	}
	
	method validarElemento(caja) {
		if(cajas.isNotEmpty() and self.elemento() != caja.elemento()){
			throw new Exception("El elemento de la caja es distinto al del bulto")
		}
	}
}

class Liquido {
	const property elemento
	const property densidad
	
	constructor(_elemento, _densidad){
		elemento = _elemento
		densidad = _densidad
	}
}

class Estado {
	const property estaDisponible = false
	const property estaDeViaje = false
	
	method sacarDeReparacion(camion) {}
	method llevarAReparacion(camion) {}
	method sacarDeViaje(camion) {}
	method volverDeViaje(camion) {}
	method validarDescarga(camion, deposito) {
		throw new Exception("No se puede descargar")
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
			throw new Exception("No hay cosos para descargar")
		}
	}
}

object enReparacion inherits Estado {
	override method sacarDeReparacion(camion) {
		camion.estado(disponible)
	}
}