#include <stdlib.h> // card > aek.ppm
#include <stdio.h>
#include <algorithm>
#include <math.h>

const int width = 1920;
const int height = 1080;
const int samples = 256;

struct vec
{
  float x, y, z;
  vec operator+(vec r) { return vec(x + r.x, y + r.y, z + r.z); }
  vec operator*(float r) { return vec(x * r, y * r, z * r); }
  float operator%(vec r) { return x * r.x + y * r.y + z * r.z; }
  vec() {}
  vec operator^(vec r) { return vec(y * r.z - z * r.y, z * r.x - x * r.z, x * r.y - y * r.x); }
  vec(float a, float b, float c)
  {
    x = a;
    y = b;
    z = c;
  }
  vec operator!() { return *this * (1 / sqrt(*this % *this)); }
};
int balls[] = {247570, 280596, 280600,
           249748, 18578, 18577, 231184, 16, 16};
float uniformRandom()
{
  return (float)rand() / RAND_MAX;
}
int trace(vec origin, vec direction, float &t, vec &normal)
{
  t = 1e9;
  int material = 0;
  float p = -origin.z / direction.z;
  if (.01 < p)
    t = p, normal = vec(0, 0, 1), material = 1;
  for (int k = 19; k--;)
    for (int j = 9; j--;)
      if (balls[j] & 1 << k)
      {
        vec p = origin + vec(-k, 0, -j - 4);
        float b = p % direction, c = p % p - 1, q = b * b - c;
        if (q > 0)
        {
          float s = -b - sqrt(q);
          if (s < t && s > .01)
            t = s, normal = !(p + direction * t), material = 2;
        }
      }
  return material;
}
vec shade(vec origin, vec direction)
{
  float t;
  vec normal;
  int m = trace(origin, direction, t, normal);
  if (m == 0)
    return vec(.7, .6, 1) *
           pow(1 - direction.z, 4);
  vec hit = origin + direction * t;
  vec light = !(vec(9 + uniformRandom(), 9 + uniformRandom(), 16) + hit * -1);
  vec r = direction + normal * (normal % direction * -2);
  float diffuse = light % normal;
  if (diffuse < 0 || trace(hit, light, t, normal))
    diffuse = 0;
  float phong = pow(light % r * (diffuse > 0), 99);
  if (m == 1)
  {
    hit = hit * .2;
    return (
      (int)(ceil(hit.x) + ceil(hit.y)) & 1 ?
      vec(3, 1, 1) :
      vec(3, 3, 3)
      ) * (diffuse * .2 + .1);
  }
  return vec(phong, phong, phong) + shade(hit, r) * .5;
}
int main()
{
  printf("P6 %d %d 255 ", width, height);
  vec g = !vec(-6, -16, 0);
  vec a = !(vec(0, 0, 1) ^ g) * (1.0 / std::min(width, height));
  vec b = !(g ^ a) * (1.0 / std::min(width, height));
  vec c = (a * width + b * height) * -0.5 + g;
  for (int y = height; y--;)
    for (int x = width; x--;)
    {
      vec p(13, 13, 13);
      for (int r = samples; r--;)
      {
        vec t = a * (uniformRandom() - .5) * 99 +
                b * (uniformRandom() - .5) * 99;
        p = shade(vec(17, 16, 8) + t, !(t * -1 + (a * (uniformRandom() + x) + b * (y + uniformRandom()) + c) * 16)) * (224.0 / samples) + p;
      }
      printf("%c%c%c", (int)p.x, (int)p.y, (int)p.z);
    }
}
