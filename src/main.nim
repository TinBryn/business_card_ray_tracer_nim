import math
import random
import strformat
import threadpool

{.experimental: "parallel".}

const text = [
  [1, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 1],
  [1, 1, 0, 0, 0, 1, 0, 0, 1, 0, 0, 1, 1, 0, 0, 0, 1, 1],
  [1, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 1, 0, 1, 0, 1],
  [1, 0, 0, 1, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1],
  [1, 0, 0, 0, 1, 1, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 1],
  [1, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 1]
]

const
  width = 1920
  height = 1080
  samples = 64
  debugDepth = false
  debugRefraction = false

type
  Vec* = object
    x*, y*, z*: float32
  
  Image* = object
    width, height: int
    data: seq[char]

  Material = enum
    mSky, mFloor, mReflective, mRefractive

proc initImage*(width, height: int): Image =
  Image(width: width, height: height, data: newSeq[char](width * height * 3))

proc `[]`*(image: Image, x, y, c: int): char =
  image.data[(x + image.width * y) * 3 + c]
  

proc `[]=`*(image: var Image, x, y, c: int, data: char) =
  image.data[(x + image.width * y) * 3 + c] = data

proc vec(x, y, z: float32): Vec {.inline.} = Vec(x: x, y: y, z: z)

proc `-`*(v: Vec): Vec = vec(-v.x, -v.y, -v.z)
proc `+`*(u, v: Vec): Vec = vec(u.x + v.x, u.y + v.y, u.z + v.z)
proc `*`*(u, v: Vec): Vec = vec(u.x * v.x, u.y * v.y, u.z * v.z)
proc `-`*(u, v: Vec): Vec = vec(u.x - v.x, u.y - v.y, u.z - v.z)

proc `*`*(v: Vec, f: float32): Vec = vec(v.x * f, v.y * f, v.z * f)
proc `*`*(f: float32, v: Vec): Vec = vec(v.x * f, v.y * f, v.z * f)
proc `/`*(v: Vec, f: float32): Vec = vec(v.x / f, v.y / f, v.z / f)
proc `/`*(v: Vec, f: static float32): Vec =
  const mult = 1 / f
  v * mult



proc `%`*(u, v: Vec): float32 = u.x*v.x + u.y*v.y + u.z*v.z

proc `^`*(u, v: Vec): Vec = vec(u.y*v.z - u.z*v.y,
                                u.z*v.x - u.x*v.z,
                                u.x*v.y - u.y*v.x)

proc `!`*(v: Vec): Vec = v / sqrt(v%v)

proc reflect*(v, n: Vec): Vec =
  v - n * (2 * n % v)

proc schlick*(cosine, index: float32): float32 =
  let r0 = (1-index) / (1+index)
  let r1 = r0 * r0
  r1 + (1-r1) * pow(1-cosine, 5)

proc refract*(v, n: Vec, index: float32): tuple[reflected, refracted: Vec, ratio: float32] =
  ##
  let v = !v
  let n = !n
  result.reflected = reflect(v, n)
  let dt = v % n
  let discriminant = 1f32 - index*index * (1f32*dt*dt)
  if discriminant > 0:
    result.refracted = !(index * (v - n * dt) - n * sqrt(discriminant))
    let cosine = (v % n) 
    result.ratio = 1-schlick(cosine, index)
  else:
    result.ratio = 1f

proc intersect(center: Vec, bestT: float32, origin, direction: Vec): tuple[t: float32, normal: Vec] =
  let offset = origin - center
  let b = offset % direction
  let c = offset%offset - 1
  let discriminant = b * b - c
  if discriminant > 0:
    let root = sqrt(discriminant)
    result.t = -b - root
    if result.t > 0.01 and result.t < bestT:
      result.normal = !(offset + direction * result.t)
    else:
      result.t = bestT
  else:
    result.t = bestT

