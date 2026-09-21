extends TileMap
# -1 casilla vacia
# 0 mina
# 1-8 casilla numero

#Columnas, filas y cantidad de minas (20% del total de casillas)
const cell_columna := 16
const cell_fila := 16
const mine_count := int(cell_columna * cell_fila * 0.20)
var ganar = false
#Tiempo para jugar, cuando partida empezada es true se activa 
var tiempo_restante := 1000
var partida_empezada := false
var panel_size := Vector2(100, 40)
#Muerte es gameover, cells la cantidad de casillas, cells_alrededor se usa para revelar cuando tocás una bien
var muerte := false
var cells : Array[int]
var cells_alrededor : Array[int]
var offsetCoords : Vector2i
#CAMBIO 7-1: Los y el tiempo que valen. Primero ibas a empezar con 1, por eso se llamaban vidas, pero me arrepentí, y así quedó
var vidas := 0
var tiempo_extra :=10
#lo uso solo dos veces, peroe es más comodo desde acá, para cuanto tarda en cambiar el label estado
var delay_await:=1.5
#CAMBIO 7-2 variables del totem (casilla)
var totem_activo := false
var posicion_totem : Vector2i
var tiempo_totem := 2.0
var probabilidad_totem:= 0.1
#CAMBIO 7-3 variables del creeper
var creeper_activo := false
var posicion_creeper : Vector2i
var tiempo_creeper := 3
var probabilidad_creeper:= 0.5
#auxiliar para cambiar del tiempo normal al tiempo del creeper
var tiempo_restante_guardado=0

var auxiliarcreeper:int
var auxiliartotem:int
# Se activa cuando empieza la escena
func _ready() -> void:
	randomize()
	setupboard()
	#estado
	$CanvasLayer/PanelEstado/LabelEstado.text = "Toca una casilla"
	#timer
	$CanvasLayer/PanelTiempo/LabelTiempo.text = "Tiempo: " + str(tiempo_restante)
	#CAMBIO 7-1.1 Label de Vidas
	$CanvasLayer/PanelVidas/LabelVidas.text = "Totems: " + str(vidas)
	#ajusta el tamaño de la pantalla al necesario
	var viewport_size := get_viewport_rect().size
	var board_size := Vector2(cell_fila, cell_columna) * 16
	# minf devbuelve el menor entre 2 floats, no se muy bien para qué es pero si funciona no lo arreglo
	var scale_factor: float = minf(
		viewport_size.x / board_size.x,
		viewport_size.y / board_size.y
	)
	#IMPORTANTE PONER AUTOWRAP MODE EN "WORD (SMART)" ASÍ SE AJUSTAN BIEN LAS PALABRAS AL TAMAÑO QUE QUIERA
	scale = Vector2.ONE * scale_factor
	position = (viewport_size - board_size * scale_factor) / 2
	
	var board_size_scaled := board_size * scale_factor
#Pone el panel de estado a la izquierda ajustaddo según tamaño
	$CanvasLayer/PanelEstado.position = Vector2(
		position.x - $CanvasLayer/PanelEstado.size.x - 60,
		position.y + board_size_scaled.y / 2 - $CanvasLayer/PanelEstado.size.y / 2
	)
	#7-0 tratando de colocar el coso de las vidas
	$CanvasLayer/PanelVidas.position = Vector2(
		position.x - $CanvasLayer/PanelVidas.size.x - 60,
		position.y + board_size_scaled.y / 2 - $CanvasLayer/PanelEstado.size.y / 2
	)
#Pone el panel de timer a la derecha ajustaddo según tamaño
	$CanvasLayer/PanelTiempo.position = Vector2(
		position.x + board_size_scaled.x + 60,
		position.y + board_size_scaled.y / 2 - $CanvasLayer/PanelTiempo.size.y / 2
	)
#7-5.1 tratando de colocar el boton
	$CanvasLayer/BotonCorrer.position = Vector2(
		position.x + board_size_scaled.x + 60,
		position.y + board_size_scaled.y / 2 - $CanvasLayer/BotonCorrer.size.y / 0.5
	)
# Tablero vacío
func setupboard() -> void:
	for y in range(cell_columna):
		for x in range(cell_fila):
			set_cell(0, Vector2i(x,y), 0, Vector2i(0,0))
			cells.append(-1)
