import os
import shutil

def run_echidna(p):
    (filename, contract) = p
    coverage = None
    
    cdir = filename.replace("/","_")+".dir"
    shutil.rmtree(cdir)
    os.mkdir(cdir)
    os.chdir(cdir)

    cmd = 'echidna-test ../'+filename+' '+contract+' --config ../tools/echidna.yaml > echidna.out 2> echidna.err'
    print(cmd)
    os.system(cmd)
    with open("echidna.out", newline='') as f:
        for l in f.readlines():
            l = l.replace('\n','')
            if "Unique instructions: " in l:
                coverage = int(l.split(" ")[2])
    
    os.chdir('..')
    return (filename, coverage)
