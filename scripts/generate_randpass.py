#!/usr/bin/env python3
import random
import string

special_character = random.choice([ '@',  '(', ')', '+', '-', '=',  '{', '}', '[', ']', '<', '>' ])
password = random.choice(string.ascii_uppercase) + random.choice(string.ascii_lowercase) + random.choice(string.digits) + special_character + ''.join(random.choices(string.ascii_letters + string.digits + '!@#$%^&*()[]{}<>?', k=11))
password = ''.join(random.sample(password, len(password)))
print(password)