#Pone las minas random
func setupmines(avoid : Vector2i) -> void:
	for i in range(mine_count):
		cells[i] = 0
	
	cells.shuffle()
	
	# previene instalose y dá margen de cells vacías al rededor del inicio
	while getSurroundingCells(avoid, 5).has(0):
		cells.shuffle()
		
		#ponemos las celss de numeros
	for y in range(cell_columna):
		for x in range(cell_fila):
			
			if not cells[getCellIndex(Vector2i(x, y))] == 0:
				var mineCount := 0
				for i in getSurroundingCells(Vector2i(x, y), 3):
					if i == 0:
						mineCount += 1
				if mineCount > 0:
					cells[getCellIndex(Vector2i(x, y))] = mineCount


# Detectar Clicks en las cells
func _input(event: InputEvent) -> void:
	#No hace nada si hay gameover
	if ganar==true:
		$CanvasLayer/PanelEstado/LabelEstado.text = "Ganaste"
	if muerte==false:

			
			#Click izquierdo
		if event.is_action_pressed("ShowMeYourTrueForm"):
			var cellAtMouse: Vector2i =local_to_map(get_local_mouse_position())
		# para que no se puedan clickear banderas
			if getCellIndex(cellAtMouse) == -1:
				return
			#CAMBIO 7-2.1 Acción por click en tile totem (10)
			if cells[getCellIndex(cellAtMouse)] == 10:
				#suma vidas (osea totems (o sea vidas))
				vidas += 1
				$CanvasLayer/PanelVidas/LabelVidas.text = "Totems: " + str(vidas)
				cells[getCellIndex(cellAtMouse)] = -1
				#vuelve a ser casilla sin revelar
				set_cell(0, cellAtMouse, 0, Vector2i(0, 0))
				$CanvasLayer/PanelEstado/LabelEstado.text = "SIII TOTEM"
				await get_tree().create_timer(delay_await).timeout
				$CanvasLayer/PanelEstado/LabelEstado.text = "Jugando"
				#libera para otro totem
				totem_activo = false
				return
			if getAtlasCoords(cellAtMouse) == Vector2i(0, 0):
				if cells.has(0):
						# CAMBIO 7-1.5 Por si clickea mal y encima hay un creeper
					if cells[getCellIndex(cellAtMouse)] == 0 && vidas<=0 && creeper_activo:
						muerte = true
						$CanvasLayer/Timer.stop()
						$CanvasLayer/PanelEstado/LabelEstado.text = "Creeper y Mina al mismo tiempo? Que mal"
						showmeyalltrueforms(cellAtMouse)
						
						# CAMBIO 7-1.6 Lo mismo pero si hay totems
					if cells[getCellIndex(cellAtMouse)] == 0 && vidas>0 && creeper_activo:
						cells[getCellIndex(posicion_creeper)]=auxiliarcreeper
						set_cell(0, posicion_creeper, 0, Vector2i(0, 0))

						creeper_activo = false
						tiempo_restante=tiempo_restante_guardado
						$CanvasLayer/PanelTiempo/LabelTiempo.text = str(tiempo_restante)
						vidas -=1
						$CanvasLayer/PanelVidas/LabelVidas.text = "Totems: " + str(vidas)
						$CanvasLayer/PanelEstado/LabelEstado.text = "Creeper y Mina al mismo tiempo? Que mal"
						$CanvasLayer/PanelEstado/LabelEstado.text = "Te explotó un creeper, perdiste una vida"
						await get_tree().create_timer(delay_await).timeout
						$CanvasLayer/PanelEstado/LabelEstado.text = "Jugando"
						
					#CAMBIO 7-3.1: si se hace click bien pero hay un creeper (y no vidas), igualmente hay muerte
					if creeper_activo && vidas>0:
						cells[getCellIndex(posicion_creeper)]=auxiliarcreeper
						set_cell(0, posicion_creeper, 0, Vector2i(0, 0))
						
						creeper_activo = false
						tiempo_restante=tiempo_restante_guardado
						$CanvasLayer/PanelTiempo/LabelTiempo.text = str(tiempo_restante)
						vidas -=1
						$CanvasLayer/PanelVidas/LabelVidas.text = "Totems: " + str(vidas)
						$CanvasLayer/PanelEstado/LabelEstado.text = "Te explotó un creeper, perdiste una vida"
						await get_tree().create_timer(delay_await).timeout
						$CanvasLayer/PanelEstado/LabelEstado.text = "Jugando"
						return
						#lo mismo pero con vidas, perdes una
					if creeper_activo && vidas<=0:
						vidas -=1
						$CanvasLayer/PanelVidas/LabelVidas.text = "Totems: 0"
						$CanvasLayer/PanelEstado/LabelEstado.text = "Te explotó un creeper, perdiste"
						muerte=true
						$CanvasLayer/Timer.stop()
						showmeyalltrueforms(cellAtMouse)
						return
					eventos_mena()
					trueForm(cellAtMouse)
					checkWin()
			
			#CAMBIO 7-1.2 Ahora solo morís si no tenés totems
					if cells[getCellIndex(cellAtMouse)] == 0 && vidas<=0:
						muerte = true
						$CanvasLayer/Timer.stop()
						$CanvasLayer/PanelEstado/LabelEstado.text = "Kaboom"
						showmeyalltrueforms(cellAtMouse)
					else:
						if cells[getCellIndex(cellAtMouse)] == 0 && vidas>0:
							vidas -=1
							$CanvasLayer/PanelVidas/LabelVidas.text = "Totems: " + str(vidas)
							$CanvasLayer/PanelEstado/LabelEstado.text = "Más cuidado con las TNT, gastaste un totem"
							$CanvasLayer/PanelVidas/LabelVidas.text = "Totems: " + str(vidas)
							await get_tree().create_timer(delay_await).timeout
							$CanvasLayer/PanelEstado/LabelEstado.text = "Jugando"
							return
						#Sino, siga siga
				else:
					setupmines(cellAtMouse)
					trueForm(cellAtMouse)
					partida_empezada = true
					$CanvasLayer/PanelEstado/LabelEstado.text = "Jugando"
					$CanvasLayer/Timer.start()
					checkWin()
					#Click derecho
		if event.is_action_pressed("flag"):
			var cellAtMouse : Vector2i = local_to_map(get_local_mouse_position())
			# Si es casilla sin ver
			if getCellIndex(cellAtMouse) == -1:
				return
			if getAtlasCoords(cellAtMouse) == Vector2i(0, 0):
				# Hace casilla con flag
				set_cell(0, cellAtMouse, 0, Vector2i(1, 0))
				# Si es casilla con flag
			elif getAtlasCoords(cellAtMouse) == Vector2i(1, 0):
				# Hace casilla sin ver
				set_cell(0, cellAtMouse, 0, Vector2i(0, 0))
				
