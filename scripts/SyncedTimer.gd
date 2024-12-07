extends Timer
class_name SyncedTimer

@export var timeLimit: float = 300.0  # Tiempo total del temporizador (en segundos)
var start_time: float = 0.0           # Marca de tiempo de inicio del temporizador
var isTimerRunning: bool = false
var isPaused: bool = false
var remaining_time: float = 0.0#:      # Tiempo restante cuando está en pausa
	#set(time):
		#remaining_time = time
		#if multiplayer.is_server():
			#print()
	#get:
		#return remaining_time

signal end()

func _ready() -> void:
	timeout.connect(onTimerEnd)
	
	if multiplayer.is_server():
		# El servidor solo inicializa el estado, no arranca el temporizador inmediatamente
		isTimerRunning = false
		isPaused = false
		remaining_time = timeLimit
	else:
		# Cliente solicita sincronización al servidor
		rpc_id(1, "sync_timer_request")

# Método para iniciar el temporizador (servidor)
func start_timer():
	if not isTimerRunning:
		start_time = Time.get_ticks_msec() / 1000.0  # Tiempo actual en segundos
		start(remaining_time if isPaused else timeLimit)
		isTimerRunning = true
		isPaused = false
		rpc("sync_timer_start", start_time)

# Método para pausar el temporizador (servidor)
func pause_timer():
	if isTimerRunning:
		stop()
		remaining_time = get_remaining_time()
		isTimerRunning = false
		isPaused = true
		rpc("sync_timer_pause", remaining_time)

# Método para detener el temporizador completamente (servidor)
func stop_timer():
	stop()
	isTimerRunning = false
	isPaused = false
	remaining_time = timeLimit
	rpc("sync_timer_stop")

# Sincronización para iniciar el temporizador (clientes)
@rpc("any_peer")
func sync_timer_start(start_time_from_server: float):
	var a = multiplayer.get_remote_sender_id()
	var b = multiplayer.get_unique_id()
	start_time = start_time_from_server
	var elapsed_time = (Time.get_ticks_msec() / 1000.0) - start_time
	remaining_time = max(0.0, timeLimit - elapsed_time)
	if remaining_time > 0:
		start(remaining_time)
		isTimerRunning = true
		isPaused = false

# Sincronización para pausar el temporizador (clientes)
@rpc("any_peer", "call_remote")
func sync_timer_pause(remaining_time_from_server: float):
	stop()
	remaining_time = remaining_time_from_server
	isTimerRunning = false
	isPaused = true

# Sincronización para detener el temporizador completamente (clientes)
@rpc("any_peer")
func sync_timer_stop():
	stop()
	isTimerRunning = false
	isPaused = false
	remaining_time = timeLimit

# Solicitud de estado del temporizador (clientes)
@rpc("any_peer")
func sync_timer_request():
	if multiplayer.is_server():
		if isPaused:
			rpc_id(multiplayer.get_remote_sender_id(), "sync_timer_pause", remaining_time)
		elif isTimerRunning:
			rpc_id(multiplayer.get_remote_sender_id(), "sync_timer_start", start_time)
		else:
			rpc_id(multiplayer.get_remote_sender_id(), "sync_timer_stop")

# Evento al finalizar el temporizador
func onTimerEnd():
	isTimerRunning = false
	isPaused = false
	remaining_time = 0.0
	if multiplayer.is_server():
		rpc("sync_timer_end")

@rpc("any_peer")
func sync_timer_end():
	isTimerRunning = false
	isPaused = false
	remaining_time = 0.0
	timeout.emit()

# Obtener el tiempo restante
func get_remaining_time() -> float:
	if isTimerRunning:
		var elapsed_time = (Time.get_ticks_msec() / 1000.0) - start_time
		return max(0.0, timeLimit - elapsed_time)
	return remaining_time
