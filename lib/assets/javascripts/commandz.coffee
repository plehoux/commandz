class CommandZ

  constructor: ->
    @VERSION = '0.0.3'
    @statusChangeCallback = null
    @storageChangeCallback = null

    this.clear()
    this.keyboardShortcuts(true)

  clear: ->
    @history = []
    @index = -1

  keyboardShortcuts: (enable=true) ->
    addOrRemove = if enable then 'addEventListener' else 'removeEventListener'
    document[addOrRemove]('keypress', this.handleKeypress)

  handleKeypress: (e) =>
    return if document.activeElement.nodeName is 'INPUT'
    return unless e.keyCode is 122 and e.metaKey is true

    e.preventDefault()
    if e.shiftKey then this.redo() else this.undo()

  # Execute and store commands as { command: {up: ->, down: ->} }
  execute: (command) ->
    historyItem = {}
    historyItem.command = command

    this.up(command)
    this.addToHistory(historyItem)

  # Store data as { data: … }
  store: (data) ->
    historyItem = {}
    historyItem.data = data

    this.addToHistory(historyItem)

  # History management
  addToHistory: (historyItem) ->
    # Overwrite upcoming history items
    if @index < @history.length - 1
      difference = (@history.length - @index) - 1
      @history.splice(-difference)

    @history.push(historyItem)
    @index = @history.length - 1

    this.handleStatusChange()

  undo: (times=1) ->
    return unless this.status().canUndo

    for i in [1..times]
      return unless @history[@index]

      historyItem = @history[@index]
      this.down(command) if command = historyItem.command

      # Has to be after a command item, but before a data item
      @index--

      if historyItem = @history[@index]
        this.sendData(data) if data = historyItem.data

      this.handleStatusChange()

  redo: (times=1) ->
    return unless this.status().canRedo

    for i in [1..times]
      return unless @history[@index + 1]

      # Has to be before both a command and a data item
      @index++

      historyItem = @history[@index]
      this.up(command) if command = historyItem.command
      this.sendData(data) if data = historyItem.data

      this.handleStatusChange()

  # Execute up/down action on a command
  # command can be a group of commands or a single command
  exec: (action, command) ->
    return command[action]() unless command instanceof Array
    c[action]() for c in command

  up:   (command) -> this.exec('up',   command)
  down: (command) -> this.exec('down', command)

  # Send current history item data
  sendData: (data) ->
    return unless @storageChangeCallback
    @storageChangeCallback(data)

  # Storage management
  onStorageChange: (callback) ->
    @storageChangeCallback = callback

  # Status management
  onStatusChange: (callback) ->
    @statusChangeCallback = callback
    this.handleStatusChange()

  handleStatusChange: ->
    return unless @statusChangeCallback
    @statusChangeCallback(this.status())

  status: ->
    canUndo: @index > -1
    canRedo: @index < @history.length - 1

# Singleton
@CommandZ = new CommandZ
