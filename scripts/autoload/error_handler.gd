extends Node
## ErrorHandler Autoload Singleton
##
## Provides centralized error logging and tracking for the entire game.
## Supports multiple severity levels, consistent formatting, and maintains
## an error history for debugging purposes.

# =============================================================================
# SEVERITY LEVELS
# =============================================================================

## Severity levels for log messages
enum Severity {
	INFO,     ## Informational messages, useful for debugging
	WARNING,  ## Potential issues that don't stop execution
	ERROR,    ## Errors that affect functionality but don't crash
	CRITICAL  ## Critical failures that may crash or break the game
}

## String representations of severity levels
const SEVERITY_NAMES: Array[String] = ["INFO", "WARNING", "ERROR", "CRITICAL"]

## Colors for different severity levels (for potential UI display)
const SEVERITY_COLORS: Dictionary = {
	Severity.INFO: Color.LIGHT_BLUE,
	Severity.WARNING: Color.YELLOW,
	Severity.ERROR: Color.ORANGE_RED,
	Severity.CRITICAL: Color.RED
}

# =============================================================================
# SIGNALS
# =============================================================================

## Emitted when any error is logged, useful for UI notifications
## severity: The Severity enum value
## message: The full formatted log message
signal error_logged(severity: int, message: String)

# =============================================================================
# CONFIGURATION
# =============================================================================

## Maximum number of errors to keep in history
const MAX_ERROR_HISTORY: int = 100

## Whether to include stack traces in debug mode
const INCLUDE_STACK_TRACE: bool = true

## Minimum severity level to emit signals (avoid UI spam from INFO messages)
const MIN_SIGNAL_SEVERITY: int = Severity.WARNING

# =============================================================================
# STATE
# =============================================================================

## Error history storage
## Each entry: { "timestamp": String, "severity": int, "source": String,
##               "message": String, "formatted": String }
var _error_history: Array[Dictionary] = []

## Whether we're running in debug mode
var _is_debug: bool = false


# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	# Detect if running in debug mode
	_is_debug = OS.is_debug_build()

	if _is_debug:
		log_info("ErrorHandler", "ErrorHandler initialized in DEBUG mode")
	else:
		log_info("ErrorHandler", "ErrorHandler initialized in RELEASE mode")


func _exit_tree() -> void:
	# Clear history to free memory
	_error_history.clear()


# =============================================================================
# PUBLIC LOGGING METHODS
# =============================================================================

## Logs an informational message
## source: The system/component generating the message (e.g., "WaveManager")
## message: The message to log
func log_info(source: String, message: String) -> void:
	_log(Severity.INFO, source, message)


## Logs a warning message
## source: The system/component generating the message
## message: The message to log
func log_warning(source: String, message: String) -> void:
	_log(Severity.WARNING, source, message)


## Logs an error message
## source: The system/component generating the message
## message: The message to log
func log_error(source: String, message: String) -> void:
	_log(Severity.ERROR, source, message)


## Logs a critical error message
## source: The system/component generating the message
## message: The message to log
func log_critical(source: String, message: String) -> void:
	_log(Severity.CRITICAL, source, message)


# =============================================================================
# ERROR HISTORY
# =============================================================================

## Returns a copy of the error history
## Returns: Array of dictionaries with error information
func get_error_history() -> Array:
	return _error_history.duplicate()


## Returns errors filtered by minimum severity
## min_severity: Minimum Severity level to include
## Returns: Array of dictionaries with error information
func get_errors_by_severity(min_severity: int) -> Array:
	var filtered: Array = []
	for entry in _error_history:
		if entry["severity"] >= min_severity:
			filtered.append(entry)
	return filtered


## Returns the most recent N errors
## count: Number of errors to return
## Returns: Array of dictionaries with error information
func get_recent_errors(count: int) -> Array:
	var start_index = max(0, _error_history.size() - count)
	return _error_history.slice(start_index)


## Clears the error history
func clear_history() -> void:
	_error_history.clear()
	if _is_debug:
		print("[ErrorHandler] History cleared")


## Returns the number of errors in history
func get_error_count() -> int:
	return _error_history.size()


## Returns the number of errors of a specific severity
func get_error_count_by_severity(severity: int) -> int:
	var count: int = 0
	for entry in _error_history:
		if entry["severity"] == severity:
			count += 1
	return count


# =============================================================================
# INTERNAL METHODS
# =============================================================================

