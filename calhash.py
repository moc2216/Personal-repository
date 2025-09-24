import hashlib

algorithm = input("输入hash算法 (如 md5, sha256): ")
text = input("输入待计算字符串: ")

hash_func = hashlib.new(algorithm)
hash_func.update(text.encode())
print(hash_func.hexdigest())
