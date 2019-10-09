import os

def run_echidna(filename, contract):
    coverage = None 
    cmd = 'echidna-test '+filename+' '+contract+' --config tools/echidna.yaml > echidna.out 2> echidna.err'
    os.system(cmd)
    with open("echidna.out", newline='') as f:
        for l in f.readlines():
            l = l.replace('\n','')
            if "Unique instructions: " in l:
                coverage = int(l.split(" ")[2])

    return coverage