## Internal logging implementation
func _log(severity: int, source: String, message: String) -> void:
	var timestamp = _get_timestamp()
	var severity_name = SEVERITY_NAMES[severity] if severity < SEVERITY_NAMES.size() else "UNKNOWN"

	# Format the message
	var formatted = _format_message(timestamp, severity_name, source, message)

	# Create history entry
	var entry: Dictionary = {
		"timestamp": timestamp,
		"severity": severity,
		"severity_name": severity_name,
		"source": source,
		"message": message,
		"formatted": formatted
	}

	# Add to history
	_add_to_history(entry)

	# Output to console based on severity and debug mode
	_output_to_console(severity, formatted, source)

	# Emit signal for UI notifications (only for warnings and above)
	if severity >= MIN_SIGNAL_SEVERITY:
		error_logged.emit(severity, formatted)


## Formats a log message with consistent structure
func _format_message(timestamp: String, severity: String, source: String, message: String) -> String:
	return "[%s] [%s] [%s] %s" % [timestamp, severity, source, message]


## Returns the current timestamp in HH:MM:SS.mmm format
func _get_timestamp() -> String:
	var time = Time.get_time_dict_from_system()
	var msec = Time.get_ticks_msec() % 1000
	return "%02d:%02d:%02d.%03d" % [time["hour"], time["minute"], time["second"], msec]


## Adds an entry to the error history, managing capacity
func _add_to_history(entry: Dictionary) -> void:
	_error_history.append(entry)

	# Trim history if over capacity
	while _error_history.size() > MAX_ERROR_HISTORY:
		_error_history.pop_front()


## Outputs the message to the appropriate console function
func _output_to_console(severity: int, formatted: String, source: String) -> void:
	match severity:
		Severity.INFO:
			# Only print INFO in debug mode
			if _is_debug:
				print(formatted)

		Severity.WARNING:
			# Use push_warning for visibility in debug
			if _is_debug:
				push_warning(formatted)
			else:
				# In release, still log warnings but less verbosely
				print(formatted)

		Severity.ERROR:
			# Errors are always logged
			push_error(formatted)
			# In debug mode, also print stack trace
			if _is_debug and INCLUDE_STACK_TRACE:
				_print_stack_trace()

		Severity.CRITICAL:
			# Critical errors are always prominently logged
			push_error("!!! CRITICAL !!! " + formatted)
			# Always print stack trace for critical errors
			if INCLUDE_STACK_TRACE:
				_print_stack_trace()


## Prints the current stack trace (debug aid)
func _print_stack_trace() -> void:
	var stack = get_stack()
	if stack.size() > 2:  # Skip _print_stack_trace and _output_to_console frames
		print("  Stack trace:")
		for i in range(2, min(stack.size(), 10)):  # Limit to 8 frames
			var frame = stack[i]
			print("    at %s:%d in %s()" % [frame["source"], frame["line"], frame["function"]])


# =============================================================================
# CONVENIENCE METHODS
# =============================================================================

## Logs an error with additional context data
## source: The system/component generating the message
## message: The message to log
## context: Dictionary of additional context data
func log_error_with_context(source: String, message: String, context: Dictionary) -> void:
	var context_str = ""
	for key in context:
		context_str += "\n    %s: %s" % [key, str(context[key])]
	log_error(source, message + context_str)


## Logs a warning with additional context data
## source: The system/component generating the message
## message: The message to log
## context: Dictionary of additional context data
func log_warning_with_context(source: String, message: String, context: Dictionary) -> void:
	var context_str = ""
	for key in context:
		context_str += "\n    %s: %s" % [key, str(context[key])]
	log_warning(source, message + context_str)


## Asserts a condition and logs an error if it fails
## Returns: Whether the condition was true
## condition: The condition to check
## source: The system/component making the assertion
## message: The message to log if assertion fails
func assert_true(condition: bool, source: String, message: String) -> bool:
	if not condition:
		log_error(source, "Assertion failed: " + message)
	return condition


## Asserts that a value is not null and logs an error if it is
## Returns: Whether the value was not null
## value: The value to check
## source: The system/component making the assertion
## value_name: Name of the value being checked (for the error message)
func assert_not_null(value: Variant, source: String, value_name: String) -> bool:
	if value == null:
		log_error(source, "Null value: %s is null" % value_name)
		return false
	return true
