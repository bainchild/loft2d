extremely odd behavior with print:
setbgcolor+setcolor doesn't change anything(?) when done in love.draw
setbgcolor half/half applies when done in love.load
color changes by interpolating from the first line, being the bg color, to
the last one, being the print color
(the bg color is interspersed with all of the lines)
