extends TileMap
# -1 casilla vacia
# 0 mina
# 1-8 casilla numero

#Columnas, filas y cantidad de minas (20% del total de casillas)
const cell_columna := 16
const cell_fila := 16
const mine_count := int(cell_columna * cell_fila * 0.20)
#Tiempo para jugar, cuando partida empezada es true se activa 
var tiempo_restante := 1000
var partida_empezada := false
var panel_size := Vector2(100, 40)
#Muerte es gameover, cells la cantidad de casillas, cells_alrededor se usa para revelar cuando tocás una bien
var muerte := false
var cells : Array[int]
var cells_alrededor : Array[int]
var offsetCoords : Vector2i

# CAMBIO 6-1: Esto para tener la ubicación del tablero para moverlo
var posicion_inicial : Vector2
# CAMBIO 6-2: Acá van las posibilidades de cada acción, cada una tiene su función
#CAMBIO 6-3
var probabilidad_resbalar := 0.80
#CAMBIO 6-4
var probabilidad_girar := 0.50
# herramienta sorpresa que nos ayudará mas tarde
var grados = 0
#CAMBIO 6-5
var probabilidad_caer := 0.30
# otra herramienta sorpresa que nos ayudará mas tarde
var caido=false
# CAMBIO 6-2.1 Esta es la probabilidad de que cada segundo se active la función de las acciones como si se hiciera un click
var probabilidad_accion_tiempo := 0.30



# Se activa cuando empieza la escena
var movido = false
var centro : Vector2
func _ready() -> void:
	$CanvasLayer/BotonLevantar.hide()
	randomize()
	setupboard()
	#estado
	$CanvasLayer/PanelEstado/LabelEstado.text = "Toca una casilla"
	#timer
	$CanvasLayer/PanelTiempo/LabelTiempo.text = "Tiempo: " + str(tiempo_restante)
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
	#6-1.1 después de calcular la posición cuando empieza, se iguala a posición inical, para saber
	# donde regresarlo después de moverlo
	posicion_inicial = position
	var board_size_scaled := board_size * scale_factor
	#CAMBIO 6-1.1: Acá calculo el centro porque lo necesito para girar el tablero sobre su propio eje
	centro = posicion_inicial + board_size_scaled / 2.0
	#y para posicionar el boton en el centro (le resto 100 de x e y porque sino toma la esquina. Mide 200x200)
	$CanvasLayer/BotonLevantar.position=centro-Vector2(100,100)
#Pone el panel de estado a la izquierda ajustaddo según tamaño
	$CanvasLayer/PanelEstado.position = Vector2(
		position.x - $CanvasLayer/PanelEstado.size.x - 60,
		position.y + board_size_scaled.y / 2 - $CanvasLayer/PanelEstado.size.y / 2
	)
