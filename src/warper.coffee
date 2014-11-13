
# Adapted from
# https://code.google.com/p/wiimotetuio/source/browse/trunk/WiimoteTUIO/Warper.cs
# Discoverd via
# http://www.gamedev.net/topic/539588-transform-arbitrary-quadrangle-into-unit-square/
# Related
# http://wiki.panotools.org/Perspective_correction
# http://franklinta.com/2014/09/08/computing-css-matrix3d-transforms/
# https://github.com/julapy/ofxQuadWarp/blob/master/src/ofxQuadWarp.cpp
# http://docs.opencv.org/modules/imgproc/doc/geometric_transformations.html#getperspectivetransform

zeroes = (n) ->
  a = new Array(n)
  for i in [0...n]
    a[i] = 0
  return a

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

  setIdentity: ->
    @setSource(0, 0, 1, 0, 0, 1, 1, 1)
    @setDestination(0, 0, 1, 0, 0, 1, 1, 1)
    @computeWarp()

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

    mat[ 0] = a
    mat[ 1] = d
    mat[ 2] = 0
    mat[ 3] = g
    mat[ 4] = b
    mat[ 5] = e
    mat[ 6] = 0
    mat[ 7] = h
    mat[ 8] = 0
    mat[ 9] = 0
    mat[10] = 1
    mat[11] = 0
    mat[12] = c
    mat[13] = f
    mat[14] = 0
    mat[15] = 1

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
    idet = 1 / (a * A + b * D + c * G)
    mat[ 0] = A * idet
    mat[ 1] = D * idet
    mat[ 2] = 0
    mat[ 3] = G * idet
    mat[ 4] = B * idet
    mat[ 5] = E * idet
    mat[ 6] = 0
    mat[ 7] = H * idet
    mat[ 8] = 0
    mat[ 9] = 0
    mat[10] = 1
    mat[11] = 0
    mat[12] = C * idet
    mat[13] = F * idet
    mat[14] = 0
    mat[15] = I * idet

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