# Evento cuando click derecho 
func trueForm(cellCoords : Vector2i) -> void:
	# Codigo de las casillas en la textura
	var cellIndex : int
	cellIndex = getCellIndex(cellCoords)
	
	var atlasCoords : Vector2i
	match cells[cellIndex]:
		-1: atlasCoords = Vector2i(3,0) # Empty cell
		0: atlasCoords = Vector2i(0,3) # Mine
		1: atlasCoords = Vector2i(0, 1) # Number cells
		2: atlasCoords = Vector2i(1, 1)
		3: atlasCoords = Vector2i(2, 1)
		4: atlasCoords = Vector2i(3, 1)
		5: atlasCoords = Vector2i(0, 2)
		6: atlasCoords = Vector2i(1, 2)
		7: atlasCoords = Vector2i(2, 2)
		8: atlasCoords = Vector2i(3, 2)
		9: atlasCoords = Vector2i(2, 3) #Creeper
		10: atlasCoords = Vector2i(3, 3) #Totem
	set_cell(0, cellCoords, 0, atlasCoords)
# Si está sin revelar, revela este y su alrededor
	if cells[cellIndex] == -1:
		trueformalrededor(cellCoords)
		


# convierte la coordenada del click del mouse en una posición del array de las casillas
func getCellIndex(cellCoords : Vector2i) -> int:
	# Comprueba si el click está dentro de los limites del tablero
	if cellCoords.x < cell_fila and cellCoords.y < cell_columna:
		if cellCoords.x >= 0 and cellCoords.y >= 0:
			return cellCoords.y * cell_fila + cellCoords.x
		else:
			return -1
	else:
		return -1
		

# Don't set size too high or it will lag/crash the game. OK
func getSurroundingCells(cellCoords : Vector2i, size : int) -> Array[int]:
	cells_alrededor = []
	for y in range(-1, size-1):
		for x in range(-1, size-1):
			offsetCoords = cellCoords + Vector2i(x, y)
			# Si las cells de alrededor no están vacás
			if getCellIndex(offsetCoords) > -1:
				cells_alrededor.append(cells[getCellIndex(offsetCoords)])
			else:
				cells_alrededor.append(-1)
				# Devuelve la información de que hay alrededor
	return cells_alrededor