#Pone el panel de timer a la derecha ajustaddo según tamaño
	$CanvasLayer/PanelTiempo.position = Vector2(
		position.x + board_size_scaled.x + 60,
		position.y + board_size_scaled.y / 2 - $CanvasLayer/PanelTiempo.size.y / 2
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
	#6-5.1 Y tampoco hace nada si está caido el tablero
	if muerte==false&&caido==false:
			
			#Click izquierdo
		if event.is_action_pressed("ShowMeYourTrueForm"):
			var cellAtMouse: Vector2i =local_to_map(get_local_mouse_position())
		# para que no se puedan clickear banderas
			if getCellIndex(cellAtMouse) == -1:
				return
			if getAtlasCoords(cellAtMouse) == Vector2i(0, 0):
				if cells.has(0):
					# 6-2.2 llama a mi hermosa función, ella hace todo. 
					moverse()
					
					trueForm(cellAtMouse)
					checkWin()
			
			# si el clickea una mina (0), shinu
					if cells[getCellIndex(cellAtMouse)] == 0:
						muerte = true
						$CanvasLayer/Timer.stop()
						$CanvasLayer/PanelEstado/LabelEstado.text = "Kaboom"
						showmeyalltrueforms(cellAtMouse)
						
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
	$CanvasLayer/PanelTiempo/LabelTiempo.text = str(tiempo_restante)
#6-2.3 Lo de antes para que se mueva por tiempo, pero solo si el tablero no está 
# ya corrido, porque sino puede irse demasiado lejos y pasar demasiadas cosas juntas
	if randf() < probabilidad_accion_tiempo && movido == false:
		moverse()
		
		
	if tiempo_restante <= 0:
		muerte = true
		$CanvasLayer/Timer.stop()
		$CanvasLayer/PanelEstado/LabelEstado.text = "Se acabó el tiempo"
		showmeyalltrueforms(Vector2i(-1, -1))
		
		
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
		$CanvasLayer/Timer.stop()
		$CanvasLayer/PanelEstado/LabelEstado.text = "Ganaste"

#CAMBIO 6-3: función para saber donde se mueve el tablerinho

func resbalarse() -> void:
	#randomizar movimiento (pre-hecho) y tiempo
	var movimiento:= randi_range(1, 10)
	var tiempo_carga := randf_range(0.5, 2.0)
	#switch para donde se mueve, no lo hice con randf porque sinó me podía mover 1 milimetro o 12 km
	match movimiento:
		1: position += Vector2(100, 0)
		2: position += Vector2(-200, -200)
		3: position += Vector2(0, 100)
		4: position += Vector2(-100, 0)
		5: position += Vector2(0, -100)
		6: position += Vector2(100, 100)
		7: position += Vector2(-100, -100)
		8: position += Vector2(-100, 100)
		9: position += Vector2(100, -100)
		10: position += Vector2(200, 200)
	$CanvasLayer/PanelEstado/LabelEstado.text = "Uy, se te resbaló"
	#espera para confundir
	await get_tree().create_timer(tiempo_carga).timeout
	#se pone bien
	position = posicion_inicial
	#deja ya que se mueva por tiempo
	movido = false
	$CanvasLayer/PanelEstado/LabelEstado.text = "Jugando"

#6-4 esto para que gire
func girarse() -> void:
	# como rota
	var movimiento:= randi_range(1, 4)
	#en este caso solo es el retraso para que se pueda seguir moviendo por tiempo, porque no restaura so posición
	var tiempo_carga := randf_range(0.5, 2.0)
	# calcula la diferencia entre la esquina de la pantalla (posición inicial) y el centro, para usarlao ahora
	var offset := centro - posicion_inicial
	while rotation_degrees==grados:
		movimiento = randi_range(1, 4)
		match movimiento:
			1: grados = 90
			2: grados = 180
			3: grados = 270
			4: grados = 0
	#si no va a girar porque el switch eligió la misma posición de antes, reinicia
	rotation_degrees = grados
	# Mantiene el centro quieto mientras gira
	# rota la distancia entre la esquina y el centro del tablero y lo mueve hasta ahí, muy rara esta macumba. 
	# Y pasa los grados a randianes porque es la unidad que toma vector2
	position = centro - offset.rotated(deg_to_rad(grados))
	$CanvasLayer/PanelEstado/LabelEstado.text = "Uy, se te dió vuelta"
	#espera para confundir
	await get_tree().create_timer(tiempo_carga).timeout
	movido = false
	$CanvasLayer/PanelEstado/LabelEstado.text = "Jugando"

#6-5 esto para que se caiga
func caerse() -> void:
	#para que no siga hasta que lo levantes
	caido=true
	# lo manda fuera de la vista. Si por alguna razón se sigue viendo hay que mandarlo más lejos
	position= Vector2(1000, 1000)
	$CanvasLayer/PanelEstado/LabelEstado.text = "Uy, se te cayó"
	$CanvasLayer/BotonLevantar.show()
	

# 6-6 Randomiza cuál de todas las acciones ocurre
func moverse() -> void:
	var movimiento= randi_range(1, 3)
	match movimiento:
		1: 
			# Si la probabilidad de que ocurra da false, simplemente no hace nada
			if randf()<probabilidad_resbalar: 
				movido = true
				resbalarse()
		2: 
			if randf()<probabilidad_girar: 
				movido = true
				girarse()
		3: 
			if randf()<probabilidad_caer: 
				movido = true
				caerse()

#6-5.3 cuando se apreta el botón, bastante indicativo el nombre
func _on_boton_levantar_pressed() -> void:
	#vuelve el tablero a la posición normal, saca el botón y te deja seguir jugando (y que se mueva por tiempo obvio)
	position=posicion_inicial
	$CanvasLayer/BotonLevantar.hide()
	caido = false
	movido = false
	$CanvasLayer/PanelEstado/LabelEstado.text = "Jugando"
