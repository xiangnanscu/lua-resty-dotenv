local dotenv = require "resty.dotenv"

local env = dotenv()
local expected_env = {
  A = '1',
  B = '2',
  C = '3',
  D = '4',
  E = '4',
  F = '4',
  G = 'g',
  JSON = '{"foo": "bar"}',
  TRIM_STRING = 'some spaced out string',
  LINES1 = [[this\nis\nmultiple line]],
  LINES2 = [[this
is
multiple line]],
  LINES3 = [[this
is
multiple line]],
  RSA_KEY = [[-----BEGIN RSA PRIVATE KEY-----
#YOUR/FANCY/=KEY/YOUR/FANCY/=KEY
YOUR/FANCY/=KEY/YOUR/FANCY/=KEY
-----END RSA PRIVATE KEY-----]],
  X = '1',
  Y = '2',
  Z = '1+2',
  XY = '3',
  S = '1Y',
  T = '3+',
  foo1 = '1\n2',
  foo2 = '1#1\n2',
  foo3 = '1#1\n2',
  SPACE = 'a + b = c',
  EMPTY = ''
}

for key, value in pairs(expected_env) do
  assert(env[key] == value, string.format("error in key `%s`: expected `%s`, but got `%s`", key, value, env[key]))
end

print("test passed!")
