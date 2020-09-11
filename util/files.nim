template withFile*(file: untyped, filename: string, filemode: FileMode, body: untyped): untyped =
  var file: File
  let fn = filename
  if file.open(fn, filemode):
    try:
      body
    finally:
      file.close()
  else:
    echo "Could not open ", fn
