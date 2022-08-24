import
  std/terminal,
  std/os,
  std/strformat,
  std/random

type
  State = enum
    Closed
    Open
    Flagged

  Spot = object
    state: State
    value: range[0..9] # 0 = empty 9 = bomb

  Field = seq[seq[Spot]]

  Cursor = object
    x: int
    y: int

  Game = object
    cursor: Cursor
    field: Field
    height: int
    width: int
    mines: int

proc initSpot: Spot =
  Spot(state: Closed, value: 0)

proc placeMine(field: var Field, height, width: int): bool =
  if field[height][width].value == 9:
    false
  else:
    field[height][width].value = 9
    true

proc neighbourBombs(field: Field, height, width: int): range[0..9] =
  if field[height][width].value == 9:
    return 9
  # row over
  if height - 1 >= 0:
    if width - 1 >= 0:
      if field[height - 1][width - 1].value == 9:
        result += 1
    if field[height - 1][width].value == 9:
      result += 1
    if width + 1 < field[height - 1].len:
      if field[height - 1][width + 1].value == 9:
        result += 1
  # self row
  if width - 1 >= 0:
    if field[height][width - 1].value == 9:
      result += 1
  if width + 1 < field[height].len:
    if field[height][width + 1].value == 9:
      result += 1
  # under
  if height + 1 < field.len:
    if width - 1 >= 0:
      if field[height + 1][width - 1].value == 9:
        result += 1
    if field[height + 1][width].value == 9:
      result += 1
    if width + 1 < field[height + 1].len:
      if field[height + 1][width + 1].value == 9:
        result += 1
      
proc setValue(field: var Field, height, width: int) =
  field[height][width].value = field.neighbourBombs(height, width)

proc initField(height, width, mines: int): Field =
  for h in 0..<height:
    var line: seq[Spot] = @[]
    for w in 0..<width:
      line.add initSpot()
    result.add(line)
  
  randomize()
  var placedMines = 0
  while placedMines < mines:
    let 
      randH = rand(height - 1)
      randW = rand(width - 1)
    if result.placeMine(randH, randW):
      placedMines += 1

  for h in 0..<height:
    for w in 0..<width:
      result.setValue(h, w)


proc `$`(self: Field): string =
  for line in self:
    for spot in line:
      result &= $spot.value
    result &= '\n'

proc print(self: Game) =
  for h, line in self.field.pairs:
    for w, spot in line.pairs:
      case spot.state
      of Flagged:
        if self.cursor.x == w and self.cursor.y == h:
          stdout.styledWrite(fgWhite, "[", fgRed, "P", fgWhite ,"]")
        else:
          stdout.styledWrite(fgRed, " P ")
      of Closed:
        if self.cursor.x == w and self.cursor.y == h:
          stdout.styledWrite(fgWhite, "[.]")
        else:
          stdout.styledWrite(" . ")
      of Open:
        case spot.value
        of 0: 
          if self.cursor.x == w and self.cursor.y == h:
            stdout.styledWrite(fgWhite, "[ ]")
          else:
            stdout.styledWrite("   ")
        of 1: 
          if self.cursor.x == w and self.cursor.y == h:
            stdout.styledWrite(fgWhite, "[", fgBlue, "1", fgWhite, "]")
          else:
            stdout.styledWrite(fgBlue, " 1 ")
        of 2: 
          if self.cursor.x == w and self.cursor.y == h:
            stdout.styledWrite(fgWhite, "[", fgGreen, "2", fgWhite, "]")
          else:
            stdout.styledWrite(fgGreen, " 2 ")
        of 3: 
          if self.cursor.x == w and self.cursor.y == h:
            stdout.styledWrite(fgWhite, "[", fgMagenta, "3", fgWhite, "]")
          else:
            stdout.styledWrite(fgMagenta, " 3 ")
        of 4: 
          if self.cursor.x == w and self.cursor.y == h:
            stdout.styledWrite(fgWhite, "[", fgRed, "4", fgWhite, "]")
          else:
            stdout.styledWrite(fgRed, " 4 ")
        of 5..8: 
          if self.cursor.x == w and self.cursor.y == h:
            stdout.styledWrite(fgWhite, "[", $spot.value, "]")
          else:
            stdout.styledWrite(fgWhite, " " & $spot.value & " ")
        of 9: 
          if self.cursor.x == w and self.cursor.y == h:
            stdout.styledWrite(fgWhite, "[", fgYellow, "*", fgWhite, "]")
          else:
            stdout.styledWrite(fgYellow, " * ")
    stdout.write "\n"

proc up(self: var Game) =
  if self.cursor.y != 0:
    self.cursor.y -= 1 
  else:
    self.cursor.y = self.height - 1

proc down(self: var Game) =
  if self.cursor.y != self.height - 1:
    self.cursor.y += 1 
  else: 
    self.cursor.y = 0

proc left(self: var Game) =
  if self.cursor.x != 0:
    self.cursor.x -= 1 
  else:
    self.cursor.x = self.width - 1

proc right(self: var Game) =
  if self.cursor.x != self.width - 1:
    self.cursor.x += 1 
  else: 
    self.cursor.x = 0

proc newGame(height, width, mines: int): Game =
  result.field = initField(height, width, mines)
  result.cursor = Cursor(x: 0, y: 0)
  result.height = height
  result.width = width
  result.mines = mines

proc open(self: var Game)

proc openNeigbours(self: var Game) =
  let current = self.cursor
  # up
  if current.y != self.height - 1:
    if current.x != 0:
      self.cursor.x -= 1
      self.cursor.y += 1
      self.open()
      self.cursor = current
    if current.x != self.width - 1:
      self.cursor.y += 1
      self.cursor.x += 1
      self.open()
      self.cursor = current
    self.cursor.y += 1
    self.open()
    self.cursor = current
  # middle
    if current.x != 0:
      self.cursor.x -= 1
      self.open()
      self.cursor = current
    if current.x != self.width - 1:
      self.cursor.x += 1
      self.open()
      self.cursor = current
  # down
  if current.y != 0:
    if current.x != 0:
      self.cursor.x -= 1
      self.cursor.y -= 1
      self.open()
      self.cursor = current
    if current.x != self.width - 1:
      self.cursor.y -= 1
      self.cursor.x += 1
      self.open()
      self.cursor = current
    self.cursor.y -= 1
    self.open()
    self.cursor = current

proc open(self: var Game) =
  if self.field[self.cursor.y][self.cursor.x].state == Open:
    return
  let current = self.cursor
  self.field[self.cursor.y][self.cursor.x].state = Open
  if self.field[self.cursor.y][self.cursor.x].value == 0:
    self.openNeigbours()

  self.cursor = current

proc flag(self: var Game) =
  case self.field[self.cursor.y][self.cursor.x].state
  of Closed:
    self.field[self.cursor.y][self.cursor.x].state = Flagged
  of Flagged:
    self.field[self.cursor.y][self.cursor.x].state = Closed
  of Open:
    return

var game = newGame(15, 25, 35)

stdout.hideCursor()

while true:
  stdout.eraseScreen()
  stdout.setCursorPos(0,0)
  print game
  let key = getch()
  case key
  of 'q': break
  of 'w': game.up()
  of 'r': game.down()
  of 'a': game.left()
  of 's': game.right()
  of 'u': game.open()
  of 'y': game.flag()
  else:
    continue

stdout.showCursor()
stdout.resetAttributes()

