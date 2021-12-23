import sys

problem_loc = 0x1A
bytefix = bytearray([1, 0])

try:
    with open(sys.argv[1], "r+b") as f:
        f.seek(problem_loc)
        f.write(bytefix)
except PermissionError as e:
    print(f"Permission denied: {e}")