proc trace*(origin, direction: Vec): tuple[bestT: float32, normal: Vec, material: Material] =
  result.bestT = float32.high # start closest point being infinite
  result.material = mSky

  let plainT = -origin.z / direction.z
  if plainT > 0.01:
    result.bestT = plainT
    result.normal = vec(0, 0, 1)
    result.material = mFloor

  for j in 0 ..< text.len:
    for i in 0 ..< (text[0].len):
      case text[j][i]:
      of 1:
        let center = vec((text[0].len - i).float32, 0f32, (text.len - j).float32 + 4)
        let (t, n) = intersect(center, result.bestT, origin, direction)
        if t < result.bestT:
          result.bestT = t
          result.normal = n
          result.material = mReflective
      of 2:
        let center = vec((text[0].len - i).float32, 0f32, (text.len - j).float32 + 4)
        let (t, n) = intersect(center, result.bestT, origin, direction)
        if t < result.bestT:
          result.bestT = t
          result.normal = n
          result.material = mRefractive
      else: continue

proc uniform*(gen: var Rand): float32 =
  gen.rand(1.0)

proc shade*(gen: var Rand, origin, direction: Vec, depth = 8): Vec =
  let (bestT, normal, material) = trace(origin, direction)

  if material == mSky:
    return vec(0.7, 0.6, 1) * pow(1 - direction.z, 4)
  
  let hit = origin + direction * bestT
  let light = ! (vec(9 + uniform(gen), 9 + uniform(gen), 16) - hit)
  var diffuse = light % normal

  if diffuse < 0 or trace(hit, light).material != mSky:
    diffuse = 0
  
  if material == mFloor:
    let tile = int(ceil(hit.x / 5) + ceil(hit.y / 5)) and 1
    if tile == 1:
      return vec(3, 1, 1) * (diffuse / 5 + 0.1)
    else:
      return vec(3, 3, 3) * (diffuse / 5 + 0.1)


  if material == mReflective:
    if depth > 0:
      let reflect = reflect(direction, normal)
      let phong = pow( light % reflect * float32(diffuse > 0), 99)
      return shade(gen, hit, reflect, depth-1) * 0.5 + vec(phong, phong, phong)
    else:
      when debugDepth:
        return vec(3, 0, 3)
      else:
        return vec(0, 0, 0)

  if material == mRefractive:
    if depth > 0:
      let (reflect, refract, ratio) = refract(direction, normal, 1.4)
      let phong = pow( light % reflect * float32(diffuse > 0), 99)
      if uniform(gen) < ratio:
        when debugRefraction:
          return vec(3,0,3)
        else:
          return shade(gen, hit, refract, depth-1) * 0.5
      else:
        when debugRefraction:
          return vec(0,3,0)
        else:
          return shade(gen, hit, reflect, depth-1) * 0.5 + vec(phong, phong, phong)
    else:
      return vec(0, 0, 0) 

proc clamp(f: var float32) =
  if f < 0: f = 0
  if f > 255: f = 255

proc renderLine(image: var Image, y: int) =
  # camera vectors
  const
    eye = vec(18, 19, 10)
    gaze = !(vec(11, 0, 8) - eye)
    fov = max(width, height)
    right = !(gaze ^ vec(0, 0, 1)) / fov
    down = !(gaze ^ right) / fov
    corner = gaze - (right * width + down * height) / 2

  var gen = initRand(y * width + 1)
  for x in 0..<width:
    var color = vec(0, 0, 0)
    for sample in 0 ..< samples:
      let lens = ( right * (uniform(gen) - 0.5) +
                    down * (uniform(gen) - 0.5) ) * 99
      let direction = corner + right * (x.float32 + uniform(gen)) +
                                down * (y.float32 + uniform(gen)) 
      color = color + shade(gen, eye + lens, !(direction * 16 - lens)) * 224 / samples
    
    clamp color.x
    clamp color.y
    clamp color.z
    image[x, y, 0] = color.x.round.toInt.chr
    image[x, y, 1] = color.y.round.toInt.chr
    image[x, y, 2] = color.z.round.toInt.chr
  echo &"line {y+1} done"

proc main =
  var image = initImage(width, height)

  parallel:
    for y in 0..<height:
      spawn renderLine(image, y)  
  var file: File
  if file.open("NIM.ppm", fmWrite):
    try:
      file.write &"P6 {width} {height} 255 "

      for y in 0 ..< height:
        for x in 0 ..< width:
          file.write &"{image[x, y, 0]}{image[x, y, 1]}{image[x, y, 2]}"
    finally:
      file.close()

main()