# Revela las casillas vacías
func trueformalrededor(cellCoords : Vector2i) -> void:
	for y in range(-1, 2):
		for x in range(-1, 2):
			offsetCoords = cellCoords-Vector2i(x , y)
			if getCellIndex(offsetCoords) > -1:
					if getAtlasCoords(offsetCoords) == Vector2i(0,0) or getAtlasCoords(offsetCoords) == Vector2i(1,0):
						trueForm(offsetCoords)
						muleta()

func getAtlasCoords(cellCoords : Vector2i) -> Vector2i:
	return get_cell_atlas_coords(0, cellCoords)
	
	#Para la derrota
func showmeyalltrueforms(avoid : Vector2i) -> void:
	var cellCoords : Vector2i
	for y in range(cell_columna):
		for x in range(cell_fila):
			cellCoords = Vector2i(x, y)
			if cells[getCellIndex(cellCoords)] == 0:
				# bomba, duh
				if not cellCoords == avoid:
					set_cell(0, cellCoords, 0, Vector2i(2, 0))
			else:
				# banderita mal puesta
				if getAtlasCoords(cellCoords) == Vector2i(1, 0):
					set_cell(0, cellCoords, 0, Vector2i(1, 3))
					
#función para timer
func _on_timer_timeout() -> void:
	tiempo_restante -= 1
	#oculta las casillas explotadas, para que te olvides
	muleta()
	$CanvasLayer/PanelTiempo/LabelTiempo.text = str(tiempo_restante)
	
	#CAMBIO 7-1.3 lo mismo que el  7-1.2 pero por tiempo
	if tiempo_restante <= 0 && vidas<=0:
		muerte = true
		$CanvasLayer/Timer.stop()
		$CanvasLayer/PanelEstado/LabelEstado.text = "Se acabó el tiempo, perdiste"
		showmeyalltrueforms(Vector2i(-1, -1))
	else: 
		if tiempo_restante <= 0 && vidas>0:
			tiempo_restante += tiempo_extra
			$CanvasLayer/PanelTiempo/LabelTiempo.text = str(tiempo_restante)
			vidas -=1
			$CanvasLayer/PanelVidas/LabelVidas.text = "Totems: " + str(vidas)
			$CanvasLayer/PanelEstado/LabelEstado.text = "Se acabó el tiempo, perdés un totem"
			await get_tree().create_timer(delay_await).timeout
			$CanvasLayer/PanelEstado/LabelEstado.text = "Jugando"
	
	#CAMBIO 7-1.4 lo mismo que el  7-1.3 pero por con creepers
	if tiempo_restante <= 0 && creeper_activo && vidas<=0:
		$CanvasLayer/PanelEstado/LabelEstado.text = "¡El Creeper explotó!, moriste"
		creeper_activo = false
		muerte=true
	else:
		if tiempo_restante <= 0 && creeper_activo && vidas>0:
			vidas -=1
			$CanvasLayer/PanelVidas/LabelVidas.text = "Totems: " + str(vidas)
			cells[getCellIndex(posicion_creeper)]=auxiliarcreeper
			set_cell(0, posicion_creeper, 0, Vector2i(0, 0))
			
			creeper_activo = false
			tiempo_restante=tiempo_restante_guardado
			$CanvasLayer/PanelTiempo/LabelTiempo.text = str(tiempo_restante)
			$CanvasLayer/PanelEstado/LabelEstado.text = "¡El Creeper explotó!, perdiste un totem"
			await get_tree().create_timer(delay_await).timeout
			$CanvasLayer/PanelEstado/LabelEstado.text = "Jugando"

# Función para ganar
func checkWin() -> void:
	var unrevealed := 0
	
	for y in range(cell_columna):
		for x in range(cell_fila):
			var cellCoords := Vector2i(x, y)
			var atlasCoords := getAtlasCoords(cellCoords)
			
			if atlasCoords == Vector2i(0, 0) or atlasCoords == Vector2i(1, 0):
				unrevealed += 1
	
	if unrevealed == mine_count:
		muerte = true
		muleta()
		muleta_otros()
		$CanvasLayer/Timer.stop()
		
		ganar = true
		$CanvasLayer/PanelEstado/LabelEstado.text = "Ganaste"

