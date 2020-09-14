import random
import glm
import bitops
# import nimprof

const
  width = 368
  height = 256
  samples = 64

# proc reflect(incident, normal: Vec3f): Vec3f =
#   let scale = -2 * dot(incident, normal)
#   result.x = incident.x + scale * normal.x
#   result.y = incident.y + scale * normal.y
#   result.z = incident.z + scale * normal.z

const bits =
  [247570, 280596, 280600, 249748, 18578, 18577, 231184, 16, 16]

proc uniformRandom(): float32 =
  rand(1.0)

proc checkBalls(origin, direction: Vec3f, t: var float32, normal: var Vec3f, material: var int) {.used, inline.} =
  when true:
    for j, bit in bits:
      for k in 0 .. 18:
        if bit.testBit(k):
          let p = origin + vec3f(-k.float32, 0, -j.float32 - 4)
          let b = dot(p, direction)
          let c = p.length2 - 1
          let q = b*b - c
          if q > 0:
            let s = -b - sqrt(q)
            if s < t and s > 0.01f32:
              t = s
              normal = normalize(p + direction * t)
              material = 2

var traceCount = 0

proc trace(origin, direction: Vec3f, t: var float32, normal: var Vec3f): int =
  inc(traceCount)
  t = float32.high
  let p = -origin.z / direction.z
  if 0.01f32 < p:
    t = p
    normal = vec3f(0, 0, 1)
    result = 1
  checkBalls(origin, direction, t, normal, result)

proc shade(origin, direction: Vec3f): Vec3f =
  var t: float32
  var normal: Vec3f
  let material = trace(origin, direction, t, normal)
  if material == 0:
    return vec3f(0.7f32, 0.6f32, 1.0f32) *
      pow(1 - direction.z, 4)

  let hit = origin + direction * t
  let light = normalize(vec3f(
    9f32 + uniformRandom(),
    9f32 + uniformRandom(),
    16) + hit * -1)
  let reflect = reflect(direction, normal)
  var b = dot(light, normal)
  if b < 0 or trace(hit, light, t, normal) != 0:
    b = 0
  let p =
    if b > 0: pow(dot(light, reflect), 99)
    else: 0f32
  if material == 1:
    let h = hit * 0.2f32
    if ((ceil(h.x) + ceil(h.y)).toInt and 1) == 1:
      return vec3f(3, 1, 1) * (b * 0.2f32 + 0.1f32)
    else:
      return vec3f(3, 3, 3) * (b * 0.2f32 + 0.1f32)
  
  return vec3f(p, p, p) + shade(hit, reflect) * 0.5f32

proc main =
  randomize()
  var file: File
  if file.open("nimaek.ppm", fmWrite):
    try:
      file.write "P6 ", width, " ", height, " 255 "
      let
        gaze = normalize(vec3f(-6, -16, 0))
        right = normalize(cross(vec3f(0, 0, 1), gaze)) * (1 / min(width, height))
        down = normalize(cross(gaze, right)) * (1 / min(width, height))
        corner = (right * width + down * height) * -0.5 + gaze

      for y in countdown(height-1, 0):
        for x in countdown(width-1, 0):
          var color = vec3f(13, 13, 13)
          for r in 0 .. samples-1:
            let t =
              right * (uniformRandom() - 0.5) * 99 +
              down * (uniformRandom() - 0.5) * 99

            color += shade(
              vec3f(17,16,8) + t,
              normalize(-t +
                (right * (uniformRandom() + x.float32) +
                (down * (uniformRandom() + y.float32)) + corner) * 16f32)
            ) * 224.0 / samples

          if 3 != file.writeChars(
            [
              color.x.toInt.chr,
              color.y.toInt.chr,
              color.z.toInt.chr
            ], 0, 3):
              raise ValueError.newException "could not write to file"
    finally:
      file.close()
  
  echo traceCount.float / (width * height * samples)

main()
