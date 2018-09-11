#!/usr/bin/env python
# _*_coding:utf-8_*_
# Author: create by yang.hong
# Time: 2018-07-05 18:33


class CA(object):
    cls_pre = 'aaaa'
    abc_pre = [1, 2, 3]

    def __init__(self):
        self.obj_pre = 'bbbb'


#a = CA()
#b = CA()

#print(a.cls_pre, a.obj_pre)
#print(b.cls_pre, b.obj_pre)

#CA.cls_pre = 'ccccc'
#c = CA()

#d = CA()
#d.cls_pre = 'ddddd'

#print(CA.abc_pre)

e = CA()
e.abc_pre.append(6)

str_e = e.abc_pre
print(str_e)
print(CA.abc_pre)

#print(c.cls_pre, c.obj_pre)
#print(d.cls_pre, d.obj_pre)
#print(CA.cls_pre)
#print(CA.abc_pre)