#CAMBIO 7-4
func eventos_mena() -> void:

	#7-4.1 solo crea creeper si el todopoderoso randf da true
	if randf()<probabilidad_creeper && muerte == false:
		#7-4.2 y si no hay ya un creeper suelto
		if creeper_activo==false:
			#auxiliar para recorrer las casillas nro 8000000
			var casillas := []
			#7-4.3 recorre las casillas vacías
			for y in range(cell_columna):
				for x in range(cell_fila):
					var cellCoords := Vector2i(x, y)
					if getAtlasCoords(cellCoords) == Vector2i(0, 0):
						casillas.append(cellCoords)
			# 7-4.4 si está todo lleno de antorchas puede que ninguna casilla sea 0,0, por eso comprueba
			if casillas.is_empty()==false:
				# 7-4.5 pone un creeper en una posición random
				posicion_creeper = casillas.pick_random()
				auxiliarcreeper=cells[getCellIndex(posicion_creeper)]
				cells[getCellIndex(posicion_creeper)] = 9
				set_cell(0, posicion_creeper, 0, Vector2i(2, 3))
				#7-4.6 pone activo 
				creeper_activo = true
				#se usa el auxiliar y se pone el tiempo para correr
				tiempo_restante_guardado=tiempo_restante
				tiempo_restante=tiempo_creeper
				$CanvasLayer/PanelTiempo/LabelTiempo.text = "CREEPER, CORRÉ " + str(tiempo_restante)

	#totem
	#comprueba si dá el porcentaje
	if randf()<probabilidad_totem && muerte == false:
		# comprueba si no hay ya otro totem
		if not totem_activo:
			#mismo axuliar que el creeper
			var casillas_totem := []
			#mismo recorrido que el creeper
			for y in range(cell_columna):
				for x in range(cell_fila):
					var cellCoords := Vector2i(x, y)
					if getAtlasCoords(cellCoords) == Vector2i(0, 0):
						casillas_totem.append(cellCoords)
			#es todo lo mismo
			if not casillas_totem.is_empty():
				posicion_totem = casillas_totem.pick_random()
				auxiliartotem=cells[getCellIndex(posicion_totem)]
				cells[getCellIndex(posicion_totem)] = 10
				set_cell(0, posicion_totem, 0, Vector2i(3, 3))
				totem_activo = true
				#7-4.7 espera lo que tiene que esperar para que desaparezca
				await get_tree().create_timer(tiempo_totem).timeout
				#7-4.8 si no lo agarraste, desaparece
				if totem_activo:
					set_cell(0, posicion_totem, 0, Vector2i(0, 0))
					cells[getCellIndex(posicion_totem)]=auxiliartotem
					totem_activo = false

#7-5 el botón
func _on_boton_correr_pressed() -> void:
	# si no hay creeper no hace nada
	if creeper_activo == true&& muerte == false:
#ya no está activo, devuelve la casilla a una normal, devuelve el tiempo al de antes y te avisa que escapaste
		creeper_activo = false
		cells[getCellIndex(posicion_creeper)]=auxiliarcreeper
		set_cell(0, posicion_creeper, 0, Vector2i(0, 0))

		tiempo_restante=tiempo_restante_guardado
		$CanvasLayer/PanelTiempo/LabelTiempo.text = str(tiempo_restante)
		$CanvasLayer/PanelEstado/LabelEstado.text = "Escapaste"
		await get_tree().create_timer(delay_await).timeout
		$CanvasLayer/PanelEstado/LabelEstado.text = "Jugando"
		
#para solucionar el problema de que a veces mostravas calaveras cuando no debía
func muleta() -> void:
	var cellCoords : Vector2i
	for y in range(cell_columna):
		for x in range(cell_fila):
			cellCoords = Vector2i(x, y)
			if getAtlasCoords(cellCoords) ==  Vector2i(0, 3):
					set_cell(0, cellCoords, 0, Vector2i(0, 0))
func muleta_otros() -> void:
	var cellCoords : Vector2i
	for y in range(cell_columna):
		for x in range(cell_fila):
			cellCoords = Vector2i(x, y)
			if getAtlasCoords(cellCoords) ==  Vector2i(0, 3) or getAtlasCoords(cellCoords) ==  Vector2i(2, 3) or getAtlasCoords(cellCoords) ==  Vector2i(3, 3):
					set_cell(0, cellCoords, 0, Vector2i(0, 0))
