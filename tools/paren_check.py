import re
path=r"c:/CODING_AREA/software Practice -_-/PreacherPro/lib/screens/ManagePayment/officer_approve_payment_page.dart"
s=open(path,encoding='utf-8').read()
counts={'(':0,')':0,'{':0,'}':0,'[':0,']':0}
for i,ch in enumerate(s):
    if ch in counts:
        counts[ch]+=1
print('counts:',counts)
# show last 200 chars for context
print('\nlast 200 chars:\n', s[-200:])
# show a snippet around earlier reported line ~302
lines=s.splitlines()
ln=302
start=max(0,ln-10)
end=min(len(lines),ln+10)
cum=0
for idx, line in enumerate(lines, start=1):
    for ch in line:
        if ch=='(':
            cum+=1
        elif ch==')':
            cum-=1
    if idx>=start and idx<end:
        print(f"{idx:03}: {line}  | cum={cum}")
    if cum<0:
        print('Negative cum at', idx)
        break
print('\nFinal cum (should be 0):', cum)
