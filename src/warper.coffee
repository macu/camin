
zeroes = (n) ->
  a = new Array(n)
  for i in [0...n]
    a[i] = 0
  return a

# http://wiki.panotools.org/Perspective_correction
class Warper
constructor: ->
  @srcX = zeroes(4)
  @srcY = zeroes(4)
  @dstX = zeroes(4)
  @dstY = zeroes(4)
  @srcMat = zeroes(16)
  @dstMat = zeroes(16)
  @warpMat = zeroes(16)
  @dirty = false
  @setIdentity()
  return

setIdentity: ->
  @setSource(0, 0, 1, 0, 0, 1, 1, 1)
  @setDestination(0, 0, 1, 0, 0, 1, 1, 1)
  @computeWarp()
  return

setSource: (x0, y0, x1, y1, x2, y2, x3, y3) ->
  @srcX[0] = x0
  @srcY[0] = y0
  @srcX[1] = x1
  @srcY[1] = y1
  @srcX[2] = x2
  @srcY[2] = y2
  @srcX[3] = x3
  @srcY[3] = y3
  @dirty = true
  return

setDestination: (x0, y0, x1, y1, x2, y2, x3, y3) ->
  @dstX[0] = x0
  @dstY[0] = y0
  @dstX[1] = x1
  @dstY[1] = y1
  @dstX[2] = x2
  @dstY[2] = y2
  @dstX[3] = x3
  @dstY[3] = y3
  @dirty = true
  return

computeWarp: ->
  @computeQuadToSquare @srcX[0], @srcY[0],
  @srcX[1], @srcY[1],
  @srcX[2], @srcY[2],
  @srcX[3], @srcY[3],
  @srcMat
  @computeSquareToQuad @dstX[0], @dstY[0],
  @dstX[1], @dstY[1],
  @dstX[2], @dstY[2],
  @dstX[3], @dstY[3],
  @dstMat
  @multMats @srcMat, @dstMat, @warpMat
  @dirty = false
  return

multMats: (srcMat, dstMat, resMat) ->
  for r in [0...4]
    ri = r * 4
    for c in [0...4]
      resMat[ri + c] =
      srcMat[ri    ] * dstMat[c    ] +
      srcMat[ri + 1] * dstMat[c + 4] +
      srcMat[ri + 2] * dstMat[c + 8] +
      srcMat[ri + 3] * dstMat[c + 12]
  return

computeSquareToQuad: (x0, y0, x1, y1, x2, y2, x3, y3, mat) ->
  dx1 = x1 - x2
  dy1 = y1 - y2
  dx2 = x3 - x2
  dy2 = y3 - y2
  sx = x0 - x1 + x2 - x3
  sy = y0 - y1 + y2 - y3
  g = (sx * dy2 - dx2 * sy) / (dx1 * dy2 - dx2 * dy1)
  h = (dx1 * sy - sx * dy1) / (dx1 * dy2 - dx2 * dy1)
  a = x1 - x0 + g * x1
  b = x3 - x0 + h * x3
  c = x0
  d = y1 - y0 + g * y1
  e = y3 - y0 + h * y3
  f = y0

  [mat[ 0], mat[ 1], mat[ 2], mat[ 3]] = [a, d, 0, g]
  [mat[ 4], mat[ 5], mat[ 6], mat[ 7]] = [b, e, 0, h]
  [mat[ 8], mat[ 9], mat[10], mat[11]] = [0, 0, 1, 0]
  [mat[12], mat[13], mat[14], mat[15]] = [c, f, 0, 1]
  return

computeQuadToSquare: (x0, y0, x1, y1, x2, y2, x3, y3, mat) ->
  @computeSquareToQuad x0,y0,x1,y1,x2,y2,x3,y3, mat
  # invert through adjoint

  a = mat[ 0]
  d = mat[ 1]
  g = mat[ 3]
  b = mat[ 4]
  e = mat[ 5]
  h = mat[ 7]
  c = mat[12]
  f = mat[13]

  A =     e - f * h
  B = c * h - b
  C = b * f - c * e
  D = f * g - d
  E =     a - c * g
  F = c * d - a * f
  G = d * h - e * g
  H = b * g - a * h
  I = a * e - b * d

  # Probably unnecessary since 'I' is also scaled by the determinant,
  #   and 'I' scales the homogeneous coordinate, which, in turn,
  #   scales the X,Y coordinates.
  # Determinant  =   a * (e - f * h) + b * (f * g - d) + c * (d * h - e * g);
  id = 1 / (a * A + b * D + c * G)

  [mat[ 0], mat[ 1], mat[ 2], mat[ 3]] = [A * id, D * id, 0, G * id]
  [mat[ 4], mat[ 5], mat[ 6], mat[ 7]] = [B * id, E * id, 0, H * id]
  [mat[ 8], mat[ 9], mat[10], mat[11]] = [     0,      0, 1,      0]
  [mat[12], mat[13], mat[14], mat[15]] = [C * id, F * id, 0, I * id]
  return

warp: (srcX, srcY) ->
  @computeWarp() if @dirty

  mat = @warpMat
  result = zeroes(4)
  z = 0
  result0 = (srcX*mat[0] + srcY*mat[4] + z*mat[8] + 1*mat[12])
  result1 = (srcX*mat[1] + srcY*mat[5] + z*mat[9] + 1*mat[13])
  result2 = (srcX*mat[2] + srcY*mat[6] + z*mat[10] + 1*mat[14])
  result3 = (srcX*mat[3] + srcY*mat[7] + z*mat[11] + 1*mat[15])

  dstX = result0 / result3
  dstY = result1 / result3
  return [dstX, dstY]
